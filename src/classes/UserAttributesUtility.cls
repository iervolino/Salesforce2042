/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date Feb 14, 2013 @ 0849 hrs
 * Revised: Person Account Refactor - Paul Coleman
 * 
 * Created Dec 17 2012 @ 1739 hrs
 * 
 * UserAttributes__c object's Utility methods
 *
 */

public with sharing class UserAttributesUtility {
    
    
 //////////////////////////////////// START SET USER ROLE based on UserAttributes__c.CollegeTeam__c Picklist value  /////////////////////////////////////////////// 
     //UserAttributes__c: AFTER UPDATE, set the UserRoleId on related User record  
     public static void setUserRoleFromCollegeTeam( String ListTriggerNewJSON, String MapTriggerOldJSON, String targetRecordTypeId ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processSetUserRoleFromCollegeTeam(ListTriggerNewJSON, MapTriggerOldJSON, targetRecordTypeId);
       } else {
          asyncSetUserRoleFromCollegeTeam(ListTriggerNewJSON, MapTriggerOldJSON, targetRecordTypeId);
       }
     }
     
     @future
     private static void asyncSetUserRoleFromCollegeTeam( String ListTriggerNewJSON, String MapTriggerOldJSON, String targetRecordTypeId ) {
          processSetUserRoleFromCollegeTeam(ListTriggerNewJSON, MapTriggerOldJSON, targetRecordTypeId);
     }
     
     //UserAttributes__c: after Update, set the UserRoleId on related User record  
     private static void processSetUserRoleFromCollegeTeam( String ListTriggerNewJSON, String MapTriggerOldJSON, String targetRecordTypeId ) {
        
        if ( ListTriggerNewJSON != null ) {
            
              List<UserAttributes__c> TriggerNew = (List<UserAttributes__c>)JSON.deserialize( ListTriggerNewJSON, List<UserAttributes__c>.class );
              Map<Id,UserAttributes__c> TriggerOldMap = (Map<Id,UserAttributes__c>)JSON.deserialize( MapTriggerOldJSON, Map<Id,UserAttributes__c>.class );
              Map<String,Id> enrollmentRolesMap = new Map<String,Id>();
              for (UserRole thisRole: [Select id,Name from UserRole where DeveloperName in ('BusinessGraduate','BusinessUndergrad','EnrollmentIT','HealthProfessions','HPPrelicensure','TeachersCollegeElEdSoSci','TeachersCollegeMathScience','TeachersCollegeMEd')]) {
                 enrollmentRolesMap.put( thisRole.Name, thisRole.Id );
              } 
              System.debug( LoggingLevel.DEBUG, '>>>> >>>>> enrollmentRolesMap: ' + JSON.serialize(enrollmentRolesMap));
              List<User> usersForUpdate = new List<User>();
               
              if ( !TriggerNew.isEmpty() ) {
                  Set<Id> userIdSet = new Set<Id>();
                  for ( UserAttributes__c thisAttrib : TriggerNew ) {
                    if( thisAttrib.User__c != null && !userIdSet.contains(thisAttrib.User__c ) ) {
                       userIdSet.add(thisAttrib.User__c);
                    }
                  }
                  System.debug( LoggingLevel.DEBUG, 'USER RECORD IDS FOR ATTRIBUTES IN TRIGGER NEW LIST (USERIDSET): ' + JSON.serialize(userIdSet));
                  Map<Id,User> usersFromTrigger = new Map<Id,User>([Select Id,UserRoleId,UserRole.Name from User where Id in :userIdSet]);
                  System.debug( LoggingLevel.DEBUG, 'USER RECORDS MAP FROM USERIDSET: ' + JSON.serialize(usersFromTrigger));

                for ( UserAttributes__c thisAttrib : TriggerNew ) {
                    if ( thisAttrib.RecordTypeId == targetRecordTypeId ) {
                        UserAttributes__c oldAttrib = TriggerOldMap.get(thisAttrib.Id);
                        if ( thisAttrib.CollegeTeam__c != null && thisAttrib.CollegeTeam__c != oldAttrib.CollegeTeam__c ) {
                      System.debug( LoggingLevel.DEBUG, 'CHANGING COLLEGERTEAM__C TO ('+thisAttrib.CollegeTeam__c+') FROM ('+oldAttrib.CollegeTeam__c+') ');
                            Id newRoleId = enrollmentRolesMap.get(thisAttrib.CollegeTeam__c);
                            User thisUser = usersFromTrigger.get(thisAttrib.User__c);
                            if ( newRoleId != null && thisUser != null && thisUser.UserRoleId != newRoleId ) {
                                usersForUpdate.add(new User(Id=thisUser.Id,UserRoleId=newRoleId) );
                            }
                        } 
                    }
                }
              }
              
              if ( !usersForUpdate.isEmpty() ) {
                update usersForUpdate;
              }
         }      
    } //END FUNCTION : private static void processSetUserRoleFromCollegeTeam
    
//////////////////////////////////// END SET USER ROLE based on UserAttributes__c.CollegeTeam__c Picklist value ////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////// 



//////////////////////////////////// START SET/UPDATE USER QA PERCENTAGE based on UserAttributes__c.QAPercentage__c //////////////////
    public static void updateQAPercentage(String usersToUpdateJSON, String idsToUpdateJSON)
    {
        if (  Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
            processUpdateQAPercentage(usersToUpdateJSON, idsToUpdateJSON);
        } else {
            asyncUpdateQAPercentage(usersToUpdateJSON, idsToUpdateJSON);
        }
    }        
    
    @future
    private static void asyncUpdateQAPercentage(String usersToUpdateJSON, String idsToUpdateJSON)
    {
        processUpdateQAPercentage(usersToUpdateJSON, idsToUpdateJSON);
    }   
     
    private static void processUpdateQAPercentage(String usersToUpdateJSON, String idsToUpdateJSON) 
    {   
        List<UserAttributes__c> recordsToPush = (List<UserAttributes__c>)JSON.deserialize( usersToUpdateJSON, List<UserAttributes__c>.class );
        Set<Id> idsToUpdate = (Set<Id>)JSON.deserialize( idsToUpdateJSON, Set<Id>.class );
        
        Map<Id,User> userRecords = new Map<Id,User>([SELECT Id,QAPercentage__c FROM User WHERE Id IN :idsToUpdate]);
        List<User> usersForUpdate = new List<User>();         
        Map<Id, Decimal> userToPercentMap = new Map<Id, Decimal>();
                 
        for (UserAttributes__c currUA : recordsToPush)
        {
            System.debug(LoggingLevel.DEBUG, '===================> map entries ' + currUA.User__c + ' ' + currUA.QAPercentage__c);            
            User currUser = userRecords.get( currUA.User__c );
            if ( currUser != null && currUser.QAPercentage__c != currUA.QAPercentage__c ) {
              usersForUpdate.add( new User(Id=currUser.id, QAPercentage__c=currUA.QAPercentage__c) );
            }
        }              
        
        if ( !usersForUpdate.isEmpty() ) {
          update usersForUpdate;
        }
    } 
//////////////////////////////////// END SET/UPDATE USER QA PERCENTAGE based on UserAttributes__c.QAPercentage__c ////////////////////                 
}