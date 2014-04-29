/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date January 28, 2013 @ 1746 hrs
 * Revised: Person Account Refactor 
 * 
 * Date Oct 30 2012 @ 1148 hrs
 * Revised: (security audit compliance: with sharing) 
 *
 * Test the MyFieldExperienceController class (which calls many methods of the StudentFieldExperience class)
 *
 */ 
@isTest()
public with sharing class TestMyFieldExperienceController {
 
  public static testmethod void testMyFieldExperienceControllerAttachments() {
  
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	    
	            
	            MyFieldExperienceController controller = new MyFieldExperienceController();
	            System.assert( controller.getClassroomExperienceExtJSON().contains('No classroom experience') );
	            System.assert( controller.getAbsenceReasonExtJSON().contains('Personal') );
	            System.assert( controller.getAvailableCohortsExtJSON() != null );
	            System.assert( controller.getVerifyPersonalInfoURL().contains( 'http' ) );
	            System.assertEquals( controller.getLt(), '<');
	            System.assertEquals( controller.getGt(), '>' );
	            System.assert( controller.getStatesExtJSON() != null );
	            
	            try {
	                controller.attachFile();
	            } catch (FieldExperienceException fe) {
	                System.assert( fe.getMessage().contains('NULL VALUE ERROR') );
	            }
	            
	            try {
	                controller.attachGeneralFile();
	            } catch (FieldExperienceException fe) {
	                System.assert( fe.getMessage().contains('NULL VALUE ERROR') );
	            }
	            
	            id feid = controller.fieldExperienceId;
	            Blob dataBlob = Blob.valueOf('Test Blob');
	            controller.fileAttachment = dataBlob;
	            controller.fileAttachmentName = 'Test Attachment';
	            controller.fileContentType = 'text/plain';
	            controller.attachFile();
	            
	            feid = controller.fieldExperienceId;
	            dataBlob = Blob.valueOf('Test General Blob');
	            controller.fileAttachment = dataBlob;
	            controller.fileAttachmentName = 'Test General Attachment';
	            controller.fileContentType = 'text/plain';
	            controller.attachGeneralFile();
	            
	            System.assert( MyFieldExperienceController.saveFileAttachment(feid,dataBlob,null,null) == false );
	            
	    }

        Test.stopTest();
  }

  public static testmethod void testStudentFEFieldExperienceSetDTPhaseStatus() {
  
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs(  TestStudentUser.getTestStudentUser() ) {
	
	
	             MyFieldExperienceController.setDTPhaseStatus();
	            
	    }
        Test.stopTest();
  }

   public static testmethod void testStudentFEFieldExperienceMissingKhadijah() {
  
    User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
    System.runAs(  siuser ) {

        Test.startTest();

             System.Assert( MyFieldExperienceController.getStudentFieldExperience() == null );
            
        Test.stopTest();
    }
  }

  public static testmethod void testStudentFEFieldExperienceProperties() {
  
    	TestStudentFieldExperience.setupTestFEData();

        Test.startTest();

	    User studentUser = TestStudentUser.getTestStudentUser();
	
	    MyFieldExperienceController controller = new MyFieldExperienceController();
	
	    System.runAs(  studentUser ) {
	
	
	             String name = controller.FieldExperienceName;
	             String status = controller.FieldExperienceStatus;
	             
	            
	    }
        Test.stopTest();
  }
    
  /*
  public static testmethod void testStudentFEPAbsence() {
  
    Id mentorId = [SELECT Id FROM User WHERE ProfileName__c = 'Mentor' AND isActive=true LIMIT 1].Id;
    TestStudentFieldExperience.setupTestFEData();
    User studentUser =  TestStudentUser.getTestStudentUser();
    User studentIntegrationUser =  [SELECT Id FROM User WHERE IsActive = True AND UserName LIKE 'studentintegration@wgu.edu%' LIMIT 1];
    Contact student = TestStudentUser.getTestStudentContact();
    if ( student.Mentor__c == null ) {
        student.Mentor__c = mentorId;
        update student;
    }
      Id schoolId;
      Id placementAttemptId; 
      FieldExperience__c testFE;
      System.runAs ( studentIntegrationUser ){
          schoolId = [SELECT Id from Account WHERE RecordType.DeveloperName = 'SchoolK12' LIMIT 1].Id;
      }
      System.runAs ( studentUser ){
          StudentFieldExperience sfe = new StudentFieldExperience( student.Id );
          testFE = sfe.getActiveFieldExperience();
          testFE.Mentor__c = mentorId;
          update testFE;
          Id csRequestId = [SELECT Id from RecordType WHERE RecordType.DeveloperName = 'CSRequest' AND SObjectType = 'FieldExperienceProcess__c' LIMIT 1].Id;
          placementAttemptId = [SELECT Id from RecordType WHERE RecordType.DeveloperName = 'PlacementAttempt' AND SObjectType = 'FieldExperienceProcess__c' LIMIT 1].Id;
          insert new FieldExperienceProcess__c(Name='CSRequest',Mentor__c=mentorId,RecordTypeId=csRequestId,CSRequest__c='Confirmed',ClinicalSupervisor__c=student.Id,
                                               Student__c=student.Id,FieldExperience__c=testFE.Id);
      }
      System.runAs ( studentIntegrationUser ){    
          insert new FieldExperienceProcess__c(Name='PlacementAttempt',Mentor__c=mentorId,RecordTypeId=placementAttemptId,School__c=schoolId,PlacementOutcome__c='Accepted',
                                                  HostTeacher__c=student.Id,Student__c=student.Id,FieldExperience__c=testFE.Id);
      }    
      System.runAs ( studentUser ){    
            Test.startTest();

             Id supervisor = MyFieldExperienceController.getCSRequestClinicalSupervisor( testFE.Id );
             System.assert( supervisor == student.Id, 'LOOKUP FAILURE. ClinicalSupervisor Id does not match expected value: expected['+student.Id+'] found['+supervisor+']');
             List<FieldExperienceProcess__c> fepList = MyFieldExperienceController.getFEPlacements( testFE.Id );
             System.assert( !fepList.isEmpty(), 'LOOKUP FAILURE. No Placement Attempt records found.');

             Map<String,String> fepFields = new Map<String,String>();
             fepFields.put('Student__c',student.Id);
             fepFields.put('Name','Absence Test');
             fepFields.put('ClinicalSupervisor__c',student.Id);
             fepFields.put('HostTeacher__c',student.Id);
             fepFields.put('AbsenceDescription__c','Testing');
             fepFields.put('AbsenceReason__c','Personal');
             fepFields.put('FieldExperience__c',testFE.Id);
             fepFields.put('FirstDayAbsent__c','04/01/2014');
             fepFields.put('LastDayAbsent__c','04/01/2014');
             fepFields.put('NumberofDaysAbsent__c','1');
             fepFields.put('Mentor__c',mentorId);
             String fepID = MyFieldExperienceController.addFEPAbsence( JSON.serialize(fepFields) );
             System.assert( fepId != null, 'INSERT FAILURE. Absence record NOT inserted correctly.');
             
             String absencesJSON = MyFieldExperienceController.getRecordedAbsences( testFE.Id );
             System.assert( absencesJSON.contains(fepId), 'QUERY FAILURE. Absence records do NOT contain the newly inserted test record.');
            
            Test.stopTest();
    }
  }
  */
    
  public static testmethod void testStudentFEFieldExperienceWrongDegree() {
  
    TestStudentFieldExperience.setupTestFEData();
    Contact testStudent = TestStudentUser.getTestStudentContact();
    testStudent.ProgramCode__c = 'BASC';
    update testStudent;

        Test.startTest();
        
	    System.runAs(  TestStudentUser.getTestStudentUser() ) {
	
	
	            try {
	               MyFieldExperienceController controller = new MyFieldExperienceController();
	               String feid = controller.fieldExperienceId;
	            } catch (Exception e) {
	              System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER TEST WRONG DEGREE: ' + e.getMessage() );
	            }
	
	            try {
	               MyFieldExperienceController.getFEExtJSON();
	            } catch (Exception e) {
	              System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER TEST WRONG DEGREE: ' + e.getMessage() );
	            }
	
	            try {
	               MyFieldExperienceController.getAllToDoTemplates();
	            } catch (Exception e) {
	              System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER TEST WRONG DEGREE: ' + e.getMessage() );
	            }
	             
	            try {
	               MyFieldExperienceController.getAllToDosAsJSON();
	            } catch (Exception e) {
	              System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER TEST WRONG DEGREE: ' + e.getMessage() );
	            }             
	             
	    }
        Test.stopTest();
  }
    
  public static testmethod void testStudentFEFieldExperienceTooManyActiveFERecords() {
    TestStudentFieldExperience.setupTestFEData();
    Contact student = TestStudentUser.getTestStudentContact();
    
    insert new FieldExperience__c(Name=student.Firstname+' '+student.Lastname ,Active__c=true,Student__c=student.Id);
    insert new FieldExperience__c(Name=student.Firstname+' '+student.Lastname ,Active__c=true,Student__c=student.Id);
    
    User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
    System.runAs(  siuser ) {

        Test.startTest();
		
		    User studentUser =  TestStudentUser.getTestStudentUser();

             try {  
                StudentFieldExperience sfe = new StudentFieldExperience( student.Id );
                sfe.getActiveFieldExperience(); 
             } catch (FieldExperienceException e) {
                System.assert( e.getMessage().startsWith('TOO MANY ACTIVE RECORDS ERROR'), 'Exception does not indicate TOO MANY ACTIVE RECORDS' );
             } 
 
        Test.stopTest();
    }
  }    


  public static testmethod void testStudentFEFieldExperienceGetAllToDo() {
  
    TestStudentFieldExperience.setupTestFEData();
    Contact student = TestStudentUser.getTestStudentContact();
    
     //update SFAW and other tasks to test refetch of Task records
     List<StudentCompletionTask__c> tasks = [select id from StudentCompletionTask__c where Student__c = :student.Id LIMIT 100];
     for( StudentCompletionTask__c task: tasks ) {
       task.RequirementComplete__c = false;
       task.AssessmentStatus__c = 'Not Passed';
     }
     update tasks;
     
    User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
    System.runAs(  siuser ) {

        Test.startTest();
		    User studentUser =  TestStudentUser.getTestStudentUser();

             System.assert( MyFieldExperienceController.getAllToDosAsJSON() != null, 'getAllToDosAsJSON returned NULL string' );
             
             //update SFAW and other tasks to test refetch of Task records
             tasks = [select id from StudentCompletionTask__c where Student__c = :studentUser.ContactId LIMIT 100];
             for( StudentCompletionTask__c task: tasks ) {
               task.RequirementComplete__c = true;
               task.AssessmentStatus__c = 'Passed';
             }
             update tasks;
            
        Test.stopTest();

             System.assert( MyFieldExperienceController.getAllToDosAsJSON() != null, 'getAllToDosAsJSON returned NULL string'  );             
    }
  }    

  public static testmethod void testStudentFEFieldExperienceGetAllToDoMissingTask() {
  
    Id mentorId = [SELECT Id FROM User WHERE ProfileName__c = 'Mentor' AND isActive=true LIMIT 1].Id;
    TestStudentFieldExperience.setupTestFEData();
    Contact testStudent = TestStudentUser.getTestStudentContact();
    if (testStudent.Mentor__c == null ) {
        testStudent.Mentor__c  = mentorId;
        update testStudent;
    }
    
    
    StudentFieldExperience sfe = new StudentFieldExperience( testStudent.Id );
    FieldExperience__c testFE = sfe.getActiveFieldExperience();
    for (Task t : sfe.getStudentFETasks() ) { 
       if ( t.Subject.toUppercase().contains('SFAW') || t.Subject.toUppercase().contains('BASIC SKILLS') ) {
         delete t;
       } 
    } 
     
    User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
    System.runAs(  siuser ) {

        Test.startTest();

            //grabbing code coverage into missing tasks or wrong subject tasks
                    for (Task t : sfe.getStudentFETasks() ) { 
                       if (t.Subject.toUppercase().contains('SFAW') || t.Subject.toUppercase().contains('BASIC SKILLS')) {
                         t.Subject = 'Wrong Subject Name';
                         t.Status = 'Not Started';
                         update t;
                       } 
                    } 
                         
        Test.stopTest();

           System.assert( !sfe.getStudentFETasks().isEmpty(), 'getStudentFETasks() returned an empty Task list'  );                
    }
  }    


  public static testmethod void testStudentFEFieldExperienceTasks() {
  
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs(  TestStudentUser.getTestStudentUser() ) {
	
	
	            String feJSON = MyFieldExperienceController.getFEExtJSON();
	            System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER TEST TASKS FIELD EXPERIENCE JSON: ' + feJSON);    
	            System.assertEquals( MyFieldExperienceController.setToDoComplete( null ), false );
	            
	    }
        Test.stopTest();
  }
    
  public static testmethod void testStudentFEFieldExperienceCompleteTask() {
  
    //ensure proper data setup
    TestStudentFieldExperience.setupTestFEData();
    Contact testStudent = TestStudentUser.getTestStudentContact();
    StudentFieldExperience sfe = new StudentFieldExperience( testStudent.Id );
    
    FieldExperience__c testFE = sfe.getActiveFieldExperience();
    System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER testStudentFEFieldExperienceCompleteTask ActiveFE: ' + JSON.serialize(testFE) );
    
    //get TO DO Template for test Task
    WGUFEToDo__c toDoTemplate = [select Id, Name, SortOrder__c, CardIndex__c, FECheckboxFieldName__c  
                                 FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c 
                                                                from WGUFEToDoByProgram__c 
                                                                where Name =:testStudent.ProgramCode__c ) 
                                                                and isDeleted = false 
                                                                AND FECheckboxFieldName__c = 'LiabilityInsuranceUploaded__c' 
                                                                AND Name LIKE '%Liability Insurance Upload%' LIMIT 1 ];
    System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER testStudentFEFieldExperienceCompleteTask TO DO TEMPLATE: ' + JSON.serialize( toDoTemplate ) );
    
    Task targetTask;
      
        User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
        System.runAs(  siuser ) {
        
            Test.startTest();       
            
                for ( Task t: sfe.getStudentFETasks() ) {
                  if ( t.Subject.equals(toDoTemplate.Name) ) {
                   targetTask = t;
                   System.debug( LoggingLevel.DEBUG, 'FE CONTROLLER testStudentFEFieldExperienceCompleteTask (targetTask variable): ' + JSON.serialize( targetTask ) );
                   break;
                  }
                }
                System.assert( targetTask != null, 'Task for template '+ toDoTemplate.Name + ' NOT FOUND, resulting in the targetTask for completion testing being NULL' );
                System.assert( sfe.setFEToDoComplete( targetTask.id ), 'CALL to StudentFieldExperience.setFEToDoComplete( targetTask.id ) did not return TRUE' );
                
            Test.stopTest();
            
            FieldExperience__c activeFE = [SELECT Id, Active__c, LiabilityInsuranceUploaded__c from FieldExperience__c where Id = :testFE.Id];
            System.assert( activeFE.LiabilityInsuranceUploaded__c == true, 
                           'FieldExperience.LiabilityInsuranceUploaded__c is NOT TRUE after updating the Task record whose Id is ' + targetTask==null? 'NULL': targetTask.id );
        
        }
                
  }
    
    
  public static testmethod void testStudentFEFieldExperienceTemplates() {
  
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	
	        MyFieldExperienceController.getStudentFieldExperience().getActiveFieldExperience();
	
	        
	            System.assert( MyFieldExperienceController.getAllToDoTemplates().contains('CardIndex__c') );
	            
	            AggregateResult[] pgms = [SELECT Name FROM WGUFEToDoByProgram__c group by Name];
	            boolean firstrecord = true;
	            String whereClause = '';
	            for ( AggregateResult pgm : pgms ) {
	                if ( firstrecord ) {
	                    firstrecord = false;
	                    whereClause += '\'' + pgm.get('Name') + '\'';
	                } else {
	                whereClause += ',\'' + pgm.get('Name') + '\'';          
	                }
	            }
	            id controllertactid = [select id from Contact where ProgramCode__c NOT in (:whereClause) LIMIT 1].id;
	            System.assert( controllertactid != null );       
	            
	    }
        Test.stopTest();
  }
      
  public static testmethod void testStudentFEFieldExperienceSearchesSchool() {
   
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	
	        
	            String searchResult = MyFieldExperienceController.findSchool( 'Granger', 'UT' );
	            System.debug('FIND SCHOOL JSON RESULT: ' + searchResult );
	            System.assert( searchResult.contains('SUCCESS') ); 
	        
	    }
        Test.stopTest();
  } 
  
   public static testmethod void testStudentFEFieldExperienceSearchesDistrict() {
    
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	    
	            String searchResult = MyFieldExperienceController.findDistrict( 'Alpine', 'UT' ) ;
	            System.debug('FIND DISTRICT JSON RESULT: ' + searchResult );
	            System.assert( searchResult.contains('SUCCESS') );
	            
	    }
        Test.stopTest();
  }
   
  public static testmethod void testStudentFEFieldExperienceSearchesAssessment() {
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	
	            
	            System.assert( MyFieldExperienceController.isAssessmentComplete( 'SFAW' ) != null );
	            System.assert( MyFieldExperienceController.isAssessmentComplete( 'SFAWASDFASDFASDFA' ) != null );
	            System.assert( MyFieldExperienceController.isAssessmentComplete( 'SFAW,HABR' ) != null );
	            System.assert( MyFieldExperienceController.isAssessmentComplete( 'SFAW HABR' ) != null );
	            System.assert( MyFieldExperienceController.isBasicSkillsAssessmentComplete() != null );
	                        
	    }
        Test.stopTest();
  }
  
  public static testmethod void testStudentFEFieldExperienceGetLicenses() {
    TestStudentFieldExperience.setupTestFEData();

        Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) { 
	            System.assert( MyFieldExperienceController.getStateLicensesJSON( 'UT' ).contains('"type":"TeacherLicense__c"') ); 
	    }
        Test.stopTest();
  }
  
  public static testmethod void testStudentFEFieldExperienceSettersPlacementAttempt() {
  
    Id mentorId = [SELECT Id FROM User WHERE ProfileName__c = 'Mentor' AND isActive=true LIMIT 1].Id;
    TestStudentFieldExperience.setupTestFEData();
    Contact student = TestStudentUser.getTestStudentContact();
    if ( student.Mentor__c == null ) {
        student.Mentor__c = mentorId;
        update student;
    }

    Account school = [SELECT id,Name,County__c,IsWGUPlacementRequired__c,ShippingCity,SchoolDistrict__c 
                      from Account 
                      where  isDeleted = false 
                      AND RecordTypeID in (select id from RecordType where DeveloperName = 'SchoolK12' ) LIMIT 1];
    id schoolid = school.id;
    id districtId  = school.SchoolDistrict__c;
      
    Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	    
	        
	         //     System.assert( MyFieldExperienceController.addFEPlacementAttempt( schoolId, districtId ) != null ); 
	              System.assert( MyFieldExperienceController.getSchoolNamesFromFEProcessDistricts() != null );
	              System.assertEquals( MyFieldExperienceController.addFEPlacementAttempt( null, null ), '' ); 
	              try {
	                 MyFieldExperienceController.getStudentFieldExperience().addFEProcess( null, null, null, false);
	              } catch (FieldExperienceException e) {
	                System.assert( e.getMessage().contains('PLACEMENT ATTEMPT ERROR') );
	              } 
	
	    }
    Test.stopTest();
  } 

  public static testmethod void testStudentFEFieldExperienceSetCustomPlacementAttempt() {
  
    Id mentorId = [SELECT Id FROM User WHERE ProfileName__c = 'Mentor' AND isActive=true LIMIT 1].Id;
    TestStudentFieldExperience.setupTestFEData();
    Contact student = TestStudentUser.getTestStudentContact();
    if ( student.Mentor__c == null ) {
        student.Mentor__c = mentorId;
        update student;
    }

	Test.startTest();
	    System.runAs( TestStudentUser.getTestStudentUser() ) {
	    
	        
	              System.assert( MyFieldExperienceController.addFEPlacementAttemptCustom( 'Test Address 1', 'Test Contact 1', true ) != null ); 
	              System.assert( MyFieldExperienceController.addFEPlacementAttemptCustom( 'Test Address 2', 'Test Contact 2', false ) != null ); 
	              System.assertEquals( MyFieldExperienceController.addFEPlacementAttemptCustom( null, null, true ), ''); 
	              System.assert( MyFieldExperienceController.getSchoolNamesFromFEProcessDistricts() != null );
	
	    }
	Test.stopTest();
  } 
    
  public static testmethod void testStudentFEFieldExperienceGetAllFEProcesses() {
  
    Id mentorId = [SELECT Id FROM User WHERE ProfileName__c = 'Mentor' AND isActive=true LIMIT 1].Id;
    TestStudentFieldExperience.setupTestFEData();
    Contact student = TestStudentUser.getTestStudentContact();
    if ( student.Mentor__c == null ) {
        student.Mentor__c = mentorId;
        update student;
    }

      
        Test.startTest();
		    System.runAs( TestStudentUser.getTestStudentUser() ) {
                
              System.assert( MyFieldExperienceController.addFEPlacementAttemptCustom( 'Test Address', 'Test Contact', true ) != null ); 
              System.assert( MyFieldExperienceController.getAllFEProcesses().contains('Records') );

    		}
        Test.stopTest();
  } 
  
  public static testmethod void testStudentFEFieldExperienceSettersLicense() {
    
    TestStudentFieldExperience.setupTestFEData();

    Test.startTest();
    System.runAs( TestStudentUser.getTestStudentUser() ) {
    
        
            System.assert( MyFieldExperienceController.setLicenseState( 'Utah') );
            System.assert( MyFieldExperienceController.isBasicSkillsAssessmentComplete() != null );
            System.assert( MyFieldExperienceController.setLicenseState( null ) );
            
    }
	Test.stopTest();
  }
  
  public static testmethod void testStudentFEFieldExperienceSettersCohort() {
    
    TestStudentFieldExperience.setupTestFEData();

    Test.startTest();
    System.runAs( TestStudentUser.getTestStudentUser() ) {
    
          List<Cohort__c> cohorts = [SELECT Id, Name from Cohort__c where AvailableForStudents__c = true];                                               
            
         //   System.assert( MyFieldExperienceController.setCohort(cohorts[0].Id) );
        
            id licenseId = [SELECT Id,Name,UtahLicenseTitle__c,UtahReciprocity__c,Version__c,VersionChangeDate__c 
                            FROM TeacherLicense__c where Active__c = true and isDeleted = false AND LicenseStateCode__c = 'UT' LIMIT 1].id;
            System.assert( MyFieldExperienceController.setLicenseGoal( licenseId ) );
            
    }
    Test.stopTest();
  }
   
  public static testmethod void testStudentFEFieldExperienceUpdate() {
    
    TestStudentFieldExperience.setupTestFEData();
    
    Test.startTest();
    System.runAs( TestStudentUser.getTestStudentUser() ) {
    
        
            String feJSON = MyFieldExperienceController.getFEExtJSON();
            System.assert( feJSON.contains('"Id"') );
            id feId;
            String[] items = feJSON.split(',');
            for (String item  : items ) {
                if ( item.contains( '"Id":"') ) {
                   String[] vars = item.split(':');
                   feId = vars[1].split('"')[1];
                   break;
                }
            }
        
            System.assert( MyFieldExperienceController.updateFieldExperience( null ) == false, 'MyFieldExperienceController updateFieldExperience NULL String, did not return FALSE' );
            StudentFieldExperience sfe = new StudentFieldExperience( TestStudentUser.getTestStudentContact().Id );
            FieldExperience__c fes = sfe.getActiveFieldExperience();
            Id contactId = fes.Student__c;
            feJSON = JSON.serialize(fes);
            System.assert( MyFieldExperienceController.updateFieldExperience( feJSON ), 'MyFieldExperienceController updateFieldExperience with valid Object, did not return TRUE' );
            sfe.updateFieldExperience( feJSON );
      
    }
    Test.stopTest();
  }

public static testmethod void testStudentFEWrongDegreeProgram() {
     TestStudentFieldExperience.setupTestFEData();
     
     User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
     System.runAs(  siuser ) {
     
           Test.startTest();  
           
             StudentFieldExperience sfe = new StudentFieldExperience( TestStudentUser.getTestStudentUser().id );
             String code = sfe.getStudentContact().ProgramCode__c;
             update new Contact(id=sfe.getStudentContact().id, ProgramCode__c='BSAC');
             
             try {
               List<Task> tasks = sfe.getStudentFETasks();
             } catch (FieldExperienceException e) {
                  System.assert( e.getMessage().contains('DEGREE PROGRAM NOT PERMITTED'), 'EXCEPTION did not contain DEGREE PROGRAM NOT PERMITTED in testStudentFEWrongDegreeProgram' );
             }
             
             //reset
             update new Contact(id=sfe.getStudentContact().id, ProgramCode__c=code);
             
           Test.stopTest();
     }
   }   
   
   
   public static testmethod void testStudentFEMissingSFAWandBASICSKILLS() {
     TestStudentFieldExperience.setupTestFEData();
     
     User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
     System.runAs(  siuser ) {
     
           Test.startTest(); 
           
             StudentFieldExperience sfe = new StudentFieldExperience( TestStudentUser.getTestStudentUser().id );
             sfe.getActiveFieldExperience().State__c = 'Utah';
             update sfe.getActiveFieldExperience();
             
             List<Task> tasks = sfe.getStudentFETasks();
             for (Task t : tasks) {
               if ( t.Subject.toUppercase().contains('SFAW') || t.Subject.toUppercase().contains('BASIC SKILLS') ) {
                  delete t;
               }
             }
             tasks = sfe.getStudentFETasks();
             
           Test.stopTest();
     }         
   }   
   
   public static testmethod void testStudentFEWrongNameSFAWandBASICSKILLS() {
     TestStudentFieldExperience.setupTestFEData();
     
     User siuser = [Select id from User where username like 'studentintegration@wgu.edu%' AND isActive = true LIMIT 1];
     System.runAs(  siuser ) {
     
         Test.startTest();  
         
             StudentFieldExperience sfe = new StudentFieldExperience( TestStudentUser.getTestStudentUser().id );
             List<Task> tasks = sfe.getStudentFETasks();
             for (Task t : tasks) {
               if ( t.Subject.toUppercase().contains('SFAW') || t.Subject.toUppercase().contains('BASIC SKILLS') ) {
                  t.Subject = 'Incorrect Name';
                  update t;
               }
             }
             tasks = sfe.getStudentFETasks();
             
         Test.stopTest();
     }           
   }   
}