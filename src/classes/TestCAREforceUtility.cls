@isTest
public class TestCAREforceUtility {

    @IsTest
    public static void testNewCAREMiddleEarthRecordOnProgramVersion() {
        CAREProgram__c cProgram = new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test');
        insert cProgram;
        
        WGUDegreeProgram__c original = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test');
        insert original;
        
        CareProgramMiddleEarth__c middleEarth = new CareProgramMiddleEarth__c(Name=cProgram.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram.Id, BannerProgramCode__c=original.Id);
        insert middleEarth;
        
        Test.startTest();
            
            // Test insert of newer program that is active and newer than the previous.
            WGUDegreeProgram__c newProgram = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=2, Active__c=true, CatalogTerm__c='201208', Title__c='PAMS Program Test');
            insert newProgram;
    
            List<CareProgramMiddleEarth__c> checkOriginal = [SELECT id, Active__c FROM CareProgramMiddleEarth__c WHERE id = :middleEarth.Id];                        
            List<CareProgramMiddleEarth__c> checkNew = [SELECT id, Active__c FROM CareProgramMiddleEarth__c WHERE BannerProgramCode__c = :newProgram.Id];
            
            System.assert(!checkOriginal[0].Active__c);
            System.assert(checkNew[0].Active__c);
            
            // Test insert of a past record that should not be active.
            WGUDegreeProgram__c newerProgram = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=3, Active__c=true, CatalogTerm__c='201108', Title__c='PAMS Program Test');
            insert newerProgram;        
                           
            checkNew = [SELECT id, Active__c FROM CareProgramMiddleEarth__c WHERE BannerProgramCode__c = :newProgram.Id];  
            System.assert(checkNew[0].Active__c);
            
            List<CareProgramMiddleEarth__c> checkNewer = [SELECT id, Active__c FROM CareProgramMiddleEarth__c WHERE BannerProgramCode__c = :newerProgram.Id];            
            System.assert(checkNewer.isEmpty());
                           
            // Test insert of a future record that is not active.
            newerProgram = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=4, Active__c=false, CatalogTerm__c='201308', Title__c='PAMS Program Test');
            insert newerProgram;        
                           
            checkNew = [SELECT id, Active__c FROM CareProgramMiddleEarth__c WHERE BannerProgramCode__c = :newProgram.Id];  
            System.assert(checkNew[0].Active__c);
            
            checkNewer = [SELECT id, Active__c FROM CareProgramMiddleEarth__c WHERE BannerProgramCode__c = :newerProgram.Id];            
            System.assert(checkNewer.isEmpty());                       
                       
                       
        Test.stopTest();
    }

    @isTest
    public static void testLeadScoringAndGradeLeadTrigger()
    {         
        Opportunity newLead = new Opportunity(name='Ben Kesner', careStatus__c='PROS – Prospect', stageName='Prospect', closeDate=Date.today());
        
        EnrollmentResponses__c r1 = new EnrollmentResponses__c();
        EnrollmentResponses__c r2 = new EnrollmentResponses__c();
        EnrollmentResponses__c r3 = new EnrollmentResponses__c();
        EnrollmentResponses__c r4 = new EnrollmentResponses__c();
        
        EnrollmentQuestions__c q1 = new EnrollmentQuestions__c();
        EnrollmentQuestions__c q2 = new EnrollmentQuestions__c();
        EnrollmentQuestions__c q3 = new EnrollmentQuestions__c();
        EnrollmentQuestions__c q4 = new EnrollmentQuestions__c();
        
        EnrollmentAnswers__c a1 = new EnrollmentAnswers__c();
        EnrollmentAnswers__c a2 = new EnrollmentAnswers__c();
        EnrollmentAnswers__c a3 = new EnrollmentAnswers__c();
        EnrollmentAnswers__c a4 = new EnrollmentAnswers__c();
        
        //newLead.LeadSource = '99999';
    
        q1.QuestionText__c = 'Date of Grad Test';
        q1.GradingType__c = 'Grad Date';
        q1.QuestionStatus__c = 'Active';
        
        insert q1;
     
        q2.QuestionText__c = 'Positive Experence';
        q2.GradingType__c = 'Normal';
        q2.QuestionStatus__c = 'Active';
        insert q2;
      
        q3.QuestionText__c = 'Rate as Online Learner';
        q3.GradingType__c = 'Normal';
        q3.QuestionStatus__c = 'Active';
        insert q3;
    
        q4.QuestionText__c = 'Time Learning';
        q4.GradingType__c = 'Normal';
        q4.QuestionStatus__c = 'Active';
        insert q4;
        
        a1.AnswerText__c = '2004';
        a1.EnrollmentQuestion__c = q1.id;
        a1.Multiplier__c = 1;
        a1.MultiplierValue__c = 1;
        a1.Value__c = '2004';
        insert a1;
        
        a2.AnswerText__c = 'Test Very Pos';
        a2.EnrollmentQuestion__c = q2.id;
        a2.Multiplier__c =  1.37647077038823;
        a2.MultiplierValue__c = 1;
        a2.Value__c = 'Test VP';
        insert a2;
        
        a3.AnswerText__c = 'Test LVG';
        a3.EnrollmentQuestion__c = q3.id;
        a3.Multiplier__c =  0.479126413550687;
        a3.MultiplierValue__c = 1;
        a3.Value__c = 'Test LVG';
        insert a3;
        
        a4.AnswerText__c = 'Test 21H';
        a4.EnrollmentQuestion__c = q4.id;
        a4.Multiplier__c  = 1.32053380265839;
        a4.MultiplierValue__c = 1;
        a4.Value__c = '21H';
        insert a4;
        
        insert newLead;
        
        r1.AnswerQuestion__c = a1.id;
        r1.QuestionNumber__c = q1.id;
        r1.CAREProfile__c = newLead.id;
        insert r1;
        
        r2.AnswerQuestion__c = a2.id;
        r2.QuestionNumber__c = q2.id;
        r2.CAREProfile__c = newLead.id;
        insert r2;
        
        r3.AnswerQuestion__c = a3.id;
        r3.QuestionNumber__c = q3.id;
        r3.CAREProfile__c = newLead.id;
        insert r3;
        
        r4.AnswerQuestion__c = a4.id;
        r4.QuestionNumber__c = q4.id;
        r4.CAREProfile__c = newLead.id;
        insert r4;
        
        CAREforceUtility.ScoreResult result = CAREforceUtility.scoreLead(newLead);

    
        Boolean b1 = result.score < 0.1010872;
        Boolean b2 = result.score > 0.1010871;
    
        System.assert(b1);
        System.assert(b2);
        System.assertEquals(result.grade, 'B');
    }


    @IsTest
  public static void testSyncLastCallDispositionTrigger() {        
    
    Contact student = TestStudentUser.getTestStudentContact();
    
    Opportunity care = new Opportunity(AccountId=student.AccountId, Name='Dudley Schults', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
    insert care;
    update care;
    care = [select id, AccountId, LastCallDisposition__c from Opportunity where id = :care.id];
    Id careTaskId = [Select id from RecordType where Name='CAREforce Task' and sObjectType = 'Task'].id;    
        
    Test.StartTest();

        List<Task> newTasksList = new List<Task>();
        newTasksList.add( new Task(Subject='Call', CallDisposition__c='Phone Attempt 1', RecordTypeId=careTaskId, whoid=student.Id, whatid=care.id, NoteType__c='Other') );
        insert newTasksList;
            
    Test.StopTest();
        
    System.assert( [select id, LastCallDisposition__c from Opportunity where id = :care.id].LastCallDisposition__c == 'Phone Attempt 1', 'CARE.LastCallDisposition__c DOES NOT equal Task.CallDisposition__c AFTER INSERT');
    
    //grabbing code coverage
    doSyncCallDisposition( JSON.serialize(newTasksList) );

  }
 
 
  @future 
  private static void doSyncCallDisposition( String taskListNewJSON ) {
    try { CAREforceUtility.syncOpportunityTaskToCallDisposition( taskListNewJSON ); } catch (Exception e) {}
  }
  
  
  
  
  @IsTest
  public static void testRandomUUID() {
      String uuid = CAREforceUtility.randomUUID();
      System.assert(uuid != null);
  }
  
  @IsTest
  public static void testTrimCAREStatusValue() {
      System.assert(CAREforceUtility.trimCAREStatusValue('APCO – Application Complete, Unpaid') == 'APCO');
  }
  
  @IsTest
  public static void testUsePersonalAccountsDeactivated() {
      Runtime__c c = new Runtime__c();
      c.Name = 'UsePersonAccounts';
      c.Value__c = 'false';
      insert c;  
      
      Test.startTest();
      System.assert(!CAREforceUtility.usePersonAccounts());
      Test.stopTest();
  }  
  
  @IsTest
  public static void testUsePersonalAccountsActivated() {
      Runtime__c c = new Runtime__c();
      c.Name = 'UsePersonAccounts';
      c.Value__c = 'true';
      insert c;  
      
      Test.startTest();
      System.assert(CAREforceUtility.usePersonAccounts());
      Test.stopTest();
  }
  
  @IsTest
  public static void testCheckProspectForExistingAccount() {
      Test.startTest();
      
      Id prospectRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' and Name = 'ProspectRecord'][0].Id;
      
      Contact controlledInstance = new Contact(FirstName = 'Test', LastName = 'Person', Email = 'testMyEmail@unit.test', 
                                               Phone = '(801) 679-1234', SocialSecurityNumber__c = '123456789', DateOfBirth__c = '05/11/1980',
                                               RecordTypeId = prospectRecordType);
      insert controlledInstance;
      

      Account controlledAccount = [SELECT Id FROM Account WHERE StudentContact__c = :controlledInstance.Id];
      
      Opportunity controlledProfile = new Opportunity(Name = 'Test Person', AccountId = controlledAccount.Id, CloseDate=Date.today(), StageName='Applicant');
      insert controlledProfile;
      
      Test.stopTest();
      
      
      // Test Name & Email
      Contact check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail@unit.test', '(801) 111-1234', null, null);
      System.assert(check.Id == controlledInstance.Id, 'Could not match by name and email');
      
      // Test Name & Email (with SSN and DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail@unit.test', '(801) 111-1234', '526526526', '09/13/1985');
      System.assert(check != null, 'Could not match by name and email');
      System.assert(check.Id == controlledInstance.Id, 'Could not match by name and email');
      
      // Test Name and Phone
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '(801) 679-1234', null, null);
      System.assert(check.Id == controlledInstance.Id, 'Could not match by name and phone');
      
      // Test Name and Phone (with SSN and DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '(801) 679-1234', '526526526', '09/13/1985');
      System.assert(check != null, 'Could not match by name and phone');
      System.assert(check.Id == controlledInstance.Id, 'Could not match by name and phone');
      
      // Test Name but wrong phone and email
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '(801) 111-1234', null, null);
      System.assert(check == null, 'Incorrectly matched by just name');
      
      // Test Name but wrong phone and email (with SSN and DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '(801) 111-1234', '526526526', '09/13/1985');
      System.assert(check == null, 'Incorrectly matched by just name');
      
      // Test Name, blank phone and email
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', '', '', null, null);
      System.assert(check == null, 'Incorrectly matched by just name (blank email and phone)');
      
      // Test Name, blank phone and email (with SSN and DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', '', '', '526526526', '09/13/1985');
      System.assert(check == null, 'Incorrectly matched by just name (blank email and phone)');
      
      // Test Name, blank phone and bad email
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '', null, null);
      System.assert(check == null, 'Incorrectly matched by name blank phone');
      
      // Test Name, blank phone and bad email (with SSN and DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '', '526526526', '09/13/1985');
      System.assert(check == null, 'Incorrectly matched by name blank phone');
      
      // Test Name, bad phone, and blank email
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', '', '(801) 111-1234', null, null);
      System.assert(check == null, 'Incorrectly matched by name and blank email');
      
      // Test Name, bad phone, and blank email (with SSN and DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', '', '(801) 111-1234', '526526526', '09/13/1985');
      System.assert(check == null, 'Incorrectly matched by name and blank email');
      
      // Test Name SSN and last name
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '(801) 111-1234', '123456789', null);
      System.assert(check != null, 'Could not match by SSN and last name');
      System.assert(check.Id == controlledInstance.Id, 'Could not match by SSN and last name');
      
      // Test Name SSN and last name (with DoB)
      check = CAREforceUtility.checkProspectForExistingContact('Test', 'Person', 'testMyEmail.wrong@unit.test', '(801) 111-1234', '123456789', '09/13/1985');
      System.assert(check != null, 'Could not match by SSN and last name');
      System.assert(check.Id == controlledInstance.Id, 'Could not match by SSN and last name');
      
      // Test SSN and Date of Birth
      check = CAREforceUtility.checkProspectForExistingContact('George', 'Patterson', 'testMyEmail.wrong@unit.test', '(801) 111-1234', '123456789', '05/11/1980');
      System.assert(check != null, 'Could not match by SSN and Date of Birth');
      System.assert(check.Id == controlledInstance.Id, 'Could not match by SSN and Date of Birth');   
  }
  
  @IsTest
  public static void testGetContactInfo() {
      Test.startTest();
      
      Id prospectRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' and Name = 'ProspectRecord'][0].Id;
      
      Contact controlledInstance = new Contact(FirstName = 'Test', LastName = 'Person', Email = 'testMyEmail@unit.test', 
                                               Phone = '(801) 679-1234', SocialSecurityNumber__c = '123456789', DateOfBirth__c = '05/11/1980',
                                               RecordTypeId = prospectRecordType);
      insert controlledInstance;
      
      Account controlledAccount = [SELECT Id FROM Account WHERE StudentContact__c = :controlledInstance.Id];
      
      Opportunity controlledProfile = new Opportunity(Name = 'Test Person', AccountId = controlledAccount.Id, CloseDate=Date.today(), StageName='Applicant');
      insert controlledProfile;
      
      Test.stopTest();
      
      Contact contact = CAREforceUtility.getContactInfo(controlledAccount.Id);
      System.assert(contact != null, 'Could not gather contact information');
  }
    
  @IsTest
  public static void testMatchSsnAndDOB() {
      Test.startTest();
      
      Id prospectRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' and Name = 'ProspectRecord'][0].Id;
      
      Contact controlledInstance = new Contact(FirstName = 'Test', LastName = 'Person', Email = 'testMyEmail@unit.test', 
                                               Phone = '(801) 679-1234', SocialSecurityNumber__c = '123456789', DateOfBirth__c = '05/11/1980',
                                               RecordTypeId = prospectRecordType);
      insert controlledInstance;
      
      Account controlledAccount = [SELECT Id FROM Account WHERE StudentContact__c = :controlledInstance.Id];
      
      Test.stopTest();
      
      Id accountId = CAREforceUtility.MatchSsnAndDOB('123456789', Date.parse('05/11/1980'));
      System.assert(accountId != null, 'Could not match contact with SSN and Date of Birth');
      System.assert(accountId == controlledAccount.Id, 'Could not match contact with SSN and Date of Birth');
  }
    
  @IsTest
  public static void testMatchSsn() {
      Test.startTest();
      
      Id prospectRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' and Name = 'ProspectRecord'][0].Id;
      
      Contact controlledInstance = new Contact(FirstName = 'Test', LastName = 'Person', Email = 'testMyEmail@unit.test', 
                                               Phone = '(801) 679-1234', SocialSecurityNumber__c = '123456789', DateOfBirth__c = '05/11/1980',
                                               RecordTypeId = prospectRecordType);
      insert controlledInstance;
      
      Account controlledAccount = [SELECT Id FROM Account WHERE StudentContact__c = :controlledInstance.Id];
      
      Test.stopTest();
      
      Id accountId = CAREforceUtility.MatchSsn('123456789');
      System.assert(accountId != null, 'Could not match contact with SSN');
      System.assert(accountId == controlledAccount.Id, 'Could not match contact with SSN');
  }
  
  @IsTest
  public static void testSendBasicInfoToEloqua() {
      //EloquaCalloutMockHandler handler = new EloquaCalloutMockHandler();
      //Test.setMock(HttpCalloutMock.class, handler);
      
      Test.startTest();
          CAREforceUtility.sendBasicInfoToEloqua('test@unittest.fake', 'Unit', 'Unit Test Program', 'Western Governors University', 'WGU', 'UT Enrollment Counselor', 'APAC');
      Test.stopTest();
      
      //System.assert(handler.getValidated());
  }
  
  /*public class EloquaCalloutMockHandler implements HttpCalloutMock {
      private Boolean validated = false;
      
      public HTTPResponse respond(HTTPRequest request) {
          HTTPResponse response = new HTTPResponse();
          response.setStatusCode(200);
          
          String submission = request.getBody();
          this.validated = submission.indexOf('&campusLongName=Western+Governors+University') > -1;
          
          return response;
      }
      
      public Boolean getValidated() {
          return this.validated;
      }
  }*/
  
    @IsTest
    public static void testSynchronizeToBannerTrigger()
    {
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact;
       
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];

        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Sync MacTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        insert care;
        update care;
        
        care = [select id, AccountId,pidm__C from Opportunity where id = :care.id];

        SynchronizeToBanner__c syncObject = new SynchronizeToBanner__c();    
        syncObject.ActiveOpportunity__c = care.id;
        
        insert syncObject;

        test.startTest();

        SynchronizeToBanner__c syncObject2 = [Select id, BannerIdIn__c, PIDMIn__c,     WGUEmailIn__c from SynchronizeToBanner__c where id = :syncObject.id];
        syncObject2.BannerIdIn__c = '998877';
        syncObject2.PidmIn__C = '234234';
        syncObject2.WGUEmailIn__c = 'smact@wgu.edu';
        
        update syncObject2;
        
        test.stopTest();

        Contact  check = [SELECT id,  PIDM__c, StudentID__c, WGUEmail__c from contact WHERE id = :contact.id];

        System.assert(check.PIDM__c == '234234' );  
        System.assert(check.StudentID__c == '998877' );  
        System.assert(check.WGUEmail__c == 'smact@wgu.edu' );  
    }   
    
    @IsTest
    public static void testUpdateEnrollmentAnswerMappings() {
        EnrollmentQuestions__c question = new EnrollmentQuestions__c();
        insert question;
        
        question = [SELECT id, name FROM EnrollmentQuestions__c WHERE id = :question.id];
        
        // Test mapping Question Key to lookup reference.
        EnrollmentAnswers__c answer = new EnrollmentAnswers__c(name='Option A', EnrollmentQuestion__c = question.id);
        insert answer;
        
        answer = [SELECT id, name, QuestionKey__c FROM EnrollmentAnswers__c WHERE id = :answer.id];
        System.assert(answer.QuestionKey__c == Decimal.valueOf(question.name));
        
        // Test mapping lookup reference by question key.
        answer = new EnrollmentAnswers__c(name='Option B', QuestionKey__c = Decimal.valueOf(question.name));
        insert answer;
        
        answer = [SELECT id, name, EnrollmentQuestion__c FROM EnrollmentAnswers__c WHERE id = :answer.id];
        System.assert(answer.EnrollmentQuestion__c == question.id);        
        
    }    

    @IsTest
    public static void testCAREProfileSyncCreationTriggerOnInsert() {
        Test.startTest();
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact;
       
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];

        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Sync MacTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        insert care;   
        Test.StopTest();
        

        
        SynchronizeToBanner__c sync = [SELECT Id, Name FROM SynchronizeToBanner__c WHERE ActiveOpportunity__c = :care.Id];
        
        System.assert(sync.Name == care.Name);            
    }
    
    @IsTest
    public static void testCreateCAREforceCase (){
        Contact contact = new Contact(firstName='Case', lastName = 'CareForceFixIt', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact;
       
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
        
        User user1 = new User(firstName='CaseTest', lastName='McGee', enrollmentMultiplier__c=2, Username='casetest1@wgu.edu', 
            Email='test1@wgu.edu', Alias='casetest', CommunityNickname='casetest', LocaleSidKey='en_US', 
            EmailEncodingKey='UTF-8', ProfileId=[SELECT Id FROM Profile WHERE Name = 'Enrollment Team'].id, LanguageLocaleKey='en_US', pidm__c='000000001', TimeZoneSidKey='America/Denver', isEmployee__c=true);           
        insert user1;

        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Case CareForceFixIt', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id, Owner = [SELECT Id FROM User WHERE Id = :user1.Id]);
        insert care;
        
        Test.startTest();
        
        FeedItem item = new FeedItem(ParentId = care.id, Body = '#CAREforceHelp this student is having problems');
        insert item;
        
        FeedComment comment = new FeedComment(FeedItemId = item.Id, CommentBody = '#CAREforceHelp this student is having problems');
        insert comment;
        
        Test.stopTest();
        
        List<Case> cases = [SELECT Id, Subject FROM Case WHERE Subject = 'CAREforce Help Team' AND CAREProfile__c = :care.id];
        
        System.Assert(cases[0].Subject == 'CAREforce Help Team');
        System.Assert(cases.Size() == 2);
    
    }
    
    
        @IsTest
    public static void testNextEnrollmentCounselor() {    
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        // Uses runAs to avoid Mixed DML error.
        System.runAs ( thisUser ) {
            Profile profile = [SELECT id FROM Profile WHERE name = 'Enrollment Team' LIMIT 1];
        
            List<User> users = new List<User>();
        
            User user1 = new User(firstName='Test', lastName='McGee', Username='test1@wgu.edu', 
                Email='test1@wgu.edu', Alias='test1', CommunityNickname='test1', LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', ProfileId=profile.id, LanguageLocaleKey='en_US', pidm__c='000000001', TimeZoneSidKey='America/Denver', isEmployee__c=true);
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            user1.setOptions(dmo);            
            users.add(user1);
    
            User user2 = new User(firstName='Katrina', lastName='McGee', Username='test2@wgu.edu', 
                Email='test2@wgu.edu', Alias='test2', CommunityNickname='test2', LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', ProfileId=profile.id, LanguageLocaleKey='en_US', pidm__c='000000002', TimeZoneSidKey='America/Denver', isEmployee__c=true);
            dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            user1.setOptions(dmo);
            users.add(user2);
            
            insert users;
            
            List<UserAttributes__c> attributes = new List<UserAttributes__c>();
            Id ecRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'UserAttributes__c' AND Name = 'Enrollment Team'][0].Id;
            UserAttributes__c attributes1 = new UserAttributes__c(Name=user1.Name, User__c=user1.Id, AssignmentMultiplier__c=2, RecordTypeID=ecRecordType, CollegeTeam__c='Business Graduate', AssignedPrograms__c='MBA IT Management; MBA Management and Strategy; MBA Strategic Leadership');
            attributes.add(attributes1);
            
            UserAttributes__c attributes2 = new UserAttributes__c(Name=user2.Name, User__c=user2.Id, RecordTypeID=ecRecordType, CollegeTeam__c='Business Graduate', AssignedPrograms__c='MBA IT Management; MBA Management and Strategy; MBA Strategic Leadership');
            attributes.add(attributes2);            

            insert(attributes);
            
            List<Account> accounts = new List<Account>();
            List<Opportunity> opps = new List<Opportunity>();
        
            for (Integer i = 0; i < 5; i++) {
             
                
                Contact contact = new Contact(firstName='Case', lastName = 'CareForceFixIt', email='MACTESTER' + i + '@Msn.com',  pidm__C = '1235632' + i );
                contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
                insert contact;
       
                Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
                
                accounts.add(student);
         
            }
            
        
            
            for (Integer i = 0; i < 5; i++) {                
                Opportunity o = new Opportunity(AccountId=accounts[i].Id, Name='My Opportunity', StageName='Prospecting', CloseDate=Date.today(), CareStatus__c='APNN – Application Incomplete PRAP');
                opps.add(o);
            }
                        
            insert opps;        
            
            Test.startTest();
            
            Map<ID,Integer> counts = new Map<ID, Integer>();
            List<Id> owners = CAREforceUtility.nextEnrollmentCounselor('MBA Management and Strategy', opps.size());
            Integer counter = 0;
            
            for (Opportunity opp : opps) {
                ID owner = owners[counter];
                counter++;
                opp.ownerId = owner;
                
                if (counts.get(owner) == null) {
                    counts.put(owner, 1);
                } else {
                    counts.put(owner, counts.get(owner) + 1);
                }
            }
            
            // Out of 5 opportunities, 2 go to user 1 in which each person counts as 2 and 3 go to user 2 in which each person counts as 1.
            System.assert(counts.get(user1.id) == 2);
            System.assert(counts.get(user2.id) == 3);
            
            
            System.assert(CAREforceUtility.nextEnrollmentCounselor(null, 1) == null);
            System.assert(CAREforceUtility.nextEnrollmentCounselor('NoneExistentGroup', 1) == null);
            Test.stopTest();
        }
    }
    
    
    
    
    
    
    /*
    //  7/9/2013 yemeng Test case of CAREFORCE-535
    @IsTest
    public static void testNextEnrollmentCounselorByGrade() {    
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        // Uses runAs to avoid Mixed DML error.
        System.runAs ( thisUser ) {
            Profile profile = [SELECT id FROM Profile WHERE name = 'Enrollment Team' LIMIT 1];
        
            List<User> users = new List<User>();
        
            User user1 = new User(firstName='Test', lastName='McGee', Username='test1@wgu.edu', 
                Email='test1@wgu.edu', Alias='test1', CommunityNickname='test1', LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', ProfileId=profile.id, LanguageLocaleKey='en_US', pidm__c='000000001', TimeZoneSidKey='America/Denver', isEmployee__c=true);
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            user1.setOptions(dmo);            
            users.add(user1);
    
            User user2 = new User(firstName='Katrina', lastName='McGee', Username='test2@wgu.edu', 
                Email='test2@wgu.edu', Alias='test2', CommunityNickname='test2', LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', ProfileId=profile.id, LanguageLocaleKey='en_US', pidm__c='000000002', TimeZoneSidKey='America/Denver', isEmployee__c=true);
            dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            user1.setOptions(dmo);
            users.add(user2);
            
            insert users;
            
            List<UserAttributes__c> attributes = new List<UserAttributes__c>();
            Id ecRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'UserAttributes__c' AND Name = 'Enrollment Team'][0].Id;
            UserAttributes__c attributes1 = new UserAttributes__c(Name=user1.Name, User__c=user1.Id, AssignmentMultiplier__c=2, RecordTypeID=ecRecordType, CollegeTeam__c='Business Graduate', AssignedPrograms__c='MBA IT Management; MBA Management and Strategy; MBA Strategic Leadership');
            attributes.add(attributes1);
            
            UserAttributes__c attributes2 = new UserAttributes__c(Name=user2.Name, User__c=user2.Id, RecordTypeID=ecRecordType, CollegeTeam__c='Business Graduate', AssignedPrograms__c='MBA IT Management; MBA Management and Strategy; MBA Strategic Leadership');
            attributes.add(attributes2);            

            insert(attributes);
            
            List<Account> accounts = new List<Account>();
            List<Opportunity> opps = new List<Opportunity>();
        
            for (Integer i = 0; i < 5; i++) {
             
                
                Contact contact = new Contact(firstName='Case', lastName = 'CareForceFixIt', email='MACTESTER' + i + '@Msn.com',  pidm__C = '1235632' + i );
                contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
                insert contact;
       
                Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
                
                accounts.add(student);
         
            }
            
        
            // 5 opportunity with A+ grade 
            for (Integer i = 0; i < 5; i++) {                
                Opportunity o = new Opportunity(LeadGrade__c='A+', AccountId=accounts[i].Id, Name='My Opportunity', StageName='Prospecting', CloseDate=Date.today(), CareStatus__c='APNN – Application Incomplete PRAP');
                opps.add(o);
            }
                        
            insert opps; 
            
            // 3 opportunity with B grade 
            List<Opportunity> oppsB = new List<Opportunity>();       
             for (Integer i = 0; i < 3; i++) {                
                Opportunity o = new Opportunity(LeadGrade__c='B', AccountId=accounts[i].Id, Name='My Opportunity', StageName='Prospecting', CloseDate=Date.today(), CareStatus__c='APNN – Application Incomplete PRAP');
                oppsB.add(o);
            }
                        
            insert oppsB; 
            Test.startTest();
            
            Map<ID,Integer> counts = new Map<ID, Integer>();
            List<Id> owners = CAREforceUtility.nextEnrollmentCounselorByGrade('MBA Management and Strategy','A+', opps.size());
            Integer counter = 0;
            
            for (Opportunity opp : opps) {
                ID owner = owners[counter];
                counter++;
                opp.ownerId = owner;
                
                if (counts.get(owner) == null) {
                    counts.put(owner, 1);
                } else {
                    counts.put(owner, counts.get(owner) + 1);
                }
            }
            
            // Out of 5 opportunities, 2 go to user 1 in which each person counts as 2 and 3 go to user 2 in which each person counts as 1.
            System.assert(counts.get(user1.id) == 2);
            System.assert(counts.get(user2.id) == 3);
            
            
            System.assert(CAREforceUtility.nextEnrollmentCounselorByGrade(null,'A+' ) == null);
            System.assert(CAREforceUtility.nextEnrollmentCounselorByGrade('NoneExistentGroup','A+', 1) == null);
            // leadGrade B
            counts = new Map<ID, Integer>();
            owners = CAREforceUtility.nextEnrollmentCounselorByGrade('MBA Management and Strategy','B', oppsB.size());
            counter = 0;
            
            for (Opportunity opp : oppsB) {
                ID owner = owners[counter];
                counter++;
                opp.ownerId = owner;
                
                if (counts.get(owner) == null) {
                    counts.put(owner, 1);
                } else {
                    counts.put(owner, counts.get(owner) + 1);
                }
            }
            
            // Out of 3 opportunities, 1 go to user 1 in which each person counts as 1 and 2 go to user 2 in which each person counts as 2.
            System.assert(counts.get(user1.id) == 1);
            System.assert(counts.get(user2.id) == 2);
            
            
            
            
            Test.stopTest();
        }
    }
    */
}