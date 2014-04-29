/*
 * Authors Brad King
 * Western Governors University 
 *
 * Date April 19 2013
 * 
 * Test EmailHandlers  
 *
 * Revised by Joey Day, February 24 2014, to account for SCRFConnector for Remedyforce
 * 
 */

@isTest
private with sharing class TestITHelpDeskEmailHandler
{      
    private static testMethod void testITHelpDeskEmailHandler()
    {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        User testUser = new User();
        Contact testContact1 = new Contact();
        Contact testContact2 = new Contact();
        List<Contact> testContacts = new List<Contact>();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Field Experiences User' LIMIT 1].Id;
        
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
        testContact1.Email = 'wslayed@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';
             
        testContact2.FirstName = 'Willtest1';
        testContact2.Lastname = 'Slayedtest1';
        testContact2.Email = 'wslayed@my.wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
        System.assert(testContact1.Id != NULL, 'testScholarshipEmailHandler: TestContact1.id IS NULL');
        
        Date oppCloseDate = date.valueOf('2012-10-02');
        Opportunity testOpp = new Opportunity(name = 'Opp Case Feed Tester43', StageName = 'Applicant', CloseDate = oppCloseDate);
        insert testOpp;
        
        User testMentor = [SELECT Id FROM User WHERE UserRole.Name = 'Mentor' AND isActive = true LIMIT 1];
        FieldExperience__c testFE = new FieldExperience__c(Name = 'FE Case Feed Tester43', Student__c = testContact1.Id);
        insert testFE;
        testFE.Mentor__c = testMentor.Id;
        update testFE;
        
        FieldExperienceProcess__c testFEP = new FieldExperienceProcess__c(Name = 'FEP Case Feed Tester43', FieldExperience__c = testFE.Id);
        insert testFEP;
        
        EmailAddress__c emailAddressObj = new EmailAddress__c(Email__c = 'qanewobj@qanewobj.qanewobj1', Contact__c = testContact1.Id);
        insert emailAddressObj;
             
        insert testUser;
          
        // setup the data for the email
        email.subject = 'Crazy Subject Line [ ref:999999999_999999999:ref ]';
        email.fromname = 'Will Slayed';
        email.htmlBody = '<br><b>This is the email body @!$654654654654654654$!@' + testFEP.Id + '</b><br> ref:999999999_999999999:ref';
        email.fromAddress = 'wslayed@wgu.edu';
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
        email.headers=new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;        
        
        id[] fixedSearchResults = new id[2];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        // Test SC-RF_Connector Rules
        List<SCRFConnector__Case_Incident_Mapping__c> testRules = new List<SCRFConnector__Case_Incident_Mapping__c>();
        SCRFConnector__Case_Incident_Mapping__c testRule1 = new SCRFConnector__Case_Incident_Mapping__c();
        testRule1.SCRFConnector__Case_Field_API_Name__c = 'Description';
        testRule1.SCRFConnector__Default_Mapping_Not_Required__c = false;
        testRule1.SCRFConnector__Directional_Mapping__c = 'Bi - Directional ( C <-> I)';
        testRule1.SCRFConnector__Incident_Field_API_Name__c = 'BMCServiceDesk__incidentDescription__c';
        testRule1.SCRFConnector__Override_Default_Mapping__c = false;
        testRule1.SCRFConnector__isStandard__c = false;
        SCRFConnector__Case_Incident_Mapping__c testRule2 = new SCRFConnector__Case_Incident_Mapping__c();
        testRule2.SCRFConnector__Case_Field_API_Name__c = 'Subject';
        testRule2.SCRFConnector__Default_Mapping_Not_Required__c = false;
        testRule2.SCRFConnector__Directional_Mapping__c = 'Bi - Directional ( C <-> I)';
        testRule2.SCRFConnector__Incident_Field_API_Name__c = 'BMCServiceDesk__shortDescription__c';
        testRule2.SCRFConnector__Override_Default_Mapping__c = false;
        testRule2.SCRFConnector__isStandard__c = false;
        testRules.add(testRule1);
        testRules.add(testRule2);
        insert testRules;
        
        // Use startTest and stopTest to break up calls to not exceed query limits
        Test.startTest();
        
        User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
        
        System.runAs( sysAdmin ) {
           
            ITHelpDeskEmailHandler emailHandler5 = new ITHelpDeskEmailHandler();
            emailHandler5.handleInboundEmail(email, env);
            //NEED ASSERTION HERE
          
        }
  
        Test.stopTest();
    }
}