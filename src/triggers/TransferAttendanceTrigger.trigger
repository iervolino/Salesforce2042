/*****************************************************************************************
* Name: TransferAttendanceTrigger
* Author: Will Slade
* Purpose: Creates data synchronization object for transfer attendance
* Revisions: 
*    - 4/17/2013 Created Trigger
*
******************************************************************************************/

trigger TransferAttendanceTrigger on TransferAttendance__c (After Insert, After Update, Before Delete) 
{
    boolean delErr = false;

    /////////////////////////////// Start Create/Update TranscriptToBanner ///////////////////////////
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {
        TransferAttendanceUtility.createTranscriptsToBanner(JSON.serialize(Trigger.new));
    }
    //////////////////////////////// End Create/Update TranscriptToBanner ////////////////////////////
    
    //////////////////////////////////// Start Delete Error Check ////////////////////////////////////
    if (Trigger.isBefore && Trigger.isDelete)
    {
        List<StudentTransferredCourse__c> trCrsList = [SELECT Id, TransferAttendance__c
                                                       FROM StudentTransferredCourse__c
                                                       WHERE TransferAttendance__c IN :trigger.Old];
        Map<Id, Id> trgToErrMap = new Map<Id, Id>();
                                                       
        System.debug('======> list size ' + trCrsList.size());                                                       
                                                       
        if (trCrsList.size() > 0)
        {
            List<Id> trAttIds = new List<Id>();
            
            for (StudentTransferredCourse__c trCrs : trCrsList)
            {
                trAttIds.add(trCrs.TransferAttendance__c);
            }
            
            List<TransferAttendance__c> trAttList = [SELECT Id 
                                                     FROM TransferAttendance__c
                                                     WHERE Id IN :trAttIds];
                                                     
            for (TransferAttendance__c trAtt : trAttList)
            {
                trgToErrMap.put(trAtt.Id, null);
            }
            
            for (TransferAttendance__c trAtt : Trigger.old)
            {
                if (trgToErrMap.containsKey(trAtt.Id))
                {
                    delErr = true;
                    trAtt.addError('Cannot delete Transfer Attendance while related Student Transferred Courses exist.');                    
                }
            }
        }                                                                       
    }
    ///////////////////////////////////// End Delete Error Check /////////////////////////////////////
    
    /////////////////////////////// Begin Delete Attendance From Banner //////////////////////////////
    if (Trigger.isBefore && Trigger.isDelete && delErr == false)
    {
        List<String> trgRefIds = new List<String>();
        RecordType attRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'TransferAttendance' LIMIT 1];        
        
        for (TransferAttendance__c trAtt : Trigger.old)
        {            
            trgRefIds.add(String.valueOf(Trigger.oldMap.get(trAtt.Id).Id));
        }
        
        List<TranscriptToBanner__c> transToBanList = [SELECT Id, RefId__c FROM TranscriptToBanner__c WHERE RefId__c IN :trgRefIds AND RecordTypeId = :attRT.Id];
        
        for (TranscriptToBanner__c transToBan : transToBanList)
        {
            transToBan.TransferAttendance__c = null;
            transToBan.ActionNeeded__c = 'Delete';
            System.debug('====> changed action to ' + transToBan.Id);
        }
        
        update transToBanList;
    }
    //////////////////////////////// End Delete Attendance From Banner ///////////////////////////////    
}