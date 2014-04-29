/*****************************************************************************************************
* Name: StudentProcessTrigger
* Author: Will Slade
* Purpose: Trigger for Student Process Object - multiple functions
* Revisions: 
*    5-31-2013 - Created Trigger
*    7-09-2013 - Modified trigger to avoid multiple/duplicate calls spawned by workflows - Will Slade
*    8-15-2013 - Modified trigger to add type for triggering an approval process
*
******************************************************************************************************/

trigger StudentProcessTrigger on StudentProcess__c (After Insert, After Update, Before Delete, Before Insert) 
{
    ////////////////////// Begin Change Owner of Withdrawal //////////////////////////
    if (trigger.isBefore && trigger.isInsert)
    {
        RecordType wdRT = [SELECT Id FROM RecordType WHERE SObjectType = 'StudentProcess__c' AND DeveloperName = 'Withdrawal' LIMIT 1];
        QueueSObject wdQ = [SELECT QueueId FROM QueueSObject WHERE SObjectType = 'StudentProcess__c' AND Queue.Name = 'Withdraw Recovery' LIMIT 1];        
        
        for (StudentProcess__c wd : Trigger.new)
        {
            if (wd.RecordTypeId == wdRT.Id)
            {
                wd.OwnerId = wdQ.QueueId;
            }
        }
    }
    /////////////////////// End Change Owner of Withdrawal ///////////////////////////
    
    ////////////////// Begin Mark Withdrawal to Banner as Delete ////////////////////
    if (trigger.isBefore && trigger.isDelete)
    {
        List<String> trgRefIds = new List<String>();       
        
        for (StudentProcess__c prc : Trigger.old)
        {            
            trgRefIds.add(String.valueOf(Trigger.oldMap.get(prc.Id).Id));
        }
        
        List<WithdrawalToBanner__c> wdToBanList = [SELECT Id, RefId__c FROM WithdrawalToBanner__c WHERE RefId__c IN :trgRefIds];
        
        for (WithdrawalToBanner__c wdToBan : wdToBanList)
        {
            wdToBan.StudentProcess__c = null;
            wdToBan.ActionNeeded__c = 'Delete';
        }
        
        update wdToBanList;
    }    
    ///////////////////// End Mark Withdrawal to Banner as Delete //////////////////
    
    ////////////////////// Begin Create Withdrawals to Banner //////////////////////
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate))
    {
        RecordType wdRT = [SELECT Id FROM RecordType WHERE SObjectType = 'StudentProcess__c' AND DeveloperName = 'Withdrawal' LIMIT 1]; 
               
        List<StudentProcess__c> wdList = [SELECT Id, StudentPidm__c FROM StudentProcess__c WHERE RecordTypeId = :wdRT.Id AND Id IN :Trigger.New];
        
        System.debug('=====> firstrun ' + StudentProcessUtility.firstRun);
        
        if (wdList.size() > 0 && StudentProcessUtility.firstRun == true)
        {
            StudentProcessUtility.createWithdrawalsToBanner(JSON.serialize(wdList));
            StudentProcessUtility.firstRun = false;
        }
    }
    /////////////////////// End Create Withdrawals to Banner ///////////////////////

    ///////////////////// Create Missing User for Readmissions /////////////////////
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate))
    {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> feContacts = new Set<Id>();
        
        for (StudentProcess__c sp : [SELECT Student__c FROM StudentProcess__c WHERE RecordType.Name = 'Readmission' 
                                     AND Stage__c = 'Requested' AND HoldsExist__c = 'No' AND Id IN :Trigger.new])
        {
            if ( !contactIds.contains(sp.Student__c) )
            {
                contactIds.add(sp.Student__c);
            }
        }
        
        StudentProcessUtility.createMissingStudentUsers(JSON.serialize(contactIds));
        
    /////////////////// End Create Missing User for Readmissions ///////////////////
       
     
        // Triggering an Approval Process
        
         for (StudentProcess__c stprocess : [SELECT Type__c FROM StudentProcess__c WHERE Id IN :Trigger.new])
         
         {
             if(stprocess.Type__c!= null && (stprocess.Type__c == 'Incomplete Course Request' || stprocess.Type__c == 'Late Referral Only' || stprocess.Type__c == 'Late Referral and Incomplete Course Request') && stprocess.Type__c!=Trigger.oldMap.get(stprocess.id).Type__c){
             
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitted for approval. Please approve.');
                req.setObjectId(Trigger.new[0].Id);
                // submit the approval request for processing
                Approval.ProcessResult result = Approval.process(req);
             }
         }
     }
    
     // get the active FE record  for the student and populate in Student Process
     
     if (trigger.isAfter && (trigger.isInsert)){
        List<studentprocess__c> stdprocList = new List<studentprocess__c>();
        for (StudentProcess__c stprocess : [SELECT Id,Student__c,FieldExperience__c FROM StudentProcess__c WHERE RecordType.Name = 'Term Break' AND Id IN :Trigger.new])
        {
          if(stprocess.Student__c!= null){
              stdprocList.add(stprocess);
          }
        }       
        StudentProcessUtility.populateFEonSdtProcess(JSON.serialize(stdprocList));
    }
    
}