/*******************************************************************************
* Test Class for FinancialApplicationUtility and FinancialApplicationTrigger.
* Author - Will Slade
* 3/20/2013 - Created class
********************************************************************************/
@isTest()
private class TestFinancialApplicationUtility
{  
    private static testmethod void TestFinancialApplicationUtility()
    {
        List<RecordType> thirdPartyRT = [SELECT Id FROM RecordType WHERE SobjectType = 'FinancialApplication__c' AND Name = 'Third Party' LIMIT 1];
        List<RecordType> reqRuleBadRT = [SELECT Id FROM RecordType WHERE SObjectType = 'RequirementRule__c' AND Name = 'Scholarship Import' LIMIT 1];
        List<RecordType> reqRuleRT = [SELECT Id FROM RecordType WHERE SObjectType = 'RequirementRule__c' AND Name = 'Third Party' LIMIT 1];        
            
        Opportunity opp1 = new Opportunity( Name = 'TestFinApp Opp1', CloseDate = Date.today().addDays(3), StageName = 'Prospecting');
        insert opp1;
        
        System.assert(opp1.Id != null);
        
        KeyValue__c kv = new KeyValue__c( Name = 'Third Party Voucher', Value__c = 'Third Party Voucher', ExternalID__c = 'Third Party Voucher');
        insert kv;
        
        RequirementRule__c reqRule1 = new RequirementRule__c( RecordTypeId = reqRuleRT[0].Id, FinRequirement__c = kv.Id );
        insert reqRule1;
        
        RequirementRule__c reqRule2 = new RequirementRule__c( RecordTypeId = reqRuleRT[0].Id, FinRequirement__c = kv.Id );
        insert reqRule2;                
        
        RequirementRule__c reqRule3 = new RequirementRule__c( RecordTypeId = reqRuleBadRT[0].Id, FinRequirement__c = kv.Id );
        insert reqRule3;
        
        List<RequirementRule__c> reqRules = [SELECT Id FROM RequirementRule__c LIMIT 5];
        System.assertEquals(reqRules.size(), 3);                            
        
        Test.startTest();   
         
        FinancialApplication__c fa = new FinancialApplication__c(Name = 'Test FAReq1', Opportunity__c = opp1.id, RecordTypeId = thirdPartyRT[0].Id);
        insert fa;
        
        System.assert(fa.Id != null);
        
        Test.stopTest();
        
        List<FinancialRequirement__c> finReqs = [SELECT Id, FinancialRequirement__c.RecordTypeId FROM FinancialRequirement__c WHERE FinancialApplication__c = :fa.Id LIMIT 5];
        System.assertEquals(finReqs.size(), 2);
        
        List<RecordType> finReqRT = [SELECT Id FROM RecordType WHERE SObjectType = 'FinancialRequirement__c' AND Name = 'Third Party' LIMIT 1];
        System.assertEquals(finReqs[0].RecordTypeId, finReqRT[0].Id);
    }
}