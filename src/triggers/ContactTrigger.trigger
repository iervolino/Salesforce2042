/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date Aug 4, 2013 @ 1414 hrs
 * Revised: Added S2S FORWARDING TO STUDENT API ORG - Paul Coleman
 * 
 * 
 * Date Febuary 2, 2013 @ 1600 hrs
 * Revised: Added AFTER INSERT OR UPDATE code block to generate StudentSearchHash__c records and synchronize PIDM & 
 * RecordType.DeveloperName between Contact->Account pairs - Paul Coleman
 * 
 * Date August 13, 2013 @ 1430 hrs
 * Revised: Added AFTER INSERT OR UPDATE: SYNCHRONIZE WITH BANNER code block to generate ContactToBanner__c records for synchronization - Will Slade
 * 
 * Date Sep 20, 2013
 * Revised: Modify account creation and contact--account 2 way association to AFTER INSERT. - Yemeng Zhu 
 *
 * Date March 20, 2014
 * Revised: Added check for when the first name, last name, or email is updated that the change is propagated to the user record
 *
 * Class to capture crud event handlers for the Contact records
 *
 * Date Apr 28, 2014
 * Edit the test case and it nolonger test governer limit of insert 200+ records.
 * Caution: If you made any change on this trigger, make sure test your change by insert/update at least 200 records at one time without hit governer limit.  
 *
 *
 *
 *
 */
trigger ContactTrigger on Contact (after insert, after update, before insert, before update) {


    ////////////////////// CALL TO CONTACT UTILITY CLASS ///////////////////////////////////

    ContactUtility.ContactTrigger(); 

    ///////////////////////////////////////////////////////////////////////////////////////


    //Gather Record Types for student record processing (Contact->Account pairs)
    //TODO: this part will be done 4 times for 4 event, should be able to reduce to 1 time.
    Id studentAccountRecordTypeId;
    Id prospectAccountRecordTypeId;
    Id alumniAccountRecordTypeId;
    Id studentContactRecordTypeId;
    Id prospectContactRecordTypeId;
    Id alumniContactRecordTypeId;
    Map<String,Id> recordTypesMap = new Map<String,Id>();
    Map<Id,RecordType> studentContactRecordTypes = new Map<Id,RecordType>();
    //get Student record types
    for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) 
    {
        recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
        if ( rt.SobjectType == 'Contact' ) {
            studentContactRecordTypes.put( rt.id, rt );
        }
        if ( rt.DeveloperName == 'StudentRecord' ) {
            if (rt.sObjectType == 'Contact') {
                studentContactRecordTypeId = rt.id;
            } else {
                studentAccountRecordTypeId = rt.id;       
            }
        } else if ( rt.DeveloperName == 'ProspectRecord' ) {
            if (rt.sObjectType == 'Contact') {
                prospectContactRecordTypeId = rt.id;
            } else {
                prospectAccountRecordTypeId = rt.id;        
            }
        } else {
            if (rt.sObjectType == 'Contact') {
                alumniContactRecordTypeId = rt.id;
            } else {
                alumniAccountRecordTypeId = rt.id;        
            }

        }
    }

    //9-20-2013 Yemeng  
    //======================================START SECTION: after CONTACT INSERT: Student Records====================================
    //Process BEFORE INSERT Student Contacts, making sure each student type Contact record has an associated Account record (1:1)
    if ( Trigger.isAfter && Trigger.isInsert ) {

        List<Contact> contacts=[select id, FirstName,LastName, RecordTypeid, pidm__c, ispersonAccount__c, Ownerid,WGUCreatedDate__c, mentorpidm__c, mentor__c, accountid from contact where id In :Trigger.new and accountid = null and (RecordTypeid in ( :studentContactRecordTypeId,:alumniContactRecordTypeId,:prospectContactRecordTypeId))];
        if(contacts.size()>0)
        {
            //static variable isInsert, to block the AFTER UPDATE operation in this trigger
            AccountUtility.isInsertContact=true;
            AccountUtility.createAccountsForContacts( contacts); //create a account for each single contact
            AccountUtility.isInsertContact=false;
        } 


        //IMPLICIT COMMIT OF UPDATED CONTACT RECORDS

        //NEXT: update the Account fields (StudentContact__c) in the Contact After Insert Trigger section
    }


    /*
  //9-20-2013 Yemeng : move to after insert.
//======================================START SECTION: BEFORE CONTACT INSERT: Student Records====================================
  //Process BEFORE INSERT Student Contacts, making sure each student type Contact record has an associated Account record (1:1)
  if ( Trigger.isBefore && Trigger.isInsert ) {

     Map<String,Account> accountsForInsert = new Map<String,Account>(); //(pidm, account) map
     Set<Integer> generatedPidms = new Set<Integer>();

     Id sadminId = [select id from user where username like 'sadmin@%wgu.edu%' LIMIT 1].id;
     //FIRST PASS, create Missing Accounts
     for ( Contact student: Trigger.new ) {
        if ( (student.RecordTypeId == prospectContactRecordTypeId || student.RecordTypeId == studentContactRecordTypeId || student.RecordTypeId == alumniContactRecordTypeId) && student.AccountId == null ) {
          //most contacts will be created without a PIDM value, but we can use the field as a temporary value to sync Account->Contact until after both Account and Contact Id values exist
          integer pidm = Crypto.getRandomInteger();
          pidm = pidm<0? pidm*-1: pidm; //ensure a postive value
          while ( generatedPidms.contains(pidm) ) { //ensure unique temporary values for key matching
            pidm = Crypto.getRandomInteger();
            pidm = pidm<0? pidm*-1: pidm; //ensure a postive value
          }
          generatedPidms.add(pidm);
          student.isPersonAccount__c = true;
          student.PIDM__c = student.PIDM__c==null? 'p:dm'+String.ValueOf(pidm): student.PIDM__c; 
          student.OwnerId = sadminId;  //place all new student contact and account records under sadmin ownership 

          //create new Student Account Record
          Account newAccount = new Account(PIDM__c=student.PIDM__c);
          newAccount.RecordTypeId = (student.RecordTypeId==prospectContactRecordTypeId)? prospectAccountRecordTypeId: ((student.RecordTypeId==studentContactRecordTypeId)?studentAccountRecordTypeId:alumniAccountRecordTypeId);
          newAccount.Name = student.FirstName!=null? student.FirstName+' '+student.LastName: student.LastName;
          newAccount.OwnerId = sadminId; 
          newAccount.WGUCreatedDate__c = date.today();
          accountsForInsert.put( student.PIDM__c, newAccount );
        }
     }

     if ( !accountsForInsert.isEmpty() ) {
       insert accountsForInsert.values();
     }

     //ensure accountsForInsert Map has new Account Ids for SECOND PASS
     Set<String> pidms = accountsForInsert.keySet();  //save off pidms for account query
     accountsForInsert = new Map<String,Account>();   //reset account Pidm Map
     boolean runUpdate = false;                       //flag for determining if new Account list needs an update to remove temporary pidms
     for (Account student: [select id,PIDM__c from Account where PIDM__c IN :pidms]) {
        String pidm = student.PIDM__c;
        runUpdate = !runUpdate? student.PIDM__c.startsWith('p:dm'): false;
        student.PIDM__c = student.PIDM__c.startsWith('p:dm')? null: student.PIDM__c; //reset temporary PIDM to null value
        accountsForInsert.put( pidm, new Account(id=student.id,PIDM__c=student.PIDM__c) );
     }
     if (runUpdate){
        update accountsForInsert.values(); //save PIDM adjustments back to Account Records if necessary
     }

     //SECOND PASS, update AccountId fields on Contact with newly created Account Ids, matched by PIDM
     for ( Contact student: Trigger.new ) {
        if ( (student.RecordTypeId == prospectContactRecordTypeId || student.RecordTypeId == studentContactRecordTypeId || student.RecordTypeId == alumniContactRecordTypeId) && student.AccountId == null ) {
            //associate newly created account
            student.AccountId = accountsForInsert.get( student.PIDM__c ).id;
            student.PIDM__c = student.PIDM__c.startsWith('p:dm')? null: student.PIDM__c; //reset temporary PIDM to null value if necessary  
            student.WGUCreatedDate__c = student.WGUCreatedDate__c==null? date.today(): student.WGUCreatedDate__c;          
        }
     }

     //IMPLICIT COMMIT OF UPDATED CONTACT RECORDS

     //NEXT: update the Account fields (StudentContact__c) in the Contact After Insert Trigger section
  }
//============================================END SECTION: BEFORE CONTACT INSERT================================================== 
//================================================================================================================================
     */

    //======================= START SECTION: BEFORE INSERT|UPDATE :STOP BLEEDING====================== 
    //                          STOP BLEEDING: 
    //===============================================================================
    if (Trigger.isBefore &&  (Trigger.isUpdate || Trigger.isInsert) ) {// edit by yemeng
        for ( Contact student: Trigger.new ) {
            if ( student.isInvalid__c ) { //if account is not null but point to other contact
                 student.addError('One account should only associate with one contact, it is invalid to associate the contact of student  '+student.FirstName + ' '+ student.LastName+ ' with the existing account ['+student.Accountid+']');
            }
        }
        
    }

    //======================= START SECTION: BEFORE INSERT|UPDATE MENTOR PIDM AND DEGREE PROGRAM SYNC ====================== 
    if (Trigger.isBefore && (Trigger.isInsert || (Trigger.isUpdate &&!AccountUtility.isInsertContact)) ) {// edit by yemeng
        boolean isTargetRecordFound = false;
        //Update Mentor Assignments
        for ( Contact student: Trigger.new ) {
            if ( studentContactRecordTypes.get(student.RecordTypeId) != null && student.MentorPIDM__c != null ) {
                isTargetRecordFound = true;
                break;
            }
        }
        if (isTargetRecordFound) {
            ContactUtility.updateMentorAssignmentTrigger( Trigger.new, studentContactRecordTypes );
        }           

        isTargetRecordFound = false;
        //Update WGUDegreeProgram ID
        for ( Contact student: Trigger.new ) {
            //search for target record context, else ignore
            if ( studentContactRecordTypes.get(student.RecordTypeId) != null && student.ProgramCode__c != null && student.ProgramCatalogTerm__c != null ) {
                isTargetRecordFound = true;
                break;
            }
        }
        if (isTargetRecordFound) {
            ContactUtility.updateWGUDegreeProgramTrigger( Trigger.new , studentContactRecordTypes, (Trigger.isUpdate? Trigger.oldMap: new Map<ID,Contact>()), Trigger.isUpdate );
        }

    } 
    //======================= END SECTION: BEFORE INSERT|UPDATE MENTOR PIDM AND DEGREE PROGRAM SYNC ====================== 
    //======================================================================================================================

    /*
   //9-20-2013 Yemeng : move to after insert.
//===========================START SECTION: AFTER CONTACT INSERT: CONTACT->ACCOUNT PAIRING FOR STUDENT RECORDS=================== 
  if ( Trigger.isAfter && Trigger.isInsert ) {

    if ( [select count() from Contact where id IN :Trigger.new AND RecordTypeId IN (:studentContactRecordTypeId,:prospectContactRecordTypeId,:alumniContactRecordTypeId)] > 0 ) {
      //gather student Accounts for existing account search
      Set<Id> studentAccountIds = new Set<Id>();
      for ( Contact student: Trigger.new ) {
         if ( (student.RecordTypeId == prospectContactRecordTypeId || student.RecordTypeId == studentContactRecordTypeId || student.RecordTypeId == alumniContactRecordTypeId) ) {
            studentAccountIds.add( student.AccountId );
         }               
      }

      if ( [select count() from Account where RecordTypeId IN (:studentAccountRecordTypeId,:prospectAccountRecordTypeId,:alumniAccountRecordTypeId) AND Id IN :studentAccountIds AND StudentContact__c = null] > 0 ) {
         //found Accounts with missing Contact Id values using AccountIds from the Trigger.new array
         ContactUtility.syncStudentAccountRecordTrigger( Trigger.new );
      }
    }
  }
//===========================END SECTION: AFTER CONTACT INSERT: CONTACT->ACCOUNT PAIRING FOR STUDENT RECORDS===================== 
//===============================================================================================================================
     */



    //================================START SECTION: AFTER CONTACT UPDATE: S2S FORWARDING TO STUDENT API ORG======================== 
    //PUSH StudentAPI Shares for Students
    if ( Trigger.isAfter && (Trigger.isUpdate &&!AccountUtility.isInsertContact) ) {// edit by yemeng

        ContactUtility.forwardContactRecords( JSON.serialize(Trigger.new) );

    } 
    //================================END SECTION: AFTER CONTACT UPDATE: S2S FORWARDING TO STUDENT API ORG=========================== 
    //===============================================================================================================================

    //============================= START SECTION: AFTER INSERT|UPDATE: SYNCHRONIZE CONTACT WITH BANNER ============================= 
    if (Trigger.isAfter && (Trigger.isInsert ||(Trigger.isUpdate &&!AccountUtility.isInsertContact)))
    {
        // Function testing in TestContactUtility, should not run during unit test. Prevents ability to probperly unit test 
        // ContactToBanner__c related code because of an out standing future method that may not be resolved in the correct order.
        if (!Test.isRunningTest())
        {
            List<Contact> contactList = [SELECT Id FROM Contact WHERE Id IN :Trigger.new AND RecordType.DeveloperName IN ('StudentRecord', 'ProspectRecord', 'AlumniRecord')];

            if (contactList.size() > 0)
            {
                ContactUtility.createContactToBanner(JSON.serialize(contactList));
            }
        }
    }

    //============================== END SECTION: AFTER INSERT|UPDATE: SYNCHRONIZE CONTACT WITH BANNER ==============================
    
    
    //============================= START SECTION: AFTER INSERT|UPDATE: Refresh Data from Banner ============================= 
    if (Trigger.isAfter && (Trigger.isInsert ||(Trigger.isUpdate && !AccountUtility.isInsertContact)))
    {  
        // Function testing in TestContactUtility, should not run during unit test. Prevents ability to probperly unit test 
        // ContactToBanner__c related code because of an out standing future method that may not be resolved in the correct order.
        if (!Test.isRunningTest())
        {
            List<Contact> contactList = [SELECT Id, Pidm__c
                                         FROM Contact 
                                         WHERE Id IN :Trigger.new
                                         AND Pidm__c != null
                                         AND RequestRefreshFromBanner__c = true];

            if (contactList.size() > 0)
            {           
                ContactToBannerUtilities.resyncToSalesforce(JSON.serialize(contactList));
            }
        }
    }

    //============================== END SECTION: AFTER INSERT|UPDATE: Refresh Data from Banner ==============================    
    
    //===============================================================================================================================

    //If the student changes degree or status, we need to udpate their Course Community groups
    if(Trigger.isAfter && Trigger.isUpdate) {
        List<Contact> updatedDegreeList = new List<Contact>();
        List<Contact> updatedStatusList = new List<Contact>();
        for(Contact c : Trigger.new) {
            if(c.WGUDegreeProgram__c != null && Trigger.oldMap.get(c.id).WGUDegreeProgram__c != null 
               && c.WGUDegreeProgram__c != Trigger.oldMap.get(c.id).WGUDegreeProgram__c) 
            {
                updatedDegreeList.add(c);
            }
            
            if(c.Status__c != null &&
               c.Status__c != Trigger.oldMap.get(c.id).Status__c
                && (c.Status__c.equals('AS')
                    || c.Status__c.equals('DR')
                    || c.Status__c.equals('DD')
                    || c.Status__c.equals('WI')
                    || c.Status__c.equals('TB'))) 
            {
                updatedStatusList.add(c);
            }
        }
        
        if(!updatedDegreeList.isEmpty()) {
            CourseCommunitiesDegreeChangeUtil util = new CourseCommunitiesDegreeChangeUtil();
            util.updateCourseCommunitiesForNewDegree(updatedDegreeList);
            StudentCourseVersionUtility.checkValidCourses(JSON.serialize(updatedDegreeList));
        }
        
        if(!updatedStatusList.isEmpty()) {
            ContactStatusCourseCommunitySync sync = new ContactStatusCourseCommunitySync();
            sync.processCourseCommunityGroupChanges(updatedStatusList);
        }
    }
    
    //========== Remove Line feed and Carriage return characters for data storage START ==========
    if(Trigger.isBefore &&(Trigger.isInsert||Trigger.isUpdate)){
        for(integer i=0; i<Trigger.new.size(); i++){
            if(Trigger.new[i].MailingStreet != null){
                Trigger.new[i].MailingStreet = Trigger.new[i].MailingStreet.replace('\r','');
                Trigger.new[i].MailingStreet = Trigger.new[i].MailingStreet.replace('\n',' ');
            }
        }
    }
    //========== Remove Line feed and Carriage return characters for data storage END  ==========

    if(Trigger.isBefore && Trigger.isUpdate) {
        List<RecordType> recordTypeList = [SELECT Id FROM RecordType WHERE Name IN ('AlumniRecord', 'ProspectRecord', 'StudentRecord') AND sObjectType = 'Contact'];
        Set<String> recordTypeIdSet = new Set<String>();
        for(RecordType r : recordTypeList) {
            recordTypeIdSet.add(r.id);
        }
        for(Contact c : Trigger.new) {
            if(c.pidm__c == null 
               || !recordTypeIdSet.contains(c.recordTypeId)) 
            {
                continue;
            }
            
            Contact oldContact = Trigger.oldMap.get(c.id);
            if(c.Status__c != oldContact.Status__c
              || c.Cleared_Status__c != oldContact.Cleared_Status__c
              || c.MiddleInitial__c != oldContact.MiddleInitial__c
              || c.IsNSE__c != oldContact.IsNSE__c
              || c.College__c != oldContact.College__c
              || c.Gender__c != oldContact.Gender__c
              || c.CampusCode__c != oldContact.CampusCode__c
              || c.RecordTypeId != oldContact.RecordTypeId
              || c.WGUEmail__c != oldContact.WGUEmail__c
              || c.FirstName != oldContact.FirstName
              || c.LastName != oldContact.LastName) 
            {
                c.IDMRequiresUpdate__c = true;
            }
        }
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
      ContactUtility.propagateChangesToUser(Trigger.new, Trigger.oldMap);
    }
    
    //==========================================================================================================================================
    //THE CODE BLOCK BELOW SHOULD PROBABLY ALWAYS GO LAST IN THE CONTACT TRIGGER
    //=========================START SECTION:  AFTER CONTACT INSERT OR UPDATE STUDENTSEARCHHASH AND ACCOUNT RECORD TYPE CONGURENCE============== 
    if ( Trigger.isAfter && (Trigger.isInsert || (Trigger.isUpdate &&!AccountUtility.isInsertContact) ) ) {

        String recordTypesMapJSON = JSON.serialize(recordTypesMap);
        String triggerNewJSON = JSON.serialize(trigger.new);

        //loop all triggered Contact records to be sure all contacts have an up-to-date StudentSearchHash__c record
        ContactUtility.syncStudentSearchHash( triggerNewJSON, recordTypesMapJSON, trigger.isUpdate );

        if ( trigger.isUpdate  && !AccountUtility.isInsertContact ) {// edit by yemeng
            //modify at 9/27/2013 do not run this when it is insertion.
            //loop all triggered Contact records and verify PIDM and RecordType.DeveloperName congruence on paired Contact and Account records
            ContactUtility.syncAccountRecordTypeAndPidm( triggerNewJSON, recordTypesMapJSON );

            //if the status value(s) of the triggered Contact records (students) necessitate a Customer User record, ensure one exists
            if ( [SELECT count() FROM Contact WHERE Id IN :trigger.new AND (Status__c in ('AS','TB' ) OR ( Status__c='IN' AND OtherEmail__c != null )) AND AccountID != null AND Account.isCustomerPortal = false AND PIDM__c != null AND RecordTypeId IN (:studentContactRecordTypeId,:prospectContactRecordTypeId,:alumniContactRecordTypeId)] > 0  ) {
                ContactUtility.createStudentsCustomerUserRecords( triggerNewJSON, recordTypesMapJSON );
            }
        }
    }
    //============================================END SECTION: AFTER CONTACT INSERT OR UPDATE================================================== 
    //=========================================================================================================================================
    //PLACE ANY OTHER CONTACT TRIGGER CODE BLOCKS ABOVE THIS BLOCK
}