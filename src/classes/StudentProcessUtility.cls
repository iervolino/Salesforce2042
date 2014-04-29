/***************************************************************************************************
* Name: StudentProcessUtility
* Author: Will Slade
* Purpose: Utility Class for Student Process Object - multiple functions
* Revisions: 
*    5-31-2013 - Created Class
*    7-09-2013 - Modified class to avoid multiple/duplicate calls spawned by workflows - Will Slade
*
****************************************************************************************************/

public with sharing class StudentProcessUtility 
{    
    public static boolean firstRun = true;
       
    ///////////////////// Begin Create Withdrawals to Banner /////////////////////
    public static void createWithdrawalsToBanner(String wdListJSON)
    {       
        if (Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() )
        {
            processCreateWithdrawalsToBanner(wdListJSON);
        }
        else
        {
            asyncCreateWithdrawalsToBanner(wdListJSON);
        }
    }
    
    @future
    public static void asyncCreateWithdrawalsToBanner(String wdListJSON)
    {
        processCreateWithdrawalsToBanner(wdListJSON);
    }    

    public static void processCreateWithdrawalsToBanner(String wdListJSON)
    {     
        List<StudentProcess__c> wdList = (List<StudentProcess__c>) JSON.deserialize(wdListJSON, List<StudentProcess__c>.class);   
        List<WithdrawalToBanner__c> wdToBanInsertList = new List<WithdrawalToBanner__c>();
        Map<Id, Id> wdToCtrlMap = new Map<Id, Id>();
        
        //Loop through the list of Withdrawals and populate the keyset of the map with the record ids
        for (StudentProcess__c wd : wdList)
        {
            wdToCtrlMap.put(wd.Id, null);
        }
        
        Set<Id> wdIdSet = wdToCtrlMap.keySet();
        
        wdList = [SELECT Id, StudentPidm__c, Student__r.Pidm__c
                  FROM StudentProcess__c
                  WHERE Id IN :wdIdSet];
        
        List<WithdrawalToBanner__c> wdToBanUpdateList = [SELECT Id, RefId__c, ActionNeeded__c, StudentProcess__c, StudentProcess__r.Student__r.Pidm__c
                                                         FROM WithdrawalToBanner__c
                                                         WHERE StudentProcess__c IN :wdIdSet];
        
        //2nd pass through map - update values with existing control object ids and mark them as Update needed                                         
        for (WithdrawalToBanner__c wdToBan : wdToBanUpdateList)
        {
            wdToCtrlMap.put(wdToBan.StudentProcess__c, wdToBan.Id);            
            wdToBan.actionNeeded__c = wdToBan.actionNeeded__c == 'Insert' ? 'Insert' : 'Update';
            wdToBan.StudentPidm__c = wdToBan.StudentProcess__r.Student__r.Pidm__c;
        }                                          
        
        for (StudentProcess__c wd : wdList)
        {
            if (wdToCtrlMap.get(wd.Id) == null)
            {
                System.debug('=======> size ' + wdList.size() + wd.Id);
                wdToBanInsertList.add(new WithdrawalToBanner__c(StudentProcess__c = wd.Id,
                                                                RefId__c = String.valueOf(wd.Id),
                                                                ActionNeeded__c = 'Insert',
                                                                StudentPidm__c = wd.Student__r.Pidm__c));
            }
        }
        
        update wdToBanUpdateList;
        insert wdToBanInsertList;
    }
    ////////////////////// End Create Withdrawals to Banner //////////////////////
  
    Set<Id> feContacts = new Set<Id>();  
    public static void createMissingStudentUsers(String contactIdsJSON ) 
    {
        if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) 
        {
            processCreateMissingStudentUsers(contactIdsJSON);
        }         
        else 
        {
            asyncCreateMissingStudentUsers(contactIdsJSON);
        }
    } 
     
    @future
    private static void asyncCreateMissingStudentUsers(String contactIdsJSON ) 
    {
        processCreateMissingStudentUsers(contactIdsJSON);
    }
     
    private static void processCreateMissingStudentUsers(String contactIdsJSON ) 
    {           
        Set<Id> contactIds = (Set<Id>)JSON.deserialize(contactIdsJSON, Set<Id>.class);
        
        Map<Id,String> statusResetMap = new Map<Id,String>();
        List<Contact> contactsForUpdate = new List<Contact>();
        
        for ( Contact thisContact : [SELECT Id, Status__c FROM Contact c WHERE PIDM__c != null AND AccountId != null AND Account.isCustomerPortal = false 
                                     AND Account.StudentContact__c != null AND RecordType.DeveloperName IN ('ProspectRecord','StudentRecord') AND Id in :contactIds] ) 
        { 
            if ( thisContact.Status__c != 'AS' && thisContact.Status__c != 'TB' ) 
            {
                statusResetMap.put( thisContact.Id, thisContact.Status__c );
            }
            
            contactsForUpdate.add( new Contact( Id = thisContact.Id, Status__c = (( thisContact.Status__c != 'AS' && thisContact.Status__c != 'TB' ) ? 'AS' : thisContact.Status__c ))); 
        }
        
        if ( !contactsForUpdate.isEmpty() ) 
        {
            update contactsForUpdate;
            
            for (Contact thisContact : contactsForUpdate)
            {
                if (statusResetMap.containsKey(thisContact.Id))
                {
                    thisContact.Status__c = statusResetMap.get(thisContact.Id);
                }
            }           
            update contactsForUpdate;
        }
    }
    
    
    // get the active FE record  for the student and populate in Student Process
    
     public static void populateFEonSdtProcess(String stdprocListJSON){
        if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
            processpopulateFEonSdtProcess(stdprocListJSON);
        }else{
            asyncpopulateFEonSdtProcess(stdprocListJSON);
        }
     } 
     
     @future
     private static void asyncpopulateFEonSdtProcess(String stdprocListJSON){
        processpopulateFEonSdtProcess(stdprocListJSON);
     }
     
     private static void processpopulateFEonSdtProcess(String stdprocListJSON){  
         List<StudentProcess__c> TriggerNew = (List<StudentProcess__c>)JSON.deserialize(stdprocListJSON, List<StudentProcess__c>.class );         
         //Map<String,String> StdprocessMap = new Map<String,String>();
         List<StudentProcess__c> updateList = new List<StudentProcess__c>();
         Set<Id> studentSet = new Set<Id>();
         for(StudentProcess__c stdprocess : TriggerNew){
             if(stdprocess.Student__c != null){
                 //StdprocessMap.put(stdprocess.Id,stdprocess.Student__c);    
                 studentSet.add(stdprocess.Student__c);
             }
         }
         
         Map<String,String> stdFeMap = new Map<String,String>();
         for(FieldExperience__c fe : [Select Id,Student__c from FieldExperience__c  Where Student__c in : studentSet and Active__c = true]){
                 stdFeMap.put(fe.Student__c,fe.Id);
         }       
         for(StudentProcess__c  stdproc :TriggerNew){
             if(stdFeMap != null && stdproc.Student__c!=null && stdFeMap.get(stdproc.Student__c)!=null){
               stdproc.FieldExperience__c = stdFeMap.get(stdproc.Student__c);   
               updateList.add(stdproc);
             }
         
         
         }
         
         if(updateList!= null && updateList.size() > 0)
         {
             Update updateList;
         }
        
     }
}