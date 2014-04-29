/*****************************************************************************************
* Name: TransferAttendanceUtility
* Author: Will Slade
* Purpose: Creates data integration records for Transfer Attendance via trigger of same name
* Revisions: 
*    - 4/17/2013 Created Class
*
******************************************************************************************/

public class TransferAttendanceUtility
{
    public static void createTranscriptsToBanner(String attendanceListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processCreateTranscriptsToBanner(attendanceListJSON);
        }
        else
        {
            asyncCreateTranscriptsToBanner(attendanceListJSON);
        }
    }
    
    @future
    public static void asyncCreateTranscriptsToBanner(String attendanceListJSON)
    {
        processCreateTranscriptsToBanner(attendanceListJSON);
    }

    public static void processCreateTranscriptsToBanner(String attendanceListJSON)
    {
        List<TransferAttendance__c> attendanceList = (List<TransferAttendance__c>) JSON.deserialize(attendanceListJSON, List<TransferAttendance__c>.class);
        List<TranscriptToBanner__c> trToBanInsertList = new List<TranscriptToBanner__c>();
        RecordType trAttRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'TransferAttendance' LIMIT 1];
        Map<Id, Id> attToCtrlMap = new Map<Id, Id>();
        
        //Loop through the list of attendances and populate the keyset of the map with the record ids
        for (TransferAttendance__c attendance : attendanceList)
        {
            attToCtrlMap.put(attendance.Id, null);
        }
        
        Set<Id> attIdSet = attToCtrlMap.keySet();
        
        attendanceList = [SELECT Id, StudentTransferInstitution__c, DegreeAwarded__r.ExternalId__c, StudentTransferInstitution__r.Pidm__c
                          FROM TransferAttendance__c
                          WHERE Id IN :attIdSet];                           
        
        List<TranscriptToBanner__c> trToBanUpdateList = [SELECT Id, RefId__c, ParentId__c, ActionNeeded__c, TransferAttendance__c,
                                                                TransferAttendance__r.DegreeAwarded__r.ExternalId__c,
                                                                TransferAttendance__r.StudentTransferInstitution__r.Opportunity__r.Pidm__c                                                                
                                                         FROM TranscriptToBanner__c
                                                         WHERE RecordTypeId = :trAttRT.Id
                                                         AND TransferAttendance__c IN :attIdSet];
        
        //2nd pass through map - update values with existing control object ids and mark them as Update needed                                         
        for (TranscriptToBanner__c trToBan : trToBanUpdateList)
        {
            attToCtrlMap.put(trToBan.TransferAttendance__c, trToBan.Id);
            trToBan.actionNeeded__c = trToBan.actionNeeded__c == 'Insert' ? 'Insert' : 'Update';
            trToBan.DegreeCode__c = trToBan.TransferAttendance__r.DegreeAwarded__r.ExternalId__c;
            trToBan.Pidm__c = trToBan.TransferAttendance__r.StudentTransferInstitution__r.Opportunity__r.Pidm__c;
        }                                          
        
        for (TransferAttendance__c attendance : attendanceList)
        {
            if (attToCtrlMap.get(attendance.Id) == null)
            {
                trToBanInsertList.add(new TranscriptToBanner__c(TransferAttendance__c = attendance.Id,
                                                                StudentTransferInstitution__c = attendance.StudentTransferInstitution__c,
                                                                RefId__c = String.valueOf(attendance.Id),
                                                                ParentId__c = String.valueOf(attendance.StudentTransferInstitution__c),
                                                                RecordTypeId = trAttRT.Id,
                                                                ActionNeeded__c = 'Insert',
                                                                DegreeCode__c = attendance.DegreeAwarded__r.ExternalId__c,
                                                                Pidm__c = attendance.StudentTransferInstitution__r.Pidm__c));
            }
        }
        
        update trToBanUpdateList;
        insert trToBanInsertList;
    }    
}