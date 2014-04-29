/*****************************************************************************************
* Name: StudentAcademicCourseUtility
* Author: Will Slade
* Purpose: Upserts Student Academic Courses based on control object
* Revisions: 
*    - 10/21/2013 Created Class
*
******************************************************************************************/

public class StudentAcademicCourseUtility
{
    public static void upsertCourses(String sacfbListJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture())
        {
            processUpsertCourses(sacfbListJSON);
        }
        else
        {
            asyncUpsertCourses(sacfbListJSON);
        }
    }
    
    @future
    public static void asyncUpsertCourses(String sacfbListJSON)
    {
        processUpsertCourses(sacfbListJSON);
    }

    public static void processUpsertCourses(String sacfbListJSON)
    {
        List<StudentAcademicCourseFromBanner__c> sacfbList = (List<StudentAcademicCourseFromBanner__c>) JSON.deserialize(sacfbListJSON, List<StudentAcademicCourseFromBanner__c>.class);
        List<StudentAcademicCourse__c> sacInsertList = new List<StudentAcademicCourse__c>();
        List<StudentAcademicCourse__c> sacUpdateList = new List<StudentAcademicCourse__c>();
        List<StudentAcademicCourse__c> sacDeleteList = new List<StudentAcademicCourse__c>();
        Map<String, Id> pidmToContactIdMap = new Map<String, Id>();
        String courseStatus = null;
        Id studentContact = null;       
        
        //get a keyset of the student pidms for the contact map
        for (StudentAcademicCourseFromBanner__c thisSACFB : sacfbList)
        {
            pidmToContactIdMap.put(thisSACFB.studentPIDMIN__c, null);
        }      
        
        //find all contact records within pidm set
        List<Contact> contactList = [SELECT Id, PIDM__c FROM Contact WHERE PIDM__c IN :pidmToContactIdMap.keyset()];
        
        //populate contact IDs in map
        for (Contact thisContact : contactList)
        {
            pidmToContactIdMap.put(thisContact.PIDM__c, thisContact.Id);
        }
        
        //loop through map and upsert source records
        for (StudentAcademicCourseFromBanner__c thisSACFB : sacfbList)
        {
            if (pidmToContactIdMap.get(thisSACFB.studentPIDMIN__c) != null)
            {
                studentContact = pidmToContactIdMap.get(thisSACFB.studentPIDMIN__c);
            }
            else
            {
                studentContact = null;
            }
        
            if (thisSACFB.StatusIN__c == 'NP')
            {
                courseStatus = 'Not Passed';
            }
            else if (thisSACFB.StatusIN__c == 'WD')
            {
                courseStatus = 'Not Passed';
            }             
            else if (thisSACFB.StatusIN__c == 'P')
            {
                courseStatus = 'Passed';
            }
            else if (thisSACFB.StatusIN__c == 'PA')
            {
                courseStatus = 'Passed';
            }            
            else if (thisSACFB.StatusIN__c == 'WV')
            {
                courseStatus = 'Waived';
            }            
            else if (thisSACFB.StatusIN__c == 'TR')
            {
                courseStatus = 'Transferred';
            }            
            else if (thisSACFB.StatusIN__c == 'RM')
            {
                courseStatus = 'Requirements Met';
            } 
            else if (thisSACFB.StatusIN__c == 'RE')
            {
                courseStatus = 'Registered';
            }     
            else if (thisSACFB.StatusIN__c == 'DD')
            {
                courseStatus = 'Unenrolled';
            }                              
            else
            {
                courseStatus = 'Planned';
            }            
            
            if ((thisSACFB.ActionNeeded__c == 'Insert' || thisSACFB.ActionNeeded__c == 'Update' || thisSACFB.ActionNeeded__c == 'Upsert')
                && thisSACFB.SynchronizationError__c == null && studentContact != null)
            {
                if (thisSACFB.StudentAcademicCourse__c == null)
                {                                    
                    sacInsertList.add(new StudentAcademicCourse__c(CompositeKey__c = thisSACFB.CompositeKeyIn__c,
                                                                   Name = thisSACFB.CourseTitleIN__c.length()>80 ? thisSACFB.CourseTitleIN__c.substring(0,80) : thisSACFB.CourseTitleIN__c,
                                                                   FullCourseTitle__c = thisSACFB.CourseTitleIN__c,
                                                                   CompetencyUnits__c = thisSACFB.CompetencyUnitsIN__c,
                                                                   CourseCode__c = thisSACFB.CourseCodeIN__c,
                                                                   StartDate__c = thisSACFB.StartDateIN__c,
                                                                   EndDate__c = thisSACFB.EndDateIN__c,
                                                                   Status__c = courseStatus,
                                                                   StudentContact__c = studentContact,
                                                                   Term__c = thisSACFB.TermIN__c,
                                                                   Type__c = thisSACFB.TypeIN__c,
                                                                   Version__c = thisSACFB.Version__c));
                }
                if (thisSACFB.StudentAcademicCourse__c != null)
                {                                    
                    sacUpdateList.add(new StudentAcademicCourse__c(Id = thisSACFB.StudentAcademicCourse__c,
                                                                   Name = thisSACFB.CourseTitleIN__c.length()>80 ? thisSACFB.CourseTitleIN__c.substring(0,80) : thisSACFB.CourseTitleIN__c,
                                                                   FullCourseTitle__c = thisSACFB.CourseTitleIN__c,
                                                                   CompositeKey__c = thisSACFB.CompositeKeyIn__c,
                                                                   CompetencyUnits__c = thisSACFB.CompetencyUnitsIN__c,
                                                                   CourseCode__c = thisSACFB.CourseCodeIN__c,
                                                                   StartDate__c = thisSACFB.StartDateIN__c,
                                                                   EndDate__c = thisSACFB.EndDateIN__c,
                                                                   Status__c = courseStatus,
                                                                   StudentContact__c = studentContact,
                                                                   Term__c = thisSACFB.TermIN__c,
                                                                   Type__c = thisSACFB.TypeIN__c,
                                                                   Version__c = thisSACFB.Version__c));
                }                
            }
            else if (thisSACFB.ActionNeeded__c == 'Delete' && thisSACFB.StudentAcademicCourse__c != null)
            {
                sacDeleteList.add(new StudentAcademicCourse__c(Id = thisSACFB.StudentAcademicCourse__c));
            }                     
            //some key value is missing
            else
            {
                //do not add the record to any update or insert lists as it has an error
            }
        }
        
        update sacUpdateList;
        insert sacInsertList;
        delete sacDeleteList;
    }
    
   public static void insertSFAWcrseReq(String sacJson){
        if (Limits.getFutureCalls() > 3 || System.isFuture()){
            processInsertSFAWcrseReq(sacJson);
        }else{
            asyncInsertSFAWcrseReq(sacJson);
        }
    }
    
    @future
    public static void asyncInsertSFAWcrseReq(String sacJson){
        processInsertSFAWcrseReq(sacJson);
    }

    public static void processInsertSFAWcrseReq(String sacJson){
        List<StudentAcademicCourse__c> sacList = (List<StudentAcademicCourse__c>)JSON.deserialize(sacJson, List<StudentAcademicCourse__c>.class);
        List<StudentAcademicCourseRequirement__c> sacrList = new List<StudentAcademicCourseRequirement__c>();
        for(StudentAcademicCourse__c sac : sacList){
            if('SFAW'.equals(sac.CourseCode__c) && 'Passed'.equals(sac.Status__c)){
                StudentAcademicCourseRequirement__c sacr = new StudentAcademicCourseRequirement__c(Name = sac.Name,
                                                                    UniqueKey__c = sac.CompositeKey__c,
                                                                    RequirementCode__c = sac.CourseCode__c,
                                                                    Status__c = sac.Status__c,
                                                                    Completed__c = TRUE,
                                                                    StudentAcademicCourse__c = sac.Id);
                sacrList.add(sacr);
            }
        }
        insert sacrList;
    }
}