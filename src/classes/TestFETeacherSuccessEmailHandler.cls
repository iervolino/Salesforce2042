/*
 * Author Brad King
 * Western Governors University 
 *
 * Date April 2 2013
 * 
 * Test EmailHandlers  
 * Revisions: 
 *    - 8/15/13 Carolyn Coronado and Yemeng Zhu. Copy from TestStudentConcernEmailHandler. 
 */

@isTest
private with sharing class TestFETeacherSuccessEmailHandler
{
    private static testMethod void testFETeacherSuccessEmailHandlerHTML() 
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
        testContact1.StudentID__c = '123456789';   
             
        testContact2.FirstName = 'Willtest1';
        testContact2.Lastname = 'Slayedtest1';
        testContact2.Email = 'wslayed@my.wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
        
       ///create student concern
         StudentDisposition__c scon=new StudentDisposition__c( Name ='test',Student__c = testContact1.id ,StudentID__c=testContact1.studentID__c);
        insert scon;
  
        // setup the data for the email
        email.subject = 'Html test case';
        email.fromname = 'Will Slayed';
        email.htmlBody = '<br><b>This is the email body <br>concernid: '+scon.id +' <br></b><br> ';
        email.fromAddress = 'wslayed@wgu.edu';
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
        email.headers=new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;     
       
        // attachment
        Messaging.InboundEmail.BinaryAttachment efa = new Messaging.InboundEmail.BinaryAttachment ();
        efa.FileName='attachment.pdf';
        efa.Body=Blob.valueof('email attachment body');
        email.BinaryAttachments= new Messaging.InboundEmail.BinaryAttachment[] {efa} ;
        
        id[] fixedSearchResults = new id[2];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        Test.setFixedSearchResults(fixedSearchResults);
  
       // Use startTest and stopTest to break up calls to not exceed query limits
       Test.startTest();     
        insert testUser;
         
       User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
       
       System.runAs( sysAdmin ) {
           
             FETeacherSuccessEmailHandler emailHandler5 = new FETeacherSuccessEmailHandler();
             emailHandler5.handleInboundEmail(email, env);
              
              System.assert([select Id,description from task where whatid= :scon.id].size()==1);
              System.assert([select Id,description from task where whatid= :scon.id][0].description.indexOf('This is the email body')!=-1); 
              System.assert([select id from attachment  ].size()==1);
               
        //NEED ASSERTION HERE
          
      }
  
      Test.stopTest();
      
    }
    
    
    
    private static testMethod void testStudentConcernEmailHandlerTEXT()
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
        testContact1.StudentID__c = '123456789'; 
             
        testContact2.FirstName = 'Willtest1';
        testContact2.Lastname = 'Slayedtest1';
        testContact2.Email = 'wslayed@my.wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
      
        
        ///create student concern
        StudentDisposition__c scon=new StudentDisposition__c( Name ='test',Student__c = testContact1.id ,StudentID__c=testContact1.studentID__c);
        insert scon;
        
             
  
        // setup the data for the email
        email.subject = 'Html test case';
        email.fromname = 'Will Slayed';
        email.plainTextBody= '\n\n This is the email body \nconcernid: '+scon.id +'\n\n\n ';
        email.fromAddress = 'wslayed@wgu.edu';
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
        email.headers=new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;     
       
       // attachment
        Messaging.InboundEmail.TextAttachment efa = new Messaging.InboundEmail.TextAttachment ();
        efa.FileName='attachment.pdf';
        efa.Body='email attachment body';
        email.TextAttachments= new Messaging.InboundEmail.TextAttachment[] {efa} ;
        
        
        id[] fixedSearchResults = new id[2];
        fixedSearchResults[0] = testContact1.Id;
        fixedSearchResults[1] = testContact2.Id;
        Test.setFixedSearchResults(fixedSearchResults);
  
       // Use startTest and stopTest to break up calls to not exceed query limits
       Test.startTest();   
        insert testUser;
         
       User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
       
       System.runAs( sysAdmin ) {
           
             FETeacherSuccessEmailHandler emailHandler5 = new FETeacherSuccessEmailHandler();
             emailHandler5.handleInboundEmail(email, env);
              
              System.assert([select Id,description from task where whatid= :scon.id].size()==1);
              System.assert([select Id,description from task where whatid= :scon.id][0].description.indexOf('This is the email body')!=-1); 
              System.assert([select id from attachment  ].size()==1);
               
        //NEED ASSERTION HERE
          
      }
  
      Test.stopTest();
      
    }
    
    
    
    private static testMethod void testStudentConcernEmailHandlerWithoutConcernID()
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
        testContact1.StudentID__c = '123456789';  
             
        testContact2.FirstName = 'Willtest1';
        testContact2.Lastname = 'Slayedtest1';
        testContact2.Email = 'wslayed@my.wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
      
        
        ///create student concern
         StudentDisposition__c scon=new StudentDisposition__c( Name ='test',Student__c = testContact1.id,StudentID__c=testContact1.studentID__c );
        insert scon;
        
             
  
        // setup the data for the email
        email.subject = 'null test case';
        email.fromname = 'Will Slayed';
        email.htmlBody = '<br><b>This is the email body  <br>something without id </b><br> ';
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
  
       // Use startTest and stopTest to break up calls to not exceed query limits
       Test.startTest();   
        insert testUser;
         
       User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
       
       System.runAs( sysAdmin ) {
           
             FETeacherSuccessEmailHandler emailHandler5 = new FETeacherSuccessEmailHandler();
             emailHandler5.handleInboundEmail(email, env);
              
              //System.assert([select id from task].size()==0);
              System.assert([select Id  from case].size()==1);
              System.assert([select Id,subject from case][0].subject=='null test case' ); 
              
               
        //NEED ASSERTION HERE
          
      }
  
      Test.stopTest();
      
    }
    
    
    private static testMethod void testStudentConcernEmailHandlerWithWrongConcernID()
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
        testContact1.StudentID__c = '123456789';    
             
        testContact2.FirstName = 'Willtest1';
        testContact2.Lastname = 'Slayedtest1';
        testContact2.Email = 'wslayed@my.wgu.edu';
        testContact2.PIDM__c = 'EMQAPIDM2';
        testContacts.add(testContact1);
        testContacts.add(testContact2);
        insert testContacts;
        
      
        
        ///create student concern
        StudentDisposition__c scon=new StudentDisposition__c( Name ='test',Student__c = testContact1.id,StudentID__c=testContact1.studentID__c );
        insert scon;
        
             
  
        // setup the data for the email
        email.subject = 'wrong test case';
        email.fromname = 'Will Slayed';
        email.htmlBody = '<br><b>This is the email body  <br>concernid:xxxxx</b><br> ';
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
  
       // Use startTest and stopTest to break up calls to not exceed query limits
       Test.startTest();
         
       User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
       
       System.runAs( sysAdmin ) {   
        insert testUser;
           
             FETeacherSuccessEmailHandler emailHandler5 = new FETeacherSuccessEmailHandler();
             emailHandler5.handleInboundEmail(email, env);
              
              //System.assert([select id from task].size()==0); 
              System.assert([select Id  from case].size()==1);
              System.assert([select Id,subject from case][0].subject =='wrong test case'); 
               
        //NEED ASSERTION HERE
          
      }
  
      Test.stopTest();  
      
    }
    
}