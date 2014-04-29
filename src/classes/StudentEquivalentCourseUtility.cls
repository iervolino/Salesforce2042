/*****************************************************************************************
* Name: StudentEquivalentCourseUtility
* Author: Brad King
* Purpose: 
* Revisions: 
*    - 4/23/2013 Created Class
*    - 7/08/2013 Modified class on update to re-populate PIDM
*
******************************************************************************************/

public class StudentEquivalentCourseUtility
{
    /////////////////////////// Update Transcripts To Banner ///////////////////////////    
    public static void updateTranscriptsToBanner(String equivCourseListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processUpdateTranscriptsToBanner(equivCourseListJSON);
        }
        else
        {
            asyncUpdateTranscriptsToBanner(equivCourseListJSON);
        }
    }
    
    @future
    public static void asyncUpdateTranscriptsToBanner(String equivCourseListJSON)
    {
        processUpdateTranscriptsToBanner(equivCourseListJSON);
    }

    public static void processUpdateTranscriptsToBanner(String equivCourseListJSON)
    {        
        List<StudentEquivalentCourse__c> equivCourseList = (List<StudentEquivalentCourse__c>) JSON.deserialize(equivCourseListJSON, List<StudentEquivalentCourse__c>.class);
        List<Id> equivCourseIds = new List<Id>();
        List<TranscriptToBanner__c> eqToBanList = new List<TranscriptToBanner__c>();
        List<TranscriptToBanner__c> eqToBanAddList = new List<TranscriptToBanner__c>();
        Map<Id, Id> eqCrsToTrBanMap = new Map<Id, Id>();
        RecordType equivCourseRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'StudentEquivalentCourse' LIMIT 1];
        
        //Populate map keys with all Equivalent Course Ids from the trigger
        for (StudentEquivalentCourse__c equivCourse : equivCourseList)
        {
            equivCourseIds.add(equivCourse.Id);
            eqCrsToTrBanMap.put(equivCourse.Id, null);
        }
        
        eqToBanList = [SELECT Id, StudentEquivalentCourse__c, ActionNeeded__c, StudentEquivalentCourse__r.WGUCourse__c,
                              StudentEquivalentCourse__r.TransferredCourse__c, 
                              StudentEquivalentCourse__r.TransferredCourse__r.TransferAttendance__c,
                              StudentEquivalentCourse__r.TransferredCourse__r.StudentTransferInstitution__c,
                              StudentEquivalentCourse__r.TransferredCourse__r.StudentTransferInstitution__r.Pidm__c                              
                       FROM TranscriptToBanner__c 
                       WHERE StudentEquivalentCourse__c
                       IN :equivCourseIds AND RecordTypeId = :equivCourseRT.Id];
        
        //Add control object Ids to the map where they exist - also set Action Needed field to Update for push job
        for (TranscriptToBanner__c eqToBan : eqToBanList)
        {
            eqCrsToTrBanMap.put(eqToBan.StudentEquivalentCourse__c, eqToBan.Id);
            eqToBan.ActionNeeded__c = eqToBan.ActionNeeded__c == 'Insert' ? 'Insert' : 'Update';
            eqToBan.WGUCourseCode__c = eqToBan.StudentEquivalentCourse__r.WGUCourse__c;
            eqToBan.StudentTransferredCourse__c = eqToBan.StudentEquivalentCourse__r.TransferredCourse__c;
            eqToBan.TransferAttendance__c = eqToBan.StudentEquivalentCourse__r.TransferredCourse__r.TransferAttendance__c;
            eqToBan.StudentTransferInstitution__c = eqToBan.StudentEquivalentCourse__r.TransferredCourse__r.StudentTransferInstitution__c;
            eqToBan.Pidm__c = eqToBan.StudentEquivalentCourse__r.TransferredCourse__r.StudentTransferInstitution__r.Pidm__c;
        }
        
        //For any missing control objects, create the record with Insert Action Needed
        for (StudentEquivalentCourse__c equivCourse : equivCourseList)
        {
            if (eqCrsToTrBanMap.get(equivCourse.Id) == null)
            {
                eqToBanAddList.add(new TranscriptToBanner__c(RecordTypeId = equivCourseRT.Id, 
                                                             StudentEquivalentCourse__c = equivCourse.Id,
                                                             StudentTransferredCourse__c = equivCourse.TransferredCourse__c,
                                                             TransferAttendance__c = equivCourse.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__c, 
                                                             RefId__c = String.valueOf(equivCourse.Id),
                                                             ParentId__c = String.valueOf(equivCourse.TransferredCourse__c), 
                                                             ActionNeeded__c = 'Insert',
                                                             PIDM__c = equivCourse.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c,
                                                             WGUCourseCode__c = equivCourse.WGUCourse__c));
            }
        }
        
        update eqToBanList;
        insert eqToBanAddList;
    }    
}