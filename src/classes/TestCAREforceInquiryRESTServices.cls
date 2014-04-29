@IsTest
public class TestCAREforceInquiryRESTServices{
    /**
     * All System.runAs() statements have been commeneted out because they create errors
     * that are not seen in the code when tested manually.
     */
    
    /**
     * testOnePageInquiry is available to avoid causing errors in other tests that rely on it.
     */
    
    /**
     * Possible Tests Conditions (X = Included, ? = Unsure if they should be tested, - = Other ideas of tests): 
     * X new, incomplete record
     * X new, complete record (no questions)
     * X new, complete record (just required questions)
     * X new, complete record (required and optional questions)
     * X update without id, match phone (and name)
     * X update without id, match email (and name)
     * ? update without id, match email and phone (and less on the name)? Possible enhancement?
     * X new opportunity (existing contact)
     * X refresh existing opportunity (existing contact)
     * X update responses and grade
     * X update with id (account id)
     * X update with id (contact id)
     * X Bad Id
     * X Account created and attached through contact trigger 
     * X Datamark Submission (posting source and posting score fields, different user)
     * X Datamark Incomplete Submission (posting source and posting score fields, different user)
     * X Fieldrep Submission (has fieldrep value)
     * X Fieldrep Incomplete Submission (has fieldrep value)
     * X EC Submission (run as EC user)
     * X EC Incomplete Submission (run as EC user)
     * ? Change program, change EC (check that this business logic is correct)
     * ? Stay with same program but new form submission, keep EC (check business logic)
     * 
     * Pottential Issue (possible solution)
     * - Catch Bad Email Address (give better error message/experience)
     * - Provided an account id and no contacts link to the account (create new and case)
     * - Provided a contact id that doesn't have an account id listed (create new and case)
     * - Assigning EC fails to find a valid EC (provide a default EC)
     * - Filling out the Inquiry after application sets program away from application program (catch and stop change or create new opportunity)
     * - Enrollment question and answer don't line up (ignore adding)
     * - Partial enrollment response, either missing question or answer (ignore adding)
     */
    

//    @IsTest
    public static void testIncompleteSubmission() {
        createExternalLead();
        // Runtime variable (avoid certain processes)
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        // Detach phone (to make incomplete)
        inquiryFields.remove('phone');
        
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, true);
            Test.stopTest(); 
        
            // Ensure Lead creation is communicated
            System.assert(result.get('status') == 'incomplete');
            
            // Lead not graded, even though it was requeste
            System.assert(result.get('graded') == 'false'); 
        //}
        
        // Query to make sure Lead is in the system
        List<Lead> leads = [SELECT Id, FirstName FROM Lead WHERE LastName = 'Lead'];
        System.assert(leads.get(0).FirstName == 'Test');
    }
    
 //   @IsTest
    public static void testIncompleteECSubmission() {
            createExternalLead();
        // Runtime variable (avoid certain processes)
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        // Detach phone (to make incomplete)
        inquiryFields.remove('phone');
        
        User ec = createEC();
        
        System.assertNotEquals(ec, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(ec) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, true);
            Test.stopTest();
            
            // Ensure Lead creation is communicated
            System.assert(result.get('status') == 'incomplete');
            
            // Lead not graded, even though it was requeste
            System.assert(result.get('graded') == 'false');
        //}
        
        // Query to make sure Lead is in the system
        List<Lead> leads = [SELECT Id, FirstName FROM Lead WHERE LastName = 'Lead'];
        System.assert(leads.get(0).FirstName == 'Test');
    }
    
//   @IsTest
    public static void testIncompleteSubmissionDatamark() {
            createExternalLead();
        // Runtime variable (avoid certain processes)
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        inquiryFields.put('source', 'Datamark');
        inquiryFields.put('postingsource', 'All Star Directories');
        inquiryFields.put('postingscoreid', '43900963');
        
        // Detach email (to make incomplete)
        inquiryFields.remove('email');
        
        List<User> users = [SELECT id FROM User WHERE alias = 'dinte'];
        User datamark = users.get(0);
        
        System.assertNotEquals(datamark, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(datamark) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, true);
            Test.stopTest();
        
            // Ensure Lead creation is communicated
            System.assert(result.get('status') == 'incomplete');
            
            // Lead not graded, even though it was requeste
            System.assert(result.get('graded') == 'false');
        //}
        
        // Query to make sure Lead is in the system
        // Also verify that certain Datamark specific fields were properly set
        List<Lead> leads = [SELECT Id, FirstName, LeadSource, PostingSource__c, PostingScoreId__c FROM Lead WHERE LastName = 'Lead'];
        System.assert(leads.get(0).FirstName == 'Test');
        System.assert(leads.get(0).LeadSource == inquiryFields.get('source'));
        System.assert(leads.get(0).PostingSource__c == inquiryFields.get('postingsource'));
        System.assert(leads.get(0).PostingScoreId__c == inquiryFields.get('postingscoreid'));
    }
    
//    @IsTest
    public static void testIncompleteSubmissionFieldRep() {
            createExternalLead();
        // Runtime variable (avoid certain processes)
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        // Add fieldrep specific fields (fieldrep and hard coded referid)
        inquiryFields.put('fieldrep', 'Ann Miller');
        inquiryFields.put('referid', '659');
        
        // Detach email (to make incomplete)
        inquiryFields.remove('email');
        
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, true);
            Test.stopTest();
        
            // Ensure Lead creation is communicated
            System.assert(result.get('status') == 'incomplete');
            
            // Lead not graded, even though it was requeste
            System.assert(result.get('graded') == 'false');
        //}
        
        // Query to make sure Lead is in the system
        // Also verify that certain Datamark specific fields were properly set
        List<Lead> leads = [SELECT Id, FirstName, FieldRep__c FROM Lead WHERE LastName = 'Lead'];
        System.assert(leads.get(0).FirstName == 'Test');
        System.assert(leads.get(0).FieldRep__c == inquiryFields.get('fieldrep'));
    }
    
    @IsTest
    public static void testGradeWithoutQuestions() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;             
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);       
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.assert(result.get('grade') == 'NS');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of NS has been assigned
        System.assert(opportunity.leadGrade__c == 'NS');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
   // @IsTest
    public static void testECComplete() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;                  
        
        // Prepare Testing Objects
        String program = getProgram();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);        
    
        User ec = createEC();
        
        System.assertNotEquals(ec, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(ec) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.assert(result.get('grade') == 'NS');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assert(opportunity.ownerid == ec.Id);
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'NS');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
  //  @IsTest
    public static void testFieldRepComplete() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;             
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        // Add fieldrep specific fields (fieldrep and hard coded referid)
        inquiryFields.put('fieldrep', 'Ann Miller');
        inquiryFields.put('referid', '659');
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, null, null, false);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.assert(result.get('grade') == 'NS');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, FieldRep__c, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        System.assert(opportunity.FieldRep__c == inquiryFields.get('fieldrep'));
        
        // Check that a grade of NS has been assigned
        System.assert(opportunity.leadGrade__c == 'NS');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
  //  @IsTest
    public static void testDatamarkComplete() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;                  
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        inquiryFields.put('source', 'Datamark');
        inquiryFields.put('postingsource', 'All Star Directories');
        inquiryFields.put('postingscoreid', '43900963');
        
        // Attach Program
        inquiryFields.put('program', program);        
    
        List<User> users = [SELECT id FROM User WHERE alias = 'dinte'];
        User datamark = users.get(0);
        
        System.assertNotEquals(datamark, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(datamark) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, optionalQuestions, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.assert(result.get('grade') == 'B');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, LeadSource, PostingSource__c, PostingScoreId__c, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, datamark.id, 'Owner was not changed from lead integration to ec');
        
        System.assert(opportunity.LeadSource == inquiryFields.get('source'));
        System.assert(opportunity.PostingSource__c == inquiryFields.get('postingsource'));
        System.assert(opportunity.PostingScoreId__c == inquiryFields.get('postingscoreid'));
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'B');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    public static void testShortForm() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;             
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, null, false);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');

            System.assertEquals(result.get('grade'),'NS');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of NS has been assigned
        System.assert(opportunity.leadGrade__c == 'NS');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    public static void testOnePageForm() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;                  
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, optionalQuestions, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.assert(result.get('grade') == 'B');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'B');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    public static void testNoGradeWithResponses() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;                  
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, optionalQuestions, false);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.debug('#######846'+result.get('grade'));
            System.assertEquals(result.get('grade') , 'NS');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of NS has been assigned
  
        System.assert(opportunity.leadGrade__c == 'NS');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    public static void testPageOneOfTwoPageForm() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;             
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, null, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'inserted');
            System.assert(result.get('grade') == 'F');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of F has been assigned
        System.assert(opportunity.leadGrade__c == 'F');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
//    @IsTest
    public static void testBadId() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        User ec = createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();
        
        // Create Existing Record
        Map<String, String> ids = createRecordPageOneOfTwoPageFormRaw(responses, program);

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = New Map<String, String>();
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry('BadId', inquiryFields, null, optionalQuestions, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'Invalid ID');
        //}
    }
    
//    @IsTest
    public static void testPageTwoOfTwoPageFormWithAccountId() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();
        
        // Create Existing Record
        Map<String, String> ids = createRecordPageOneOfTwoPageFormRaw(responses, program);

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = New Map<String, String>();
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // Cannot run as Lead Integration - it throws and access error
        // when it goes to update the opportunity
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(ids.get('accountId'), inquiryFields, null, optionalQuestions, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'updated');
            System.assert(result.get('newopportunity') == 'false');
            System.assert(result.get('grade') == 'B');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId, Phone FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'B');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
 //   @IsTest
    public static void testPageTwoOfTwoPageFormWithContactId() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();
        
        // Create Existing Record
        Map<String, String> ids = createRecordPageOneOfTwoPageFormRaw(responses, program);

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = New Map<String, String>();
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // Cannot run as Lead Integration - it throws and access error
        // when it goes to update the opportunity
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(ids.get('contactId'), inquiryFields, null, optionalQuestions, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'updated');
            System.assert(result.get('newopportunity') == 'false');
            System.assert(result.get('grade') == 'B');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId, Phone FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'B');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
  //  @IsTest
    public static void testMatchPhoneCreateOpportunity() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();
        
        // Create Existing Record
        createInquiryContactRaw();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));

        // Add question and answers to optionalQuestions
        Map<String, String> optionalQuestions = new Map<String, String>();
        optionalQuestions.put(responses.get(2).get('question'), responses.get(2).get('answer'));
        optionalQuestions.put(responses.get(3).get('question'), responses.get(3).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        // Change Email (force match on phone)
        inquiryFields.put('email', 'myemail2@unitest.wgu.edu.fake');
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // RunAs creates errors that are not seen in the code when tested manually.
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, optionalQuestions, true);
            Test.stopTest();
        
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'updated');
            System.assert(result.get('newopportunity') == 'true');
            System.assert(result.get('grade') == 'B');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId, otherEmail__c FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Email hase been updated
        System.assert(contact.otherEmail__c == 'myemail2@unitest.wgu.edu.fake');
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        List<Opportunity> opportunities = [SELECT id, ownerid, leadGrade__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        Opportunity opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'B');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
    
   // @IsTest
    public static void testMatchEmailUpdateOpportunityAndResponses() {
            createExternalLead();
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;
        
        // Prepare Testing Objects
        String program = getProgram();
        String program2 = getProgram(2);
        createEC();
        List<Map<String, String>> responses = getInquiryQuestionsAndAnswers();
        
        // Create Previous Existing Record
        Map<String, String> ids = createRecordPageOneOfTwoPageFormRaw(responses, program);
        
        // Ensure standards are expected
        // To test change, we need to ensure there is a change
        List<Opportunity> opportunities = [SELECT id, MarketingProgram__c, referid__c, LeadGrade__c FROM Opportunity WHERE StudentContact__c = :ids.get('contactId')];
        Opportunity opportunity = opportunities.get(0);
        System.assert(opportunity.MarketingProgram__c == program);
        System.assert(opportunity.referid__c == '2120');
        System.assert(opportunity.LeadGrade__c == 'F');
        
        // Standard for Questions
        List<EnrollmentResponses__c> startingResponses = [SELECT id, AnswerQuestion__r.Value__c FROM EnrollmentResponses__c WHERE CAREProfile__c = :opportunity.id AND QuestionNumber__r.QuestionText__c = 'Positive Experence'];
        String startingValue = startingResponses.get(0).AnswerQuestion__r.Value__c;
        System.assert(startingValue == 'Test VP');
        
        // Add another available response for a question
        // This answer is artificially weighted to  get a higher grade when regraded
        EnrollmentAnswers__c newAnswer = new EnrollmentAnswers__c();
        List<EnrollmentQuestions__c> questions = [SELECT id FROM EnrollmentQuestions__c WHERE QuestionText__c = 'Positive Experence'];
        newAnswer.AnswerText__c = 'Super Positive';
        newAnswer.EnrollmentQuestion__c = questions.get(0).id;
        newAnswer.Multiplier__c = 1;
        newAnswer.MultiplierValue__c = 3;
        newAnswer.Value__c = 'Super Positive';
        insert newAnswer;
        
        // Add question and answers to requiredQuestions
        // New answer for first question
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), newAnswer.id);
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues('5180');
        
        // Change Phone (force match on email)
        // Update phone
        inquiryFields.put('phone', '801-555-6368');
        
        // Change program, should update
        inquiryFields.put('program', program2);
    
        List<User> users = [SELECT id FROM User WHERE alias = 'linte'];
        User leadIntegration = users.get(0);
        
        System.assertNotEquals(leadIntegration, null, 'Unable to find user.');
        
        // Cannot run as Lead Integration - it throws and access error
        // when it goes to update the opportunity
        //System.runAs(leadIntegration) {
            Test.startTest();
            Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, null, true);
            Test.stopTest();
            
            // Assert that the response map is returning correct values.
            System.assert(result.get('status') == 'updated');
            System.assert(result.get('newopportunity') == 'false');
            System.assert(result.get('grade') == 'B');
        //}
        
        // Contact Checks
        List<Contact> contacts = [SELECT id, accountId, Phone FROM Contact WHERE lastName = 'Lead'];
        
        // Contact record exists
        System.assert(contacts.size() == 1);
        
        Contact contact = contacts.get(0);
        
        // Email hase been updated
        System.assert(contact.Phone == '(801) 555-6368');
        
        // Account Checks
        List<Account> accounts = [SELECT id, StudentContact__c, Name FROM Account WHERE id = :contact.accountId];
        
        // Account record exists
        System.assert(accounts.size() == 1);
        
        Account account = accounts.get(0);
        
        // Account has the correct name
        System.assert(account.Name == 'Test Lead');
        
        // Opportunity Checkes
        opportunities = [SELECT id, ownerid, MarketingProgram__c, leadGrade__c, referid__c, accountId, StudentContact__c, StudentAttributes__c FROM Opportunity WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(opportunities.size() == 1);
        
        opportunity = opportunities.get(0);
        
        // Check that EC is set (ownerid)
        System.assertNotEquals(opportunity.ownerid, leadIntegration.id, 'Owner was not changed from lead integration to ec');
        
        // Check that a grade of B has been assigned
        System.assert(opportunity.leadGrade__c == 'B');
        
        // Program was updated
        System.assert(opportunity.MarketingProgram__c == program2);
        
        // ReferId was not updated
        System.assert(opportunity.referid__c == '2120');
        
        // Attributes Checks
        List<StudentAttributes__c> attributes = [SELECT id, StudentContact__c, StudentAccount__c FROM StudentAttributes__c WHERE StudentContact__c = :contact.id];
        
        // Opportunity record exists
        System.assert(attributes.size() == 1);
        
        StudentAttributes__c attribute = attributes.get(0);
        
        // Test connections
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
        
        // Questions Check
        List<EnrollmentResponses__c> newResponses = [SELECT id, AnswerQuestion__r.Value__c FROM EnrollmentResponses__c WHERE CAREProfile__r.StudentContact__c = :contact.id AND QuestionNumber__r.QuestionText__c = 'Positive Experence'];
        String newValue = newResponses.get(0).AnswerQuestion__r.Value__c;
        
        // Ensure that the new value has been set
        // And is different than initial
        System.assert(newValue == 'Super Positive');
        System.assertNotEquals(newValue, startingValue, 'Cannot test answer change if both answers are the same');
    }
    
    public static Map<String, String> getDefaultInquiryFieldsValues() {
        return getDefaultInquiryFieldsValues('2120');
    }
    
    public static Map<String, String> getDefaultInquiryFieldsValues(String referId) {
        Map<String, String> inquiryFields = new Map<String, String>();
        
        // Add defaults for all inquiry fields that are not references
        inquiryFields.put('firstName', 'Test');
        inquiryFields.put('lastName', 'Lead');
        inquiryFields.put('email', 'myemail@unitest.wgu.edu.fake');
        inquiryFields.put('street', '1234 SW NorthEast Dr.');
        inquiryFields.put('city', 'Salt Lake City');
        inquiryFields.put('state', 'UT');
        inquiryFields.put('postalCode', '12345-6789');
        inquiryFields.put('country', 'USA');
        inquiryFields.put('phone', '801-555-5555');
        inquiryFields.put('extension', '0132');
        inquiryFields.put('mobile', '123-123-1234');
        inquiryFields.put('acceptsTexting', '1');
        
        // Hidden Fields
        //createReferId(referId);
        inquiryFields.put('ReferID', referId);
        inquiryFields.put('Campus', 'WGU');
        
        return inquiryFields;
    }
    
    public static String getAccountId(String contactId) {
        Contact contact = [SELECT accountId FROM Contact WHERE Id = :contactId];
        
        return contact.accountId;
    }
    
    // Until Application test class is updated
    public static void testOnePageInquiry() {
        createRecordPageOneOfTwoPageFormRaw(getInquiryQuestionsAndAnswers(), getProgram());
    }
    
    /**
     * Raw because it is not running any future methods etc.
     */
    private static Map<String, String> createRecordPageOneOfTwoPageFormRaw(List<Map<String, String>> responses, String program) {
        Map<String, String> ids = New Map<String, String>();

        // Add question and answers to requiredQuestions
        Map<String, String> requiredQuestions = new Map<String, String>();
        requiredQuestions.put(responses.get(0).get('question'), responses.get(0).get('answer'));
        requiredQuestions.put(responses.get(1).get('question'), responses.get(1).get('answer'));
        
        // Get Default Inquiry Test Values
        Map<String, String> inquiryFields = getDefaultInquiryFieldsValues();
        
        // Attach Program
        inquiryFields.put('program', program);
        
        Map<String, String> result = CAREforceInquiryRESTServices.inquiry(null, inquiryFields, requiredQuestions, null, true);
        
        String contactId = result.get('id');
        
        ids.put('accountId', getAccountId(contactId));
        ids.put('contactId', contactId);
        
        return ids;
    }
    
    /**
     * Raw because it is not running any future methods etc.
     * Only setting Inquiry REST service fields
     * This is only as accurate as it is kept up with the inquiry rest services
     */
    public static Contact createInquiryContactRaw() {
        // Contact Record
        Contact contact = New Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Lead';
        contact.MailingStreet = '1234 SW NorthEast Dr.';
        contact.MailingCity = 'Salt Lake City';
        contact.MailingState = 'UT';
        contact.MailingPostalCode = '12345-6789';
        contact.MailingCountry = 'USA';
        contact.otherEmail__c = 'myemail@unitest.wgu.edu.fake';
        contact.Phone = '(801) 555-5555';
        contact.HomePhone = '(801) 555-5555';
        contact.phoneExtension__c = '0132';
        contact.MobilePhone = '(123) 123-1234';
        contact.OtherPhone = '(123) 123-1234';
        contact.acceptsTexting__c = true;
        
        // Get record type id
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;   
        
        // Some other systems still rely on this flag
        // Set it even though it is not technically true any more
        contact.isPersonAccount__c = true;
        
        insert contact;
        
        return contact;
    }

    public static List<Map<String, String>> getInquiryQuestionsAndAnswers() {
        // Ensure that this is a test (avoid triggers for Eloqua)
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;       

        // Create Response Array
        List<Map<String, String>> response = new List<Map<String, String>>();

        // Create Enrollment questions
        EnrollmentQuestions__c q1 = new EnrollmentQuestions__c();
        EnrollmentQuestions__c q2 = new EnrollmentQuestions__c();
        EnrollmentQuestions__c q3 = new EnrollmentQuestions__c();
        EnrollmentQuestions__c q4 = new EnrollmentQuestions__c();

        // Create Enrollment Answers
        EnrollmentAnswers__c a1 = new EnrollmentAnswers__c();
        EnrollmentAnswers__c a2 = new EnrollmentAnswers__c();
        EnrollmentAnswers__c a3 = new EnrollmentAnswers__c();
        EnrollmentAnswers__c a4 = new EnrollmentAnswers__c();

         // Create Enrollment Responses
         Map<String, String> r1 = new Map<String, String>();
         Map<String, String> r2 = new Map<String, String>();
         Map<String, String> r3 = new Map<String, String>();
         Map<String, String> r4 = new Map<String, String>();       

        // Group 1 - Grad Date
        // Group 1 Question
        q1.QuestionText__c = 'Date of Grad Test';
        q1.GradingType__c = 'Grad Date';
        q1.QuestionStatus__c = 'Active';
        insert q1;

        // Group 1 Answer
        a1.AnswerText__c = '2004';
        a1.EnrollmentQuestion__c = q1.id;
        a1.Multiplier__c = 1;
        a1.MultiplierValue__c = 1;
        a1.Value__c = '2004';
        insert a1;

        // Group 1 Response
        r1.put('question', q1.id);
        r1.put('answer', a1.id);

        response.add(r1);

        // Group 2 
        // Group 2 Question
        q2.QuestionText__c = 'Positive Experence';
        q2.GradingType__c = 'Normal';
        q2.QuestionStatus__c = 'Active';
        insert q2;

        // Group 2 Answer
        a2.AnswerText__c = 'Test Very Pos';
        a2.EnrollmentQuestion__c = q2.id;
        a2.Multiplier__c =  1.37647077038823;
        a2.MultiplierValue__c = 1;
        a2.Value__c = 'Test VP';
        insert a2;

        // Group 2 Response
        r2.put('question', q2.id);
        r2.put('answer', a2.id);

        response.add(r2);

        // Group 3 
        // Group 3 Question
        q3.QuestionText__c = 'Rate as Online Learner';
        q3.GradingType__c = 'Normal';
        q3.QuestionStatus__c = 'Active';
        insert q3;

        // Group 3 Answer
        a3.AnswerText__c = 'Test LVG';
        a3.EnrollmentQuestion__c = q3.id;
        a3.Multiplier__c =  0.479126413550687;
        a3.MultiplierValue__c = 1;
        a3.Value__c = 'Test LVG';
        insert a3;

        // Group 3 Response
        r3.put('question', q3.id);
        r3.put('answer', a3.id);

        response.add(r3);
    
        // Group 4 
        // Group 4 Question
        q4.QuestionText__c = 'Time Learning';
        q4.GradingType__c = 'Normal';
        q4.QuestionStatus__c = 'Active';
        insert q4;
        
        // Group 4 Answer
        a4.AnswerText__c = 'Test 21H';
        a4.EnrollmentQuestion__c = q4.id;
        a4.Multiplier__c  = 1.32053380265839;
        a4.MultiplierValue__c = 1;
        a4.Value__c = '21H';
        insert a4;

        // Group 4 Response
        r4.put('question', q4.id);
        r4.put('answer', a4.id);

        response.add(r4);

        // Return all questions and answers that were just created
        return response;
    }
    
    /*
    public static void createReferId(String referId) {
        MarketingSourceCode__c source = New MarketingSourceCode__c(ReferId__c = referId);
        
        insert source;
    }
    */
    
    public static String getProgram() {
        return getProgram(1);
    }

    public static String getProgram(Integer sequence) {
        CAREProgram__c careProgram = null;
        CareProgramMiddleEarth__c earth = null;
        
        if (sequence == 1 || sequence == null) {
            // Create CARE Program
            careProgram = new CAREProgram__c(Name='BAECE', ProgramLabel__c='B.A. in Early Childhood Education', active__c=true);
            insert careProgram;
            
            // Create Marketing Program
            earth = new CareProgramMiddleEarth__c(Name='BA Early Childhood Education', active__c=true, CAREProgramCode__c=careProgram.id, InquiryProgram__c=true);
            insert earth;
        }
        else {
            // Create CARE Program
            careProgram = new CAREProgram__c(Name='BAMA', ProgramLabel__c='B.A. in Mathematics (5-9 or 5-12)', active__c=true);
            insert careProgram;
            
            // Create Marketing Program
            earth = new CareProgramMiddleEarth__c(Name='BA Mathematics 5-9', active__c=true, CAREProgramCode__c=careProgram.id, InquiryProgram__c=true);
            insert earth;
        }

        // Return Marketing Program Id
        return earth.id;
    }
    
    public static User createEC() {
        Profile profile = [SELECT id FROM Profile WHERE name = 'Enrollment Team' LIMIT 1];
        
        User ec = new User(
            firstName = 'Test', 
            lastName = 'McGee', 
            Username = 'test1@wgu.edu', 
            Email = 'test1@wgu.edu', 
            Alias = 'test1', 
            CommunityNickname = 'test1', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            ProfileId = profile.id, 
            LanguageLocaleKey = 'en_US', 
            pidm__c = '000000001', 
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
    
      private static void createExternalLead()
        {
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