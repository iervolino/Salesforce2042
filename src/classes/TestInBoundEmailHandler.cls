/*
 * Author Will Slade
 * Western Governors University 
 *
 * Date May 1 2012
 * 
 * Revised: Dec 21, 2012 @1110 hrs, by Paul Coleman
 * Broke up the test methods into one test for each Handler type
 * 
 * Test EmailHandlers  
 *
 */

@isTest
private with sharing class TestInBoundEmailHandler
{
    private static testMethod void testInBoundEmailHandler()
    {
        // All other tests have been separated into their own classes.
        // This class aims to cover code not covered by all other classes.

        // Scenario to cover is that the email is coming from an LRV Account, and no Contact is found.
        
        // Create LRV Account--This Account does not have a Contact associated with it
        Account acct = new Account();
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE sObjectType='Account' AND DeveloperName='LearningResourcesVendor' LIMIT 1];
        acct.RecordTypeId = rt.Id;
        acct.Name = 'TestInBoundEmailHandler';
        acct.AccountEmail__c = 'test.account@gmail.com';
        insert acct;
        
        System.assert(acct.Id != null, 'Account is null');
        
        // Create a Student Contact to which this email is to be sent--Shouldn't matter if there is an Account with Contact. For now we won't have one
        Contact cntct = new Contact();
        rt = [SELECT Id, Name FROM RecordType WHERE sObjectType='Contact'  AND DeveloperName='StudentRecord' LIMIT 1];
        cntct.RecordTypeId = rt.Id;
        cntct.Email = 'test.student@wgu.edu';
        cntct.FirstName = 'Te';
        cntct.LastName = 'st';
        insert cntct;
        
        System.assert(cntct.Id != null, 'Contact is null.');
        
        // Compose the email to be sent
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
  
        // Populate the email
        email.subject = '';
        email.fromname = '';
        email.htmlBody = '';
        email.fromAddress = acct.AccountEmail__c;
        email.toAddresses = new String[] {cntct.Email};
        Messaging.InboundEmail.Header hditem = new Messaging.InboundEmail.Header();        
        email.headers = new Messaging.InboundEmail.Header[1];
        hditem.name = 'Date';
        hditem.value = 'Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0] = hditem;
        
        Id[] fixedSearchIds = new Id[] {acct.Id};
  
          
       // Use startTest and stopTest to break up calls to not exceed query limits
       Test.startTest();
         
           User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
           
           System.runAs( sysAdmin )
           {
               Test.setFixedSearchResults(fixedSearchIds);
               LearningResourceEmailHandler emailHandler = new LearningResourceEmailHandler();
               emailHandler.handleInboundEmail(email, env);
               
               // NEED ASSERTION HERE
           }
  
        Test.stopTest();
    }
}