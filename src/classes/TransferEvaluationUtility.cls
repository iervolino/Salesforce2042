/***************************************************************************************************************
*
* Purpose: Create TranscriptToBanner records from TransferEvaluationTrigger
* Author: Will Slade
* Revisions:
*     4-16-2013 - Created Class
*
****************************************************************************************************************/

public class TransferEvaluationUtility
{
    public static void createTranscriptsToBanner(String trEvalListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processCreateTranscriptsToBanner(trEvalListJSON);
        }
        else
        {
            asyncCreateTranscriptsToBanner(trEvalListJSON);
        }
    }
    
    @future
    public static void asyncCreateTranscriptsToBanner(String trEvalListJSON)
    {
        processCreateTranscriptsToBanner(trEvalListJSON);
    }

    public static void processCreateTranscriptsToBanner(String trEvalListJSON)
    {
        Id trCrsRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND Name = 'StudentTransferredCourse' LIMIT 1].Id;
        Id eqCrsRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND Name = 'StudentEquivalentCourse' LIMIT 1].Id;
        List<TransferEvaluation__c> trEvalList = (List<TransferEvaluation__c>) JSON.deserialize(trEvalListJSON, List<TransferEvaluation__c>.class);        
        List<Id> trEvalIds = new List<Id>(); 
        List<Id> trCrsIds = new List<Id>();
        List<Id> eqCrsIds = new List<Id>();              
        
        Map<Id, Id> eqCrsToControlMap = new Map<Id, Id>();
        Map<Id, Id> trCrsToControlMap = new Map<Id, Id>();
        Map<Id, String> eqCrsToPidmMap = new Map<Id, String>();
        Map<Id, String> trCrsToPidmMap = new Map<Id, String>();
        Map<Id, Id> eqCrsToTrCrsMap = new Map<Id, Id>();
        Map<Id, Id> trCrsToTrAttMap = new Map<Id, Id>();
        Map<Id, Id> transcriptMap = new Map<Id, Id>();
        Map<Id, Id> attendanceMap = new Map<Id, Id>();
        
        List<StudentEquivalentCourse__c> eqCrsList = new List<StudentEquivalentCourse__c>();
        List<StudentTransferredCourse__c> trCrsList = new List<StudentTransferredCourse__c>(); 
        List<TranscriptToBanner__c> trToBannerList = new List<TranscriptToBanner__c>();
        List<TranscriptToBanner__c> trToBannerUpdateList = new List<TranscriptToBanner__c>();
        List<TranscriptToBanner__c> trToBannerInsertList = new List<TranscriptToBanner__c>();
        
        //Compile list of Ids in Transfer Evaluations and pull the equivalent/transferred courses associated with them
        for (TransferEvaluation__c trEval : trEvalList)
        {
            trEvalIds.add(trEval.Id);
        }
        
        eqCrsList = [SELECT Id, TransferredCourse__c, TransferEvaluation__r.Opportunity__r.Pidm__c, PushedToBanner__c, TransferredCourse__r.TransferAttendance__c,
                            TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c, TransferredGroup__c, WGUCourse__c,
                            TransferredCourse__r.StudentTransferInstitution__c, TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__c
                     FROM StudentEquivalentCourse__c
                     WHERE TransferEvaluation__c IN :trEvalIds
                     AND SatisfiedInd__c = 'Y'];            
        
        //Build maps to link the transfer/equivalent courses to their control objects (if they exist)
        for (StudentEquivalentCourse__c eqCrs : eqCrsList)
        {
            eqCrsIds.add(eqCrs.Id);   
            eqCrsToPidmMap.put(eqCrs.Id, eqCrs.TransferEvaluation__r.Opportunity__r.Pidm__c);
            
            if (eqCrs.TransferredCourse__c != null)
            {
                trCrsToPidmMap.put(eqCrs.TransferredCourse__c, eqCrs.TransferEvaluation__r.Opportunity__r.Pidm__c);
                trCrsIds.add(eqCrs.TransferredCourse__c);
            }                    
        
            if (!eqCrsToControlMap.containsKey(eqCrs.Id))
            {
                System.debug('======> adding equiv course to map: ' + eqCrs.Id);
                eqCrsToControlMap.put(eqCrs.Id, null);               
            }
            
            if (!trCrsToControlMap.containsKey(eqCrs.TransferredCourse__c) && eqCrs.TransferredCourse__c != null)
            {
                System.debug('======> adding trans course to map: ' + eqCrs.TransferredCourse__c);
                trCrsToControlMap.put(eqCrs.TransferredCourse__c, null);
            }
            
            if (!attendanceMap.containsKey(eqCrs.TransferredCourse__r.TransferAttendance__c))
            {
                attendanceMap.put(eqCrs.TransferredCourse__r.TransferAttendance__c, null);
            }
            
            if (!transcriptMap.containsKey(eqCrs.TransferredCourse__r.StudentTransferInstitution__c))
            {
                transcriptMap.put(eqCrs.TransferredCourse__r.StudentTransferInstitution__c, null);
            }
        }
        
        List<TransferAttendance__c> attendanceUpdateList = [SELECT Id FROM TransferAttendance__c WHERE Id IN :attendanceMap.keySet()];
        List<StudentTranscript__c> transcriptUpdateList = [SELECT Id FROM StudentTranscript__c WHERE Id IN :transcriptMap.keySet()];
        
        update attendanceUpdateList;
        update transcriptUpdateList;

        //Pull the list of existing control objects related to the courses        
        trToBannerList = [SELECT Id, StudentEquivalentCourse__c, StudentTransferredCourse__c, StudentEquivalentCourse__r.WGUCourse__c, ActionNeeded__c
                          FROM TranscriptToBanner__c 
                          WHERE StudentEquivalentCourse__c IN :eqCrsIds
                          OR StudentTransferredCourse__c IN :trCrsIds];
                          
        System.debug('=====> existing control object size: ' + trToBannerList.size());
        
        Map<Id, String> trBanToActionMap = new Map<Id, String>();                          
        
        //Repopulate the maps, this time including the control object ids as values to the course keys                  
        for (TranscriptToBanner__c trToBanner : trToBannerList)
        {
            trBanToActionMap.put(trToBanner.Id, trToBanner.ActionNeeded__c);
            
            if (eqCrsToControlMap.containsKey(trToBanner.StudentEquivalentCourse__c))
            {
                eqCrsToControlMap.put(trToBanner.StudentEquivalentCourse__c, trToBanner.Id);
            }
            
            if (trCrsToControlMap.containsKey(trToBanner.StudentTransferredCourse__c))
            {
                trCrsToControlMap.put(trToBanner.StudentTransferredCourse__c, trToBanner.Id);
            }            
        }
        
        System.debug('=====> loading from list size ' + eqCrsList.size());
        Map<Id, Id> dupeCheck = new Map<Id, Id>();
        
        //Populate the lists of control objects with which ones need to be updated vs inserted (null value on course key means new control object needed)                
        for (StudentEquivalentCourse__c eqCrs : eqCrsList)
        {
            System.debug('=====> Transferred Course: ' + eqCrs.TransferredCourse__c);
            if (eqCrs.TransferredCourse__c != null && trCrsToControlMap.containsKey(eqCrs.TransferredCourse__c) && trCrsToControlMap.get(eqCrs.TransferredCourse__c) == null
                && !dupeCheck.containsKey(eqCrs.TransferredCourse__c))
            {
                System.debug('====> Creating new control object for trans course: ' + eqCrs.TransferredCourse__c);
                trToBannerInsertList.add(new TranscriptToBanner__c(RecordTypeId = trCrsRT, 
                                                                   ActionNeeded__c = 'Insert', 
                                                                   StudentTransferredCourse__c = eqCrs.TransferredCourse__c,
                                                                   TransferAttendance__c = eqCrs.TransferredCourse__r.TransferAttendance__c,
                                                                   StudentTransferInstitution__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__c,
                                                                   RefId__c = eqCrs.TransferredCourse__c,
                                                                   ParentId__c = eqCrs.TransferredCourse__r.TransferAttendance__c,
                                                                   Pidm__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c,
                                                                   WGUCourseCode__c = eqCrs.WGUCourse__c));
                dupeCheck.put(eqCrs.TransferredCourse__c, null);
            }
            else if (eqCrs.TransferredCourse__c != null && trCrsToControlMap.containsKey(eqCrs.TransferredCourse__c) 
                     && !dupeCheck.containsKey(trCrsToControlMap.get(eqCrs.TransferredCourse__c))
                     && !dupeCheck.containsKey(eqCrs.TransferredCourse__c))
            {   
                System.debug('====> Updating control object for trans course: ' + eqCrs.TransferredCourse__c);
                
                String action = trBanToActionMap.get(trCrsToControlMap.get(eqCrs.TransferredCourse__c)) == 'Insert' ? 'Insert' : 'Update';                              
                        
                trToBannerUpdateList.add(new TranscriptToBanner__c(Id = trCrsToControlMap.get(eqCrs.TransferredCourse__c), 
                                                                   ActionNeeded__c = action,
                                                                   ParentId__c = eqCrs.TransferredCourse__r.TransferAttendance__c,
                                                                   StudentTransferredCourse__c = eqCrs.TransferredCourse__c,
                                                                   TransferAttendance__c = eqCrs.TransferredCourse__r.TransferAttendance__c,
                                                                   StudentTransferInstitution__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__c,                                                                   
                                                                   WGUCourseCode__c = eqCrs.WGUCourse__c,
                                                                   Pidm__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c));
                //Prevent duplicate Transfer Courses from being added to update list
                dupeCheck.put(trCrsToControlMap.get(eqCrs.TransferredCourse__c), null);                                                   
            }
                     
            if (eqCrsToControlMap.containsKey(eqCrs.Id) && eqCrsToControlMap.get(eqCrs.Id) == null
                && !dupeCheck.containsKey(eqCrs.Id))
            {
                System.debug('====> Creating new control object for equiv course: ' + eqCrs.Id);
                trToBannerInsertList.add(new TranscriptToBanner__c(RecordTypeId = eqCrsRT, 
                                                                   StudentEquivalentCourse__c = eqCrs.Id,
                                                                   StudentTransferredCourse__c = eqCrs.TransferredCourse__c,
                                                                   TransferAttendance__c = eqCrs.TransferredCourse__r.TransferAttendance__c,
                                                                   StudentTransferInstitution__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__c,                                                                    
                                                                   ActionNeeded__c = 'Insert',
                                                                   RefId__c = eqCrs.Id,
                                                                   ParentId__c = eqCrs.TransferredCourse__c,
                                                                   Pidm__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c));
                dupeCheck.put(eqCrs.Id, null);
            }
            else if (eqCrsToControlMap.containsKey(eqCrs.Id) 
                     && !dupeCheck.containsKey(eqCrsToControlMap.get(eqCrs.Id))
                     && !dupeCheck.containsKey(eqCrs.Id))
            {  
                System.debug('====> Updating control object for equiv course: ' + eqCrs.Id);  
                
                String action = trBanToActionMap.get(eqCrsToControlMap.get(eqCrs.Id)) == 'Insert' ? 'Insert' : 'Update'; 
                            
                trToBannerUpdateList.add(new TranscriptToBanner__c(Id = eqCrsToControlMap.get(eqCrs.Id),
                                                                   StudentTransferredCourse__c = eqCrs.TransferredCourse__c,
                                                                   TransferAttendance__c = eqCrs.TransferredCourse__r.TransferAttendance__c,
                                                                   StudentTransferInstitution__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__c,                 
                                                                   ActionNeeded__c = action,
                                                                   ParentId__c = eqCrs.TransferredCourse__c,
                                                                   Pidm__c = eqCrs.TransferredCourse__r.TransferAttendance__r.StudentTransferInstitution__r.Pidm__c));
                dupeCheck.put(eqCrsToControlMap.get(eqCrs.Id), null);
            }
            
            eqCrs.PushedToBanner__c = true;
        }
        
        insert trToBannerInsertList;
        update trToBannerUpdateList; 
        update eqCrsList;       
    }                
}