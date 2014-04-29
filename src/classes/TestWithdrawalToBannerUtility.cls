/*****************************************************************************************
* Name: TestWithdrawalToBannerUtility
* Author: Will Slade
* Purpose: Test Class for WithdrawalToBannerUtility and WithdrawalToBannerTrigger
* Revisions: 
*    5-31-2013 - Created Class
*
******************************************************************************************/

@isTest
public class TestWithdrawalToBannerUtility
{
    private static testMethod void testUtil()
    {
        WithdrawalToBanner__c wtb = new WithdrawalToBanner__c(ActionNeeded__c = 'Insert');    
        Insert wtb;
        
        List<WithdrawalToBanner__c> wtbList = [SELECT Id, ActionNeeded__c FROM WithdrawalToBanner__c WHERE ActionNeeded__c = 'Insert' LIMIT 100];        
        System.assertEquals(wtbList.size(), 1, 'Too many Withdrawal to Banner records were returned.  Test method only inserted 1.');
        
        for (WithdrawalToBanner__c wtb1 : wtbList)
        {
            wtb1.ActionNeeded__c = 'Error';
        } 
        
        Test.startTest();       
            Update wtbList;
        Test.stopTest();
        
        List<SynchronizeToBannerLog__c> stblList = [SELECT Id, ReferenceId__c FROM SynchronizeToBannerLog__c WHERE ReferenceType__c = 'WithdrawalToBanner__c'];        
        System.assertEquals(stblList.size(), 1, 'Should be 1 and only 1 Sync to Banner record as only 1 Withdrawal to Banner was updated with a status of Error');
        System.assertEquals(stblList[0].ReferenceId__c, String.valueOf(wtb.Id));
    }
}