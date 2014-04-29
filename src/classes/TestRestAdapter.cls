/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date June 1, 2013 @ 1506 hrs
 * Revised: Added testQueryAll method
 * 
 * Date January 30, 2013 @ 1033 hrs
 * Revised: Person Account Refactor 
 * 
 * Date Nov 3 2012 @ 1230 hrs
 * Revised: (security audit compliance: with sharing and SeeAllData=false) 
 * 
 * Test the RestAdapter class (REST And SOAP API Wrapper functions)
 *
 */
@isTest(SeeAllData=false) 
private with sharing class TestRestAdapter {

    static testmethod void testRestAdapterAsGuest()   {
        User guestUser = [SELECT count() FROM User WHERE UserType = 'Guest' and isActive = true]==0? [SELECT Id FROM User WHERE Profile.Name ='NoAccess' AND isActive = true LIMIT 1] : [SELECT Id FROM User WHERE UserType = 'Guest' AND isActive = true LIMIT 1];
        System.runAs(guestUser) {
          try {
            RestAdapter adapter = new RestAdapter();
          } catch ( RestException re ) {
            System.assert( re.getMessage() == 'NOT AUTHORIZED' );
          }
        }
        
    }
    
            
    static testmethod void testQueryAll() {
      User mentorUser = [Select Id, Username  From User where IsActive = true AND ProfileId in (select id from Profile where Name = 'Student Profile') LIMIT 1];
      System.runAs(mentorUser) {
          RestAdapter a = new RestAdapter();
          List<Task> objs = (List<Task>)a.queryAllObjects( 'SELECT Id, WhatId, Subject, IsClosed, TemplateId__c, CardIndex__c, SortOrder__c, Status FROM Task where Whatid=\'a0T30000005x27v\' AND TemplateId__c != null AND isDeleted = false ORDER BY SortOrder__c ASC LIMIT 100' );
          System.assert( objs.size() > 0 );
      }
    }
    
    static testmethod void testRestAdapterAsMentor()   {
        RestException ex = new RestException();
        User mentorUser = [Select Id, Username  From User where IsActive = true AND ProfileId in (select id from Profile where Name = 'Mentor') LIMIT 1];
        System.runAs(mentorUser) {
           
          RestAdapter adapter;
          try {
            adapter = new RestAdapter();
          } catch ( RestException re ) {
            System.assert( re.getMessage() == 'NOT AUTHORIZED' );
          }
        }
    }
    
    static testmethod void testRestAdapterExceptions()   {
        TestStudentUser.setupStudentTestData();
        User studentUser = TestStudentUser.getTestStudentUser();
        Account studentAccount = TestStudentUser.getTestStudentAccount();

        System.runAs(TestStudentUser.getSAdminUser()) {
	        Test.startTest();
	
	        RestAdapter adapter;
	        try {
	          adapter = new RestAdapter();
	        } catch ( RestException re ) {
	          System.assert( re.getMessage() != 'NOT AUTHORIZED' );
	        }
	        
	        ApexClass apexClassObj = [SELECT ID from ApexClass LIMIT 1];
	        ID illegalId = [SELECT Id, Name from Profile where NAME = 'Student Profile'].id ;
	                
	        try {
	          adapter.getSObject( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception') );    
	        }
	        
	        try {
	          adapter.getSObject( apexClassObj ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.getSObject( new Profile(id=illegalId) ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.describe( apexClassObj ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.describe( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception') );    
	        }
	        
	        try {
	          adapter.updateObject( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception') );    
	        }
	        
	        try {
	          adapter.updateObject( apexClassObj ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.updateObject( [Select ID from User where id != :studentUser.Id LIMIT 1] ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.updateObject( [Select ID from Account where ID IN (Select AccountId from User where AccountId = :studentAccount.Id ) LIMIT 1] ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.updateObject( [Select ID from Contact where ID IN (Select ContactId from User where AccountId = :studentAccount.Id ) LIMIT 1] ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.deleteObject( apexClassObj ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.deleteObject( new Account() ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception') );    
	        }
	        
	        try {
	          adapter.deleteObject( [Select ID from Account where ID IN (Select AccountId from User where AccountId = :studentAccount.Id ) LIMIT 1]  ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.deleteObject( [Select Id from User where id = :studentUser.Id LIMIT 1] ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.deleteObject( [SELECT id from Case LIMIT 1] ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        } catch (QueryException qe) {
	          System.assert( qe.getMessage().contains('List has no rows for assignment to SObject') );    
	        }
	        
	        try {
	          adapter.deleteObject( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception') );    
	        }
	        
	        try {
	          adapter.createObject( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception') );    
	        }
	        
	        try {
	          adapter.createObject( [Select Id from States__c LIMIT 1] ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('CANNOT CREATE AN OBJECT THAT ALREADY HAS AN ID') );    
	        }
	        
	        try {
	          adapter.createObject( apexClassObj ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.createObject( new Account() ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.createObject( new Contact() ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.createObject( new User() ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.createObject( new KeyValue__c() ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.queryObjects( illegalId ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.queryObjects( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('Must supply a valid query string') );    
	        }
	        
	        try {
	          adapter.search( illegalId ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED') );    
	        }
	        
	        try {
	          adapter.search( null ); 
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('Must supply a valid search string') );    
	        }
	        
	        Test.stopTest();
        }
    }
        
     static testmethod void testRestAdapterFabrications() {
        TestStudentUser.setupStudentTestData();
        User studentUser = TestStudentUser.getTestStudentUser();
        
        	
        System.runAs(TestStudentUser.getSAdminUser()) {
	        
	        Test.startTest();
	        
	        RestAdapter adapter;
	        try {
	          adapter = new RestAdapter();
	        } catch ( RestException re ) {
	          System.assert( re.getMessage() != 'NOT AUTHORIZED' );
	        }
	     
	        //NOTE: in testing outbound messaging, all responses are fabricated
	        List<StudentAttributes__c> attrs = adapter.queryObjects('SELECT ID, Name from StudentAttributes__c LIMIT 1');
	        System.assert( attrs.size() == 1 );
	        String jsonString = JSON.serialize( attrs );
	        System.assert( adapter.queryObjects('SELECT ID, Name from StudentAttributes__c LIMIT 1').size() == 1 );
	        System.assert( adapter.describe( new StudentAttributes__c() ).contains('"name" : "StudentAttributes__c",') ); //meta description of objectType
	        System.assert( adapter.query('SELECT ID, Name from StudentAttributes__c LIMIT 1').contains('"totalSize" : 1,') ); //same as queryObjects, but returns JSON string
	        System.assert( adapter.search('FIND {doggone} IN ALL FIELDS RETURNING StudentAttributes__c').contains('[') );
	        System.assert( adapter.recent().contains('[') ); //retrieve recent objects list
	               jsonString = adapter.createObjects( attrs ); //do not set id field
	        System.assert( jsonString.contains('<success>true') );
	               jsonString = adapter.createObject( new StudentAttributes__c( Name=studentUser.Name, Affiliation__c='WGU',Nickname__c='Johnny Be Good') ); //do not set id field
	               List<SObject> objs = (List<SObject>)RestAdapter.getListFromJSON( jsonString );
	        System.assert( jsonString.contains('"success" : true') );
	            JSONParser parser = JSON.createParser(jsonString);
	            ID newID;
	            while (parser.nextToken() != null) {
	                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
	                    (parser.getText() == 'id')) {
	                         parser.nextToken();
	                         newID = parser.getIdValue();
	                         System.debug(newId);        
	                         break;
	                }
	            }    
	        System.assert( adapter.getSObject( new FieldExperience__c() ).contains('"type" : "FieldExperience__c",') ); 
	        System.assert( adapter.getSObject( new StudentAttributes__c(id=newID) ).contains('"type" : "StudentAttributes__c",') ); 
	        System.assert( adapter.updateObject( new StudentAttributes__c(id=newID,Name='Changling')).contains('[ ]') ); //update by id
	        System.assert( adapter.deleteObject( new StudentAttributes__c(id=newID)).contains('[ ]') ); //delete by id 
	 
	        List<KeyValue__c> keyvalues = new List<KeyValue__c>();
	        keyvalues.add( new KeyValue__c(Name='1',Value__c='paultest') );
	        keyvalues.add( new KeyValue__c(Name='2',Value__c='paultest') );
	        String resultSoapXML = adapter.createObjects( keyvalues );
	        System.assert( resultSoapXML.contains ('success'), 'TEST of SOAP CALL createObjects did NOT contain the word "success"' );
	
	        //all frabricated callouts return static XML or JSON, therefore tests are really only grabbing code coverage
	        adapter.convertAttachmentToChatterFile(null);
	        adapter.getUserValidationSessionId();
	        RestAdapter.encryptUVPassword();
	        RestAdapter.encryptRestAdapterPassword();
	        adapter.setProfilePhoto( studentUser.Id, '1234' );
	        
	        Test.stopTest();
        }

    }

    static testmethod void testRestAdapterSoapCalls() {
    
        TestStudentUser.setupStudentTestData();

        System.runAs(TestStudentUser.getSAdminUser()) {
	        
	        Test.startTest();
	        
	        RestAdapter adapter;
	        try {
	          adapter = new RestAdapter();
	        } catch ( RestException re ) {
	          System.assert( re.getMessage() != 'NOT AUTHORIZED' );
	        }
	
	        List<StudentAttributes__c> attribs = new List<StudentAttributes__c>();
	        attribs.add( new StudentAttributes__c() );
	        try {
	          adapter.createObjects(null);
	        } catch (RestException e) {
	            System.assert( e.getMessage().contains('NULL Value Exception' ) ); 
	        }
	        try {
	          List<Account> accounts = new List<Account>();
	          accounts.add( new Account());
	          adapter.createObjects(accounts);
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED' ) ); 
	        }
	        adapter.createObjects(attribs);
	        try {
	          adapter.updateObjects(null);
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NULL Value Exception' ) ); 
	        }
	        try {
	            List<Account> accounts = new List<Account>();
	            accounts.add( new Account());
	          adapter.updateObjects(accounts);
	        } catch (RestException e) {
	          System.assert( e.getMessage().contains('NOT AUTHORIZED' ) ); 
	        }
	        adapter.updateObjects([select id from StudentCompletionTask__c limit 10]);
	        
	        Test.stopTest();
        } 
    }   
}