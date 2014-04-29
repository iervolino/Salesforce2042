/*****************************************************************************************
* Name: MentorCourseAssignToBannerUtility
* Author: Will Slade
* Purpose: Creates error logs for failed attempts at pushing a Mentor Course Groups To Banner
* Revisions: 
*    7-12-2013 - Created Class
*
******************************************************************************************/

public class MentorCourseAssignToBannerUtility
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
        List<MentorCourseAssignToBanner__c> wtbList = (List<MentorCourseAssignToBanner__c>) JSON.deserialize(wtbListJSON, List<MentorCourseAssignToBanner__c>.class);
        List<SynchronizeToBannerLog__c> stblList = new List<SynchronizeToBannerLog__c>();

        for (MentorCourseAssignToBanner__c wtb : wtbList)
        {
            stblList.add(new SynchronizeToBannerLog__c(ReferenceType__c = 'MentorCourseAssignToBanner__c',
                                                       ReferenceId__c = wtb.Id,
                                                       SynchronizationError__c = wtb.PushResult__c));                                                       
        }
        
        insert stblList;
    }    
}