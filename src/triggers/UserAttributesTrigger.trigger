/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Revised Feb 14 2013 @ 0920 hrs
 *    -Consolidated code for QA Percentage - Paul Coleman
 *
 * Revised Jan 11 2013 @ 1321 hrs
 *    -Added code for QA Percentage - Will Slade
 *
 * Created Dec 17 2012 @ 1709 hrs
 * 
 * UserAttributes__c object's Trigger class
 *
 */

trigger UserAttributesTrigger on UserAttributes__c (after insert, after update) 
{
  //AFTER UPDATE to Enrollment Users Attributes causes UserRoleId to change on User record
  if ( Trigger.isAfter && Trigger.isUpdate ) {
      Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
      if ( [select count() from UserAttributes__c where id in :Trigger.new AND RecordTypeId =:targetRecordTypeId ] > 0 ) {
         UserAttributesUtility.setUserRoleFromCollegeTeam( Json.serialize(Trigger.new), Json.serialize(Trigger.OldMap), targetRecordTypeId );
      }
  }
  
  //Update QA Percentage on user AFTER INSERT | UPDATE
  if ( Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert ) ) {
  
        List<UserAttributes__c> recordsOfInterest = new List<UserAttributes__c>();
        Set<Id> idsOfInterest = new Set<Id>();
        for ( UserAttributes__c thisUserAttrib : trigger.New ) 
        {
          if ( Trigger.isInsert && thisUserAttrib.User__c != null ) 
          {
             recordsOfInterest.add(thisUserAttrib);
             idsOfInterest.add(thisUserAttrib.User__c);        
          } 
          else if ( Trigger.isUpdate && thisUserAttrib.QAPercentage__c != Trigger.OldMap.get(thisUserAttrib.id).QAPercentage__c && thisUserAttrib.User__c != null ) 
          {
             recordsOfInterest.add(thisUserAttrib);
             idsOfInterest.add(thisUserAttrib.User__c);        
          }
        }
  
        if ( !recordsOfInterest.isEmpty() ) { 
            UserAttributesUtility.updateQAPercentage ( JSON.serialize(recordsOfInterest), JSON.serialize(idsOfInterest) );      
        } 
        
  }
  
  
  
  /*
    //Update QA Percentage on user
    if (Trigger.isAfter && Trigger.isUpdate)
    {       
        List<UserAttributes__c> recordsOfInterest = new List<UserAttributes__c>();
        List<Id> idsOfInterest = new List<Id>();
        
        for (UserAttributes__c uaNew : trigger.New)
        {
            for (UserAttributes__c uaOld : trigger.Old)
            {
                if (uaNew.Id == uaOld.Id && uaNew.QAPercentage__c != uaOld.QAPercentage__c)
                {
                    recordsOfInterest.add(uaNew);
                    idsOfInterest.add(uaNew.User__c);
                }
            }
        }        
        
        if (recordsOfInterest.size() > 0)
        {   
            UserAttributesUtility.updateQAPercentage (JSON.serialize(recordsOfInterest), JSON.serialize(idsOfInterest));                                                                         
        }                                                
    }
    
    //Update QA Percentage on user
    if (Trigger.isAfter && Trigger.isInsert)
    {
        List<UserAttributes__c> recordsOfInterest = [SELECT Id, QAPercentage__c, User__c FROM UserAttributes__c WHERE Id IN :trigger.New];
        List<Id> idsOfInterest = new List<Id>();
        
        for (UserAttributes__c currUA : recordsOfInterest)
        {
            idsOfInterest.add(currUA.User__c);         
        }        
        
        if (recordsOfInterest.size() > 0)
        {                                                                              
            UserAttributesUtility.updateQAPercentage (JSON.serialize(recordsOfInterest), JSON.serialize(idsOfInterest));                                                                         
        }
    }
    */
}