@IsTest
public class TestCAREforceScheduledStatusUpdate {
    @IsTest
    public static void testScheduling() {
        Test.startTest();
        CAREforceScheduledStatusUpdate.schedule();
        Test.stopTest();
    }

    @IsTest
    public static void testRun() {
        List<Contact> contacts = new List<Contact>();
        String prospectId = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND Name = 'ProspectRecord'][0].Id;
        String studentId = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND Name = 'StudentRecord'][0].Id;
    
        contacts.add(new Contact(FirstName = 'Unit', LastName = 'Test', Email = 'utest@test.fake', RecordTypeId = studentId,
                                      HomePhone = '(801) 555-5555', Phone = '(801) 555-5555',
                                       CAREStage__c = 'Prospect', DateOfBirth__c = '07/01/1980',
                                      Status__c = 'AS', WGUEmail__c = 'utest@my.wgu.edu', StudentID__c = '000123456'));
                                      
        contacts.add(new Contact(FirstName = 'Grad', LastName = 'Test', Email = 'utest@test.fake', RecordTypeId = studentId,
                                      HomePhone = '(801) 555-5555', Phone = '(801) 555-5555',
                                       CAREStage__c = 'Prospect', DateOfBirth__c = '07/01/1980',
                                      Status__c = 'IG', WGUEmail__c = 'gtest@my.wgu.edu', StudentID__c = '000123457'));   
                                      
        contacts.add(new Contact(FirstName = 'Drop', LastName = 'Test', Email = 'utest@test.fake', RecordTypeId = studentId,
                                      HomePhone = '(801) 555-5555', Phone = '(801) 555-5555',
                                       CAREStage__c = 'Prospect', DateOfBirth__c = '07/01/1980',
                                      Status__c = 'DR', WGUEmail__c = 'dtest@my.wgu.edu', StudentID__c = '000123458'));                                                                          
        insert contacts;
        
        List<Account> accounts = [SELECT id, Name, StudentContact__c From Account];
        
        Map<Id, Id> accountMap = new Map<Id, Id>();
        
        for (Account acc : accounts) {
            for (Contact con : contacts) {
                if (acc.StudentContact__c == con.Id) {
                    accountMap.put(con.Id, acc.Id);
                    break;
                }
            }
        }
        
        List<Opportunity> opportunities = new List<Opportunity>();
        
        // Contact 1, Opportunity 1 - CLRD -> ENRL
        Date today = Date.today();
        opportunities.add(new Opportunity(name = 'Unit Test', CAREStatus__c = 'CLRD - Cleared to Start', 
                                         StudentContact__c = contacts[0].Id, closeDate = Date.newInstance(today.year(), today.month(), 1),
                                         AccountId = accountMap.get(contacts[0].Id), StageName = 'Dis-positioned'));
        
        // Contact 1, Opportunity 2 - ENRL -> MATR
        opportunities.add(new Opportunity(name = 'Unit Test 2', CAREStatus__c = 'ENRL – Enrolled and Assigned a Mentor', 
                                         StudentContact__c = contacts[0].Id, closeDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-1),
                                         AccountId = accountMap.get(contacts[0].Id), StageName = 'Dis-positioned'));
        
        // Contact 2, Opportunity 3 - MATR -> GRAD
        opportunities.add(new Opportunity(name = 'Grad Test', CAREStatus__c = 'MATR – Matriculated', 
                                         StudentContact__c = contacts[1].Id, closeDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-18),
                                         AccountId = accountMap.get(contacts[1].Id), StageName = 'Dis-positioned'));
                                         
        // Contact 3, Opportunity 3 - MATR -> DROP
        opportunities.add(new Opportunity(name = 'Drop Test', CAREStatus__c = 'MATR – Matriculated', 
                                         StudentContact__c = contacts[2].Id, closeDate = Date.newInstance(today.year(), today.month(), 1).addMonths(-18),
                                         AccountId = accountMap.get(contacts[2].Id), StageName = 'Dis-positioned'));                                    
        
        insert opportunities;        
        
        Test.startTest();
        
        CAREforceScheduledStatusUpdate sched = new CAREforceScheduledStatusUpdate();
        sched.execute(null);
        
        Test.stopTest();
        
        opportunities = [SELECT Name, CAREStatusListView__c, CloseDate FROM Opportunity];
        
        for (Opportunity opp : opportunities) {
            if (opp.Name == 'Unit Test') {
                System.assert(opp.CAREStatusListView__c == 'ENRL');
            }
            
            if (opp.Name == 'Unit Test 2') {
                System.assert(opp.CAREStatusListView__c == 'MATR');
            }        
            
            if (opp.Name == 'Grad Test') {
                System.assert(opp.CAREStatusListView__c == 'GRAD');
            }                
            
            if (opp.Name == 'Drop Test') {
                System.assert(opp.CAREStatusListView__c == 'DROP');
            }            
        }
    }
}