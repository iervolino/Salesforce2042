/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 13 2013 @ 0858  hrs
 * Revised: Added Before INSERT | UPDATE block for Student Contactid=AccountId Synchronization - Paul Coleman
 * 
 * Created Date Aug 06 2012 @ 0940 hrs
 * 
 * Various after update Case processes 
 *
 */

trigger CaseTrigger on Case (before insert, before update, after update) {
   
   //keep Contactid and Accountid on Case in sync
   /*
   if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
       system.debug('~~~~~~~~~~~~~~~~~ Case Trigger isBefore, isInsert ~~~~~~~~~~~~~~~~~~~~~' );
      //Update every Case record where ContactId is a student Contact and AccountId does not match
      Set<Id> contactIds = new Set<Id>();
      //----Get the case records ---RAAVI
      Set<String> caseQueId=new Set<String>();
      for ( Case thisCase: Trigger.New ) {
          caseQueId.add(thisCase.ownerId);
      //------    
          
        if ( thisCase.contactID != null ) {
            contactIds.add(thisCase.contactId);
        } 
      } 
      if ( !contactIds.isEmpty() ) {
          Map<Id,Contact> contactsMap = new Map<Id,Contact>([SELECT Id,AccountId,Account.StudentContact__c FROM Contact WHERE Id IN :contactIds]);
          for ( Case contactCase: Trigger.new ) {
            Contact thisContact = contactsMap.get(contactCase.contactId);
            if ( thisContact != null && thisContact.AccountId != null && thisContact.Account.StudentContact__c != null && contactCase.AccountId != thisContact.AccountId ) {
                 //synchronize AccountId for Student Case records based on Contact->Account relationship
                  contactCase.AccountId = thisContact.AccountId;
            }
          }
      }
      
      // Update the recordtype when the Queue is changed
      if(Trigger.isUpdate){
         Map<String,String> mapRecNameRecId=new Map<String,String>();               
         Map<String,String> queueMap=new Map<String,String>(); 
         Map<String,String> kvMap=new Map<String,String>();
         
         // Get the Queue Id for selected new Queue value
         for(QueueSobject q : [Select Id, Queue.Name,Queue.Id from QueueSobject where sobjecttype='Case' and Queue.Id in:caseQueId  ORDER BY Queue.Name]){
            queueMap.put(q.Queue.Id,q.Queue.Name);
         }
         // Get the associated Recordtype from Keyvalue__c for selected new Queue value
         for(KeyValue__c kv : [select name,Value__c from KeyValue__c where RecordType.Name = 'Queue']){
             kvMap.put(kv.Name,kv.Value__c);
         }
         // Get the Recordtype Id for the value 
         for(RecordType Rectype : [Select Id,developerName,Name from RecordType where sobjecttype='Case']){
            // mapRecNameRecId.put(Rectype.developerName,RecType.Id);
            mapRecNameRecId.put(Rectype.Name,RecType.Id);
         }
         //Update the case with the Recordtype
         for (Case caseRectype: Trigger.new ) {
         
             caseRectype.recordtypeId=Trigger.newMap.get(caseRectype.id).OwnerId!=Trigger.oldmap.get(caseRectype.Id).OwnerId && queueMap!=null && queueMap.get(caseRectype.ownerId)!=null && kvMap!=null && kvMap.get(queueMap.get(caseRectype.ownerId))!=null && mapRecNameRecId!=null && mapRecNameRecId.get(kvMap.get(queueMap.get(caseRectype.ownerId)))!=null?mapRecNameRecId.get(kvMap.get(queueMap.get(caseRectype.ownerId))):caseRectype.recordtypeId;
             /*if(Trigger.newMap.get(caseRectype.id).OwnerId!=Trigger.oldmap.get(caseRectype.Id).OwnerId && queueMap!=null && queueMap.get(caseRectype.ownerId)!=null && kvMap!=null && kvMap.get(queueMap.get(caseRectype.ownerId))!=null && mapRecNameRecId!=null && mapRecNameRecId.get(kvMap.get(queueMap.get(caseRectype.ownerId)))!=null){
                 caseRectype.recordtypeId=mapRecNameRecId.get(kvMap.get(queueMap.get(caseRectype.ownerId)));
               }* /
         }
      
      }
      //IMPLICIT COMMIT OF CHANGES ON BEFORE EVENT
      
     

   }*/
   
   
   //When Case Owner is not SysAdmin or Queue, transfer any associated Tasks to Case OwnerId 
   if ( Trigger.isAfter && Trigger.isUpdate ) {
     Set<Id> queueIds = new Set<Id>();
     for ( QueueSobject q : [Select q.SystemModstamp, q.SobjectType, q.QueueId, q.Id, q.CreatedById From QueueSobject q where SobjectType = 'Case'] ) {
          queueIds.add( q.QueueId );
     } 
     ID sysAdminId = [SELECT Id from User where alias = 'sadmi' LIMIT 1].id;
     ID studentTaskID = [Select ID from RecordType where DeveloperName='EmployeeTask' and sObjectType = 'Task' LIMIT 1].ID;
     //count all cases with non-queue and non-sadmin ownership
     //system.debug('~~~~~~~~~~~~~~~~~ Case sysAdminId ~~~~~~~~~~~~~~~~~~~~~' + sysAdminId );
     //system.debug('~~~~~~~~~~~~~~~~~ Case studentTaskID ~~~~~~~~~~~~~~~~~~~~~' + studentTaskID );
     if ( [SELECT count() FROM Case WHERE OwnerId NOT in :queueIds AND OwnerId != :sysAdminId AND id IN :Trigger.New] > 0 ) { 
       //Fire off Async Task Transfer process
       CaseUtility.transferOpenSysAdminTasks( JSON.serialize(Trigger.new), JSON.serialize(Trigger.oldMap) );  
     } 
     
     // Case History //
     CaseUtility.updateCaseHistory( JSON.serialize(Trigger.new), JSON.serialize(Trigger.oldMap)  );

       
   }
    
   
}