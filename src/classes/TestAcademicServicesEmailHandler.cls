/*
 * Author Brad King
 * Western Governors University 
 *
 * Date April 2 2013
 * 
 * Test EmailHandlers  
 *
 */

@isTest
private with sharing class TestAcademicServicesEmailHandler
{
    private static testMethod void testAcademicServicesEmailHandler()
    {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        User testUser = new User();
        Contact testContact1 = new Contact();
        Contact testContact2 = new Contact();
        List<Contact> testContacts = new List<Contact>();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Field Experiences User' LIMIT 1].Id; 
        RecordType busContRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'BusinessContact' LIMIT 1];              
        
        testUser.Firstname = 'TestFEPlEm';
        testUser.Lastname = 'UserFEPlEm';
        testUser.Pidm__c = 'QA95050QA';
        testUser.Username = 'testuserFEPlEm@testuser.testuser';
        testUser.Email = 'testuserFEPlEm@testuser.testuser.wgu.edu';
        testUser.Alias = 'testFEPl';
        testUser.CommunityNickname = 'testua6123se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';    
  
        testContact1.FirstName = 'Willtest';
        testContact1.Lastname = 'Slayedtest';
        testContact1.Email = 'wslayed1@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';
        testContact1.RecordTypeId = busContRT.Id;
             
        testContact2.FirstName = 'Willtest1';
        testContact2.Lastname = 'Slayedtest1';
        testContact2.Email = 'wslayed1@my.wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContact2.RecordTypeId = busContRT.Id;
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
        System.assert(testContact1.Id != NULL, 'testAcademicServicesEmailHandler: TestContact1.id IS NULL');
        
        Date oppCloseDate = date.valueOf('2012-10-02');
        Opportunity testOpp = new Opportunity(name = 'Opp Case Feed Tester43', StageName = 'Applicant', CloseDate = oppCloseDate);
        insert testOpp;
        
        StudentProcess__c testStudentProcess = new StudentProcess__c(Student__c = testContact1.Id);
        insert testStudentProcess;
        
        EmailAddress__c emailAddressObj = new EmailAddress__c(Email__c = 'qanewobj@qanewobj.qanewobj1', Contact__c = testContact1.Id);
        insert emailAddressObj;
             
  
        // setup the data for the email
        email.subject = 'Crazy Subject Line [ @!$1234567890123456789 ]';
        email.fromname = 'WillSlayed';
        email.htmlBody = '<br><b>This is the email body @!$654654654654654$!@' + testStudentProcess.Id + '</b><br> ref:999999999_999999999:ref';
        email.fromAddress = 'wslayed1@wgu.edu';
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
        email.headers=new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;
        
        EmailAddress__c ea = new EmailAddress__c(Contact__c = TestContact1.Id, Email__c = 'wslayed1@wgu.edu');
        insert ea;
       
        id[] fixedSearchResults = new id[2];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        Test.setFixedSearchResults(fixedSearchResults);
  
        // Use startTest and stopTest to break up calls to not exceed query limits
        Test.startTest();
            
        insert testUser;
        User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
        
        System.runAs( sysAdmin ) 
        {           
            AcademicServicesEmailHandler emailHandler1 = new AcademicServicesEmailHandler();                
            emailHandler1.handleInboundEmail(email, env);
                 
        }
          
        Test.stopTest();     
        
        List<Case> newCases = [SELECT Id FROM Case LIMIT 1];
        System.assert(newCases.size() == 1, 'NEWCASES SIZE DOES NOT EQUAL 1 AFTER TEST.STOPTEST()');                   
    }
}