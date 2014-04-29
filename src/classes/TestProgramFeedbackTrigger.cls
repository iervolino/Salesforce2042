/*
 * Author Will Slade
 * Western Governors University 
 *
 * Modified October 8, 2013 by PBC, commented creation of User records for test and added getTestUser method to select an active user instead
 *
 * Created Date April 2 2013
 * 
 * Test ProgramFeedback Trigger
 *
 */

@isTest
private with sharing class TestProgramFeedbackTrigger
{      
	private static User getTestUser() {
		return [SELECT id FROM USER WHERE isActive = true AND id IN (Select AssigneeId From PermissionSetAssignment WHERE PermissionSet.Name = 'ProgramFeedbackUsers') LIMIT 1];
	}
	
    private static testMethod void testInsertToQueue() 
    {
        //User testUser = getTestUser(); //new User();
        //Id profileId = [SELECT Id FROM Profile WHERE Name = 'WGU Standard User' LIMIT 1].Id;
        QueueSObject pfTriage = [SELECT QueueId FROM QueueSObject WHERE Queue.Name = 'Program Feedback Triage' LIMIT 1];
        //QueueSObject cosFeedback = [SELECT QueueId FROM QueueSObject WHERE Queue.Name = 'CoS Feedback' LIMIT 1];
        
        /*testUser.Firstname = 'TestPFQueue';
        testUser.Lastname = 'UserPFQueue';
        testUser.Pidm__c = 'QA95090QA';
        testUser.Username = 'testuserPFQeueu@testuser.testuser';
        testUser.Email = 'testuserPFQueue@testuser.testuser.wgu.edu';
        testUser.Alias = 'testPFQ';
        testUser.CommunityNickname = 'testua6723se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';      
        insert testUser;
        */
        
        Test.startTest();
        
        ProgramFeedback__c testPF = new ProgramFeedback__c (OwnerId = pfTriage.QueueId);
        insert testPF;  
        
        Test.stopTest();
        
        testPF = [SELECT Id, Queue__c FROM ProgramFeedback__c WHERE Id = :testPF.Id];
        System.assertEquals(testPF.Queue__c, 'Program Feedback Triage');           
    }
    
    private static testMethod void testUpdateToUser() 
    {
		User testUser = getTestUser(); //new User();
        //Id profileId = [SELECT Id FROM Profile WHERE Name = 'WGU Standard User' LIMIT 1].Id;
        QueueSObject pfTriage = [SELECT QueueId FROM QueueSObject WHERE Queue.Name = 'Program Feedback Triage' LIMIT 1];
        //QueueSObject cosFeedback = [SELECT QueueId FROM QueueSObject WHERE Queue.Name = 'CoS Feedback' LIMIT 1];
        
        /*
        testUser.Firstname = 'TestPFQueue';
        testUser.Lastname = 'UserPFQueue';
        testUser.Pidm__c = 'QA95090QA';
        testUser.Username = 'testuserPFQeueu@testuser.testuser';
        testUser.Email = 'testuserPFQueue@testuser.testuser.wgu.edu';
        testUser.Alias = 'testPFQ';
        testUser.CommunityNickname = 'testua6723se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';      
        insert testUser;
        */
        
        Test.startTest();
        
        ProgramFeedback__c testPF = new ProgramFeedback__c (OwnerId = pfTriage.QueueId);
        insert testPF; 
        
        testPF.OwnerId = testUser.Id;
        update testPF; 
        
        Test.stopTest();
        
        testPF = [SELECT Id, Queue__c FROM ProgramFeedback__c WHERE Id = :testPF.Id];
        System.assertEquals(testPF.Queue__c, 'Program Feedback Triage');           
    }  
    
    private static testMethod void testUpdateToQueue() 
    {
		User testUser = getTestUser(); //new User();
        //Id profileId = [SELECT Id FROM Profile WHERE Name = 'WGU Standard User' LIMIT 1].Id;
        QueueSObject pfTriage = [SELECT QueueId FROM QueueSObject WHERE Queue.Name = 'Program Feedback Triage' LIMIT 1];
        QueueSObject cosFeedback = [SELECT QueueId FROM QueueSObject WHERE Queue.Name = 'CoS Feedback' LIMIT 1];
        
        /*testUser.Firstname = 'TestPFQueue';
        testUser.Lastname = 'UserPFQueue';
        testUser.Pidm__c = 'QA95090QA';
        testUser.Username = 'testuserPFQeueu@testuser.testuser';
        testUser.Email = 'testuserPFQueue@testuser.testuser.wgu.edu';
        testUser.Alias = 'testPFQ';
        testUser.CommunityNickname = 'testua6723se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';      
        insert testUser;
        */
        
        Test.startTest();
        
        ProgramFeedback__c testPF = new ProgramFeedback__c (OwnerId = pfTriage.QueueId);
        insert testPF; 
        
        testPF.OwnerId = testUser.Id;
        update testPF; 
        
        testPF.OwnerId = cosFeedback.QueueId;
        update testPF;
        
        Test.stopTest();
        
        testPF = [SELECT Id, Queue__c FROM ProgramFeedback__c WHERE Id = :testPF.Id];
        System.assertEquals(testPF.Queue__c, 'CoS Feedback');           
    }        
}