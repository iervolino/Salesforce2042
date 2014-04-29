/**
 * Author Paul Stay
 * Western Governors University
 *
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing)
 * Revised: Switched from StudentTestUser account setup to use the ContactTestData static resource. 
 *          Changed reference to PersonContactId to Contact.Id field. (Katarina Melki 1/23/2012)
 */
@isTest
private with sharing class TestWguStudentNoteUtility {

    static testMethod void testWguStudentNoteUtility() {
        //Set up test mentor user
        ID mentorProfileID = [SELECT  id from Profile where name = 'Mentor'].id;
        User thisUser = new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942', Username='a@wgu.edu', email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true);
        System.debug(LoggingLevel.DEBUG, 'User for testWguStudentNoteUtility ' + thisUser.Name);
        Test.startTest();
        System.runAs(thisUser){ 
            //Load Contact test data to use for a test student
            List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData'); 
            
                       
        }  
        Test.stopTest();    
        Contact student=[select id, FirstName, LastName, Email,Status__c,  pidm__c, recordTypeId, recordType.Name, recordType.DeveloperName from contact][0];
        // Set up the test note
        WguStudentNote__c note = new WguStudentNote__c(AuthorPidm__c=thisUser.PIDM__c, WGUCreationDateTime__c=DateTime.now(), InteractionID__c = 'xtest001', PIDM__c=student.PIDM__c, Type__c='Live Call', SubType__c='Graduation', Text__c='now is the time!', name='Live Call');
         
        insert note;
        
        WGUStudentNote__c newNote = [Select id, Author__c, Student__c from WGUStudentNote__c where AuthorPidm__c = :thisUser.PIDM__c LIMIT 1];
        
        System.debug('    [4001] ' + newNote.Student__c);
        System.debug('    [4002] ' + student.id);           
        System.assert(newNote.Student__c==student.id);
        System.assert(newNote.Author__c==thisUser.id);   
        delete student;       
            
            
    }
}