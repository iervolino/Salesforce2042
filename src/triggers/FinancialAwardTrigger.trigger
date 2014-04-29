/*
This is the trigger on Financial Award Object.
Author -Bhavadeep Raavi
Modified by Mike Slade to include delete
*/
trigger FinancialAwardTrigger on FinancialAward__c (after insert,after update, after delete)
{
    if (trigger.isAfter)  //Will
    {
        List<FinancialAward__c> finAwardList;
    
        if (trigger.isUpdate || trigger.isInsert)
        { 
            finAwardList = Trigger.new; 
        }    
        else
        { 
            finAwardList = Trigger.old; 
        }
        
        FinancialAwardUtility.awardAmtRollup(JSON.serialize(finAwardList));
    }
}