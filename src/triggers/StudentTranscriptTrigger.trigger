/*****************************************************************************************
* Name: StudentTranscriptTrigger
* Author: Will Slade
* Purpose: Assigns contact directly to StudentTranscript__c on creation
* Revisions: 
*    - 10/1/12 Created Trigger
*    - 1/24/13 Updated to conform with person account refactor standards - Will Slade
*    - 4/17/13 Renamed per naming standards - Will Slade
*    - 4/17/13 Added functionality to create control objects for data integration
******************************************************************************************/

trigger StudentTranscriptTrigger on StudentTranscript__c (After Insert, After Update, Before Delete, Before Insert, Before Update) 
{
    boolean delErr = false;

    //////////////////////////////////////////////// Begin Contact Linking Code ////////////////////////////////////////////////
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
    {
        List<StudentTranscript__c> transcripts = [SELECT Opportunity__c, Opportunity__r.Account.StudentContact__c FROM StudentTranscript__c WHERE Id IN :trigger.new];
        Map<Id, Id> oppToContactMap = new Map<Id, Id>();        
        List<Id> oppIdList = new List<Id>();
            
        for (StudentTranscript__c transcript : Trigger.new)
        {
            oppIdList.add(transcript.Opportunity__c);
            //transcript.Contact__c = transcript.Opportunity__r.Account.StudentContact__c;
        }
        
        List<Opportunity> oppList = [SELECT Id, StudentContact__c FROM Opportunity WHERE Id IN :oppIdList];
        
        for (Opportunity opp : oppList)
        {
            oppToContactMap.put(opp.Id, opp.StudentContact__c);
        }
        
        for (StudentTranscript__c transcript : Trigger.new)
        {
            transcript.Contact__c = oppToContactMap.get(transcript.Opportunity__c);
        }
    }
    //////////////////////////////////////////////// End Contact Linking Code //////////////////////////////////////////////////
    
    //////////////////////////////////////////////// Begin Control Object Ins/Upd //////////////////////////////////////////////
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {   
        StudentTranscriptUtility.createTranscriptsToBanner(JSON.serialize(Trigger.new));
    }
    ///////////////////////////////////////////////// End Control Object Code //////////////////////////////////////////////////
    
    ///////////////////////////////////////////////// Begin Delete Error Check /////////////////////////////////////////////////
    if (Trigger.isBefore && Trigger.isDelete)
    {   
        List<TransferAttendance__c> trAttList = [SELECT Id, StudentTransferInstitution__c
                                                 FROM TransferAttendance__c
                                                 WHERE StudentTransferInstitution__c IN :trigger.Old];
        Map<Id, Id> trgToErrMap = new Map<Id, Id>();
                                                       
        System.debug('======> list size ' + trAttList.size());                                                       
                                                       
        if (trAttList.size() > 0)
        {
            List<Id> transIds = new List<Id>();
            
            for (TransferAttendance__c trAtt : trAttList)
            {
                transIds.add(trAtt.StudentTransferInstitution__c);
            }
            
            List<StudentTranscript__c> transList = [SELECT Id 
                                                    FROM StudentTranscript__c
                                                    WHERE Id IN :transIds];
                                                     
            for (StudentTranscript__c trans : transList)
            {
                trgToErrMap.put(trans.Id, null);
            }
            
            for (StudentTranscript__c trans : Trigger.old)
            {
                if (trgToErrMap.containsKey(trans.Id))
                {
                    delErr = true;
                    trans.addError('Cannot delete Transcript while related Transfer Attendances exist.');
                }
            }
        }        
    }
    ////////////////////////////////////////////////// End Delete Error Check //////////////////////////////////////////////////
    
    //////////////////////////////////////////////// Begin Delete Transcript From Banner /////////////////////////////////////////////
    if (Trigger.isBefore && Trigger.isDelete && delErr == false)
    {
        List<String> trgRefIds = new List<String>();
        RecordType transRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'StudentTranscript' LIMIT 1];        
        
        for (StudentTranscript__c trans : Trigger.old)
        {            
            trgRefIds.add(String.valueOf(Trigger.oldMap.get(trans.Id).Id));
        }
        
        List<TranscriptToBanner__c> transToBanList = [SELECT Id, RefId__c FROM TranscriptToBanner__c WHERE RefId__c IN :trgRefIds AND RecordTypeId = :transRT.Id];
        
        for (TranscriptToBanner__c transToBan : transToBanList)
        {
            transToBan.StudentTransferInstitution__c = null;
            transToBan.ActionNeeded__c = 'Delete';
        }
        
        update transToBanList;
    }
    //////////////////////////////////////////////// End Delete Transcript From Banner ///////////////////////////////////////////////        
}