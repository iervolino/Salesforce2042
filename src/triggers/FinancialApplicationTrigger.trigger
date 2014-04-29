/**************************************************************************
Trigger on Financial Application object
Author - Will Slade
3/20/2013 @ 12:12 pm - Created Trigger
3/20/2013 @ 12:12 pm - Added Third Party Requirement Rules functionality
***************************************************************************/

trigger FinancialApplicationTrigger on FinancialApplication__c (After Insert) 
{
    ////////////////////// Begin Third Party Requirement Rules //////////////////////////
    if (Trigger.isInsert && Trigger.isAfter)
    {        
        List<RecordType> thirdPartyRT = [SELECT Id FROM RecordType WHERE SobjectType = 'FinancialApplication__c' AND Name = 'Third Party' LIMIT 1];
        List<FinancialApplication__c> finApps = new List<FinancialApplication__c>();    
        
        if (thirdPartyRT.size() > 0)
        {
            for (FinancialApplication__c finApp : Trigger.New)
            {
                if (finApp.RecordTypeId == thirdPartyRT[0].Id)
                {
                    finApps.add(finApp);
                }
            }
        }
        
        if (finApps.size() > 0)
        {
            FinancialApplicationUtility.addRequirementRules (JSON.Serialize(finApps));
        }
    }
    /////////////////////// End Third Party Requirement Rules //////////////////////////
}