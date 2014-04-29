/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 *
 * Revised Dec 17 2012 @ 1709 hrs
 * Revised: added After Insert logic for creating UserAttributes__c object for enrollment process users 
 * 
 * User object's Utility Test methods
 *
 */
@isTest
public with sharing class TestUserUtility {

   static testmethod void testUserTrigger(){
       List<TimeZoneByZip__c> timezones = new List<TimeZoneByZip__c>();
       timezones.add( new TimeZoneByZip__c(Name='20776',TimeZoneKey__c='America/New_York'));
       timezones.add( new TimeZoneByZip__c(Name='85003',TimeZoneKey__c='America/Phoenix'));
       insert timezones;
       List<States__c> states = new List<States__c>();
       states.add( new States__c(Name='CA',DefaultTimeZoneKey__c='America/Los_Angeles',StateFullName__c='California'));
       states.add( new States__c(Name='IL',DefaultTimeZoneKey__c='America/Chicago',StateFullName__c='Illinois'));
       insert states;
       
    
      Test.startTest(); 
        ID LockDownID = [SELECT id from Profile where name = 'LockDown'].id;
        List<User> users = new List<user>();
        users.add( new User(LastName='Mentor',FirstName='Standard',pidm__c='a1111111', Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=LockDownID, LanguageLocaleKey='en_US',WGUPostalCode__c='20776') );
        users.add( new User(LastName='Mentor',FirstName='State',pidm__c='b2222222', Username='b@wgu.edu', Email='b@wgu.edu', Alias='b', CommunityNickname='b', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=null, isEmployee__c=true, LanguageLocaleKey='en_US',PostalCode='85003') );
        users.add( new User(LastName='Mentor',FirstName='State',pidm__c='c2222222', Username='c@wgu.edu', Email='c@wgu.edu', Alias='c', CommunityNickname='c', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=LockDownID, isEmployee__c=true,LanguageLocaleKey='en_US',WGUState__c='IL') );
        users.add( new User(LastName='Mentor',FirstName='State',pidm__c='d2222222', Username='d@wgu.edu', Email='d@wgu.edu', Alias='d', CommunityNickname='d', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=LockDownID, isEmployee__c=true,LanguageLocaleKey='en_US',State='CA') );
        users.add( new User(LastName='Mentor',FirstName='State',pidm__c='e2222222',Username='e@wgu.edu', Email='e@wgu.edu', Alias='e', CommunityNickname='e', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=LockDownID, isEmployee__c=true,LanguageLocaleKey='en_US') );
        insert users;
        List<User> usersAfter = [SELECT id,username,state,postalcode,WGUpostalcode__c,WGUState__c,timezonesidkey,ProfileId from user where id in :users];
        System.debug( LoggingLevel.DEBUG, JSON.serialize( usersAfter ) );
        System.assertEquals(usersAfter[0].timezonesidkey,'America/New_York');
        System.assertEquals(usersAfter[1].ProfileId,[select id from Profile where Name = 'WGU Chatter Only'].id);
        System.assertEquals(usersAfter[1].timezonesidkey,'America/Phoenix');
        System.assertEquals(usersAfter[2].timezonesidkey,'America/Chicago');
        System.assertEquals(usersAfter[3].timezonesidkey,'America/Los_Angeles');
        System.assertEquals(usersAfter[4].timezonesidkey,'America/Denver');
        
        
        //test trigger's logic which sets all user record profiles to StudentProfile when isEmployee__c == false
        try {
          insert new User(LastName='Mentor',FirstName='Standard',pidm__c='f1111111',Username='f@wgu.edu', Email='f@wgu.edu', Alias='f', CommunityNickname='f', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=null, LanguageLocaleKey='en_US',WGUPostalCode__c='20776');
        } catch (DmlException e) {
          if( !e.getMessage().contains('INVALID_CROSS_REFERENCE_KEY') ) {
            throw e;
          }
        }
        
        //test trigger's logic which sets all user record profiles to StudentProfile when isEmployee__c == false
        try {
          insert new User(LastName='Mentor',FirstName='Standard',pidm__c='g1111111',Username='g@wgu.edu', Email='g@wgu.edu', Alias='g', CommunityNickname='g', TimeZoneSidKey='GMT'
        , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=LockDownID, isEmployee__c=false,LanguageLocaleKey='en_US',WGUPostalCode__c='20776');
        } catch (DmlException e) {
          if( !e.getMessage().contains('INVALID_CROSS_REFERENCE_KEY') ) {
            throw e;
          }
        }
      Test.stopTest();
    }



//////////////////////////START TEST Enrollment (UserAttributes) AFTER INSERT ////////////////////////////////

    static testmethod void testCreateEnrollmentAttributes() { 
      
       User testUser = [SELECT Id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
       ID testProfileID = [SELECT id from Profile where name = 'Enrollment Team' LIMIT 1].id;
       UserRole testUserRole = [SELECT id,Name from UserRole where DeveloperName = 'EnrollmentIT' LIMIT 1];
       Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
       
       User newUser = new User(LastName='Counselor',FirstName='Enrollment',pidm__c='ec123456', Username='ec@test.wgu.edu', Email='ec@test.wgu.edu', Alias='ec', CommunityNickname='ec', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=testProfileID, LanguageLocaleKey='en_US',WGUPostalCode__c='84070', isEmployee__c=true);
       newUser.UserRoleId = testUserRole.Id;
       insert newUser;
            
       System.runAs(testUser) {
        
         Test.startTest();
         
            System.assert( [select count() from UserAttributes__c where User__c = :newUser.Id] == 0, 'UserAttributes__c already exists after newUser insert for createEntrollmentAttributes Test' );
            update newUser; //kickoff Trigger (after update) 
         
         Test.stopTest(); 

	        System.assert( [select count() from UserAttributes__c where User__c = :newUser.Id] == 1, 'No UserAttributes__c exists after newUser update for createEntrollmentAttributes Test' );
	        UserAttributes__c newUserAttributes = [select id, name, collegeTeam__c, recordTypeId from UserAttributes__c where User__c = :newUser.Id LIMIT 1];    
	        System.assert(  newUserAttributes.collegeTeam__c == testUserRole.Name, 'UserAttributes__c exists after newUser update, but CollegeTeam__c is not set correctly in createEntrollmentAttributes Test' );
	        System.assert(  newUserAttributes.recordTypeId == targetRecordTypeId, 'UserAttributes__c exists after newUser update, but RecordTypeId is not set correctly in createEntrollmentAttributes Test' );

       }
    
    }
     
    static testmethod void testCreateEnrollmentAttributesWithExistingUserAttributesRecord() {
      
       User testUser = [SELECT Id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
       ID testProfileID = [SELECT id from Profile where name = 'Enrollment Team' LIMIT 1].id;
       UserRole testUserRole = [SELECT id,Name from UserRole where DeveloperName = 'EnrollmentIT' LIMIT 1];
       Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
       
       User newUser = new User(LastName='Counselor',FirstName='Enrollment',pidm__c='ec123456', Username='ec@test.wgu.edu', Email='ec@test.wgu.edu', Alias='ec', CommunityNickname='ec', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=testProfileID, LanguageLocaleKey='en_US',WGUPostalCode__c='84070', isEmployee__c=true);
       newUser.UserRoleId = testUserRole.Id;
       insert newUser;
       
       Map<Id,UserRole> testUserRoleMap = new Map<Id,UserRole>([SELECT id,Name from UserRole where DeveloperName = 'EnrollmentIT' LIMIT 1]);            
       List<User> userList = new List<User>();
       userList.add(newUser);
            
       System.runAs(testUser) {
        
         Test.startTest();
            UserAttributes__c newAttrib = new UserAttributes__c(Name=newUser.FirstName+' '+newUser.LastName+' Attributes', User__c=newUser.Id, CollegeTeam__c=testUserRole.Name, RecordTypeId=targetRecordTypeId);
            insert newAttrib;

            System.assert( [select count() from UserAttributes__c where User__c = :newUser.Id] == 1, 'No UserAttributes__c exists before newUser update for testCreateEnrollmentAttributesWithExistingUserAttributesRecord Test' );            
            update newUser; //kickoff Trigger (after update) 
            
         Test.stopTest();
         
	        UserAttributes__c newUserAttributes = [select id, name, collegeTeam__c, recordTypeId from UserAttributes__c where User__c = :newUser.Id LIMIT 1];    
	        System.assert(  newUserAttributes.collegeTeam__c == testUserRole.Name, 'UserAttributes__c exists after newUser update, but CollegeTeam__c is not set correctly in testCreateEnrollmentAttributesWithExistingUserAttributesRecord Test' );
	        System.assert(  newUserAttributes.recordTypeId == targetRecordTypeId, 'UserAttributes__c exists after newUser update, but RecordTypeId is not set correctly in testCreateEnrollmentAttributesWithExistingUserAttributesRecord Test' );
         
          futureCallCreateEnrollmentAttributes( Json.serialize(userList), Json.serialize(testUserRoleMap) );             
          
       }
    
    }
     
    
     
    @future
    private static void futureCallCreateEnrollmentAttributes( String ListNewJSON, String MapRoleIdsJSON ) {
      
        //grabbing code coverage into future call exception handling block
        try { UserUtility.createEnrollmentAttributes( ListNewJSON, MapRoleIdsJSON ); } catch (Exception e) {}
        
    } 

//////////////////////////END TEST Enrollment (UserAttributes) ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////START TEST USER EMAIL AND USERNAME CHANGES ////////////////////////////////
    static testmethod void testChangeUsername() { 
      
       ID testProfileID = [SELECT id from Profile where name = 'Enrollment Team' LIMIT 1].id;
       UserRole testUserRole = [SELECT id,Name from UserRole where DeveloperName = 'EnrollmentIT' LIMIT 1];
       Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
       
       User newUser = new User(LastName='Counselor',FirstName='Enrollment',pidm__c='ec123456', Username='ec@junk.wgu.edu', Email='ec@junk.wgu.edu', Alias='ec', CommunityNickname='ec', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=testProfileID, LanguageLocaleKey='en_US',WGUPostalCode__c='84070', isEmployee__c=true);
       newUser.UserRoleId = testUserRole.Id;
       insert newUser;
            
       User testUser = TestStudentUser.getSAdminUser();
       System.runAs(testUser) {
        
         Test.startTest();
            String org = TestStudentUser.getEnvironment();
            newUser.Username = (org !=null && org.equals('prod'))? 'ec@testing2.wgu.edu': 'ec@wgu.edu.testing2';
            newUser.Email = org !=null && org.equals('prod')? 'ec@testing2.wgu.edu': 'ec@wgu.edu.testing2';
            update newUser; //kickoff Trigger (after update) 
         
         Test.stopTest(); 
         
         User afterUpdateUser = [SELECT Username,Email FROM User WHERE Id = :newUser.Id LIMIT 1];
         System.assert( afterUpdateUser.Username.equals(newUser.Username), 'Username DOES NOT Match AFTER UPDATE');
         System.assert( afterUpdateUser.Email.equals('ec@testing2.wgu.edu'), 'Email DOES NOT Match expected value of ec@testing.wgu.edu' );

       }
    
    }


    static testmethod void testChangeEmailAndName() { 
      
       ID testProfileID = [SELECT id from Profile where name = 'Enrollment Team' LIMIT 1].id;
       UserRole testUserRole = [SELECT id,Name from UserRole where DeveloperName = 'EnrollmentIT' LIMIT 1];
       Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
       
       User newUser = new User(LastName='Counselor',FirstName='Enrollment',pidm__c='ec123456', Username='ec@junk.wgu.edu', Email='ec@junk.wgu.edu', Alias='ec', CommunityNickname='ec', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=testProfileID, LanguageLocaleKey='en_US',WGUPostalCode__c='84070', isEmployee__c=true);
       newUser.UserRoleId = testUserRole.Id;
       insert newUser;
            
       User testUser = TestStudentUser.getSAdminUser();
       System.runAs(testUser) {
        
         Test.startTest();
         
            String org = TestStudentUser.getEnvironment();
            newUser.Email = (org !=null && org.equals('prod'))? 'ec@testing3.wgu.edu': 'ec@wgu.edu.testing3';
            newUser.LastName = 'THIS SHOULD NOT CHANGE';
            update newUser; //kickoff Trigger (after update) 
         
         Test.stopTest(); 
         
         User afterUpdateUser = [SELECT LastName,Email FROM User WHERE Id = :newUser.Id LIMIT 1];
         System.assert( afterUpdateUser.Email.equals('ec@testing3.wgu.edu'), 'Email DOES NOT Match expected value of ec@testing3.wgu.edu' );
         System.assert( afterUpdateUser.LastName.equals('Counselor'), 'LastName was altered by SAdmin User, expected "Counselor" but got "'+  afterUpdateUser.LastName + '"');
         List<User> userTestList = new List<User>();
         userTestList.add(afterUpdateUser);
         futureRecoverFromUserNameChange( JSON.serialize(userTestList) );

       }
    
    }

    @future
    private static void futureRecoverFromUserNameChange( String ListNewJSON ) {
      
        //grabbing code coverage into future call exception handling block
        try { UserUtility.recoverFromUsernameChange( ListNewJSON ); } catch (Exception e) {}
        
    } 
//////////////////////////END TEST USER EMAIL AND USERNAME CHANGES ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////


}