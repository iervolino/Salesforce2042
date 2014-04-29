trigger FieldExperienceProcessTrigger  on FieldExperienceProcess__c (before insert, before update, after insert){
    
    if( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
         //PHASE 1, Gather FE records by Id
         Set<Id> feIDs = new Set<Id>();
         for ( FieldExperienceProcess__c fep: trigger.New ) {
          if ( fep.FieldExperience__c != null ) {
            feIDs.add( fep.FieldExperience__c );
          }
       }
       //PHASE 2, Get Student__c fields from feIDs
       Map<Id,FieldExperience__c> feRecords = feIDs.isEmpty()? new Map<Id, FieldExperience__c>(): new Map<Id, FieldExperience__c>([SELECT Id,Student__c,Mentor__c FROM FieldExperience__c WHERE Id in :feIDs]);
       
       //PHASE 3, set Student__c  and Mentor on FieldExperienceProcess if referenced FieldExperience has a different or non-null Student__c, Mentor__c value
         for ( FieldExperienceProcess__c fep: trigger.New ) {
              FieldExperience__c fe = (fep.FieldExperience__c != null)? feRecords.get(fep.FieldExperience__c): null;
              fep.Student__c = ( fe != null && fe.Student__c != null )? fe.Student__c: 'CANNOT SAVE FEP RECORD WITHOUT A VALID STUDENT'; //throws exception         
              fep.Mentor__c = ( fe != null && fe.Mentor__c != null )? fe.Mentor__c:null;
         }
    } //implicit commits for Before UPDATE / INSERT


    if( Trigger.isAfter && Trigger.isInsert ){
        
       if( [SELECT count() from FieldExperienceProcess__c WHERE id IN :trigger.new and RecordType.DeveloperName = 'PlacementAttempt'] > 0 ){  
         //fire off future method to create Case for WGU Student Placement
         FieldExperienceProcessUtility.createWGUPlacesStudentCase( JSON.serialize(trigger.new) ); 
       }
   
        }
    
}