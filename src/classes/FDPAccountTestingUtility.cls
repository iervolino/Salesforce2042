public with sharing class FDPAccountTestingUtility {
  List<StudentCompletionTask__c> studentCompletionTasks;
  List<StudentCompletionCourse__c> studentCompletionCourseVersions;
  List<StudentCourseRegistration__c> studentCourseRegistrations;
  List<StudentTermBreak__c> studentTermBreaks;
  public Enum CourseCompletionType {Passed, Failed, Transfer, RequirementMet, RequirementSatisfied, Waived, PreviousProgram}
  public with sharing class CompletedCourse {
    public WGUCourse__c course;
    public WGUCourseVersion__c version;
    public CourseCompletionType cType;
    public Date completionDate;
  }
  Map<String,CompletedCourse> completedCourses;
  Set<Id> completedCourseIds;
  AccountTestingUtility atu;
  public AccountTestingUtility.TestingStudentInfo student1 {
    get {
      return atu.student1;
    }
  }
  public AccountTestingUtility.TestingMentorInfo mentor1 {
    get {
      return atu.mentor1;
    }
  }

  public AccountTestingUtility.TestingStudentInfo student2 {
    get {
      return atu.student2;
    }
  }

  public AccountTestingUtility.TestingMentorInfo mentor2 {
    get {
      return atu.mentor2;
    }
  }

  public List<AccountTestingUtility.TestingStudentInfo> students;
  public List<AccountTestingUtility.TestingMentorInfo> mentors;

  public FDPAccountTestingUtility(String pBoxName) {
    atu = new AccountTestingUtility(pBoxName);
    studentCompletionTasks = new List<StudentCompletionTask__c>();
    studentCourseRegistrations = new List<StudentCourseRegistration__c>();
    completedCourses = new Map<String,CompletedCourse>();
    completedCourseIds = new Set<Id>();
    studentCompletionCourseVersions = new List<StudentCompletionCourse__c>();
    students = new List<AccountTestingUtility.TestingStudentInfo>();
    students.add(atu.student1);
    students.add(atu.student2);
    mentors = new List<AccountTestingUtility.TestingMentorInfo>();
    mentors.add(atu.mentor1);
    mentors.add(atu.mentor2);
    studentTermBreaks = new List<StudentTermBreak__c>();
  }

  public void createTermBreakInfo() {
    for(AccountTestingUtility.TestingStudentInfo student : students) {
      StudentTermBreak__c tb = new StudentTermBreak__c();
      tb.PIDM__c = student.PIDM;
      tb.EffectiveTermCode__c = student.Contact.TermCode__c;
      tb.Code__c = 'A';
      tb.StartDate__c = Date.today().addMonths(6);
      tb.EndDate__c = Date.today().addMonths(9);
      tb.Unique_Id__c = tb.PIDM__c + '-' + tb.EffectiveTermCode__c;
      studentTermBreaks.add(tb);
    }
  }

  public void saveAccounts() {
    atu.save();
  }

  public void onlyWorkWith(String pidm) {
    atu.onlyWorkWith(pidm);
    atu.save();
    AccountTestingUtility.TestingStudentInfo stu;
    for(AccountTestingUtility.TestingStudentInfo student : students) {
      if(stu.pidm == pidm) {
        stu = student;
      }
    }
    students.clear();
    students.add(stu);
  }

  public List<StudentCourseRegistration__c> addEnrolledCourse(WGUCourse__c course, Date pWhen) {
    for(AccountTestingUtility.TestingStudentInfo student : students) {
      StudentCourseRegistration__c scr = new StudentCourseRegistration__c();
      scr.PIDM__c = student.PIDM;
      scr.TermCode__c = FDPUtilities.generateTermCode(pWhen);
      scr.StartDate__c = pWhen;
      scr.EndDate__c = pWhen;
      scr.BannerActivityDate__c = pWhen;
      scr.CourseCode__c = course.Name;
      studentCourseRegistrations.add(scr);
    }
    return studentCourseRegistrations;
  }


  public void addCompletionCourse(WGUCourse__c course, Date pWhen, CourseCompletionType pType) {
    CompletedCourse c = new CompletedCourse();
    c.course = course;
    c.completionDate = pWhen;
    c.cType = pType;
    String foo = String.valueOf(course.Id) + ':' + String.valueOf(pWhen);
    completedCourses.put(foo,c);
    completedCourseIds.add(course.Id);
  }

  public void addPassedCourse(WGUCourse__c course, Date pWhen) {
    addCompletionCourse(course,pWhen,CourseCompletionType.Passed);
  }

  public void addFailedCourse(WGUCourse__c course, Date pWhen) {
    addCompletionCourse(course,pWhen,CourseCompletionType.Failed);
  }

  public void addTransferCourse(WGUCourse__c course) {
    addCompletionCourse(course,null,CourseCompletionType.Transfer);
  }

  public void addRequirementMetCourse(WGUCourse__c course, Date pWhen) {
    addCompletionCourse(course,pWhen,CourseCompletionType.RequirementMet);
  }

  public void addRequirementSatisfiedCourse(WGUCourse__c course, Date pWhen) {
    addCompletionCourse(course,pWhen,CourseCompletionType.RequirementMet);
  }

  public void addWaivedCourse(WGUCourse__c course) {
    addCompletionCourse(course,null,CourseCompletionType.Waived);
  }

  public void addPreviousProgramCourse(WGUCourse__c course, Date pWhen) {
    addCompletionCourse(course,pWhen,CourseCompletionType.PreviousProgram);
  }

  public void addPassedCourseVersion(WGUCourseVersion__c cv, Date pWhen) {
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Passed';
    }
  }

  public void addFailedCourseVersion(WGUCourseVersion__c cv, Date pWhen) {
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Not Passed';
    }
  }

  public void addRequirementSatisfiedCourseVersion(WGUCourseVersion__c cv, Date pWhen) {
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Requirement Satisfied';
    }
  }

  public void addRequirementMetCourseVersion(WGUCourseVersion__c cv, Date pWhen) {
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Requirement Met';
    }
  }

  public void addWaivedCourseVersion(WGUCourseVersion__c cv) {
    Date pWhen = Date.newInstance(1901,1,1);
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Waived';
    }
  }

  public void addPreviousProgramCourseVersion(WGUCourseVersion__c cv, Date pWhen) {
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Passed';
      c.InPreviousProgram__c = true;
    }
  }

  public void addTransferCourseVersion(WGUCourseVersion__c cv) {
    Date pWhen = Date.newInstance(1901,1,1);
    for(StudentCompletionCourse__c c : addCompletedCourseVersion(cv,pWhen)) {
      c.Status__c = 'Transferred';
    }
  }

  public List<StudentCompletionCourse__c> addCompletedCourseVersion(WGUCourseVersion__c cv, Date pWhen) {
    List<StudentCompletionCourse__c> courses = new List<StudentCompletionCourse__c>();
    for(AccountTestingUtility.TestingStudentInfo student : students) {
      StudentCompletionCourse__c c = new StudentCompletionCourse__c();
      c.PIDM__c = student.contact.PIDM__c;
      c.StatusDate__c = pWhen;
      c.BannerActivityDate__c = pWhen;
      c.TermCode__c = FDPTestingUtilities.generateTermCode(pWhen);
      c.Name = cv.WGUCourse__r.Name;
      //c.WGUCourseVersion__c = cv.Id;
      studentCompletionCourseVersions.add(c);
      courses.add(c);
    }
    return courses;
  }

  public void addFailedAssessment(WGUCourseCompletionTask__c task, Date pWhen) {
    for(StudentCompletionTask__c t : addCompletionTask(task,pWhen)) {
      t.RequirementComplete__c = false;
      t.AssessmentStatus__c = 'Failed';
    }
  }
  public void addPassedAssessment(WGUCourseCompletionTask__c task, Date pWhen) {
    for(StudentCompletionTask__c t : addCompletionTask(task,pWhen)) {
      t.RequirementComplete__c = true;
      t.AssessmentStatus__c = 'Passed';
    }
  }
  public void addTransferCredit(WGUCourseCompletionTask__c task) {
    Date pWhen = Date.newInstance(1901,1,1);
    for(StudentCompletionTask__c t : addCompletionTask(task,pWhen)) {
      t.RequirementComplete__c = true;
      t.AssessmentStatus__c = 'Passed';
    }
  }

  private List<StudentCompletionTask__c> addCompletionTask(WGUCourseCompletionTask__c task, Date pWhen) {
    List<StudentCompletionTask__c> tasks = new List<StudentCompletionTask__c>();
    for(AccountTestingUtility.TestingStudentInfo student : students) {
      StudentCompletionTask__c t = new StudentCompletionTask__c();
      t.StudentPIDM__c = student.contact.PIDM__c;
      t.StatusDate__c = pWhen;
      t.TermCode__c = FDPTestingUtilities.generateTermCode(pWhen);
      t.Name = task.Name;
      studentCompletionTasks.add(t);
      tasks.add(t);
    }
    return tasks;
  }

  public void fetchCourseVersions() {
    List<WGUCourseVersion__c> courseVersions = [select
      MajorVersion__c,
      WGUCourse__r.Id,
      WGUCourse__r.Name,
      WGUCourse__c,
      PAMSCourseId__c
      from WGUCourseVersion__c
      where WGUCourse__r.Id in :completedCourseIds];
    Map<String,WGUCourseVersion__c> courseToCourseVersion = new Map<String,WGUCourseVersion__c>();
    for(WGUCourseVersion__c cv : courseVersions) {
      if(!courseToCourseVersion.containsKey(cv.WGUCourse__r.Id)) {
        courseToCourseVersion.put(cv.WGUCourse__r.Id,cv);
      } else if(courseToCourseVersion.get(cv.WGUCourse__r.Id).MajorVersion__c < cv.MajorVersion__c) {
        courseToCourseVersion.put(cv.WGUCourse__r.Id,cv);
      }
    }
    for(String key : completedCourses.keySet()) {
      CompletedCourse cc = completedCourses.get(key);
      String thisId = key.split(':',2).get(0);
      cc.version = courseToCourseVersion.get(thisId);
      if(cc.cType == CourseCompletionType.Passed) {
        addPassedCourseVersion(cc.version,cc.completionDate);
      } else if(cc.cType == CourseCompletionType.Failed) {
        addFailedCourseVersion(cc.version,cc.completionDate);
      } else if(cc.cType == CourseCompletionType.RequirementMet) {
        addRequirementMetCourseVersion(cc.version,cc.completionDate);
      } else if(cc.cType == CourseCompletionType.RequirementSatisfied) {
        addRequirementSatisfiedCourseVersion(cc.version,cc.completionDate);
      } else if(cc.cType == CourseCompletionType.Waived) {
        addWaivedCourseVersion(cc.version);
      } else if(cc.cType == CourseCompletionType.PreviousProgram) {
        addPreviousProgramCourseVersion(cc.version,cc.completionDate);
      } else {
        addTransferCourseVersion(cc.version);
      }
    }
  }

  public void saveCourseVersions() {
    fetchCourseVersions();
    for(StudentCompletionCourse__c c : studentCompletionCourseVersions) {
    }
    upsert studentCompletionCourseVersions;
  }

  public void saveTermBreaks() {
    upsert studentTermBreaks;
  }

  public void saveAssessments() {
    upsert studentCompletionTasks;
  }

  public void saveCourseRegistrations() {
    upsert studentCourseRegistrations;
  }

}