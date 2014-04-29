/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 15 2013 @ 1348 hrs
 * Revised: Person Account Refactor = Paul Coleman 
 * 
 * Date Oct 30 2012 @ 1026 hrs
 * Revised: Restructured all For loop code with booleans instead of calling into Utility classes before the break (security audit compliance: executing SOQL within For Loops) 
 * 
 * Task object's Trigger class 
 *
 */
trigger TaskTrigger on Task (after insert, after update) {
    
    
    if ( Trigger.isAfter && Trigger.isInsert ) {
     
       //CAREForce Tasks
       Id careTaskId = [select id from RecordType where developerName = 'CAREforceTask' AND sObjectType = 'Task'].id;
       
       if ( [select count() from Task where ID IN :Trigger.new AND CallDisposition__c != null and isDeleted = false AND RecordTypeId = :careTaskId] > 0 ) {
         //Fire off Async Opportunity sync process
         CAREforceUtility.syncOpportunityTaskToCallDisposition( JSON.serialize(Trigger.new) );
        }
    if ( [select count() from Task where ID IN :Trigger.new  and isDeleted = false AND RecordTypeId = :careTaskId] > 0 ) {
         //Fire off Async Opportunity sync process
         CAREforceUtility.sendStatusUpdateToLeadQualDecode( JSON.serialize(Trigger.new) );
       }   
       
    }
    

  if ( Trigger.isAfter && Trigger.isUpdate ) {
       ID studentTaskTypeID = [Select ID from RecordType where DeveloperName='StudentTask' and sObjectType = 'Task' ].id;
       //find any Task in the trigger action that has a TemplateId__c field value of not null (a FieldExperience__c Task)
       if ( [select count() from Task where id in :Trigger.new AND Status != 'Deactivated' AND TemplateId__c != null AND TemplateObjectType__c = 'WGUFEToDo__c' AND RecordTypeId = :studentTaskTypeID] > 0 ) { 
           boolean isTargetRecord = false;
           for ( Task thisTask : Trigger.new ) {
              //find any Task that has changed status
              if ( thisTask.isClosed && !Trigger.oldMap.get(thisTask.id).isClosed ) {
                 isTargetRecord = true;
                 break;
              }
           }
           if (isTargetRecord) {
              //Fire off FieldExperience__c sync process for all triggered Tasks
              FieldExperienceUtility.syncFETaskToCheckBox( JSON.serialize(Trigger.new), JSON.serialize(Trigger.oldMap) );
           }
       }
  }
  
}