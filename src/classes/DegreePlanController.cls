public with sharing class DegreePlanController {

  public List<GradSelect> gradSelects {get; set;}
  public Integer completedcu {get;set;}
  public Integer currentcu {get; set;}
  public Integer futurecu {get;set;}
  public Integer transfercu {get;set;}
  public Integer totalCU {get;set;}
  public Decimal totalTuition {get;set;}
  public Integer completedtermsize {get;set;}
  public String courseId {get;set;}
  public String fromTermId {get;set;}
  public String toTermId {get;set;}
  public String insertAt {get;set;}
  public String currentPlanId {get;set;}
  public String currentPlanName {get;set;}
  public String planningPlanId {get;set;}
  public String planningPlanName {get;set;}
  public String ApprovalStatus {get;set;}
  public Date ApprovalDate {get;set;}
  public Date CurrentDate {get;set;}
  public Boolean IsApproved {get;set;}
  public String MentorNameWhoApproved {get;set;}
  public String MentorName {get;set;}
  public String MentorEmail {get;set;}
  public String StudentName {get;set;}
  public String modifyActionType {get;set;} // created modified
  public Date planModifyDate {get;set;}
  public Date planGraduationDate {get;set;}
  public Boolean includeCurrentTerm {get;set;}
  public Contact currentStudent {get;set;}
  public String UserName {get;set;}
  public String UserLogin {get;set;}
  public String PortalStudentUserLogin {get;set;}
  public ScenarioManagerViewModel scenarioManager {get;set;}
  public StudentTermViewModel currentTerm {get;set;}
  public List<StudentTermViewModel> terms {get; set;}
  public Map<String,StudentCourseViewModel> coursesMap {get; set;}
  public Map<String,StudentTermViewModel> termsMap {get; set;}
  public Map<String,StudentCourseViewModel> wguCourseToVM {get;set;}
  public LicenseChooserViewModel licenseChooser {get;set;}
  public EulaAcceptanceMessage eulaMessage {get;set;}
  public Boolean showPceButton {get;set;}
  public Boolean showNotesButton {get;set;}
  public Boolean checkForCoursesInWrongTerm;
  public boolean showPastTerms {
    get;set {
      if(terms != null) {
        for(StudentTermViewModel t : terms) {
          if(t.EndDate < Date.Today()
            && t.TermNumber != -1) {
            t.Visible = value;
          }
        }
      }
      this.showPastTerms = value;
    }
  }
  public Map<String,Tuition__c> p_tuitionMap;
  public static final Integer MINCUPERTERM = 12;
  public static final Integer MAXCUPERTERM = 32;
  public static final Integer MAXUNENROLLEDCUPERTERM = 18; // take little bites at a time, once you've enrolled and finish courses, grab more
  public static final Integer LOWEFFORT = 12;
  public static final Integer MEDIUMEFFORT = 14;
  public static final Integer HIGHEFFORT = 16;
  public static final Integer MINCUPERTERMGRAD = 8;
  public static final Integer MINCUPERTERMUNDERGRAD = 12;
  public static final Integer EFFORTLOWTHRESHOLD = 1;
  public static final Integer EFFORTMEDIUMTHRESHOLD = 3;
  public static final Integer EFFORTHIGHTHRESHOLD = 4;
  public static final Integer EFFORTNONEVALUE = 0;
  public static final Integer EFFORTLOWVALUE = 1;
  public static final Integer EFFORTMEDIUMVALUE = 2;
  public static final Integer EFFORTHIGHVALUE = 3;
  public ApprovalMessage approvalMessage {get;set;}
  public StudentMessage studentMessage {get;set;}
  public StudentMessage enrollMessage {get;set;}
  private Decimal tuitionPerTerm;
  private User currentUserSecure {
    get {
      return currentUserSecure;
    }
    set {
      currentUserSecure = value;
      currentUserPermissionSets = null;
    }
  }
  private Map<String,String> currentUserPermissionSets {
    get {
      if(currentUserPermissionSets == null) {
        currentUserPermissionSets = new Map<String,String>();
        List<PermissionSetAssignment> ps = [
          select Id,
          PermissionSet.Name,
          PermissionSet.Label
          from PermissionSetAssignment
          where AssigneeId = :UserInfo.getUserId()
        ];
        for(PermissionSetAssignment p : ps) {
       
          currentUserPermissionSets.put(p.PermissionSet.Name,p.PermissionSet.Label);
        }
      }
      return currentUserPermissionSets;
    }
    set;
  }
  public String UserAgent {get;set;}
  public String CareStatus {get;set;}
  public Decimal IEVersion {get;set;}
  public String spoofid {get;set;}
  public String action {get;set;}
  public Map<String,List<StudentAssessmentViewModel>> assessmentsInCourse {get;set;}
  public static Map<String,String> messages;
  public static Map<String, String> configs {
    get{
      if(configs==null) {
        configs=new  Map<String, String>();
        List <FDPConfig__c> figs=[select Name,Value__c from FDPConfig__c];
        for(FDPConfig__c c:figs) {
          configs.put(c.Name,c.Value__c);
        }
      }
      return configs;
    }
    set;
  }
  public static String cosurl {
    set;
    get {
        if (cosurl==null){
          cosurl=configs.get('CosURL');
        }
        return cosurl;
      }
    }
  static {
    messages = new Map<String,String>();
    messages.put('planNotApprovedMessage','The plan “[% planName %]” [% modifyActionType %] on [% modifyDate %] is available for review with the student.');
    messages.put('planNotApprovedPostMessage','Approve this plan only after you have discussed it with the student.');
    messages.put('planApprovedTermNotApproved','Term [% termNumber %] is available for review with the student.');
    messages.put('planApprovedTermNotApprovedPost','Approve this plan only after you have discussed it with the student.');
    messages.put('howeverMessage','However, ');
    messages.put('andMessage',' Additionally, ');
    messages.put('hasEmptyDatesMessage','there are courses that do not have dates. These courses will need to have dates before the term can be approved for enrollment.');
    messages.put('notEnoughCUs','the term is below the required full-time CUs. There are only [% competencyUnits %] CUs in the term, but you must have at least [% requiredNumCUs %].');
    messages.put('noCourses','there are no courses in the term. There should be at least [% requiredNumCUs %] CUs in the term.');
    messages.put('tooManyCUs','the term has [% competencyUnits %] CUs. It is recommended that the student begin the term with fewer than [% recommendedMaxCUs %] CUs. Once the student has completed 100% of those units you may accelerate additional courses as appropriate.');
    messages.put('planApprovedForStudent','[% mentorNameWhoApproved %] has approved “[% planName %]” on [% approvalDate %]. Please enroll in your term [% termNumber %] below.');
    messages.put('enrollGreenDialog','The term enrollment process is important because you are agreeing to pay tuition in full, complete the courses by the end of the term, and adhere to the communication protocol with your mentor. Once you enroll in these courses you are not eligible for a Term Break. All of these courses will be included on your transcript and will count for Satisfactory Academic Progress (SAP) if you are using Financial Aid.<br/><br/> To enroll these courses in term [% termNumber%] please click on the checkbox next to each course. Then click Enroll.<br/><br/>If you do not understand or agree to the terms listed above please contact your mentor as soon as possible.');
    messages.put('enrollGreenDialogEmptyDates','Term [% termNumber %] requires Start and End dates and mentor approval before you can begin the enrollment process.');
    messages.put('enrollGreenDialogUnapproved','The plan on Term [% termNumber %] must be approved by your mentor before you can enroll.');
    messages.put('nextTermEnrollNeedApproval','Before you can enroll in your next term on [% termStartShortDate %] you must have an approved plan. Contact your mentor [% mentorName %] as soon as possible.');
    messages.put('nextTermEnrollApproved','[% mentorName %] has approved your next term for enrollment. On [% termStartShortDate %], you will be able to enroll in Term [% termNumber %].  If you have any questions or want to revise your plan prior to enrollment contact your mentor [% mentorName %] for assistance.');
    messages.put('studentGraduated','This student has graduated therefore can no longer access myDegree Plan');
    messages.put('studentOnTermBreak','This student is currently on term break. They will not be able to access myDegree Plan until they have come back from term break.');
    messages.put('prospectNotYetAbleToView','When you begin the Education Without Boundaries Orientation you will access your Degree Plan here. Your personalized Degree Plan is a detailed blueprint of the courses, including the learning resources and assessments, that comprise your program.<br/><br/>Please contact your Enrollment Counselor if you have any questions about the Degree Plan or beginning the Education Without Boundaries Orientation.');
    messages.put('prospectCannotEnrollError','You are not yet able to enroll in your classes. If your term is starting in the next day, you may need to wait 24 hours before you can enroll.');
    messages.put('studentNotAbleToView',messages.get('prospectNotYetAbleToView'));
  }

  public class DegreePlanException extends Exception {}
  public class DegreePlanControllerException extends Exception {}
  public class TooManyDegreePlansException extends Exception {}
  public class PlanNameTooLongException extends Exception {}


  // Reviewed 3/19/2012
  public DegreePlanController() {
      UserAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
      IEVersion = 0.0;
      if(UserAgent != null) {
          List<String> agentStrings = UserAgent.split('; ',0);
          for(String s : agentStrings) {
            if(s.contains('MSIE')) {
                String possibleVersion = '';
                if(s.endsWith('b')) {
                    possibleVersion = s.substring(5,s.length()-1);
                } else {
                    possibleVersion = s.substring(5);
                }
                IEVersion = Decimal.valueOf(possibleVersion);
            }
         }
      }
      spoofid=null;
      totalCU = 0;
      totalTuition = 0;
      completedcu=0;
      currentcu=0;
      futurecu=0;
      terms=new List<StudentTermViewModel>();
      coursesMap=new Map<String,StudentCourseViewModel>();
      termsMap=new Map<String,StudentTermViewModel>();
      showPastTerms = false;
      includeCurrentTerm = true;
      checkForCoursesInWrongTerm = true;
      approvalMessage = new ApprovalMessage();
      studentMessage = new StudentMessage();
      enrollMessage = new StudentMessage();
      eulaMessage = new EulaAcceptanceMessage();
      showPceButton = false;
      showNotesButton = false;
  }

  // Reviewed 3/12/2012
  public PageReference initialize() {
       Contact student=getCurrentContactWithProgramCode() ;
      List<AllFDPpilot__c> pilots=[select id from AllFDPpilot__c where name=:student.pidm__c and isactive__C=true];
      if (pilots.size()>0) {
        PageReference reference=new PageReference(configs.get('jFDPURL')+student.pidm__c);
        reference.setRedirect(true);
        return reference;
       }
    try {
      String action = ApexPages.currentPage().getParameters().get('action');
      if(action == 'throwexception') {
        throw new DegreePlanException('Generically thrown exception.');
      }
      List<FDPMessage__c> mess = [select Name,Message__c from FDPMessage__c];
      for(FDPMessage__c m : mess) {
        messages.put(m.Name,m.Message__c);
      }
      if(configs.get('!OfflineNow!') != null) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,configs.get('!OfflineNow!'));
        ApexPages.addMessage(myMsg);
        return null;
      }
      if(configs.get('!GlobalMessage!') != null) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,configs.get('!GlobalMessage!'));
        ApexPages.addMessage(myMsg);
      }
      currentStudent = getCurrentContactWithProgramCode();
      checkForResetDegreePlan();
      //TODO: remove status checking to outside of the initialize method

      String currentStudentStatus = currentStudent.Status__c;
      if(currentStudentStatus == null)
        currentStudentStatus = 'AS';
      if(currentStudentStatus == 'IN') {
        if(CareStatus != null && CareStatus.contains('CLRD')
            && (
              (currentStudent.TermCode__c != null
              && FDPUtilities.getTermStartDateByCode(currentStudent.TermCode__c).addMonths(-1).addDays(14) <= Date.Today())
              || currentStudent.BannerStatus__c == 'FDPTestStudent'
              )
            ) {
          //show the degree plan

        } else if(CareStatus != null && CareStatus.contains('ENRL')) {
          //show the degree plan
        } else {
          ApexPages.Message myMsg = new ApexPages.message(ApexPages.Severity.INFO,messages.get('prospectNotYetAbleToView'));
          ApexPages.addMessage(myMsg);
          return null;
        }
      } else if(currentStudentStatus == 'TB' && currentlyOnTermBreak(currentStudent)) {
        ApexPages.Message myMsg = new ApexPages.message(ApexPages.Severity.INFO,messages.get('studentOnTermBreak'));
        ApexPages.addMessage(myMsg);
        return null;
      } else if(currentStudentStatus == 'IG') {
        ApexPages.Message myMsg = new ApexPages.message(ApexPages.Severity.INFO,messages.get('studentGraduated'));
        ApexPages.addMessage(myMsg);
        return null;
      } else if(currentStudentStatus != 'AS'&&currentStudentStatus != 'TB') {
        ApexPages.Message myMsg = new ApexPages.message(ApexPages.Severity.INFO,messages.get('studentNotAbleToView'));
        ApexPages.addMessage(myMsg);
        return null;
      }
      //TODO: load degree plan asynchronousely
      loadDegreePlan(currentStudent,null);
      if(checkForCoursesInWrongTerm) {
        moveCompletedOrFailedCoursesToCorrectTerm(currentStudent);
      }
      //TODO: load grad selects asynchronously
      loadGradSelects(currentStudent);
      deleteEmptyTerms(currentStudent);
      CurrentDate = Date.today();
      showPastTerms = false;
      // load this after the student clicks on the eula
      checkForTermIntervalChange();
      setEulaOnPage();
      licenseChooser = new LicenseChooserViewModel(currentStudent);
      if(spoofid != null) {
        licenseChooser.DisplayView = false;
        showNotesButton = true;
      }
      if(currentStudent.WGUDegreeProgram__r.HasFieldExp__c) {
        showPceButton = true;
      }
    } catch (Exception ex) {
      displayException(ex);
    }
    return null;
  }

  public Boolean currentlyOnTermBreak(Contact s) {
    List<StudentTermBreak__c> termBreaks = [select
      Name,
      Code__c,
      EffectiveTermCode__c,
      StartDate__c,
      EndDate__c,
      Student__c
      from StudentTermBreak__c
      where Student__c = :s.Id];
    for(StudentTermBreak__c stb : termBreaks) {
      if(stb.EffectiveTermCode__c <= FDPUtilities.generateTermCode(Date.Today())
          && stb.StartDate__c <= Date.Today()
          && stb.EndDate__c >= Date.Today()) {
        return true;
      }
    }
    return false;
  }

  public void checkForResetDegreePlan() {
    if(ApexPages.currentPage().getParameters().get('resetDegreePlan') != null) {
      if(currentUserPermissionSets.containsKey('FDPDeveloper')) {
        FDPUtilities.cleandegreeplanwithpidm(currentStudent.PIDM__c);
      } else {
        throw new DegreePlanException('You are not authorized to perform that action');
      }
    }
  }

  public void checkForTermIntervalChange() {
    if(currentTerm != null
        && currentTerm.StartDate != null
        && currentStudent.TermCode__c != null) {
      Integer studentInterval = FDPUtilities.getTermInterval(currentStudent.TermCode__c);
      Integer currentTermInterval = FDPUtilities.getTermInterval(currentTerm.StartDate);
      if(studentInterval != currentTermInterval) {
        Integer termCodeDiff = currentTerm.StartDate.monthsBetween(currentStudent.TermStartDate__c);
        List<StudentTerm__c> updateTerms =
          [select Id,Name,StartDate__c,EndDate__c,
            (select Id,StartDate__c,EndDate__c
             from StudentCourses__r
             where Status__c = 'Planned')
           from StudentTerm__c
           where Student__c = :currentStudent.Id
           and EndDate__c >= Today
           order by StartDate__c];
        List<StudentCourse__c> updateCourses = new List<StudentCourse__c>();
        for(StudentTerm__c t : updateTerms) {
          if(FDPUtilities.getTermEndDateFromStartDate(
                t.StartDate__c.addMonths(termCodeDiff)
              ) > Date.Today()
            ) {
            t.StartDate__c = t.StartDate__c.addMonths(termCodeDiff);
            t.EndDate__c = FDPUtilities.getTermEndDateFromStartDate(t.StartDate__c);
            t.Name = FDPUtilities.generateTermCode(t.StartDate__c);
            if(termsMap.containsKey(t.Id)) {
              termsMap.get(t.Id).StartDate = t.StartDate__c;
              termsMap.get(t.Id).EndDate = t.EndDate__c;
              termsMap.get(t.Id).Name = t.Name;
            }
            for(StudentCourse__c c : t.StudentCourses__r) {
              c.StartDate__c = null;
              c.EndDate__c = null;
              if(coursesMap.containsKey(c.Id)) {
                coursesMap.get(c.Id).StartDate = null;
                coursesMap.get(c.Id).EndDate = null;
              }
              updateCourses.add(c);
            }
          }
        }
        if(updateTerms.size() > 0) {
          update updateTerms;
        }
        if(updateCourses.size() > 0) {
          update updateCourses;
        }
      }
    }
  }

  public void setEulaOnPage() {
    List<StudentEulaAgreement__c> studentEulas = [
      select Name,WGUEula__c,Student__c,LastModifiedDate
      from StudentEulaAgreement__c
      where Student__c = :currentStudent.Id
      and Name = 'FDP'];
     List<WGUEula__c> eulas = [select Name,EulaText__c,Version__c
       from WGUEula__c
       where Name = 'FDP'
       order by Version__c];
     Boolean needToAgreeToEula = true;
     WGUEula__c latestEula = null;
     for(WGUEula__c eula : eulas) {
       if(latestEula == null
           || latestEula.Version__c < eula.Version__c) {
         latestEula = eula;
       }
     }
     if(latestEula == null) {
       eulaMessage.HideEverything = true;
     } else {
       eulaMessage.HideEverything = false;
     }
     StudentEulaAgreement__c currentEulaAgreement = null;
     for(StudentEulaAgreement__c su : studentEulas) {
       if(su.WGUEula__c != null
           && latestEula != null
           && su.WGUEula__c == latestEula.Id) {
         needToAgreeToEula = false;
         currentEulaAgreement = su;
       }
     }
     if(latestEula != null) {
       String text = '<div class="content clear-block" style="max-height:300px;overflow:auto;">';
       text += latestEula.EulaText__c;
       text += '</div>';
       eulaMessage.EulaText = text;
       eulaMessage.EulaId = latestEula.Id;
     } else {
       eulaMessage.EulaText = 'Eula text not found';
     }
     if(needToAgreeToEula) {
       eulaMessage.Checked = false;
       if(spoofid == null) {
         //student
         eulaMessage.SideText = '&larr; Please read and accept.';
         eulaMessage.ShowButtons = true;
         eulaMessage.Disabled = false;
       } else {
         eulaMessage.SideText = '&larr; To be accepted by the Student.';
         eulaMessage.ShowButtons = false;
         eulaMessage.Disabled = true;
       }
     } else {
       eulaMessage.Disabled = true;
       eulaMessage.Checked = true;
       eulaMessage.SideText = 'Accepted on ' + FDPUtilities.formatDateLong(currentEulaAgreement.LastModifiedDate.date());
       eulaMessage.ShowButtons = false;
     }
  }

  public static String formatMessage(String format,Map<String,String> arguments) {
            String output = format;
            for(String key:arguments.keySet()) {
                String rData = arguments.get(key);
                rData = rData == null ? '' : rData;
                output = output.replaceAll('\\[\\%\\s*'+key+'\\s*\\%\\]',rdata);
            }
            return output;
    }

  public with sharing class EulaAcceptanceMessage {
    public String EulaText {get;set;}
    public Boolean Checked {get;set;}
    public Boolean Disabled {get;set;}
    public Boolean ShowButtons {get;set;}
    public String SideText {get;set;}
    public String EulaId {get;set;}
    public Boolean HideEverything {get;set;}

    public EulaAcceptanceMessage() {
    }
  }

    public with sharing class StudentMessage {
        public Boolean Visible {get;set;}
        public String Message {get;set;}
        public String Icon {get;set;}
        public String Color {get;set;}
        public String TermId {get;set;}
        public Boolean ButtonEnabled {get;set;}
        public StudentMessage() {
            Visible = false;
            Message = '';
            Icon = '';
            Color = 'blue';
            TermId = '';
            ButtonEnabled = true;
        }
    }

    public with sharing class ApprovalMessage {
        public Boolean Visible {get;set;}
        public String Message {get;set;}
        public String ButtonText {get;set;}
        public Boolean ButtonEnabled {get;set;}
        public Boolean ButtonVisible {get;set;}
        public String TermId {get;set;}
        public ApprovalMessage() {
            Message = 'Please approve of the plan.';
            ButtonText = 'Approve for Enrollment';
            ButtonEnabled = false;
            Visible = false;
            ButtonVisible = true;
            TermId = '';
        }
    }

  public void updateStudentMessage() {
    studentMessage.Visible = false;
    enrollMessage.Visible = false;
    if(spoofid != null) {
        return;
    }
    Map<String,String> args = new Map<String,String>();
    String message = '';
    String eMessage = '';
    if(IsApproved && (currentTerm == null || currentTerm.numUnenrolledCourses > 0)) {
        studentMessage.Visible = true;
        message += messages.get('planApprovedForStudent');
        args.put('mentorNameWhoApproved',mentorNameWhoApproved);
        args.put('planName',planningPlanName);
        args.put('approvalDate',formatLongDate(ApprovalDate));
        Integer termNumber = currentTerm == null ? 1 : (Integer)currentTerm.TermNumber;
        args.put('termNumber',String.valueOf(currentTerm));
        args.put('mentorName',mentorName);
    }
    for(StudentTermViewModel t : terms) {
        if(t.StartDate <= Date.Today() && t.EndDate >= Date.Today() && t.numUnenrolledCourses >0) {
            enrollMessage.Visible = true;
            enrollMessage.TermId = t.Id;
            enrollMessage.Color = 'green';
            args.put('termNumber',String.valueOf((Integer)t.TermNumber));
            args.put('numUnenrolledCourses',String.valueOf((Integer)t.numUnenrolledCourses));
            if(!t.NoEmptyDates) {
                eMessage = messages.get('enrollGreenDialogEmptyDates');
                enrollMessage.ButtonEnabled = false;
            } else if(!t.Approved) {
                eMessage = messages.get('enrollGreenDialogUnapproved');
                enrollMessage.ButtonEnabled = false;
            } else {
                eMessage = messages.get('enrollGreenDialog');
            }
            break;
        } else if(t.StartDate <= Date.Today().addMonths(1) && t.EndDate >= Date.Today().addMonths(1) && t.numUnenrolledCourses >0) {
            studentMessage.Visible = true;
            studentMessage.Color = 'blue';
            studentMessage.TermId = t.Id;
            enrollMessage.Visible = true;
            enrollMessage.TermId = t.Id;
            enrollMessage.Color = 'green';
            args.put('termNumber',String.valueOf((Integer)t.termNumber));
            args.put('mentorName',mentorName);
            args.put('termStartShortDate',formatShortDate(t.StartDate));
            if(!t.NoEmptyDates || !t.Approved) {
                eMessage = messages.get('nextTermEnrollNeedApproval');
                message = eMessage;
            } else {
                eMessage = messages.get('nextTermEnrollApproved');
                message = eMessage;
            }
            enrollMessage.ButtonEnabled = false;
            break;
        }
    }
    studentMessage.Message = formatMessage(message,args);
    enrollMessage.Message = formatMessage(eMessage,args);
  }

  //This will be run at the end of loadPlan
  public void updateApprovalMessage() {
    Map<String,String> args = new Map<String,String>();
    args.put('mentorName',mentorName);
    args.put('studentName',studentName);
    args.put('planName',planningPlanName);
    args.put('modifyActionType',modifyActionType);
    args.put('modifyDate',formatLongDate(planModifyDate));
    String message = '';
    String appendMessage = '';
    approvalMessage.TermId = '';
    approvalMessage.Visible = false;
    approvalMessage.ButtonEnabled = true;

    User currentUser = getCurrentUserSecure();
    if(currentUser.userType != 'Standard') {
        return;
    }
    if(!IsApproved) {
        message += messages.get('planNotApprovedMessage');
        appendMessage = messages.get('planNotApprovedPostMessage');
        approvalMessage.Visible = true;
    }

    for(StudentTermViewModel t : terms) {
      if (t.startdate==null)continue;
        if((!t.Approved && t.startDate <= Date.Today() && t.EndDate >= Date.Today())
        ||
        (!t.Approved && t.StartDate <= Date.Today().addMonths(1) && t.EndDate >= Date.Today().addMonths(1))) {
            approvalMessage.TermId = t.Id;
            if(IsApproved && !t.Approved) {
                args.put('termNumber',String.valueOf((Integer)t.TermNumber));
                approvalMessage.Visible = true;
                message += messages.get('planApprovedTermNotApproved');
                appendMessage = messages.get('planApprovedTermNotApprovedPost');
            }
            Integer requiredCUs = currentStudent.WGUDegreeProgram__r.ProgramLevel__r.Name == 'GR' ? MINCUPERTERMGRAD : MINCUPERTERMUNDERGRAD;
            Boolean notEnoughCUs = t.cu < requiredCUs;
            Boolean tooManyCUs = t.unenrolledCUs > MAXUNENROLLEDCUPERTERM;
            if(!t.NoEmptyDates) {
                message += ' ' + messages.get('howeverMessage');
                message += ' ' + messages.get('hasEmptyDatesMessage');
                approvalMessage.ButtonEnabled = false;
                if(notEnoughCUs) {
                    message += ' ' + messages.get('andMessage');
                    if(t.unenrolledCUs == 0) {
                      message += ' ' + messages.get('noCourses');
                    } else {
                      message += ' ' + messages.get('notEnoughCUs');
                    }
                    args.put('competencyUnits',String.valueOf((Integer)t.unenrolledCUs));
                    args.put('requiredNumCUs',String.valueOf(requiredCUs));
                } else if(tooManyCUs) {
                    message += ' ' + messages.get('andMessage');
                    message += ' ' + messages.get('tooManyCUs');
                    args.put('competencyUnits',String.valueOf((Integer)t.unenrolledCUs));
                    args.put('recommendedMaxCUs',String.valueOf(MAXUNENROLLEDCUPERTERM));
                }
            } else {
                if(notEnoughCUs) {
                    message += ' ' + messages.get('howeverMessage');
                    if(t.unenrolledCUs == 0) {
                      message += ' ' + messages.get('noCourses');
                    } else {
                      message += ' ' + messages.get('notEnoughCUs');
                    }
                    args.put('competencyUnits',String.valueOf((Integer)t.unenrolledCUs));
                    args.put('requiredNumCUs',String.valueOf(requiredCUs));
                } else if(tooManyCUs) {
                    message += ' ' + messages.get('howeverMessage');
                    message += ' ' + messages.get('tooManyCUs');
                    args.put('competencyUnits',String.valueOf((Integer)t.unenrolledCUs));
                    args.put('recommendedMaxCUs',String.valueOf(MAXUNENROLLEDCUPERTERM));
                }
            }
            break;
        }
    }
    message += ' ' + appendMessage;
    approvalMessage.Message = formatMessage(message,args);
    updateStudentMessage();
  }

  public PageReference deleteDegreePlan() {
   try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        date grad=null;
        if(ApexPages.currentPage().getParameters().get('degreePlanId') != null) {
            list<StudentDegreeplans__C>plans=[select isapproved__C from StudentDegreeplans__C where id =:ApexPages.currentPage().getParameters().get('degreePlanId') ];
            if (plans.size()==1){
                if (plans[0].isapproved__C){//if delete approved then we need to update currentplan
                      Studentterm__C maxterm = [select id, enddate__C,(select enddate__C from studentcourses__r where enddate__C!=null order by enddate__C desc limit 1) from studentterm__C
                    where StudentDegreePlan__c=:currentplanid order by enddate__C desc limit 1];
                    
                    if (maxterm.studentcourses__r.size()>0&&maxterm.studentcourses__r[0].enddate__C!=null) grad=maxterm.studentcourses__r[0].enddate__C;
                    else grad =maxterm.enddate__C;
                    studentdegreeplans__C currentplan=[select plannedgraduationdate__C, id from studentdegreeplans__C where id =:currentplanid];
                    if (currentplan.plannedgraduationdate__C!=grad){
                        currentplan.plannedgraduationdate__C=grad;
                    update currentplan;
                    }
                
                }
                FDPUtilities.deletePlan(ApexPages.currentPage().getParameters().get('degreePlanId'));
            }
            loadDegreePlan(currentStudent,null);
            if (grad!=null){
               createFDPapprovalGrad(grad);
            }
            updateApprovalMessage();
        } else {
            throw new DegreePlanException('Need degree plan id to delete');
        }
    } catch (Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public PageReference deleteAllPlans() {
    try {
      FDPUtilities.checkThrowExceptionTest();
      currentUserSecure = null;
      User currentUser = getCurrentUserSecure();
      if(currentUser.userType == 'Standard') {
        FDPUtilities.cleandegreeplanwithpidm(currentStudent.PIDM__c);
        loadDegreePlan(currentStudent,null);
        updateApprovalMessage();
      } else {
        throw new DegreePlanException('Cannot delete plans.');
      }
    } catch(Exception ex) {
      displayException(ex);
    }
    return null;
  }

  public PageReference saveStudentLicense() {
    try {
        FDPUtilities.checkThrowExceptionTest();
      currentUserSecure = null;
      string licenseId = ApexPages.currentPage().getParameters().get('licenseId');
     currentStudent =getCurrentContactWithProgramCode();
      List<StudentLicenseHistory__c> licenses = [select Id
      from StudentLicenseHistory__c
      where Student__c = :currentStudent.Id];
      List<StudentLicenseHistory__c> upsertLicenses = new List<StudentLicenseHistory__c>();
      List<StudentLicenseHistory__c> deleteLicenses = new List<StudentLicenseHistory__c>();
      if(licenses.size() > 0) {
        for(StudentLicenseHistory__c l : licenses) {
          if(upsertLicenses.size() > 0)
            deleteLicenses.add(l);
          else {
            l.WGUStateLicensure__c=licenseId;
            upsertLicenses.add(l);
          }
        }
      } else {
        StudentLicenseHistory__c l = new StudentLicenseHistory__c(Student__c=currentStudent.Id,WGUStateLicensure__c=licenseId);
        upsertLicenses.add(l);
      }
      upsert upsertLicenses;
      if(deleteLicenses.size() > 0)
        delete deleteLicenses;
      FDPUtilities.refreshNonDegreeRequirements(currentStudent,spoofid);
      loadDegreePlan(currentStudent,null);
    } catch(Exception ex) {
      displayException(ex);
    }
    return null;
  }

  public PageReference loadGradSelects() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
    if(ApexPages.currentPage().getParameters().get('includeCurrentTerm')!=null)
      includeCurrentTerm = Boolean.valueOf(ApexPages.currentPage().getParameters().get('includeCurrentTerm'));
    loadGradSelects(getCurrentContactWithProgramCode());
    } catch (Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public PageReference acceptEula() {
    try {
        FDPUtilities.checkThrowExceptionTest();
      currentUserSecure = null;
      User u = getCurrentUserSecure();
      Contact c = getCurrentContactWithProgramCode();
      if(u != null && c.Id == u.ContactId) {
        StudentEulaAgreement__c sua = new StudentEulaAgreement__c();
        sua.WGUEula__c = eulaMessage.EulaId;
        sua.Student__c = c.Id;
        sua.Name = 'FDP';
        insert sua;
        eulaMessage.SideText = 'Accepted on &nsbp;' + String.valueOf(c.EulaAgreementDate__c);
        eulaMessage.Checked = true;
        eulaMessage.Disabled = true;
        eulaMessage.ShowButtons = false;
      } else {
        throw new DegreePlanException('User does not have a contact record');
      }
    } catch(Exception ex) {
      displayException(ex);
    }
    return null;
  }

  public void displayException(Exception ex) {
    String additionalInfo = '';
    Contact c = getCurrentContactWithProgramCode();
    if(c != null && c.PIDM__c != null) {
      additionalInfo = 'pidm: \'' + c.PIDM__c + '\'';
    }
    String errorCode = UnhandledExceptionLogger.logError(ex,'Flexible Degree Plan',additionalInfo);
    String m = 'Oops! We had a problem accessing your degree plan. Please contact the helpdesk at (877) 435-7948 option 2. You may be asked to reference the following number: ' + errorCode;
    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,m,ex.getMessage());
    ApexPages.addMessage(myMsg);
  }

  public PageReference loadGradSelects(Contact student) {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        gradSelects = getGradSelects(student);
    } catch(Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public PageReference UpdateStartAndEnddateAndReload() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        String coid = ApexPages.currentPage().getParameters().get('dateCourseId');
        String fromdate = ApexPages.currentPage().getParameters().get('fromDate');
        String enddate = ApexPages.currentPage().getParameters().get('endDate');
        updateStartAndEnddate(coid, fromdate, enddate);
        updateApprovalMessage();
        updateStudentMessage();
    } catch (Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public PageReference UpdateStartAndEnddate() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        String coid = ApexPages.currentPage().getParameters().get('dateCourseId');
        String fromdate = ApexPages.currentPage().getParameters().get('fromDate');
        String enddate = ApexPages.currentPage().getParameters().get('endDate');
        updateStartAndEnddate(coid, fromdate, enddate);
    } catch (Exception ex) {
        displayException(ex);
    }
   return null;
  }

  public PageReference approveTerm() {
    try {
      FDPUtilities.checkThrowExceptionTest();
      currentUserSecure = null;
      String status = ApexPages.currentPage().getParameters().get('termApprovalStatus');
      String termId = ApexPages.currentPage().getParameters().get('termId');
      User currentUser = getCurrentUserSecure();
      if(currentUser.userType == 'Standard') {
        StudentTerm__c term;
        if(termId != '' && termId != null) {
          term = [select Approved__c,ApprovalStatus__c,ApprovalDate__c,Name,
            ApprovalDateTime__c
            from StudentTerm__c
            where Id =:termId];
          term.Approved__c = true;
          term.ApprovalStatus__c = 'Mentor Approved';
          term.ApprovalDate__c = Date.Today();
          term.ApprovalDateTime__c = Datetime.now();
          StudentTermViewModel t = termsMap.get(termId);
          t.Approved = true;
          t.ApprovalStatus = 'Mentor Approved';
          t.ApprovalDate = Date.Today();
        }

        List<StudentDegreePlans__c> plans = [select Name,
          ApprovalDate__c,
          ApprovalStatus__c,
          ApprovedBy__c,
          plannedgraduationdate__C,
          (select Name,
          Approved__c,
          ApprovalStatus__c,
          ApprovalDate__c,
          ApprovalDateTime__c
          from StudentTerms__r)
          from StudentDegreePlans__c
          where Student__c = :currentStudent.Id];
         planGraduationDate=terms[terms.size()-1].getGradDate();
        List<StudentTerm__c> unapproveTerms = new List<StudentTerm__c>();
        for(StudentDegreePlans__c plan : plans) {
            plan.plannedgraduationdate__C=planGraduationDate;
          if(plan.Id == planningPlanId) {
             plan.ApprovedBy__c = currentUser.Id;
             plan.IsApproved__c = status == 'Mentor Approved' || status == 'Registrar Approved' ? true : false;
             plan.ApprovalStatus__c = status;
             plan.ApprovalDate__c = Date.Today();
             // Update the view model
             MentorNameWhoApproved = currentUser.Name;
             ApprovalStatus = status;
             IsApproved = plan.IsApproved__c;
             ApprovalDate = Date.Today();
             scenarioManager.markPlanApprovalStatus(planningPlanId,status);
          } else if(status == 'Mentor Approved' || status == 'Registrar Approved') {
            plan.ApprovedBy__c = null;
            plan.IsApproved__c = false;
            plan.ApprovalStatus__c = 'Unapproved by Default';
            plan.ApprovalDate__c = Date.Today();
            for(StudentTerm__c pt : plan.StudentTerms__r) {
              if(pt.Approved__c) {
                pt.Approved__c = false;
                pt.ApprovalDate__c = null;
                pt.ApprovalDateTime__c = null;
                pt.ApprovalStatus__c = 'Pending Mentor Approval';
                unapproveTerms.add(pt);
              }
            }
             //update plan.StudentTerms__r;
            scenarioManager.markPlanApprovalStatus(plan.Id,'Unapproved by Default');
          }
        }
        List<FDPApproval__c> deletableApprovals = [select Name
          from FDPApproval__c
          where Student__c = :currentStudent.Id
          and Name = :term.Name
          and UsedForEnrollment__c = false];
        try {
          delete deletableApprovals;
        } catch(System.DmlException ex) {
          for(Integer i=0;i<ex.getNumDml();i++) {
            if(ex.getDmlType(i) == StatusCode.ENTITY_IS_DELETED) {
              // no need for complaint if it's already deleted
            } else {
              throw ex;
            }
          }
        }
        FDPApproval__c ap = new FDPApproval__c();
        ap.Student__c = currentStudent.Id;
        ap.ProgramCode__c = currentStudent.ProgramCode__c;
        for(StudentTermViewModel t : terms) {
          if(t.Id == termId) {
            //this is our term
            ap.Name = t.Name;
            ap.TermNumber__c = Integer.valueOf(t.TermNumber);
          }
        }
        ap.CatalogTerm__c = currentStudent.ProgramCatalogTerm__c;
        ap.UsedForEnrollment__c = false;
        ap.CompletedTerm__c = completedTermSize;
        ap.TotalTerms__c = terms.size();
        if (spoofid!=null)
        ap.OwnerId = spoofid;
        if(transferCU>0) {
          ap.CompletedTerm__c--;
          ap.TotalTerms__c--;
        }
        ap.GraduationDate__c = terms[terms.size()-1].getGradDate();    
        ap.MentorNotes__c = 'FDP Planned Graduation date update';
        ap.CURegistered__c=0;        
        insert ap;

        update plans;
        update unapproveTerms;
        if(term != null) {
          update term;
        }
        updateApprovalMessage();
      }
    } catch(Exception ex) {
      displayException(ex);
    }
    return null;
  }

  public PageReference enrollCourses() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
    String courseIdsJson = ApexPages.currentPage().getParameters().get('courseIdsJson');
    List<String> courseIds = (List<String>)JSON.deserialize(courseIdsJson, List<String>.class);
    List<StudentCourse__c> courses = [select Name, TermSequence__c,CourseType__c,
      StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
      StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.BannerCode__c,
      StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CCN__c,
      StudentCourseVersion__r.WGUCourseVersion__r.CourseOfStudyId__c,
      StudentCourseVersion__r.StudentCompletionCourse__r.Status__c,
      StudentTerm__r.Name,
      StudentTerm__r.TermNumber__c,
      StudentTerm__r.StartDate__c,
      StudentTerm__r.EndDate__c,
      StudentTerm__r.StudentDegreePlan__r.Name,
      StudentTerm__r.StudentDegreePlan__r.IsApproved__c
      from StudentCourse__c
      where Id in :courseIds
      and Status__c = 'Planned'];
    Boolean coursesValidForEnrollment = true;
    List<Map<String, Object>> coursesToEnroll = new List<Map<String, Object>>();
    Contact student = getCurrentContactWithProgramCode();
    if(student.Status__c == 'IN') {
      throw new DegreePlanControllerException(messages.get('prospectCannotEnrollError'));
    }
    Decimal tcu=0;
    for(StudentCourse__c course : courses) {
        if(course.StudentTerm__r.StartDate__c > Date.Today() // Term can't be in the future
          || course.StudentTerm__r.EndDate__c < Date.Today() // Term can't be in the past
          //TODO: After mentor approval is implemented
          // The following should change to make it so only the approved plan is able
          // To be enrolled
          || !course.StudentTerm__r.StudentDegreePlan__r.IsApproved__c  // Must be an approved plan
          || spoofid != null // only student can enroll
          ) {
          coursesValidForEnrollment = false;

        }
        else {
            // Add course to list to be sent to enroll rest service
            Map<String, Object> model = new Map<String, Object>();
            model.put('bannercode', course.Name);
            model.put('pidm', student.PIDM__c);
            model.put('sequence', course.TermSequence__c);
            model.put('termCode', course.StudentTerm__r.Name);
            model.put('termNumber', course.StudentTerm__r.TermNumber__c);
            coursesToEnroll.add(model);
        }
    }
    if(coursesValidForEnrollment) {
        String mentorApprovalMessage = 'Enrolled student in ';
        for(StudentCourse__c course : courses) {
            coursesMap.get(course.Id).Status = 'Submitted';
            termsMap.get(course.StudentTerm__r.Id).NumUnenrolledCourses--;
            mentorApprovalMessage += course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.BannerCode__c + ', ';
            if( course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__c!=null)
            tcu+=course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c;
            course.Status__c = 'Submitted';
            course.EnrollDate__c = Date.Today();
            coursesMap.get(course.Id).EnrollDate = course.EnrollDate__c;
        }
        List<StudentDegreePlans__c> plans = [select Name,CurrentPlan__c,
          (
            select StartDate__c,EndDate__c,Name,TermNumber__c
            from StudentTerms__r
            order by Name
          )
          from StudentDegreePlans__c
          where Student__c = :currentStudent.Id];
        List<StudentTerm__c> previousTerms = [select Name,
         StudentDegreePlan__c,
         TermNumber__c
         from StudentTerm__c
         where StudentDegreePlan__r.CurrentPlan__c = true
         and Student__c = :currentStudent.Id
         and EndDate__c < Today
         order by Name];
         Integer termNum = 1;
         List<StudentTerm__c> update_terms = new List<StudentTerm__c>();
        for(StudentTerm__c previousTerm : previousTerms) {
          if(previousTerm.Name == '000000') {
            previousTerm.TermNumber__c = 0;
          } else if(previousTerm.Name == '111111') {
            previousTerm.TermNumber__c = -1;
          } else {
            previousTerm.TermNumber__c = termNum++;
          }
          previousTerm.StudentDegreePlan__c = planningPlanId;
          update_terms.add(previousTerm);
        }
        List<StudentCourse__c> fixedCoursesInCurrentTerm = [select Name,coursetype__C,
          StudentTerm__c
          from StudentCourse__c
          where StudentTerm__r.StartDate__c <= Today
          and StudentTerm__r.EndDate__c >= Today
          and StudentTerm__r.StudentDegreePlan__r.CurrentPlan__c = true
          and Student__c = :currentStudent.Id
          and Status__c in ('Completed','Enrolled','Submitted')
        ];
        StudentDegreePlans__c currentPlan;
        List<StudentDegreePlans__c> deletePlans = new List<StudentDegreePlans__c>();
        StudentTerm__c currentTermInNewPlan;
        for(StudentDegreePlans__c plan : plans) {
            if(plan.Id == planningPlanId) {
                plan.Name = 'Current Plan';
                plan.CurrentPlan__c = true;
                currentPlan = plan;
                for(StudentTerm__c t : plan.StudentTerms__r) {
                    if(t.StartDate__c <= Date.Today() && t.EndDate__c >= Date.Today()) {
                        currentTermInNewPlan = t;
                    }
                }
            } else {
                deletePlans.add(plan);
            }
        }
        currentTermInNewPlan.TermNumber__c = termNum;
        update_terms.add(currentTermInNewPlan);
        FDPApproval__c ap = null;
        List<FDPApproval__c> approvals = [select Name,UsedForEnrollment__c,MentorNotes__c,CUregistered__C
          from FDPApproval__c
          where Student__c = :currentStudent.Id
          and Name = :currentTermInNewPlan.Name
          and UsedForEnrollment__c = false];
        if(approvals.size() == 0) {
          throw new DegreePlanException('Error enrolling, could not verify mentor approval. Have your mentor try to approve the plan or a copy of the plan again.');
        }
        List<FDPApproval__c> deleteExtraApprovals = new List<FDPApproval__c>();
        for(FDPApproval__c appr: approvals) {
          if(ap == null) {
            ap = appr;
          } else {
            deleteExtraApprovals.add(appr);
          }
        }
        ap.UsedForEnrollment__c = true;
        ap.MentorNotes__c = mentorApprovalMessage;
        ap.CURegistered__c=tcu;
        for(StudentCourse__c completedCourse : fixedCoursesInCurrentTerm) {
            completedCourse.StudentTerm__c = currentTermInNewPlan.Id;
            courses.add(completedCourse);
        }
        List<StudentTerm__c> deleteTerms = [select Name
          from StudentTerm__c
          where StudentDegreePlan__c in :deletePlans
          and (
            StudentDegreePlan__r.CurrentPlan__c != true or
            EndDate__c >= Today
          )];
        List<StudentCourse__c> deleteCourses = [select Name
          from StudentCourse__c
          where StudentTerm__c in :deleteTerms
          and Id not in :fixedCoursesInCurrentTerm];
        delete deleteCourses;
        delete deleteTerms;
        delete deletePlans;
        delete deleteExtraApprovals;
        update currentPlan;
        update update_terms;
        update courses;
        update ap;
        loadDegreePlan(currentStudent,null);
        updateStudentMessage();
    } else {
        throw new DegreePlanException('Cannot enroll.');
    }
    } catch(Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public void updateStartAndEnddate(String coid, String fromdate, String enddate){
    StudentCourse__c scourse =
      [select id, StartDate__c, EndDate__c,
       StudentTerm__r.Approved__c,
       student__C,
       StudentTerm__r.studentdegreeplan__r.IsApproved__c,
        StudentTerm__r.studentdegreeplan__r.currentplan__C,
       StudentTerm__c,coursetype__C
       from StudentCourse__c
       where Id = :coid];
       User currentUser = getCurrentUserSecure();
    //Only a mentor or employee can approve a plan
    if (currentUser.userType != 'Standard' && scourse.StudentTerm__r.Approved__c) {
        throw new DegreePlanException('Student cannot change start and end dates once a term has been approved.');
    }
   StudentCourseViewModel course = coursesMap.get(coid);
   if(fromdate != null && fromdate.length() > 0) {
       course.StartDate = Date.parse(fromdate);
       scourse.StartDate__c = course.StartDate;
   }
   if(enddate != null && enddate.length() > 0) {
       course.EndDate = Date.parse(enddate);
       scourse.EndDate__c = course.EndDate;
   }
   StudentTermViewModel term = termsMap.get(scourse.StudentTerm__c);
   term.NoEmptyDates = true;
   for(StudentCourseViewModel c : term.RemainingCourses) {
     if(c.StartDate == null || c.EndDate == null) {
        term.NoEmptyDates = false;
     }
   }
  
   update scourse;
    if ((term==terms[terms.size()-1] )&& ((scourse.StudentTerm__r.studentdegreeplan__r.isApproved__c==true)||(scourse.StudentTerm__r.studentdegreeplan__r.currentplan__c==true))){//last term
        
        date grad=term.getGradDate();
        if (course.EndDate ==grad){
             List<StudentDegreePlans__c> plans = [select Name,id,PlannedGraduationDate__c
            from StudentDegreePlans__c
            where Student__c = :scourse.student__C and (currentplan__C=true or isapproved__C=true) ];
            if(! ((scourse.StudentTerm__r.studentdegreeplan__r.currentplan__c==true)||plans.size()>1)){
            //if we are on current plan and there is an approved plan that is not current plan
            }else{//@addfdpapproval
                    delete [select id from fdpapproval__C where UsedForEnrollment__c = false and Student__c = :scourse.student__C];
                    FDPApproval__c ap = new FDPApproval__c();
                    ap.Student__c = currentStudent.Id;
                    ap.ProgramCode__c = currentStudent.ProgramCode__c;
                    for(StudentTermViewModel t : terms) {
                      if(t.StartDate <= Date.today() && t.EndDate >= Date.today()) {
                        //this is our term
                        ap.Name = t.Name;
                        ap.TermNumber__c = Integer.valueOf(t.TermNumber);
                      }
                    }
                    ap.CatalogTerm__c = currentStudent.ProgramCatalogTerm__c;
                    ap.UsedForEnrollment__c = false;
                    ap.CompletedTerm__c = completedTermSize;
                    ap.TotalTerms__c = terms.size();
                    if (spoofid!=null)
                    ap.OwnerId = spoofid;
                    if(transferCU>0) {
                      ap.CompletedTerm__c--;
                      ap.TotalTerms__c--;
                    }
                    ap.GraduationDate__c = grad;
                    ap.MentorNotes__c = 'FDP Planned Graduation date update';
                    ap.CURegistered__c=0;
                    insert ap;
                List<StudentDegreePlans__c> upplans=new List<StudentDegreePlans__c> ();
                for(StudentDegreePlans__c plan:plans){
                    if (plan.plannedgraduationdate__C!=grad){
                        plan.plannedgraduationdate__C=grad;
                        upplans.add(plan);
                    }
                }
                if (upplans.size()>0){
                    update upplans;
                }
            }
            
        }
   }
  }

  //Can take a look at it later with @remoteaction
   //reviewed 3/19/2012
  public PageReference toggleExpand() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
      String termid=ApexPages.currentPage().getParameters().get('toggleTermId');
      StudentTermViewModel model=termsMap.get(termid);
      model.toggleExpand();
    } catch(Exception ex) {
        displayException(ex);
    }
      return null;
  }
   //reviewed 3/19/2012
  public PageReference togglePastTerms() {
    try {
        FDPUtilities.checkThrowExceptionTest();
      currentUserSecure = null;
      showPastTerms = !showPastTerms;
    } catch(Exception ex) {
        displayException(ex);
    }
    return null;
  }

  // Used to seperate two vital functions into different unit tests.
  // Reviewed 3/12/2012
  public PageReference putCourseInTerm() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
     putCourseInTerm(courseId,fromTermId,toTermId,insertAt);
    } catch(Exception ex) {
        displayException(ex);
    }
     return null;
  }

  public PageReference recalculatePlan() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
     String degreePlanId=ApexPages.currentPage().getParameters().get('degreePlanId');
     if(degreePlanId == currentPlanId) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You do not have permission to recalculate the degree plan that is currently in use. Create a new degree plan to do this.');
        ApexPages.addMessage(myMsg);
        return null;
     }
     Integer desiredCU=Integer.valueOf(ApexPages.currentPage().getParameters().get('desiredCU'));
     includeCurrentTerm = Boolean.valueOf(ApexPages.currentPage().getParameters().get('includeCurrentTerm'));
     Contact student = getCurrentContactWithProgramCode();
     recalculatePlan(degreePlanId,desiredCU,student,includeCurrentTerm);
    } catch(Exception ex) {
        displayException(ex);
    }

     return null;
  }

  public void recalculatePlan(String degreePlanId, Integer desiredCU, Contact student, Boolean includeCurrentTerm) {
     DegreePlanGenerator generator = new DegreePlanGenerator(student,desiredCU,degreePlanId,'',spoofid);
     generator.IncludeCurrentTerm = includeCurrentTerm;
     generator.generateAndSave();
     deleteEmptyTerms(student);
     loadDegreePlan(student,degreePlanId);
     updateApprovalMessage();
  }

  public PageReference createNewDegreePlan() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
    String planName = ApexPages.currentPage().getParameters().get('planName');
    StudentDegreePlans__c plan;
    try {
        plan = FDPUtilities.cloneStudentDegreePlan(planningPlanId,planName);
    } catch(TooManyDegreePlansException ex) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You have too many degree plans. Please delete other degree plans before you create another');
        ApexPages.addMessage(myMsg);
        return null;
    } catch(PlanNameTooLongException ex) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'The plan name \'' + planName + '\' is too long. Please choose a shorter name.');
        ApexPages.addMessage(myMsg);
        return null;
    } catch(Exception ex) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Plan name already exists. Please choose a different plan name');
        ApexPages.addMessage(myMsg);
        return null;
    }
    loadDegreePlan(currentStudent,plan.Id);
    updateApprovalMessage();
    } catch(Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public PageReference createNewDegreePlanAndRecalculate() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        String planName = ApexPages.currentPage().getParameters().get('planName');
        Integer desiredCU=Integer.valueOf(ApexPages.currentPage().getParameters().get('desiredCU'));
        Boolean includeCurrentTerm = Boolean.valueOf(ApexPages.currentPage().getParameters().get('includeCurrentTerm'));
        StudentDegreePlans__c plan;
        try {
            plan = FDPUtilities.cloneStudentDegreePlan(planningPlanId, planName);
        } catch(Exception ex) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Plan name already exists. Please choose a different plan name');
            ApexPages.addMessage(myMsg);
            return null;
        }
        recalculatePlan(plan.Id, desiredCU, currentStudent, includeCurrentTerm);
        loadDegreePlan(currentStudent,plan.Id);
        updateApprovalMessage();
    }catch(Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public PageReference createNewDegreePlanAndMoveCourse() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        String planName = ApexPages.currentPage().getParameters().get('planName');
        String courseId = ApexPages.currentPage().getParameters().get('courseId');
        Integer termNumber = Integer.valueOf(ApexPages.currentPage().getParameters().get('termNumber'));
        StudentCourse__C fromcourse = [Select StudentCourseVersion__c,WGULicenseRequirement__c from StudentCourse__c where Id =:courseId];

        StudentDegreePlans__c plan;
        try {
            plan = FDPUtilities.cloneStudentDegreePlan(planningPlanId,planName);
        } catch(Exception ex) {

            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Plan name already exists. Please choose a different plan name');
            ApexPages.addMessage(myMsg);
            return null;
        }
        String newCourseId;
        if (fromcourse.StudentCourseVersion__c!=null) {
          newCourseId = [select Id
            from StudentCourse__c
            where StudentCourseVersion__c = :fromcourse.StudentCourseVersion__c
            and StudentTerm__r.StudentDegreePlan__c = :plan.Id].Id;
        } else {
          newCourseId=[select Id
            from StudentCourse__c
            where WGULicenseRequirement__c = :fromcourse.WGULicenseRequirement__c
            and StudentDegreePlan__c = :plan.Id].Id;
        }
        AggregateResult res = [Select count(Id) MyCount
          from StudentTerm__c
          where StudentDegreePlan__c = :currentPlanId
          and EndDate__c < Today];
        Integer tNum = Integer.valueOf(res.get('MyCount')); //current term number
        String newTermId = '0';
        if(termNumber != 0) {
          // if we're to put
          // this in a new term
          // just keep the termId as '0'
          List<StudentTerm__c> terms = [Select Name,Id
            from StudentTerm__c
            where StudentDegreePlan__c = :plan.Id
            order by StartDate__c];
          for(StudentTerm__c term : terms) {
            if(term.Name == '000000'
              || term.Name == '111111') {
              tNum = 0;
            }
            if(tNum == termNumber) {
                newTermId = term.Id;
                break;
            }
            tNum++;
          }
        }
        loadDegreePlan(currentStudent,plan.Id);
        putCourseInTerm(newCourseId, null, newTermId, null);
        loadDegreePlan(currentStudent,plan.Id);
        updateApprovalMessage();
    }catch(Exception ex) {
        displayException(ex);
    }
    return null;
  }

  // returned is a list of objects and new studentTerms
  public Map<String,List<sObject>> cloneCourseForEveryPlan(StudentCourse__c ec,String termCode,List<StudentTerm__c> existingNewTerms) {
    List<sObject> newTerms = new List<sObject>();
    List<sObject> newCourses = new List<sObject>();
    Map<String,List<sObject>> returnedData = new Map<String,List<sObject>>();
    for(ScenarioManagerDegreePlanViewModel dp : scenarioManager.degreePlans) {
      if(dp.PlanName != 'Current Plan') {
        StudentCourse__c nc = (StudentCourse__c)ec.clone(false,true,false,false);
        nc.StudentTerm__r = null;
        newCourses.add(nc);
        nc.StudentTerm__c = dp.TermCodeToId.get(termCode);
        if(nc.StudentTerm__c == null) {
          StudentTerm__c nt = null;
          for(StudentTerm__c t: existingNewTerms) {
            if(t.Name == termCode
                && t.StudentDegreePlan__c == dp.PlanId) {
              nt = t;
            }
          }
          if(nt == null) {
            nt = new StudentTerm__c();
            nt.Name = termCode;
            nt.StudentDegreePlan__c = dp.PlanId;
            nt.Student__c = currentStudent.Id;
            nt.StartDate__c = FDPUtilities.getTermStartDateByCode(termCode);
            nt.EndDate__c = FDPUtilities.getTermEndDateByCode(termCode);
            nt.Approved__c = false;
            nt.ApprovalStatus__c = 'Pending Mentor Approval';
            nt.ApprovalDate__c = null;
            if(spoofid != null)
              nt.OwnerId = spoofid;
            newTerms.add(nt);
          }
          nc.StudentTerm__r = nt;
        }
      }
    }
    returnedData.put('terms',newTerms);
    returnedData.put('courses',newCourses);
    return returnedData;
  }

  //reeviewed 4/3/2012
  //TODO need to take a look at the plans loop. Could be issue in the future.
  public void deleteEmptyTerms(Contact student) {
    List<StudentDegreePlans__c> plans = [select Name
        from StudentDegreePlans__c
        where Student__c = :student.Id];
    List<StudentTerm__c> updateTerms = new List<StudentTerm__c>();
    List<StudentTerm__c> deleteTerms = new List<StudentTerm__c>();
    for(StudentDegreePlans__c plan : plans) {
        List<StudentTerm__c> iterms = [select Name,
            EndDate__c,
            StartDate__c,
            (select Name
            from StudentCourses__r)
            from StudentTerm__c
            where StudentDegreePlan__r.Id = :plan.Id
            order by StartDate__c];
        Integer decrementTerms = 0;
        for(StudentTerm__c term : iterms) {
            if(decrementTerms < 0) {
                for(Integer i=0;i>decrementTerms;i--) {
                    term.StartDate__c = FDPUtilities.getPreviousTermStartDateFromStartDate(term.StartDate__c);
                }
                term.EndDate__c = FDPUtilities.getTermEndDateFromStartDate(term.StartDate__c);
                term.Name = FDPUtilities.generateTermCode(term.StartDate__c);
                StudentTermViewModel tvm = termsmap.get(term.Id);
                if(tvm != null) {
                    for(Integer i=0;i>decrementTerms;i--) {
                        tvm.StartDate = FDPUtilities.getPreviousTermStartDateFromStartDate(tvm.StartDate);
                    }
                    tvm.EndDate = FDPUtilities.getNextTermStartDateFromStartDate(tvm.StartDate);
                    tvm.TermNumber += decrementTerms;
                }
                updateTerms.add(term);
            }
            // If the term is empty and it's not the current term
            if(term.StudentCourses__r.size() == 0
                && !(term.StartDate__c <= Date.today() && term.EndDate__c >= Date.today())
                ) {
                if(term.EndDate__c > Date.Today()) {
                    //We only want to adjust the dates on future terms.
                    // So if the term we are looking at is in the future
                    //OR is a current term, then all the future ones
                    // we adjust the dates/termNumber
                    decrementTerms -= 1;
                }
                deleteTerms.add(term);
                termsmap.remove(term.Id);
                Integer termIndex = null;
                for(Integer i=0;i<terms.size();i++) {
                    if(terms.get(i).Id == term.Id) {
                        termIndex = i;
                        break;
                    }
                }
                if(termIndex != null) {
                    terms.remove(termIndex);
                }
            }
        }
    }
    if(updateTerms.size() > 0)
      update updateTerms;
    if(deleteTerms.size() > 0) {
      for(StudentTerm__c t : deleteTerms) {
        if(scenarioManager != null) {
          scenarioManager.removeTerm(t);
        }
      }
      delete deleteTerms;
    }
  }

  public void moveCompletedOrFailedCoursesToCorrectTerm(Contact student) {
    List<StudentCourse__c> cCourses = [
      select
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Title__c,
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Name,
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CCN__c,
         WGULicenseRequirement__r.name,
         WGULicenseRequirement__r.requirementcode__C,
         CourseType__c,
         StartDate__c,
         EndDate__c,
         Status__c,
         CompletedDate__c,
         StudentTerm__c,
         StudentTerm__r.Approved__c,
         TermSequence__c,
         EnrollDate__c,
         InCorrectTerm__c,
         StudentCourseVersion__r.WGUCourseVersion__r.Version__c,
         StudentCourseVersion__r.WGUCourseVersion__r.MajorVersion__c,
         StudentCourseVersion__r.WGUCourseVersion__r.MinorVersion__c,
         StudentCourseVersion__r.WGUCourseVersion__r.CourseOfStudyId__c,
         StudentCourseVersion__r.StudentCompletionCourse__r.Status__c,
         StudentCourseVersion__r.StudentCompletionCourse__r.InPreviousProgram__c,
         StudentCourseVersion__r.StudentCourseRegistration__c,
         StudentCourseVersion__r.StudentCourseRegistration__r.Name,
         StudentCourseVersion__r.CompletedTermCode__c,
         StudentCourseVersion__r.EnrollTermCode__c,
         StudentCourseVersion__r.EnrollDate__c
      from StudentCourse__c
      where (
        InCorrectTerm__c = 'false'
        and Student__c = :student.Id
        and (
          Status__c = 'Failed'
          or Status__c = 'Completed'
          or Status__c = 'Enrolled'
        )
      ) or (
        Student__c = :student.Id
        and Status__c = 'Enrolled'
        and (
           StudentTerm__r.EndDate__c < Today
           or StudentTerm__r.StartDate__c > Today
        )
      )
    ];

    List<StudentCourse__c> updatedCourses = new List<StudentCourse__c>();
    List<StudentTerm__c> newTerms = new List<StudentTerm__c>();
    List<StudentCourseVersion__c> updatedCourseVersions = new List<StudentCourseVersion__c>();
    List<StudentCourse__c> coursesWithNoTerm = new List<StudentCourse__c>();
    Map<String,StudentTerm__c> courseIdToStudentTerm = new Map<String,StudentTerm__c>();
    Map<String,studentTerm__C> newtermcodesmap=new Map<String,studentterm__C>();

    for(StudentCourse__c c : cCourses) {
      StudentCourseViewModel cvm = coursesMap.get(c.Id);
      if(cvm == null) {
        cvm = new StudentCourseViewModel(c,cosurl,PortalStudentUserLogin,spoofid != null);
        coursesMap.put(c.Id,cvm);
      } else if(c.StudentTerm__c != null) {
        StudentTermViewModel oldTvm = termsMap.get(c.StudentTerm__c);
        if(oldTvm != null) {
          oldTvm.removeCourse(cvm);
        }
      }
      String termId;
      String oldStatus = c.Status__c;
      String oldEnrollTermCode = c.StudentCourseVersion__r.EnrollTermCode__c;
      if(c.Status__c == 'Enrolled') {
        Date termStartDate = FDPUtilities.getTermStartDateByCode(c.StudentCourseVersion__r.EnrollTermCode__c);
        if(currentTerm != null && termStartDate < currentTerm.StartDate) {
          // incomplete course
          // mark as planned
          StudentCourseVersion__c cv = c.StudentCourseVersion__r;
          cv.EnrollDate__c = null;
          cv.EnrollTermCode__c = null;
          cv.StudentCourseRegistration__c = null;
          cv.Status__c = 'Planned';
          updatedCourseVersions.add(cv);

          c.Status__c = 'Planned';
          c.EnrollDate__c = null;
          c.StartDate__c = null;
          c.EndDate__c = null;
          cvm.StartDate = null;
          cvm.EndDate = null;
          cvm.Status = 'Planned';
          String newTermCode = FDPUtilities.generateTermCode(currentTerm.StartDate.addMonths(6));
          // THis is incorrect
          termId = scenarioManager.termIdForTermCodeInCurrentPlan(newTermCode);
          Map<String,List<sObject>> addedStuff = cloneCourseForEveryPlan(c,newTermCode,newTerms);
          newTerms.addAll((List<StudentTerm__c>)addedStuff.get('terms'));
          updatedCourses.addAll((List<StudentCourse__c>)addedStuff.get('courses'));
        } else if(currentTerm != null && termStartDate > currentTerm.EndDate) {
          // enrolled in next term ?!?!
        } else {
          //This is incorrect
          termId = scenarioManager.termIdForTermCodeInCurrentPlan(c.StudentCourseVersion__r.EnrollTermCode__c);
        }
      } else {
        // this is incorrect
        termId = scenarioManager.termIdForTermCodeInCurrentPlan(c.StudentCourseVersion__r.StudentCompletionCourse__r.InPreviousProgram__c != true ? c.StudentCourseVersion__r.CompletedTermCode__c : '000000');
      }
      String termcode=null;
        //need to add term to the scenariomanager
        if(oldStatus == 'Enrolled'
            && c.Status__c == 'Planned') {
          //change enroll term code to new term code
          // may not need to do anything here if the above covers it.
        } else if(c.Status__c == 'Enrolled') {
          termcode = c.StudentCourseVersion__r.EnrollTermCode__c;
        } else {
          termcode = c.StudentCourseVersion__r.StudentCompletionCourse__r.InPreviousProgram__c != true ? c.StudentCourseVersion__r.CompletedTermCode__c : '000000';
        }
      if(termId == null) {
        
        StudentTerm__c t = newtermcodesmap.get(termcode);
        if(t==null){
          t = new StudentTerm__c();
          t.Name=termcode;
          t.StudentDegreePlan__c = currentPlanId;
          t.Student__c = student.Id;
          t.StartDate__c = FDPUtilities.getTermStartDateByCode(t.Name);
          t.EndDate__c = FDPUtilities.getTermEndDateFromStartDate(t.StartDate__c);
          t.Approved__c = false;
          t.ApprovalStatus__c = 'Pending Mentor Approval';
          t.ApprovalDate__c = null;
          if(spoofid != null)
            t.OwnerId = spoofid;
          newTerms.add(t);
          newtermcodesmap.put(termcode,t);
        }
        c.StudentTerm__r = null;
        c.StudentTerm__c = null;
        courseIdToStudentTerm.put(c.Id,t);
        coursesWithNoTerm.add(c);
      } else {
        c.StudentTerm__c = termId;
       
        updatedCourses.add(c);
        StudentTermViewModel newTvm = termsMap.get(termId);
        if(newTvm != null) {
          newTvm.addCourse(cvm);
        } else {
         StudentTerm__C t=[select id ,name from studentterm__C where id=:termId];
        for (StudentTermViewModel model:termsMap.values()){
         
            if (model.name==t.name){
                model.addCourse(cvm);
                break;
            }
            
        }
        //  throw new DegreePlanException('could not find term view model: ' + termId);
        }
      }
    }
    if(newTerms.size() > 0) {
      insert newTerms;
      for(StudentTerm__c t : newTerms) {
        StudentTermViewModel newTvm = new StudentTermViewModel(t,student);
        terms.add(newTvm);
        terms.sort();
        Decimal i =0;
        for(StudentTermViewModel tvm : terms) {
          tvm.TermNumber = i++;
        }
        termsMap.put(t.Id,newTvm);
      }
      for(StudentCourse__c c : updatedCourses) {
        if(c.StudentTerm__c == null
            && c.StudentTerm__r != null
            && c.StudentTerm__r.Id != null) {
          c.StudentTerm__c = c.StudentTerm__r.Id;
        }
      }
      for(StudentCourse__c c : coursesWithNoTerm) {
        StudentTerm__c t = courseIdToStudentTerm.get(c.Id);
        c.StudentTerm__c = t.Id;
        termsMap.get(t.Id).addCourse(coursesMap.get(c.Id));
        updatedCourses.add(c);
      }
    }
    if(updatedCourses.size() > 0) {
      upsert updatedCourses;
    }
     if(updatedCourseVersions.size() > 0) {
      update updatedCourseVersions;
    }
   
  }

  public String termIdWithTermCode(String termCode) {
    for(StudentTermViewModel t : terms) {
      if(t.Name == termCode) {
        return t.Id;
      }
    }
    return null;
  }

  // Reviewed 3/26/2012
  public void putCourseInTerm(String pCourseId, String pFromTermId, String pToTermId, String pInsertAt) {
  StudentCourse__c course =
      [select StudentTerm__c,
            coursetype__C,
              StartDate__c,
              EndDate__c,
              CompletedDate__c,
              Status__c,
              StudentTerm__r.StudentDegreePlan__c,
              StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
              StudentTerm__r.Approved__c
       from StudentCourse__c
       where Id = :pCourseId];
       AggregateResult beforeUpdate = [select max(EndDate__c) maxenddate
    from StudentTerm__c
    where StudentDegreePlan__c =:course.StudentTerm__r.StudentDegreePlan__c];
    if(pToTermId == '0' && course.StudentTerm__r.StudentDegreePlan__c == currentPlanId) {
      throw new DegreePlanException('You do not have permission to change the graduation date on a degree plan that has been approved.');
    }
     if(course.Status__c != 'Planned') {
       throw new DegreePlanException('Cannot move a course that does not have a status of planned.');
     }
     StudentTerm__c toterm = null;
     if(pToTermId == '0') {
        // We just dragged to create a new term
        toterm = new StudentTerm__c();
         StudentTerm__c oldTerm=null;
        if (course.StudentTerm__c!=null)
        oldTerm = [select Id,
            Name,
            StartDate__c,
            EndDate__c,
            StudentDegreePlan__c,
            ApprovalStatus__c,
            Approved__c,
            ApprovalDate__c,
            ApprovalDateTime__c
          from StudentTerm__c
          where StudentDegreePlan__c = :course.StudentTerm__r.StudentDegreePlan__c
          order by StartDate__c desc
          limit 1];

        toterm.StartDate__c = FDPUtilities.getNextTermStartDateFromStartDate(oldTerm.StartDate__c);
        toterm.EndDate__c = FDPUtilities.getTermEndDateFromStartDate(toterm.StartDate__c);
        toterm.Name = FDPUtilities.generateTermCode(toterm.StartDate__c);
        toterm.CompetencyUnits__c = 0;
        toterm.StudentDegreePlan__c = oldTerm.StudentDegreePlan__c;
        toterm.Approved__c = false;
        toterm.ApprovalDate__c = null;
        toterm.ApprovalDateTime__c = null;
        toterm.ApprovalStatus__c = 'Pending Mentor Approval';
        if (spoofid!=null)toterm.ownerid=spoofid;
        insert toterm;
        StudentTermViewModel tv = new StudentTermViewModel(toterm,getCurrentContactWithProgramCode());
        tv.TermNumber = termsmap.get(oldTerm.Id).TermNumber+1;
        termsmap.put(toterm.Id,tv);
        terms.add(tv);
     } else {
        try{
           toterm = [select Id,Name,CompetencyUnits__c,
             StartDate__c,EndDate__c,Approved__c,
             ApprovalDate__c,ApprovalStatus__c,ApprovalDateTime__c
           from StudentTerm__c
           where Id = :pToTermId];
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Degreen Plan has been modified by another user, Please refresh the page.' + pToTermId);
            ApexPages.addMessage(myMsg);
            return;
        }
     }
     // Commented this out
     // GKC Mar 19, 2013
     // changing course to should unapprove term and plan
     /*if(course.StudentTerm__r.Approved__c || toTerm.Approved__c) {
        throw new DegreePlanException('Cannot move a course to or from a term that is approved');
     }*/
     if(course.StudentTerm__c != toTerm.Id) {
       StudentTerm__c fromterm=null;
       if(course.StudentTerm__c!=null)
        fromterm = [select Id,
          CompetencyUnits__c,
          Approved__c,ApprovalDate__c,ApprovalStatus__c,ApprovalDateTime__c
       from StudentTerm__c where Id = :course.StudentTerm__c];

        course.StudentTerm__c = toTerm.Id;
        course.StartDate__c = null;
        course.EndDate__c = null;


        toTerm.Approved__c = false;
        toTerm.ApprovalDate__c = null;
        toTerm.ApprovalDateTime__c = null;
        toTerm.ApprovalStatus__c = 'Pending Mentor Approval';
        if (fromTerm!=null){
          if (course.StudentCourseVersion__r!=null){
           toTerm.CompetencyUnits__c += course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c;
          fromTerm.CompetencyUnits__c -= course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c;
          }
          fromTerm.Approved__c = false;
          fromTerm.ApprovalDate__c = null;
          fromTerm.ApprovalDateTime__c = null;
          fromTerm.ApprovalStatus__c = 'Pending Mentor Approval';
        }
        StudentCourseViewModel cv=coursesMap.get(course.id);
        cv.StartDate = null;
        cv.EndDate = null;
        StudentTermViewModel tv=termsmap.get(toTerm.id);
        tv.Approved = false;
        tv.ApprovalDate = null;
        //TODO: Add ApprovalDateTime to view model
        //tv.ApprovalDateTime__c = null;
        tv.ApprovalStatus = 'Pending Mentor Approval';
        StudentTermViewModel fv;

        if (fromterm!=null){
        fv=termsmap.get(fromTerm.id);
        }else fv=termsmap.get('Non Degree Requirement');
        fv.Approved = false;
        fv.ApprovalDate = null;
        //TODO: Add ApprovalDateTime to view model
        //fv.ApprovalDateTime__c = null;
        fv.ApprovalStatus = 'Pending Mentor Approval';
        tv.addCourse(cv);
        fv.removeCourse(cv);
        update course;
        update toTerm;
        if (fromterm!=null)
        update fromTerm;
     }
     deleteEmptyTerms(getCurrentContactWithProgramCode());
     List<StudentDegreePlans__c> plans = getAndLoadDegreePlans(currentStudent,planningPlanId);
     scenarioManager = new ScenarioManagerViewModel(currentStudent,terms,plans,tuitionPerTerm);
     AggregateResult afterUpdate = [select max(EndDate__c) maxenddate
    from StudentTerm__c
    where StudentDegreePlan__c =:course.StudentTerm__r.StudentDegreePlan__c];
    if(afterUpdate.get('maxenddate') != beforeUpdate.get('maxenddate')) {
        StudentDegreePlans__c plan = [select ApprovedBy__c,id,
       IsApproved__c,ApprovalStatus__c,ApprovalDate__c,currentplan__C,
       (select Approved__c,ApprovalStatus__c,
         ApprovalDate__c,ApprovalDateTime__c
       from StudentTerms__r)
       from StudentDegreePlans__c
       where id = :planningPlanId];
       StudentDegreePlans__c approvedplan=null;
       StudentDegreePlans__c currentplan=null;
       for( StudentDegreePlans__c p:plans){
        if (p.IsApproved__c) approvedplan=p;
        if (p.currentplan__C)currentplan=p; 
       }
       if (plan.id==currentplan.id){
         if ((approvedplan.id==currentplan.id)||(approvedplan==null)){
            
            planGraduationDate =(Date)afterUpdate.get('maxenddate');
            plan.plannedgraduationdate__C=planGraduationDate;
         }
       }
       else if (approvedplan != null && plan.id==approvedplan.id){
          Studentterm__C maxterm = [select id, enddate__C,(select enddate__C from studentcourses__r where enddate__C!=null order by enddate__C desc limit 1) from studentterm__C
            where StudentDegreePlan__c=:currentplanid order by enddate__C desc limit 1];
            date grad=null;
            if (maxterm.studentcourses__r.size()>0&&maxterm.studentcourses__r[0].enddate__C!=null) grad=maxterm.studentcourses__r[0].enddate__C;
            else grad =maxterm.enddate__C;
            if (currentplan.plannedgraduationdate__C!=grad){
                currentplan.plannedgraduationdate__C=grad;
                planGraduationDate =grad;
                update currentplan;
            }
          createFDPapprovalGrad(grad);
       }
     plan.ApprovedBy__c = null;
     plan.IsApproved__c = false;
     plan.ApprovalStatus__c = 'Pending Mentor Approval';
     plan.ApprovalDate__c = Date.Today();
     for(StudentTerm__c t : plan.StudentTerms__r) {
        t.Approved__c = false;
        t.ApprovalStatus__c = 'Pending Mentor Approval';
        t.ApprovalDate__c = null;
        t.ApprovalDateTime__c = null;
     }
     update plan.StudentTerms__r;
     update plan;
     scenarioManager.markPlanApprovalStatus(plan.Id,'Pending Mentor Approval');
    }
     updateApprovalMessage();
  }
     private void createFDPapprovalGrad(date grad){

                    delete [select id from fdpapproval__C where UsedForEnrollment__c = false and Student__c = :currentStudent.Id];
                    FDPApproval__c ap = new FDPApproval__c();
                    ap.Student__c = currentStudent.Id;
                    ap.ProgramCode__c = currentStudent.ProgramCode__c;
                    for(StudentTermViewModel t : terms) {
                      if(t.StartDate <= Date.today() && t.EndDate >= Date.today()) {
                        //this is our term
                        ap.Name = t.Name;
                        ap.TermNumber__c = Integer.valueOf(t.TermNumber);
                      }
                    }
                    ap.CatalogTerm__c = currentStudent.ProgramCatalogTerm__c;
                    ap.UsedForEnrollment__c = false;
                    ap.CompletedTerm__c = completedTermSize;
                    ap.TotalTerms__c = terms.size();
                    if(transferCU>0) {
                      ap.CompletedTerm__c--;
                      ap.TotalTerms__c--;
                    }
                    ap.GraduationDate__c = grad;
                    ap.MentorNotes__c = 'FDP Planned Graduation date update';
                    ap.CURegistered__c=0;
                    insert ap;

}
  public PageReference loadDegreePlan() {
    try {
        FDPUtilities.checkThrowExceptionTest();
        currentUserSecure = null;
        Contact student = getCurrentContactWithProgramCode();
        String planId = ApexPages.currentPage().getParameters().get('planId');
        loadDegreePlan(student,planId);
    } catch (Exception ex) {
        displayException(ex);
    }
    return null;
  }

  public Map<String,Tuition__c> getTuition() {
    if(p_tuitionMap != null) {
      return p_tuitionMap;
    }
    p_tuitionMap = new Map<String,Tuition__c>();
    for(Tuition__c t : [SELECT Amount__c,name,TermCode__c
        FROM Tuition__c
        WHERE name = :currentStudent.PIDM__c]) {
      p_tuitionMap.put(t.TermCode__c,t);
    }
    return p_tuitionMap;
  }

  public List<StudentDegreePlans__c> getAndLoadDegreePlans(Contact student,String degreePlanId) {
    WGUDegreeProgram__c program = student.WGUDegreeProgram__r;
    String termCode = FDPUtilities.getTermCodeFromContact(student);
    List<StudentDegreePlans__c> plans = [select id, Name,
        ApprovalStatus__c,
        plannedgraduationdate__C,
        ApprovalDate__c,
        IsApproved__c,
        CreatedDate,
        LastModifiedDate,
        ApproverName__c,
        IsIncludeCurrentTerm__c,
        CurrentPlan__c,
          (select StartDate__c,EndDate__c,Name
          from StudentTerms__r
          order by StartDate__c)
        from StudentDegreePlans__c
        where student__C=:student.Id
        and BasedOnProgram__c=:program.id
        order by CurrentPlan__c desc,Name];
    List<Tuition__c> tpt = [select Amount__c,Name
      from Tuition__c
      where Name = :student.WGUDegreeProgram__r.Name
      and TermCode__c = :termCode
      limit 1];
    if(tpt.size() >0)
        tuitionPerTerm = tpt[0].Amount__c;
    else
        tuitionPerTerm = 0;
    if(degreePlanId == null) {
      for(StudentDegreePlans__c p : plans) {
        
       
        if(p.CurrentPlan__c) {
          degreePlanId = p.Id;
        } 
        if(p.IsApproved__c) {
          degreePlanId = p.Id;
        }
         
        
      }
      if(degreePlanId == null) {
        degreePlanId = FDPUtilities.getLastDegreePlan(UserInfo.getUserID(),student.Id);
      }
    }
    if(degreePlanId != null) {
      FDPUtilities.setLastDegreePlan(UserInfo.getUserID(),student.Id,degreePlanId);
    }
    for (StudentDegreePlans__c oneplan:plans) {
      //Notice: here we call the parent plan
      if (oneplan.CurrentPlan__c) {
        currentPlanId = oneplan.Id;
        currentPlanName = oneplan.Name;
        planGraduationDate=oneplan.plannedgraduationdate__C;
      }
      if((degreePlanId != null && oneplan.Id == degreePlanId)||(degreePlanId == null && oneplan.CurrentPlan__c)) {
          if(degreePlanId == null) {
            FDPUtilities.setLastDegreePlan(UserInfo.getUserID(),student.Id,oneplan.Id);
          }
          planningPlanId = oneplan.Id;
          planningPlanName = oneplan.Name;
          ApprovalDate = oneplan.ApprovalDate__c;
          IsApproved = oneplan.IsApproved__c;
          MentorNameWhoApproved = oneplan.ApproverName__c;
          ApprovalStatus = oneplan.ApprovalStatus__c;
          if(oneplan.CreatedDate == oneplan.LastModifiedDate) {
            this.modifyActionType = 'created';
          } else {
            this.modifyActionType = 'modified';
          }
          planModifyDate = Date.valueOf(oneplan.LastModifiedDate);
          includeCurrentTerm = oneplan.IsIncludeCurrentTerm__c;
      }
    }
    return plans;
  }

  public void checkForProgramChange(Contact student) {
    WGUDegreeProgram__c program = student.WGUDegreeProgram__r;
    List<StudentDegreePlans__c> plans = [select Name,
      BasedOnProgram__c
      from StudentDegreePlans__c
      where Student__c = :student.Id];
    Boolean programChanged = false;
    for(StudentDegreePlans__c plan : plans) {
        if(plan.BasedOnProgram__c != program.Id) {
            programChanged = true;
        }
    }
    if(programChanged) {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'New degree program has been detected. A new plan has been generated for you.');
        ApexPages.addMessage(myMsg);
        FDPUtilities.cleandegreeplanwithpidm(student.PIDM__c);
    }
  }

  // reviewed 4/3/2012
  public PageReference loadDegreePlan(Contact student,String degreePlanId) {
  try {
        FDPUtilities.checkThrowExceptionTest();
    currentUserSecure = null;
    terms.clear();
    WGUDegreeProgram__c program = student.WGUDegreeProgram__r;
    Boolean isInitialGeneration = false;
    if (program == null){
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You don\'t have a degree program assigned. Please contact your mentor for help.');
      ApexPages.addMessage(myMsg);
      return null;
    }
    checkForProgramChange(student);
    String termCode = FDPUtilities.getTermCodeFromContact(student);
    List<StudentDegreePlans__c> plans = getAndLoadDegreePlans(student,degreePlanId);
    if(plans.size() == 0) {
      try {
        Integer requiredCUs = currentStudent.WGUDegreeProgram__r.ProgramLevel__r.Name == 'GR' ? MINCUPERTERMGRAD : MINCUPERTERMUNDERGRAD;
        DegreePlanGenerator generator = new DegreePlanGenerator(student,requiredCUs,'Current Plan');
        generator.spoofid = spoofid;
        generator.IsInitialGeneration = true;
        StudentDegreePlans__c planning =generator.generateAndSave();
        isInitialGeneration = true;
        planningPlanId = currentPlanId = planning.Id;
        planningPlanName = currentPlanName = planning.Name;
      }
      catch(Exception e) {
        plans = getAndLoadDegreePlans(student,degreePlanId);
        if(plans.size() == 0) {
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'A current plan is already being processed. Please reload the page.');
          ApexPages.addMessage(myMsg);
          ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.FATAL,String.valueOf(e));
          ApexPages.addMessage(myMsg2);
          return null;
        }
      }
    }

    if(isInitialGeneration) {
      plans = getAndLoadDegreePlans(student,degreePlanId);
    } else {
      /*DegreePlanGenerator gen = new DegreePlanGenerator();
      gen.Student = student;
      gen.PlanId = currentPlanId;
      gen.SpoofId = spoofid;
      gen.putCoursesInCorrectPlace();*/
    }
    deleteEmptyTerms(getCurrentContactWithProgramCode());
    Date cur = Date.today();
    Set<String> allCourseVersions = new Set<String>();
    List<StudentTerm__c> termsList = [select Name,
      (
         select
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Title__c,
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Name,
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
         StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CCN__c,
          StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Latestversion__C,
         StudentCourseVersion__c,
         WGULicenseRequirement__r.name,
         WGULicenseRequirement__r.requirementcode__C,
         CourseType__c,
         StartDate__c,
         EndDate__c,
         Status__c,
         CompletedDate__c,
         StudentTerm__c,
         StudentTerm__r.Approved__c,
         TermSequence__c,
         EnrollDate__c,
         InCorrectTerm__c,
         StudentCourseVersion__r.WGUCourseVersion__r.Version__c,
         StudentCourseVersion__r.WGUCourseVersion__r.MajorVersion__c,
         StudentCourseVersion__r.WGUCourseVersion__r.MinorVersion__c,
         StudentCourseVersion__r.WGUCourseVersion__r.CourseOfStudyId__c,
         StudentCourseVersion__r.StudentCompletionCourse__r.Status__c
         from StudentCourses__r
         where (
           (
              StudentTerm__r.EndDate__c >= Today
              and Status__c = 'Planned'
           ) or (
              StudentTerm__r.EndDate__c < Today
           )
         )
         and
         (
           StudentCourseVersion__r.StudentCompletionCourse__r.Status__c not in ('Requirement Met','Waived')
           or StudentTerm__r.Name != '000000'
         )
         // Ordering by status happens to be alphabetical :)
         // but the order should be 'Completed' then 'Enrolled' then 'Failed' then 'Planned'
         order by CompletedDate__c,StartDate__c,TermSequence__c
       ),
       TermNumber__c,
       CompetencyUnits__c,
       StartDate__c,
       EndDate__c,
       StudentDegreePlan__c,
       Approved__c,
       ApprovalStatus__c,
       ApprovalDate__c
       from StudentTerm__c
       where StudentDegreePlan__r.Student__r.Id = :student.Id
       and (
       ((Name = '111111' or EndDate__c >= Today) and StudentDegreePlan__r.Id = :planningPlanId)
          or
        (Name != '111111' and EndDate__c < Today and StudentDegreePlan__r.Id = :currentPlanId)
        )
      order by StartDate__c];


    Map<String,Tuition__c> tuitionMap = getTuition();
    Integer termNum = 1;
    transfercu = 0;
    completedtermsize = 0;
    //jwang10 start

    Set<String> courseVersions = new Set<String>();
    List <String> cvs=new List<String>();
       //jwang10 end
    for(StudentTerm__c term : termsList) {
    //jwang10
      StudentTermViewModel onemodel=new StudentTermViewModel(term,getCurrentContactWithProgramCode());
      if(term.EndDate__c < cur) {
        completedtermsize++;
        if (tuitionMap.get(term.Name) != null) {
          onemodel.Tuition = tuitionMap.get(term.Name).Amount__c;
          totalTuition += onemodel.Tuition;
        }
      } else {
          if(term.StartDate__c <= cur) {
            // current term
            currentTerm = onemodel;
          }
          onemodel.Tuition = tuitionPerTerm;
          totalTuition += onemodel.Tuition;
      }
      if (term.Name=='000000') {
        onemodel.TermNumber = 0;
        onemodel.Name='Transferred Courses';
      } else if(term.Name == '111111') {
        onemodel.TermNumber = -1;
        onemodel.Name = 'Graduation Requirements';
      } else {
        onemodel.TermNumber = termNum++;
      }
      terms.add(onemodel);
      termsMap.put(onemodel.id,onemodel);
      if(term.StartDate__c <= cur && term.EndDate__c >= cur) {
        // current term, get completed courses from current plan
        List<StudentCourse__c> completedCoursesInCurrentTerm = [select
          Name,
          StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Title__c,
          StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Name,
          StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
          StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CCN__c,
           StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Latestversion__C,
         StudentCourseVersion__c,
          StartDate__c,
          EndDate__c,
          Status__c,
          CompletedDate__c,
          StudentTerm__c,
          StudentTerm__r.Approved__c,
          TermSequence__c,
          EnrollDate__c,
          CourseType__c,
          InCorrectTerm__c,
          StudentCourseVersion__r.WGUCourseVersion__r.Version__c,
          StudentCourseVersion__r.WGUCourseVersion__r.MajorVersion__c,
          StudentCourseVersion__r.WGUCourseVersion__r.MinorVersion__c,
          StudentCourseVersion__r.WGUCourseVersion__r.CourseOfStudyId__c,
          StudentCourseVersion__r.StudentCompletionCourse__r.Status__c
          from StudentCourse__c
          where StudentTerm__r.StartDate__c <= Today
          and StudentTerm__r.EndDate__c >= Today
          and Student__c = :student.Id
          and StudentTerm__r.StudentDegreePlan__r.Name = 'Current Plan'
          and Status__c != 'Planned'
          and Status__c != 'Failed'
        ];
        for(StudentCourse__c course : completedCoursesInCurrentTerm) {
          StudentCourseViewModel coursev = new StudentCourseViewModel(course,cosurl,PortalStudentUserLogin, spoofid != null);
          coursev.term = onemodel;
          coursesMap.put(course.id,coursev);
          onemodel.addCourse(coursev);
          courseVersions.add(course.StudentCourseVersion__r.WGUCourseVersion__c);
        }
      }
     
      for(StudentCourse__c course : term.StudentCourses__r) {
        if (course.Status__c == 'Planned'&&course.StudentCourseVersion__r.WGUCourseVersion__c!=course.StudentCourseVersion__r.wgucourseversion__r.wgucourse__r.LatestVersion__C)
        {
            course.StudentCourseVersion__r.WGUCourseVersion__c=course.StudentCourseVersion__r.wgucourseversion__r.wgucourse__r.LatestVersion__C;
            cvs.add(course.StudentCourseVersion__c);
        }
        courseVersions.add(course.StudentCourseVersion__r.WGUCourseVersion__c);
        StudentCourseViewModel coursev=new StudentCourseViewModel(course,cosurl,PortalStudentUserLogin, spoofid != null);
        coursev.term=onemodel;
        coursesMap.put(course.id,coursev);
        onemodel.addCourse(coursev);
        Integer courseCU = 0;
        if(course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c != null) {
          courseCU = Integer.valueOf(course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c);
        }
        if(course.StudentCourseVersion__r != null) {
          if (course.Status__c != 'Failed') {
            totalCU += courseCU;
          }
          if(term.StartDate__c <= cur) {
            if(term.EndDate__c >= cur) {
              currentcu += courseCU;
            } else {
              if (term.name=='000000') {
                transfercu += courseCU;
              } else if (course.status__C != 'Failed') {
                  completedcu += courseCU;
              }
            }
          } else {
            futurecu += courseCU;
          }
        }
      }
      onemodel.HistoricalCourses.sort();
      onemodel.RemainingCourses.sort();
    }
    List<Studentcourseversion__C> scovs=[
    select id,wgucourseversion__C, wgucourseversion__r.wgucourse__r.latestversion__C from studentcourseversion__C where id in :cvs
    ];
    for (Studentcourseversion__C sc:scovs){
        sc.wgucourseversion__C=sc.wgucourseversion__r.wgucourse__r.latestversion__C;
    }
    update scovs;
    List<WGUCompletionTaskInCourseVersion__c> tasks = [
      select Name,
      WGUCourseVersion__c,
      WGUCourseVersion__r.WGUCourse__c,
      WGUCourseCompletionTask__c,
      WGUCourseCompletionTask__r.Title__c,
      WGUCourseCompletionTask__r.Type__c,
      WGUCourseCompletionTask__r.BannerCode__c
      from WGUCompletionTaskInCourseVersion__c
      where WGUCourseVersion__c in :courseVersions
      order by WGUCourseCompletionTask__r.Type__c desc
    ];
    Map<String,List<WGUCompletionTaskInCourseVersion__c>> tasksmap=new Map<String,List<WGUCompletionTaskInCourseVersion__c>> ();
    for(WGUCompletionTaskInCourseVersion__c ctcv : tasks) {
      String wgucourseversionId = ctcv.WGUCourseVersion__c;
      if (!tasksmap.containskey(wgucourseversionid)){
        tasksmap.put(wgucourseversionid,new List<WGUCompletionTaskInCourseVersion__c>());
      }
      tasksmap.get(wgucourseversionId).add(ctcv);
    }

    //use wgucoursecompletiontask + termcode as the key
    Map<String,StudentCompletionTask__c> sTasks = new Map<String,StudentCompletionTask__c>();
    Map<String,StudentCompletionTask__c> failedTasks = new Map<String,StudentCompletionTask__c>();
    for(StudentCompletionTask__c t : [
      select Name,WGUCourseCompletionTask__c,
      RequirementComplete__c,
      TermCode__c
      from StudentCompletionTask__c
      where Student__c = :student.Id]) {
      if(t.RequirementComplete__c == true) {
        sTasks.put(t.WGUCourseCompletionTask__c,t);
      } else {
        failedTasks.put(t.WGUCourseCompletionTask__c+'|'+t.termcode__C,t);
      }
    }

    for(StudentTermViewModel tvm : terms) {
      for(StudentCourseViewModel cvm : tvm.HistoricalCourses) {
        List<WGUCompletionTaskInCourseVersion__c> wtasks=tasksmap.get(cvm.WGUCourseversionId);
        if(cvm.assessments == null) {
          cvm.assessments = new List<StudentAssessmentViewModel>();
        }

        for(WGUCompletionTaskInCourseVersion__c ctcv:wtasks) {
          StudentAssessmentViewModel sctvm = new StudentAssessmentViewModel();
          if(ctcv.WGUCourseCompletionTask__r.Type__c != null
            && ctcv.WGUCourseCompletionTask__r.Type__c.length() > 0) {
            sctvm.Character = ctcv.WGUCourseCompletionTask__r.Type__c.substring(0,1);
          }
          sctvm.Type = ctcv.WGUCourseCompletionTask__r.Type__c;
          if(sctvm.Character == 'P') {
            sctvm.Title = 'Performance Assessment';
          } else if(sctvm.Character == 'O') {
            sctvm.Title = 'Objective Assessment';
          }
          sctvm.BannerCode = ctcv.WGUCourseCompletionTask__r.BannerCode__c;
          sctvm.Color = null;
          if(sTasks.containsKey(ctcv.WGUCourseCompletionTask__c)) {
            StudentCompletionTask__c sct = sTasks.get(ctcv.WGUCourseCompletionTask__c);
            if(sct.TermCode__c <= tvm.Name) {
              sctvm.Color = 'blue';
            }
          }
          if(failedTasks.containsKey(ctcv.WGUCourseCompletionTask__c+'|'+tvm.name)) {
            sctvm.color='red';
          }
         
           if(cvm.status=='Completed') {
             sctvm.Color = 'blue';
           } else if(cvm.Status == 'Failed') {
             sctvm.Color = 'red';
           }
          
          cvm.assessments.add(sctvm);
        }
      }
      for(StudentCourseViewModel cvm : tvm.RemainingCourses) {
        List<WGUCompletionTaskInCourseVersion__c> wtasks=tasksmap.get(cvm.WGUCourseVersionId);
        if(wtasks == null)
          continue;
        if(cvm.assessments == null) {
            cvm.assessments = new List<StudentAssessmentViewModel>();
          }
        for(WGUCompletionTaskInCourseVersion__c ctcv:wtasks){
          StudentAssessmentViewModel sctvm = new StudentAssessmentViewModel();
          sctvm.Character = '';
          if(ctcv.WGUCourseCompletionTask__r.Type__c != null
            && ctcv.WGUCourseCompletionTask__r.Type__c.length() > 0) {
            sctvm.Character = ctcv.WGUCourseCompletionTask__r.Type__c.substring(0,1);
          }
          sctvm.Type = ctcv.WGUCourseCompletionTask__r.Type__c;
          if(sctvm.Character == 'P') {
            sctvm.Title = 'Performance Assessment';
          } else if(sctvm.Character == 'O') {
            sctvm.Title = 'Objective Assessment';
          }
          sctvm.BannerCode = ctcv.WGUCourseCompletionTask__r.BannerCode__c;
          if(sTasks.containsKey(ctcv.WGUCourseCompletionTask__c+'|'+tvm.name)) {
            sctvm.Color = 'blue';
          }
           if (sTasks.containsKey(ctcv.WGUCourseCompletionTask__c+'|'+tvm.name)) {
              sctvm.color='red';
          } else {
            sctvm.Color = 'green';
          }
          if(cvm.status=='Completed'){sctvm.Color = 'blue';}
          cvm.assessments.add(sctvm);
        }
      }
    }

    showPastTerms = false;
    scenarioManager = new ScenarioManagerViewModel(student,terms,plans,tuitionPerTerm);
    updateApprovalMessage();
    updateStudentMessage();
    if (isInitialGeneration){//it will be the current plan 
        for (Studentdegreeplans__C plan:plans){
                plan.plannedgraduationdate__C=terms[terms.size()-1].getGradDate();
              createFDPapprovalGrad( plan.plannedgraduationdate__C);
        }
        update plans;
    }
    } catch(Exception ex) {
      displayException(ex);
    }
    return null;
  }

  public User getCurrentUserSecure() {
    if(currentUserSecure != null) {
        return currentUserSecure;
    }
    currentUserSecure = [SELECT ContactId, UserType, Name FROM User WHERE id = :UserInfo.getUserID()];
    return currentUserSecure;
  }

  // Reviewed 3/19/2012
  //todo need to use a newly created studentInformation Class
  public Contact getCurrentContactWithProgramCode() {
      PageReference page = ApexPages.currentPage();

      if(currentStudent == null || page.getParameters().get('id') != null) {
        User currentUser = getCurrentUserSecure();
        UserName = UserInfo.getName();
        UserLogin = UserInfo.getUserName();
        // Check if user is employee, if so allow identity spoofing.
        if(currentUser.userType == 'Standard') {
            String pidm = page.getParameters().get('pidm');
            String spoofUserName = page.getParameters().get('id');
            if(spoofUserName == null)
              spoofUserName = page.getParameters().get('user_name');
            String spoofContactId = page.getParameters().get('contact_id');
            String spoofUserId = page.getParameters().get('user_id');
            String spoofStudentId = page.getParameters().get('student_id');
            if(pidm != null){
              currentUser = [SELECT ContactId,Name,UserName FROM User WHERE PIDM__c = :pidm];
              spoofid=currentUser.id;
            } else if(spoofUserName != null) {
              currentUser = [SELECT ContactId,Name,UserName FROM User WHERE UserName = :spoofUserName];
              spoofid=currentUser.id;
            } else if(spoofContactId != null) {
              currentUser = [select ContactId,Name,UserName from User where ContactId = :spoofContactId];
            } else if(spoofStudentId != null) {
              spoofStudentId = spoofStudentId.leftPad(9).replace(' ','0');
              currentUser = [select ContactId,Name,UserName from User where Contact.StudentId__c = :spoofStudentId];
            } else if(spoofUserId != null) {
              currentUser = [select ContactId,Name,UserName from User where Id = :spoofUserId];
            } else {
              throw new DegreePlanException('No student record found for current user. If you are trying to view a student as a mentor, be sure to pass in the PIDM of the student that you are trying to view.');
            }
        }

        currentstudent=[select Id,
        Name,
        WGUEmail__c,
        ProgramCode__c,
        ProgramCatalogTerm__c,
        PIDM__c,
        StudentId__c,
        TermCode__c,
        TermStartDate__c,
        TermEndDate__c,
        MentorName__c,
        Mentor__r.Email,
        ProgramName__c,
        WGUDegreeProgram__r.Id,
        WGUDegreeProgram__r.Name,
        WGUDegreeProgram__r.TuitionPerTerm__c,
        WGUDegreeProgram__r.CatalogTerm__c,
        WGUDegreeProgram__r.ProgramLevel__r.Name,
        WGUDegreeProgram__r.HasFieldExp__c,
        EulaAgreementDate__c,
        Status__c,
        BannerStatus__c
        from Contact
        where Id=:currentUser.contactid];

        if(!correctProgram(currentStudent)) {
          currentStudent = assignCorrectProgram(currentStudent);
        }
        StudentName = currentstudent.Name;
        MentorName = currentstudent.MentorName__c;
        MentorEmail = currentstudent.Mentor__r.Email;
        Pattern p = Pattern.compile('(.*)@.*');
        if(currentStudent.WGUEmail__c != null) {
          String e = currentStudent.WGUEmail__c;
          Matcher m = p.matcher(e);
          if(m.groupCount() == 2) {
            PortalStudentUserLogin = m.group(1);
          } else {
            if(e.indexOf('@') > 0) {
              PortalStudentUserLogin = e.substring(0,e.indexOf('@'));
            } else {
              PortalStudentUserLogin = null;
            }
          }
        } else {
          PortalStudentUserLogin = null;
        }
        List<Opportunity> opps = [select CareStatus__c
          from Opportunity
          where StudentContact__c = :currentUser.ContactId
          and
            (CareStatus__c like 'CLRD%'
             or
             CareStatus__c like 'ENRL%')
          order by CareStatus__c desc
          ];
        //favor the ENRL status over the CLRD in case there's
        //multiple care profiles
        if(opps.size() > 0) {
          CareStatus = opps[0].CareStatus__c;
        } else {
          CareStatus = 'Not Cleared, No CARE Profile';
        }
      }
      return currentStudent;
  }

  public Contact assignCorrectProgram(Contact s) {
    if(s.ProgramCode__c == null
        || s.ProgramCatalogTerm__c == null) {
      // do we need this?
      if(s.WGUDegreeProgram__c != null) {
        s.WGUDegreeProgram__c = null;
      }
      return s;
    }
    List<WGUDegreeProgram__c> programs = [select
      Id,
      Name,
      TuitionPerTerm__c,
      CatalogTerm__c,
      ProgramLevel__r.Name,
      HasFieldExp__c
      from WGUDegreeProgram__c
      where Name = :s.ProgramCode__c];
    Map<String,WGUDegreeProgram__c> programMap = new Map<String,WGUDegreeProgram__c>();
    for(WGUDegreeProgram__c p : programs) {
      programMap.put(p.Name + '-' + p.CatalogTerm__c,p);
    }
    String key = s.ProgramCode__c + '-' + s.ProgramCatalogTerm__c;
    if(programMap.containsKey(key)) {
      s.WGUDegreeProgram__r = programMap.get(key);
      s.WGUDegreeProgram__c = programMap.get(key).Id;
      update s;
    } else {
      // program not found
      //throw new DegreePlanException('program not found with that code + catalog term');
    }
    return s;
  }

  public Boolean correctProgram(Contact s) {
    if(s.ProgramCode__c != null
       && s.ProgramCatalogTerm__c != null
       && s.WGUDegreeProgram__c != null
       && s.ProgramCode__c == s.WGUDegreeProgram__r.Name
       && s.ProgramCatalogTerm__c == s.WGUDegreeProgram__r.CatalogTerm__c) {
      return true;
    } else if(s.ProgramCode__c == null
        && s.ProgramCatalogTerm__c == null
        && s.WGUDegreeProgram__c == null) {
      return true;
    }
    return false;
  }

  public with sharing class ScenarioManagerViewModel {
      public void markPlanApprovalStatus(String planId,String status) {
        for(ScenarioManagerDegreePlanViewModel p : degreePlans) {
            if(p.PlanId == planId) {
                p.IsApproved = status == 'Mentor Approved' || status == 'Registrar Approved' ? true : false;
                p.ApprovalStatus = status;
                p.ApprovalDate = Date.Today();
            }
        }
      }
      public ScenarioManagerViewModel (Contact student,List<StudentTermViewModel> terms,List<StudentDegreePlans__c> plans, Decimal tuitionPerTerm) {
        PreviousTermsCU = 0;
        FutureTermsCU = 0;
        this.TotalCU = 0;
        TotalTuition=0;
        Integer mincu = 1;
        HistoricalTerms = new List<Date>();
        AllFutureTermsDates = new List<Date>();
        PreviousTermsData = new List<ScenarioManagerTermData>();
        FutureTermsData = new List<ScenarioManagerTermData>();
        Date cur = Date.Today();
        Decimal TotalEffort = 0;
        TuitionLeft = 0;
        degreePlans = new List<ScenarioManagerDegreePlanViewModel>();
        for(StudentDegreePlans__c plan : plans) {
            if(plan.CurrentPlan__c) {
              for(StudentTerm__c term : plan.StudentTerms__r) {
                if(term.EndDate__c < Date.Today()
                  && term.Name != '000000'
                  && term.Name != '111111') {
                    HistoricalTerms.add(term.StartDate__c);
                }
              }
            }
            ScenarioManagerDegreePlanViewModel p = new ScenarioManagerDegreePlanViewModel(plan,tuitionPerTerm);
            if(largestDegreePlan == null || largestDegreePlan.FutureTerms.size() < p.FutureTerms.size()) {
                largestDegreePlan = p;
            }
            degreePlans.add(p);
        }

        if(student.WGUDegreeProgram__r.ProgramLevel__r.Name == 'GR') {
            mincu = MINCUPERTERMGRAD;
        } else {
            mincu = MINCUPERTERMUNDERGRAD;
        }

        for(StudentTermViewModel term : terms) {
            
            this.TotalCU += term.cu;
            if(term.startDate == Date.newInstance(1900,1,1)
              || term.startDate == Date.newInstance(1901,1,1)) {
                continue;
            }
            ScenarioManagerTermData smtd = new ScenarioManagerTermData();
            smtd.TermDate = term.StartDate;
            smtd.CU = term.cu;

            if(term.Tuition != null) {
                smtd.Tuition = term.Tuition;
                TotalTuition += term.Tuition;
            } else {
                smtd.Tuition = 0;
            }
            smtd.Effort = term.Effort;
            TotalEffort += term.Effort;

            smtd.OTP = term.otp;
            if(term.StartDate > cur) {
                if(term.Tuition != null)
                    TuitionLeft += term.Tuition;
                FutureTermsData.add(smtd);
                FutureTermsCU += term.cu;
            } else {
                if(term.EndDate < cur) {
                    PreviousTermsData.add(smtd);
                    PreviousTermsCU += term.cu;
                } else {
                   CurrentTermData = smtd;
                }
            }
        }
        if(this.TotalCU / Decimal.valueOf(mincu*terms.size()) < 1) {
            OTP = false;
        } else {
            OTP = true;
        }
        HumanReadableTimeLeft = HumanReadableDateInterval(cur,terms[terms.size()-1].EndDate);
        AverageEffort = TotalEffort / terms.size();
      }
      public void removeTerm(StudentTerm__c t) {
        for(ScenarioManagerDegreePlanViewModel s : degreePlans) {
          s.removeTerm(t);
        }
      }
      public String termIdForTermCodeInCurrentPlan(String termCode) {
        for(ScenarioManagerDegreePlanViewModel s : degreePlans) {
          if(s.PlanName == 'Current Plan') {
            return s.TermCodeToId.get(termCode);
          }
        }
        return null;
      }
      public List<ScenarioManagerDegreePlanViewModel> degreePlans {get;set;}
      public ScenarioManagerDegreePlanViewModel largestDegreePlan {get;set;}
      public List<ScenarioManagerTermData> PreviousTermsData {get;set;}
      public Decimal PreviousTermsCU {get;set;}
      public ScenarioManagerTermData CurrentTermData {get;set;}
      public List<Date> AllFutureTermsDates {get;set;}
      public List<Date> HistoricalTerms {get;set;}
      public List<ScenarioManagerTermData> FutureTermsData {get;set;}
      public Decimal FutureTermsCU {get;set;}
      public Decimal TotalCU {get;set;}
      public Decimal TotalTuition {get;set;}
      public Decimal TuitionLeft {get;set;}
      public Boolean OTP {get;set;}
      public Decimal AverageEffort {get;set;}
      public String HumanReadableTuitionLeft {get;set;}
      public String HumanReadableTimeLeft {get;set;}
 }
  public with sharing class ScenarioManagerTermData {
    public Date TermDate {get;set;}
    public Decimal CU {get;set;}
    public Boolean OTP {get;set;}
    public Decimal Effort {get;set;}
    public Decimal Tuition {get;set;}
 }
 public with sharing class ScenarioManagerDegreePlanViewModel {
    public ScenarioManagerDegreePlanViewModel(StudentDegreePlans__c plan,Decimal tuitionPerTerm) {
        this.PlanName = plan.Name;
        this.PlanId = plan.Id;
        this.TermCodeToId = new Map<String,String>();
        this.Terms = new List<Date>();
        this.FutureTerms = new List<Date>();
        this.ApprovalStatus = plan.ApprovalStatus__c;
        this.ApprovalDate = plan.ApprovalDate__c;
        this.IsApproved = plan.IsApproved__c;
        this.TuitionPerTerm = tuitionPerTerm;
        for(StudentTerm__c t : plan.StudentTerms__r) {
            TermCodeToId.put(t.Name,t.Id);
            if(t.StartDate__c > Date.Today()) {
                this.FutureTerms.add(t.StartDate__c);
            }
            if(t.StartDate__c <= Date.Today() && t.EndDate__c >= Date.Today()) {
                CurrentTerm = t.StartDate__c;
            }
            this.Terms.add(t.StartDate__c);
        }
        this.TuitionLeft = this.FutureTerms.size() * this.TuitionPerTerm;
        this.TimeLeft =
          HumanReadableDateInterval(
            Date.Today(),
            FDPUtilities.getTermEndDateFromStartDate(this.Terms.get(this.Terms.size()-1))
          );
    }
    public void removeTerm(StudentTerm__c term) {
      this.TermCodeToId.remove(term.Name);
      List<Date> newTermsList = new List<Date>();
      for(Date d : this.Terms) {
        if(d != term.StartDate__c) {
          newTermsList.add(d);
        }
      }
      this.Terms = newTermsList;
      List<Date> newFutureTermsList = new List<Date>();
      for(Date d : this.FutureTerms) {
        if(d != term.StartDate__c) {
          newFutureTermsList.add(d);
        }
      }
      this.FutureTerms = newFutureTermsList;
      this.TuitionLeft = this.FutureTerms.size() * this.TuitionPerTerm;
      this.TimeLeft =
        HumanReadableDateInterval(
            Date.Today(),
            FDPUtilities.getTermEndDateFromStartDate(this.Terms.get(this.Terms.size()-1))
        );
    }

    public String PlanName {get;set;}
    public String PlanId {get;set;}
    public Map<String,String> TermCodeToId {get;set;}
    public List<Date> Terms {get;set;}
    public Date CurrentTerm {get;set;}
    public Decimal TuitionLeft {get;set;}
    public String TimeLeft {get;set;}
    public Decimal TuitionPerTerm;
    public List<Date> FutureTerms {get;set;}
    public Date ApprovalDate {get;set;}
    public String ApprovalStatus {get;set;}
    public Boolean IsApproved {get;set;}
  }

 public static String HumanReadableDateInterval(Date date1,Date date2) {
    //TODO: implement num days - NOT!
    //if this doesn't work try...
    //go through every day and check if the year changed.
    //then check if the month changed
    //then check the leftover days when the month and year match
    String human = '';
    Decimal monthsBetween = Math.abs(Math.floor(date1.monthsBetween(date2)));
    Integer yearsBetween = Integer.valueOf(Math.floor(monthsBetween / 12));
    if(yearsBetween > 0) {
        human += String.valueOf(yearsBetween) + ' Year';
        if(yearsBetween > 1) {
            human += 's';
        }
    }
    Integer mBetween = Math.mod(Integer.valueOf(monthsBetween),12);
    if(mBetween > 0) {
        if(yearsBetween > 0)
          human += ' ';
        human += String.valueOf(mBetween) + ' Month';
        if(mBetween > 1) {
            human += 's';
        }
    }
    return human;
 }

   public with sharing class StudentTermViewModel implements Comparable {

        public String name {get;set;}
        public Decimal cu {get;set;}
        public Decimal mincu {get;set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public String id {get;set;}
        public String studentDegreePlan {get;set;}
        public Decimal TermNumber {get;set;}
        public String status {get;set;}
        public List<StudentCourseViewModel> HistoricalCourses {get;set;}
        public List<StudentCourseViewModel> RemainingCourses {get;set;}
        public Decimal Effort {get;set;}
        public boolean otp  {get;set;}
        public boolean expand  {get;set;}
        public String programlevel {get;set;}
        public Decimal Tuition {get;set;}
        public String TermSubName {get;set;}
        public Integer NumUnenrolledCourses {get;set;}
        public Boolean Approved {get;set;}
        public String ApprovalStatus {get;set;}
        public Date ApprovalDate {get;set;}
        public Boolean NoEmptyDates {get;set;}
        public Boolean CurrentTerm {get;set;}
        public Boolean NextTerm {get;set;}
        public Boolean ShowDatesMessage {get;set;}
        public Integer completedCU {get;set;}
        public Integer unenrolledCUs {get;set;}
        public Integer historicalCU {get;set;}
        public Boolean Visible {get;set;}

        //reviewed 3/19/2012
        public StudentTermViewModel(StudentTerm__c st,Contact student) {
            cu=0;
            completedCU = 0;
            unenrolledCUs = 0;
            endDate=st.EndDate__c;
            historicalCU = 0;
            id=st.Id;
            Name=st.Name;
            expand=true;
            startDate=st.StartDate__c;
            studentDegreePlan=st.StudentDegreePlan__c;
            Approved = st.Approved__c;
            ApprovalStatus = st.ApprovalStatus__c;
            ApprovalDate = st.ApprovalDate__c;
            CurrentTerm = false;
            NextTerm = false;
            Visible = true;
            ShowDatesMessage = false;
            if(endDate >= Date.Today() && startDate <= Date.Today()) {
                CurrentTerm = true;
                ShowDatesMessage = true;
            }
            if(startDate <= Date.Today().addMonths(6) && endDate >= Date.Today().addMonths(6)) {
                NextTerm = true;
                if(startDate <= Date.Today().addMonths(1)) {
                    ShowDatesMessage = true;
                }
            }
            if(!Approved
              && endDate < Date.Today()
              && st.Name != '111111') {
                Approved = true;
                ApprovalStatus = 'Mentor Approved';
                ApprovalDate = Date.Today();
            }
            NoEmptyDates = true;
            HistoricalCourses = new List<StudentCourseViewModel>();
            RemainingCourses = new List<StudentCourseViewModel>();
            Effort=0;
            NumUnenrolledCourses=0;
            otp=false;
            Contact materializedStudent = student;
            if(materializedStudent.WGUDegreeProgram__r.ProgramLevel__r.Name == 'GR') {
                mincu = MINCUPERTERMGRAD;
            }
            else {
                mincu = MINCUPERTERMUNDERGRAD;
            }
            programlevel = materializedStudent.WGUDegreeProgram__r.ProgramLevel__r.Name;
        }

        // needs review
        public void addCourse(StudentCourseViewModel course) {
          if (course.cu==null )course.cu=0;
            if (course.status!='Completed' && course.status != 'Failed'){
                if(course.status != 'Enrolled' && course.status != 'Submitted') {
                    NumUnenrolledCourses++;
                    unenrolledCUs += Integer.valueOf(course.cu);
                }
                RemainingCourses.add(course);
            } else {
                if(course.Status == 'Completed') {
                    completedCU += Integer.valueOf(course.cu);
                }
                historicalCU += Integer.valueOf(course.cu);
                HistoricalCourses.add(course);
            }
            if((course.StartDate == null || course.EndDate == null) && course.Status == 'Planned') {
                NoEmptyDates = false;
            }
            if(course.status != 'Failed')
            cu=cu+course.cu;
            // Calculate the averaged effort
            Decimal rawEffort = 0;
            Decimal numCourses = RemainingCourses.size() + HistoricalCourses.size();
            for(StudentCourseViewModel icourse : RemainingCourses) {
                rawEffort += icourse.Effort;
            }
            for(StudentCourseViewModel icourse : HistoricalCourses) {
                rawEffort += icourse.Effort;
            }
            Effort = Math.round(rawEffort / numCourses);
            if(cu >= mincu) {
                otp = true;
            }
            else {
                otp = false;
            }
        }

         public void removeCourse(StudentCourseViewModel course) {
            if (course.status!='Completed' && course.Status != 'Failed') {
                if(course.status != 'Enrolled' && course.status != 'Submitted') {
                    NumUnenrolledCourses--;
                    unenrolledCUs -= Integer.valueOf(course.cu);
                }
                NoEmptyDates = true;
                for (integer i=0;i<remainingcourses.size();i++){
                    StudentCourseViewModel c = remainingcourses.get(i);
                    if (c.id==course.id){
                        remainingCourses.remove(i);
                        cu=cu-course.cu;
                        continue;
                    }
                    if((c.StartDate == null || c.EndDate == null) && c.Status == 'Planned') {
                        NoEmptyDates = false;
                    }
                }
                // Calculate the averaged effort
                Decimal rawEffort = 0;
                Decimal numCourses = RemainingCourses.size() + HistoricalCourses.size();
                for(Integer counter=0; counter<remainingCourses.size(); counter++) {
                    rawEffort += RemainingCourses.get(counter).cu;
                }
                for(Integer counter=0; counter<HistoricalCourses.size(); counter++) {
                    rawEffort += HistoricalCourses.get(counter).cu;
                }
                if (numCourses==0) return;
                Effort = Math.round(rawEffort / numCourses);
                if(cu >= mincu) {
                    otp = true;
                }
                else {
                    otp = false;
                }
            }
        }

        public Integer compareTo(Object compareTo) {
          StudentTermViewModel t = (StudentTermViewModel)compareTo;
          if(StartDate == t.StartDate) return 0;
          if(StartDate > t.StartDate) return 1;
          return -1;
        }

        public Date getGradDate() {
          Date lastDate = null;
          for (StudentCourseViewModel c : RemainingCourses) {
            if(c.EndDate != null && (
                  lastDate==null || c.EndDate > lastDate
              )) {
              lastDate = c.EndDate;
            }
          }
          if(lastDate == null) {
            lastDate = this.EndDate;
          }
          return lastdate;
        }

        //reviewed 3/19/2012
        public void toggleExpand() {
            expand=!expand;
        }
    }

    public with sharing class StudentCourseCheckboxViewModel {
        public Boolean Disabled {get;set;}
        public String Tooltip {get;set;}
        public Boolean Checked {get;set;}
        public StudentCourseCheckboxViewModel() {
            Disabled = false;
            Tooltip = 'Click to enroll';
            Checked = false;
        }
    }

    public with sharing class StudentAssessmentViewModel {
      public String Color {get;set;}
      public String Character {get;set;}
      public String Type {get;set;}
      public String Title {get;set;}
      public String BannerCode {get;set;}
      public StudentAssessmentViewModel() {}
    }

    public with sharing class StudentCourseViewModel implements Comparable {

        public Decimal CU  {get;set;}
        public Date StartDate  {get;set;}
        public Date EndDate  {get;set;}
        public Date CompletedDate {get;set;}
        public Date EnrollDate {get;set;}
        public String Id  {get;set;}
        public String Name  {get;set;}
        public String Title  {get;set;}
        public String Status  {get;set;}
        public String CompletedStatus {get;set;}
        public String FlagTooltip {get;set;}
        public String StudentId  {get;set;}
        public String TermId  {get;set;}
        public Decimal TermSequence  {get;set;}
        public String pWGUCourseId;
        public String wgucourseversionid{get;set;}
        public String WGUCourseId {get{
          return pWGUCourseId;
        } set {
          pWGUCourseId = value;
        }}
        public StudentTermViewModel term {get;set;}
        public Decimal Effort {get;set;}
        public Integer Version {get;set;}
        public Integer MajorVersion {get;set;}
        public Integer MinorVersion {get;set;}
        public String CosId {get;set;}
        public String CoStudyUrl {get;set;}
        public String CosTarget {get;set;}
        public StudentCourseCheckboxViewModel checkbox {get;set;}
        public List<StudentAssessmentViewModel> assessments {get;set;}
        public String coursetype{get;set;}
        public String newWGUCoursetitle {get;set;}
        public Date termplusoneDate{get;set;}

        public Integer compareTo(Object compareTo) {
          StudentCourseViewModel compareToSCVM = (StudentCourseViewModel)compareTo;
          if(this.term.TermNumber == 0) {
            if(this.Title > compareToSCVM.Title) {
              return 1;
            } else if(this.Title < compareToSCVM.Title) {
              return -1;
            }
          }
          if(this.CompletedDate > compareToSCVM.CompletedDate) {
            return 1;
          }
          if(this.CompletedDate < compareToSCVM.CompletedDate) {
            return -1;
          }
          if(this.StartDate > compareToSCVM.StartDate) {
            return 1;
          }
          if(this.StartDate < compareToSCVM.StartDate) {
            return -1;
          }
          if(this.EnrollDate > compareToSCVM.EnrollDate) {
            return 1;
          }
          if(this.EnrollDate < compareToSCVM.EnrollDate) {
            return -1;
          }
          if(this.TermSequence > compareToSCVM.TermSequence) {
            return 1;
          }
          if(this.TermSequence < compareToSCVM.TermSequence) {
            return -1;
          }
          if(this.Title > compareToSCVM.Title) {
            return 1;
          }
          if(this.Title < compareToSCVM.Title) {
            return -1;
          }
          return 0;
        }

         //reviewed 3/19/2012

        public StudentCourseViewModel(StudentCourse__c course,String pCoStudyUrl,String pPortalUserId, Boolean isEmployee) {
          coursetype=course.CourseType__c;
          WGUCourse__c wguCourse = course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r;
          if(coursetype=='Course'){
            if(wguCourse == null || wguCourse.CompetencyUnits__c==null) {
              cu = 0;
            } else {
              cu = wguCourse.CompetencyUnits__c;
            }
            if(wguCourse != null) {
              title=wguCourse.Title__c;
            } else {
              title = '';
            }
            wgucourseversionid=course.StudentCourseVersion__r.WGUCourseVersion__r.id;
            if(course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CCN__c != null) {
              if(wguCourse.Name != null && wguCourse.Name != wguCourse.CCN__c && isEmployee) {
                //Name = wguCourse.CCN__c + '/' + wguCourse.Name;
                Name = wguCourse.Name;
              } else {
                //Name = wguCourse.CCN__c;
                Name = wguCourse.Name;
              }
            } else {
              Name = course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.Name;
            }
            pWGUCourseId = course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__c;
            Version = Integer.valueOf(course.StudentCourseVersion__r.WGUCourseVersion__r.Version__c);
            MajorVersion = Integer.valueOf(course.StudentCourseVersion__r.WGUCourseVersion__r.MajorVersion__c);
            MinorVersion = Integer.valueOf(course.StudentCourseVersion__r.WGUCourseVersion__r.MinorVersion__c);
          }else{
            cu=0;
            name=course.WGULicenseRequirement__r.requirementcode__C;
            title=course.WGULicenseRequirement__r.name;
          }
          Status=course.Status__c;
          StartDate=course.StartDate__c;
          EndDate=course.EndDate__c;
          Id=course.Id;
          if(course.StudentCourseVersion__r.WGUCourseVersion__r.CourseOfStudyId__c != null) {
            CosId = String.valueOf(Integer.valueOf(course.StudentCourseVersion__r.WGUCourseVersion__r.CourseOfStudyId__c));
          } else {
            CosId = null;
          }
          Integer iframeVersion = 0;
          if(ApexPages.CurrentPage().getParameters().get('iframe') != null)
            iframeVersion = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('iframe'));
          if(pCoStudyUrl == null)
            pCoStudyUrl = '';
          if(this.CosId != null) {
            if(iframeVersion >= 4) {
              //this.CoStudyUrl = 'javascript:document.open_cos_id(' + this.CosId + ')';
              this.CoStudyUrl = 'javascript:document.open_cos_code(' + this.Name + ')';
              this.CosTarget = '';
            } else {
              //this.CoStudyUrl = pCoStudyUrl + '/courses/' + this.CosId + '/bookmark';
              this.CoStudyUrl = pCoStudyUrl + '/courses/for/' + this.Name;
              if(pPortalUserId != null) {
                this.CoStudyUrl += '?user=' + pPortalUserId;
              }
              this.CosTarget = '_blank';
            }
          } else {
            this.CoStudyUrl = pCoStudyUrl + '/courses/for/' + this.name;
            if(pPortalUserId != null) {
              this.CoStudyUrl += '?user=' + pPortalUserId;
            }
            this.CosTarget = '_blank';
          }
          CompletedStatus=course.StudentCourseVersion__r.StudentCompletionCourse__r.Status__c;
          termId=course.StudentTerm__c;
          termSequence=course.TermSequence__c;
          checkbox = new StudentCourseCheckboxViewModel();
          if(Status == 'Planned') {
            if(course.StudentTerm__r.Approved__c) {
              checkbox.Tooltip = 'Click to enroll';
            } else {
              checkbox.Disabled = true;
              if(StartDate == null || EndDate == null) {
                checkbox.Tooltip = 'Choose dates first';
              } else {
                checkbox.Tooltip = 'Requires mentor approval';
              }
            }
            this.FlagTooltip = this.Status;
          } else if(Status == 'Enrolled') {
            checkbox.Tooltip = 'Enrolled on ' + DegreePlanController.formatNumberedDate(EnrollDate);
            checkbox.Checked = true;
            checkbox.Disabled = true;
            this.FlagTooltip = this.Status;
          } else if (Status == 'Submitted') {
            checkbox.Tooltip = 'Submitted for enrollment';
            checkbox.Checked = true;
            checkbox.Disabled = true;
            this.FlagTooltip = this.Status;
          } else if(Status == 'Completed' || Status == 'Failed') {
            this.FlagTooltip = this.CompletedStatus;
          }

          if(cu < EFFORTLOWTHRESHOLD) { Effort = EFFORTNONEVALUE; }
          else if(cu < EFFORTMEDIUMTHRESHOLD) { Effort = EFFORTLOWVALUE; }
          else if(cu < EFFORTHIGHTHRESHOLD) { Effort = EFFORTMEDIUMVALUE; }
          else { Effort = EFFORTHIGHVALUE; }
        }
    }

    public static String formatNumberedDate(Date pdate) {
        String formatted = '';
        if(pdate == null) {
            return '';
        }
        if(pdate.month() < 10) {
            formatted += '0';
        }
        formatted += pdate.month();
        formatted += '/';
        if(pdate.day() < 10) {
            formatted += '0';
        }
        formatted += pdate.day();
        formatted += '/';
        formatted += pdate.year();
        return formatted;
    }

    public static String formatShortDate(Date pdate) {
        String formatted = '';
        if(pdate == null) {
            return '';
        }
        Map<Integer,String> mToMonth = new Map<Integer,String>();
        mToMonth.put(1,'January');
        mToMonth.put(2,'February');
        mToMonth.put(3,'March');
        mToMonth.put(4,'April');
        mToMonth.put(5,'May');
        mToMonth.put(6,'June');
        mToMonth.put(7,'July');
        mToMonth.put(8,'August');
        mToMonth.put(9,'September');
        mToMonth.put(10,'October');
        mToMonth.put(11,'November');
        mToMonth.put(12,'December');
        formatted += mToMonth.get(pdate.month());
        formatted += ' ' + pdate.day();
        Integer day = math.mod(pdate.day(),10);
        if(day == 1 || day == 2 || day == 3) {
          if(day == 1)
            formatted += 'st';
          else if(day == 2)
            formatted += 'nd';
          else if(day == 3)
            formatted += 'rd';
        } else
          formatted += 'th';
        return formatted;
    }

    public static String formatLongDate(Date pdate) {
        // There's no formatter in apex code for date :)
        String formatted = '';
        if(pdate == null) {
            return '';
        }
        Map<Integer,String> mToMonth = new Map<Integer,String>();
        mToMonth.put(1,'January');
        mToMonth.put(2,'February');
        mToMonth.put(3,'March');
        mToMonth.put(4,'April');
        mToMonth.put(5,'May');
        mToMonth.put(6,'June');
        mToMonth.put(7,'July');
        mToMonth.put(8,'August');
        mToMonth.put(9,'September');
        mToMonth.put(10,'October');
        mToMonth.put(11,'November');
        mToMonth.put(12,'December');
        formatted += mToMonth.get(pdate.month());
        formatted += ' ' + pdate.day();
        formatted += ', ' + pdate.year();
        return formatted;
    }

    public with sharing class LicenseChooserViewModel {
      public List<StateWithLicensesViewModel> StatesWithLicensures {get;set;}
      public Boolean DisplayView {get;set;}
      public LicenseChooserViewModel(){}
      public LicenseChooserViewModel(Contact student) {
        LicenseChooserViewModel v = new LicenseChooserViewModel();
        FDPStateAndLicensure fsl = new FDPStateAndLicensure(student);
        this.DisplayView = fsl.needLicensure();
        this.StatesWithLicensures = new List<StateWithLicensesViewModel>();
        Map<String,Set<WGUStateLicensure__c>> stateMaps = fsl.getStateLicensureMap();
        for(String state : statemaps.keySet()) {
          StateWithLicensesViewModel slvm = new StateWithLicensesViewModel(state,stateMaps.get(state));
          this.StatesWithLicensures.add(slvm);
        }
      }
    }

    public with sharing class StateWithLicensesViewModel {
      public String StateName {get;set;}
      public List<LicenseViewModel> Licenses {get;set;}
      public StateWithLicensesViewModel(String sn,Set<WGUStateLicensure__c> sls) {
        this.StateName = sn;
        this.Licenses = new List<LicenseViewModel>();
        for(WGUStateLicensure__c sl : sls) {
          LicenseViewModel lvm = new LicenseViewModel();
          lvm.LicenseName = sl.Name;
          lvm.LicenseId = sl.Id;
          Licenses.add(lvm);
        }
      }
    }

    public with sharing class LicenseViewModel {
      public String LicenseName {get;set;}
      public String LicenseId {get;set;}
    }

    public static String formatDate(Date pdate) {
        // There's no formatter in apex code for date :)
        String formatted = '';
        if(pdate == null) {
            return '';
        }
        Map<Integer,String> mToMonth = new Map<Integer,String>();
        mToMonth.put(1,'January');
        mToMonth.put(2,'February');
        mToMonth.put(3,'March');
        mToMonth.put(4,'April');
        mToMonth.put(5,'May');
        mToMonth.put(6,'June');
        mToMonth.put(7,'July');
        mToMonth.put(8,'August');
        mToMonth.put(9,'September');
        mToMonth.put(10,'October');
        mToMonth.put(11,'November');
        mToMonth.put(12,'December');
        formatted += mToMonth.get(pdate.month());
        formatted += ' ' + pdate.year();
        return formatted;
    }

    //Reviewed on 3/26/12
    public  List<GradSelect> getGradSelects(Contact student) {
        //return new List<GradSelect>();
        AggregateResult[] res = [select sum(Course__r.CompetencyUnits__c) TotalCU,Program__c
            from WGUCourseInProgram__c
            where Program__c =:student.WGUDegreeProgram__r.Id
            group by Program__c];
        List<GradSelect> gradSelects = new List<GradSelect>();
        List<Integer> CUs = new List<Integer>{};
        Boolean graduate = student.WGUDegreeProgram__r.ProgramLevel__r.Name == 'GR' ? true : false;
        if(graduate) {
             CUs = new List<Integer>{8, 10, 12, 14, 16, 18, 20, 24, 28, 32};
        } else {
            CUs = new List<Integer>{12, 14, 16, 18, 20, 24, 28, 32};
        }
        gradSelects.add(new GradSelect('Terms Left','termsLeft'));
        gradSelects.add(new GradSelect('CU per Term','CU'));
        gradSelects.add(new GradSelect('Approx Tuition Left','approxTuitionLeft'));
        gradSelects.add(new GradSelect('Planned Graduation Date','plannedGradDate'));
        Date startDate = FDPUtilities.getNextTermStartDate();
        DegreePlanGenerator gen = new DegreePlanGenerator();
        gen.Student = student;
        gen.planName = 'Sample';
        Integer cuIndex = -1;
        if(tuitionPerTerm == null)
            tuitionPerTerm = 0;
        for(Integer i=0;i<CUs.size();i++){
            Integer CU = CUs[i];
            gen.MinCUPerTerm = CU;
            gen.IncludeCurrentTerm = includeCurrentTerm; // from the controller
            StudentDegreePlans__c plan = gen.generateStudentDegreePlan();
            Integer termCount = gen.getFutureTermCount();

            Date gradDate = null;
            if(gen.getLastTerm() != null) {
              gradDate = gen.getLastTerm().EndDate__c;
            }
            GradSelect gs = gradSelects[0];
            if(!gs.containsLabel(String.valueOf(termCount))) {
                cuIndex++;
                gs.addGradOption(String.valueOf(termCount),cuIndex);
                gs = gradSelects[3];
                gs.addGradOption(FDPUtilities.formatDateLongMonthYear(gradDate),cuIndex);
                gs = gradSelects[2];
                Decimal tuition = 0;
                tuition = termCount*tuitionPerTerm;
                String t = FDPUtilities.formatCurrency(tuition,0);
                gs.addGradOption(t,cuIndex);
            }
            gs = gradSelects[1];
            gs.addGradOption(String.valueOf(CU),cuIndex);
        }
        return gradSelects;
    }

    public with sharing class GradSelect {
            public String Label {get;set;}
            public String Name {get;set;}
            public List<GradOption> Options {get;set;}

            public GradSelect(String SelectLabel, String SelectName) {
                Label = SelectLabel;
                Name = SelectName;
                Options = new List<GradOption>();
            }

            public void addGradOption(String opLabel,Integer cuIndex) {
                GradOption option  = new GradOption(Options.size(),opLabel,cuIndex);
                Options.add(option);
            }

            public Boolean containsLabel(String label) {
                for(GradOption go : Options) {
                    if(go.Label == label)
                        return true;
                }
                return false;
            }
    }

    public with sharing class GradOption {
           public Integer Index {get;set;}
           public String Label {get;set;}
           public Integer CUIndex {get;set;}
           public GradOption(Integer pindex,String plabel,Integer pcuIndex) {
                Index = pindex;
                Label = plabel;
                CUIndex = pcuIndex;
           }
    }
}