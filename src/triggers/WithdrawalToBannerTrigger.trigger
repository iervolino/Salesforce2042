/*****************************************************************************************
* Name: WithdrawalToBannerTrigger
* Author: Will Slade
* Purpose: Create Synchronize To Banner Logs for errors in pushing Withdrawals to Banner
* Revisions: 
*    5-29-2013 - Created Trigger
*
******************************************************************************************/

trigger WithdrawalToBannerTrigger on WithdrawalToBanner__c (After Update) 
{
////////////////////////// Begin Create Sync To Banner Logs ////////////////////////////
    if (Trigger.isAfter && Trigger.isUpdate)
    {    
        List<WithdrawalToBanner__c> wtbList = new List<WithdrawalToBanner__c>();
                    
        for (WithdrawalToBanner__c wtb : Trigger.new)
        {        
            if (wtb.ActionNeeded__c.equals('Error') && !Trigger.oldMap.get(wtb.Id).ActionNeeded__c.equals('Error'))
            {
                wtbList.add(wtb);
            }
        }
        
        if (wtbList.size() > 0)
        {
            WithdrawalToBannerUtility.createSyncToBannerLogs(JSON.serialize(wtbList));
        }
    }
/////////////////////////// End Create Sync To Banner Logs /////////////////////////////
}