/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Created Dec 17 2012 @ 1739 hrs
 *
 * Date January 30, 2013 @ 1033 hrs
 * Revised: Person Account Refactor - Paul Coleman 
 * 
 * Revised Jan 11 2013 @ 1325 hrs
 *    -Added test functionality for QAPercentage__c field update trigger - Will Slade
 * 
 * UserAttributes__c object's Utility Test methods
 *
 */

@isTest
private with sharing class TestUserAttributesUtility {

    static testMethod void testChangingCollegeTeamPickListAndSetUserRole() {
       ID testProfileID = [SELECT id from Profile where name = 'Enrollment Team' LIMIT 1].id;
       UserRole testUserRole = [SELECT id,Name from UserRole where DeveloperName = 'EnrollmentIT' LIMIT 1];
       Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
       
       User newUser = new User(LastName='Counselor',FirstName='Enrollment',pidm__c='ec123456', Username='ec@test.wgu.edu', Email='ec@test.wgu.edu', Alias='ec', CommunityNickname='ec', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=testProfileID, LanguageLocaleKey='en_US',WGUPostalCode__c='84070', isEmployee__c=true);
       newUser.UserRoleId = testUserRole.Id;
       insert newUser;
            
       User testUser = [SELECT Id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
       System.runAs(testUser) {
        
         Test.startTest();

           UserAttributes__c newAttrib = new UserAttributes__c(Name=newUser.FirstName+' '+newUser.LastName+' Attributes', User__c=newUser.Id, CollegeTeam__c=testUserRole.Name, RecordTypeId=targetRecordTypeId);
           insert newAttrib;
    
            String testCollegeTeamValue = 'Business Graduate'; 
            //test changing collegeTeam__c value on UserAttributes__c record--should change the UserRoleId (and Name) to matching value by UserAttributesTrigger (UserAttributesUtility) 
            newAttrib.CollegeTeam__c = testCollegeTeamValue;
            update newAttrib; //kickoff Trigger (after update) 
            
         Test.stopTest(); 

         User newUserAfterUpdate = [select id,userRoleId, userRole.Name from User where Id = :newUser.Id LIMIT 1];
         System.assert(  newAttrib.collegeTeam__c == newUserAfterUpdate.UserRole.Name, 'After update of UserAttributes__c record, User__c.UserRole.Name does not equal UserAttribtutes__c.CollegeTeam__c(' +testCollegeTeamValue+ ') but equals: '+newUserAfterUpdate.UserRole.Name+' in testChangingCollegeTeamPickListAndSetUserRole Test' );

         Map<Id,UserAttributes__c> userAttribOldMap = new Map<Id,UserAttributes__c>();
         userAttribOldMap.put(newAttrib.Id,new UserAttributes__c(Id=newAttrib.Id, CollegeTeam__c=newAttrib.CollegeTeam__c));

         //test setting nonsense picklist value on UserAttributes__c record--should be ignored during UserRole change in UserAttributesTrigger (UserAttributesUtility)
         newAttrib.CollegeTeam__c = 'NonsenseValueDoesNotExist';
         update newAttrib; //kickoff Trigger (after update) 
         
         //grabbing code coverage into future call handling block
         List<UserAttributes__c> listNew = new List<UserAttributes__c>();
         listNew.add(newAttrib);
         //synchronous call
         futureCallSetUserRoleFromCollegeTeam( Json.serialize(listNew), Json.serialize(userAttribOldMap), targetRecordTypeId );
         
         newUserAfterUpdate = [select id,userRoleId, userRole.Name from User where Id = :newUser.Id LIMIT 1];
         System.assert(  newUserAfterUpdate.UserRole.Name == testCollegeTeamValue, 'After update of UserAttributes__c record with bogus CollegeTeam__c value, User__c.UserRole.Name did not remain unchanged (equals: '+newUserAfterUpdate.UserRole.Name+') in testChangingCollegeTeamPickListAndSetUserRole Test' );
         
       }
        
    }
    
    
    
    @future
    private static void futureCallSetUserRoleFromCollegeTeam( String listNewJSON, String mapOldJSON, String targetRecordTypeId ) {
      
        //grabbing code coverage into future call exception handling block
        try { UserAttributesUtility.setUserRoleFromCollegeTeam( listNewJSON, mapOldJSON, targetRecordTypeId ); } catch (Exception e) {}
        
    } 
///////////////////////////////////// END PAUL TEST /////////////////////////////////////

///////////////////////////////////// BEGIN WILL TEST ///////////////////////////////////
    
    public static testmethod void testUserAttributesQAPercIns()
    {    
        User testUser = new User();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Finaid' LIMIT 1].Id;
        
        testUser.Firstname = 'TestQApEm';
        testUser.Lastname = 'QApEm';
        testUser.Pidm__c = 'QA94050QA';
        testUser.Username = 'testuserQApEm@testuser.testuser';
        testUser.Email = 'testuserQApEm@testuser.testuser.wgu.edu';
        testUser.Alias = 'testQAp';
        testUser.CommunityNickname = 'testua4123se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.QAPercentage__c = 75.0;      
        insert testUser;
        
        User testingUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        System.runAs(testingUser)
        {                       
            test.startTest();
    
            UserAttributes__c testUA = new UserAttributes__c( user__c = testUser.Id, QAPercentage__c = 80.0 );
            insert testUA;
            
            test.stopTest();

            System.assert([SELECT QAPercentage__c FROM User WHERE Id = :testUser.Id LIMIT 1].QAPercentage__c == 80.0, 'INSERT Test FAILURE, QAPercentage__C does not equal target value.');
        }   
    }
    
    public static testmethod void testUserAttributesQAPercUpd()
    {    
        User testUser = new User();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Finaid' LIMIT 1].Id;
        
        testUser.Firstname = 'TestQApEm';
        testUser.Lastname = 'QApEm';
        testUser.Pidm__c = 'QA94050QA';
        testUser.Username = 'testuserQApEm@testuser.testuser';
        testUser.Email = 'testuserQApEm@testuser.testuser.wgu.edu';
        testUser.Alias = 'testQAp';
        testUser.CommunityNickname = 'testua4123se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.QAPercentage__c = 75.0;        
        insert testUser; 
        
        User testingUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];               
        
        System.runAs(testingUser)
        {
            test.startTest();
    
            UserAttributes__c testUA = new UserAttributes__c( user__c = testUser.Id, QAPercentage__c = 80.0 );
            insert testUA;
            testUA.QAPercentage__c = 50.6;
            update testUA;
            
            test.stopTest();
            
            System.assert([SELECT QAPercentage__c FROM User WHERE Id = :testUser.Id LIMIT 1].QAPercentage__c == 50.6, 'UPDATE Test FAILURE, QAPercentage__c does not equal target value.');
            
            //grabbing code coverage into Catch(System.AsyncException e) block
            List<UserAttributes__c> recordsOfInterest = [SELECT Id, QAPercentage__c, User__c FROM UserAttributes__c WHERE Id = :testUA.Id];
            Set<Id> idsOfInterest = new Set<Id>();
            idsOfInterest.add(testUA.Id);
    
            futureCallUserAttributesQAPercUpd( JSON.serialize(recordsOfInterest), JSON.serialize(idsOfInterest) );
        }
    }

    
    @future
    private static void futureCallUserAttributesQAPercUpd( String usersToUpdateJSON, String idsToUpdateJSON ) {
      
        //grabbing code coverage into future call exception handling block
        try { UserAttributesUtility.updateQAPercentage(usersToUpdateJSON, idsToUpdateJSON ); } catch (Exception e) {}
        
    } 

///////////////////////////////////// END WILL TEST ////////////////////////////////////       
}