/**
 * Author Paul R. Stay
 * Western Governors University @ 2012
 * Created Date: February 2012
 *
 *  Modified November 3, 2012 @1044 hrs by Paul Coleman ver APIVersion 20.0->26.0 and test method compliance
 * Modified 01/28/2013 to match standard naming conventions by Katarina Melki
 */
@isTest
private with sharing class TestMentorUtility {

    //Tests the MentorUtility.mapUserPidm function
    static testMethod void testPIDMAssignmentFromUserToMentorObjBeforeInsert() {
                
        User runAsUser = [SELECT Id FROM User where username like 'sadmin@wgu.edu%' LIMIT 1];

        System.runAs( runAsUser ) {
        
            // First create a user so that we can test against it
            ID mentorProfileID = [SELECT id from Profile where name = 'Mentor'].id;
            User testUser = new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942_test', Username='a_test_mentor@wgu.edu', email='a_test_mentor@wgu.edu', Alias='a_test_m', CommunityNickname='a_test_mentor', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true);
      
            System.debug(LoggingLevel.DEBUG, 'TEST USER FOR TEST: ' + JSON.serialize( testUser ) );
        
            Test.startTest();
            
            // Test PIDM__c match and assignment by creating a Mentor__c record, seeking confirmation of User Record assignment (User__c) by before insert trigger
            Mentor__c newMentor = new Mentor__c();
            newMentor.PIDM__c = testUser.PIDM__c;
            newMentor.StudentCapacity__c = 90.0;
            newMentor.StudentsAssigned__c = 45;
            System.debug(LoggingLevel.DEBUG, 'NEW TEST MENTOR__C BEFORE INSERT: ' + JSON.serialize( newMentor ) );
            insert newMentor;
            System.debug(LoggingLevel.DEBUG, 'NEW TEST MENTOR__C AFTER INSERT: ' + JSON.serialize( newMentor ) );
            
            // Check to see of the user ID has been set.
            Mentor__c mentorAfterInsert = [select Id, user__c from Mentor__c where id = :newMentor.Id];
            System.assertEquals( mentorAfterInsert.user__c, testUser.Id, 'Mentor__c.user__c DOES NOT MATCH User.Id for User.PIDM__c of ' + testUser.PIDM__c );
            
            Test.stopTest();
        }
    }
}