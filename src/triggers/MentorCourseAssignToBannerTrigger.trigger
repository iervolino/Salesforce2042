/*****************************************************************************************
* Name: MentorCourseAssignToBannerTrigger
* Author: Will Slade
* Purpose: Create Synchronize To Banner Logs for errors in pushing MentorCourseAssign to Banner
* Revisions: 
*    7-12-2013 - Created Trigger
*
******************************************************************************************/

trigger MentorCourseAssignToBannerTrigger on MentorCourseAssignToBanner__c (After Update) 
{
////////////////////////// Begin Create Sync To Banner Logs ////////////////////////////
    if (Trigger.isAfter && Trigger.isUpdate)
    {    
        List<MentorCourseAssignToBanner__c> wtbList = new List<MentorCourseAssignToBanner__c>();
                    
        for (MentorCourseAssignToBanner__c wtb : Trigger.new)
        {        
            if (wtb.ActionNeeded__c.equals('Error') && !Trigger.oldMap.get(wtb.Id).ActionNeeded__c.equals('Error'))
            {
                wtbList.add(wtb);
            }
        }
        
        if (wtbList.size() > 0)
        {
            MentorCourseAssignToBannerUtility.createSyncToBannerLogs(JSON.serialize(wtbList));
        }
    }
/////////////////////////// End Create Sync To Banner Logs /////////////////////////////
}