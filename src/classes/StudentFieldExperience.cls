/* 
 * Author Paul Coleman
 * Western Governors University
 *
 * Date June 1, 2013 @ 1511 hrs
 * Revised: modified getStudentFETasks(), changing all calls to RestAdapter.queryObjects() to RestAdapter.queryAllObjects() so archived Tasks will show up in all resultsets
 * 
 * Date January 28, 2013 @ 1447 hrs
 * Revised: Person Account Refactor 
 * 
 * Created Date Oct 30, 2012 @ 1130 hrs
 * 
 * Class to support the Student process of Field Experience in support of the MyFieldExperience page and controller
 *
 */
public virtual with sharing class StudentFieldExperience extends StudentUser {
    
    private FieldExperience__c activeFE;  
    
    public StudentFieldExperience(ID sfID) { 
      super(sfID); 
    }
    
    public virtual boolean updateFieldExperience( String feJSON ) {
        if (feJSON != null) {
            FieldExperience__c fe = (FieldExperience__c)JSON.deserialize( feJSON, FieldExperience__c.class );
            FieldExperience__c updateFe = this.getActiveFieldExperience();
            if ( fe.id == updateFe.id ) {  //test for injection
                updateFe.State__c = fe.State__c; 
                updateFe.TeacherLicense__c = fe.TeacherLicense__c; 
                updateFe.Cohort__c = fe.Cohort__c;
                updateFe.SameSchoolasPCE__c = fe.SameSchoolasPCE__c;
                updateFe.NotPCEReason__c = fe.NotPCEReason__c;
                updateFe.ClassroomExperience__c = fe.ClassroomExperience__c;
                updateFe.WorkinSameDistrictasPlacement__c = fe.WorkinSameDistrictasPlacement__c;
                updateFe.DistrictNameStudentWorksIn__c = fe.DistrictNameStudentWorksIn__c;
                updateFe.RelativesinDistrict__c = fe.RelativesinDistrict__c;
                updateFe.DistrictNameRelativeWorksIn__c = fe.DistrictNameRelativeWorksIn__c;
                updateFe.ChildreninDistrict__c = fe.ChildreninDistrict__c;
                updateFe.DistrictNameChildrenAreIn__c = fe.DistrictNameChildrenAreIn__c;
                updateFe.SchoolNameChildrenAreIn__c = fe.SchoolNameChildrenAreIn__c;
                updateFe.DODStudent__c = fe.DODStudent__c;
                update updateFe;
            }
        } else {
            throw new StudentFieldExperienceException('NULL VALUE ERROR: Attempt to update empty FieldExperience__c object on StudentFieldExperience.updateFieldExperience().');
        }
        return true;
    }
 
    public virtual String getActiveFieldExperienceExtJSON() {
        return JSONUtil.getJSON(getActiveFieldExperience());
    }
    
    public virtual FieldExperience__c getActiveFieldExperience() {
      if ( this.activeFE == null ) {
              Contact student = getStudentContact();
              List<FieldExperience__c> feRecords = [select ID, State__c, StudentsPIDM__c,TeacherLicense__c,Cohort__c,Cohort__r.Name,SameSchoolasPCE__c,NotPCEReason__c,ClassroomExperience__c,WorkinSameDistrictasPlacement__c,DistrictNameStudentWorksIn__c,RelativesinDistrict__c,DistrictNameRelativeWorksIn__c,ChildreninDistrict__c,DistrictNameChildrenAreIn__c,SchoolNameChildrenAreIn__c,DODStudent__c,Student__c,Mentor__c,Student__r.Name,PCEPhaseStatus__c,DTPhaseStatus__c,AdmissionStatus__c from FieldExperience__c WHERE Student__c = :student.Id and Active__c = true and isDeleted = false];
                  if ( feRecords.size() > 1 ) {
                      throw new FieldExperienceException('TOO MANY ACTIVE RECORDS ERROR: Student has more than one active FieldExperience Record in StudentFieldExperience.getActiveFieldExperience()');
                  } else if ( feRecords.size() == 1 ) {
                      this.activeFE = feRecords[0];
                  } else {
                      //before creating the new Field Experience Record, see if the student's degree is configured in WGUFEToDo__c, no sense creating the record if no tasks can follow
                      if ( [select count() FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:student.ProgramCode__c ) and isDeleted = false] == 0 ) {
                         throw new FieldExperienceException('DEGREE PROGRAM NOT PERMITTED: Your degree ('+student.ProgramCode__c+') is not authorized for the Field Experience Application');
                      } else {
                         this.activeFE = new FieldExperience__c(Name=student.Firstname+' '+student.Lastname ,Active__c=true,Student__c=student.Id,Mentor__c=student.Mentor__c);
                         insert this.activeFE;
                      }
                  }
      }
      return this.activeFE;
    }
     
    private void createStudentFETasks(ID contactId, String programCode, ID feId) {
          //GET Task Templates
          List<WGUFEToDo__c> toDos = [select count() FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:programCode ) and isDeleted = false] > 0? [select Id, Name, SortOrder__c, CardIndex__c FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:programCode ) and isDeleted = false order by SortOrder__c ASC ]: new List<WGUFEToDo__c>();  
          if ( !toDos.isEmpty() ) {
                  Set<String> completedAssessments = new Set<String>(); 
                  if ( [SELECT count() FROM StudentCompletionTask__c where Student__c = :contactId AND isDeleted = false AND Name IN ('SFAW') and RequirementComplete__c=true] > 0 ) {
                    for ( StudentCompletionTask__c sTask :[SELECT Name FROM StudentCompletionTask__c where Student__c = :contactId AND isDeleted = false AND Name IN ('SFAW') and RequirementComplete__c=true] ) {
                        completedAssessments.add( sTask.Name );            
                    }
                  }
                  
                  List<Task> feTasks = new List<Task>();
                  //Create new Student Tasks on FieldExperience__c record
                  ID studentTaskRecordId = [Select id from RecordType where DeveloperName='StudentTask' and sObjectType = 'Task'].id;
                  for (WGUFEToDo__c todo: toDos ) {
                    //if SFAW assessments are already complete, create the To Do task items in the Completed status
                    if ( todo.Name.toUpperCase().contains('SFAW') ) {
                        if ( completedAssessments.contains('SFAW') ) {
                          feTasks.add( new Task(Status='Completed',Whoid=contactId,WhatId=feId,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) );
                        } else {
                          feTasks.add( new Task(Whoid=contactId,WhatId=feId,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) );                   
                        }
                    } else {
                      feTasks.add( new Task(Whoid=contactId,WhatId=feId,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) );
                    }   
                  }
                  //use RestAdapter to bypass license restriction on customer accounts creating tasks
                  String responseXML = '';
                  if (!Test.isRunningTest() && adapter != null ) {
                    responseXML = adapter.createObjects( feTasks ); //createObjectS() uses the SOAP API to create multiple objects in one transaction, The REST API only supports creating one record at a time 
                  } else {
                    System.debug(LoggingLevel.DEBUG,'TEST MODE DETECTED');
                    insert feTasks;
                  }
                  if ( responseXML.contains( '<success>false</success>' ) ) {
                    System.debug( LoggingLevel.ERROR, 'FieldExperience__c Task Creation Failure: ' + EncodingUtil.urlEncode(responseXML,'UTF-8') );
                  }
          }
    }
    
    public virtual String getStudentFETasksExtJSON() {
        return JSONUtil.getJSON( getStudentFETasks() );
    }
    
    private void createMissingFETasks( List<Task> tasksForInsert ) {
          System.debug( LoggingLevel.DEBUG, 'INSERTING MISSING TASK LIST ITEMS for ' + String.ValueOf( tasksForInsert.size() ) + ' tasks' );
          Id studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
          if ( !Test.isRunningTest() && adapter != null ) {
            //use RestAdapter to bypass license restriction on customer accounts creating tasks
            String responseXML = adapter.createObjects( tasksForInsert ); 
            if ( responseXML.contains( '<success>false</success>' ) ) {
                System.debug( LoggingLevel.ERROR, 'FieldExperience__c Task Creation Failure: ' + EncodingUtil.urlEncode(responseXML,'UTF-8') );
            }
          } else {
            System.debug(LoggingLevel.DEBUG,'TEST MODE DETECTED');
            insert tasksForInsert;
          }
    }
    
    private void syncFETaskUpdates( List<Task> tasksForUpdate ) {
          System.debug( LoggingLevel.DEBUG, 'UPDATING TASK LIST ITEMS for ' + String.ValueOf( tasksForUpdate.size() ) + ' tasks' );
          Id studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
          if ( !Test.isRunningTest() && adapter != null ) {
            //use RestAdapter to bypass license restriction on customer accounts creating tasks
            String responseXML = adapter.updateObjects( tasksForUpdate ); 
            if ( responseXML.contains( '<success>false</success>' ) ) {
                System.debug( LoggingLevel.ERROR, 'FieldExperience__c Task Update Failure: ' + EncodingUtil.urlEncode(responseXML,'UTF-8') );
            }
          } else {
            System.debug(LoggingLevel.DEBUG,'TEST MODE DETECTED');
            update tasksForUpdate;
          }                
    }

    
    public virtual List<Task> getStudentFETasks() {
       Boolean tasksCreated = false;
       String queryString = 'SELECT Id, WhatId, Subject, IsClosed, TemplateId__c, CardIndex__c, SortOrder__c, Status, isArchived FROM Task where Whatid=\''+getActiveFieldExperience().Id+'\' AND TemplateId__c != null AND isDeleted = false ORDER BY SortOrder__c ASC LIMIT 100';
       List<Task> tasks = (!Test.isRunningTest() && adapter != null)? (List<Task>)adapter.queryAllObjects( queryString ): (List<Task>)Database.query( queryString + ' ALL ROWS ' );
        
       if ( tasks == null || tasks.isEmpty() ) {
            tasksCreated  = true;
            System.debug( LoggingLevel.DEBUG, 'FE TASKS CREATED');
            Contact student = getStudentContact();
            createStudentFETasks( student.Id, student.ProgramCode__c, getActiveFieldExperience().Id );
            tasks = ( !Test.isRunningTest() && adapter != null )? (List<Task>)(adapter.queryAllObjects( queryString )): (List<Task>)Database.query( queryString + ' ALL ROWS ' ); 
       }
       
       //if the FE tasks were just created, no need to verify template synchronization, else, ensure template-to-task data equality
       if ( !tasksCreated ) {
          System.debug( LoggingLevel.DEBUG, 'FE TASKS NOT CREATED, SYNCHRONIZING TASKS TO TEMPLATES');

         //create an assessment map for task items to be auto completed if assessments are already done
         Map<String,Boolean> assessmentMap = new Map<String,Boolean>();
         assessmentMap.put('SFAW', isAssessmentComplete( 'SFAW' ) );
         
         if ( getActiveFieldExperience().State__c != null ) {
           String stateAbbr = [SELECT NAME from States__c where StateFullName__c = :getActiveFieldExperience().State__c LIMIT 1].Name;
           String skillCodes = States__c.getValues(stateAbbr)!=null? States__c.getValues(stateAbbr).EducatorBasicSkillsCodes__c: null;
           assessmentMap.put('BASIC SKILLS', skillCodes != null? isAssessmentComplete( skillCodes ) : false );
         } else {
           assessmentMap.put('BASIC SKILLS', false );
         }
         
            //Gather existing template ids from tasks to match them against the current list of to do templates, fetched next
            Set<Id> templateIds = new Set<Id>();
            for ( Task t: tasks ) {
              if ( !templateIds.contains( t.templateId__c ) ) {
                templateIds.add( (Id)t.templateId__c );
              }
            }
            
            Boolean refreshList = false;  //if changes are needed, the tasks array will need to be refreshed before returning them from this function
            if ( [select count() FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:getStudentContact().ProgramCode__c ) and isDeleted = false] > 0 ) { 
                //get the current to do template records
                Map<Id,WGUFEToDo__c> toDos = new Map<Id,WGUFEToDo__c>([select Id, Name, SortOrder__c, CardIndex__c FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:getStudentContact().ProgramCode__c ) and isDeleted = false order by SortOrder__c ASC ]);
                
                //verify all ToDo templates have a corresponding task, say, in case of accidental deletion or new template additions
                if ( toDos.size() > tasks.size() ) {  //generic check, avoiding too frequent verification, if more template records than tasks, tasks items are missing
                System.debug( LoggingLevel.DEBUG, 'FE TASKS COUNT IS LESS THAN TEMPLATE COUNT');
                  List<Task> tasksForInsert = new List<Task>();
                  ID studentTaskRecordId = [Select id from RecordType where DeveloperName='StudentTask' and sObjectType = 'Task'].id;
                  for ( WGUFEToDo__c todo: toDos.values() ) {
                    if ( !templateIds.contains( todo.id ) ) {
                      System.debug( LoggingLevel.DEBUG, 'FE TASK FOUND TO BE MISSING: ' + todo.Name);
                      //check to see if the task is an assessment that is already completed
                      if ( todo.Name.toUpperCase().contains('SFAW') ) {
                         tasksForInsert.add( ( assessmentMap.containsKey('SFAW') && assessmentMap.get('SFAW')==true )? new Task(Status='Completed',Whoid=getStudentContact().Id,WhatId=getActiveFieldExperience().Id,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) : new Task(Whoid=getStudentContact().Id,WhatId=getActiveFieldExperience().Id,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) );   
                      } else if ( todo.Name.toUpperCase().contains('BASIC SKILLS') ) {
                        tasksForInsert.add( ( assessmentMap.containsKey('BASIC SKILLS') && assessmentMap.get('BASIC SKILLS')==true )? new Task(Status='Completed',Whoid=getStudentContact().Id,WhatId=getActiveFieldExperience().Id,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) : new Task(Whoid=getStudentContact().Id,WhatId=getActiveFieldExperience().Id,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) );   
                      } else {
                        tasksForInsert.add( new Task(Whoid=getStudentContact().Id,WhatId=getActiveFieldExperience().Id,Subject=todo.Name,TemplateId__c=todo.Id,TemplateObjectType__c='WGUFEToDo__c',RecordTypeId=studentTaskRecordId,SortOrder__c=todo.SortOrder__c,CardIndex__c=todo.CardIndex__c) );   
                      }
                    }
                  }
                  if ( tasksForInsert.size() > 0 ) {
                    System.debug( LoggingLevel.DEBUG, 'ABOUT TO CREATE TASKS: ' + JSON.serialize(tasksForInsert) );
                    createMissingFETasks( tasksForInsert );
                    refreshList = true;
                  }
               } 
               
               //verify ToDo template and task sync by Name, SortOrder__c and CardIndex__c
               List<Task> tasksForUpdate = new List<Task>();
               for ( Task t: tasks ) {
                 if ( toDos.containsKey( t.templateId__c ) ) {
                   WGUFEToDo__c todo = toDos.get( t.templateId__c ) ;
                   if ( t.SortOrder__c != todo.SortOrder__c || t.CardIndex__c != todo.CardIndex__c  || t.Subject != todo.Name ) {
                    System.debug( LoggingLevel.DEBUG, 'FE TASK FOUND TO BE OUT OF SYNC: todo=' + JSON.serialize(todo) + '  task='+JSON.serialize(t) );
                    Task newTask = new Task(id=t.id);
                      newTask.SortOrder__c = todo.SortOrder__c;
                      newTask.CardIndex__c = todo.CardIndex__c; 
                      newTask.Subject = todo.Name;
                      //Adjust task status if necessary 
                      newTask.Status = todo.Name.toUpperCase().contains('SFAW')? ( ( assessmentMap.containsKey('SFAW') && assessmentMap.get('SFAW')==true && !t.isClosed )?'Completed': t.Status ) : ( todo.Name.toUpperCase().contains('BASIC SKILLS')? ( ( assessmentMap.containsKey('BASIC SKILLS') && assessmentMap.get('BASIC SKILLS')==true && !t.isClosed )? 'Completed': t.Status ) : t.Status );
                      tasksForUpdate.add( newTask );
                   } else {
                     //verify assessment tasks statuses
                      if ( ( todo.Name.toUpperCase().contains('SFAW') && ( assessmentMap.containsKey('SFAW') && assessmentMap.get('SFAW')==true && !t.isClosed ) ) || ( todo.Name.toUpperCase().contains('BASIC SKILLS') && ( assessmentMap.containsKey('BASIC SKILLS') && assessmentMap.get('BASIC SKILLS')==true && !t.isClosed ) ) ) {
                          tasksForUpdate.add( new Task(id=t.id, Status='Completed') );
                      } 
                   }             
                 } 
               }
              if ( tasksForUpdate.size() > 0 ) {
                System.debug( LoggingLevel.DEBUG, 'ABOUT TO RESYNCHRONIZE TASKS: ' + JSON.serialize(tasksForUpdate) );
                syncFETaskUpdates( tasksForUpdate );
                refreshList = true;             
              }           
            }
            if ( refreshList ) {
                   System.debug( LoggingLevel.DEBUG, 'REFRESHING TASKLIST' );
                   tasks = (!Test.isRunningTest() && adapter != null)? (List<Task>)adapter.queryAllObjects( queryString ): (List<Task>)Database.query( queryString + ' ALL ROWS ' ); 
            }
       }
       return tasks;
    }

    public virtual String getAllFEProcessesExtJSON() {
       return JSONUtil.getJSON( getAllFEProcesses() );
    }
    
    public virtual List<FieldExperienceProcess__c> getAllFEProcesses() {
       return [SELECT ID,Name,District__c, District__r.Name,District__r.ShippingCity, School__c, School__r.Name,School__r.ShippingCity,NewSchool__c,NewDistrict__c,NewSchoolContact__c,NewDistrictContact__c,PreferredPriority__c from FieldExperienceProcess__c where FieldExperience__c = :getActiveFieldExperience().id AND RecordType.DeveloperName = 'PlacementAttempt' AND isDeleted = false ORDER BY PreferredPriority__c ASC LIMIT 100];
    }
    
    public virtual String addFEProcess(String recordTypeName, String address, String contact, Boolean isDistrict ) {
        FieldExperienceProcess__c placementAttempt = new FieldExperienceProcess__c();
        FieldExperience__c ParentFe = getActiveFieldExperience();
        Id thisRecordTypeId = ( recordTypeName == null )? [SELECT ID from RecordType where DeveloperName = 'PlacementAttempt' and SObjectType = 'FieldExperienceProcess__c' LIMIT 1].id : [SELECT ID from RecordType where DeveloperName = :recordTypeName and SObjectType = 'FieldExperienceProcess__c' LIMIT 1].id;

        if ( address == null && contact == null ) {
          throw new FieldExperienceException('PLACEMENT ATTEMPT ERROR: either an address or contact information must be supplied to create a Placement Attempt in StudentFieldExperience.addFEProcess()');
        }
        
        placementAttempt.PreferredPriority__c = String.ValueOf( [SELECT count() from FieldExperienceProcess__c where FieldExperience__c = :ParentFe.id and isDeleted = false] + 1 );
        placementAttempt.RecordTypeID = thisRecordTypeId;
        if ( isDistrict ) {
          placementAttempt.NewDistrict__c = address;
          placementAttempt.NewDistrictContact__c = contact;
          placementAttempt.Name = 'New District';
        } else {
          placementAttempt.NewSchool__c = address ;
          placementAttempt.NewSchoolContact__c = contact;
          placementAttempt.Name = 'New School';
        }
        placementAttempt.FieldExperience__c = ParentFe.id;
        placementAttempt.Student__c = ParentFe.Student__c;
        placementAttempt.Mentor__c = ParentFe.Mentor__c;
        insert placementAttempt;
        return placementAttempt.id;
    }
    
    public virtual String addFEProcess(String recordTypeName, String schoolId, String districtId ) {
        FieldExperienceProcess__c placementAttempt = new FieldExperienceProcess__c();
        FieldExperience__c ParentFe = getActiveFieldExperience();
        Id thisRecordTypeId = ( recordTypeName == null )? [SELECT ID from RecordType where DeveloperName = 'PlacementAttempt' and SObjectType = 'FieldExperienceProcess__c' LIMIT 1].id : [SELECT ID from RecordType where DeveloperName = :recordTypeName and SObjectType = 'FieldExperienceProcess__c' LIMIT 1].id;

        if ( schoolId == null && districtId == null ) {
          throw new FieldExperienceException('PLACEMENT ATTEMPT ERROR: either a valid school Id or a district Id must be supplied to create a Placement Attempt');
        }
        
        placementAttempt.PreferredPriority__c = String.ValueOf( [SELECT count() from FieldExperienceProcess__c where FieldExperience__c = :ParentFe.id and isDeleted = false] + 1 );
        placementAttempt.RecordTypeID = thisRecordTypeId;
        
        if ( districtId != null && districtId != '' ) {
          placementAttempt.District__c = districtId;
          placementAttempt.Name = [SELECT Name from Account where id = :districtId].Name;
        }
        if ( schoolId != null && schoolId != '' ) {
          placementAttempt.School__c = schoolId ;
          placementAttempt.Name = [SELECT Name from Account where id = :schoolId].Name;
        }
        placementAttempt.FieldExperience__c = ParentFe.id;
        placementAttempt.Student__c = ParentFe.Student__c;
        placementAttempt.Mentor__c = ParentFe.Mentor__c;
        insert placementAttempt;
        return placementAttempt.id;
    }
    
    public virtual String getAllFEToDoTemplatesExtJSON() {
        return JSONUtil.getJSON(getFEToDoTemplateObjects());
    }

    public virtual List<WGUFEToDo__c> getFEToDoTemplateObjects() {
          List<WGUFEToDo__c> toDos = [select count() FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:getStudentContact().ProgramCode__c ) and isDeleted = false ] >0? [select AfterCompletionMessage__c,NextCardIndex__c,Instructions__c,CompletionCriteria__c,CompletionURL__c,FEFieldName__c,Id,IsBannerDataVerificationRequired__c,Name,PrerequisiteToDo__c,SortOrder__c,StudentTaskCode__c,TaskDurationDays__c,CardIndex__c FROM WGUFEToDo__c WHERE ID IN (SELECT WGUFEToDo__c from WGUFEToDoByProgram__c where Name =:getStudentContact().ProgramCode__c ) and isDeleted = false order by SortOrder__c ASC ]: new List<WGUFEToDo__c>();
          if ( toDos.isEmpty() ) {  
              throw new FieldExperienceException('DEGREE PROGRAM NOT PERMITTED: Your degree ('+getStudentContact().ProgramCode__c+') is not authorized for the Field Experience Application');
          }
          return toDos;
    }
    
    public virtual boolean setFEToDoComplete( Id taskId ) {
        boolean result = false;
        Task thisTask;
        Boolean validTaskForThisStudent = false;
        if ( taskId == null || !((String)taskId).toLowerCase().startsWith(Schema.SObjectType.Task.getKeyPrefix().toLowerCase()) ) {
            throw new FieldExperienceException('INVALID TASK ID ERROR: setFEToDoComplete() requires a valied SFID for a Task in StudentFieldExperience.setFEToDoComplete()' );
        } else {
            for ( Task aTask: this.getStudentFETasks() ) {
              if ( ((String)aTask.id).startsWith( taskId ) ) {
                validTaskForThisStudent = true;
                System.debug( LoggingLevel.DEBUG, 'TASK ID FOUND for taskId ' + taskId + ' in StudentFieldExperience.setFEToDoComplete()' );
                break;
              }
            }
            if ( validTaskForThisStudent ) {
                thisTask = new Task(id=taskId,Status='Completed');
                if ( !Test.isRunningTest() && adapter != null ) {
                    adapter.updateObject( thisTask );
                } else {
                    System.debug(LoggingLevel.DEBUG,'TEST MODE DETECTED');
                    update thisTask;
                }            
                result = true;
            } else {
                System.debug( LoggingLevel.DEBUG, 'TASK ID NOT FOUND for taskId ' + taskId + ' in StudentFieldExperience.setFEToDoComplete()' );
            }
        }
        return result;
    }

    public virtual String findDistrictExtJSON(String districtName, String state) {
       return JSONUtil.getJSON(findDistrict(districtName, state));
    }
    
    public virtual List<Account> findDistrict(String districtName, String state) {
        List<Account> results = new List<Account>();
        ID recordTypeDistrict = [SELECT ID from RecordType where DeveloperName ='District' and SObjectType = 'Account'].id;
        if ( !Test.isRunningTest() && adapter != null ) {
          String result = adapter.search( 'FIND {*'+districtName+'*} IN NAME FIELDS RETURNING Account (id,Name,County__c,IsWGUPlacementRequired__c,ShippingCity,NCESCode__c where IsPersonAccount = false and isDeleted = false and RecordTypeId = \''+recordTypeDistrict+'\' AND ShippingState = \''+state+'\' ORDER BY Name LIMIT 100)' );
          results = ( result != '[ ]' && result != '' )? (List<Account>)JSON.deserialize( result, List<Account>.class ): results;
        } else {
          results = (List<Account>)(search.query( 'FIND \'*'+districtName+'*\' IN NAME FIELDS RETURNING Account (id,Name,County__c,IsWGUPlacementRequired__c,ShippingCity,NCESCode__c where IsPersonAccount = false and isDeleted = false and RecordTypeId = \''+recordTypeDistrict+'\' AND ShippingState = \''+state+'\' ORDER BY Name LIMIT 100)' )[0]);
        }
        return results;
    }

    public virtual String getSchoolNamesFromFEProcessDistrictsExtJSON() {
      List<FieldExperienceProcess__c> feprocesses = getAllFEProcesses();
      Map<String,String> districts = new Map<String,String>();
      //eliminate any duplicates
      for (FieldExperienceProcess__c fep : feprocesses ) {
        System.debug( LoggingLevel.DEBUG, 'FE PROCESS: ' + fep );      
        System.debug( LoggingLevel.DEBUG, 'FE District: ' + fep.District__c );      
        if ( fep.District__c != null ) {
          if ( !districts.containsKey( fep.District__c ) ) {
            districts.put( fep.District__c, fep.District__c );
          }
        } 
      }
      if ( districts.size() > 0 ) {
          String districtIds = '';
          Boolean firstRecord = true;
          for( Id district: districts.keySet() ) {
              districtIds += (( firstRecord )? '\''+district+'\'': ','+ '\''+district+'\'');  
              firstRecord = false;
          }
          ID recordTypeK12 = [SELECT ID from RecordType where DeveloperName ='SchoolK12' and SObjectType = 'Account'].id;
          System.debug( LoggingLevel.DEBUG, 'RECORD ID: ' + recordTypeK12 );
          String queryStr = 'SELECT id,Name,County__c,IsWGUPlacementRequired__c,SchoolDistrict__c,ShippingCity,SchoolDistrict__r.Name,SchoolDistrict__r.ShippingCity,NCESCode__c FROM Account where IsPersonAccount = false and isDeleted = false and RecordTypeId = \''+recordTypeK12+'\' AND SchoolDistrict__c IN ('+ districtIds +') ORDER BY Name LIMIT 10000';
          System.debug( LoggingLevel.DEBUG, 'QUERY STRING: ' + queryStr );
          return JSONUtil.getJSON(( !Test.isRunningTest() && adapter != null )? (List<Account>)(adapter.queryObjects(queryStr)) : Database.query(queryStr));
      } else {
          return JSONUtil.getJSON(new List<Account>());
      }
    }

    public virtual String findSchoolExtJSON(String schoolName, String state) {
           return JSONUtil.getJSON(findSchool(schoolName, state));
    }

    public virtual List<Account> findSchool(String schoolName, String state) { 
        List<Account> results = new List<Account>();
        ID recordTypeK12 = [SELECT ID from RecordType where DeveloperName ='SchoolK12' and SObjectType = 'Account'].id;
        if ( !Test.isRunningTest() && adapter != null ) {
           String result = adapter.search( 'FIND {*'+schoolName+'*} IN NAME FIELDS RETURNING Account (id,Name,County__c,IsWGUPlacementRequired__c,SchoolDistrict__c,ShippingCity,SchoolDistrict__r.Name,SchoolDistrict__r.ShippingCity,NCESCode__c where IsPersonAccount = false and isDeleted = false and RecordTypeId = \''+recordTypeK12+'\' AND ShippingState = \''+state+'\' ORDER BY Name LIMIT 100)' );
           results = ( result != '[ ]' && result != '' )?(List<Account>)JSON.deserialize( result, List<Account>.class ): results;
        } else {
          results = (List<Account>)(search.query( 'FIND \'*'+schoolName+'*\' IN NAME FIELDS RETURNING Account (id,Name,County__c,IsWGUPlacementRequired__c,SchoolDistrict__c,ShippingCity,SchoolDistrict__r.Name,SchoolDistrict__r.ShippingCity,NCESCode__c where IsPersonAccount = false and isDeleted = false and RecordTypeId = \''+recordTypeK12+'\' AND ShippingState = \''+state+'\' ORDER BY Name LIMIT 100)' )[0]);
        }
        return results;
    }

    public virtual boolean isAssessmentComplete(String assessmentCode) {
        assessmentCode = assessmentCode.trim();
        boolean result = false;
        Integer completedAssessments = 0;
        if ( assessmentCode.contains(',') ) {
          String[] andAssessments = assessmentCode.split(',');
          completedAssessments = [SELECT count() FROM StudentCompletionTask__c where Student__c = :getStudentContact().id AND isDeleted = false AND name IN :andAssessments and RequirementComplete__c=true];
          result = (completedAssessments == andAssessments.size() );
        } else if ( assessmentCode.contains(' ') ) {
          String[] orAssessments = assessmentCode.split(' ');
          completedAssessments = [SELECT count() FROM StudentCompletionTask__c where Student__c = :getStudentContact().id AND isDeleted = false AND name IN :orAssessments and RequirementComplete__c=true];
          result = (completedAssessments > 0);
        } else {
          completedAssessments = [SELECT count() FROM StudentCompletionTask__c where Student__c = :getStudentContact().id AND isDeleted = false AND name = :assessmentCode and RequirementComplete__c=true];
          result = (completedAssessments > 0);
        }
        return result;
    }

    public virtual String getFEStateLicensesExtJSON(String state) {
         //return [SELECT count() FROM TeacherLicense__c where Active__c = true and isDeleted = false AND AvailableForDTApp__c = true AND LicenseStateCode__c = :state] > 0? JSONUtil.getJSON([SELECT Id,Name,UtahLicenseTitle__c,UtahReciprocity__c,Version__c,VersionChangeDate__c FROM TeacherLicense__c where Active__c = true AND AvailableForDTApp__c = true AND isDeleted = false AND LicenseStateCode__c = :state]): JSONUtil.getJSON(new List<TeacherLicense__c>() );
         return [SELECT count() FROM TeacherLicense__c where Active__c = true and isDeleted = false AND AvailableForDTApp__c = true AND LicenseStateCode__c = :state] > 0? JSONUtil.getJSON([SELECT Id,Name,UtahReciprocity__c,Version__c,VersionChangeDate__c FROM TeacherLicense__c where Active__c = true AND AvailableForDTApp__c = true AND isDeleted = false AND LicenseStateCode__c = :state]): JSONUtil.getJSON(new List<TeacherLicense__c>() );
    }

     public virtual boolean setFELicenseState(String state) {
        boolean result = false;
        FieldExperience__c fe = getActiveFieldExperience();
        fe.state__c = state;
        update fe;
        result = true;
        return result;
    }

     public virtual boolean setFELicenseGoal(Id licenseId) {
        boolean result = false;
        FieldExperience__c fe = getActiveFieldExperience();
        fe.TeacherLicense__c = licenseId;
        update fe;
        result = true;
        return result;
    }

     public virtual boolean setDTPhaseStatus(String status) {
        boolean result = false;
        FieldExperience__c fe = getActiveFieldExperience();
        fe.DTPhaseStatus__c = status;
        update fe;
        result = true;
        return result;
     }
 
     public virtual boolean setFECohort(ID cohort) {
        boolean result = false;
        FieldExperience__c fe = getActiveFieldExperience();
        fe.Cohort__c = [SELECT count() from Cohort__c where ID = :cohort]>0 ?cohort: fe.Cohort__c;
        update fe;
        result = true;
        return result;
     }
    
}