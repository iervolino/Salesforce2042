@IsTest
public class TestCAREforceApplicationRESTService {
    
    /**
     * Possible Tests Conditions (X = Included, ? = Unsure if they should be tested, - = Other ideas of tests): 
     * X Application with existing record - inquiry
     * X Application with existing record - matriculated (should fail)
     * X Application with existing record - paid applicant (should fail)
     * X Application without existing record
     * X Match on Email
     * X Match on Phone
     * X Login to Inquiry Record (should fail)
     * X Login to incomplete Application
     * X Login to Completed Application (should fail) 
     * X Login to Student Account (should fail) 
     * X Login Bad Email (should fail)
     * X Login Bad Pin (should fail)
     * X Pin Rest on Inquiry record (should fail)
     * X Pin Rest on incomplete Application
     * X Pin Rest on completed Application (should fail)
     * X Pin Rest on Student Account (should fail)
     * - Searching by SSN (only after we figure out the hashing piece)
     * X Add Transcript with Id
     * X Add Transcript without Id (other)
     * - Update Existing Transcript (not available through web service)
     * X Remove Transcript
     * X Clear Transcripts
     * X Add Employment without Id
     * X Add Employment with Id
     * - Update Employment (Maybe later)
     * - Remove Employment (not available through web service)
     * X Check Payment
     * X Waiver Promo Payment
     * X Credit Card Payment
     * X ReferId (shouldn't update after set)
     * ? Change program, change EC (check that this business logic is correct)
     * ? Stay with same program but new form submission, keep EC (check business logic)
     * 
     * Pottential Issue (possible solution)
     * - Catch Bad Email Address (give better error message/experience)
     * - Provided an account id and no contacts link to the account (create new and case)
     * - Provided a contact id that doesn't have an account id listed (create new and case)
     * - Assigning EC fails to find a valid EC (provide a default EC)
     * - Find duplicate contact/account in the middle of the process (like after getting SSN)
     * - Cannot remove transcript because it already is being reviewed/entered
     */


    public static User createEC() {
        Profile profile = [SELECT id FROM Profile WHERE name = 'Enrollment Team' LIMIT 1];
        
        User ec = new User(
            firstName = 'NotTest', 
            lastName = 'NotMcGee', 
            Username = 'testnot1@wgu.edu', 
            Email = 'test1not@wgu.edu', 
            Alias = 'test1not', 
            CommunityNickname = 'test1not', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            ProfileId = profile.id, 
            LanguageLocaleKey = 'en_US', 
            pidm__c = '000000002', 
            TimeZoneSidKey = 'America/Denver', 
            isEmployee__c = true
        );
            
        insert ec;
            
        Id ecRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'UserAttributes__c' AND Name = 'Enrollment Team'][0].Id;
        
        UserAttributes__c attributes = new UserAttributes__c(
            Name = ec.firstName + ' ' + ec.lastName, 
            User__c = ec.Id, 
            AssignmentMultiplier__c = 2, 
            RecordTypeID = ecRecordType, 
            CollegeTeam__c = 'Test College', 
            AssignedPrograms__c = 'BA Mathematics 5-9; BA Early Childhood Education'
        );
        
        insert attributes;
        
        return ec;
    }



    @IsTest
        public static void testExistingInquiryLoginPinResetMatchEmail() {
        createExternalLead();
            // Create inquiry pieces
            // Mimic createRecordPageOneOfTwoPageFormRaw 
            // it is private and so cannot be called directly
            List<Map<String, String>> responses = TestCAREforceInquiryRESTServices.getInquiryQuestionsAndAnswers();
            String program = TestCAREforceInquiryRESTServices.getProgram();
            
            // Add question and answers to requiredQuestions
            Map<String, String> requiredQuestions = new Map<String, String>();
            requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
            requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));
            
            // Get Default Inquiry Test Values
            Map<String, String> inquiryFields = TestCAREforceInquiryRESTServices.getDefaultInquiryFieldsValues();
            
            // Attach Program
            inquiryFields.put('program', program);
            
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, null, true);
            
            String contactId = result.get('id');
            
            // Check application login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login(inquiryFields.get('email'), '111111', null, null);
            
            System.assert(response.status == 'Invalid Credentials');
            
            // Not Valid for Reset
            response = CAREforceApplicationLoginRESTService.login(inquiryFields.get('email'), null, inquiryFields.get('lastName'), inquiryFields.get('postalCode'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Reset Pin and login
            response = CAREforceApplicationLoginRESTService.login(inquiryFields.get('email'), '654321', inquiryFields.get('lastName'), inquiryFields.get('postalCode'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Check login with new pin (no reset)
            response = CAREforceApplicationLoginRESTService.login(inquiryFields.get('email'), '654321', null, null);
            System.assert(response.status == 'Invalid Credentials');
            
            // Set program
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            service.setPage1();
            service.fields.put('firstName', inquiryFields.get('firstName'));
            service.fields.put('lastName', inquiryFields.get('lastName'));
            service.fields.put('email', inquiryFields.get('email'));
            
            // Submit first page
            Map<String, String> results = service.run();
            
            // Make sure the inquiry id and applicant id are the same (matched records)
            System.assert(contactId == results.get('id'));
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testExistingInquiryMatchPhone() {
                createExternalLead();
            // Create inquiry pieces
            // Mimic createRecordPageOneOfTwoPageFormRaw 
            // it is private and so cannot be called directly
            List<Map<String, String>> responses = TestCAREforceInquiryRESTServices.getInquiryQuestionsAndAnswers();
            String program = TestCAREforceInquiryRESTServices.getProgram();
            
            // Add question and answers to requiredQuestions
            Map<String, String> requiredQuestions = new Map<String, String>();
            requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
            requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));
            
            // Get Default Inquiry Test Values
            Map<String, String> inquiryFields = TestCAREforceInquiryRESTServices.getDefaultInquiryFieldsValues();
            
            // Attach Program
            inquiryFields.put('program', program);
            
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, null, true);
            
            String contactId = result.get('id');
            
            List<Opportunity> opportunities = [SELECT ReferId__c FROM Opportunity WHERE StudentContact__c = :result.get('id')];
            System.assert(opportunities.size() == 1);
            System.assert(opportunities.get(0).ReferId__c != '4546');
            
            
            // Check application login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login(inquiryFields.get('email'), '111111', null, null);
            
            System.assert(response.status == 'Invalid Credentials');       
            
            // Set program
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            service.setPage1();
            service.fields.put('firstName', inquiryFields.get('firstName'));
            service.fields.put('lastName', inquiryFields.get('lastName'));
            service.fields.put('phone', inquiryFields.get('phone'));
            service.fields.put('referId', '4546');
            
            // Submit first page
            Map<String, String> results = service.run();
            
            // Make sure the inquiry id and applicant id are the same (matched records)
            System.assert(contactId == results.get('id'));
            
            // Check Referid
            opportunities = [SELECT ReferId__c FROM Opportunity WHERE StudentContact__c = :result.get('id')];
            System.assert(opportunities.size() == 1);
            // Should not have updated to be 2120
            System.assert(opportunities.get(0).ReferId__c != '4546');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testExistingPaidApplicationLoginPinResetMatchEmail() {
                createExternalLead();
            // Create application
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            service.setPage1();
            // Progress to paid application
            service.setPage5WithCreditCard();
            
            service.run();
            
            // Check application login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), service.fields.get('password'), null, null);
            
            System.assert(response.status == 'Application Complete');
            
            // Not Valid for Reset
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), null, service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Reset Pin and login
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '654321', service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Check login with new pin (no reset)
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '654321', null, null);
            System.assert(response.status == 'Invalid Credentials');
            
            // Create new application
            RunService service2 = new RunService();
            service.careProgramId = getProgram(2);
            
            service.setPage1();
            
            // Ensure the new email doesn't match the old one
            System.assert(service.fields.get('phone') != 'inobody@nowhere.com.fake.bad.email');
            service2.fields.put('phone', '');
            
            Test.startTest();
            Map<String, String> results = service.run(); 
            Test.stopTest();
            
            System.assert(results.get('status') == 'Email used by active application.');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testExistingMatriculateLoginPinResetMatchPhone() {
                createExternalLead();
            // Create application
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            service.setPage1();
            // Progress to paid application
            service.setPage5WithCreditCard();
            
            Map<String, String> existingResults = service.run();
            
            // Get record
            List<Opportunity> opportunities = [SELECT id FROM Opportunity WHERE StudentContact__c = :existingResults.get('id')];
            
            // Opportunity record exists
            System.assert(opportunities.size() == 1);
            
            // Progress to MATR
            Opportunity opportunity = opportunities.get(0);
            opportunity.CareStatus__c = 'MATR – Matriculated';
            
            // Save updates
            update opportunity;
            
            // Check application login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), service.fields.get('password'), null, null);
            
            System.assert(response.status == 'Application Complete');
            
            // Not Valid for Reset
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), null, service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Reset Pin and login
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '654321', service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Check login with new pin (no reset)
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '654321', null, null);
            System.assert(response.status == 'Invalid Credentials');
            
            // Create new application
            RunService service2 = new RunService();
            service.careProgramId = getProgram(2);
            
            service.setPage1();
            
            // Ensure the new email doesn't match the old one
            System.assert(service.fields.get('email') != 'inobody@nowhere.com.fake.bad.email');
            service2.fields.put('email', 'inobody@nowhere.com.fake.bad.email');
            
            Test.startTest();
            Map<String, String> results = service.run(); 
            Test.stopTest();
            
            System.assert(results.get('status') == 'Email used by active application.');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testLoginPINReset() {  
                createExternalLead();    
            Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            service.setPage1();
            Map<String, String> results = service.run();
            
            // Not Valid for Reset
            // Bad Email
            System.assert(service.fields.get('email') != 'bademail@nowhere.com.fake');
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('bademail@nowhere.com.fake', null, service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Bad Last name
            System.assert(service.fields.get('lastName') != 'Smith');
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), null, 'Smith', service.fields.get('zip'));
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            // Bad Zip
            System.assert(service.fields.get('zip') != '85236');
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), null, service.fields.get('lastName'), '85236');
            System.assert(response.status == 'Not Valid For PIN Reset');
            
            
            // Valid for Reset
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), null, service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.status == 'Valid For PIN Reset');
            
            // Reset Pin and login
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '654321', service.fields.get('lastName'), service.fields.get('zip'));
            System.assert(response.fields.get('firstName') == service.fields.get('firstName'));
            
            // Check login with new pin (no reset)
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '654321', null, null);
            System.assert(response.fields.get('firstName') == service.fields.get('firstName'));        
        }

    @IsTest
        public static void testNewApplicationAndLogin() {   
                createExternalLead();   
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            // Submit basic information
            service.setPage1();
            Map<String, String> results = service.run();
                
            // Check application login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), service.fields.get('password'), null, null);
            
            // Check that we got the same record
            System.assert(response.id == results.get('id'));
            
            // Test invalid password.
            // Ensure the bad password is bad
            System.assert(service.fields.get('password') != '111111');
            response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), '111111', null, null);
            System.assert(response.reason == 'Pin Did Not Match With Active Opportunity');
            
            // Test invalid email.
            // Unsure that the bad email is bad
            System.assert(service.fields.get('email') != 'inobody@nowhere.com.fake.bad.email');
            response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake.bad.email', service.fields.get('password'), null, null);
            System.assert(response.reason == 'Pin Did Not Match With Active Opportunity');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testAdditionalPageSSNandDOB() {    
                createExternalLead();  
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            service.setPage1();
            Map<String, String> results = service.run();    
            
            Test.startTest();
                service = new RunService();
                service.id = results.get('id');
                service.setPage2();
                results = service.run(); 
            Test.stopTest();
            
            Contact contact = [Select id, socialSecurityNumber__c FROM contact WHERE id = :results.get('id')];
            Opportunity opportunity = [SELECT id, graduatedHighSchool__c, nativeLanguageIsEnglish__c, CareStatus__c FROM Opportunity WHERE StudentContact__c = :results.get('id')];
            
            // Verify Page 2
            // Just fields getting set really
            // Would like to test the SSN hashing and searching by the hash once that work is complete
            System.assert(opportunity.nativeLanguageIsEnglish__c == true);
            System.assert(contact.socialSecurityNumber__c == '123456789');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testAdditionalPageAddTranscriptWithoutIdDeleteTranscript() {
                createExternalLead();    
            Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;    
        
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();   
            
            service.setPage1();
            Map<String, String> results = service.run();
            
            service = new RunService();
            service.id = results.get('id');
            service.setPage3();
            results = service.run();
            
            // Ensure the transcript got saved
            List<StudentTranscript__c> transcripts = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__r.StudentContact__c = :results.get('id')];
            System.assert(transcripts.size() == 1);
            
            // Test Transcript returned on login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.transcripts.get(0).get('institutionName') == 'Carl\'s Beautician and Auto Repair Reform School');  
            
            // Get transcript if from application response
            String transcriptID = results.get('transcriptIds');
            transcriptID = transcriptID.remove(';').trim();
            
            Test.startTest();
                service = new RunService();
                service.id = results.get('id');
                service.deleteTranscript(transcriptID);
                service.run();
            Test.stopTest();
            
            // Ensure transcript was deleted
            response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.transcripts.size() == 0);
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }

    @IsTest
        public static void testAdditionalPageNoTranscriptsAddTranscriptWithId() {  
                createExternalLead();  
            Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;    
        
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();   
            
            service.setPage1();
            Map<String, String> results = service.run();
            
            // Run None process
            service = new RunService();
            service.id = results.get('id');
            service.setNONEForTranscripts();
            results = service.run();
            
            // Test Transcript return from login.
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.transcripts.size() == 1); 
            System.assert(response.transcripts.get(0).get('degree') == 'NONE');
            
            // Create institution of Higher Education
            Id institutionRecordType = [select id from recordtype where name = 'Institution of Higher Ed' and sobjecttype = 'Account' limit 1].id;   
            Account institution = New Account(Name = '360 Degrees Beauty Academy');
            institution.recordtypeid = institutionRecordType;   
            insert institution;
            
            Test.startTest();
                // Add transcript
                service = new RunService();
                service.id = results.get('id');
                service.setPage3();
                
                service.transcripts.get(0).put('institutionName', '360 Degrees Beauty Academy');
                service.transcripts.get(0).put('transcriptinstitution', institution.id);
                
                results = service.run();
            Test.stopTest();

            // Ensure the transcript got saved and NONE was removed
            List<StudentTranscript__c> transcripts = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__r.StudentContact__c = :results.get('id')];
            System.assert(transcripts.size() == 1);
            
            // Test Transcript return from login.
            response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.transcripts.size() == 1); 
            System.assert(response.transcripts.get(0).get('institutionName') == '360 Degrees Beauty Academy');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }

    @IsTest
        public static void testAdditionalPageAddSecondTranscriptClearTranscripts() {
            createExternalLead();    
            Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;    
        
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();   
            
            service.setPage1();
            Map<String, String> results = service.run();
            
            // Set transcript
            service = new RunService();
            service.id = results.get('id');
            service.setPage3();
            results = service.run();
            
            // Ensure the transcript got saved
            List<StudentTranscript__c> transcripts = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__r.StudentContact__c = :results.get('id')];
            System.assert(transcripts.size() == 1);
            Test.startTest();
            // Add same transcript with new information
            service = new RunService();
            service.id = results.get('id');
            service.setPage3();
            
            service.transcripts.get(0).put('attendanceStarted', '2000-08-30');
            service.transcripts.get(0).put('attendanceEnd', '2005-04-15');
            
            
                results = service.run();
            
            
            // Adds a new institution
            transcripts = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__r.StudentContact__c = :results.get('id')];
            System.assert(transcripts.size() == 2);
            
            // Test Transcripts' return from login.
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.transcripts.size() == 2);
            
            // Run None process (to verify that it will clear existing transcripts)
            service = new RunService();
            service.id = results.get('id');
            service.setNONEForTranscripts();
            results = service.run();
            Test.stopTest();
            // Test Transcript return from login.
            response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.transcripts.size() == 1); 
            System.assert(response.transcripts.get(0).get('degree') == 'NONE');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id); 
            
            System.assert(true);
        }
    
    @IsTest
        public static void testAdditionalPageSaveOtherEmployment() {
                createExternalLead();      
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();  
            
            service.setPage1();
            Map<String, String> results = service.run();   
            
            service = new RunService();
            service.id = results.get('id');
            service.setPage4();
            
            Test.startTest();
                results = service.run();                        
            Test.stopTest();      
            
            // Test Employer return.
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.employments.get(0).get('employerOther') == 'Quizno\'s');   
            
            Account account = [SELECT id, studentContact__r.firstName, studentContact__r.lastName, studentContact__r.socialSecurityNumber__c FROM Account WHERE studentContact__r.firstName = 'Ima'];
            StudentAttributes__c attribute = [SELECT id, ParentsAttendedACollegeOrUniversity__c, ethnicbackground__c FROM StudentAttributes__c WHERE StudentAccount__c = :account.id];
            
            // Verify Page 4
            System.assert(response.fields.get('ethnicBackground') == 'Asian;Hispanic');
            System.assert(response.fields.get('parentsAttendCollege') == 'false');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }

    @IsTest
        public static void testAdditionalPageSaveEmployment() { 
                createExternalLead();     
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();  
            
            service.setPage1();
            Map<String, String> results = service.run();   
            
            service = new RunService();
            service.id = results.get('id');
            service.setPage4();
            
            service.employments.get(0).remove('employerOther');
            
            //Business Account
            // Create institution of Higher Education
            Id employerRecordType = [select id from recordtype where name = 'Business Account' and sobjecttype = 'Account' limit 1].id;   
            Account employer = New Account(Name = 'Bed, Bath, and Beyond-ish');
            employer.recordtypeid = employerRecordType;
            employer.Type = 'Employer';
            insert employer;
            
            service.employments.get(0).put('employerinformation', employer.id);
            
            Test.startTest();
                results = service.run();                        
            Test.stopTest();      
            
            // Test Employer return.
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.employments.get(0).get('employerInformation') == employer.id);   
            System.assert(response.employments.get(0).get('employerOther') == null);
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            Account account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testAdditionalPagePayByCheck() {  
                createExternalLead();    
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                  
            RunService service = new RunService();
            service.careProgramId = getProgram();    
            
            service.setPage1();
            Map<String, String> results = service.run();   
            
            Test.startTest();
                service = new RunService();
                service.id = results.get('id');
                service.setPage4(); // To set PRAP status
                service.setPage5WithCheck();
                results = service.run();             
            Test.stopTest();
            
            // Login should still work
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.fields.get('applicationFeeAmount') == '65.00');
    
            Account account = [SELECT id, studentContact__r.firstName, studentContact__r.lastName, studentContact__r.socialSecurityNumber__c FROM Account WHERE studentContact__r.firstName = 'Ima'];
            Opportunity opportunity = [SELECT id, graduatedHighSchool__c, nativeLanguageIsEnglish__c, CareStatus__c FROM Opportunity WHERE StudentContact__c = :response.id];        
            
            // Verify Page 5 - There is no page 5 values
            System.assert(opportunity.CareStatus__c == 'PRAP – Prospect Applied Online');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testAdditionalPagePayByWaiverCode() {  
                createExternalLead();    
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;
            
            List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
            User leadIntegration = users.get(0);
            
            System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
            
            createEC();
                  
            RunService service = new RunService();
            service.careProgramId = getProgram();    
            
            service.setPage1();
            Map<String, String> results = service.run();   
            
            Test.startTest();
                service = new RunService();
                service.id = results.get('id');
                service.setPage5WithWaiverCode();
                results = service.run();              
            Test.stopTest();
            
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.status == 'Application Complete');
    
            Account account = [SELECT id, studentContact__r.firstName, studentContact__r.lastName, studentContact__r.socialSecurityNumber__c FROM Account WHERE studentContact__r.firstName = 'Ima'];
            Opportunity opportunity = [SELECT id, graduatedHighSchool__c, nativeLanguageIsEnglish__c, CareStatus__c FROM Opportunity WHERE accountid = :account.id];        
            
            // Verify Page 5 - There is no page 5 values
            System.assert(opportunity.CareStatus__c == 'APAC – Application Complete, Paid');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, ownerid, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            opportunity = opportunities.get(0);
            
            // Check that EC is set (ownerid)
            System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testAdditionalPagePayByCreditCard() {     
                createExternalLead(); 
           Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                  
            RunService service = new RunService();
            service.careProgramId = getProgram();    
            
            service.setPage1();
            Map<String, String> results = service.run();   
            
            Test.startTest();
                service = new RunService();
                service.id = results.get('id');
                service.setPage5WithCreditCard();
                results = service.run();              
            Test.stopTest();
            
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login('inobody@nowhere.com.fake', '123456', null, null);
            System.assert(response.status == 'Application Complete');
    
            Account account = [SELECT id, studentContact__r.firstName, studentContact__r.lastName, studentContact__r.socialSecurityNumber__c FROM Account WHERE studentContact__r.firstName = 'Ima'];
            Opportunity opportunity = [SELECT id, graduatedHighSchool__c, nativeLanguageIsEnglish__c, CareStatus__c FROM Opportunity WHERE accountid = :account.id];        
            
            // Verify Page 5 - There is no page 5 values
            System.assert(opportunity.CareStatus__c == 'APAC – Application Complete, Paid');
            
            // Test connections
            // Contact Checks
            List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Nobody'];
            System.assert(contacts.size() == 1);
            Contact contact = contacts.get(0);
            
            // Account Checks
            List<Account> accounts = [SELECT id, StudentContact__c FROM Account WHERE id = :contact.accountId];
            System.assert(accounts.size() == 1);
            account = accounts.get(0);
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
            System.assert(opportunities.size() == 1);
            opportunity = opportunities.get(0);
            
            // Attributes Checks
            List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
            System.assert(attributes.size() == 1);
            StudentAttributes__c attribute = attributes.get(0);
            
            // To Account
            System.assert(contact.accountId == account.id);
            System.assert(opportunity.accountId == account.id);
            System.assert(attribute.StudentAccount__c == account.id);
            // To Contact
            System.assert(account.StudentContact__c == contact.id);
            System.assert(opportunity.StudentContact__c == contact.id);
            System.assert(attribute.StudentContact__c == contact.id);
            // To Student Attributes
            System.assert(opportunity.StudentAttributes__c == attribute.id);
        }
    
    @IsTest
        public static void testAdmissionsObjectCreated() {
            createExternalLead(); 
            Runtime__c c = new Runtime__c();
            c.Name = 'UsePersonAccounts';
            c.Value__c = 'false';
            insert c;  
            
            Runtime__c e = new Runtime__c();
            e.Name = 'environment';
            e.Value__c = 'test';
            insert e;               
                
            RunService service = new RunService();
            service.careProgramId = getProgram();
            
            // Submit basic information
            service.setPage1();
            Map<String, String> results = service.run();
                
            // Check application login
            CAREforceApplicationLoginRESTService.Response response = CAREforceApplicationLoginRESTService.login(service.fields.get('email'), service.fields.get('password'), null, null);
            
            // Check that we got the same record
            System.assert(response.id == results.get('id'));
            
            // Opportunity Checkes
            List<Opportunity> opportunities = [SELECT id, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :response.id];
            System.assert(opportunities.size() == 1);
            Opportunity opportunity = opportunities.get(0);
            
            // Admissions Check
            List<Admission__c> admissions = [SELECT id FROM Admission__c WHERE AdmissionReview__c = :opportunity.id];
            System.assert(admissions.size() == 1);
        }

        
    public class RunService {
        public String id = null;
        public Map<String, String> fields = new Map<String, String>();
        public List<Map<String, String>> transcripts = new List<Map<String, String>>();
        public List<Map<String, String>> employments = new List<Map<String, String>>();
        public List<String> deleteTranscripts = new List<String>();
        public Boolean noTranscripts = null;  
        public Id careProgramId = null;      
        
        public Map<String, String> run() {
            return CAREforceApplicationRESTService.apply(id, fields, transcripts, employments, deleteTranscripts, noTranscripts);
        }       
        
        public void setPage1() {
            fields.put('firstName', 'Ima');
            fields.put('lastName', 'Nobody');
            fields.put('prefix', 'Mrs');
            fields.put('middleInitial', 'R');
            fields.put('suffix', 'Ima');
            fields.put('email', 'inobody@nowhere.com.fake');
            fields.put('street', '1234 S North Western Easternton');
            fields.put('city', 'Unitville');
            fields.put('state', 'UT');
            fields.put('zip', '12345-6789');
            fields.put('country', 'US');
            fields.put('phone', '801-123-4567');
            fields.put('ext', '1234');
            fields.put('mobile', '801-123-4567');
            fields.put('acceptsTexting', '1');
            fields.put('internationalPhone', '1111232456789251');
            fields.put('nickname', 'Izzy');
            fields.put('campus', 'WGU');
            fields.put('learnMoreFinancialAid', 'true');
            fields.put('password', '123456');
            fields.put('referId', '2119');
            fields.put('graduateHighSchool', 'true');
            fields.put('earnedBachelors', 'false');
            fields.put('priorCollege', 'false');
            fields.put('collegeInterest', 'Something');
            fields.put('majorInterest', careProgramId);
            fields.put('username', 'sally');
        }
        
        public void setPage2() {
            fields.put('ssn', '123456789');
            fields.put('itn', '123456789');
            fields.put('gender', 'Female');
            fields.put('dob', '19750101');
            fields.put('englishNativeLanguage', 'true');
            fields.put('toeflScore', '42');
        }
        
        public void setPage3() {
            Map<String, String> transcript = new Map<String, String>();
            transcript.put('institutionName', 'Carl\'s Beautician and Auto Repair Reform School');
            transcript.put('city', 'Nowherescille');
            transcript.put('state', 'UT');
            transcript.put('zip', '12345');
            transcript.put('degree', 'BS');
            transcript.put('major', 'Tatooing and Accounting Management');
            transcript.put('minor', 'Bartending');
            transcript.put('dateGraduated', '1997-06-01');
            transcript.put('attendanceStarted', '1986-04-15');
            transcript.put('attendanceEnd', '1997-06-01');
            transcripts.add(transcript);
        }
        
        public void setNONEForTranscripts() {
            noTranscripts = true;
        }
        
        public void deleteTranscript(String id) {
            deleteTranscripts.add(id);
        }
        
        public void setPage4() {
            fields.put('ethnicBackground', 'Asian;Hispanic');
            fields.put('communityType', 'Non-Rural');
            fields.put('parentsAttendCollege', 'false');
            fields.put('parentsGraduated', 'false');
            fields.put('citizenshipStatus', 'Citizen');
            fields.put('militaryStatus', 'No Affiliation');
            fields.put('maritalStatus', 'Married');
            fields.put('applicationcomplete', 'true');
            
            Map<String, String> employement = new Map<String, String>();
            employement.put('employerOther', 'Quizno\'s');
            employement.put('annualIncome', '$16,000 - $24,999');
            employments.add(employement);
        }
        
        public void setPage5WithCheck() {
            fields.put('applicationFeeAmount', '65.00');       
        }
        
        public void setPage5WithCreditCard() {
            fields.put('paymentType', 'visa');
            fields.put('confirmationNumber', '123456798');
            fields.put('applicationFeeAmount', '65.00');
        }
        
        public void setPage5WithWaiverCode() {
            fields.put('paymentType', 'PROMO');
            fields.put('affiliateCode', 'WGU');
            fields.put('applicationFeeAmount', '65.00');    
            fields.put('discountAmount', '65.00');    
        }
    }
    
    public static String getProgram() {
        return getProgram(1);
    }
    
    public static String getProgram(Integer sequence) {
        WGUDegreeProgram__c degreeProgram = null;
        CareProgramMiddleEarth__c earth = null;
        
        if (sequence == 1 || sequence == null) {
            // Create WGU Degree Program
            degreeProgram = new WGUDegreeProgram__c(Name='BAECE', Title__c='Bachelor of Arts, Early Childhood Education', active__c=true, PAMSID__c=15);
            insert degreeProgram;
            
            // Create Marketing Program
            earth = new CareProgramMiddleEarth__c(Name='BA Early Childhood Education', active__c=true, BannerProgramCode__c=degreeProgram.id, InquiryProgram__c=true);
            insert earth;
        }
        else {
            // Create WGU Degree Program
            degreeProgram = new WGUDegreeProgram__c(Name='BAMA9', Title__c='Bachelor of Arts, Mathematics (5-9)', active__c=true, PAMSID__c=300000);
            insert degreeProgram;
            
            // Create Marketing Program
            earth = new CareProgramMiddleEarth__c(Name='BA Mathematics 5-9', active__c=true, BannerProgramCode__c=degreeProgram.id, InquiryProgram__c=true);
            insert earth;
        }

        // Return Marketing Program Id
        return earth.id;
    }
    
     private static void createExternalLead() {
        List<ExternalLeadContactControl__c> elist = new List<ExternalLeadContactControl__c>();
    
    	String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
     	ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '10';
        
        elist.add(wguELCC);
        
        insert elist;
    }
}