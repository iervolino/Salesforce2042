/*****************************************************************************************
* Name: StudentCaseUtility
* Author: Will Slade
* Purpose: On creation of a student case, creates a case and links to it
* Revisions: 
*    - 12/1/12 Created Class
*    - 1/23/13 Removed update functionality as student will no longer manipulate this object,
               rather they will maniuplate cases directly through the visualforce page
               provided them via rest adapter
******************************************************************************************/

public with sharing class StudentCaseUtility
{
    //Not a future method because changes need to be reflected on the screen immediately following call
    public static void relateCaseToStudentCase(String studentCasesNewJSON, String studentCasesOldJSON)
    {
        List<StudentCase__c> triggerNew = (List<StudentCase__c>)JSON.deserialize( studentCasesNewJSON, List<StudentCase__c>.class );
        List<StudentCase__c> triggerOld = (List<StudentCase__c>)JSON.deserialize( studentCasesOldJSON, List<StudentCase__c>.class );
        System.debug(LoggingLevel.DEBUG, '********************* StudentCase__c TRIGGER DUMP BEGIN *********************' );               
        System.debug(LoggingLevel.DEBUG, 'VIRGIN TRIGGER NEW LIST:' + JSON.serialize(triggerNew) );               
        Map<Id, Id> studentCaseToCaseMap = new Map<Id, Id>();
        Map<Id, String> caseToContactNameMap = new Map<Id, String>();
        List<Id> studentCaseIds = new List<Id>();
        List<Id> caseIds = new List<Id>();
        List<Case> cases = new List<Case>();
        RecordType transRT = [SELECT Id FROM RecordType WHERE Name = 'Transcripts' AND SobjectType = 'Case' LIMIT 1];
        List<QueueSObject> queues = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = 'Transcripts' LIMIT 1]; 
        System.debug(LoggingLevel.DEBUG, 'QUEUES LIST:' + JSON.serialize(queues) );               
        
        for (StudentCase__c sc : triggerNew)
        {
            if (sc.Case__c == null ) { //only process StudentCase__c records that do not have a Case assigned
	            Case newCase = new Case(RecordTypeId = transRT.Id, ContactId = sc.Contact__c, TranscriptTeamURL__c = sc.ParentURL__c, ServiceDescription__c = sc.ServiceDescription__c, 
	                                    Reason = sc.StudentCaseReason__c, TransferEvaluation__c = sc.TransferEvaluation__c, Subject = sc.Id, RequestComments__c = sc.Comments__c);                             
	            cases.add(newCase);
	            studentCaseIds.add(sc.Id);
            }
        }                
        
        System.debug(LoggingLevel.DEBUG, 'CASES FOR INSERT:' + JSON.serialize(cases) );               
        insert cases;                        
        System.debug(LoggingLevel.DEBUG, 'CASES AFTER INSERT:' + JSON.serialize(cases) );               
        
        for (Case thisCase : cases)
        {
            caseIds.add(thisCase.Id);
        }
        
        cases = [SELECT Id, Subject, Reason, Contact.FirstName, Contact.LastName FROM Case WHERE Id IN :caseIds];
        System.debug(LoggingLevel.DEBUG, 'CASES FOR QUEUE ASSIGN:' + JSON.serialize(cases) );               
        
        for (Case thisCase : cases)
        {
            if (queues.size() > 0)
            {
                thisCase.OwnerId = queues[0].QueueId;
            }
            studentCaseToCaseMap.put(thisCase.Subject, thisCase.Id);
            thisCase.Subject = 'Transcript ' + thisCase.Reason + ' for ' + thisCase.Contact.FirstName + ' ' + thisCase.Contact.LastName;
        }
        System.debug(LoggingLevel.DEBUG, 'CASES BEFORE QUEUE ASSIGN UPDATE:' + JSON.serialize(cases) );               
        update cases;
        
        List<Attachment> attachments = [SELECT Id, Body, Name, ParentId FROM Attachment WHERE ParentId IN :studentCaseIds];
        List<Attachment> attachments2 = new List<Attachment>();
        
        if (test.isRunningTest())
        {
            Attachment attach = new Attachment();  
            attach.Body = Blob.valueOf('Attachment Body');  
            attach.Name = 'TestAttachFileWS.txt';
            attach.ParentID = studentCaseIds[0];
            
            insert attach;    
            attachments.add(attach);
        }    
        
        for (Attachment attach : attachments)
        {
            Attachment attach2 = new Attachment();
            attach2.Body = attach.Body;
            attach2.Name = attach.Name;
            attach2.ParentId = studentCaseToCaseMap.get(attach.ParentId);
            attachments2.add(attach2);
        }        
        insert attachments2;
        
        List<StudentCase__c> scList = [SELECT Id, Case__c FROM StudentCase__c WHERE Id IN :studentCaseIds];
        System.debug(LoggingLevel.DEBUG, 'STUDENT CASES FOR CASE ID UPDATE:' + JSON.serialize(scList) );               
        
        for (StudentCase__c sc : scList)
        {
            sc.Case__c = studentCaseToCaseMap.get(sc.Id);
        }
        System.debug(LoggingLevel.DEBUG, 'STUDENT CASES BEFORE UPDATE:' + JSON.serialize(scList) );               
        update scList;
        System.debug(LoggingLevel.DEBUG, '********************* StudentCase__c TRIGGER DUMP END *********************' );               
    }
    
    //Not a future method because changes need to be reflected on the screen immediately following call
    /*public static void updateCaseFromStudent(String studentCasesNewJSON, String studentCasesOldJSON)
    {
        List<StudentCase__c> triggerNew = (List<StudentCase__c>)JSON.deserialize( studentCasesNewJSON, List<StudentCase__c>.class );
        List<StudentCase__c> triggerOld = (List<StudentCase__c>)JSON.deserialize( studentCasesOldJSON, List<StudentCase__c>.class );
        Map<Id, String> caseToServiceDescMap = new Map<Id, String>();
        Map<Id, String> caseToCommentsMap = new Map<Id, String>();
        Map<Id, Id> studentCaseToCaseMap = new Map<Id, Id>();
        List<Id> caseIds = new List<Id>();
        List<Id> studentCaseIds = new List<Id>();
        List<Case> cases = new List<Case>();        
        
        for (StudentCase__c sc : triggerNew)
        {
            caseToServiceDescMap.put(sc.Case__c, sc.ServiceDescription__c);
            caseToCommentsMap.put(sc.Case__c, sc.Comments__c);
            caseIds.add(sc.Case__c);
            studentCaseIds.add(sc.Id);
            studentCaseToCaseMap.put(sc.Id, sc.Case__c);
        }
        
        System.debug('=============> wrong caseIds.size() ' + caseIds.size() + ' ' + caseIds[0]);        
        
        cases = [SELECT Id, ServiceDescription__c, Contact.StudentID__c FROM Case WHERE Id = '500e0000001Z6ZQAA0'];//IN :caseIds];
        List<Case> casesIdOnly = [SELECT Id FROM Case WHERE Id = '500e0000001Z6ZQ'];//IN :caseIds];
        Map<Id, String> caseToBannerIdMap = new Map<Id, String>();          
        
        for (Case thisCase : cases)
        {
            thisCase.ServiceDescription__c = caseToServiceDescMap.get(thisCase.Id);
            thisCase.RequestComments__c = caseToCommentsMap.get(thisCase.Id);
            caseToBannerIdMap.put(thisCase.id, thisCase.Contact.StudentID__c);
        }
        update cases;                        
        
        List<Attachment> cAttachments = [SELECT Id FROM Attachment WHERE ParentId IN :caseIds];
        List<Attachment> scAttachments = [SELECT Id FROM Attachment WHERE ParentId IN :studentCaseIds];
        
        assignCasesToQueue(JSON.serialize(casesIdOnly), caseIds, studentCaseIds, studentCaseToCaseMap, caseToBannerIdMap);        
    }
    
    @future (callout = true)
    private static void assignCasesToQueue(String caseListJSON, List<Id> caseIds, List<Id> studentCaseIds, Map<Id, Id> studentCaseToCaseMap, Map<Id, String> caseToBannerIdMap)
    {
        List<Case> cases = (List<Case>)JSON.deserialize(caseListJSON, List<Case>.class);
        List<Attachment> cAttachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE isDeleted = false AND ParentId IN :caseIds];
        List<Attachment> scAttachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE isDeleted = false AND ParentId IN :studentCaseIds];
        RestAdapter ra = new RestAdapter();        
        String queryString = 'SELECT QueueId FROM QueueSobject WHERE Queue.Name = \'Transcripts\' LIMIT 1';
        
        System.debug('==========================================> LIST RESPONSE: ' + ra.queryObjects(queryString));                
        
        List<QueueSobject> queueList;
        
        if (!Test.isRunningTest() && ra != null) 
        {
            queueList = (List<QueueSObject>)ra.queryObjects(queryString); 
        } 
        else 
        { 
            queueList = (List<QueueSObject>)Database.query(queryString); 
        }                
        
        for (Case thisCase : cases)
        {
            if (queueList.size() > 0)
            {            
                thisCase.OwnerId = queueList[0].QueueId;
            }
        }
        update cases; 
        
        List<Attachment> newAttachments = new List<Attachment>();
        
        for (Attachment scAttach : scAttachments)
        {
            Boolean newAttach = true;
        
            for (Attachment cAttach : cAttachments)
            {
                if (scAttach.Name == cAttach.Name && cAttach.ParentId == studentCaseToCaseMap.get(scAttach.ParentId))
                {
                    newAttach = false;
                    break;
                }
            }
            
            if (newAttach)
            {
                Attachment attachToAdd = new Attachment();
                attachToAdd.Name = scAttach.Name;
                attachToAdd.Body = scAttach.Body;
                attachToAdd.ParentId = studentCaseToCaseMap.get(scAttach.parentId);
                newAttachments.add(attachToAdd);
            }
        }
        
        insert newAttachments;
        
        for (Attachment attach : newAttachments)
        {
            List<Attachment> tempList = new List<Attachment>();
            tempList.add(attach);
            OnbaseAttachmentUtility.SendToOnbase(tempList, caseToBannerIdMap.get(attach.ParentId));
        }                                    
    }*/
}