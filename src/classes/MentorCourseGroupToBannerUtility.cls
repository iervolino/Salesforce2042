/*****************************************************************************************
* Name: MentorCourseGroupToBannerUtility
* Author: Will Slade
* Purpose: Creates error logs for failed attempts at pushing a Mentor Course Groups To Banner
* Revisions: 
*    7-12-2013 - Created Class
*
******************************************************************************************/

public class MentorCourseGroupToBannerUtility
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
        List<MentorCourseGroupToBanner__c> wtbList = (List<MentorCourseGroupToBanner__c>) JSON.deserialize(wtbListJSON, List<MentorCourseGroupToBanner__c>.class);
        List<SynchronizeToBannerLog__c> stblList = new List<SynchronizeToBannerLog__c>();

        for (MentorCourseGroupToBanner__c wtb : wtbList)
        {
            stblList.add(new SynchronizeToBannerLog__c(ReferenceType__c = 'MentorCourseGroupToBanner__c',
                                                       ReferenceId__c = wtb.Id,
                                                       SynchronizationError__c = wtb.PushResult__c));                                                       
        }
        
        insert stblList;
    }    
}