@IsTest
public class TestEmailAddressToBannerUtilities{
    @IsTest
    public static void testLinkingErrors() {   
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        
        Contact baggins = [SELECT Id, PIDM__C FROM Contact WHERE LastName = 'Baggins'];    
        EmailAddress__c email = new EmailAddress__c(Contact__c = baggins.Id, Email__c = 'iexist@unit.test', 
                                                    EmailCode__c = 'CPMA', PIDM__c = baggins.PIDM__c,
                                                    PrimaryEmail__c = false, StatusIndicator__c = 'Inactive');

        insert email;
        
        Test.startTest();

        List<EmailAddressToBanner__c> testRecords = new List<EmailAddressToBanner__c>();
        
        // New Email.
        EmailAddressToBanner__c e2b1 = new EmailAddressToBanner__c(ContactIdIN__c = 'fhjkhfjkdlhfjkh', PIDMIN__c = baggins.PIDM__c, EmailCodeIN__c = 'EM', 
                                                                   PrimaryEmailIN__c = true, StatusIndicatorIN__c = 'A', EmailAddressIN__c = 'testme@unit.test');
        
        testRecords.add(e2b1);
        
        // New Bad Email.
        EmailAddressToBanner__c e2b3 = new EmailAddressToBanner__c(ContactIdIN__c = 'fhjkhfjkdlhfjkh', PIDMIN__c = baggins.PIDM__c, EmailCodeIN__c = 'EM', 
                                                                   PrimaryEmailIN__c = true, StatusIndicatorIN__c = 'A', EmailAddressIN__c = 'testme@unit.test.');
        testRecords.add(e2b3);   
        
        // Existing Email.
        EmailAddressToBanner__c e2b2 = new EmailAddressToBanner__c(ContactIdIN__c = baggins.Id, PIDMIN__c = baggins.PIDM__c, EmailCodeIN__c = 'EM', 
                                                                   PrimaryEmailIN__c = true, StatusIndicatorIN__c = 'I', EmailAddressIN__c = 'iexist@unit.test');
        
        testRecords.add(e2b2);        
        insert testRecords; 
        
        testRecords = [SELECT Id, EmailAddress__c, EmailAddressIN__c, SynchronizationError__c FROM EmailAddressToBanner__c];
        
        Boolean record1Mapped = false;
        Boolean record2Mapped = false;
        
        for (EmailAddressToBanner__c record : testRecords) {
            if (record.EmailAddressIN__c == 'testme@unit.test') {
                record1Mapped = record.SynchronizationError__c != null;
            }
            
            if (record.EmailAddressIN__c == 'iexist@unit.test') {
                record2Mapped = record.SynchronizationError__c != null;
            }            
        }
        
        System.assert(record1Mapped && record2Mapped);        
    }
    
    @IsTest
    public static void testLinkingAndUpdate() {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        
        Contact baggins = [SELECT Id, PIDM__C FROM Contact WHERE LastName = 'Baggins'];
        
        EmailAddress__c email = new EmailAddress__c(Contact__c = baggins.Id, Email__c = 'iexist@unit.test', 
                                                    EmailCode__c = 'CPMA', PIDM__c = baggins.PIDM__c,
                                                    PrimaryEmail__c = false, StatusIndicator__c = 'Inactive');
        
        insert email;
        
        Test.startTest();

        List<EmailAddressToBanner__c> testRecords = new List<EmailAddressToBanner__c>();
        
        // New Email.
        EmailAddressToBanner__c e2b1 = new EmailAddressToBanner__c(ContactIdIN__c = baggins.Id, PIDMIN__c = baggins.PIDM__c, EmailCodeIN__c = 'EM', 
                                                                   PrimaryEmailIN__c = true, StatusIndicatorIN__c = 'A', EmailAddressIN__c = 'testme@unit.test');
        
        testRecords.add(e2b1);
        
        // Existing Email.
        EmailAddressToBanner__c e2b2 = new EmailAddressToBanner__c(ContactIdIN__c = baggins.Id, PIDMIN__c = baggins.PIDM__c, EmailCodeIN__c = 'OT', 
                                                                   PrimaryEmailIN__c = false, StatusIndicatorIN__c = 'I', EmailAddressIN__c = 'iexist@unit.test');
        
        testRecords.add(e2b2);        
        
        
        insert testRecords;
        
        Test.stopTest();
        
        testRecords = [SELECT Id, EmailAddress__c, EmailAddressIN__c, SynchronizationError__c, EmailCodeIN__c FROM EmailAddressToBanner__c];
        
        Boolean record1Mapped = false;
        Boolean record2Mapped = false;
        
        for (EmailAddressToBanner__c record : testRecords) {
            if (record.EmailAddressIN__c == 'testme@unit.test') {
                record1Mapped = record.EmailAddress__c != null && record.SynchronizationError__c == null;
            }
            
            if (record.EmailAddressIN__c == 'iexist@unit.test') {
                record2Mapped = record.EmailAddress__c  == email.Id && record.SynchronizationError__c == null && record.EmailCodeIN__c == 'OT';
                
            }            
        }
        
        System.assert(record1Mapped && record2Mapped);
    }
}