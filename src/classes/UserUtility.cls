/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date Feb 20, 2013 @ 1500 hrs
 * Revised: Added recoverFromUsernameChange block - Paul Coleman 
 *
 * Revised Dec 17 2012 @ 1709 hrs
 * Revised: added After Insert logic for creating UserAttributes__c object for enrollment process users - Paul Coleman 
 * 
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) - Paul Coleman 
 *
 * User object's Utility methods
 *
 */
public with sharing class UserUtility {
  
    //User: before Insert (do not use before or after 'Update' for timezone updates, because the User needs to be able to override the timezone setting based on current location [for scheduling])
    public static void UserTimeZoneSetTrigger( List<User> TriggerNew ) {
        ID studentProfileID = [select id from Profile where Name = 'Student Profile' LIMIT 1].id;
        ID WGUChatterProfileID = [select id from Profile where Name = 'WGU Chatter Only'].id;

        for (User thisUser: TriggerNew ) {
            
          String pidm = thisUser.pidm__c;
          String communityName = Test.isRunningTest()? 't'+String.ValueOf(Crypto.getRandomLong()) : pidm; //generate a unique value if testing
          String[] emailParts = thisUser.Email.split('@');
          String federatedId = Test.isRunningTest()? emailParts[0]+'@wgu.edu'+'.'+communityName: emailParts[0]+'@wgu.edu'; //generate a unique value if testing
            
            thisUser.Alias = thisUser.Alias == null? pidm: thisUser.Alias;
            thisUser.CommunityNickname = thisUser.CommunityNickname == null? communityName: thisUser.CommunityNickname;
            thisUser.FederationIdentifier = thisUser.FederationIdentifier == null? federatedId: thisUser.FederationIdentifier;  
            thisUser.IsEmployee__c = ( thisUser.ProfileID != studentProfileID );
            
          //ensure that any new Employee User records become Standard Licenses, and have the default profile of Chatter Only
            thisUser.ProfileId = ( thisUser.ProfileId == null && thisUser.IsEmployee__c == true )? WGUChatterProfileID: thisUser.ProfileID; 
            
            //ensure that any new Student User records become Customer Portal Licenses, and have the default profile of Student Profile
          thisUser.ProfileId = ( thisUser.IsEmployee__c == false )? studentProfileID: thisUser.ProfileID;

          if ( thisUser.ProfileId != studentProfileID ) {  //student timezones are processed in the Account trigger
             //try timezone lookup by zipcode first (private address zip first, then profile zipcode)
             String zipcode = ( thisUser.WGUPostalCode__c==null? thisUser.PostalCode: thisUser.WGUPostalCode__c );
                    zipcode = ( zipcode!=null && zipcode!='-' ? ( zipcode.contains('-')? zipcode.split('-')[0]: zipcode ) : (zipcode=='-'? null: zipcode));
             System.debug( LoggingLevel.DEBUG, 'ZIPCODE: '+ zipcode );
             String timeZoneValue = ( zipcode != null && TimeZoneByZip__c.getValues(zipcode) != null )? TimeZoneByZip__c.getValues(zipcode).TimeZoneKey__c : null;
                    timeZoneValue =   timeZoneValue==null? ( ( thisUser.WGUState__c != null && States__c.getValues(thisUser.WGUState__c) != null )? States__c.getValues(thisUser.WGUState__c).DefaultTimeZoneKey__c: null ): timeZoneValue;
                    timeZoneValue =   timeZoneValue==null? ( ( thisUser.State != null && States__c.getValues(thisUser.State) != null )? States__c.getValues(thisUser.State).DefaultTimeZoneKey__c: 'America/Denver' ): timeZoneValue;
             
             //TimeZoneSidKey is a required field on User and need only be set when a record is first created, hence before insert
             thisUser.TimeZoneSidKey = timeZoneValue;
          }

        }
    }
  
  
  
/////////////////////////// START SECTION: CREATE User Attributes for enrollment personnel ///////////////////////////////////
     public static void createEnrollmentAttributes( String ListTriggerNewJSON, String MapEnrollmentRolesJSON  ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processCreateEnrollmentAttributes(ListTriggerNewJSON, MapEnrollmentRolesJSON);
       } else {
          asyncCreateEnrollmentAttributes(ListTriggerNewJSON, MapEnrollmentRolesJSON);
       }
     }
     
     @future
     private static void asyncCreateEnrollmentAttributes( String ListTriggerNewJSON, String MapEnrollmentRolesJSON ) {
          processCreateEnrollmentAttributes(ListTriggerNewJSON, MapEnrollmentRolesJSON);
     }
     
     //User: after Update, Create new User Attribute record  
     private static void processCreateEnrollmentAttributes( String ListTriggerNewJSON, String MapEnrollmentRolesJSON ) {
        
          Id targetRecordTypeId = [select id from RecordType where sObjectType = 'UserAttributes__c' AND DeveloperName = 'EnrollmentTeam' LIMIT 1].Id;
          List<User> TriggerNew = (List<User>)JSON.deserialize( ListTriggerNewJSON, List<User>.class );
          Map<Id,UserRole> EnrollmentRolesMap = (Map<Id,UserRole>)JSON.deserialize( MapEnrollmentRolesJSON, Map<Id,UserRole>.class );
          List<UserAttributes__c> userAttributesForInsert = new List<UserAttributes__c>();
          Map<Id,UserAttributes__c> userAttributesMap = new Map<Id,UserAttributes__c>();
          for (UserAttributes__c thisAttrib: [select id,User__c from userAttributes__c where User__c in :TriggerNew] ) {
             if ( !userAttributesMap.containsKey(thisAttrib.User__c) ) {
                  userAttributesMap.put( thisAttrib.User__c, thisAttrib);
             }
          }
           
          for( User thisUser: TriggerNew ) {
                if ( !userAttributesMap.containsKey(thisUser.Id) && EnrollmentRolesMap.containsKey( thisUser.UserRoleId ) ) {
                    UserRole thisUserRole = EnrollmentRolesMap.get(thisUser.UserRoleId); 
                    userAttributesForInsert.add( new UserAttributes__c(Name=thisUser.FirstName+' '+thisUser.LastName+' Attributes', User__c=thisUser.Id, CollegeTeam__c=thisUserRole.Name, RecordTypeId=targetRecordTypeId) );
                }
          }
          
          if ( !userAttributesForInsert.isEmpty() ) {
            insert userAttributesForInsert;
          }
              
      } //END FUNCTION : private static void processCreateEnrollmentAttributes
        
/////////////////////////// END SECTION: CREATE User Attributes for enrollment personnel ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
        
 
//////////////////////////////////// START SECTION: recover from Username change /////////////////////////////////////////////// 
     //User: AFTER UPDATE, recover from Username change by removing notify_bogify from the front of the Email address 
     public static void recoverFromUsernameChange( String ListTriggerNewJSON ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processRecoverFromUsernameChange(ListTriggerNewJSON);
       } else {
          asyncRecoverFromUsernameChange(ListTriggerNewJSON); 
       }
     }
     
     @future
     private static void asyncRecoverFromUsernameChange( String ListTriggerNewJSON ) {
          processRecoverFromUsernameChange(ListTriggerNewJSON);
     }
     
     //User: AFTER UPDATE, recover from Username change by removing notify_bogify from the front of the Email address   
     private static void processRecoverFromUsernameChange( String ListTriggerNewJSON ) {
        
              List<User> triggerNew = (List<User>)JSON.deserialize( ListTriggerNewJSON, List<User>.class );
              List<User> usersForUpdateList = new List<User>();
               
                for( User thisUser: triggerNew ) {
                    if ( thisUser.Email.startsWith('notify_bogify.') && thisUser.NewUserName__c != null ) {
                        String[] emailParts = thisUser.Email.split('notify_bogify\\.');
                        String emailStr = emailParts[1]; 
                        usersForUpdateList.add( new User(Id=thisUser.Id,Email=emailStr,Username=thisUser.NewUserName__c) );
                    }
                }
              
              if ( !usersForUpdateList.isEmpty() ) {
                update usersForUpdateList;
              }
              
        } //END FUNCTION : private static void processRecoverFromUsernameChange
        
//////////////////////////////////// END CREATE User Attributes for enrollment personnel /////////////////////////////// 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
        
  
}