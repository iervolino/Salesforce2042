/*****************************************************************************************
* Name: TestMentorCourseAssignToBannerUtility
* Author: Will Slade
* Purpose: Test Class for MentorCourseAssignToBannerUtility and MentorCourseAssignToBannerTrigger
* Revisions: 
*    5-31-2013 - Created Class
*
******************************************************************************************/

@isTest
public class TestMentorCourseAssignToBannerUtility
{
    private static testMethod void testUtil()
    {
        MentorCourseAssignToBanner__c mcatb = new MentorCourseAssignToBanner__c(ActionNeeded__c = 'Insert');    
        Insert mcatb;
        
        List<MentorCourseAssignToBanner__c> mcatbList = [SELECT Id, ActionNeeded__c FROM MentorCourseAssignToBanner__c WHERE ActionNeeded__c = 'Insert' LIMIT 100];        
        System.assertEquals(mcatbList.size(), 1, 'Too many MentorCourseAssign to Banner records were returned.  Test method only inserted 1.');
        
        for (MentorCourseAssignToBanner__c mcatb1 : mcatbList)
        {
            mcatb1.ActionNeeded__c = 'Error';
        } 
        
        Test.startTest();       
            Update mcatbList;
        Test.stopTest();
        
        List<SynchronizeToBannerLog__c> stblList = [SELECT Id, ReferenceId__c FROM SynchronizeToBannerLog__c WHERE ReferenceType__c = 'MentorCourseAssignToBanner__c'];        
        System.assertEquals(stblList.size(), 1, 'Should be 1 and only 1 Sync to Banner record as only 1 MentorCourseAssign to Banner was updated with a status of Error');
        System.assertEquals(stblList[0].ReferenceId__c, String.valueOf(mcatb.Id));
    }
}