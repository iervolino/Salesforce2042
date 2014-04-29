/**********************************************************************************************************************
*
* Purpose: 
* Author: Brad King
* Revisions:
*     4-23-2013 - Created Trigger
*
***********************************************************************************************************************/

trigger StudentEquivalentCourseTrigger on StudentEquivalentCourse__c (After Insert, After Update, Before Delete) 
{    
    ////////////////////////////////////////////////// Begin Update Transcript To Banner /////////////////////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        List<StudentEquivalentCourse__c> equivCourseList = new List<StudentEquivalentCourse__c>();
        
        for (StudentEquivalentCourse__c equivCourse : [SELECT Id, Name, TransferAttendance__c, TransferCourseName__c, TransferEvaluation__c, TransferredCourse__c, PushedToBanner__c,
                                                       WGUCourse__c, TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c,
                                                       TransferredCourse__r.TransferAttendance__r.DegreeAwarded__r.ExternalId__c
                                                       FROM StudentEquivalentCourse__c
                                                       WHERE Id IN :Trigger.new
                                                       AND PushedToBanner__c = true])
        {
            equivCourseList.add(equivCourse);             
        }
        
        if (equivCourseList.size() > 0)
        {
            StudentEquivalentCourseUtility.updateTranscriptsToBanner(JSON.serialize(equivCourseList));
        }        
    }
    ////////////////////////////////////////////////// End Update Transcript To Banner ///////////////////////////////////////////////
    
    //////////////////////////////////////////////// Begin Delete Transcript From Banner /////////////////////////////////////////////
    if (Trigger.isBefore && Trigger.isDelete)
    {
        List<String> trgRefIds = new List<String>();
        RecordType eqCourseRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'StudentEquivalentCourse' LIMIT 1];        
        
        for (StudentEquivalentCourse__c equivCourse : Trigger.old)
        {
            trgRefIds.add(String.valueOf(Trigger.oldMap.get(equivCourse.Id).Id));
        }
        
        List<TranscriptToBanner__c> transToBanList = [SELECT Id, RefId__c 
                                                      FROM TranscriptToBanner__c 
                                                      WHERE RefId__c IN :trgRefIds 
                                                      AND RecordTypeId = :eqCourseRT.Id];
        
        for (TranscriptToBanner__c transToBan : transToBanList)
        {
            transToBan.ActionNeeded__c = 'Delete';
        }
        
        update transToBanList;
    }
    //////////////////////////////////////////////// End Delete Transcript From Banner ///////////////////////////////////////////////        
}