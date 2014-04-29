/**********************************************************************************************************************
*
* Purpose: Ensure all Transferred Courses are linked to a Transfer Attendance for data consistency in pushing to Banner
* Author: Will Slade
* Revisions:
*     4-16-2013 - Created Trigger
*
***********************************************************************************************************************/

trigger StudentTransferredCourseTrigger on StudentTransferredCourse__c (After Insert, After Update, Before Delete) 
{
    boolean delErr = false;

    ////////////////////////////////////////////////// Begin Link to Transfer Attendance /////////////////////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        List<StudentTransferredCourse__c> transCourseList = new List<StudentTransferredCourse__c>();
        
        for (StudentTransferredCourse__c transCourse : [SELECT Id, StudentTransferInstitution__c, TransferAttendance__c, StudentTransferInstitution__r.Pidm__c,
                                                               TransferAttendance__r.DegreeAwarded__r.ExternalId__c,
                                                               StudentTransferInstitution__r.Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name
                                                        FROM StudentTransferredCourse__c 
                                                        WHERE Id IN :Trigger.new
                                                        AND TransferAttendance__c = null])
        {
            transCourseList.add(transCourse);
        }
        
        if (transCourseList.size() > 0)
        {
            StudentTransferredCourseUtility.linkToAttendance(JSON.serialize(transCourseList));
        }
    }
    ////////////////////////////////////////////////// End Link to Transfer Attendance ///////////////////////////////////////////////
    
    ////////////////////////////////////////////////// Begin Update Transcript To Banner /////////////////////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        List<StudentTransferredCourse__c> transCourseList = new List<StudentTransferredCourse__c>();
        
        for (StudentTransferredCourse__c transCourse : [SELECT Id, StudentTransferInstitution__c, TransferAttendance__c, StudentTransferInstitution__r.Pidm__c
                                                        FROM StudentTransferredCourse__c 
                                                        WHERE Id IN :Trigger.new
                                                        AND PushedToBanner__c = true])
        {
            transCourseList.add(transCourse);
        }
        
        if (transCourseList.size() > 0)
        {
            StudentTransferredCourseUtility.updateTranscriptsToBanner(JSON.serialize(transCourseList));
        }
    }
    ////////////////////////////////////////////////// End Update Transcript To Banner ///////////////////////////////////////////////
    
    ////////////////////////////////////////////////////// Begin Delete Error Check ////////////////////////////////////////////////// 
    if (Trigger.isBefore && Trigger.isDelete)
    {
        List<StudentEquivalentCourse__c> eqCrsList = [SELECT Id, TransferredCourse__c
                                                      FROM StudentEquivalentCourse__c
                                                      WHERE TransferredCourse__c IN :trigger.Old];
        Map<Id, Id> trgToErrMap = new Map<Id, Id>();
                                                       
        System.debug('======> list size ' + eqCrsList.size());                                                       
                                                       
        if (eqCrsList.size() > 0)
        {
            List<Id> trCrsIds = new List<Id>();
            
            for (StudentEquivalentCourse__c eqCrs : eqCrsList)
            {
                trCrsIds.add(eqCrs.TransferredCourse__c);
            }
            
            List<StudentTransferredCourse__c> trCrsList = [SELECT Id 
                                                           FROM StudentTransferredCourse__c
                                                           WHERE Id IN :trCrsIds];
                                                     
            for (StudentTransferredCourse__c trCrs : trCrsList)
            {
                trgToErrMap.put(trCrs.Id, null);
            }
            
            for (StudentTransferredCourse__c trCrs : Trigger.old)
            {
                if (trgToErrMap.containsKey(trCrs.Id))
                {
                    delErr = true;
                    trCrs.addError('Cannot delete Transferred Course while related Student Equivalent Courses exist.');
                }
            }
        }
    }
    /////////////////////////////////////////////////////// End Delete Error Check ///////////////////////////////////////////////////        
    
    //////////////////////////////////////////////// Begin Delete Trans Course From Banner ///////////////////////////////////////////
    if (Trigger.isBefore && Trigger.isDelete && delErr == false)
    {
        List<String> trgRefIds = new List<String>();
        RecordType transCourseRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'StudentTransferredCourse' LIMIT 1];        
        
        for (StudentTransferredCourse__c transCourse : Trigger.old)
        {            
            trgRefIds.add(String.valueOf(Trigger.oldMap.get(transCourse.Id).Id));
            System.debug('=====> oldmap id ' + String.valueOf(Trigger.oldMap.get(transCourse.Id).Id));
        }
        
        List<TranscriptToBanner__c> transToBanList = [SELECT Id, RefId__c FROM TranscriptToBanner__c WHERE RefId__c IN :trgRefIds AND RecordTypeId = :transCourseRT.Id];
        
        for (TranscriptToBanner__c transToBan : transToBanList)
        {
            transToBan.StudentTransferredCourse__c = null;
            transToBan.ActionNeeded__c = 'Delete';
        }
        
        update transToBanList;
    }
    //////////////////////////////////////////////// End Delete Trans Course From Banner /////////////////////////////////////////////        
}