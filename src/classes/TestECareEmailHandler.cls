/*
 * Author Brad King
 * Western Governors University 
 *
 * Date April 2 2013
 * 
 * Test EcareEmailHandler
 *
 */

@isTest
private with sharing class TestECareEmailHandler
{      
    private static testMethod void testECareEmailHandler()
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
        
        RecordType studentrt = [SELECT Id, Name From RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'StudentRecord'];
  
        testContact1.FirstName = 'Magdalene';
        testContact1.Lastname = 'Williams';
        testContact1.Email = 'mwill75@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';
        testContact1.StudentID__c = '000234952';
        testContact1.RecordTypeId = studentrt.Id;
             
        testContact2.FirstName = 'Brad';
        testContact2.Lastname = 'King';
        testContact2.Email = 'brad.king@wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContact2.StudentID__c = '123456789';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
        System.assert(testContact1.Id != NULL, 'TestECareEmailHandler: TestContact1.id IS NULL');
  
        // setup the data for the email
        email.subject = 'This Email came in from TestECare Email Handler';
        email.fromname = 'Notification@TaskStream.com';        
        email.plainTextBody = 'This is a notification that the following person has requested support. Do not reply to this email.\n\n';
        email.plainTextBody += 'Student name: Magdalene Williams\n';
        email.plainTextBody += 'Student ID: 000234952\n';
        email.plainTextBody += 'Time Zone: pacific\n';
        email.plainTextBody += 'Phone: 347 251 6215, (5pm - 6:30pm)\n';
        email.plainTextBody += 'Email: mwill78@my.wgu.edu\n\n';
        email.plainTextBody += 'Program: JTT2 Issues in Ed Research (V2 GRADUATE-1010)-PA\n\n';
        email.plainTextBody += 'DRF Category/Requirement: Issues in Educational Research: JTT Task 1\n\n';
        email.plainTextBody += 'Category of request:\n';
        email.plainTextBody += '* Guidance for accessing resources to gain competency\n';
        email.plainTextBody += '* Feedback Clarification\n';
        email.plainTextBody += '* Other\n\n';
        email.plainTextBody += 'Description: I need clarification on section D \"interrelationships of data analysis, study results and conclusion. JTT2 Task1\n 2nd line of description \n 3rd line of description \n the description should be able to handle multiple lines.\n';
        
        email.fromAddress = 'notification@taskstream.com';
        Messaging.InboundEmail.Header hditem = new Messaging.InboundEmail.Header();
        email.headers = new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;
        
        QueueSObject q = [SELECT QueueId, sObjectType FROM QueueSObject WHERE Queue.Name = 'ECare' LIMIT 1];
       
        id[] fixedSearchResults = new id[3];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        fixedSearchResults[2] = q.QueueId;
        Test.setFixedSearchResults(fixedSearchResults);
  
        // Use startTest and stopTest to break up calls to not exceed query limits
        Test.startTest();  
        insert testUser;
        
        User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
        
        System.runAs( sysAdmin )
        {
            ECareEmailHandler emailHandler5 = new ECareEmailHandler();
            emailHandler5.handleInboundEmail(email, env);
            //NEED ASSERTION HERE
            List<Case> cases = [SELECT Id, ContactId, Subject, ECareDRF__c,ECareTask__c, SuppliedPhone, StudentComments__c, Reason, Status, OwnerId FROM Case];
            
            for(Case ccc : cases)
                System.debug('=====>:\t' + ccc);
            
            System.assert(cases.size() > 0, 'There were no cases :(');
            System.assert(!(cases.size() > 1), 'There was more than one case :(');
            System.assert(cases.size() == 1, 'There should only be one case--there was 0 or more than 1');
            System.assert(cases[0].OwnerId == q.QueueId, 'Queue IDs didn\'t match');
            System.assert(cases[0].StudentComments__c.toLowercase().indexOf('2nd line')!=-1);
            System.assert(cases[0].SuppliedPhone.toLowercase().indexOf('pacific')!=-1);
            System.assert(cases[0].SuppliedPhone.toLowercase().indexOf('347 251 6215')!=-1);
		}
       
       Test.stopTest();
    }
    
    
    private static testMethod void testECareEmailHandlerHTML()
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
        
        RecordType studentrt = [SELECT Id, Name From RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'StudentRecord'];
  
        testContact1.FirstName = 'Magdalene';
        testContact1.Lastname = 'Williams';
        testContact1.Email = 'mwill75@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';
        testContact1.StudentID__c = '000234952';
        testContact1.RecordTypeId = studentrt.Id;
             
        testContact2.FirstName = 'Brad';
        testContact2.Lastname = 'King';
        testContact2.Email = 'brad.king@wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContact2.StudentID__c = '123456789';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
        System.assert(testContact1.Id != NULL, 'TestECareEmailHandler: TestContact1.id IS NULL');
  
        // setup the data for the email
        email.subject = 'This Email came in from TestECare Email Handler';
        email.fromname = 'Notification@TaskStream.com';        
        email.htmlBody = 'This is a notification that the following person has requested support. Do not reply to this email.<br><br>';
        email.htmlBody += 'Student name: Magdalene Williams<br>';
        email.htmlBody += 'Student ID: 000234952<br>';
        email.htmlBody += 'Time Zone: pacific<br>';
        email.htmlBody += 'Phone: 347 251 6215, (5pm - 6:30pm)<br>';
        email.htmlBody += 'Email: mwill78@my.wgu.edu<br><br>';
        email.htmlBody += 'Program: JTT2 Issues in Ed Research (V2 GRADUATE-1010)-PA<br><br>';
        email.htmlBody += 'DRF Category/Requirement: Issues in Educational Research: JTT Task 1<br><br>';
        email.htmlBody += 'Category of request:<br>';
        email.htmlBody += '* Guidance for accessing resources to gain competency<br>';
        email.htmlBody += '* Feedback Clarification\n';
        email.htmlBody += '* Other<br><br>';
        email.htmlBody += 'Description: I need clarification on section D \"interrelationships of data analysis, study results and conclusion. JTT2 Task1<br> 2nd line of description <br> 3rd line of description <br> the description should be able to handle multiple lines.<br>';
        
        email.fromAddress = 'notification@taskstream.com';
        Messaging.InboundEmail.Header hditem = new Messaging.InboundEmail.Header();
        email.headers = new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;
        
        QueueSObject q = [SELECT QueueId, sObjectType FROM QueueSObject WHERE Queue.Name = 'ECare' LIMIT 1];
       
        id[] fixedSearchResults = new id[3];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        fixedSearchResults[2] = q.QueueId;
        Test.setFixedSearchResults(fixedSearchResults);
  
        // Use startTest and stopTest to break up calls to not exceed query limits
        Test.startTest();
           
        insert testUser;
        User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
        
        System.runAs( sysAdmin )
        {
            ECareEmailHandler emailHandler5 = new ECareEmailHandler();
            emailHandler5.handleInboundEmail(email, env);
            //NEED ASSERTION HERE
            List<Case> cases = [SELECT Id, ContactId, Subject, ECareDRF__c,ECareTask__c, SuppliedPhone, StudentComments__c, Reason, Status, OwnerId FROM Case];
            
            for(Case ccc : cases)
                System.debug('=====>:\t' + ccc);
            
            System.assert(cases.size() > 0, 'There were no cases :(');
            System.assert(!(cases.size() > 1), 'There was more than one case :(');
            System.assert(cases.size() == 1, 'There should only be one case--there was 0 or more than 1');
            System.assert(cases[0].OwnerId == q.QueueId, 'Queue IDs didn\'t match');
            System.assert(cases[0].StudentComments__c.toLowercase().indexOf('2nd line')!=-1);
            System.assert(cases[0].SuppliedPhone.toLowercase().indexOf('pacific')!=-1);
            System.assert(cases[0].SuppliedPhone.toLowercase().indexOf('347 251 6215')!=-1);
		}
       
       Test.stopTest();
    }
    
    
    
    private static testMethod void testECareEmailHandlerNotFromNotificationAtTaskstreamDotCom()
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
        
        RecordType studentrt = [SELECT Id, Name From RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'StudentRecord'];
  
        testContact1.FirstName = 'Magdalene';
        testContact1.Lastname = 'Williams';
        testContact1.Email = 'mwill75@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';
        testContact1.StudentID__c = '000234952';
        testContact1.RecordTypeId = studentrt.Id;
             
        testContact2.FirstName = 'Brad';
        testContact2.Lastname = 'King';
        testContact2.Email = 'brad.king@wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContact2.StudentID__c = '123456789';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
        System.assert(testContact1.Id != NULL, 'TestECareEmailHandler: TestContact1.id IS NULL');
  
        // setup the data for the email
        email.subject = 'This Email came in from TestECare Email Handler';
        email.fromname = 'Notification@TaskStream.com';        
        email.htmlBody = 'This is a notification that the following person has requested support. Do not reply to this email.<br><br>';
        email.htmlBody += 'Student name: Magdalene Williams<br>';
        email.htmlBody += 'Student ID: 000234952<br>';
        email.htmlBody += 'Time Zone: pacific<br>';
        email.htmlBody += 'Phone: 347 251 6215, (5pm - 6:30pm)<br>';
        email.htmlBody += 'Email: mwill78@my.wgu.edu<br><br>';
        email.htmlBody += 'Program: JTT2 Issues in Ed Research (V2 GRADUATE-1010)-PA<br><br>';
        email.htmlBody += 'DRF Category/Requirement: Issues in Educational Research: JTT Task 1<br><br>';
        email.htmlBody += 'Category of request:<br>';
        email.htmlBody += '* Guidance for accessing resources to gain competency<br>';
        email.htmlBody += '* Feedback Clarification\n';
        email.htmlBody += '* Other<br><br>';
        email.htmlBody += 'Description: I need clarification on section D \"interrelationships of data analysis, study results and conclusion. JTT2 Task1<br> 2nd line of description <br> 3rd line of description <br> the description should be able to handle multiple lines.<br>';
        
        email.fromAddress = 'someotherEmail@wgu.edu';
        Messaging.InboundEmail.Header hditem = new Messaging.InboundEmail.Header();
        email.headers = new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;
        
        QueueSObject q = [SELECT QueueId, sObjectType FROM QueueSObject WHERE Queue.Name = 'ECare' LIMIT 1];
       
        id[] fixedSearchResults = new id[3];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        fixedSearchResults[2] = q.QueueId;
        Test.setFixedSearchResults(fixedSearchResults);
  
        // Use startTest and stopTest to break up calls to not exceed query limits
        Test.startTest();   
        insert testUser;
        
        User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
        
        System.runAs( sysAdmin )
        {
            ECareEmailHandler emailHandler5 = new ECareEmailHandler();
            emailHandler5.handleInboundEmail(email, env);
            //NEED ASSERTION HERE
            List<Case> cases = [SELECT Id, ContactId, Subject, ECareDRF__c,ECareTask__c, SuppliedPhone, StudentComments__c, Reason, Status, OwnerId FROM Case];
            
            for(Case ccc : cases)
                System.debug('=====>:\t' + ccc);
            
            System.assert(cases.size() > 0, 'There were no cases :(');
            System.assert(!(cases.size() > 1), 'There was more than one case :(');
            System.assert(cases.size() == 1, 'There should only be one case--there was 0 or more than 1');
           /* System.assert(cases[0].OwnerId == q.QueueId, 'Queue IDs didn\'t match');
            System.assert(cases[0].StudentComments__c.toLowercase().indexOf('2nd line')!=-1);
            System.assert(cases[0].SuppliedPhone.toLowercase().indexOf('pacific')!=-1);
            System.assert(cases[0].SuppliedPhone.toLowercase().indexOf('347 251 6215')!=-1);*/
		}
       
       Test.stopTest();
    }
}