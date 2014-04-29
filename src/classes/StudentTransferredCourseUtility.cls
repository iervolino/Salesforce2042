/*****************************************************************************************
* Name: StudentTransferredCourseUtility
* Author: Will Slade
* Purpose: -Updates data integration records for Transfer Attendance via trigger of same name
*          -Updates link to Transfer Attendance via trigger of same name
* Revisions: 
*    - 4/19/2013 Created Class
*
******************************************************************************************/

public class StudentTransferredCourseUtility
{
    ////////////////////////////// Link To Attendance ///////////////////////////////
    public static void linkToAttendance(String transCourseListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processLinkToAttendance(transCourseListJSON);
        }
        else
        {
            asyncLinkToAttendance(transCourseListJSON);
        }
    }
    
    @future
    public static void asyncLinkToAttendance(String transCourseListJSON)
    {
        processLinkToAttendance(transCourseListJSON);
    }

    public static void processLinkToAttendance(String transCourseListJSON)
    {
        List<StudentTransferredCourse__c> transCourseList = (List<StudentTransferredCourse__c>) JSON.deserialize(transCourseListJSON, List<StudentTransferredCourse__c>.class);
        List<StudentTranscript__c> transcrList = new List<StudentTranscript__c>(); 
        List<TransferAttendance__c> trAttList = new List<TransferAttendance__c>();  
        List<TransferAttendance__c> trAttCreateList = new List<TransferAttendance__c>();     
        Map<Id, Id> transcrToAttMap = new Map<Id, Id>();
        RecordType trDegRT = [SELECT Id FROM RecordType WHERE SObjectType = 'KeyValue__c' AND DeveloperName = 'TransferDegree' LIMIT 1];        
        KeyValue__c noDegree = [SELECT Id FROM KeyValue__c WHERE RecordTypeId = :trDegRT.Id AND ExternalID__c = 'ND' LIMIT 1];
        
        //Create initial map linking Transcripts to lowest ID Attendances based on Transfer Courses (all Attendances should be null at this point)
        for (StudentTransferredCourse__c transCourse : transCourseList)
        {
            if (!transcrToAttMap.containsKey(transCourse.StudentTransferInstitution__c) ||
                (transcrToAttMap.get(transCourse.StudentTransferInstitution__c) == null && transCourse.TransferAttendance__c != null) ||
                (transCourse.TransferAttendance__c < transcrToAttMap.get(transCourse.StudentTransferInstitution__c) && transCourse.TransferAttendance__c != null && 
                    transcrToAttMap.get(transCourse.StudentTransferInstitution__c) != null))
            {
                System.debug('=====> adding to map ' + transCourse.StudentTransferInstitution__c);
                transcrToAttMap.put(transCourse.StudentTransferInstitution__c, transCourse.TransferAttendance__c);
            }
        }
        
        Set<Id> transInstIds = transcrToAttMap.keySet();
        
        //Query Attendances to find lowest SFID Attendance in existence for each Transcript, and populate the map (some still may not have attendances and will be null)
        trAttList = [SELECT Id, StudentTransferInstitution__c FROM TransferAttendance__c WHERE StudentTransferInstitution__c IN :transInstIds ORDER BY Id];
        transcrList = [SELECT Id FROM StudentTranscript__c WHERE Id IN :transInstIds ORDER BY Id];
        
        for (TransferAttendance__c trAtt : trAttList)
        {
            if (transcrToAttMap.get(trAtt.StudentTransferInstitution__c) == null || trAtt.Id < transcrToAttMap.get(trAtt.StudentTransferInstitution__c))
            {
                transcrToAttMap.put(trAtt.StudentTransferInstitution__c, trAtt.Id);             
            }
        }
        
        //Create and insert new Attendances for any that were still missing
        for (StudentTranscript__c transcr : transcrList)
        {
            if (transcrToAttMap.get(transcr.Id) == null)
            {
                trAttCreateList.add(new TransferAttendance__c(DegreeAwarded__c = noDegree.Id, StudentTransferInstitution__c = transcr.Id, 
                                                              ProgramName__c = 'NA', StartDate__c = date.valueOf('1950-01-01'), 
                                                              EndDate__c = date.valueOf('2100-01-01')));
            }
        }
        
        insert trAttCreateList;    
        
        trAttList = [SELECT Id, StudentTransferInstitution__c FROM TransferAttendance__c WHERE StudentTransferInstitution__c IN :transInstIds ORDER BY Id];
        
        //Make one final pass at the map filling in the null values with the IDs of the records just inserted
        for (TransferAttendance__c trAtt : trAttList)
        {
            if (transcrToAttMap.get(trAtt.StudentTransferInstitution__c) == null)
            {
                transcrToAttMap.put(trAtt.StudentTransferInstitution__c, trAtt.Id);
            }
        }
        
        //Link the Transfer Courses that were missing links to Transfer Attendances (all should be populated via the now-complete map)
        for (StudentTransferredCourse__c transCourse : transCourseList)
        {
            transCourse.TransferAttendance__c = transcrToAttMap.get(transCourse.StudentTransferInstitution__c);
        } 
        
        update transCourseList;                   
    }  

    /////////////////////////// Update Transcripts To Banner ///////////////////////////    
    public static void updateTranscriptsToBanner(String transCourseListJSON)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processUpdateTranscriptsToBanner(transCourseListJSON);
        }
        else
        {
            asyncUpdateTranscriptsToBanner(transCourseListJSON);
        }
    }
    
    @future
    public static void asyncUpdateTranscriptsToBanner(String transCourseListJSON)
    {
        processUpdateTranscriptsToBanner(transCourseListJSON);
    }

    public static void processUpdateTranscriptsToBanner(String transCourseListJSON)
    {        
        List<StudentTransferredCourse__c> transCourseList = (List<StudentTransferredCourse__c>) JSON.deserialize(transCourseListJSON, List<StudentTransferredCourse__c>.class);
        List<Id> transCourseIds = new List<Id>();
        List<TranscriptToBanner__c> trToBanList = new List<TranscriptToBanner__c>();
        List<TranscriptToBanner__c> trToBanAddList = new List<TranscriptToBanner__c>();
        Map<Id, Id> trCrsToTrBanMap = new Map<Id, Id>();
        RecordType transCourseRT = [SELECT Id FROM RecordType WHERE SObjectType = 'TranscriptToBanner__c' AND DeveloperName = 'StudentTransferredCourse' LIMIT 1];
        
        //Populate map keys with all Transferred Course Ids from the trigger
        for (StudentTransferredCourse__c transCourse : transCourseList)
        {
            transCourseIds.add(transCourse.Id);
            trCrsToTrBanMap.put(transCourse.Id, null);
        }
        
        trToBanList = [SELECT Id, StudentTransferredCourse__c, ActionNeeded__c, StudentTransferredCourse__r.TransferAttendance__r.DegreeAwarded__r.ExternalId__c,
                              StudentTransferredCourse__r.TransferAttendance__c, StudentTransferredCourse__r.StudentTransferInstitution__c,
                              StudentTransferInstitution__r.Opportunity__r.Pidm__c
                       FROM TranscriptToBanner__c 
                       WHERE StudentTransferredCourse__c 
                       IN :transCourseIds 
                       AND RecordTypeId = :transCourseRT.Id];
        
        //Add control object Ids to the map where they exist - also set Action Needed field to Update for push job
        for (TranscriptToBanner__c trToBan : trToBanList)
        {
            trCrsToTrBanMap.put(trToBan.StudentTransferredCourse__c, trToBan.Id);
            trToBan.ActionNeeded__c = trToBan.ActionNeeded__c == 'Insert' ? 'Insert' : 'Update';
            trToBan.TransferAttendance__c = trToBan.StudentTransferredCourse__r.TransferAttendance__c;
            trToBan.StudentTransferInstitution__c = trToBan.StudentTransferredCourse__r.StudentTransferInstitution__c; 
            trToBan.Pidm__c = trToBan.StudentTransferInstitution__r.Opportunity__r.Pidm__c;          
        }
        
        //For any missing control objects, create the record with Insert Action Needed
        for (StudentTransferredCourse__c transCourse : transCourseList)
        {
            if (trCrsToTrBanMap.get(transCourse.Id) == null)
            {
                trToBanAddList.add(new TranscriptToBanner__c(RecordTypeId = transCourseRT.Id, 
                                                             StudentTransferredCourse__c = transCourse.Id,
                                                             TransferAttendance__c = transCourse.TransferAttendance__c,
                                                             StudentTransferInstitution__c = transCourse.TransferAttendance__r.StudentTransferInstitution__c, 
                                                             RefId__c = String.valueOf(transCourse.Id),
                                                             ParentId__c = String.valueOf(transCourse.TransferAttendance__c), 
                                                             ActionNeeded__c = 'Insert',
                                                             Pidm__c = transCourse.StudentTransferInstitution__r.Pidm__c));
            }
        }
        
        update trToBanList;
        insert trToBanAddList;
    }    
}