/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 25 2013 @ 2019 hrs
 * Revised: Corrected Mentor Synchronization on FE Record - Paul Coleman
 * 
 * Date Feb 11 2013 @ 1322 hrs
 * Revised: try/catch correction for future methods  - Paul Coleman
 * 
 * Date January 30 2013 @ 2019 hrs
 * Revised: Person Account Refactor - Paul Coleman
 * 
 * Created Date Aug 15 2012 @ 1536 hrs
 * 
 * Sync the Task Status on related Field Experience records 
 *
 */
 public class FieldExperienceUtility {
 

 
////////////////////// START syncFETaskToCheckBox  ///////////////////////////

     //Task: after Update, this method is called from the TaskTrigger
     public static void syncFETaskToCheckBox( String ListNewJSON, String OldMapJSON ) {
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processSyncFETaskToCheckBox(ListNewJSON, OldMapJSON);
       } else {
          asyncSyncFETaskToCheckBox(ListNewJSON, OldMapJSON);
       }
     }
     
     @future
     private static void asyncSyncFETaskToCheckBox( String ListNewJSON, String OldMapJSON ) {
        processSyncFETaskToCheckBox(ListNewJSON, OldMapJSON);
     }

     //Task: after Update, this method is called from the TaskTrigger
     private static void processSyncFETaskToCheckBox( String taskListNewJSON, String OldMapJSON ) {
     
         if ( taskListNewJSON != null  && OldMapJSON != null ) {
            
             List<Task> TriggerNew = (List<Task>)JSON.deserialize( taskListNewJSON, List<Task>.class );
             Map<ID,Task> TriggerOldMap = (Map<ID,Task>)JSON.deserialize( OldMapJSON, Map<ID,Task>.class );
             
             
             Map<Id,FieldExperience__c> feRecordsForUpdate = new Map<Id,FieldExperience__c>();
             Set<ID> WhatIds = new Set<ID>();
             List<Task> taskRecords;
             Map<Id,FieldExperience__c> feRecords;
             Map<Id, WGUFEToDo__c> templateRecords;
             ID studentTaskID = [Select ID from RecordType where DeveloperName='StudentTask' and sObjectType = 'Task' ].id;
             
             templateRecords = new Map<Id,WGUFEToDo__c>([Select Id, FECheckboxFieldName__c from WGUFEToDo__c WHERE FECheckboxFieldName__c != null LIMIT 10000]);
             
            //get qualified Task records from TriggerNew list
             taskRecords = [SELECT count() from Task where ID IN :TriggerNew AND TemplateId__c != null AND TemplateObjectType__c = 'WGUFEToDo__c' AND WhatId != null AND RecordTypeID = :studentTaskID AND Status != 'Deactivated'] > 0? [SELECT ID, TemplateId__c, Status, WhatId, isClosed from Task where ID IN :Triggernew AND TemplateId__c != null AND TemplateObjectType__c = 'WGUFEToDo__c' AND WhatId != null AND RecordTypeID = :studentTaskID AND Status != 'Deactivated' LIMIT 50000 ]: new List<Task>();
             for ( Task taskRec: taskRecords ) {
                  if ( !WhatIds.contains( taskRec.whatId ) ) {
                    WhatIds.add( taskRec.whatId );
                  }   
             }
                 
             System.debug( LoggingLevel.DEBUG, 'TASK WHAT IDs: ' +JSON.serialize( WhatIds ) );    
             //get FieldExperience__c records from Task records' whatId field (gathered above)
             feRecords = [Select count() from FieldExperience__c where id IN :WhatIds and Active__c = true ] > 0? new Map<Id,FieldExperience__c>([Select Id from FieldExperience__c where id IN :WhatIds and Active__c = true LIMIT 10000]): new Map<Id,FieldExperience__c>();
            
             for ( Task studentTask : taskRecords ) {
             
                    Task oldTask = TriggerOldMap.get(studentTask.id);
                    FieldExperience__c fe = feRecords.get(studentTask.whatId);
                    WGUFEToDo__c template = templateRecords.get(studentTask.templateId__c);
                    
                    //evaluate if the old and new values for status have changed in this trigger's context, if so, change the value of the FE record's checkbox field, if any
                    if ( oldTask != null && oldTask.Status != studentTask.Status && fe != null && template != null ) {
                        
                        //if FE record already has one checkbox field already being updated, add the current field
                        FieldExperience__c existingUpdate = feRecordsForUpdate.get(fe.id);
                        if ( existingUpdate == null ) {
                            FieldExperience__c newFe = new FieldExperience__c(id=fe.id);
                            System.debug( LoggingLevel.DEBUG, 'SETTING FE CHECKBOX VALUE: ' + template.FECheckboxFieldName__c +'='+ studentTask.IsClosed );
                            newFe.put( template.FECheckboxFieldName__c, studentTask.IsClosed );
                            feRecordsForUpdate.put( newFe.id, newFe );
                        } else {
                          existingUpdate.put( template.FECheckboxFieldName__c, studentTask.IsClosed );
                        }
                        
                    }
                    
              }
          
             if ( !feRecordsForUpdate.isEmpty() ) {
                System.debug( LoggingLevel.DEBUG, JSON.serialize(feRecordsForUpdate) ); 
                update feRecordsForUpdate.values();
             }
         } 
       }
       
////////////////////// END syncFETaskToCheckBox  ///////////////////////////
////////////////////////////////////////////////////////////////////////////
 
 
 
////////////////////// START closeAllOpenStudentTasks  ///////////////////////////
    //FieldExperience__c: after Update, this method is called from FieldExperienceTrigger, Note: the Task updates will cause the TaskTrigger to fire
   public static void closeAllOpenStudentTasks(  String ListNewJSON,  String OldMapJSON ) {
       if (  Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processCloseAllOpenStudentTasks(ListNewJSON, OldMapJSON);
       } else {
          asyncCloseAllOpenStudentTasks(ListNewJSON, OldMapJSON);
       }
   }
     
   @future
   private static void asyncCloseAllOpenStudentTasks( String ListNewJSON, String OldMapJSON ) {
        processCloseAllOpenStudentTasks(ListNewJSON, OldMapJSON);
   }

    
   //FieldExperience__c: after Update, this method is called from FieldExperienceTrigger, Note: the Task updates will cause the TaskTrigger to fire
   private static void processCloseAllOpenStudentTasks( String ListNewJSON, String OldMapJSON ) {
     
      List<FieldExperience__c> TriggerNew = (List<FieldExperience__c>)JSON.deserialize( ListNewJSON, List<FieldExperience__c>.class );
      Map<ID,FieldExperience__c> TriggerOldMap = (Map<ID,FieldExperience__c>)JSON.deserialize( OldMapJSON, Map<ID,FieldExperience__c>.class );
      
      if ( TriggerNew.size() > 0 && TriggerOldMap.size() > 0  ) {
               
          if ( [SELECT count() from FieldExperience__c where Active__c = false AND id IN :TriggerNew] > 0 ) {
            
              Set<ID> FeIDs = new Set<ID>();
              for ( FieldExperience__c fe: TriggerNew ) {
                if ( fe.Active__c == false && TriggerOldMap.get(fe.id).Active__c == true && (!FeIDs.contains(fe.id)) ) {  
                    //if the old record was active, and new record is not, add it to the map. This process only processes newly deactivated records
                  FeIDs.add( fe.id );
                }
              }
          
              ID studentTaskID = [Select ID from RecordType where DeveloperName='StudentTask' and sObjectType = 'Task' ].id; 
               
              //get the tasks connected to the FieldExperience records of interest (from the trigger array)
              
              List<Task> tasks = [SELECT count() from Task where WhatId IN :FeIDs AND RecordTypeID = :studentTaskID] > 0?[SELECT id, Whatid, isClosed from Task where WhatId IN :FeIDs AND RecordTypeID = :studentTaskID LIMIT 10000]: new List<Task>();
              List<Task> taskForUpdate = new List<Task>();        
              
              for ( FieldExperience__c thisFE : TriggerNew ) {
                  if ( thisFE.Active__c == false && FeIDs.contains(thisFE.id) ) {  //newly deactivated FE record
                    for ( Task t: tasks ) {
                        if ( t.whatId == thisFE.id && (!t.isClosed) ) {
                            taskForUpdate.add( new Task(id=t.id,Status='Deactivated') );
                        }
                    }
                  }
              }
           
              if ( taskForUpdate.size() > 0 ) {
                update taskForUpdate;
              }
             
          }
      }
   }

////////////////////// END closeAllOpenStudentTasks  ///////////////////////////
////////////////////////////////////////////////////////////////////////////////
 
 
 
   //FieldExperience: before Insert, before Update, sync Mentor__c field value with Student's current Mentor__c assignment
    public static void syncFEStudentMentor( List<FieldExperience__c> TriggerNew, boolean IsUpdate ) {
        
       Set<ID> studentContactIds = new Set<ID>();
       //collect all the triggered student contact ids
       for ( FieldExperience__c fe: TriggerNew ) {
         if ( fe.Student__c != null && !studentContactIds.contains(fe.Student__c) ) {
              studentContactIds.add( fe.Student__c );
         }
       }
       
       //get the studentContact Mentor ids from the student Contact array of Ids
       Map<Id,Id> contactMentorMap = new Map<Id,Id>();
       for ( Contact studentContact : [SELECT Id, Mentor__c from Contact where Id IN :studentContactIds AND Mentor__c != null ] ) {
         contactMentorMap.put( studentContact.Id, studentContact.Mentor__c );
       }
       
       //set the mentor id on all FE records for known student contact mentor ids
       for ( FieldExperience__c fe: TriggerNew ) {
            fe.Mentor__c = (fe.Student__c != null? contactMentorMap.get(fe.Student__c): null); 
       }           
               
   }
   
   
   
   //-----RAAVI--------------------
   
   //-- To Update the Placement Specialist field based on Owner Profile
   public static void updateFEPlacementSpecialist( List<FieldExperience__c> TriggerNew, boolean IsUpdate ) {
           
               List<FieldExperience__c> updateFE = new  List<FieldExperience__c>();
               if ( TriggerNew != null && !TriggerNew.isEmpty() ) {
        
                   Set<ID> feOwnerIDs = new Set<ID>();
                   for ( FieldExperience__c fe: TriggerNew ) {                 
                          feOwnerIDs.add(fe.ownerId);                
                   }
                   Map<String,user> usrMap=new Map<String,user>();
                   List<User> usrList=[select id,Profile.Name,Name from user where id in:feOwnerIDs];
                   for(User usr:usrList){
                       usrMap.put(usr.id,usr);        
                   }       
                   
                   for ( FieldExperience__c fe: TriggerNew ) {                 
                      fe.PlacementSpecialist__c = (usrMap.get(fe.ownerId).Profile.Name=='Field Experiences User')? usrMap.get(fe.ownerId).Id: null;
                   }
               
           }
   }
   
   
   
   //-------- Handle Field Experience Withdrawn------------
   public static void doFEWithdraw(String TriggerNewJSON, String TriggerOldMapJSON){
       if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
          processFEWithdraw( TriggerNewJSON, TriggerOldMapJSON );
       } else {
          asyncFEWithdraw( TriggerNewJSON, TriggerOldMapJSON  );
       }
   }
    
   @future
   private static void asyncFEWithdraw(String ListNewJSON, String OldMapJSON) {
       processFEWithdraw( ListNewJSON, OldMapJSON );
   }
    
   private static void processFEWithdraw(String ListNewJSON, String OldMapJSON){
      List<FieldExperience__c> TriggerNew = (List<FieldExperience__c>)JSON.deserialize( ListNewJSON, List<FieldExperience__c>.class );
      Map<ID,FieldExperience__c> TriggerOldMap = (Map<ID,FieldExperience__c>)JSON.deserialize( OldMapJSON, Map<ID,FieldExperience__c>.class );
    
       List<FieldExperience__c> cloneFeList=new List<FieldExperience__c>();
       List<FieldExperience__c> updateFeListCount=new List<FieldExperience__c>();
       List<Contact> contactsForUpdateList=new List<Contact>();
       Set<id> contactIds = new Set<Id>();
       for(FieldExperience__c fe:TriggerOldMap.values()){
           contactIds.add(fe.Student__c);   
       }
       List<FieldExperienceProcess__c> fepUPDList=new List<FieldExperienceProcess__c>();
       List<FieldExperienceProcess__c> fepList= [SELECT count() FROM FieldExperienceProcess__c WHERE FieldExperience__c in:TriggerOldMap.keyset() AND (recordtype.DeveloperName ='CSRequest' OR recordtype.DeveloperName ='PlacementAttempt') ]>0? [SELECT id,FieldExperience__c,CSRequest__c,PlacementStatus__c,recordtype.DeveloperName FROM FieldExperienceProcess__c WHERE FieldExperience__c in:TriggerOldMap.keyset() AND (recordtype.DeveloperName ='CSRequest' OR recordtype.DeveloperName ='PlacementAttempt') ]: new List<FieldExperienceProcess__c>();
       Map<Id,Contact> conMap = [SELECT count() FROM Contact where Id IN :contactIds]>0? new Map<Id,Contact>([SELECT id,NumberofFEAppWithdrawn__c FROM Contact where Id IN :contactIds]): new Map<Id,Contact>();
       for(FieldExperience__c fe:TriggerNew){
           if(fe.AdmissionStatus__c!=null && fe.AdmissionStatus__c!='' && fe.AdmissionStatus__c=='Withdrawn' && fe.AdmissionStatus__c!=TriggerOldMap.get(fe.id).AdmissionStatus__c){
               FieldExperience__c cloneOldFe=TriggerOldMap.get(fe.id).clone();
               cloneOldFe.DTRecommendStatus__c='Required'; 
               cloneOldFe.AdmissionStatusDate__c=null; 
               cloneOldFe.Cohort__c=null;
               cloneOldFe.DTAffidavit__c=false;
               cloneOldFe.DTCohortTimelineUploaded__c=false;
               cloneOldFe.TimelineOK__c=false;
               cloneOldFe.SplitPlacement__c= false;
               cloneOldFe.SFAWReminder__c=null;
               cloneOldFe.BasicSkillsRevision__c=null;
               cloneOldFe.FERPANeeded__c=null;
               cloneOldFe.LiabilityReminder__c=null;
               cloneOldFe.FEAutoEmails__c='';
               cloneOldFe.AdmissionStatus__c='';
               cloneOldFe.ReasonforWithdrawalorDenial__c='';
               cloneOldFe.WithdrawalEmailSent__c=null;
               cloneOldFe.LicensureRevsion__c=null;
               cloneOldFe.DistrictSchoolRevision__c=null;
               cloneOldFe.DTTimelineRevision__c=null;
               cloneOldFe.Active__c=true;
               cloneOldFe.DTPlacementStartDate__c=null;
               cloneOldFe.DTPlacementEndDate__c=null;
               cloneOldFe.DODStudent__c=false;
               cloneOldFe.TPAParticipant__c=false;
               cloneOldFe.VideoRelease__c=false;
               cloneOldFe.StudentCallMade__c=null;
               cloneOldFe.PlacementComplete__c=null;
               cloneOldFe.EverythingComplete__c=null;
               cloneOldFe.DTPhaseStatus__c=null;
               cloneOldFe.MenRecAcceptsGuidance__c=null;
               cloneOldFe.MenRecAcceptsResponsibility__c=null;
               cloneOldFe.MenRecAttemptstoSolveProblems__c=null;
               cloneOldFe.MenRecClarifiesConcepts__c=null;
               cloneOldFe.MenRecCommProfessionalToneTechnology__c=null;
               cloneOldFe.MenRecConductedInterviewCall__c=null;
               cloneOldFe.MenRecConveysThoughts__c=null;
               cloneOldFe.MenRecDateConductedCall__c=null;
               cloneOldFe.MenRecDoesNotCutOthersOff__c=null;
               cloneOldFe.MenRecDoesNotUseFillerWords__c=null;
               cloneOldFe.MenRecEmploysLatestToolsTechnology__c=null;
               cloneOldFe.MenRecEnunciatesWordsClearly__c=null;
               cloneOldFe.MenRecEvaluatesPersonalPerformance__c=null;
               cloneOldFe.MenRecExhibitsAdaptability__c=null;
               cloneOldFe.MenRecExhibitsProfessionalDemeanor__c=null;
               cloneOldFe.MenRecExhibitsResponsibility__c=null;
               cloneOldFe.MenRecExhibitsSelfConfidence__c=null;
               cloneOldFe.MenRecExhibitsSelfControl__c=null;
               cloneOldFe.MenRecExhibitsSelfEsteem__c=null;
               cloneOldFe.MenRecExpressesFeelings__c=null;
               cloneOldFe.MenRecExpressesPositiveAttitude__c=null;
               cloneOldFe.MenRecFacesProblemsRealistically__c=null;
               cloneOldFe.MenRecInteractsProfessionally__c=null;
               cloneOldFe.MenRecListensCarefully__c=null;
               cloneOldFe.MenRecMaintainsAttitude__c=null;
               cloneOldFe.MenRecMakesSoundDecisions__c=null;
               cloneOldFe.MenRecMentorRecommend__c=null;
               cloneOldFe.MenRecModifiesActionsAfterCriticism__c=null;
               cloneOldFe.MenRecNeedsTSReview__c=null;
               cloneOldFe.MenRecPresentsWillingnessSolve__c=null;
               cloneOldFe.MenRecProficientInUseOfTechnology__c=null;
               cloneOldFe.MenRecProjectsVoiceAppropriately__c=null;
               cloneOldFe.MenRecReasonNoRecommend__c=null;
               cloneOldFe.MenRecRecommendationDate__c=null;
               cloneOldFe.MenRecShowsConcernCaringCompassion__c=null;
               cloneOldFe.MenRecShowsInterestandEnthusiasm__c=null;
               cloneOldFe.MenRecShowsRespect__c=null;
               cloneOldFe.MenRecShowsSensitivity__c=null;
               cloneOldFe.MenRecShowsTolerance__c=null;
               cloneOldFe.MenRecShowsWillingnesstoLearn__c=null;
               cloneOldFe.MenRecUsesandAcceptsHumor__c=null;
               cloneOldFe.MenRecUsesAppropriateSyntax__c=null;
               cloneOldFe.MenRecUsesAppropriateWords__c=null;
               cloneOldFe.MenRecUsesRespectfulLanguage__c=null;
               cloneOldFe.MenRecUsesVoiceInflection__c=null;
               cloneOldFe.MenRecWearsSuitableClothing__c=null;
               cloneOldFe.MenRecWorksCooperatively__c=null; 
               
               Integer now=0;
               Contact st=new Contact(id=fe.Student__c);
               system.debug('raavi1 '+st);
               system.debug('raavi2 '+fe.Student__r.StudentID__c);
               system.debug('raavi3 '+st.NumberofFEAppWithdrawn__c);   
               now = (conMap!=null && conMap.size()>0 && conMap.get(fe.Student__c) != null && (conMap.get(fe.Student__c).NumberofFEAppWithdrawn__c == null  || conMap.get(fe.Student__c).NumberofFEAppWithdrawn__c==0 ))? 0 : Integer.valueOf(conMap.get(fe.Student__c).NumberofFEAppWithdrawn__c);
               st.NumberofFEAppWithdrawn__c=now+1;
               contactsForUpdateList.add(st);
               cloneFeList.add(cloneOldFe);
                 
               
               FieldExperience__c feUpd=new FieldExperience__c(id=fe.id,AdmissionStatus__c='Withdrawn',Active__c=false,AdmissionStatusDate__c=System.now());
               updateFeListCount.add(feUpd);
               
                for(FieldExperienceProcess__c fepRec: fepList){
                      if(fepRec.FieldExperience__c==fe.id && fepRec.recordtype.DeveloperName=='PlacementAttempt'){
                           fepRec.PlacementStatus__c=null;
                           fepUPDList.add(fepRec);
                      }else if(fepRec.FieldExperience__c==fe.id && fepRec.recordtype.DeveloperName=='CSRequest'){     
                           fepRec.CSRequest__c=null;                           
                           fepUPDList.add(fepRec);        
                      }
                }
               
               
           }  
       } 
       insert cloneFeList; 
       update updateFeListCount;
       update fepUPDList;
       update contactsForUpdateList;
        
   }
   
        
} //End FieldExperienceUtility CLASS