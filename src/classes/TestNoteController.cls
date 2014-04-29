/**
 *  Author Paul Stay and Paul Coleman
 *  Test the WGU Student Notes class, controller, and page.
 *
 *  Date: Oct 30 2012, 1147 hrs
 *  Revised: (security audit compliance: with sharing) 
 *
 */
@isTest
private with sharing class TestNoteController {

    private static testMethod void getStudentJSONByContactId() {
        // Create a new Student
        Contact studentContact = TestStudentUser.getTestStudentContact();   
        
        // Test method
        Test.startTest();
            String json = NotesController.getStudentJSONByContactId(studentContact.Id);
            System.debug('  ' + json);
            System.assert(json.length() > 0);
            
            // Test for a null contactId
            try {
                json = NotesController.getStudentJSONByContactId(null);
            } catch (StudentException e){
                System.assert(true);
            }
            
        Test.stopTest();
        
    }
    
    private static testMethod void getStudentJSONByStudentWGUId() {
        // Create a new Student
        Contact studentContact = TestStudentUser.getTestStudentContact();  
        
        if ( studentContact.StudentID__c == null ) {
         studentContact.StudentId__c = '0012334567';
         update studentContact;
        }
        
        // Test method
        Test.startTest();
            String json = NotesController.getStudentJSONByStudentWGUId(studentContact.StudentId__c);
            System.debug('  ' + json);
            System.assert(json.length() > 0);
            
            // Test for a null contactId
            try {
                json = NotesController.getStudentJSONByStudentWGUId(null);
            } catch (StudentException e){
                System.assert(true);
            }
            
        Test.stopTest();
                
    }
    
    private static testMethod void getStudentJSON() {
        // Create a new Student
        Contact studentContact = TestStudentUser.getTestStudentContact();
        
        Test.startTest();
            String json = NotesController.getStudentJSON( studentContact.PIDM__C, true);
            System.assert(json.length() > 0);
            
            json = NotesController.getStudentJSON(studentContact.AccountId, false);
            System.assert(json.contains(studentContact.AccountId));
        Test.stopTest();        
    }

    private static testMethod void getNoteJSONById() {
        Contact studentContact = TestStudentUser.getTestStudentContact();  

        ID mentorProfileId = [SELECT id from Profile where name = 'Mentor'].ID;
        User mentorUser = new User(LastName='Mentor',FirstName='Standard',pidm__c='m198765',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId , LanguageLocaleKey='en_US');
        insert mentorUser ;
        
        WGUStudentNote__c note1 = getTestNote(mentorUser, studentContact, '1');
        
        insert note1; 
        
        System.runAs(mentorUser) {
            Test.startTest();
                String json = NotesController.getNoteJSONById(note1.id);
                System.assert(json.contains('short text'));
            Test.stopTest();
        }
    } 

    private static testMethod void saveNoteJSON(){
        
        Contact studentContact = TestStudentUser.getTestStudentContact();  
        studentContact.StudentRiskScore__c = 3;
        update studentContact;       
        ID mentorProfileId = [SELECT id from Profile where name = 'Mentor'].ID;
        User mentorUser = new User(LastName='Mentor',FirstName='Standard',pidm__c='m198765',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId , LanguageLocaleKey='en_US');
        insert mentorUser ;
        
        WGUStudentNote__c note = getTestNote(mentorUser,studentContact, '1');
        note.Text__c = EncodingUtil.base64Encode(Blob.ValueOf(note.text__c));
        
        WGUStudentNote__c note2 = getTestNote(mentorUser, studentContact, '2');
        insert note2;
        
        note2.Text__c = EncodingUtil.base64Encode(Blob.ValueOf(note.text__c));        
        
        String jsonStr = JSON.serialize(note);
        String jsonStr2 =  JSON.serialize(note2);
        
        Test.startTest();
            String jsonNote = NotesController.saveNoteJSON(jsonStr);
            System.assert(jsonNote.contains('m198765'));
        
            String updateNote = NotesController.saveNoteJSON(jsonStr2);
            System.assert(updateNote.contains('Subject line2'));
        Test.stopTest();
                
    }
    
    private static testMethod void getNotesJSONByOffset() {
        
        Contact studentContact = TestStudentUser.getTestStudentContact();  

        ID mentorProfileId = [SELECT id from Profile where name = 'Mentor'].ID;
        User mentorUser = new User(LastName='Mentor',FirstName='Standard',pidm__c='m198765',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId , LanguageLocaleKey='en_US');
        insert mentorUser ;
        
        List<WguStudentNote__c> noteList = new List<WguStudentNote__c>();
        for(Integer i=0; i < 60; i++){
            WGUStudentNote__c note = getTestNote(mentorUser, studentContact, i.format());
            noteList.add(note);
        }
        insert noteList;
        
        Test.startTest();
            // First test the count
            Integer count = NotesController.getNotesCountByContactId(studentContact.Id);
            System.debug('Motherload    -----> Note count is ' + count);
            System.assert(count> 50);
        
            String jsonStr = NotesController.getNotesJSONByOffset(studentContact.Id, 0);
            System.assert(jsonStr.contains('line49'));
            
            jsonStr = NotesController.getNotesJSONByOffset(studentContact.Id, 50);
            System.assert(jsonStr.contains('isDone'));
        Test.stopTest();
    }

    private static testMethod void nonStaticMethods(){
        
        Contact studentContact = TestStudentUser.getTestStudentContact(); 
        
        if ( studentContact.StudentID__c == null ) {
         studentContact.StudentId__c = '0012334567';
         update studentContact;
        }
        
        PageReference pageRef = new PageReference('/apex/Notes?accountId=' + studentContact.Id);
        test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(new WGUStudentNote__c());
        NotesController controller = new NotesController(stdController);        
        
        Test.startTest();
            
            String jsonStr = controller.getNoteSubTypeMetaJSON();
            System.assert(jsonStr.contains('controllerName'));

            jsonStr = controller.getNoteTypeJSON();
            System.assert(jsonStr.contains('name'));
             
            jsonStr = controller.getActionSubTypeMetaJSON();
            System.assert(jsonStr.contains('controllerName'));

            jsonStr = controller.getActionTypeJSON();
            System.assert(jsonStr.contains('name'));
            
            jsonStr = controller.getNoteTypeFilterJSON();
            System.assert(jsonStr.length() > 0);

            jsonStr = controller.getIE8SubHeader();
            System.assert(jsonStr.length() == 0);

            jsonStr = controller.getIE8Header();
            System.assert(jsonStr.length() == 0);

            jsonStr = controller.getIE8Footer();
            System.assert(jsonStr.length() == 0);

            jsonStr = controller.getLt();
            System.assert(jsonStr.length() > 0);

            jsonStr = controller.getGt();
            System.assert(jsonStr.length() > 0);

        Test.stopTest();
    } 
    
    private static testMethod void getPerformanceSurveyJSONByOffsetAndSave(){

        Contact studentContact = TestStudentUser.getTestStudentContact(); 

        ID mentorProfileId = [SELECT id from Profile where name = 'Mentor'].ID;
        User mentorUser = new User(LastName='Mentor',FirstName='Standard',pidm__c='m198765',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId , LanguageLocaleKey='en_US');
        insert mentorUser ;
        
        WGUStudentNote__c note = getTestNote(mentorUser, studentContact, '1');
        insert note;
        
        WGUStudentPerformanceSurvey__c survey = new WGUStudentPerformanceSurvey__c(); 
        survey.EvidenceOfAcademicActivity__c = 'Yes - 100%';
        survey.GoalPerformanceSinceLastCall__c = 'Attended a Seminar';
        survey.Name = 'Testing Note';
        survey.Student__c = studentContact.Id;
        survey.WGUStudentNote__c = note.Id;
        
        Test.startTest();
            String surveyJSON = NotesController.saveSurveyJSON( JSON.serialize( survey ) ); //INSERT
            System.assert( surveyJSON.contains( '"Id":"'), 'Survey Id NOT Present after save' );
            surveyJSON = NotesController.saveSurveyJSON( JSON.serialize( [SELECT id,EvidenceOfAcademicActivity__c,GoalPerformanceSinceLastCall__c,Name,Student__c,WGUStudentNote__c FROM WGUStudentPerformanceSurvey__c LIMIT 1][0] ) ); //UPDATE
            System.assert( NotesController.getPerformanceSurveyJSONByOffset(studentContact.Id,0).contains('"count":1,'), 'Survey fetch returned no records' );
        Test.stopTest();
    } 
        
    private static WGUStudentNote__c getTestNote(User mentorUser, Contact student, String indexNumber) {
        WGUStudentNote__c note1 = new WGUStudentNote__c(Student__c=student.Id, AuthorPidm__c=mentorUser.PIDM__c, WGUCreationDateTime__c=Date.today(), 
            Type__c='Live Call', PIDM__C=student.PIDM__c, ShortText__c='short text',
            Name='Subject line' + indexNumber, Text__c='This is some text', Author__c=mentorUser.id);
        return note1;
    }
}