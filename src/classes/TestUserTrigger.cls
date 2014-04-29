@IsTest
public class TestUserTrigger{

    @IsTest static void IDMUpdateRequiredTest_True() {
        User u = [SELECT Id, City FROM User WHERE IsActive = true AND IsEmployee__c = false AND IDMRequiresUpdate__c = false LIMIT 1];
        
        u.City = 'Fakeville';
        Test.startTest();
        update u;
        Test.stopTest();
        
        User result = [SELECT Id, IDMRequiresUpdate__c FROM User WHERE Id = :u.id];
        System.assertEquals(true, result.IDMRequiresUpdate__c);
    }
    
    @IsTest static void IDMUpdateRequiredTest_False() {
        User u = [SELECT Id, City FROM User WHERE IsActive = true AND IsEmployee__c = true AND IDMRequiresUpdate__c = false LIMIT 1];
        
        u.City = 'Fakeville';
        Test.startTest();
        update u;
        Test.stopTest();
        
        User result = [SELECT Id, IDMRequiresUpdate__c FROM User WHERE Id = :u.id];
        System.assertEquals(false, result.IDMRequiresUpdate__c);
    }
    
}