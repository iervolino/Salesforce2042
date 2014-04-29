/*
 * Author Raavi
 * Western Governors University
 *
 * Date February 11, 2013 @ 1322 hrs
 * Revised: PersonAccount Refactor, try/catch correction for future calls - Paul Coleman 
 *
 * Utility class to support static and @future method calls from FieldExperienceProcess__c object's Trigger class
 *
 * DECLARED WITHOUT SHARING TO ENSURE PROPER RECORD SYNCRHONIZATION
 *
 */
 public without sharing class FieldExperienceProcessUtility {
 
 
/////////////////////////////////////////// START CREATE CASE ///////////////////////////////////////////////// 
    public static void createWGUPlacesStudentCase(String TriggerNewJSON) {
        if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processCreateWGUPlacesStudentCase( TriggerNewJSON );
       } else {
          asyncCreateWGUPlacesStudentCase( TriggerNewJSON );
       }
    }
    
    @future
    private static void asyncCreateWGUPlacesStudentCase(String TriggerNewJSON) {
         processCreateWGUPlacesStudentCase(TriggerNewJSON);
    }
    
    private static void processCreateWGUPlacesStudentCase(String TriggerNewJSON) {
        
      List<FieldExperienceProcess__c> TriggerNew = (List<FieldExperienceProcess__c>)JSON.deserialize(TriggerNewJSON, List<FieldExperienceProcess__c>.class );
      List<Case> casesForInsert = new List<Case>();
        Id QueueId = [SELECT QueueId FROM QueueSobject WHERE sobjecttype ='Case' AND Queue.DeveloperName='FELogisticsQueue' LIMIT 1].QueueId;
        Id RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype ='Case' AND DeveloperName='FieldPlacement' LIMIT 1].Id;
        system.debug('raavi==============' +RecordTypeId);
        System.debug( LoggingLevel.DEBUG, 'TriggerNew ARRAY in createWGUPlacesStudentCase: ' + JSON.serialize(TriggerNew));
        
            for(FieldExperienceProcess__c fep : [Select Id,Student__c,FieldExperience__r.Student__c,District__r.Name,School__r.Name,District__r.WGUPlacesStudents__c,School__r.WGUPlacesStudents__c from FieldExperienceProcess__c WHERE Id in :TriggerNew AND RecordType.DeveloperName = 'PlacementAttempt'] ) {

                    if( (fep.Student__c != null || (fep.FieldExperience__c != null && fep.FieldExperience__r.Student__c != null)) && ((fep.District__c != null && fep.District__r.WGUPlacesStudents__c==true) || (fep.School__c != null && fep.School__r.WGUPlacesStudents__c ==true)) ) {
                        casesForInsert.add( new Case(Status='New',Priority ='High',Origin='Web',Subject='WGU Places Student',OwnerId=QueueId,RecordTypeId =RecordTypeId, contactId=(fep.Student__c!=null? fep.Student__c : fep.FieldExperience__r.Student__c),Description=((fep.District__c != null && fep.District__r.WGUPlacesStudents__c==true)? fep.District__r.Name : fep.School__r.Name)) );
                    }

            }
        if ( !casesForInsert.isEmpty() ) { 
            insert casesForInsert;
        System.debug( LoggingLevel.DEBUG, 'casesForInsert ARRAY in createWGUPlacesStudentCase: ' + JSON.serialize(casesForInsert));
        }
    }
/////////////////////////////////////////// END CREATE CASE ///////////////////////////////////////////////// 

   
}