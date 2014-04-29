/*****************************************************************************************
* Name: TestMentorCourseGroupToBannerUtility
* Author: Will Slade
* Purpose: Test Class for MentorCourseGroupToBannerUtility and MentorCourseGroupToBannerTrigger
* Revisions: 
*    7-15-2013 - Created Class
*
******************************************************************************************/

@isTest
public class TestMentorCourseGroupToBannerUtility
{
    private static testMethod void testUtil()
    {
        MentorCourseGroupToBanner__c mcgtb = new MentorCourseGroupToBanner__c(ActionNeeded__c = 'Insert');    
        Insert mcgtb;
        
        List<MentorCourseGroupToBanner__c> mcgtbList = [SELECT Id, ActionNeeded__c FROM MentorCourseGroupToBanner__c WHERE ActionNeeded__c = 'Insert' LIMIT 100];        
        System.assertEquals(mcgtbList.size(), 1, 'Too many MentorCourseGroup to Banner records were returned.  Test method only inserted 1.');
        
        for (MentorCourseGroupToBanner__c mcgtb1 : mcgtbList)
        {
            mcgtb1.ActionNeeded__c = 'Error';
        } 
        
        Test.startTest();       
            Update mcgtbList;
        Test.stopTest();
        
        List<SynchronizeToBannerLog__c> stblList = [SELECT Id, ReferenceId__c FROM SynchronizeToBannerLog__c WHERE ReferenceType__c = 'MentorCourseGroupToBanner__c'];        
        System.assertEquals(stblList.size(), 1, 'Should be 1 and only 1 Sync to Banner record as only 1 MentorCourseGroup to Banner was updated with a status of Error');
        System.assertEquals(stblList[0].ReferenceId__c, String.valueOf(mcgtb.Id));
    }
}