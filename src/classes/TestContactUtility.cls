/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date February 11, 2013 @ 1526 hrs
 * Revised: Corrected try/catch blocks for future methods - Paul Coleman 
 * 
 * Date February 4, 2013 @ 1519 hrs
 * Revised: Added test methods for User record creation, WGUDegreeProgram sync, and Mentor PIDM sync - Paul Coleman 
 * 
 * Date January 17, 2013 @ 1536 hrs
 * Revised: (added future method test case) - Paul Coleman
 * 
 * Utility class to support static and @future method calls from Contact object's Trigger and Utility classes
 *
 */
@isTest
private with sharing class TestContactUtility {

  static testmethod void testCreateStudentUserRecordCAREContext() {
    
    String environment = TestStudentUser.getEnvironment();
    
    ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
    ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
    ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
    Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='Dudley', Email='dasterdlytesterson@'+environment+'.wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId );
    String[] emailParts = student.Email.split('@');
            
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
        
            insert student;
            System.assert( [SELECT count() FROM User WHERE ContactId = :student.Id] == 0, 'CONTACT ALREADY HAS A USER RECORD, before Contact update, User account already exists' );

            student.Status__c = 'IN';
            student.OtherEmail__c = student.Email;
            update student;  
                              
        Test.stopTest();
        
        //Requery Contact to get current Database values (POST Trigger values)
        student = [SELECT Id,Status__c,PIDM__c,FirstName,Email,MailingState,LastName,RecordTypeId,AccountId FROM Contact WHERE Id = :student.Id LIMIT 1];

        //Assert Trigger Operations AFTER future methods return
        System.assert( [SELECT count() FROM User WHERE ContactId = :student.Id] == 1, 'CONTACT TRIGGER FAILURE, after Contact update, User account does not exist' );
        
        User studentUser = TestStudentUser.getTestStudentUser(student.Id);
        System.assert( studentUser.Accountid == student.AccountId,      'CONTACT TRIGGER FAILURE, User.AccountId ('+ User.AccountId +') does not equal Contact.AccountId ('+ student.AccountId +')');
        System.assert( studentUser.FederationIdentifier.startsWith(emailParts[0]), 'CONTACT TRIGGER FAILURE, FederationIdentifier does not start with email part: ' + emailParts[0] );
        System.assert( studentUser.ContactId == student.Id,             'CONTACT TRIGGER FAILURE, User.ContactId ('+ User.ContactId +')does not equal Contact.Id ('+ student.Id +')');
        System.assert( studentUser.Email.startsWith(emailParts[0]),     'CONTACT TRIGGER FAILURE, User.Email does not does not start with email part: ' + emailParts[0] );
        System.assert( studentUser.Username.startsWith(emailParts[0]),  'CONTACT TRIGGER FAILURE, User.Username ('+ studentUser.Username +') does not start with email part ' + emailParts[0] );
        System.assert( studentUser.LastName.equals(student.LastName),   'CONTACT TRIGGER FAILURE, User.LastName does not equal Contact.LastName ('+ student.LastName +')');
        System.assert( studentUser.FirstName.equals(student.FirstName), 'CONTACT TRIGGER FAILURE, User.FirstName does not equal Contact.FirstName ('+ student.FirstName +')');
        System.assert( studentUser.ProfileId == studentProfileID,       'CONTACT TRIGGER FAILURE, User.ProfileId does not equal Student Profile ('+ studentProfileID +')');
        System.assert( studentUser.PIDM__c.equals(student.PIDM__c),     'CONTACT TRIGGER FAILURE, User.PIDM__c does not equal Contact.PIDM__c ('+ student.PIDM__c +')');
            
    }
  }
  
  static testmethod void testCreateStudentUserRecordBannerContext() {
    
    String environment = TestStudentUser.getEnvironment();
    
    ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
    ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
    ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
    Contact student = new Contact( Status__c='AS', pidm__c='p002233', firstName='Dudley', Email='dasterdlytesterson@'+environment+'.wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId );
    
      Map<String,Id> recordTypesMap = new Map<String,Id>();
      //get Student record types
      for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) {
        recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
    }
    String recordTypesMapJSON = JSON.serialize(recordTypesMap);

    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
            
            insert student;
            
            //grabbing code coverage
            ContactUtility.createStudentUser(student,null,null,null);
            //grabbing code coverage for Exception block
            try { ContactUtility.createStudentUser(null,null,null,null); } catch ( StudentException e ) {
                System.assert( e.getMessage().startsWith('REQUIRED PARM ERROR'), 'EXCEPTION OF WRONG Message, thrown by ContactUtility.createStudentUser() with NULL Contact ');
            }
        
            System.assert( [SELECT count() FROM User WHERE ContactId = :student.Id] == 0, 'CONTACT ALREADY HAS A USER RECORD, before Contact update, User account already exists' );
            update student;  
                              
        Test.stopTest();

        //Assert Trigger Operations AFTER future methods return
        System.assert( [SELECT count() FROM User WHERE ContactId = :student.Id] == 1, 'CONTACT TRIGGER FAILURE, after Contact update, User account does not exist' );
        
        List<Contact> contactsList = new List<Contact>();
        contactsList.add(student);
        
        //hand off records to future call to force utility to throw System.AsyncException (cannot call future method from within a future method)
        studentUserFutureCall( JSON.serialize(contactsList), recordTypesMapJSON ); 
                          
    }
  }
  
    @future
    private static void studentUserFutureCall( String listNewJSON, String recordTypesMapJSON  ) {
      
        //grabbing code coverage into future call from future call
        try { ContactUtility.createStudentsCustomerUserRecords( listNewJSON, recordTypesMapJSON ); } catch (Exception e) {}
        
    }

  static testmethod void testChangeContactFieldsSyncToAccountTrigger() {
    Contact student = TestStudentUser.getTestStudentContact();
    Account studentAccount = testStudentUser.getTestStudentAccount();
            
    RecordType alumniRecordType = [SELECT Id,DeveloperName FROM RecordType WHERE DeveloperName = 'StudentRecord' AND SObjectType = 'Contact' LIMIT 1];
    String oldRecordTypeName = student.RecordType.DeveloperName;
        
        Map<String,Id> recordTypesMap = new Map<String,Id>();
      //get Student record types
      for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) {
        recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
    }
    String recordTypesMapJSON = JSON.serialize(recordTypesMap);
            
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
            
            System.assert( studentAccount.StudentContact__c == student.Id, 'Contact->Account are NOT linked on StudentContact__c BEFORE UPDATE' );
            System.assert( studentAccount.RecordType.DeveloperName.equals(student.RecordType.DeveloperName), 'Contact->Account Record Type Names are NOT the same BEFORE UPDATE' );
            studentAccount.StudentContact__c = null;
            update studentAccount;
            System.assert( [SELECT StudentContact__c FROM Account WHERE id = :studentAccount.id LIMIT 1].StudentContact__c == null, 'Account.StudentContact__c value NOT reset to NULL BEFORE Contact TRIGGER UPDATE' );
                        
            student.PIDM__c = 'changed';
            Student.FirstName = 'Changed';
            Student.LastName = 'Changed';
            Student.RecordTypeId = alumniRecordType.Id;
            update student;  
                              
        Test.stopTest();
        
        //ASSERT AFTER FUTURE Methods return
        student = [SELECT Id,Name,RecordType.DeveloperName,PIDM__c FROM Contact WHERE id = :student.id LIMIT 1];
        System.debug( LoggingLevel.DEBUG, 'TEST CONTACT AFTER UPDATE in testChangeContactFieldsSyncToAccountTrigger(): ' + JSON.serialize(student));
        studentAccount = [SELECT Name,RecordType.DeveloperName,PIDM__c,StudentContact__c FROM Account WHERE id = :studentAccount.id LIMIT 1];
        System.debug( LoggingLevel.DEBUG, 'TEST ACCOUNT AFTER UPDATE in testChangeContactFieldsSyncToAccountTrigger(): ' + JSON.serialize(studentAccount));
        
        System.assert ( student.RecordType.DeveloperName.equals(alumniRecordType.DeveloperName), 'CONTACT TIGGER FAILURE, Contact('+student.RecordType.DeveloperName+') Record Type Name is NOT correct. Expected ('+alumniRecordType.DeveloperName+')' );
        System.assert ( studentAccount.RecordType.DeveloperName.equals(alumniRecordType.DeveloperName), 'CONTACT TIGGER FAILURE, Contact('+student.RecordType.DeveloperName+')->Account('+studentAccount.RecordType.DeveloperName+') Record Type Names are NOT the same AFTER UPDATE' );
        System.assert ( studentAccount.Name.equals(student.Name), 'CONTACT TIGGER FAILURE, Contact->Account Names are NOT the same AFTER UPDATE Account('+studentAccount.Name+') Contact('+student.Name+')' );
        System.assert ( studentAccount.PIDM__c.equals(student.PIDM__c), 'CONTACT TIGGER FAILURE, Contact('+student.PIDM__c+')->Account('+studentAccount.PIDM__c+') PIDM__c values are NOT the same AFTER UPDATE' );
        System.assert ( studentAccount.StudentContact__c == student.Id, 'CONTACT TIGGER FAILURE, Account.StudentContact__c does NOT equal test Contact\'s Id' );
        
        //grabbing code coverage into synchronous block by calling future from future            
        List<Contact> contactsList = new List<Contact>();
        contactsList.add(student);           
        syncContactFieldsToAccountFutureCall(JSON.serialize(contactsList), recordTypesMapJSON);
    }
    
  }


    @future
    private static void syncContactFieldsToAccountFutureCall( String listNewJSON, String recordTypesMapJSON  ) {
      
        //grabbing code coverage into future call from future call
        try { ContactUtility.syncAccountRecordTypeAndPidm( listNewJSON, recordTypesMapJSON ); } catch (Exception e) {}
        
    }

  static testMethod void testCreateStudentContactAndAccountRecords() {
        
    String environment = TestStudentUser.getEnvironment();
    
    ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
    ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
    ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
    Contact studentContact = new Contact( Status__c='AS', pidm__c='p002233', firstName='Dudley', Email='dasterdlytesterson@'+environment+'.wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId );
    
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
            
            insert studentContact;
                        
        Test.stopTest();
        
        Contact studentContactAfterInsert = [select id,accountId,isPersonAccount__c,PIDM__c,Email,MailingState,MailingPostalCode from Contact where id = :studentContact.Id LIMIT 1];
        //Asserting results after all Future methods return
        Account studentAccountAfterInsert = [Select Id, RecordTypeId, PIDM__c, StudentContact__c, StudentContact__r.Id, isPersonAccount__c, StudentContact__r.MailingState, StudentContact__r.Status__c from Account where StudentContact__c = :studentContact.Id LIMIT 1];
        System.assert( studentAccountAfterInsert.isPersonAccount__c == 1, 'NEW Student Account.isPersonAccount__c does not equal 1 (StudentContact__c Assignment Failure)' );
        System.assert( studentAccountAfterInsert.StudentContact__c == studentContact.Id, 'NEW Student Account.StudentContact__c is not correct (StudentContact__c Reference Failure)' );
        System.assert( studentAccountAfterInsert.RecordTypeId == studentAccountRecordTypeId, 'NEW Student Account.RecordTypeId('+studentAccountAfterInsert.RecordTypeId+') is not correct Expected('+studentAccountRecordTypeId+')' );
                    
        System.assert( studentContactAfterInsert.accountId == studentAccountAfterInsert.Id, 'NEW Student Account.Id DOES NOT equal new StudentContact.accountId after INSERT' );            
        System.assert( studentContactAfterInsert.isPersonAccount__c == true, 'NEW Student Contact.isPersonAccount__c does not equal true (Trigger Field Value Assignment Failure)' );        
    }
    
  }
    
  static testMethod void testCreateStudentUser() {
    
    String environment = TestStudentUser.getEnvironment();
    Long randomI = Crypto.getRandomLong();
    randomI = randomI < 0? randomI*-1: randomI;
    String randomValue = 't'+String.ValueOf(randomI);
    randomValue = randomValue.length() > 18? randomValue.substring(0,17): randomValue;
    ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'ProspectRecord' and SObjectType = 'Contact'].id;
    ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
    Contact studentContact = new Contact( Status__c='IN', OtherEmail__c='dasterdlytesterson'+randomValue+'@'+randomValue+'.'+environment+'.wgu.edu', firstName='Dudley', WGUEmail__c='dasterdlytesterson'+randomValue+'@'+randomValue+'.'+environment+'.wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId, PIDM__c=randomValue );
    insert studentContact;
    
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
            
             User studentUser = ContactUtility.createStudentUserFromContactId( [SELECT Id FROM Contact WHERE Id = :studentContact.Id LIMIT 1].Id );
             insert studentUser;
                                         
        Test.stopTest();
        
             string expectedEmail = studentContact.WGUEmail__c.split('@')[0]+'@wgu.edu' + (environment != 'prod' ? '.'+environment : '');
             System.assert( studentUser.Email == expectedEmail, 'Create Student User Test Error. Expected User.Email of [' +expectedEmail+ '] but found ['+ studentUser.Email+']' );
             System.assert( studentUser.PIDM__c == studentContact.PIDM__c, 'Create Student User Test Error. Expected User.PIDM__c of [' +studentContact.PIDM__c+ '] but found ['+ studentUser.PIDM__c+']' );
             System.debug( 'NEW TEST USER JSON: ' + JSON.serialize(studentUser) );
        
        
    }   
  }
  
  static testMethod void testCreateProspectContactAndAccountRecords() {
        
    String environment = TestStudentUser.getEnvironment();
    
    Long randomI = Crypto.getRandomLong();
    randomI = randomI < 0? randomI*-1: randomI;
    String randomValue = 't'+String.ValueOf(randomI);
    randomValue = randomValue.length() > 18? randomValue.substring(0,17): randomValue;
    ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'ProspectRecord' and SObjectType = 'Contact'].id;
    ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'ProspectRecord' and SObjectType = 'Account'].id;
    ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
    Contact studentContact = new Contact( Status__c='IN', OtherEmail__c='dasterdlytesterson'+randomValue+'@'+randomValue+'.'+environment+'.wgu.edu', firstName='Dudley', Email='dasterdlytesterson'+randomValue+'@'+randomValue+'.'+environment+'.wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId );
    
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
            
                    insert studentContact;
                        
        Test.stopTest();
        
        Contact studentContactAfterInsert = [select id, accountId, isPersonAccount__c from Contact where id = :studentContact.Id LIMIT 1];
        //Asserting results after all Future methods return
        Account studentAccountAfterInsert = [Select Id, RecordTypeId, PIDM__c, StudentContact__c, StudentContact__r.Id, isPersonAccount__c, StudentContact__r.MailingState, StudentContact__r.Status__c from Account where StudentContact__c = :studentContact.Id LIMIT 1];
        System.assert( studentAccountAfterInsert.isPersonAccount__c == 1, 'NEW Student Account.isPersonAccount__c does not equal 1 (StudentContact__c Assignment Failure)' );
        System.assert( studentAccountAfterInsert.StudentContact__c == studentContact.Id, 'NEW Student Account.StudentContact__c is not correct (StudentContact__c Reference Failure)' );
        System.assert( studentAccountAfterInsert.RecordTypeId == studentAccountRecordTypeId, 'NEW Student Account.RecordTypeId('+studentAccountAfterInsert.RecordTypeId+') is not correct Expected('+studentAccountRecordTypeId+')' );
                           
        System.assert( studentContactAfterInsert.accountId == studentAccountAfterInsert.Id, 'NEW Student Account.Id DOES NOT equal new StudentContact.accountId after INSERT' );            
        System.assert( studentContactAfterInsert.isPersonAccount__c == true, 'NEW Student Contact.isPersonAccount__c does not equal true (Trigger Field Value Assignment Failure)' );
        
    }
    
  }
    
 
  static testmethod void testStudentSearchHashCreation() {
    
    Contact student = TestStudentUser.getTestStudentContact();
    
    String environment = TestStudentUser.getEnvironment();
    Map<String,Id> recordTypesMap = new Map<String,Id>();
    for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) {
      recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
    }
    String recordTypesMapJSON = JSON.serialize(recordTypesMap);
    
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

       Test.startTest();
       
          //FIRST Assert pre-test conditions, No StudentSearchHash__c record exists and trigger fields are null (SSN AND ITIN). THIS VERIFIES AFTER INSERT TRIGGER DID NOT CREATE THE HASH 
          System.assert( student.SocialSecurityNumber__c == null && student.ITINIndividualTaxIdentificationNumber__c == null, 'SSN HASH CONDITIONS FAILURE, Contact\'s SocialSecurityNumber__c('+student.SocialSecurityNumber__c+') AND ITINIndividualTaxIdentificationNumber__c('+student.ITINIndividualTaxIdentificationNumber__c+') are NOT null before TESTING BEGINS');
          System.assert( [select count() from StudentSearchHash__c where Student__c = :student.id] == 0, 'SSN HASH CONDITIONS FAILURE, Contact('+student.Id+') ALREADY has an StudentSearchHash__c record before TESTING BEGINS');
          
          //Create Trigger conditions by supplying encrypted field values. NOTE: SSN or ITIN must be non-null before a HASH will be created as the SSNHash__c and SSNLastFour__c fields on StudentSearchHash__c are required
          student.DateOfBirth__c = '01/01/1968';
          student.SocialSecurityNumber__c = '444557777';    
          update student;
            
       Test.stopTest();

          //MUST ASSERT ALL RESULTS AFTER Future methods returns
          List<StudentSearchHash__c> existingHashes = [select count() from StudentSearchHash__c where Student__c = :student.id]>0? [select Id, Name, Student__c, StudentAccount__c, SSNHash__c, SSNLastFour__c,BirthDateHash__c from StudentSearchHash__c where Student__c = :student.Id]: new List<StudentSearchHash__c>();
          System.assert( existingHashes.size() == 1, 'CONTACT TRIGGER FAILURE, StudentSearchHash__c did NOT create AFTER UPDATE');
          String expectedHash = EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( student.SocialSecurityNumber__c) ) );
          System.assert(  expectedHash.equals( existingHashes[0].SSNHash__c ), 'STUDENT SEARCH HASH FAILURE, Hashing algorithim on SSN did NOT produce the same results AFTER UPDATE.  Found ('+ existingHashes[0].SSNHash__c +') expected ('+ expectedHash +').');
          String dateStr = Date.parse(student.DateOfBirth__c ).format();
          expectedHash = EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( dateStr  ) ) );
          System.assert( expectedHash.equals( existingHashes[0].BirthDateHash__c ), 'STUDENT SEARCH HASH FAILURE, Hashing algorithim on Data Of Birth did NOT produce the same results AFTER UPDATE.  Found ('+ existingHashes[0].BirthDateHash__c +') expected ('+ expectedHash +').');                
          System.assert(  Integer.ValueOf(student.SocialSecurityNumber__c.substring(5)) == existingHashes[0].SSNLastFour__c, 'STUDENT SEARCH SSN PARSE FAILURE, SSN Parsing algorithim did NOT produce the same results.  Found ('+ existingHashes[0].SSNLastFour__c +') expected ('+ student.SocialSecurityNumber__c.substring(5) +').'); 
          
          List<Contact> contactsList = new List<Contact>();      
          contactsList.add( student );
          
          //hand off records to future call to force utility to throw System.AsyncException (cannot call future method from within a future method)
          ssnFutureCall( JSON.serialize(contactsList), recordTypesMapJSON );            

          //grabbing code coverage into UPDATE block vs. INSERT
          student.DateOfBirth__c = '01/01/1966';
          student.SocialSecurityNumber__c = '444556666';     
          update student;

          
    }
  }
  
  static testmethod void testStudentSearchHashUpdate() {
    
    Contact student = TestStudentUser.getTestStudentContact();
      student.DateOfBirth__c = '01/01/1966';
      student.SocialSecurityNumber__c = '444556666';    
            
    String environment = TestStudentUser.getEnvironment();
    Map<String,Id> recordTypesMap = new Map<String,Id>();
    for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) {
      recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
    }
    String recordTypesMapJSON = JSON.serialize(recordTypesMap);
    
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

       //AFTER UPDATE TRIGGER TESTS
       Test.startTest();
          update student; //Should result in StudentSearchHash__c creation. NEXT, change the DOB value and TEST for HASH UPDATE
       
          //VERIFY UPDATE OF HASH RECORD IF SSN OR DOB CHANGES
          student.DateOfBirth__c = '04/04/1966';
          update student;
          
       Test.stopTest();
          
          List<StudentSearchHash__c> existingHashes = [select count() from StudentSearchHash__c where Student__c = :student.id]>0? [select Id, Name, Student__c, StudentAccount__c, SSNHash__c, SSNLastFour__c,BirthDateHash__c from StudentSearchHash__c where Student__c = :student.Id]: new List<StudentSearchHash__c>();
          System.assert( existingHashes.size() == 1, 'CONTACT TRIGGER FAILURE, StudentSearchHash__c does NOT EXIST AFTER Contact UPDATE');
          String dateStr = Date.parse(student.DateOfBirth__c ).format();
          String expectedHash = EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( dateStr  ) ) );
          System.assert( expectedHash.equals( existingHashes[0].BirthDateHash__c ), 'STUDENT SEARCH HASH FAILURE, Hashing algorithim did NOT produce the same results AFTER Contact UPDATE.  Found ('+ existingHashes[0].BirthDateHash__c +') expected ('+ expectedHash +').');                
          
    }
  }
  

    @future
    private static void ssnFutureCall( String listNewJSON, String recordTypesMapJSON  ) {
      
        //grabbing code coverage into future call from future call
        try { ContactUtility.syncStudentSearchHash( listNewJSON, recordTypesMapJSON, false ); } catch (Exception e) {}
        
    }


    
   @IsTest
    public static void testAssignWGUDegreeProgramBeforeInsertAndUpdate() {
    
         //Create Two CatalogTerms based on current month and one year in the past
         Date t = Date.today();
         Integer tmonth = t.month();
         String month = (tmonth < 10)? '0'+String.valueOf(tmonth): String.ValueOf(tmonth);
         String year = String.valueOf(t.year());
         String programCode1 = year+month;
         String programCode2 = String.valueOf(t.year()-1)+month; 

        //CREATE TEST DEGREE PROGRAMS
        List<WGUDegreeProgram__c> pgms = new List<WGUDegreeProgram__c>();
        pgms.add( new WGUDegreeProgram__c(name='BAISK8', title__c='Sample Program for Unit Test', catalogTerm__c=programCode1, PAMSID__c=10) );                              
        pgms.add( new WGUDegreeProgram__c(name='BAISK8', title__c='Sample Program for Unit Test', catalogTerm__c=programCode2, PAMSID__c=20) );                                                                      
        insert pgms;
        System.debug( LoggingLevel.DEBUG, 'TEST WGU DEGREE PROGRAMS for testAssignWGUDegreeProgramBeforeInsertAndUpdate(): ' + JSON.serialize(pgms) );       
               
            User testUser = TestStudentUser.getSAdminUser();
            System.RunAs( testUser ) {   
        
                //BEFORE INSERT AND BEFORE UPDATE TRIGGER TESTS        
                Test.startTest();
             
                  //TEST BEFORE INSERT      
                    Contact student = TestStudentUser.getTestStudentContact();
                    System.debug( LoggingLevel.DEBUG, 'TEST STUDENT for testAssignWGUDegreeProgramBeforeInsertAndUpdate(): ' + JSON.serialize(student) );       
                              
                    Contact testResultsContact = [SELECT WGUDegreeProgram__c, programCode__c, programCatalogTerm__c FROM Contact WHERE id = :student.id LIMIT 1];
                    System.assert( testResultsContact.WGUDegreeProgram__c == pgms[0].id, 'CONTACT TRIGGER FAILURE, WGUDegreeProgram__c('+testResultsContact.WGUDegreeProgram__c+') does NOT EQUAL the test WGUDegreeProgram__c('+pgms[0].Id+') AFTER INSERT' );
                   
                    //TEST BEFORE UPDATE By Changing ProgramCatalogTerm__c
                    student.ProgramCatalogTerm__c = pgms[1].catalogTerm__c;
                    update student;
                    
                    testResultsContact = [SELECT WGUDegreeProgram__c, programCode__c, programCatalogTerm__c FROM Contact WHERE id = :student.id LIMIT 1];
                    System.assert( testResultsContact.WGUDegreeProgram__c == pgms[1].id, 'CONTACT TRIGGER FAILURE, WGUDegreeProgram__c('+testResultsContact.WGUDegreeProgram__c+') does NOT EQUAL the test WGUDegreeProgram__c('+pgms[1].Id+') AFTER UPDATE' );
                    
               Test.stopTest();
            }
       
    }


    static testMethod void testSetMentorIDFromMentorPIDMBeforeInsert(){
    
        String environment = '.'+TestStudentUser.getEnvironment();

        ID mentorProfileID = [SELECT id FROM Profile WHERE name = 'Mentor'].Id;
                ID studentRecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName IN ('StudentRecord') AND sObjectType IN ('Contact') LIMIT 1].Id;
                //Create Test Users
        List<User> testUsers = new List<user>();
        User testUser1 = new User(LastName='Mentor',FirstName='Standard',PIDM__c='m198765',Username='a@wgu.edu'+environment, Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileID, LanguageLocaleKey='en_US', isEmployee__c = true);
        testUsers.add(testUser1);
        
        User testUser2 = new User(LastName='Mentor',FirstName='State',PIDM__c='m123124',Username='b@wgu.edu'+environment, Email='b@wgu.edu', Alias='b', CommunityNickname='b', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileID, LanguageLocaleKey='en_US', isEmployee__c = true);
        testUsers.add(testUser2);
        
        insert testUsers;
        Map<ID,User> mentorUserMap = new Map<ID,User>([SELECT ID, PIDM__c, ProfileID FROM User WHERE ID in :testUsers LIMIT 2]);
        System.debug( LoggingLevel.DEBUG, 'MENTORUSERMAP AFTER INSERT in testSetMentorIDFromMentorPIDM(): ' + JSON.serialize( mentorUserMap ) );
        
        
        //Create Test Mentors
        List<Mentor__c> testMentors = new List<Mentor__c>();
        Mentor__c testMentor1 = new Mentor__c(mentorCeiling__c=1,monthlyProjection__c=1,mentorRole__c='Student Mentor',PIDM__c=testUser1.pidm__c,studentcapacity__c=80,priority1programcodes__c='BSITNW',programcodes__c='');
        testMentors.add(testMentor1);
        
        Mentor__c testMentor2 = new Mentor__c(mentorCeiling__c=1,monthlyProjection__c=1,mentorRole__c='Student Mentor (Concentrated)',PIDM__c=testUser2.pidm__c,studentcapacity__c=80,priority1programcodes__c='BSAC',programcodes__c='');           
        testMentors.add(testMentor2);
        
        insert testMentors;
        Map<ID,Mentor__c> mentorMap = new Map<ID,Mentor__c>([SELECT ID, PIDM__c, User__c FROM Mentor__c WHERE ID in :testMentors LIMIT 2]);
        System.debug( LoggingLevel.DEBUG, 'MENTORMAP AFTER INSERT in testSetMentorIDFromMentorPIDM(): ' + JSON.serialize( mentorMap ) );
                       
                       
        //Create test student Accounts  
        List<Contact> testStudents = new List<Contact>(); 
        testStudents.add( new Contact(MentorPidm__c = testMentor1.PIDM__c, lastName='Test',Firstname='Standard Student',PIDM__c='t123456',Email='t123456testing@wgu.edu',recordTypeId=studentRecordTypeId) );
        testStudents.add( new Contact(MentorPidm__c = testMentor2.PIDM__c, lastName='Test',Firstname='Concentrated Student',PIDM__c='t234567',Email='t234567testing@wgu.edu',recordTypeId=studentRecordTypeId) );
        insert testStudents; 

        User testUser = TestStudentUser.getSAdminUser();
        System.RunAs( testUser ) {   
    
            //BEFORE INSERT TRIGGER TESTS 
            Test.startTest();
            
                List<Contact> afterTriggerStudents = [SELECT Id, StudentMentor__c, Mentor__c, MentorPidm__c FROM Contact WHERE Id IN :testStudents];
                System.debug( LoggingLevel.DEBUG, 'CONTACTS afterTriggerStudents in testSetMentorIDFromMentorPIDM(): ' + JSON.serialize( afterTriggerStudents ) );
                
                for ( Contact testStudent: afterTriggerStudents ) {
                    //ASSERT StudentMentor__c
                  System.assert( testStudent.StudentMentor__c != null, 'testStudent.StudentMentor__c is NULL AFTER INSERT' );
                  System.assert( mentorMap.get(testStudent.StudentMentor__c) != null, 'MentorMap did not find a match for testStudent.StudentMentor__c('+testStudent.StudentMentor__c+')' );
                  System.assert(testStudent.MentorPidm__c.equals( mentorMap.get(testStudent.StudentMentor__c).PIDM__c) , 'PIDMs DO NOT MATCH via the Contact.StudentMentor__c relationship' );
                  
                  //ASSERT Mentor__c
                  System.assert( testStudent.Mentor__c != null, 'testStudent.Mentor__c is NULL AFTER INSERT' );
                  System.assert( mentorUserMap.get(testStudent.Mentor__c) != null, 'MentorUserMap did not find a match for testStudent.StudentMentor__c('+testStudent.StudentMentor__c+')');
                  System.assertEquals(testStudent.MentorPidm__c, mentorUserMap.get(testStudent.Mentor__c).PIDM__c , 'PIDMs DO NOT MATCH via the Contact.Mentor__c relationship');
                }
                
            Test.stopTest();
          }
    } 
  

    static testMethod void testSetMentorIDFromMentorPIDMBeforeUpdate(){
    
        String environment = '.'+TestStudentUser.getEnvironment();

        ID mentorProfileID = [SELECT id FROM Profile WHERE name = 'Mentor'].Id;
        ID studentRecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName IN ('StudentRecord') AND sObjectType IN ('Contact') LIMIT 1].Id;
        //Create Test Users
        List<User> testUsers = new List<user>();
        User testUser1 = new User(LastName='Mentor',FirstName='Standard',PIDM__c='m198765',Username='a@wgu.edu'+environment, Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileID, LanguageLocaleKey='en_US', isEmployee__c = true);
        testUsers.add(testUser1);
        
        User testUser2 = new User(LastName='Mentor',FirstName='State',PIDM__c='m123124',Username='b@wgu.edu'+environment, Email='b@wgu.edu', Alias='b', CommunityNickname='b', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileID, LanguageLocaleKey='en_US', isEmployee__c = true);
        testUsers.add(testUser2);
        
        insert testUsers;
        Map<ID,User> mentorUserMap = new Map<ID,User>([SELECT ID, PIDM__c, ProfileID FROM User WHERE ID in :testUsers LIMIT 2]);
        System.debug( LoggingLevel.DEBUG, 'MENTORUSERMAP AFTER INSERT in testSetMentorIDFromMentorPIDMBeforeUpdate(): ' + JSON.serialize( mentorUserMap ) );
        
        
        //Create Test Mentors
        List<Mentor__c> testMentors = new List<Mentor__c>();
        Mentor__c testMentor1 = new Mentor__c(mentorCeiling__c=1,monthlyProjection__c=1,mentorRole__c='Student Mentor',PIDM__c=testUser1.pidm__c,studentcapacity__c=80,priority1programcodes__c='BSITNW',programcodes__c='');
        testMentors.add(testMentor1);
        
        Mentor__c testMentor2 = new Mentor__c(mentorCeiling__c=1,monthlyProjection__c=1,mentorRole__c='Student Mentor (Concentrated)',PIDM__c=testUser2.pidm__c,studentcapacity__c=80,priority1programcodes__c='BSAC',programcodes__c='');           
        testMentors.add(testMentor2);
        
        insert testMentors;
        Map<ID,Mentor__c> mentorMap = new Map<ID,Mentor__c>([SELECT ID, PIDM__c, User__c FROM Mentor__c WHERE ID in :testMentors LIMIT 2]);
        System.debug( LoggingLevel.DEBUG, 'MENTORMAP AFTER INSERT in testSetMentorIDFromMentorPIDMBeforeUpdate(): ' + JSON.serialize( mentorMap ) );
                       
                       
        //Create test student Accounts  
        List<Contact> testStudents = new List<Contact>(); 
        testStudents.add( new Contact(lastName='Test',Firstname='Standard Student',PIDM__c='t123456',Email='t123456testing@wgu.edu',recordTypeId=studentRecordTypeId) );
        testStudents.add( new Contact(lastName='Test',Firstname='Concentrated Student',PIDM__c='t234567',Email='t234567testing@wgu.edu',recordTypeId=studentRecordTypeId) );
        insert testStudents; 

        User testUser = [Select id from User where IsActive = true AND ProfileId in (select id from profile where name = 'System Administrator') LIMIT 1];
        System.RunAs( testUser ) {   
    
          //BEFORE INSERT AND BEFORE UPDATE TRIGGER TESTS 
          Test.startTest();
          
              List<Contact> afterTriggerStudents = [SELECT Id, StudentMentor__c, Mentor__c, MentorPidm__c FROM Contact WHERE Id IN :testStudents];
              for ( Contact testStudent: afterTriggerStudents ) {
                System.assert( testStudent.StudentMentor__c == null, 'testStudent.StudentMentor__c is NOT NULL AFTER INSERT. Expected Null BEFORE UPDATE.' );
              }
              
                    testStudents[0].MentorPidm__c = testMentor1.PIDM__c;
                    testStudents[1].MentorPidm__c = testMentor2.PIDM__c;
                    update testStudents;
                    
              afterTriggerStudents = [SELECT Id, StudentMentor__c, Mentor__c, MentorPidm__c FROM Contact WHERE Id IN :testStudents];
              System.debug( LoggingLevel.DEBUG, 'CONTACTS afterTriggerStudents in testSetMentorIDFromMentorPIDM(): ' + JSON.serialize( afterTriggerStudents ) );
              
              for ( Contact testStudent: afterTriggerStudents ) {
                //ASSERT StudentMentor__c
                System.assert( testStudent.StudentMentor__c != null, 'testStudent.StudentMentor__c is NULL AFTER INSERT' );
                System.assert( mentorMap.get(testStudent.StudentMentor__c) != null, 'MentorMap did not find a match for testStudent.StudentMentor__c('+testStudent.StudentMentor__c+')' );
                System.assert(testStudent.MentorPidm__c.equals( mentorMap.get(testStudent.StudentMentor__c).PIDM__c) , 'PIDMs DO NOT MATCH via the Contact.StudentMentor__c relationship' );
                
                //ASSERT Mentor__c
                System.assert( testStudent.Mentor__c != null, 'testStudent.Mentor__c is NULL AFTER INSERT' );
                System.assert( mentorUserMap.get(testStudent.Mentor__c) != null, 'MentorUserMap did not find a match for testStudent.StudentMentor__c('+testStudent.StudentMentor__c+')');
                System.assertEquals(testStudent.MentorPidm__c, mentorUserMap.get(testStudent.Mentor__c).PIDM__c , 'PIDMs DO NOT MATCH via the Contact.Mentor__c relationship');
              }
              
          Test.stopTest();
        }
    } 

    @IsTest
    public static void testCreateContactToBanner()
    {
        String environment = TestStudentUser.getEnvironment();
    
        //Create test student Accounts  
        List<Contact> testStudents = new List<Contact>(); 
        ID studentRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName IN ('StudentRecord') AND sObjectType IN ('Contact') LIMIT 1].Id;          
        testStudents.add( new Contact(lastName='Test',Firstname='Standard Student1',PIDM__c='t123458',Email='t123458testing@wgu.edu',recordTypeId=studentRecordTypeId) );
        testStudents.add( new Contact(lastName='Test',Firstname='Concentrated Student1',PIDM__c='t234569',Email='t234569testing@wgu.edu',recordTypeId=studentRecordTypeId) );      
        insert testStudents;
        
        Test.startTest();
            ContactUtility.createContactToBanner(JSON.serialize(testStudents));
        Test.stopTest();
        
        testStudents = [SELECT Id 
                        FROM Contact 
                        WHERE LastName = 'Test' 
                        AND PIDM__c LIKE 't%'];
                        
        List<Id> contactIds = new List<Id>();
        
        for (Contact thisContact : testStudents)
        {
            contactIds.add(thisContact.Id);
        }
        
        List<ContactToBanner__c> ctbList = [SELECT Id 
                                            FROM ContactToBanner__c
                                            WHERE Contact__c IN :contactIds];
                                            
        System.assertEquals(ctbList.size(), 2);                                                                            
    }
    
    @IsTest
    public static void testMailingAddr()
    {
        String environment = TestStudentUser.getEnvironment();
    
        //Create test student Accounts
        ID studentRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName IN ('StudentRecord') AND sObjectType IN ('Contact') LIMIT 1].Id;  
        Contact testStu = new Contact(lastName='Test',Firstname='Standard Student1',PIDM__c='t123458',
                                      Email='t123458testing@wgu.edu',recordTypeId=studentRecordTypeId,
                                      MailingStreet='test\r street\nSalt Lake City');
        
        Test.startTest();
          insert testStu;
        Test.stopTest();
        
        List<Contact> testStudents = [SELECT Id,MailingStreet 
                        FROM Contact 
                        WHERE LastName = 'Test' 
                        AND PIDM__c LIKE 't%'];
                        
        System.assertEquals(testStudents.size(), 1,'error record number');
        System.assertEquals('test street Salt Lake City',testStudents[0].MailingStreet, 'error mailing address');
        
    }

    @IsTest(SeeAllData=true)//Needs see all data because ContactId on User is not writable
    private static void testContactUpdatedPropagateToUser() {
        User u = [SELECT Id, ContactId, FirstName, LastName FROM User WHERE ContactId != null AND Contact.WGUEmail__c != null AND Profile.Name = 'Student Profile' AND IsActive = true LIMIT 1];
        Contact c = [SELECT Id, FirstName, LastName, WGUEmail__c FROM Contact WHERE Id = :u.ContactId];
        
        Test.startTest();
        String updatedFirstName = c.FirstName + 'Test';
        c.FirstName = updatedFirstName;

        String updatedLastName = c.LastName + 'Test';
        c.LastName = updatedLastName;

        String updatedEmail = 'test' + c.WGUEmail__c;
        c.WGUEmail__c = updatedEmail;

        update c;
        Test.stopTest();

        User updateUser = [SELECT FirstName, LastName, Email FROM User WHERE Id = :u.id];
        System.assertEquals(updatedFirstName, updateUser.FirstName);
        System.assertEquals(updatedLastName, updateUser.LastName);
        System.assertEquals(updatedEmail.toLowerCase(), updateUser.Email);//Email ends up lowercase somewhere through the process
    }
    
}