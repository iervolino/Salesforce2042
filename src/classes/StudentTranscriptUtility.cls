/*****************************************************************************************
* Name: StudentTranscriptUtility
* Author: Will Slade
* Purpose: Creates data integration objects on insertion of StudentTranscript__c via trigger
* Revisions: 
*    4-17-2013 - Created Class
*
******************************************************************************************/

public class StudentTranscriptUtility
{
    public static void createTranscriptsToBanner(String transcriptListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processCreateTranscriptsToBanner(transcriptListJSON);
        }
        else
        {
            asyncCreateTranscriptsToBanner(transcriptListJSON);
        }
    }
    
    @future
    public static void asyncCreateTranscriptsToBanner(String transcriptListJSON)
    {
        processCreateTranscriptsToBanner(transcriptListJSON);
    }    

    public static void processCreateTranscriptsToBanner(String transcriptListJSON)
    {     
        List<StudentTranscript__c> transcriptList = (List<StudentTranscript__c>) JSON.deserialize(transcriptListJSON, List<StudentTranscript__c>.class);   
        List<TranscriptToBanner__c> trToBanInsertList = new List<TranscriptToBanner__c>();
        RecordType transRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'StudentTranscript' LIMIT 1];
        Map<Id, Id> transToCtrlMap = new Map<Id, Id>();
        
        //Loop through the list of transcripts and populate the keyset of the map with the record ids
        for (StudentTranscript__c transcript : transcriptList)
        {
            transToCtrlMap.put(transcript.Id, null);
        }
        
        Set<Id> transIdSet = transToCtrlMap.keySet();
        
        transcriptList = [SELECT Id, Pidm__c, TranscriptInstitution__r.IPED__c, Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name
                          FROM StudentTranscript__c
                          WHERE Id IN :transIdSet];
        
        List<TranscriptToBanner__c> trToBanUpdateList = [SELECT Id, RefId__c, ParentId__c, ActionNeeded__c, StudentTransferInstitution__c,
                                                                StudentTransferInstitution__r.Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name,
                                                                StudentTransferInstitution__r.TranscriptInstitution__r.IPED__c,
                                                                StudentTransferInstitution__r.Opportunity__r.Pidm__c
                                                         FROM TranscriptToBanner__c
                                                         WHERE RecordTypeId = :transRT.Id
                                                         AND StudentTransferInstitution__c IN :transIdSet];
        
        //2nd pass through map - update values with existing control object ids and mark them as Update needed                                         
        for (TranscriptToBanner__c trToBan : trToBanUpdateList)
        {
            transToCtrlMap.put(trToBan.StudentTransferInstitution__c, trToBan.Id);            
            trToBan.actionNeeded__c = trToBan.actionNeeded__c == 'Insert' ? 'Insert' : 'Update';
            trToBan.Pidm__c = trToBan.StudentTransferInstitution__r.Opportunity__r.Pidm__c;
            trToBan.InstitutionIPEDCode__c = trToBan.StudentTransferInstitution__r.TranscriptInstitution__r.IPED__c;
            trToBan.ProgramCode__c = trToBan.StudentTransferInstitution__r.Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name;
        }                                          
        
        for (StudentTranscript__c transcript : transcriptList)
        {
            if (transToCtrlMap.get(transcript.Id) == null)
            {
                System.debug('=======> size ' + transcriptList.size() + transcript.Id);
                trToBanInsertList.add(new TranscriptToBanner__c(StudentTransferInstitution__c = transcript.Id,
                                                                RefId__c = String.valueOf(transcript.Id),
                                                                RecordTypeId = transRT.Id,
                                                                ActionNeeded__c = 'Insert',
                                                                Pidm__c = transcript.Pidm__c,
                                                                InstitutionIPEDCode__c = transcript.TranscriptInstitution__r.IPED__c,
                                                                ProgramCode__c = transcript.Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name));
            }
        }
        
        update trToBanUpdateList;
        insert trToBanInsertList;
    }    
}