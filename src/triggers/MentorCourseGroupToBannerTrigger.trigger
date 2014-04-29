/*****************************************************************************************
* Name: MentorCourseGroupToBannerTrigger
* Author: Will Slade
* Purpose: Create Synchronize To Banner Logs for errors in pushing MentorCourseGroups to Banner
* Revisions: 
*    7-12-2013 - Created Trigger
*
******************************************************************************************/

trigger MentorCourseGroupToBannerTrigger on MentorCourseGroupToBanner__c (After Update) 
{
////////////////////////// Begin Create Sync To Banner Logs ////////////////////////////
    if (Trigger.isAfter && Trigger.isUpdate)
    {    
        List<MentorCourseGroupToBanner__c> wtbList = new List<MentorCourseGroupToBanner__c>();
                    
        for (MentorCourseGroupToBanner__c wtb : Trigger.new)
        {        
            if (wtb.ActionNeeded__c.equals('Error') && !Trigger.oldMap.get(wtb.Id).ActionNeeded__c.equals('Error'))
            {
                wtbList.add(wtb);
            }
        }
        
        if (wtbList.size() > 0)
        {
            MentorCourseGroupToBannerUtility.createSyncToBannerLogs(JSON.serialize(wtbList));
        }
    }
/////////////////////////// End Create Sync To Banner Logs /////////////////////////////
}