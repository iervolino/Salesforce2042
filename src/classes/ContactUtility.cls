/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Aug 4, 2013 @ 1414 hrs
 * Revised: Added forwardContactRecords() method with accompanying block for S2S sharing
 *
 * Date Febuary 2, 2013 @ 1600 hrs
 * Revised: Added code block to generate StudentSearchHash__c records (syncStudentSearchHash) and synchronize PIDM & 
 * RecordType.DeveloperName between Contact->Account pairs (syncAccountRecordTypeAndPidm) - Paul Coleman
 *
 * Date Jan 17 2013 @ 1545 hrs
 * Revised: added Limits.getFutureCalls() > 8 clause to syncStudentAccountRecordTrigger() method - Paul Coleman
 *
 * Date August 13 2013 @ 1445 hrs
 * Revised: added createContactToBanner() method - Will Slade
 * 
 * Trigger Utility for managing psuedo Person Account
 * Declared without sharing to support trigger operations
 *
 * Date March 20, 2014
 * Revised: Added check for when the first name, last name, or email is updated that the change is propagated to the user record
 *
 */ 
public without sharing class ContactUtility {
    
    
/////////////////// START SECTION: CONTACT TRIGGER //////////////////////////////////////////

    public static void ContactTrigger (){
        system.debug('~~~~~~~~~~~~~~~~~~~~~~~~~ Contact Trigger ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    } 


/////////////////// END SECTION: CONTACT TRIGGER //////////////////////////////////////////

   
//////////////////////////////// START SECTION: SYNC STUDENT ACCOUNT TO CONTACT AFTER INSERT /////////////////////////////////////////// 
     //Contact: AFTER INSERT, sync student Account record to student Contact record (1:1) 
     //ALWAYS processed synchronously to avoid delay of Contact->Account pairing for processing in other Trigger areas 
     public static void syncStudentAccountRecordTrigger( List<Contact> triggerNew ) {        
            
          Map<Id,Contact> accountIdMap = new Map<Id,Contact>(); //(accountId, contact) map
          
          if ( triggerNew != null && !triggerNew.isEmpty() ) {
            for (Contact student: triggerNew) {
                 accountIdMap.put( student.AccountId, student );
            }
            if ( [select count() from Account where Id in :accountIdMap.keySet() AND StudentContact__c = null] > 0 ) {
                List<Account> accounts = [select id, StudentContact__c from Account where id in :accountIdMap.keySet()];
                for( Account account : accounts ) {
                    account.StudentContact__c = accountIdMap.get(account.Id).Id; //retrieve matching Contact record id
                }
                update accounts;
            }
          }
              
     }
///////////////////////////////// END SECTION: SYNC STUDENT ACCOUNT TO CONTACT AFTER INSERT ///////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
                      

//////////////////////////// START SECTION: FORWARD Student CONTACTS TO S2S Connection: Student API Org /////////////////////////////////////// 

     //Contact: AFTER UPDATE
     //could not delete this method due to future dependencies in Banner Utility Tests	
     public static void forwardContactRecords( String listNewJSON ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          return; //do not process records if can't be done in a future method
       } else {
          asyncForwardContactRecords(listNewJSON);
       }
     }
     
     @future
     private static void asyncForwardContactRecords( String listNewJSON ) {
     	  //could not delete this method due to future dependencies in Banner Utility Tests
          //processForwardContactRecords(listNewJSON);
     }
     
     //Contact: AFTER UPDATE
     /*
     private static void processForwardContactRecords( String listNewJSON ) {
        
          List<Contact> triggernew = (List<Contact>)JSON.deserialize(listNewJSON, List<Contact>.class);
        
          Set<Id> sharedIds = new Set<Id>();
          Set<Id> accountIds = new Set<Id>();
          Set<Id> sharedAccountIds = new Set<Id>();
          if (Test.isRunningTest() && Runtime__c.getValues('StudentAPIConnectionId')==null) {
            insert new Runtime__c(Name='StudentAPIConnectionId',Value__c=[Select id from PartnerNetworkConnection WHERE ConnectionName like 'WGU STUDENT API%' AND ConnectionStatus = 'Accepted'].Id);          
          }
          Id studentapiConxId = (Id)Runtime__c.getValues('StudentAPIConnectionId').Value__c;
          
          for( Contact student: triggernew ) {
            if ( student.AccountId != null ) {
                 accountIds.add( student.AccountId );
            } 
          }
          
          //contact shares
          for ( PartnerNetworkRecordConnection share: [Select LocalRecordId From PartnerNetworkRecordConnection WHERE LocalRecordId IN :triggernew AND Status = 'Sent' AND ConnectionId = :studentapiConxId ]) {
             sharedIds.add( share.LocalRecordId );          
          }
          
          //account shares (ENSURE Account is already shared before forwarding contact record)
          for ( PartnerNetworkRecordConnection share: [Select LocalRecordId From PartnerNetworkRecordConnection WHERE LocalRecordId IN :accountIds AND Status IN ('Sent','Invite') AND ConnectionId = :studentapiConxId ]) {
             sharedAccountIds.add( share.LocalRecordId );           
          }
          
          List<Contact> newShares = new List<Contact>();
          for ( Contact student: [SELECT id,AccountId FROM Contact WHERE Id IN :triggernew AND Account.IsCustomerPortal = true AND Id NOT IN :sharedIds AND PIDM__c != null AND StudentId__c != null AND RecordType.DeveloperName = 'StudentRecord'] ) {
                if ( sharedAccountIds.contains(student.AccountId) ) { //ensure parent account is already shared
                  newShares.add( student );
                }
          }
          
          if ( !newShares.isEmpty() ) {
            //S2SStudentApiBatchUtility.doS2SBatch(newShares);
          }                 
     }  
     */

////////////////////////// END SECTION: FORWARD CONTACTS TO S2S Connection: Student API Org ///////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 


//////////////////////////// START SECTION: CREATE STUDENT USER RECORD (CUSTOMER PORTAL USER) /////////////////////////////////////// 
     //Contact: AFTER UPDATE, create student User records if appropriate (Customer Portal Users)
     public static void createStudentsCustomerUserRecords( String listNewJSON, String recordTypesJSON ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processCreateStudentsCustomerUserRecords(listNewJSON, recordTypesJSON);
       } else {
          asyncCreateStudentsCustomerUserRecords(listNewJSON, recordTypesJSON);
       }
     }
     
     @future
     private static void asyncCreateStudentsCustomerUserRecords( String listNewJSON, String recordTypesJSON  ) {
          processCreateStudentsCustomerUserRecords(listNewJSON, recordTypesJSON);
     }
     
     //Contact: AFTER UPDATE, create student User records if appropriate (Customer Portal Users)
     private static void processCreateStudentsCustomerUserRecords( String listNewJSON, String recordTypesJSON ) {
        
        if ( listNewJSON != null ) {
            
              List<Contact> triggerNew = (List<Contact>)JSON.deserialize( listNewJSON, List<Contact>.class );
              System.debug( LoggingLevel.DEBUG, 'CONTACT RECORDS FOR CUSTOMER USER RECORD EVALUATION: ' + JSON.serialize(triggerNew) );
              
              Map<String,Id> recordTypesMap = (Map<String,Id>)JSON.deserialize( recordTypesJSON, Map<String,Id>.class ); //a map, e.g., {AccountStudentRecord": "012a0000001ZMUzAAO"}
              List<Id> contactRecordTypeIds = new List<Id>();
              for ( String recordTypeReference : recordTypesMap.keySet() ) {
                if ( recordTypeReference.startsWith('Contact') ) {
                  contactRecordTypeIds.add( recordTypesMap.get(recordTypeReference) ); 
                }
              }
              
              List<User> newUserList = new List<User>();
              String environment = StudentUser.getEnvironment();
                      
              String studentProfileId = [Select id from Profile where Name = 'Student Profile' LIMIT 1].id;
              
              Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.EmailHeader.triggerUserEmail = false;
                dmo.EmailHeader.triggerOtherEmail = false;
                dmo.EmailHeader.triggerAutoResponseEmail = false;
                dmo.optAllOrNone = false; 
              
              //Whittle down the triggered list and process only those records without a customer user record
              for ( Contact thisContact: [SELECT Id, FirstName, LastName, PIDM__c, WGUEmail__c, Email, My_WGU_Email__c, OtherEmail__c, MailingState, MailingPostalCode, RecordType.Name, RecordTypeId FROM Contact c WHERE (Status__c in ('AS','TB' ) OR ( Status__c='IN' AND OtherEmail__c != null )) AND PIDM__c != null AND AccountId != null AND Account.isCustomerPortal=false AND Account.StudentContact__c != null AND RecordTypeId IN :contactRecordTypeIds AND Id IN :triggerNew] ) {
                
                  System.debug( LoggingLevel.DEBUG, 'CONTACT IN NEED OF A NEW CUSTOMER USER RECORD: ' + JSON.serialize(thisContact) );                                                
                  newUserList.add( createStudentUser(thisContact, studentProfileId, dmo, environment) );
                                                                
              }
              
              if ( !newUserList.isEmpty() ) {
                System.debug( LoggingLevel.DEBUG, 'USER RECORDS ABOUT TO BE INSERTED: ' + JSON.serialize(newUserList) );
                try {
                  insert newUserList;
                } catch (DMLException e) {
                    for (Integer i = 0; i < e.getNumDml(); i++) {
                          User errorUser = newUserList.get(i);
                          String errorMsg = 'USER INSERT EXCEPTION: ' + e.getDmlMessage(i) + '\t\t' + JSON.serialize( errorUser );
                                    System.debug( LoggingLevel.WARN,  errorMsg ); 
                                    errorUser.addError( errorMsg );
                                }
                }
              }              
        }
     }
              
                   
     //PUBLIC Utility functions for creating a standard WGU Student User record. Can also be used for testing.                 
     public static User createStudentUserFromContactId( Id thisContactId ) {
       Contact thisContact = [SELECT Id, FirstName, LastName, PIDM__c, WGUEmail__c, Email, My_WGU_Email__c, OtherEmail__c, MailingState, MailingPostalCode, RecordType.Name, RecordTypeId FROM Contact c WHERE PIDM__c != null AND AccountId != null AND Account.isCustomerPortal=false AND Account.StudentContact__c != null AND RecordType.DeveloperName IN ('ProspectRecord','StudentRecord') AND Id = :thisContactId LIMIT 1];
         return createStudentUser( thisContact, null, null, null);
     }
     
     public static User createStudentUser( Contact thisContact, Id studentProfileId, Database.DMLOptions dmo, String orgEnvironment ) {
       
        if ( thisContact != null && thisContact.Id != null & thisContact.PIDM__c != null ) {
            
          studentProfileId = (studentProfileId != null)? studentProfileId: [Select id from Profile where Name = 'Student Profile' LIMIT 1].id;
          String environment = (orgEnvironment != null )? orgEnvironment: StudentUser.getEnvironment();
          if ( dmo == null ) {
            dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            dmo.EmailHeader.triggerOtherEmail = false;
            dmo.EmailHeader.triggerAutoResponseEmail = false;
            dmo.optAllOrNone = false; 
          }
        
          
          String pidm = thisContact.PIDM__c;
          String communityName = Test.isRunningTest()? 't'+String.ValueOf(Crypto.getRandomLong()) : pidm; //generate a unique value if testing
                        
          String email = thisContact.WGUEmail__c!=null? thisContact.WGUEmail__c: (thisContact.My_WGU_Email__c!=null? thisContact.My_WGU_Email__c: (thisContact.Email!=null? thisContact.Email: (thisContact.OtherEmail__c!=null? thisContact.OtherEmail__c : pidm+'@my.wgu.edu' ) ));
          String[] emailParts = email.split('@');
          String federatedId = emailParts[0]+'@wgu.edu';
          String wguEmail = federatedId + (environment!='prod' ? ('.'+environment) : '');
          String orgUserName = federatedId+(environment!='prod'? ('.'+environment): (Test.isRunningTest()?'test.'+communityName:'') );
          String zipcode = (thisContact.MailingPostalCode != null && thisContact.MailingPostalCode != '-' &&  thisContact.MailingPostalCode.contains('-'))? thisContact.MailingPostalCode.split('-')[0]: (thisContact.MailingPostalCode == '-'? null: thisContact.MailingPostalCode);
          String timeZoneValue = ( zipcode != null && TimeZoneByZip__c.getValues(zipcode) != null )? TimeZoneByZip__c.getValues(zipcode).TimeZoneKey__c : null;
                 timeZoneValue = timeZoneValue!=null? timeZoneValue: ((thisContact.MailingState!=null && States__c.getValues(thisContact.MailingState)!=null)? States__c.getValues(thisContact.MailingState).DefaultTimeZoneKey__c: 'America/Denver');
          String newAlias = Test.isRunningTest()? communityName.substring(0,8) : pidm.substring(0,pidm.length()>8?7:pidm.length());
            
          //alias length = 8, required
          //community nickname length = 40, required
          User newUser = new User(    LastName              = thisContact.LastName, 
                                      FirstName             = thisContact.FirstName, 
                                      Email                 = wguEmail, 
                                      PIDM__c               = pidm, 
                                      ProfileId             = studentProfileId, 
                                      ContactId             = thisContact.Id, 
                                      Username              = orgUserName, 
                                      FederationIdentifier  = federatedId, 
                                      Alias                 = newAlias, 
                                      CommunityNickname     = communityName,
                                      EmailEncodingKey      = 'UTF-8',  
                                      LanguageLocaleKey     = 'en_US', 
                                      LocalesIdKey          = 'en_US',
                                      TimezonesIdKey        = timeZoneValue, 
                                      IsEmployee__c         = false,
                                      isActive              = true );
            newUser.setOptions(dmo);
            return newUser;
        } else {
          throw new StudentException('REQUIRED PARM ERROR: A valid Contact is a required parameter for ContactUtility.createStudentUser()');
        }
      
     }
     
////////////////////////// END SECTION: CREATE STUDENT USER RECORD (CUSTOMER PORTAL USER) ///////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////// START SECTION: SYNC STUDENT HASH, ACCOUNT PIDM__c AND ACCOUNT RECORD TYPE TO CONTACT AFTER INSERT OR UPDATE ///////////////// 
     //Contact: AFTER INSERT or UPDATE, create/update StudentSearchHash__c
     public static void syncStudentSearchHash( String listNewJSON, String recordTypesJSON, boolean isUpdate ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processSyncStudentSearchHash(listNewJSON, recordTypesJSON, isUpdate); 
       } else {
          asyncSyncStudentSearchHash(listNewJSON, recordTypesJSON, isUpdate);
       }
     }
     
     @future
     private static void asyncSyncStudentSearchHash( String listNewJSON, String recordTypesJSON, boolean isUpdate ) {
          processSyncStudentSearchHash(listNewJSON, recordTypesJSON, isUpdate);
     }
     
     //Contact: AFTER INSERT or UPDATE, create/update StudentSearchHash__c
     private static void processSyncStudentSearchHash( String listNewJSON, String recordTypesJSON, boolean isUpdate ) {
        
        if ( listNewJSON != null ) {
            
              List<Contact> triggerNew = (List<Contact>)JSON.deserialize( listNewJSON, List<Contact>.class );
              Map<String,Id> recordTypesMap = (Map<String,Id>)JSON.deserialize( recordTypesJSON, Map<String,Id>.class ); //a map, e.g., {AccountStudentRecord": "012a0000001ZMUzAAO"}
              List<Id> contactRecordTypeIds = new List<Id>();
              for ( String recordTypeReference : recordTypesMap.keySet() ) {
                if ( recordTypeReference.startsWith('Contact') ) {
                    contactRecordTypeIds.add( recordTypesMap.get(recordTypeReference) );
                }
              }
              
                        List<StudentSearchHash__c> newHashes = new List<StudentSearchHash__c>();
                        List<StudentSearchHash__c> hashesForUpdate = new List<StudentSearchHash__c>();
                        
                        for ( Contact thisContact: [SELECT c.Id, c.LastName, c.FirstName, c.Account.StudentContact__c,  c.PIDM__c, c.Account.PIDM__c, c.Account.RecordType.DeveloperName, c.RecordType.DeveloperName, c.SocialSecurityNumber__c, c.ITINIndividualTaxIdentificationNumber__c, c.DateOfBirth__c, (select s.Id, s.Name, s.SSNHash__c, s.SSNLastFour__c,s.BirthDateHash__c from StudentSearchHashes__r s) FROM Contact c WHERE c.AccountId != null AND c.Account.StudentContact__c != null AND c.RecordTypeId IN :contactRecordTypeIds AND c.Id IN :triggerNew]) {
                                    
                                 StudentSearchHash__c thisContactsHash = thisContact.studentsearchHashes__r.isEmpty()? new StudentSearchHash__c(): thisContact.studentsearchHashes__r[0];
                               String ssn;
                                 String ssnHash;
                                 Integer ssnLast4;
                                 if ( (thisContact.SocialSecurityNumber__c != null && thisContact.SocialSecurityNumber__c.length() == 9 ) || (thisContact.ITINIndividualTaxIdentificationNumber__c != null && thisContact.ITINIndividualTaxIdentificationNumber__c.length() == 9 ) ) {
                                   ssn = thisContact.SocialSecurityNumber__c != null? thisContact.SocialSecurityNumber__c: thisContact.ITINIndividualTaxIdentificationNumber__c;
                                   ssnHash = EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( ssn ) ) );
                                   ssnLast4 = Integer.ValueOf(ssn.substring(5));
                                 
                                 
                                   Date dob = null;
                                   try { dob = (thisContact.DateOfBirth__c != null)? Date.parse(thisContact.DateOfBirth__c): null; } catch (Exception e) {} //ignore bogus dob values
                                     String studentBirthDateHash = (dob != null)?  EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( dob.format() ) ) ): null;
                                   String studentName = thisContact.LastName+', '+thisContact.FirstName;
                        
                                   if ( thisContactsHash.id != null ) {
                                     if ( thisContactsHash.Name != studentName || thisContactsHash.SSNHash__c != ssnHash || thisContactsHash.SSNLastFour__c != ssnLast4 || thisContactsHash.Name != studentName || thisContactsHash.BirthDateHash__c != studentBirthDateHash  ) {
                                       hashesForUpdate.add( new StudentSearchHash__c(Id=thisContactsHash.Id, Name=studentName, SSNHash__c=ssnHash, SSNLastFour__c=ssnLast4, BirthDateHash__c=studentBirthDateHash  ) );
                                     }
                                   } else {
                                     newHashes.add( new StudentSearchHash__c(Name=studentName, Student__c=thisContact.id, StudentAccount__c=thisContact.AccountId, SSNHash__c=ssnHash, SSNLastFour__c=ssnLast4, BirthDateHash__c=studentBirthDateHash  ) );
                                   }
                                 }
                                 
                        }
                        
                            if ( !newHashes.isEmpty() ) {
                                insert newHashes;
                            }
                            
                            if ( !hashesForUpdate.isEmpty() ) {
                                update hashesForUpdate;
                            }
                            
        }
     }
              
//////////////// END SECTION: SYNC STUDENT HASH, ACCOUNT PIDM__c AND ACCOUNT RECORD TYPE TO CONTACT AFTER INSERT OR UPDATE ///////////////// 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
                      




//////////////// START SECTION: SYNC ACCOUNT PIDM__c AND ACCOUNT RECORD TYPE TO CONTACT's VALUES AFTER UPDATE ///////////////// 
     //Contact: AFTER UPDATE, sync student Account's PIDM__c and RecordType.Name field to Contact
     public static void syncAccountRecordTypeAndPidm( String listNewJSON, String recordTypesJSON ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processSyncAccountRecordTypeAndPidm(listNewJSON, recordTypesJSON);
       } else {
          asyncSyncAccountRecordTypeAndPidm(listNewJSON, recordTypesJSON);
       }
     }
     
     @future
     private static void asyncSyncAccountRecordTypeAndPidm( String listNewJSON, String recordTypesJSON  ) {
          processSyncAccountRecordTypeAndPidm(listNewJSON, recordTypesJSON);
     }
     
     //Contact: AFTER UPDATE, sync student Account's PIDM__c and RecordType.Name field to Contact
     private static void processSyncAccountRecordTypeAndPidm( String listNewJSON, String recordTypesJSON ) {
        
        if ( listNewJSON != null ) {
            
              List<Contact> triggerNew = (List<Contact>)JSON.deserialize( listNewJSON, List<Contact>.class );
              Map<String,Id> recordTypesMap = (Map<String,Id>)JSON.deserialize( recordTypesJSON, Map<String,Id>.class ); //a map, e.g., {AccountStudentRecord": "012a0000001ZMUzAAO"}
              List<Id> contactRecordTypeIds = new List<Id>();
              for ( String recordTypeReference : recordTypesMap.keySet() ) {
                if ( recordTypeReference.startsWith('Contact') ) {
                    contactRecordTypeIds.add( recordTypesMap.get(recordTypeReference) );
                }
              }
              
                            Map<Id,Account> accountsForUpdate = new Map<Id,Account>();
                            
                            for ( Contact thisContact: [SELECT c.Id, c.Name, c.FirstName, c.LastName, c.Account.StudentContact__c, c.Account.Name, c.PIDM__c, c.Account.PIDM__c, c.Account.RecordType.DeveloperName, c.RecordType.DeveloperName FROM Contact c WHERE c.AccountId != null AND c.RecordTypeId IN :contactRecordTypeIds AND c.Id IN :triggerNew]) {
                                    
                  if ( thisContact.Account.PIDM__c != thisContact.PIDM__c ) {
                    Account thisAccount = (accountsForUpdate.get(thisContact.AccountId) == null)? new Account(id=thisContact.AccountId): accountsForUpdate.get(thisContact.AccountId);
                    thisAccount.PIDM__c = thisContact.PIDM__c;
                    accountsForUpdate.put( thisContact.AccountId, thisAccount );
                  }
                  
                  if ( thisContact.Account.Name != thisContact.Name ) {
                    Account thisAccount = (accountsForUpdate.get(thisContact.AccountId) == null)? new Account(id=thisContact.AccountId): accountsForUpdate.get(thisContact.AccountId);
                    thisAccount.Name = thisContact.Name!=null? thisContact.Name: thisContact.Account.Name;
                    accountsForUpdate.put( thisContact.AccountId, thisAccount );
                  }
                  
                  if ( thisContact.Account.StudentContact__c != thisContact.Id ) {
                    Account thisAccount = (accountsForUpdate.get(thisContact.AccountId) == null)? new Account(id=thisContact.AccountId): accountsForUpdate.get(thisContact.AccountId);
                    thisAccount.StudentContact__c = thisContact.Id;
                    accountsForUpdate.put( thisContact.AccountId, thisAccount );
                  }
                  
                  if ( thisContact.Account.RecordType.DeveloperName != thisContact.RecordType.DeveloperName ) {
                    Id accountRecordTypeId = recordTypesMap.get('Account_'+thisContact.RecordType.DeveloperName);
                    Account thisAccount = (accountsForUpdate.get(thisContact.AccountId) == null)? new Account(id=thisContact.AccountId): accountsForUpdate.get(thisContact.AccountId);
                    //NOTE: purposefully setting the recordtypeid to a non-id value in the next line will cause an exception to be thrown, which condition should be investigated
                    thisAccount.RecordTypeId = (accountRecordTypeId == null)?'RECORD TYPE NOT FOUND ON ACCOUNT FOR NAME ('+thisContact.RecordType.DeveloperName+')': accountRecordTypeId;
                    accountsForUpdate.put( thisContact.AccountId, thisAccount );
                  }
                  
               } //end for loop
                        
                             if ( !accountsForUpdate.isEmpty() ) {
                                    update accountsForUpdate.values();
                             }              
        }
     } //end function processSyncAccountRecordTypeAndPidm
              
//////////////// END SECTION: SYNC STUDENT HASH, ACCOUNT PIDM__c AND ACCOUNT RECORD TYPE TO CONTACT AFTER INSERT OR UPDATE ///////////////// 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
                      
                      

 
//////////////// START SECTION:  SET MENTOR (USER) ID TO CONTACT FROM MENTOR PIDM BEFORE INSERT OR UPDATE ///////////////// 
     //Contact: before Insert and before Update (CANNOT BE ASYNCHRONOUS)
     public static void updateMentorAssignmentTrigger( List<Contact> TriggerNew, Map<Id,RecordType> studentRecordTypes ) {
               
        Set<String> mentorPidms = new Set<String>();
        Map<String,ID> mentorUserMap = new Map<String,ID>();
        Map<String,ID> studentMentorMap = new Map<String,ID>();
        
        //First Run to collect Mentor PIDMs for Matching on User and Mentor__c records by PIDM field values
        for ( Contact firstRunStudent : TriggerNew ) {
        
            if ( firstRunStudent.MentorPidm__c != null && !mentorPidms.contains( firstRunStudent.MentorPidm__c ) ) {
               mentorPidms.add( firstRunStudent.MentorPidm__c );
            }
            
        }
        
        
        if ( !MentorPidms.isEmpty() ) {
        
            //Load up User Map with Mentor Users for PIDM lookups
            for( User mentorUser :[SELECT count() FROM User WHERE PIDM__c IN :MentorPidms]>0? [SELECT Id,PIDM__c FROM User WHERE pidm__c IN :MentorPidms]: new List<User>() ) {
              if ( !mentorUserMap.containsKey( mentorUser.PIDM__c ) ) {
                mentorUserMap.put( mentorUser.PIDM__c, mentorUser.ID );
              }
            }
            
            //Load up Mentor__c Map with Mentors for PIDM lookups
            for ( Mentor__c mentor: [SELECT count() FROM Mentor__c WHERE PIDM__c IN :MentorPidms]>0? [SELECT Id,PIDM__c FROM Mentor__c WHERE pidm__c IN :MentorPidms]: new List<Mentor__c>() ) {
              if ( !studentMentorMap.containsKey( mentor.PIDM__c ) ) {
                studentMentorMap.put( mentor.PIDM__c, mentor.ID );
              }
            }
            
        }
        
        //Loop Triggered Contacts, filtering on Student Records and sync Mentor__c and StudentMentor__c values by PIDM relationship
        for ( Contact student : TriggerNew ){ 
         
                if ( studentRecordTypes.get(student.RecordTypeId) != null ) {
                
                    ID mentorUserID = mentorUserMap.get( student.MentorPidm__c );
                    student.Mentor__c = mentorUserID != null? mentorUserID: student.Mentor__c;
                    
                    ID mentorID = studentMentorMap.get( student.MentorPidm__c );
                    student.StudentMentor__c = mentorID != null? mentorID: student.StudentMentor__c;
                    
                }
                
        }
                                       
   } //END FUNCTION: public static void updateMentorAssignmentTrigger 
//////////////// END SECTION:  SET MENTOR (USER) ID TO CONTACT FROM MENTOR PIDM BEFORE INSERT OR UPDATE ///////////////// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////        
 
//////////////// START SECTION:  SET WGUDEGREEPLAN ID TO CONTACT FROM BANNER PROGRAM CODE BEFORE INSERT OR UPDATE ///////////////// 
   //Contact: before Insert and before Update (CANNOT BE ASYNCHRONOUS)
   public static void updateWGUDegreeProgramTrigger( List<Contact> TriggerNew, Map<Id,RecordType> studentRecordTypes, Map<ID,Contact> TriggerOldMap, boolean isUpdate ) {
        
        List<String> programCodesToProcess = new List<String>();
        
        for ( Contact student : TriggerNew ) {
        
           // Filter out unwanted records
           if ( studentRecordTypes.get(student.RecordTypeId) != null && student.ProgramCode__c != null && student.ProgramCatalogTerm__c != null ) {
        
               //look for null WGUDegreePrograms or records with changes in ProgramCode or ProgramCatalogTerm
               if( student.WGUDegreeProgram__c == null || ( isUpdate && ( student.ProgramCode__c != TriggerOldMap.get(student.id).ProgramCode__c || student.ProgramCatalogTerm__c != TriggerOldMap.get(student.id).ProgramCatalogTerm__c ) ) ) {
                   //need to set WGUDegreeProgram
                   programCodesToProcess.add(student.ProgramCode__c);
               } 
               
            } 
        } // END for (Account a : TriggerNew) 
        
        if( !programCodesToProcess.isEmpty() ) {
            
            Map<String, Id> programReferences = new Map<String, Id>();
            //Gather Degree Program References
            for (WGUDegreeProgram__c program : [SELECT id, name, CatalogTerm__c FROM WGUDegreeProgram__c WHERE name in :programCodesToProcess]) {
                programReferences.put(program.Name + '_' + program.CatalogTerm__c, program.id);
            }      
            
            //process all Triggered Accounts, filtering out unwanted records
            for ( Contact targetStudent : TriggerNew ){
                
                if ( studentRecordTypes.get(targetStudent.RecordTypeId) != null && targetStudent.ProgramCode__c != null && targetStudent.ProgramCatalogTerm__c != null ) {
                 
                  //Set WGUDegreeProgram to correct ID value
                  ID newDegreeReferenceID = programReferences.get( targetStudent.ProgramCode__c + '_' + targetStudent.ProgramCatalogTerm__c ); 
                  targetStudent.WGUDegreeProgram__c = (newDegreeReferenceID != null && targetStudent.WGUDegreeProgram__c != newDegreeReferenceID)? newDegreeReferenceID: targetStudent.WGUDegreeProgram__c;
                  
                }   
            }
            
        } //END if( !programCodesToProcess.isEmpty() ) 
     
   } //END FUNCTION: public static void updateDegreePrgramTrigger
//////////////// END SECTION:  SET WGUDEGREEPLAN ID TO CONTACT FROM BANNER PROGRAM CODE BEFORE INSERT OR UPDATE ///////////////// 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

///////////////////////////// START SECTION: CREATE CONTACT TO BANNER RECORDS AFTER INSERT OR UPDATE ////////////////////////////
    public static void createContactToBanner( String listNewJSON ) 
    {
        if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) 
        {
            processCreateContactToBanner (listNewJSON); 
        } 
        else 
        {
            try
            {
                asyncCreateContactToBanner(listNewJSON);
            }
            catch (Exception e)
            {
                processCreateContactToBanner(listNewJSON);
            }            
        }
    }
     
    @future
    private static void asyncCreateContactToBanner( String listNewJSON ) 
    {
        processCreateContactToBanner(listNewJSON);
    }

    private static void processCreateContactToBanner( String listNewJSON ) 
    {
        List<Contact> contactList = (List<Contact>)JSON.deserialize( listNewJSON, List<Contact>.class );
        List<Id> contactIdList = new List<Id>();
        Map<Id, Id> contactToControlMap = new Map<Id, Id>();
        List<ContactToBanner__c> ctbInsertList = new List<ContactToBanner__c>();
        
        for (Contact thisContact : contactList)
        {
            contactIdList.add(thisContact.Id);
            if (!contactToControlMap.containsKey(thisContact.Id))
            {
                contactToControlMap.put(thisContact.Id, null);
            }
        }
        
        List<ContactToBanner__c> ctbList = [SELECT Id, Contact__c, CurrentStatus__c 
                                            FROM ContactToBanner__c         
                                            WHERE Contact__c IN :contactIdList];
                                            
        for (ContactToBanner__c ctb : ctbList)
        {
            if (contactToControlMap.containsKey(ctb.Contact__c))
            {
                contactToControlMap.put(ctb.Contact__c, ctb.Id);
            }
        }
        
        Id prosRT = [SELECT Id FROM RecordType WHERE SObjectType = 'ContactToBanner__c' AND Name = 'Prospect'].Id;
        
        for (Contact thisContact : contactList)
        {
            if (contactToControlMap.get(thisContact.Id) == null)
            {
                ctbInsertList.add(new ContactToBanner__c(Contact__c = thisContact.Id, RecordTypeId = prosRT));                
            }
        } 
        
        insert ctbInsertList;                                           
    } 
     
////////////////////////////// END SECTION: CREATE CONTACT TO BANNER RECORDS AFTER INSERT OR UPDATE /////////////////////////////           
  
  public static void propagateChangesToUser(List<Contact> updatedContactList, Map<Id, Contact> oldContactMap) {
    try {
      Map<String, Contact> updatedContactMap = new Map<String, Contact>();
      Set<String> contactIdSet = new Set<String>();
      for(Contact c : updatedContactList) {
        Contact oldContact = oldContactMap.get(c.id);
        if(c.WGUEmail__c != oldContact.WGUEmail__c
              || c.FirstName != oldContact.FirstName
              || c.LastName != oldContact.LastName) 
        {
          updatedContactMap.put(c.id, c);
          contactIdSet.add(c.id);
        }
      }

      List<User> userList = [SELECT Id, ContactId, FirstName, LastName, Email FROM User WHERE ContactId = :contactIdSet];
      for(User u : userList) {
        Contact c = updatedContactMap.get(u.ContactId);
        if(u.FirstName != c.FirstName) {
          u.FirstName = c.FirstName;
        }
        if(u.LastName != c.LastName) {
          u.LastName = c.LastName;
        }
        if(u.Email != c.WGUEmail__c) {
          u.Email = c.WGUEmail__c;
        }
      }
      update userList;
    }
    catch(Exception ex) {
      System.debug(ex);
    }
  }
}