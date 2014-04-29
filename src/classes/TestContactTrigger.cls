@IsTest
public class TestContactTrigger{

    @IsTest static void IDMUpdateRequiredTest_true() {
        Contact c = new Contact();
        c.LastName = 'Test';
        c.MiddleInitial__c = 'A';
        c.recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'StudentRecord' AND sObjectType = 'Contact'].id;
        c.pidm__c = '0';
        insert c;
        
        c.MiddleInitial__c = 'Z';
        Test.startTest();
        update c;
        Test.stopTest();
        
        Contact result = [SELECT IDMRequiresUpdate__c FROM Contact WHERE Id = :c.id];
        System.assertEquals(true, result.IDMRequiresUpdate__c);
    }
    
    @IsTest static void IDMUpdateRequiredTest_NullPIDM() {
        Contact c = new Contact();
        c.LastName = 'Test';
        c.MiddleInitial__c = 'A';
        c.recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'StudentRecord' AND sObjectType = 'Contact'].id;
        insert c;
        
        c.MiddleInitial__c = 'Z';
        Test.startTest();
        update c;
        Test.stopTest();
        
        Contact result = [SELECT IDMRequiresUpdate__c FROM Contact WHERE Id = :c.id];
        System.assertEquals(false, result.IDMRequiresUpdate__c);
    }
    
    @IsTest static void IDMUpdateRequiredTest_NotAStudentRecordType() {
        Contact c = new Contact();
        c.LastName = 'Test';
        c.MiddleInitial__c = 'A';
        c.recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'BusinessContact' AND sObjectType = 'Contact'].id;
        c.pidm__c = '0';
        insert c;
        
        c.MiddleInitial__c = 'Z';
        Test.startTest();
        update c;
        Test.stopTest();
        
        Contact result = [SELECT IDMRequiresUpdate__c FROM Contact WHERE Id = :c.id];
        System.assertEquals(false, result.IDMRequiresUpdate__c);
    }
    
}