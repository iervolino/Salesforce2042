/*****************************************************************************************
* Name: TestStudentCaseUtility
* Author: Will Slade
* Purpose: Test class for StudentCaseUtility
* Revisions: 
*    - 12/1/12 Created Class
*    - 1/24/13 Updated class for person account refactor
*    - 10/8/2013 PBC commented out User record creation, replaced with active User lookup for test runs
******************************************************************************************/

@isTest
private class TestStudentCaseUtility
{
    static testMethod void buildTestData()
    {
        User testUser = [SELECT id FROM User where isActive=TRUE and Profile.Name = 'System Administrator' LIMIT 1]; //new User();
        /*List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        testUser.Firstname = 'TestStCaEm';
        testUser.Lastname = 'UserStCaEm';
        testUser.Pidm__c = 'QA9505QA';
        testUser.Username = 'testuserStuCaEm@testuser.testuser';
        testUser.Email = 'testuserStCaEm@testuser.testuser.my.wgu.edu';
        testUser.Alias = 'testStCa';
        testUser.CommunityNickname = 'testua6123se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profiles[0].Id;
        testUser.LanguageLocaleKey = 'en_US';
        
        insert testUser;       
        */
    
        Contact testContact1 = new Contact();
        testContact1.FirstName = 'Willtest';
        testContact1.Lastname = 'Slayedtest';
        testContact1.Email = 'wslayed@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';
        testContact1.StudentID__c = 'QA125ID';
        
        insert testContact1;
        
        test.startTest();
        System.RunAs(testUser)
        {
            StudentCase__c stuCase = new StudentCase__c(Comments__c = 'Hello these are comments', Contact__c = testContact1.Id);
            
            insert stuCase;                  
            
            Attachment attach = new Attachment();  
            attach.Body = Blob.valueOf('Attachment Body');  
            attach.Name = 'TestAttachFileWS.txt';
            //attach.ContentType = contentType;
            attach.ParentID = stuCase.Id;
            
            insert attach;
            
            stuCase.Comments__c += ' and here are more comments';
            
            update stuCase;
        
            test.stopTest();
            
            List<StudentCase__c> stuCases = [SELECT Id, Comments__c, Contact__c, Case__c FROM StudentCase__c WHERE Id = :stuCase.Id LIMIT 1];        
            List<Case> newCases = [SELECT Id FROM Case LIMIT 1];
            
            System.assert(stuCases.size() > 0);
            System.assert(newCases.size() > 0);
            //System.assertEquals(stuCase.Case__c, newCases[0].Id);
        }                
    }
}