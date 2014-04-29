/************************************************************
Utility class for FinancialApplicationTrigger
Author - Will Slade
3/20/2013 @ 12:15 pm - Created Class
*************************************************************/

public with sharing class FinancialApplicationUtility{

// Add all third party requirement rules to Financial Application
    public static void addRequirementRules( String finAppListJSON )
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processAddRequirementRules( finAppListJSON );
        }
        else
        {
            asyncAddRequirementRules( finAppListJSON );
        }
    }
    
    @future
    private static void asyncAddRequirementRules( String finAppListJSON )
    {
        processAddRequirementRules( finAppListJSON );
    }

    private static void processAddRequirementRules( String finAppListJSON )
    {   
        List<RecordType> reqRuleRT = [SELECT Id FROM RecordType WHERE SObjectType = 'RequirementRule__c' AND Name = 'Third Party' LIMIT 1];
        List<RecordType> finReqRT = [SELECT Id FROM RecordType WHERE SObjectType = 'FinancialRequirement__c' AND Name = 'Third Party' LIMIT 1];     
        List<FinancialApplication__c> finAppList = (List<FinancialApplication__c>)JSON.deserialize( finAppListJSON, List<FinancialApplication__c>.class );        
        List<RequirementRule__c> reqRules = [SELECT Id, FinRequirement__c FROM RequirementRule__c WHERE RecordTypeId = :reqRuleRT LIMIT 100];
        List<FinancialRequirement__c> finReqs = new List<FinancialRequirement__c>();
        
        for (FinancialApplication__c finApp : finAppList)
        {
            for (RequirementRule__c reqRule : reqRules)
            {
                FinancialRequirement__c finReq = new FinancialRequirement__c( FinancialApplication__c = finApp.Id, Requirement__c = reqRule.FinRequirement__c, 
                                                                              RequirementsStatus__c = 'Required', RecordTypeId = finReqRT[0].Id );
                finReqs.add(finReq);
            }
        }
        
        insert finReqs; 
    }
}