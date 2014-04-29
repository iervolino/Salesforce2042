/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date January 28, 2013 @ 1746 hrs
 * Revised: Person Account Refactor 
 * 
 * Revised Oct 30 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 * 
 * Manages processes for Student-facing Visual Force Page: MyFieldExperience.page
 *
 */
 public with sharing class MyFieldExperienceController {
    
    public String getLt(){
        return '<';
    }
    public String getGt(){
        return '>';
    }

    public MyFieldExperienceController() {
      this.personalInfoURL = getStudentFieldExperience().getVerifyPersonalInfoURL();
    }

    public static StudentFieldExperience getStudentFieldExperience() { 
    
        ID userId = UserInfo.getUserId();
        try {
          transient StudentFieldExperience  sfe = (UserInfo.getProfileId() != [SELECT Id from Profile where Name='Student Profile'].id)? new StudentFieldExperience( [SELECT Id FROM Contact where Name = 'Khadijah_test Abdullah_test' and PIDM__c LIKE 'pctest%' LIMIT 1].id ): new StudentFieldExperience(userId);
          return sfe;
        } catch ( QueryException  e ) {
            ApexPages.addMessages(e);
            return null;
        }
    }

    public PageReference attachFile() {
       if ( this.fileAttachment != null && this.fileContentType != null && this.fileAttachmentName != null ){
         this.fieldExperienceId = this.fieldExperienceId == null? getFE().Id: this.fieldExperienceId;
         this.uploadSuccess = saveFileAttachment( this.fieldExperienceId, this.fileAttachment, this.fileContentType, this.fileAttachmentName );
       } else {
         ApexPages.addMessages(new FieldExperienceException('NULL VALUE ERROR: fileAttachment, fileContentType and fileAttachmentName are required parameters for the attachFile() method.'));
       }     
       this.fileAttachment = null;
       this.fileAttachmentName = null;
       this.fileContenttype = null;
       return Page.MyFieldExperience;              
    }

    public PageReference attachGeneralFile() {
       if ( this.fileAttachment != null && this.fileContentType != null && this.fileAttachmentName != null ){
         this.fieldExperienceId = this.fieldExperienceId == null? getFE().Id: this.fieldExperienceId;
         this.uploadSuccess = saveFileAttachment( this.fieldExperienceId, this.fileAttachment, this.fileContentType, this.fileAttachmentName );
       } else {
         ApexPages.addMessages(new FieldExperienceException('NULL VALUE ERROR: fileAttachment, fileContentType and fileAttachmentName are required parameters for the attachFile() method.'));
       }   
       this.fileAttachment = null;
       this.fileAttachmentName = null;
       this.fileContenttype = null;
       this.toDoIndex = null;
       return Page.MyFieldExperience;              
    }

    public static Boolean saveFileAttachment( ID thisFieldExperienceId, Blob thisfileAttachment, String thisfileContentType, String thisfileAttachmentName ) {
            Attachment attach = new Attachment();
            attach.Body = thisfileAttachment;
            attach.Name = thisfileAttachmentName;
            attach.Description = thisfileAttachmentName;
            attach.ContentType = thisfileContentType;
            attach.ParentID = thisFieldExperienceId;
            attach.isPrivate = false;
            try {
                  insert attach;
                  return true;
            } catch(System.DMLException dml) {
               ApexPages.addMessages(dml);
               System.debug(LoggingLevel.ERROR, dml);
               return false;
            }
    }
    
    @RemoteAction
    public static String getAllToDosAsJSON() { 
        try {
          return getStudentFieldExperience().getStudentFETasksExtJSON();
        } catch(FieldExperienceException e) {
          ApexPages.addMessages(e);
          return '';
        }
    }

    @RemoteAction
    public static String getAllToDoTemplates() {
        try {
          return getStudentFieldExperience().getAllFEToDoTemplatesExtJSON();
        } catch(FieldExperienceException e) {
          ApexPages.addMessages(e);
          return '';
        }
    }
           
    @RemoteAction
    public static boolean setToDoComplete( Id taskId ) {    
          try {
          return getStudentFieldExperience().setFEToDoComplete( taskId );
        } catch(FieldExperienceException e) {
          ApexPages.addMessages(e);
          return false;
        }
    }
    
    @RemoteAction
    public static boolean setDTPhaseStatus() {    
        return getStudentFieldExperience().setDTPhaseStatus('DT Submitted');
    }
    
    @RemoteAction
    public static String findDistrict( String districtName, String state ) {
        return getStudentFieldExperience().findDistrictExtJSON(districtName, state);
    }
    
    @RemoteAction
    public static String findSchool( String schoolName, String state ) {
        return getStudentFieldExperience().findSchoolExtJSON(schoolName, state);
    }
    
    @RemoteAction
    public static boolean isAssessmentComplete( String assessmentCode ) {
        return getStudentFieldExperience().isAssessmentComplete(assessmentCode);
    }

    @RemoteAction
    public static boolean isBasicSkillsAssessmentComplete() {
        Boolean result = false;
        String licenseState = Test.isRunningTest()? 'Utah': getStudentFieldExperience().getActiveFieldExperience().State__c;
         if ( licenseState != null ) {
           String stateAbbr = [SELECT NAME from States__c where StateFullName__c = :licenseState LIMIT 1].Name;
           String skillCodes = States__c.getValues(stateAbbr)!=null? States__c.getValues(stateAbbr).EducatorBasicSkillsCodes__c: null;
           result = skillCodes != null? isAssessmentComplete( skillCodes ) : false;
         } else {
           result = false;
         }
        return result;
    }

    
    @RemoteAction
    public static String addFEPlacementAttempt( String school, String district ) {
          try {
            String defaultRecordType = 'PlacementAttempt';
            return getStudentFieldExperience().addFEProcess( defaultRecordType, school, district );
          } catch (FieldExperienceException e) {
          ApexPages.addMessages(e);
          return '';
          }
    }
    
    @RemoteAction
    public static String addFEPlacementAttemptCustom( String address, String contact, Boolean isDistrict ) {
        try {
            String defaultRecordType = 'PlacementAttempt';
            return getStudentFieldExperience().addFEProcess( defaultRecordType, address, contact, isDistrict );
        } catch (FieldExperienceException e) {
          ApexPages.addMessages(e);
          return '';
        }
    }
    
    @RemoteAction
    public static String getAllFEProcesses() {
        return getStudentFieldExperience().getAllFEProcessesExtJSON();
    }
    
    @RemoteAction
    public static String getSchoolNamesFromFEProcessDistricts() {
        return getStudentFieldExperience().getSchoolNamesFromFEProcessDistrictsExtJSON();
    }
    
    

    @RemoteAction
    public static String getStateLicensesJSON( String state ) {
        return getStudentFieldExperience().getFEStateLicensesExtJSON( state );
    }

    @RemoteAction
    public static boolean setLicenseState( String state ) {
        return getStudentFieldExperience().setFELicenseState( state );
    }

    @RemoteAction
    public static boolean setCohort( ID cohort ) {
        return getStudentFieldExperience().setFECohort( cohort );
    }

    @RemoteAction
    public static boolean setLicenseGoal( Id licenseId ) {
        return getStudentFieldExperience().setFELicenseGoal( licenseId );
    }

    public String getVerifyPersonalInfoURL() {
        if ( this.personalInfoURL == null || Test.isRunningTest() ) {
          this.personalInfoURL = getStudentFieldExperience().getVerifyPersonalInfoURL();
        }
        return this.personalInfoUrl;
    }

    @RemoteAction
    public static String getFEExtJSON() {
        return getStudentFieldExperience().getActiveFieldExperienceExtJSON();
    }
    
    @RemoteAction
    public static boolean updateFieldExperience( String feJSON ) {
        try {
        return getStudentFieldExperience().updateFieldExperience(feJSON);
        } catch ( StudentFieldExperienceException  spe ) {
            ApexPages.addMessages(spe);
            return false;
        }
    }
    
    @RemoteAction
    public static List<FieldExperienceProcess__c> getFEPlacements( String feId ) {
        List<FieldExperienceProcess__c> placements = [SELECT Id,SchoolName__c,District__r.Name,HostTeacher__c FROM FieldExperienceProcess__c WHERE RecordType.DeveloperName = 'PlacementAttempt' AND FieldExperience__c = :String.escapeSingleQuotes(feId) AND PlacementOutcome__c = 'Accepted' AND (district__c != null OR school__c != null)];
        return placements;
    }
    
    @RemoteAction
    public static String addFEPAbsence( String fepJSON ) {
    	Map<String,String> fepFields = (Map<String,String>)JSON.deserialize(fepJSON, MAP<String,String>.class);
    	FieldExperienceProcess__c fep = new FieldExperienceProcess__c(); 
  		fep.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Absence' AND SObjectType = 'FieldExperienceProcess__c' LIMIT 1].Id;
  		fep.Student__c = fepFields.get('Student__c');
  		fep.Name = fepFields.get('Name');
  		fep.ClinicalSupervisor__c = fepFields.get('ClinicalSupervisor__c');
  		String hostTeacher = fepFields.get('HostTeacher__c');
  		fep.HostTeacher__c = hostTeacher==''? null : hostTeacher;
  		fep.AbsenceDescription__c = fepFields.get('AbsenceDescription__c');
  		fep.AbsenceReason__c = fepFields.get('AbsenceReason__c');
  		fep.FieldExperience__c = fepFields.get('FieldExperience__c');
  		fep.FirstDayAbsent__c = Date.parse(fepFields.get('FirstDayAbsent__c'));
  		fep.LastDayAbsent__c = Date.parse(fepFields.get('LastDayAbsent__c'));
  		fep.NumberofDaysAbsent__c = Double.valueOf(fepFields.get('NumberofDaysAbsent__c')); 
  		fep.Mentor__c = fepFields.get('Mentor__c'); 
	    insert fep;
        return fep.Id;
    }
    
    @RemoteAction
    public static String getRecordedAbsences( String feId ) {
        List<FieldExperienceProcess__c> absences = [SELECT Id,Name,RecordTypeId,RecordType.Name,AbsenceReason__c,AbsenceDescription__c,FirstDayAbsent__c,LastDayAbsent__c,NumberofDaysAbsent__c FROM FieldExperienceProcess__c WHERE RecordType.DeveloperName = 'Absence' AND FieldExperience__c = :String.escapeSingleQuotes(feId) ORDER BY FirstDayAbsent__c DESC];
        return JSON.serialize(absences);
    }
    
    @RemoteAction
    public static Id getCSRequestClinicalSupervisor( String feId ) {
        Id ClinicalSupervisor = [SELECT count() FROM FieldExperienceProcess__c WHERE CSRequest__c = 'Confirmed' AND RecordType.DeveloperName = 'CSRequest' AND FieldExperience__c = :String.escapeSingleQuotes(feId)] > 0? [SELECT ClinicalSupervisor__c FROM FieldExperienceProcess__c WHERE CSRequest__c = 'Confirmed' AND RecordType.DeveloperName = 'CSRequest' AND FieldExperience__c = :String.escapeSingleQuotes(feId) ORDER BY CreatedDate DESC LIMIT 1].ClinicalSupervisor__c: null;
        return ClinicalSupervisor;
    }
    
    private static FieldExperience__c getFE() {
        FieldExperience__c result;
        try {
          result = getStudentFieldExperience().getActiveFieldExperience();
          return result;
        } catch (FieldExperienceException fee) {
            ApexPages.addMessages(fee);
            result = new FieldExperience__c(Name='No valid field experience record for this student.');
            result.DTPhaseStatus__c = 'NOT FOUND';
            result.PCEPhaseStatus__c = 'NOT FOUND';
        } 
        return result;
    }
        
    public String getAvailableCohortsExtJSON() {
      List<Cohort__c> cohorts = [SELECT Id, Name from Cohort__c where AvailableForStudents__c = true];
      String jsonString ='[';
        boolean isFirst = true;
        for ( Cohort__c entry: cohorts ) {
                if ( isFirst ) {
                    isFirst = false;
                    jsonString += '{\"value\":\"'+entry.id+'\", \"name\":\"'+entry.Name+'\"}';
                } else {
                    jsonString += ',{\"value\":\"'+entry.id+'\", \"name\":\"'+entry.Name+'\"}';
                }
        }
        jsonString += ']';
        return jsonString;
    }
    
    public String getStatesExtJSON() {
      List<States__c> states = [SELECT Id, Name, StateFullName__c from States__c];
      String jsonString ='[';
        boolean isFirst = true;
        for ( States__c state: states ) {
                if ( isFirst ) {
                    isFirst = false;
                    jsonString += '{\"abbr\":\"'+state.Name+'\", \"name\":\"'+state.StateFullName__c+'\"}';
                } else {
                    jsonString += ',{\"abbr\":\"'+state.Name+'\", \"name\":\"'+state.StateFullName__c+'\"}';
                }
        }
        jsonString += ']';
        return jsonString;
    }
    
    public String getClassroomExperienceExtJSON() {
        Schema.DescribeFieldResult f = Schema.sObjectType.FieldExperience__c.fields.ClassroomExperience__c;
        f = f.getSObjectField().getDescribe();
        List<Schema.PicklistEntry> ple = f.getPicklistValues();
        String jsonString ='[';
        boolean isFirst = true;
        for ( Schema.PicklistEntry entry: ple ) {
                if ( isFirst ) {
                    isFirst = false;
                    jsonString += '{\"value\":\"'+entry.getValue()+'\", \"name\":\"'+entry.getLabel()+'\"}';
                } else {
                    jsonString += ',{\"value\":\"'+entry.getValue()+'\", \"name\":\"'+entry.getLabel()+'\"}';
                }
        }
        jsonString += ']';
        return jsonString;
    }
               
    public String getAbsenceReasonExtJSON() {
        Schema.DescribeFieldResult f = Schema.sObjectType.FieldExperienceProcess__c.fields.AbsenceReason__c;
        f = f.getSObjectField().getDescribe();
        List<Schema.PicklistEntry> ple = f.getPicklistValues();
        String jsonString ='[';
        boolean isFirst = true;
        for ( Schema.PicklistEntry entry: ple ) {
                if ( isFirst ) {
                    isFirst = false;
                    jsonString += '{\"value\":\"'+entry.getValue()+'\", \"name\":\"'+entry.getLabel()+'\"}';
                } else {
                    jsonString += ',{\"value\":\"'+entry.getValue()+'\", \"name\":\"'+entry.getLabel()+'\"}';
                }
        }
        jsonString += ']';
        return jsonString;
    }
               
    public blob fileAttachment { get; set; }
    public Id fieldExperienceId { get {
       this.FE = this.FE==null? getFE(): this.FE; 
       return this.FE.id;
    } set; }
    public String fieldExperienceName { get {
       this.FE = this.FE==null? getFE(): this.FE; 
       return this.FE.Name;
    } set; }
    public String fieldExperienceStatus { get {
       this.FE = this.FE==null? getFE(): this.FE; 
       return this.FE.PCEPhaseStatus__c;
    } set; }
    public String fileAttachmentName { get; set; }
    public String fileContentType { get; set; }
    public Integer toDoIndex { get; set; }
    public Boolean uploadSuccess { get; set; }
    private String personalInfoURL;
    private transient FieldExperience__c FE;
}