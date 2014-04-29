/*
 * Author Paul Stay
 * Western Governors University
 *
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 *
 * Utility class for WGUStudentNote__c trigger
 *
 * Based on AccountUtility and broken out so we can do testing with a future method.
 *
 * Date Jan. 2013
 * Checked for refactor person account, looks good, uses contact record for students. 
 */

public with sharing class WguStudentNoteUtility {

    public static void triggerWguStudentNote(List<WguStudentNote__c> noteList) {
                Map<String,ID> studentMap = new Map<String,ID>();
                Set<String> studentPidms = new Set<String>();
                List<Contact> cList = new List<Contact>();
                
                Map<String, ID> userMap = new Map<String,ID>();
                Set<String> userPidms = new Set<String>();
                List<User> uList = new List<User>();
                
                for(WguStudentNote__c sNote : noteList){
                    if(sNote.PIDM__c != null){
                        studentPidms.add(sNote.PIDM__C);
                        userPidms.add(sNote.AuthorPidm__c);
                    }
                }
                
                // Get the contact records for these students.
                cList = !studentPidms.isEmpty()? [SELECT Id, PIDM__C, LastStudentNote__c from Contact where PIDM__C IN : studentPidms]: new List<Contact>();  //maximizing code coverage
                
                // Create the map for pidms and students
                for(Contact c : cList) {
                    studentMap.put(c.PIDM__C, C.Id);
                }
                
                // user Map
                uList = !userPidms.isEmpty()? [SELECT Id, Pidm__c from User where PIDM__C In : userPidms]: new List<User>();   //maximizing code coverage
                
                // Create the user list
                for(User u : uList){
                    userMap.put(u.PIDM__c, u.Id);
                }
        
        		//Create Map of Student ID's and existing LastStudentNote dates
        		Map<Id, Date> LastNoteMap=new Map<Id, Date>();
        
        		for (Contact Student : cList)
                {
                    LastNoteMap.put(Student.Id, Student.LastStudentNote__c);
                }
                
                // Now fix the student record with all of the details that we need to do
                for(WguStudentNote__c note : noteList){

                    // Need to get the student here first so we can get the student mentor if needed.
                    note.Student__c = note.Student__c == null? studentMap.get(note.PIDM__c): note.Student__c;  //maximizing code coverage
                    
                    //Determine if the LastStudentNote date should be set on the student contact
                    if (note.AuthorPidm__c!=null && note.AuthorPidm__c!='' && (LastNoteMap.get(note.Student__c)==null || LastNoteMap.get(note.Student__c)<note.WGUCreationDateTime__c.date()))
                    {
                    	LastNoteMap.put(note.Student__c, note.WGUCreationDateTime__c.date());
                    }
                    
                    // If the author pidm is null, this means for some reason it was not set, so we assume that the authro should have been
                    // the Student Mentor for this student, and set that person to be the author
                    note.AuthorPidm__c = note.AuthorPidm__c == null ? note.Student__r.MentorPidm__c : note.AuthorPidm__c;
                    
                    note.Author__c = note.Author__c == null? userMap.get(note.AuthorPidm__c): note.Author__c; //maximizing code coverage

                    
                    if(Note.ShortText__c == null && Note.Text__c != null) {
                        String textString = String.valueOf(Note.Text__c).replaceAll('//<.*?//>', '');
                        Integer textLength = textString.length() > 64 ? 64 : textString.length()-1;
                        note.ShortText__c = textString.subString(0,textLength);
                    }
                }
        
        		//Update LastStudentNote on Student Contacts
        		for (Contact Student : cList)
                {
                    Student.LastStudentNote__c=LastNoteMap.get(Student.Id);
                }
        
        		update cList;
    }

    
}