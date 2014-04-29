/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date Feb 25 2013 @ 2019 hrs
 * Revised: Corrected Mentor Synchronization on FE Record - Paul Coleman
 * 
 * Date January 30 2013 @ 2019 hrs
 * Revised: Person Account Refactor - Paul Coleman
 * 
 * FieldExperience object's Trigger class
 *
 
 */
trigger FieldExperienceTrigger on FieldExperience__c (after update, before insert, before update) {

   if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
         
         //-----RAAVI-----------
         FieldExperienceUtility.updateFEPlacementSpecialist(Trigger.new, Trigger.isUpdate); 
   
       boolean targetFound = false;
       //only process triggered FieldExperience__c records where the Mentor__c field is incorrect and Active = true
       for ( FieldExperience__c fe: (Trigger.isInsert? Trigger.new: [Select Student__c,Mentor__c,Student__r.Mentor__c,Active__c FROM FieldExperience__c WHERE Id in :Trigger.New] ) ) {
           if ( fe.Student__c != null && (Trigger.isInsert || (Trigger.isUpdate && fe.Student__r.Mentor__c != null && fe.Mentor__c != fe.Student__r.Mentor__c)) &&  fe.Active__c == true ) {
               targetFound = true;    
               break;
           }
       }
        
       if ( targetFound ) {
            FieldExperienceUtility.syncFEStudentMentor( Trigger.new, Trigger.isUpdate );
       }
   }


   if ( Trigger.isAfter && Trigger.isUpdate ) {
   
       //find any FieldExperience__c record in the Trigger action that is not active
       if ( [select count() from FieldExperience__c where id in :Trigger.new and Active__c = false] > 0 ) {
   
           boolean targetFound = false;
           for ( FieldExperience__c fe : Trigger.new  ) {
              //find any FieldExperience__c that was just deactivated (switched from Active__c = true to Active__c = false)
              if ( fe.Active__c == false && Trigger.oldMap.get(fe.id).Active__c == true ) {
                   targetFound = true;
                   break;
              }
          }
          
          if ( targetFound ) {
            //Fire off Async close process for all triggered FieldExperience__c records' tasks
            FieldExperienceUtility.closeAllOpenStudentTasks( JSON.serialize(Trigger.new), JSON.serialize(Trigger.oldMap) );
          }

       }
       
       if ( [SELECT count() FROM FieldExperience__c WHERE Id IN :Trigger.new AND AdmissionStatus__c = 'Withdrawn'] > 0 ) {
          boolean targetFound = false;
          for ( FieldExperience__c fe : Trigger.new  ) {
              //find any FieldExperience__c that was just deactivated (switched from Active__c = true to Active__c = false)
              System.debug('================> ' + Trigger.oldMap.get(fe.id).AdmissionStatus__c + ' ' + fe.AdmissionStatus__c);
              if ( fe.AdmissionStatus__c!=null && fe.AdmissionStatus__c=='Withdrawn' && fe.AdmissionStatus__c!=Trigger.oldMap.get(fe.id).AdmissionStatus__c ){
                   targetFound = true;
                   break;
              }
          }
          
          if ( targetFound ) {
            FieldExperienceUtility.doFEWithdraw( JSON.serialize(Trigger.New), JSON.serialize(Trigger.oldMap) ); 
          }
       
       } //END if Withdrawn
      
   }
   
  
}