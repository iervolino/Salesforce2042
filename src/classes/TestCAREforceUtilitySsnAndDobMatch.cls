@IsTest
public class TestCAREforceUtilitySsnAndDobMatch {
    
    /**
     * Test MatchSsnAndDOB is working correctly
     */
    @IsTest
        public static void testMatch() {
            Test.startTest();
            
            // Create contact
            // dob set as date for easier testing later
            Date dob = Date.parse('01/01/1978');
            Contact contact = new Contact(firstName='Case', lastName = 'CareForceFixIt', 
                                          email='MACTESTER@Msn.com',  pidm__C = '12356321',  
                                          SocialSecurityNumber__c = '123456789', DateOfBirth__c = dob.format() );
            contact.recordtypeid = [SELECT id 
                                    FROM recordtype 
                                    WHERE name = 'ProspectRecord' AND 
                                          sobjecttype = 'Contact' 
                                    LIMIT 1].id;
            insert contact;
            
            Test.stopTest();
            
            // Get account (created by trigger)
            Account student = [SELECT id, pidm__C 
                               FROM Account 
                               WHERE studentcontact__r.id = :contact.id];
            
            // Test proper match
            Id validId = CAREforceUtility.MatchSsnAndDOB('123456789',dob);
            System.assert(validId == student.id);
            
            // Test bad match (should fail)
            Id invalidId = CAREforceUtility.MatchSsnAndDOB('112112112',dob);
            System.assert(invalidId == null);
        }
    
    /**
     * 
     */
    @IsTest
        public static void testMergeMatchingNotMatching() {
            Test.startTest();
            
            List<Account> accounts = new List<Account>();  
            List<Contact> contacts = new List<Contact>();
            List<Task> tasks = new List<Task>();
            List<Opportunity> opportunities = new List<Opportunity>(); 
            
            // Create mock account and contact records (already in the system)
            Date dob = Date.parse('01/01/1978');
            Account existingAccount = new Account(Name='CareMerge MergeFirstAccount');
            Contact existingContact = new Contact(firstName='CareMerge', lastName = 'MergeFirstAccount', 
                                               email='MACMerger@Msn.com',  pidm__C = '12356321',  
                                               SocialSecurityNumber__c = '123456789', DateOfBirth__c = dob.format(), 
                                               MailingStreet='123 Merge', MailingCity = 'Neverland', MailingState = 'CA',
                                               MailingCountry = 'USA', Status__c = 'REDI', Account = existingAccount);
            existingContact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
            existingAccount.StudentContact__c  = existingContact.id;
            
            // Create mock Opportunity (already in system)
            Opportunity exitingOpportunity = new Opportunity(Name='CareMerge MergeFirstAccount', AccountID = existingAccount.id, 
                                                   StudentContact__c = existingContact.id, StageName = 'Prospect', CloseDate = Date.today());
            
            // Add mock records to list
            accounts.add(existingAccount); 
            contacts.add(existingContact);
            opportunities.add(exitingOpportunity);
            
            // Add tasks to mock record (attached to contact)
            Task t = new Task(WhoId = existingContact.id, Subject='Task1');
            tasks.add(t);
            Task t2 = new Task(WhoId = existingContact.id, Subject='Task2');  
            tasks.add(t2);
            
            // Add tasks to mock record (Account)
            t = new Task(WhatId = existingAccount.id, Subject='Task3');
            tasks.add(t);
            t2 = new Task(WhatId = existingAccount.id, Subject='Task4');  
            tasks.add(t2);
            
            // Add tasks to mock record (Opportunity)
            t = new Task(WhatId = exitingOpportunity.id, Subject='Task5');
            tasks.add(t);
            t2 = new Task(WhatId = exitingOpportunity.id, Subject='Task6');  
            tasks.add(t2);
            
            
            
            //---Later Entry------                                 
            
            // Create mock account and contact records (newer to the system)
            Account newAccount = new Account(Name = 'CareMerge MergeSecondAccount');
            Contact newContact = new Contact(firstName='CareMerge', lastName = 'MergeSecondAccount', 
                                                email='MACMerger@Msn.com',  
                                                MailingStreet='123 Merge', MailingCity = 'Neverland', MailingState = 'CA',
                                                MailingCountry = 'USA', Status__c = 'REDI', Account = newAccount);
            newContact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
            newAccount.StudentContact__c  = newContact.id;                             
            
            // Create mock opportunity record (newer to the system)
            Opportunity newOpportunity = new Opportunity(Name='CareMerge MergeFirstAccount', AccountID = newAccount.id, 
                                                    StudentContact__c = newContact.id, StageName = 'Prospect', CloseDate = Date.today());
            
            // Add mock records to list
            accounts.add(newAccount); 
            contacts.add(newContact);
            opportunities.add(newOpportunity);
            
            // Add tasks to mock record (attached to contact)
            t = new Task(WhoId = newContact.id, Subject='Task7');
            tasks.add(t);
            
            // Add tasks to mock record (Account)
            t = new Task(WhatId = newAccount.id, Subject='Task8');
            tasks.add(t);
            
            // Add tasks to mock record (Opportunity)
            t2 = new Task(WhatId = newOpportunity.id, Subject='Task9');  
            tasks.add(t2);
            
            // Insert Records
            insert accounts;    
            insert contacts;
            insert opportunities;
            insert tasks;
            
            Test.stopTest(); 
            
            // Switched to use newer record (incomplete as that would be the one running through this test)
            Id a = CAREforceUtility.matchSSNAndDobAndMerge(newAccount.id, '999999999', Date.today());
            
            // If no match, the original (passed) id should be returned
            System.assert(newAccount.id == a);
        }
    
    @IsTest
        public static void testMergeMatching() {
            Test.startTest();
            
            List<Account> accounts = new List<Account>();  
            List<Contact> contacts = new List<Contact>();
            List<Task> tasks = new List<Task>();
            List<Opportunity> opportunities = new List<Opportunity>(); 
            
            // Create mock contact record (already in the system)
            Date dob = Date.parse('01/01/1978');
            String ssn = '123456789';
            Contact existingContact = new Contact(firstName='CareMerge', lastName = 'MergeFirstAccount', 
                                                  email='MACMerger@Msn.com',  pidm__C = '12356321',  
                                                  SocialSecurityNumber__c = ssn, DateOfBirth__c = dob.format(), 
                                                  MailingStreet='123 Merge', MailingCity = 'Neverland', MailingState = 'CA',
                                                  MailingCountry = 'USA', Status__c = 'REDI');
            existingContact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
            insert existingContact;
            
            // Gather account (created by Trigger)
            Account existingAccount = [Select id from Account where StudentContact__r.id = :existingContact.id];
            
            // Create mock student attributes
            StudentAttributes__c existingSA = New StudentAttributes__c(StudentAccount__c = existingAccount.id, StudentContact__c = existingContact.id);
            insert existingSA;
            
            // Create mock opportunity
            Opportunity exitingOpportunity = new Opportunity(Name='CareMerge MergeFirstAccount', AccountID = existingAccount.id, StudentAttributes__c = existingSA.id,
                                                             StudentContact__c = existingContact.id, StageName = 'Prospect', CloseDate = Date.today());
            insert exitingOpportunity;
            
            // Add tasks to mock record (attached to contact)
            Task t = new Task(WhoId = existingContact.id, Subject='Task1');
            tasks.add(t);
            Task t2 = new Task(WhoId = existingContact.id, Subject='Task2');  
            tasks.add(t2);
            
            // Add tasks to mock record (Account)
            t = new Task(WhatId = existingAccount.id, Subject='Task3');
            tasks.add(t);
            t2 = new Task(WhatId = existingAccount.id, Subject='Task4');
            tasks.add(t2);
            
            // Add tasks to mock record (Opportunity)
            t = new Task(WhatId = exitingOpportunity.id, Subject='Task5');
            tasks.add(t);
            t2 = new Task(WhatId = exitingOpportunity.id, Subject='Task6');  
            tasks.add(t2);
            
            
            
            //---Later Entry------  
            
            // Create new contact record (already in the system, but without SSN and Date of Birth)
            Contact newContact = new Contact(firstName='CareMerge', lastName = 'MergeSecondAccount', 
                                             email='MACMergerNot@Msn.com',  
                                             MailingStreet='123 Merge', MailingCity = 'Neverland', MailingState = 'CA',
                                             MailingCountry = 'USA', Status__c = 'APAC');
            newContact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;
            insert newContact;
            
            // Gather created account (created by Trigger)
            Account newAccount = [Select id from Account where StudentContact__r.id = :newContact.id];
            
            // Create Student Attribute Record
            StudentAttributes__c newSA = New StudentAttributes__c(StudentAccount__c = newAccount.id, StudentContact__c = newContact.id);
            insert newSA;
            
            // Create Opportunity
            Opportunity newOpportunity = new Opportunity(Name='CareMerge MergeFirstAccount', AccountID = newAccount.id, StudentAttributes__c = newSA.id,
                                                         StudentContact__c = newContact.id, StageName = 'Prospect', CloseDate = Date.today());
            insert newOpportunity;
            
            // Add tasks to mock record (attached to contact)
            t = new Task(WhoId = newContact.id, Subject='Task7');
            tasks.add(t);
            
            // Add tasks to mock record (Account)
            t = new Task(WhatId = newAccount.id, Subject='Task8');
            tasks.add(t);
            
            // Add tasks to mock record (Opportunity)
            t2 = new Task(WhatId = newOpportunity.id, Subject='Task9');  
            tasks.add(t2);
            
            
            // Add all tasks
            insert tasks; 
            
            Test.stopTest(); 
            
            // To match SSN must match existing account as well as date of birth
            // This should not match (only date of birth matches)
            Id a = CAREforceUtility.matchSSNAndDobAndMerge(newAccount.id, '123123123', dob);
            
            // Assertions ensures it doesn't match incorrectly and 
            // returns original account id when no match is found
            System.assert(existingAccount.id != a);
            System.assert(newAccount.id == a);
            
            // Test merge
            Id b = CAREforceUtility.matchSSNAndDobAndMerge(newAccount.id, ssn, dob);
            
            // Merge will return the id of the record that is matched to
            System.assert(existingAccount.id == b);
            
            // Account inherits all tasks?
            // There are 3 total Account tasks, 3 total Contact tasks, and 3 total Opportunity tasks
            List<Task> listofTasks = [Select id, subject, whoid, whatid from Task where accountId = :existingAccount.id ];
            
            // Only true it querying for tasks on Account gets tasks on sub-objects
            // otherwise it would be 3
            System.assert(listofTasks.size() == 9);
        }
}