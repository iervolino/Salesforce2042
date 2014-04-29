/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 13 2013 @ 0858  hrs
 * Revised: Added Before INSERT | UPDATE block for Student  Contactid=AccountId  Syncrhonization - Paul Coleman
 * Revised: Person Account refactor, asynchronous try catch removed - Paul Coleman
 * 
 * Date Nov 03 2012 @ 1312  hrs
 * Revised: (security audit compliance: with sharing and SeeAllData=false) 
 * 
 *
 */  
public with sharing class CaseUtility {


//////////////////////////////// START SECTION: TRANSFER SYSADMIN TASKS TO CASE OWNER //////////////////////////////////
   public static void transferOpenSysAdminTasks( String ListNewJSON, String ListOldMapJSON ) {
     if ( Limits.getFutureCalls() > 5 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
       processTransferOpenSysAdminTasks( ListNewJSON, ListOldMapJSON );
     } else {
       try { asyncTransferOpenSysAdminTasks( ListNewJSON, ListOldMapJSON );} catch (Exception e) { processTransferOpenSysAdminTasks( ListNewJSON, ListOldMapJSON ); }
     }
   }
   
   @future
   private static void asyncTransferOpenSysAdminTasks( String ListNewJSON, String ListOldMapJSON ) {
     processTransferOpenSysAdminTasks( ListNewJSON, ListOldMapJSON );
   }
   
   //Case: after Update, look for OwnerId changes, to change corresponding Tasks on the Case
   private static void processTransferOpenSysAdminTasks( String ListNewJSON, String ListOldMapJSON ) {
      List<Case> TriggerNew = (List<Case>)JSON.deserialize( ListNewJSON, List<Case>.class );
      Map<ID,Case> TriggerOldMap = (Map<ID,Case>)JSON.deserialize( ListOldMapJSON, Map<ID,Case>.class );
      
      if ( TriggerNew.size() > 0 && TriggerOldMap.size() > 0  ) {
      
        Map<Id,Group> queues = new Map<ID,Group>([SELECT id FROM Group where Type='Queue' LIMIT 50000]);
        ID sysAdminId = [SELECT Id from User where alias = 'sadmi' LIMIT 1].id;
        
          //get all cases with non-queue and non-sadmin ownership
          List<Case> casesOfInterest = [SELECT id, OwnerId from Case where OwnerId NOT in :queues.keySet() AND OwnerId != :sysAdminId AND id IN :TriggerNew LIMIT 50000];
          
          //get all Tasks for the cases of Interest, if any
          List<Task> tasks = [SELECT id, OwnerId, WhatId from Task where WhatId IN :casesOfInterest and isClosed = false and isDeleted = false AND RecordType.DeveloperName='EmployeeTask' LIMIT 50000];
          List<Task> taskForUpdate = new List<Task>();      
          
          for ( Case thisCase : casesOfInterest ) {
              if ( TriggerOldMap.containsKey(thisCase.id) && thisCase.OwnerId != TriggerOldMap.get(thisCase.id).OwnerID ) {  //newly changed owner
                for ( Task taskRec: tasks ) {
                  //Change all Tasks owned by System Admin account to new owner id
                  if ( taskRec.whatId == thisCase.id && taskRec.Ownerid == sysAdminId ) {
                    taskForUpdate.add( new Task(id=taskRec.id,OwnerId=thisCase.OwnerId) );
                  }
                }
              }
          
          }
       
          if ( !taskForUpdate.isEmpty() ) {
            update taskForUpdate;
          }
                
      }
   }
///////////////////////////////// END SECTION: TRANSFER SYSADMIN TASKS TO CASE OWNER /////////////////////////////////// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////// START SECTION: CASE HISTORY TO SUPPORT TRIGGER //////////////////////////////////

    public static void updateCaseHistory(String ListNewJSON, String ListOldMapJSON) {  
 
        List<Case> TriggerNew = (List<Case>)JSON.deserialize( ListNewJSON, List<Case>.class );
        Map<ID,Case> TriggerOldMap = (Map<ID,Case>)JSON.deserialize( ListOldMapJSON, Map<ID,Case>.class );
        for ( Case newCase : TriggerNew ) {
            //system.debug('~~~~~~~~~~~~~~~ TriggerNew.Status ~~~~~~~~~~~~~ ' + newCase.Status);   
        }
        for ( Case oldCase : TriggerOldMap.values()) {
          //  system.debug('~~~~~~~~~~~~~~~ TriggerOldMap.Status ~~~~~~~~~~~~~ ' + oldCase.Status);   
        }
        insertCaseUpdateHistory(ListNewJSON, ListOldMapJSON);
    }
    
    private static void insertCaseUpdateHistory (String ListNewJSON, String ListOldMapJSON){
        Integer iRows;
        Id oCase;
        Id nCase;
        String sOwnerName;
       RecordType pCase;
        CaseUpdateHistory__c cuh = new CaseUpdateHistory__c();
        List<Case> TriggerNew = (List<Case>)JSON.deserialize( ListNewJSON, List<Case>.class );
        Map<ID,Case> TriggerOldMap = (Map<ID,Case>)JSON.deserialize( ListOldMapJSON, Map<ID,Case>.class );
        
        for ( Case newCase : TriggerNew ) {
            cuh.AppealStatus__c = newCase.AppealStatus__c;
            cuh.Case__c = newCase.Id;
            nCase = newCase.Id;
            cuh.StatusValue__c = newCase.Status;  
            cuh.Escalated__c = newCase.isEscalated;
            cuh.Origin__c = newCase.Origin;
            cuh.ParentCaseCreatedDate__c = newCase.CreatedDate;
            cuh.Priority__c = newCase.Priority;
            cuh.Reason__c = newCase.Reason;
            cuh.StatusChangeTime__c = system.now();
            cuh.Type__c = newCase.Type__c;        
        }
        iRows = checkCUHRows(nCase);
        for ( Case oldCase : TriggerOldMap.values()) {
          //  system.debug('~~~~~~~~~~~~~~~ insertCase TriggerOldMap.OwnerID ~~~~~~~~~~~~~ ' + oldCase.ownerId);
            
            if (iRows != 0){ cuh.PreviousStatusValue__c = oldCase.Status; }   
         //   system.debug('~~~~~~~~~~~~~~~ insertCase Trigger oldCase.ownerId ~~~~~~~~~~~~~ ' + oldCase.ownerId);
           // sOwnerName = getOwnerName(oldCase.ownerId); // Don't know who put this in a for loop / 1-22-14 Dave
            oCase = oldCase.Id;
        }

       // system.debug('~~~~~~~~~~~~~~~ insertCase before insert ~~~~~~~~~~~~~ ');
        //system.debug('~~~~~~~~~~~~~~~ insertCaseUpdateHistory cuh.StatusValue__c ~~~~~~~~~~~~~ ' + cuh.StatusValue__c);
            // if status is open: update
            // get average time
       // system.debug('~~~~~~~~~~~~~~~ insertCaseUpdateHistory cuh.StatusValue__c ~~~~~~~~~~~~~ ' + cuh.StatusValue__c);
        
        //cuh.owner__c = sOwnerName;
        if ( cuh.PreviousStatusValue__c != cuh.StatusValue__c ){
            cuh.RecordTypeId = getRecordTypeId ('Case Status Update'); //012e00000008gHtAAI
            if (iRows != 0){ cuh.PreviousStatusChangeTime__c = previousDate(oCase); }
            /* TEMP
            pCase = getPreviousCaseRecordTypeName(oCase);
            cuh.RecordType__c = pCase.name;
            insert cuh;
            END TEMP */
        }
        system.debug('~~~~~~~~~~~~~~~ insertCase after insert ~~~~~~~~~~~~~ ');        
    }
    
    private static DateTime previousDate (Id caseId){
        List<CaseUpdateHistory__c> rDate;
        DateTime lDate;
        Integer size;
        rDate = [SELECT CreatedDate FROM CaseUpdateHistory__c WHERE Case__c =: caseId ORDER BY CreatedDate DESC]; 
        size = rDate.size();
        If ( size > 0) {
          // system.debug('~~~~~~~~~~~~~~~~~~~~~~~~~ rDate[0] ~~~~~~~~~~~~~~~~~~~ ' + rDate[0].CreatedDate);
        }
        //system.debug('~~~~~~~~~~~~~~~~~~~~~~~~~ Last Date ~~~~~~~~~~~~~~~~~~~ ' + rDate.CreatedDate);
       lDate = rDate[0].CreatedDate;
     //  system.debug('~~~~~~~~~~~~~~~~~~~~~~~~~ getTime() ~~~~~~~~~~~~~~~~~~~ ' + lDate.getTime());
       return lDate; 
    }
    
    private static String getOwnerName (Id oId) {
        Integer iCount;
        Group gName;
        User uName;
        String sName;
        if ( [SELECT count() FROM Group WHERE Id =: oId] > 0 ) { 
            gName = [SELECT Name FROM Group WHERE Id =: oId]; 
            sName = gName.name;
        } else {
           if ( [SELECT count() FROM User WHERE Id =: oId] > 0 ) {  
            uName = [SELECT Name FROM User WHERE Id =: oId]; 
            sName = uName.name;  
           }
        }
        return sName;
    }
    private static Integer checkCUHRows (Id sId){
        return [SELECT count() FROM CaseUpdateHistory__c WHERE Case__c = :sId];
    }
    
    private static Id getRecordTypeId (String sRT){
        RecordType rId;
        rId = [SELECT Id FROM RecordType WHERE Name =: sRT];
        return rId.Id;
    }
    
     private static RecordType getPreviousCaseRecordTypeName (Id id){
        return [SELECT Name FROM RecordType WHERE Id IN (SELECT RecordTypeId FROM Case WHERE ID =: id)];
    }
    
///////////////////////////////// END SECTION: CASE HISTORY TO SUPPORT TRIGGER /////////////////////////////////// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


}