/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Nov 13 2012 @ 1354 hrs
 * Revised: Oct 30, security audit compliance: with sharing
 * Revised: Nov 13, added student performance survey section
 * 
 * NotesController for Notes.page and Javascript Custom Button dialogs
 *
 */ 
global with sharing class NotesController {

    private final static String noteSELECT = 'Select ShortText__c, WGUCreationDateTime__c, Text__c, SystemModstamp, SubType__c, Student__c, PIDM__c, Name, MentorId__c, Level1Image__c, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, InteractionID__c, Id, CreatedDate, CreatedById, Type__c, Author__c, Author__r.Name, CreatedBy.Name, AuthorPidm__c,PersonalizationActions__c,PersonalizationMenu__c,PersonalizationMenuSubType__c From WGUStudentNote__c';
    private final static String surveySELECT = 'Select EvidenceOfAcademicActivity__c, GoalPerformanceSinceLastCall__c, WGUStudentNote__c, Student__c, Name, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Id, CreatedDate, CreatedById, CreatedBy.Name From WGUStudentPerformanceSurvey__c';
    
    public NotesController(ApexPages.StandardController controller) {

    }

    public String getIE8SubHeader() {
      String userAgent = Test.isRunningTest()? '': ApexPages.currentPage().getHeaders().get('User-Agent').tolowercase();
      return (userAgent.contains('msie 8.0') || userAgent.contains('msie 7.0'))? 'ie8subheader': '';
    }
    
    public String getIE8Header() {
      String userAgent = Test.isRunningTest()? '': ApexPages.currentPage().getHeaders().get('User-Agent').tolowercase();
      return (userAgent.contains('msie 8.0') || userAgent.contains('msie 7.0'))? 'ie8header': '';
    }
    
    public String getIE8Footer() {
      String userAgent = Test.isRunningTest()? '': ApexPages.currentPage().getHeaders().get('User-Agent').tolowercase();
      return (userAgent.contains('msie 8.0') || userAgent.contains('msie 7.0')) ? 'ie8footer': '';
    }
    
    public String getLt(){
        return '<';
    }
    public String getGt(){
        return '>';
    }

    @RemoteAction
    webService static String getStudentJSONByContactId( String contactId ) {
        Id studentAccountId;
        if ( contactId != null ) {
             studentAccountId = [select count() from Contact where Id = :contactId]>0?[select AccountId from Contact where Id = :contactId LIMIT 1].AccountId: null;
        }
        if ( studentAccountId == null ) {
          throw new StudentException('No student found for Contact Id: ' + contactId);
        }
        return getStudentJSON( studentAccountId, false );
    }
    
    @RemoteAction
    webService static String getStudentJSONByStudentWGUId( String studentWGUId ) {
        Id studentAccountId;
        if ( studentWGUId != null ) {
             studentAccountId = [select count() from Contact where StudentID__c = :studentWGUId]>0?[select AccountId from Contact where StudentID__c = :studentWGUId LIMIT 1].AccountId: null;
        }
        if ( studentAccountId == null ) {
          throw new StudentException('No student found for WGU Student Id: ' + studentWGUId );
        }
        return getStudentJSON( studentAccountId, false );
    }
    
    @RemoteAction
    webService static String getStudentJSON( String studentAccountId, boolean isPidm ) {    
    
        List<Contact> student = new List<Contact>();
        if ( studentAccountId != null ) {
            if ( isPidm ) {
                student = [select count() from Contact where PIDM__c = :studentAccountId]==1?[select AccountId,Name,FirstName,LastName,Email,PIDM__c,Id,Phone,OtherPhone,MobilePhone,HomePhone,TermCode__c,MentorPidm__c,Mentor__c,StudentMentor__c,StudentRiskScore__c from Contact where PIDM__c = :studentAccountId LIMIT 1]: new List<Contact>();
            } else {
                student = [select count() from Contact where Accountid = :studentAccountId]==1?[select AccountId,Name,FirstName,LastName,Email,PIDM__c,Id,Phone,OtherPhone,MobilePhone,HomePhone,TermCode__c,MentorPidm__c,Mentor__c,StudentMentor__c,StudentRiskScore__c from Contact where AccountId = :studentAccountId LIMIT 1]: new List<Contact>();
            }
        }
        return JSONUtil.getJSON(student);
    }
        
    @RemoteAction
    webService static String getNoteJSONById( String noteId ) 
    {    
        List<WGUStudentNote__c> note;
        if ( noteId != null ) {
           String noteSOQL = noteSELECT + ' where id = \''+ String.escapeSingleQuotes(noteId) +'\' LIMIT 1';
           note= [select count() from WGUStudentNote__c where id = :noteId]==1? Database.query(noteSOQL): new List<WGUStudentNote__c>();
           if ( !note.isEmpty() ){
               note[0].Text__c = EncodingUtil.base64Encode( Blob.ValueOf( note[0].Text__c ) );
           }
        }
        return JSONUtil.getJSON(note);
    }
        
    @RemoteAction
    webService static String saveNoteJSON( String noteJSON ) {
    	System.debug('####### saveNoteJSON 1');
        WGUStudentNote__c pageNote = (WGUStudentNote__c)JSON.deserialize( noteJSON, WGUStudentNote__c.class );
        WGUStudentNote__c note = pageNote.Id == null? new WGUStudentNote__c(): new WGUStudentNote__c(Id=pageNote.Id); //use new note for saving/inserting for security abstraction 
        note.Text__c = EncodingUtil.base64Decode( pageNote.Text__c ).toString();
        String textString = String.valueOf(note.Text__c).replaceAll('//<.*?//>', '');
        Integer textLength = textString.length() > 254 ? 254 : textString.length()-1;
        note.ShortText__c = textString.subString(0,textLength);
        note.SubType__c = pageNote.SubType__c;
        note.Name = pageNote.Name;
        note.Type__c = pageNote.Type__c;
        note.Author__c = UserInfo.getUserId();
        note.AuthorPIDM__c = pageNote.AuthorPIDM__c;
        note.PIDM__c = pageNote.PIDM__c;
        note.Student__c = pageNote.Student__c;
        note.PersonalizationActions__c= pageNote.PersonalizationActions__c;
        note.PersonalizationMenu__c= pageNote.PersonalizationMenu__c;
        note.PersonalizationMenuSubType__c= pageNote.PersonalizationMenuSubType__c;
        if ( note.id == null ) {
          note.WGUCreationDateTime__c = System.now();
          if(note.Student__c!=null)
          {
          	Contact current = [select id, StudentRiskScore__c from contact where id = :note.Student__c]; 
          	note.StudentRiskValue__c = current.StudentRiskScore__c;
          }
    	  System.debug('####### saveNoteJSON -Insert'+note);
          insert note;
        } else {
    	  System.debug('####### saveNoteJSON -update'+note);
          update note;
        }
    	System.debug('####### saveNoteJSON 2');
        return getNoteJSONById(note.Id);
    }
        
   @RemoteAction
    webService static String getNotesJSONByOffset( String contactId, Integer offset )  {
        
        List<WGUStudentNote__c> notes = new List<WGUStudentNote__c>();
        Integer noteCount = 0;
        Integer batchSize = 50;
        if ( contactId != null ) {
          Id studentContactId = String.escapeSingleQuotes(contactId);
          noteCount = [select count() from WGUStudentNote__c where Student__c = :studentContactId];
          if ( noteCount != 0 ) {
               String noteSOQL = noteSELECT + ' where Student__c = \''+studentContactId+'\' order by WGUCreationDateTime__c DESC LIMIT '+String.valueOf(batchSize)+' OFFSET ' + string.ValueOf(offset);
               notes = Database.query(noteSOQL);
          } 
        }
        if ( !notes.isEmpty() ) {
          for ( WGUStudentNote__c note: notes ) {
            note.Text__c = EncodingUtil.base64Encode( Blob.ValueOf( note.Text__c==null?'':note.Text__c ) );
          }
        }
        return JSONUtil.getJSON(notes, ((offset+batchSize) >= noteCount), String.valueOf(offset + notes.size()) );
    }

    @RemoteAction
    webService static Integer getNotesCountByContactId( String contactId )  {        
        return [select count() from WGUStudentNote__c where Student__c = :contactId];
    }
 
    public String getNoteTypeJSON() {
        Schema.DescribeFieldResult f = Schema.sObjectType.WGUStudentNote__c.fields.Type__c;
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
    
    public String getNoteTypeFilterJSON() {
        Schema.DescribeFieldResult f = Schema.sObjectType.WGUStudentNote__c.fields.Type__c;
        f = f.getSObjectField().getDescribe();
        List<Schema.PicklistEntry> ple = f.getPicklistValues();
        String jsonString = '[{\"value\":\"'+'All'+'\", \"name\":\"'+'All'+'\"}';
        for ( Schema.PicklistEntry entry: ple ) {
            jsonString += ',{\"value\":\"'+entry.getValue()+'\", \"name\":\"'+entry.getLabel()+'\"}';
        }
        jsonString += ']';
        return jsonString;
    } 
    
    public String getNoteSubTypeMetaJSON() {
        //new winter '13 schema capabilities
        return JSON.serialize( Schema.sObjectType.WGUStudentNote__c.fields.SubType__c.getSObjectField().getDescribe() );
    } 
    //12-10 action subtype
    public String getActionTypeJSON() {
        Schema.DescribeFieldResult f = Schema.sObjectType.WGUStudentNote__c.fields.PersonalizationMenu__c;
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
    public String getActionSubTypeMetaJSON() {
        //new winter '13 schema capabilities
        return JSON.serialize( Schema.sObjectType.WGUStudentNote__c.fields.PersonalizationMenuSubType__c.getSObjectField().getDescribe() );
    } 
//******************************************************************************************
//******************************************************************************************
//********************** BEGIN STUDENT PERFORMANCE SURVEY SECTION **************************
//******************************************************************************************
//* Added November 13, 2012 by Paul Coleman
    
    /*public String getEvidenceOfAcademicActivityMetaJSON() {
        return JSON.serialize( Schema.sObjectType.WGUStudentPerformanceSurvey__c.fields.EvidenceOfAcademicActivity__c.getSObjectField().getDescribe() );
    } 
    
    public String getGoalPerformanceSinceLastCallMetaJSON() {
        return JSON.serialize( Schema.sObjectType.WGUStudentPerformanceSurvey__c.fields.GoalPerformanceSinceLastCall__c.getSObjectField().getDescribe() );
    }*/
    
   @RemoteAction
    webService static String getPerformanceSurveyJSONByOffset( String contactId, Integer offset )  {
        
        List<WGUStudentPerformanceSurvey__c> surveys = new List<WGUStudentPerformanceSurvey__c>();
        Integer surveyCount = 0;
        Integer batchSize = 50;
        if ( contactId != null ) {
          Id studentContactId = String.escapeSingleQuotes(contactId);
          surveyCount = [select count() from WGUStudentPerformanceSurvey__c where Student__c = :studentContactId];
          if ( surveyCount != 0 ) {
               String surveySOQL = surveySELECT + ' where Student__c = \''+studentContactId+'\' LIMIT '+String.valueOf(batchSize)+' OFFSET ' + string.ValueOf(offset);
               surveys = Database.query( surveySOQL );
          } 
        }
        return JSONUtil.getJSON(surveys, ((offset+batchSize) >= surveyCount), String.valueOf(offset + surveys.size()) );
    }

    @RemoteAction
    webService static String saveSurveyJSON( String surveyJSON )   {
        WGUStudentPerformanceSurvey__c pageSurvey = (WGUStudentPerformanceSurvey__c )JSON.deserialize( surveyJSON , WGUStudentPerformanceSurvey__c.class );
        WGUStudentPerformanceSurvey__c survey = pageSurvey.Id == null? new WGUStudentPerformanceSurvey__c (): new WGUStudentPerformanceSurvey__c (Id=pageSurvey.Id); //use new survey for saving/inserting for security abstraction 
        survey.EvidenceOfAcademicActivity__c = pageSurvey.EvidenceOfAcademicActivity__c;
        survey.GoalPerformanceSinceLastCall__c = pageSurvey.GoalPerformanceSinceLastCall__c;
        survey.Name = pageSurvey.Name;
        survey.Student__c = pageSurvey.Student__c;
        survey.WGUStudentNote__c = pageSurvey.WGUStudentNote__c;
        if ( survey.id == null ) {
          insert survey;
        } else {
          update survey;
        }
        String surveySOQL = surveySELECT + ' where Id = \'' + survey.Id + '\' LIMIT 1';
        return JSONUtil.getJSON(Database.query( surveySOQL ));
    }

//****************************************************************************************
//********************** END STUDENT PERFORMANCE SURVEY SECTION **************************
//****************************************************************************************
//****************************************************************************************


}