/*****************************************************************************************
* Name: WithdrawalToBannerUtility
* Author: Will Slade
* Purpose: Creates error logs for failed attempts at pushing a Withdrawal To Banner
* Revisions: 
*    5-29-2013 - Created Class
*
******************************************************************************************/

public class WithdrawalToBannerUtility
{
    public static void createSyncToBannerLogs(String wtbListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processCreateSyncToBannerLogs(wtbListJSON);
        }
        else
        {
            asyncCreateSyncToBannerLogs(wtbListJSON);
        }
    }
    
    @future
    public static void asyncCreateSyncToBannerLogs(String wtbListJSON)
    {
        processCreateSyncToBannerLogs(wtbListJSON);
    }    

    public static void processCreateSyncToBannerLogs(String wtbListJSON)
    {     
        List<WithdrawalToBanner__c> wtbList = (List<WithdrawalToBanner__c>) JSON.deserialize(wtbListJSON, List<WithdrawalToBanner__c>.class);
        List<SynchronizeToBannerLog__c> stblList = new List<SynchronizeToBannerLog__c>();

        for (WithdrawalToBanner__c wtb : wtbList)
        {
            stblList.add(new SynchronizeToBannerLog__c(ReferenceType__c = 'WithdrawalToBanner__c',
                                                       ReferenceId__c = wtb.Id,
                                                       SynchronizationError__c = wtb.PushResult__c));                                                       
        }
        
        insert stblList;
    }    
}