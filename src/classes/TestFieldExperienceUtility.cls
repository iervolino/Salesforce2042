/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 25 2013 @ 2019 hrs
 * Revised: Corrected Mentor Synchronization on FE Record - Paul Coleman
 * 
 * Date Feb 12 2013 @ 1007 hrs
 * Revised: System.isFuture changes in test procedures - Paul Coleman
 *
 * Date January 30 2013 @ 2019 hrs
 * Revised: Person Account Refactor - Paul Coleman
 * 
 * Created Date Aug 16 2012 @ 1654 hrs
 * 
 * Test FieldExperienceUtility class 
 *
 */
@isTest
private without sharing class TestFieldExperienceUtility {
    
  private static testmethod void testSyncFETaskToCheckBoxTrigger() {
  
    TestStudentFieldExperience.setupTestFEData();        
    Contact testStudent = TestStudentUser.getTestStudentContact();
            
    StudentFieldExperience sfe = new StudentFieldExperience(testStudent.Id);
    ID activeFEID = sfe.getActiveFieldExperience().Id;
    FieldExperience__c ActiveFE = [SELECT Id, Active__c, LiabilityInsuranceUploaded__c from FieldExperience__c where Id = :ActiveFEId];
    
    ID studentTaskRecordId = [Select id from RecordType where DeveloperName='StudentTask' and sObjectType = 'Task'].id;
        
    //get TO DO Template to create Task
    WGUFEToDo__c toDoTemplate = [select Id, Name, SortOrder__c, CardIndex__c, FECheckboxFieldName__c  FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:testStudent.ProgramCode__c ) and isDeleted = false AND FECheckboxFieldName__c = 'LiabilityInsuranceUploaded__c' AND Name LIKE '%Liability Insurance Upload%' LIMIT 1 ];
    System.debug( LoggingLevel.DEBUG, 'SYNC CHECKBOX TEST TO DO TEMPLATE: ' + JSON.serialize( toDoTemplate ) );
    
    //create Task from TO DO Template
    Task targetTask = new Task(Whoid=testStudent.Id, WhatId=activeFEID, Subject=toDoTemplate.Name, TemplateId__c=toDoTemplate.Id, TemplateObjectType__c=String.ValueOf(toDoTemplate.getSObjectType()), RecordTypeId=studentTaskRecordId, SortOrder__c=toDoTemplate.SortOrder__c, CardIndex__c=toDoTemplate.CardIndex__c);   
    insert targetTask;    
    System.debug( LoggingLevel.DEBUG, 'SYNC CHECKBOX TEST FIELD EXPERIENCE TASK: ' + JSON.serialize( targetTask ) );
       
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   
        
        Test.startTest();
        
               System.assert( ActiveFE.Active__c, 'NOT ACTIVE ERROR, Test FieldExperience__c record is NOT Active.' );
               System.assert( [SELECT LiabilityInsuranceUploaded__c from FieldExperience__c where id = :ActiveFEid].LiabilityInsuranceUploaded__c == false, 'DEFAULT VALUE ERROR, LiabilityInsuranceUploaded__c assumed to be false on record creation, but is found to be true.' );
               
               Task beforeClosedTask = [SELECT Status, isClosed, WhatId, WhoId, TemplateId__c from Task where ID =:targetTask.Id];
               System.debug( LoggingLevel.DEBUG, 'SYNC CHECKBOX TEST FIELD EXPERIENCE TASK AFTER INSERT, BEFORE CLOSED: ' + JSON.serialize( beforeClosedTask ) );
               
               System.assert( !beforeClosedTask.isClosed, 'BEFORE UPDATE STATE FAILURE, targetTask is assumed to NOT be closed before update, but is already closed.' );
               System.assert( beforeClosedTask.WhatID == ActiveFEid, 'TASK WhatID FAILURE, test Task record is not related to test FieldExperience__c record.' );
               System.assert( beforeClosedTask.TemplateId__c == toDoTemplate.Id, 'TASK TemplateId__c FAILURE, test Task is not related to correct WGUFEToDo__c record.' );
               beforeClosedTask.Status = 'Completed';
               update beforeClosedTask;
               
       Test.stopTest();
        
       Task afterUpdateTask = [SELECT Status, isClosed, WhatId from Task where ID =:beforeClosedTask.Id];
       System.debug( LoggingLevel.DEBUG, 'SYNC CHECKBOX TASK UPDATED: ' + afterUpdateTask );
       System.assert( afterUpdateTask.WhatID == ActiveFEid, '' );
       System.assert( afterUpdateTask.Status == 'Completed', 'TASK completion FAILURE, test Task status is not set to "Completed".' );
       System.assert( afterUpdateTask.isClosed, 'TASK completion FAILURE, test Task.isClosed flag is not set to true.' );
       
       //refresh ActiveFE
       System.assert( [SELECT LiabilityInsuranceUploaded__c from FieldExperience__c where id = :ActiveFEid].LiabilityInsuranceUploaded__c, 'TRIGGER UPDATE FAILURE, LiabilityInsuranceUploaded__c is not set to true after trigger update.');

       List<FieldExperience__c> feList = new List<FieldExperience__c>();
       feList.add( ActiveFE );
       Map<Id,FieldExperience__c> feMap = new Map<Id,FieldExperience__c>();
       feMap.put(ActiveFE.id,ActiveFE);
       //hand off records to future call to force utility to throw System.AsyncException (cannot call future method from within a future method)
       futureCall( JSON.serialize(feList), JSON.serialize(feMap), true ); //Tasks == false
                               

     }
  }

  //TASK object, After Update Trigger
  private static testmethod void testCloseAllFEActiveTasks () {
  
    //ensure proper data setup
    TestStudentFieldExperience.setupTestFEData();
    Contact testStudent = TestStudentUser.getTestStudentContact();
    StudentFieldExperience sfe = new StudentFieldExperience( testStudent.Id );
    
    FieldExperience__c testFE = sfe.getActiveFieldExperience();
    System.debug( LoggingLevel.DEBUG, 'FE TRIGGER testCloseAllFEActiveTasks ActiveFE: ' + JSON.serialize(testFE) );
                          
    User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
    System.runAs(  siuser ) {

        Test.startTest();   
            
            System.debug( LoggingLevel.DEBUG, 'FE TRIGGER testCloseAllFEActiveTasks VALIDATION of FE TASK LIST: ' + JSON.serialize(sfe.getStudentFETasks()) );
            testFE.Active__c = false;
            update testFE;
                
        Test.stopTest();
        
        List<Task> allTasks = sfe.getStudentFETasks();
        for ( Task t: allTasks ) {
            System.assert( t.Status.equals('Deactivated')||t.Status.equals('Completed'), 'FE TRIGGER FAILURE in testCloseAllFEActiveTasks. TASK ('+t.Id+') Status does NOT equal "Deactivated". Found ' + JSON.serialize(t) );
        }
        
        List<FieldExperience__c> feList = new List<FieldExperience__c>();
        feList.add( testFE );
        Map<Id,FieldExperience__c> feMap = new Map<Id,FieldExperience__c>();
        feMap.put(testFE.id,testFE);
        //hand off records to future call to force utility to throw System.AsyncException (cannot call future method from within a future method)
        futureCall( JSON.serialize(feList), JSON.serialize(feMap), false ); //Tasks == false
            
    } //end System.RunAs()
            
  }

  
    //test before update trigger
    private static testmethod void testSyncMentorToFieldExperienceTrigger() {
    
        //ensure proper data setup
        Contact testStudent = TestStudentUser.getTestStudentContact();
        
        Id mentorProfileId = [SELECT id from Profile where name = 'Mentor'].Id;
        Id roleId = [SELECT id from UserRole where DeveloperName = 'Mentor'].Id;
        
       User testUser = TestStudentUser.getSAdminUser();
       System.RunAs( testUser ) {   

            List<User> mentorUserList = new List<User>();
            mentorUserList.add( new User(LastName='Mentor',FirstName='Standard',pidm__c='m21725',Username='m2.test@junk.wgu.edu', Email='m2.test@junk.wgu.edu', Alias='m2', CommunityNickname='mentortest', TimeZoneSidKey='GMT'
            , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', UserRoleId=roleId, isEmployee__c=true) );
            mentorUserList.add( new User(LastName='Mentor2',FirstName='Standard2',pidm__c='m217252',Username='m22.test@junk.wgu.edu', Email='m22.test@junk.wgu.edu', Alias='m22', CommunityNickname='mentortest2', TimeZoneSidKey='GMT'
            , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', UserRoleId=roleId, isEmployee__c=true) );
            insert mentorUserList;        
        
            testStudent.MentorPidm__c=mentorUserList[0].Pidm__c;
            testStudent.Mentor__c=mentorUserList[0].id;
            update testStudent;

            Test.startTest();
            
    
                System.assert([Select Mentor__c from Contact where ID = :testStudent.Id LIMIT 1].Mentor__c == mentorUserList[0].id, 'ID ERROR in testSyncMentorToFieldExperienceTrigger, Mentor__c NOT set properly on Student Contact.');
            
                FieldExperience__c fe = new FieldExperience__c(Student__c=testStudent.Id,Active__c=true);
                insert fe;
                
                fe = [select Id, Student__c, Mentor__c from FieldExperience__c];                
                System.assert( fe.Student__c == testStudent.Id, 'ID ERROR AFTER INSERT, FieldExperience.Student__c does not equal testStudent(Contact).Id');
                System.assert( fe.Mentor__c == testStudent.Mentor__c, 'ID ERROR AFTER INSERT, FieldExperience.Mentor__c does not equal testStudent(Contact).Mentor__c' );

                testStudent.MentorPidm__c=mentorUserList[1].Pidm__c;
                testStudent.Mentor__c=mentorUserList[1].id;
                update testStudent;
                        
                update fe;

                fe = [select Id, Student__c, Mentor__c from FieldExperience__c];                
                System.assert( fe.Student__c == testStudent.Id, 'Student ID ERROR AFTER UPDATE, FieldExperience.Student__c does not equal testStudent(Contact).Id');
                System.assert( fe.Mentor__c == testStudent.Mentor__c, 'ID ERROR AFTER UPDATE, FieldExperience.Mentor__c does not equal testStudent(Contact).Mentor__c' );
    
            Test.stopTest();
                         
       } //END System.RunAs()     
    }
    
    
    @future
    private static void futureCall( String ListNewJSON, String OldMapJSON, boolean isTasks ) {
        
          //grabbing code coverage into future call exception handling blocks
          if ( isTasks ) { 
            try { FieldExperienceUtility.syncFETaskToCheckBox( ListNewJSON, OldMapJSON ); } catch (Exception e) {}
          } else {      
            try { FieldExperienceUtility.closeAllOpenStudentTasks( ListNewJSON, OldMapJSON ); } catch (Exception e) {}
          }
          
    }
    
    private static testmethod void testFutureCallFEWithdrawn() {
      
       User testUser = [Select id from User where Profile.Name = 'Field Experiences User' AND isActive = true LIMIT 1];
       System.RunAs( testUser ) {

        TestStudentFieldExperience.setupTestFEData();
        Contact testStudent = TestStudentUser.getTestStudentContact();
        
        StudentFieldExperience sfe = new StudentFieldExperience(testStudent.Id);
        FieldExperience__c activeFE = sfe.getActiveFieldExperience();
        sfe.addFEProcess('PlacementAttempt', '123 Testing Street', 'Testing Contact', false);
        sfe.addFEProcess('CSRequest', '123 Testing Street', 'Testing Contact', false);
        Map<Id,FieldExperience__c> feTriggerOldMap = new Map<Id,FieldExperience__c>();
        feTriggerOldMap.put( activeFE.Id, activeFE.clone(true) );
        List<FieldExperience__c> feTriggerNew = new List<FieldExperience__c>();
        
                
        
         Test.startTest();
           
                activeFE.AdmissionStatus__c='Withdrawn';
                activeFE.OwnerId = testUser.id;
                update activeFE;
                feTriggerNew.add(activeFE);
                          
         Test.stopTest();
            
            System.assert( [SELECT Active__c FROM FieldExperience__c WHERE Id = :activeFE.id].Active__c == false, 'WITHDRAW TRIGGER ERROR, FieldExperience__c record is still active.');
            
            for ( FieldExperienceProcess__c processObj : [SELECT id,FieldExperience__c,CSRequest__c,PlacementStatus__c,recordtype.DeveloperName FROM FieldExperienceProcess__c WHERE FieldExperience__c IN :feTriggerOldMap.keyset() AND (recordtype.DeveloperName ='CSRequest' OR recordtype.DeveloperName ='PlacementAttempt') ] ) {
                 if ( processObj.RecordType.DeveloperName.equals('PlacementAttempt') ) {
                   System.assert( processObj.PlacementStatus__c==null  , 'WITHDRAW TRIGGER ERROR, PlacementStatus__c is not null after update to "PlacementAttempt" FEProcess record' );
                 } else {
                   System.assert( processObj.CSRequest__c==null  , 'WITHDRAW TRIGGER ERROR, CSRequest__c is not null after update to "CSRequest" FEProcess record' );                   
                 }              
            }
      
            String TriggerNew = JSON.serialize(feTriggerNew);
            String TriggerOldMap = JSON.serialize(feTriggerOldMap);
            //hand off records to future call to force utility to throw System.AsyncException (cannot call future method from within a future method)
            withdrawnFutureCall( TriggerNew, TriggerOldMap ); //Tasks = true
         
       }      
    }

    @future
    private static void withdrawnFutureCall( String TriggerNew, String TriggerOldMap ) {
        
          //grabbing code coverage into future call exception handling blocks
          try { FieldExperienceUtility.doFEWithdraw( TriggerNew, TriggerOldMap ); } catch (Exception e) {}
          
    }
}