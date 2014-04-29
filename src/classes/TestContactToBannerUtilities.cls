@IsTest
public class TestContactToBannerUtilities{
    @IsTest
    public static void updateLastLoginDate() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        Campus__c campus = new Campus__c(name='M', Contact__c = 'WGU Main', StudentAttributes__c = 'WGU');
        insert campus;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1),
                                                           CampusCodeIN__c = 'M'
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            // Check only update to Last Login Date
            DateTime testTime = DateTime.now();
            record.LastLoginIn__c = testTime;
            record.FirstNameIN__c = 'Changed';
            update record;        
        
        Test.stopTest();
        
        // Verify only last login changes but name stays the same.
        Contact confirmContact = [SELECT LastPortalLogin__c, FirstName, CampusCode__c FROM Contact WHERE Id = :record.Contact__c];
        
        System.assert(confirmContact.LastPortalLogin__c.isSameDay(testTime));         
        System.assert(confirmContact.FirstName == baggins.FirstName);
        System.assert(confirmContact.CampusCode__c == 'WGU Main');
    }
    
    @IsTest
    public static void updateCheckIN() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];      
        
        Test.startTest();   
            
            ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                               LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                               CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                               CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                               OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                               LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                              );
            
            insert record;    
        
        Test.stopTest();
        
        // Check IN settings.
        ContactToBanner__c confirm = [SELECT Id, RecordType.Name, SynchronizationError__c FROM ContactToBanner__c WHERE Contact__c = :baggins.Id];
        System.debug(confirm);
        System.assert(confirm.RecordType.Name == 'Prospect');
        
        baggins = [SELECT Id, Status__c FROM Contact WHERE LastName = 'Baggins'];
        System.assert(baggins.Status__c == 'IN');  
    }
    
    @IsTest
    public static void updateCheckAS() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            record.StatusIN__c = 'AS';
            update record;    
        
        Test.stopTest();
        
        ContactToBanner__c confirm = [SELECT Id, RecordType.Name, SynchronizationError__c FROM ContactToBanner__c WHERE Contact__c = :baggins.Id];
        System.assert(confirm.RecordType.Name == 'Student');
        
        baggins = [SELECT Id, Status__c FROM Contact WHERE LastName = 'Baggins'];
        System.assert(baggins.Status__c == 'AS');    
    }    
    
    @IsTest
    public static void updateCheckGR() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            record.StatusIN__c = 'GR';
            update record;    
        
        Test.stopTest();
        
        ContactToBanner__c confirm = [SELECT Id, RecordType.Name, SynchronizationError__c FROM ContactToBanner__c WHERE Contact__c = :baggins.Id];
        System.assert(confirm.RecordType.Name == 'Returning');
        
        baggins = [SELECT Id, Status__c FROM Contact WHERE LastName = 'Baggins'];
        System.assert(baggins.Status__c == 'GR');    
    }      
    
    @IsTest
    public static void updateCheckInvalidEmailField() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            record.MyWGUEmailIN__c = 'someeo;jfkldjs@fjkdfos.fds.';
            update record;    
        
        Test.stopTest();
        
        ContactToBanner__c confirm = [SELECT Id, RecordType.Name, SynchronizationError__c FROM ContactToBanner__c WHERE Contact__c = :baggins.Id];
        System.assert(confirm.SynchronizationError__c.indexOf('Email') > 0);   
    }    
    
    @IsTest
    public static void updateCheckErrorDoesNotSync() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'someeo;jfkldjs@fjkdfos.fds.',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            record.MyWGUEmailIN__c = 'me@my.wgu.edu';
            update record;    
        
        Test.stopTest();
        
        ContactToBanner__c confirm = [SELECT Id, RecordType.Name, SynchronizationError__c FROM ContactToBanner__c WHERE Contact__c = :baggins.Id];
        System.assert(confirm.SynchronizationError__c.indexOf('Email') > 0); // System error from previous update.  
    } 

    @IsTest
    public static void updateCheckResynchronize() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            record.SynchronizationError__c = 'Existing Error.';
            record.ResynchronizeToSalesforce__c = true;
            record.BannerEventDateIN__c = DateTime.now();
            update record;    
        
        Test.stopTest();
        
        ContactToBanner__c confirm = [SELECT Id, ResynchronizeToSalesforce__c, SynchronizationError__c FROM ContactToBanner__c WHERE Contact__c = :baggins.Id];
        System.assert(confirm.SynchronizationError__c == null);      
        System.assert(!confirm.ResynchronizeToSalesforce__c);
    }    
   
    @IsTest
    public static void updateCheckLastAAVDate() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins'];
        
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1)
                                                          );
        
        insert record;         
        
        Test.startTest();   
            
            record.LastAAVDateIN__c = DateTime.now();
            update record;  
        
        Test.stopTest();
        
        baggins = [SELECT Id, LastDateOfAAV__c FROM Contact WHERE LastName = 'Baggins'];
        System.assert(baggins.LastDateOfAAV__c != null); 
    }
    
    @IsTest
    public static void checkUpdateReadyForBanner() {
        Runtime__c environment = new Runtime__c(name='environment', value__c = 'test');
        insert environment;
        
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName, AccountId, BannerReady__c FROM Contact WHERE LastName = 'Baggins'];
        
        System.assertEquals(false, baggins.BannerReady__c);
        
        Opportunity testOpp = new Opportunity(Name = 'FrodoTest BagginsTest', CareStatus__c = 'APIN – Application Incomplete APCO', AccountId = baggins.AccountId,
                                              CloseDate = Date.today(), StageName = 'Applicant', StudentContact__c = baggins.Id);
        insert testOpp;
        
        testOpp.CareStatus__c = 'APAC – Application Complete, Paid';
                        
        Test.startTest(); 
            update testOpp; 
        Test.stopTest();
        
        baggins = [SELECT Id, PIDM__C, FirstName, LastName, AccountId, BannerReady__c FROM Contact WHERE LastName = 'Baggins'];  
        
        System.assertEquals(true, baggins.BannerReady__c);
    }
    
    @isTest
    public static void testUpdateContactBannerData()
    {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__C, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        baggins.Pidm__c = null;
        baggins.WGUEmail__c = null;
        baggins.Username__c = null;
        baggins.StudentId__c = null;
        update baggins;
         
        ContactToBanner__c record = new ContactToBanner__c(Contact__c = baggins.Id, FirstNameIN__c = baggins.FirstName,
                                                           LastNameIN__c = baggins.LastName, StatusIN__c = 'IN', HistoricallyAttemptedCUsIN__c = 0,
                                                           CurrentTermEnrolledCUsIN__c = 0, HistoricallyCompletedCUsIN__c = 0, 
                                                           CurrentTermCompletedCUsIN__c = 0, MyWGUEmailIN__c = 'me@my.wgu.edu',
                                                           OtherEmailIN__c = 'other@unit.test', LastSynchronizedFromBanner__c = Datetime.now(),
                                                           LastLoginIn__c = DateTime.newInstance(2013, 1, 1),
                                                           PIDMFromBannerIN__c = '1967325',
                                                           UsernameFromBannerIN__c = baggins.Firstname,
                                                           WGUEmailFromBannerIN__c = 'testupdateZhang@wgu.edu',
                                                           BannerIDFromBannerIN__c = '201308275' );
        insert record;
        
        List<ContactToBanner__c> ctbList = new List<ContactToBanner__c>();
        ctbList.add(record);        
        
        Test.startTest();                
            ContactToBannerUtilities.updateContactBannerData(ctbList);                                    
        Test.stopTest();               
        
        List<Contact> updateResult = [select Id, PIDM__c, FirstName, LastName, Username__c, WGUEmail__c, StudentID__c
                                      from Contact where Id = :baggins.Id LIMIT 1];
        
        System.assert(updateResult[0].PIDM__c != null);
        System.assert(updateResult[0].Firstname != null);
        System.assert(updateResult[0].WGUEmail__c != null);
        System.assert(updateResult[0].StudentId__c != null);
        System.assertEquals(updateResult[0].PIDM__c, record.PIDMFromBannerIN__c);
        System.assertEquals(updateResult[0].Firstname, record.UsernameFromBannerIN__c);
        //System.assertEquals(updateResult[0].WGUEmail__c.toLowerCase(), record.WGUEmailFromBannerIN__c.toLowerCase());
        System.assertEquals(updateResult[0].StudentId__c, record.BannerIDFromBannerIN__c);
        
    }  
}