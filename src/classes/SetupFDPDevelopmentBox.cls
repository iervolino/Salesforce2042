public class SetupFDPDevelopmentBox {
    public FDPAccountTestingUtility atu;
    public PAMSData pams;
    public String environment;

    public SetupFDPDevelopmentBox() {
      this.environment = getBoxName();
    }

    public SetupFDPDevelopmentBox(String env) {
      this.environment = env;
    }

    public void createAccounts() {
        atu = new FDPAccountTestingUtility(this.environment);
    }

    public void saveAccounts() {
        atu.saveAccounts();
    }

    public void createPAMSData() {
        pams = new PAMSData();
        pams.createData();
    }

    public static void refreshBagginsData() {
        refreshStudentData('13');
    }

    public void onlyWorkWith(String pidm) {
      atu.onlyWorkWith(pidm);
    }

    public static void refreshStudentData(String pidm) {
        delete [select id from StudentCourse__c where Student__r.PIDM__c = :pidm];
        delete [select id from StudentCourseVersion__c where Student__r.PIDM__c = :pidm];
        delete [select id from StudentTerm__c where Student__r.PIDM__c = :pidm];
        delete [select id from StudentDegreePlans__c where Student__r.PIDM__c = :pidm];
        delete [select id from StudentCompletionTask__c where Student__r.PIDM__c = :pidm];
        delete [select id from StudentCompletionCourse__c where Student__r.PIDM__c = :pidm];
        SetupFDPDevelopmentBox devbox = new SetupFDPDevelopmentBox();
        devbox.createAccounts();
        devbox.onlyWorkWith(pidm);
        devbox.saveAccounts();
        devbox.pams.selectCompletionTasks();
        devbox.pams.selectCourses();
        devbox.assignStudentToProgram();
        devbox.createStudentCompletionTasks();
    }

    public static void refreshSchweddyData() {
        refreshStudentData('11');
    }

    public static String getBoxName() {
      String env = '';
        if(Test.isRunningTest()) {
          env = getRandomString(10);
        } else {
          List<User> u = [select Name,Username from User where Name = 'Gordon Child'];
          if(u.size() == 0) {
            env = 'fdpbox';
          } else {
            env = u[0].Username.replaceFirst('^gchild@solutionstream\\.com','');
            if(env.length() != 0) {
                env = env.replaceFirst('^\\.','');
            }
          }
        }
        return env;
    }

    public void deleteAllData() {
      delete [select id from StudentCourse__c];
      delete [select id from StudentCourseVersion__c];
      delete [select id from StudentCourseRegistration__c];
      delete [select id from StudentTerm__c];
      delete [select id from StudentDegreePlans__c];
      delete [select id from StudentCompletionTask__c];
      delete [select id from StudentCompletionCourse__c];
      delete [select id from Tuition__c];
      delete [select id from WGUCourseCompletionTask__c];
      delete [select id from WGUCompletionTaskInCourseVersion__c];
      delete [select id from WGUCourseVersion__c];
      delete [select id from WGUCourse__c];
      delete [select id from WGUCourseInProgram__c];
      delete [select id from WGUDegreeProgram__c];
      delete [select id from KeyValue__c where name in ('UG','GR')];
      delete [select id from FDPApproval__c];
      delete [select id from WGULicenseRequirement__c];
      delete [select id from StudentLicenseHistory__c];
      delete [select id from WGUStateLicensure__c];
      delete [select id from StudentEulaAgreement__c];
      delete [select id from WGUEula__c];
      delete [select id from StudentTermBreak__c];
    }

    public static void refreshAllData() {
        SetupFDPDevelopmentBox devbox = new SetupFDPDevelopmentBox();
        //devbox.deleteAllData();
        devbox.createPAMSData();
        devbox.createAccounts();
        devbox.saveAccounts();
        devbox.saveTermBreaks();
        devbox.assignStudentToProgram();
        devbox.createStudentTransferCourses();
        devbox.createStudentEnrollment();
        devbox.createStudentCompletionTasks();
        devbox.saveStudentData();
        devbox.createStudentTuitionData();
        //devbox.createStudentLicenseHistory();
        devbox.createEulaData();
    }

    public static void refreshNoCompletedCourses() {
        SetupFDPDevelopmentBox devbox = new SetupFDPDevelopmentBox();
        devbox.deleteAllData();
        devbox.createPAMSData();
        devbox.createAccounts();
        devbox.saveAccounts();
        devbox.saveTermBreaks();
        devbox.assignStudentToProgram();
        devbox.createStudentTransferCourses();
        devbox.createStudentEnrollment();
        devbox.saveStudentData();
        devbox.createEulaData();
    }

    public static void refreshCurrentTermThisMonth() {
      SetupFDPDevelopmentBox devbox = new SetupFDPDevelopmentBox();
        devbox.deleteAllData();
        devbox.createPAMSData();
        devbox.createAccounts();
        devbox.setCurrentTermThisMonth();
        devbox.saveAccounts();
        devbox.saveTermBreaks();
        devbox.assignStudentToProgram();
        devbox.createStudentTransferCourses();
        //devbox.createStudentEnrollment();
        devbox.saveStudentData();
        devbox.createEulaData();
    }

    public static void refreshWithProspect() {
      SetupFDPDevelopmentBox devbox = new SetupFDPDevelopmentBox();
      devbox.deleteAllData();
      devbox.createPAMSData();
      devbox.createAccounts();
      devbox.setStudentAsProspect();
      devbox.setCurrentTermNextMonth();
      devbox.saveAccounts();
      devbox.assignStudentToProgram();
      devbox.createStudentTransferCourses();
      devbox.saveStudentData();
      devbox.createEulaData();
    }

    public void saveTermBreaks() {
      atu.createTermBreakInfo();
      atu.saveTermBreaks();
    }

    public void setCurrentTermThisMonth() {
      for(AccountTestingUtility.TestingStudentInfo s : atu.students) {
        Date termStart = Date.Today();
        termStart = Date.newInstance(termStart.Year(),termStart.Month(),1);
        s.contact.TermStartDate__c = termStart;
        s.contact.TermEndDate__c = termStart.addMonths(6).addDays(-1);
      }
    }

    public void setCurrentTermNextMonth() {
      for(AccountTestingUtility.TestingStudentInfo s : atu.students) {
        Date termStart = Date.Today().addMonths(1);
        termStart = Date.newInstance(termStart.Year(),termStart.Month(),1);
        s.contact.TermStartDate__c = termStart;
        s.contact.TermEndDate__c = termStart.addMonths(6).addDays(-1);
      }
    }

    public void setStudentAsProspect() {
      List<Opportunity> opps = new List<Opportunity>();
      for(AccountTestingUtility.TestingStudentInfo s : atu.students) {
        s.contact.Status__c = 'IN';
        Opportunity o = new Opportunity(
            Name = s.FirstName + ' ' + s.LastName,
            CareStatus__c = 'CLRD - Cleared to Start',
            StageName = 'Prospect',
            CloseDate = Date.Today(),
            StudentContact__c = s.contact.Id);
        opps.add(o);
      }
      insert opps;
    }

    public static String getRandomString(Integer sLength) {
      string randomString = '';
      while(randomString.length() < sLength) {
        Integer i = Math.mod(Crypto.getRandomInteger(),255);
        List<Integer> myIs = new List<Integer>();
        myIs.add(i);
        String s = String.fromCharArray(myIs);
        Pattern p = Pattern.compile('[a-z]');
        Matcher m = p.matcher(s);
        if(m.matches()) {
          randomString += s;
        }
      }
      return randomString;
    }

    public void assignStudentToProgram() {
        List<Contact> students = new List<Contact>();
        atu.student1.contact.WGUDegreeProgram__c = pams.programs.get(0).Id;
        atu.student2.contact.WGUDegreeProgram__c = pams.programs.get(0).Id;
        atu.student1.contact.WGUDegreeProgram__r = pams.programs.get(0);
        atu.student2.contact.WGUDegreeProgram__r = pams.programs.get(0);
        students.add(atu.student1.contact);
        students.add(atu.student2.contact);

        update students;
        students = [select Id,
          Name,
          ProgramCode__c,
          PIDM__c,
          StudentId__c,
          TermStartDate__c,
          TermEndDate__c,
          TermCode__c,
          MentorName__c,
          ProgramName__c,
          WGUDegreeProgram__r.Id,
          WGUDegreeProgram__r.Name,
          WGUDegreeProgram__r.TuitionPerTerm__c,
          WGUDegreeProgram__r.CatalogTerm__c,
          WGUDegreeProgram__r.ProgramLevel__r.Name,
          EulaAgreementDate__c
          from Contact where Id in :students];
        for(Contact s : students) {
          if(s.Id == atu.student1.contact.Id) {
            atu.student1.contact = s;
          } else if(s.Id == atu.student2.contact.Id) {
            atu.student2.contact = s;
          }
        }
    }
   public void createStudentLicenseHistory() {
       StudentLicenseHistory__C hist=new StudentLicenseHistory__C(student__C=atu.student1.contact.id, WGUStateLicensure__C=pams.licensures[0].id);
            insert hist;
        }

   public void createStudentEnrollment() {
     Date currentTermDate = atu.student1.contact.TermStartDate__c;
      atu.addEnrolledCourse(pams.courses.get(17),currentTermDate);
      atu.addEnrolledCourse(pams.courses.get(16),currentTermDate);
   }

   public void saveStudentData() {
     atu.saveAssessments();
     atu.saveCourseVersions();
     atu.saveCourseRegistrations();
   }

   public void createStudentTransferCourses() {
        atu.addTransferCredit(pams.getTask('FCM1',0));
        atu.addTransferCourse(pams.getCourse('FCM1'));

        atu.addTransferCredit(pams.getTask('LAE1',0));
        atu.addTransferCourse(pams.getCourse('LAE1'));

        atu.addTransferCredit(pams.getTask('LUT1',0));
        atu.addTransferCourse(pams.getCourse('LUT1'));

        atu.addTransferCredit(pams.getTask('CLC1',0));
        atu.addTransferCredit(pams.getTask('CLC1',1));
        atu.addTransferCourse(pams.getCourse('CLC1'));
   }

    public void createStudentCompletionTasks() {
        Date currentTermDate = atu.student1.contact.TermStartDate__c;
        //Transfer Courses
        // BEGIN
        // This course should not appear because it's a waived course
        atu.addTransferCredit(pams.getTask('CMF1',0));
        atu.addWaivedCourse(pams.getCourse('CMF1'));
        atu.addPreviousProgramCourse(pams.getCourse('CPW5'),currentTermDate.addYears(-3));
        atu.addPreviousProgramCourse(pams.getCourse('IOS1'),currentTermDate.addYears(-3));
        // END


        // Term 1
        atu.addPassedAssessment(pams.tasks.get(8),currentTermDate.addMonths(-12));
        atu.addPassedAssessment(pams.tasks.get(9),currentTermDate.addMonths(-12));
        atu.addPassedCourse(pams.courses.get(6),currentTermDate.addMonths(-12));

        atu.addPassedAssessment(pams.tasks.get(10),currentTermDate.addMonths(-12));
        atu.addPassedCourse(pams.courses.get(7),currentTermDate.addMonths(-12));

        atu.addFailedAssessment(pams.tasks.get(11),currentTermDate.addMonths(-12));
        atu.addFailedCourse(pams.courses.get(8),currentTermDate.addMonths(-12));

        atu.addPassedAssessment(pams.tasks.get(12),currentTermDate.addMonths(-12));
        atu.addPassedAssessment(pams.tasks.get(13),currentTermDate.addMonths(-12));
        atu.addPassedCourse(pams.courses.get(9),currentTermDate.addMonths(-12));


        // Term 2
        atu.addPassedAssessment(pams.tasks.get(11),currentTermDate.addMonths(-6));
        atu.addRequirementMetCourse(pams.courses.get(8),currentTermDate.addMonths(-6));

        atu.addPassedAssessment(pams.tasks.get(14),currentTermDate.addMonths(-6));
        atu.addPassedCourse(pams.courses.get(10),currentTermDate.addMonths(-6));

        //testing wacky icons
        //atu.addFailedAssessment(pams.tasks.get(15),currentTermDate.addMonths(-6));
        atu.addFailedCourse(pams.courses.get(11),currentTermDate.addMonths(-6));

        atu.addPassedAssessment(pams.tasks.get(16),currentTermDate.addMonths(-6));
        //atu.addFailedAssessment(pams.tasks.get(17),currentTermDate.addMonths(-6));
        atu.addFailedCourse(pams.courses.get(12),currentTermDate.addMonths(-6));

        atu.addPassedAssessment(pams.tasks.get(18),currentTermDate.addMonths(-6));
        atu.addPassedCourse(pams.courses.get(13),currentTermDate.addMonths(-6));

        // Term 3
        //atu.addPassedAssessment(pams.tasks.get(15),currentTermDate);
        atu.addPassedCourse(pams.courses.get(11),currentTermDate);

        /*atu.addPassedAssessment(pams.tasks.get(17),currentTermDate);
        atu.addPassedCourse(pams.courses.get(12),currentTermDate);

        atu.addPassedAssessment(pams.tasks.get(19),currentTermDate);
        atu.addPassedCourse(pams.courses.get(14),currentTermDate);

        atu.addPassedAssessment(pams.tasks.get(20),currentTermDate);
        atu.addPassedAssessment(pams.tasks.get(21),currentTermDate);
        atu.addPassedCourse(pams.courses.get(15),currentTermDate);*/

    }

      public void createCrosswalks() {
      /*  Date cur = Date.today();
        Date cDate = Date.newInstance(cur.year(),cur.addMonths(5).month(),1);
        FDPCrosswalk__C cw1=new FDPCrosswalk__C();
        cw1.name=atu.student1.contact.pidm__C;
        cw1.student__C=atu.student1.contact.id;
        cw1.crosswalkdate__C=cDate;
        WGUcourse__C fr=[select id from wgucourse__C where pamsid__C=17];
        WGUcourse__C to=[select id from wgucourse__C where pamsid__C=117];
        cw1.OldCourse__c=fr.id;
        cw1.newWGUCourse__C=to.id;
        insert cw1;*/

    }

    public void createStudentTuitionData() {
        Integer numberOfPreviousTerms = 6;
        RecordType rt = [select Name,SobjectType from RecordType
          where SobjectType = 'Tuition__c' and Name = 'Student'];
        List<Tuition__c> student_tuitions = new List<Tuition__c>();
        Decimal amount = 2965;
        Date termDate = atu.student1.contact.TermStartDate__c;
        for(Integer i=numberOfPreviousTerms*-1;i<=0;i++) {
            Tuition__c t = new Tuition__c(Amount__c = amount,RecordTypeId = rt.Id,
            TermCode__c = FDPUtilities.generateTermCode(termDate.addMonths(i*6)),
            Name = atu.student1.PIDM);
            student_tuitions.add(t);
        }
        /*for(Integer i=numberOfPreviousTerms*-1;i<=0;i++) {
            Tuition__c t = new Tuition__c(Amount__c = amount,RecordTypeId = rt.Id,
            TermCode__c = FDPUtilities.generateTermCode(termDate.addMonths(i*6)),
            Name = atu.student2.PIDM);
            student_tuitions.add(t);
        }*/
        insert student_tuitions;
    }

    public with sharing class PAMSData {
        Id programLevel;
        List<WGUDegreeProgram__c> programs;
        List<KeyValue__c> values;
        List<WGUCourse__c> courses;
        List<WGUCourse__c> prevCourses;
        public List<WGUCourseCompletionTask__c> tasks {get;set;}
        List<WGUCourseVersion__c> courseVersions;
        Map<Integer,List<WGUCourseVersion__c>> courseToCourseVersions;
        public List <WGUStateLicensure__C> licensures {get;set;}
        public PAMSData() {}
        public WGUCourse__c getCourse(String code) {
          for(WGUCourse__c c : courses) {
            if(c.Name == code) {
              return c;
            }
          }
          for(WGUCourse__c c : prevCourses) {
            if(c.Name == code) {
              return c;
            }
          }
          return null;
        }

        public WGUCourseCompletionTask__c getTask(String code,Integer index) {
          Integer i = 0;
          for(WGUCourseCompletionTask__c t : tasks) {
            if(t.Name.contains(code)) {
              if(i++ == index) {
                return t;
              }
            }
          }
          return null;
        }

        public void createProgram() {
            programLevel = [SELECT ID FROM RecordType WHERE sobjecttype = 'KeyValue__c' AND name='ProgramLevel' LIMIT 1].get(0).id;
            List<KeyValue__c> values = new List<KeyValue__c>();
            values.add(new KeyValue__c(name='UG', value__c='Undergraduate', recordTypeId=programLevel));
            values.add(new KeyValue__c(name='GR', value__c='Graduate', recordTypeId=programLevel));

            insert values;

            WGUDegreeProgram__c prog1 = new WGUDegreeProgram__c(Name='MSRP', PAMSID__c=1, title__c='Bachelors in Situational and Relational Programming',
            IsTestData__c = true, catalogTerm__c = '201204', Active__c=true, programLevel__c=values.get(0).id,HasFieldExp__c = true);
            WGUDegreeProgram__c prog2 = new WGUDegreeProgram__c(Name='MSRPG', PAMSID__c=2, Title__c='Masters in Situational and Relational Programming',
            IsTestData__c = true, catalogTerm__c = '201204', Active__c=true, programLevel__c=values.get(1).id,HasFieldExp__c = false);
            programs = new List<WGUDegreeProgram__c>();
            programs.add(prog1);
            programs.add(prog2);

            insert programs;
        }

        public void selectCourses() {
          courses = [select
            Name,
            Title__c,
            CompetencyUnits__c,
            IsTestData__c,
            PAMSID__c
            from WGUCourse__c];
        }

        public void createCourses() {
            // TODO: Create more courses
            courses = new List<WGUCourse__c>();
            prevCourses = new List<WGUCourse__c>();
            courses.add(new WGUCourse__c(Name='ITF1', CCN__c='ITF101', Title__c='IT Fundamentals I', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=1));
            courses.add(new WGUCourse__c(Name='FCM1', CCN__c='FCM101', Title__c='Foundations of College Mathematics', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=2));
            courses.add(new WGUCourse__c(Name='CMF1', CCN__c='CMF101', Title__c='Communications Foundations', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=3));
            courses.add(new WGUCourse__c(Name='CLC1', CCN__c='CLC101', Title__c='Reasoning and Problem Solving', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=4));
            courses.add(new WGUCourse__c(Name='LAE1', CCN__c='LAE101', Title__c='Language and Communication: Essay', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=5));
            courses.add(new WGUCourse__c(Name='LUT1', CCN__c='LUT101', Title__c='Language and Communication: Presentation', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=6));
            courses.add(new WGUCourse__c(Name='LAT1', CCN__c='LAT101', Title__c='Language and Communication: Research', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=7));
            courses.add(new WGUCourse__c(Name='ITF2', CCN__c='ITF201', Title__c='IT Fundamentals II', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=8));
            courses.add(new WGUCourse__c(Name='TTV1', CCN__c='TTV101', Title__c='IT Fundamentals III', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=9));
            courses.add(new WGUCourse__c(Name='INC1', CCN__c='INC101', Title__c='Integrated Natural Science', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=10));
            courses.add(new WGUCourse__c(Name='INT1', CCN__c='INT101', Title__c='Integrated Natural Science Applications', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=11));
            courses.add(new WGUCourse__c(Name='WDF1', CCN__c='WDF101', Title__c='Web Development Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=12));
            courses.add(new WGUCourse__c(Name='WBT1', CCN__c='WBT101', Title__c='Web Technologies', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=13));
            courses.add(new WGUCourse__c(Name='WBP1', CCN__c='WBP101', Title__c='Web Programming', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=14));
            courses.add(new WGUCourse__c(Name='GAC1', CCN__c='GAC101', Title__c='Finite Mathematics', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=15));
            courses.add(new WGUCourse__c(Name='FMA1', CCN__c='FMA101', Title__c='Finite Mathematics Applications', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=16));
            courses.add(new WGUCourse__c(Name='WOS1', CCN__c='WOS101', Title__c='Windows OS Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=17));
            courses.add(new WGUCourse__c(Name='WSA1', CCN__c='WSA101', Title__c='Windows Server Admin Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=18));
            courses.add(new WGUCourse__c(Name='NWF1', CCN__c='NWF101', Title__c='Network Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=19));
            courses.add(new WGUCourse__c(Name='NWK1', CCN__c='NWK101', Title__c='Networks', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=20));
            courses.add(new WGUCourse__c(Name='QLT1', CCN__c='QLT101', Title__c='Quantitative Literacy: Quantitative Problem Solving and Applications', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=21));
            courses.add(new WGUCourse__c(Name='SCF1', CCN__c='SCF101', Title__c='Security Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=22));
            courses.add(new WGUCourse__c(Name='SEC1', CCN__c='SEC101', Title__c='Security', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=23));
            courses.add(new WGUCourse__c(Name='SDF1', CCN__c='SDF101', Title__c='Software Development Fundamentals', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=24));
            courses.add(new WGUCourse__c(Name='OBL1', CCN__c='OBL101', Title__c='Organizational Behavior and Leadership', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=25));
            courses.add(new WGUCourse__c(Name='LAH1', CCN__c='LAH101', Title__c='Literature, Arts and the Humanities', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=26));
            courses.add(new WGUCourse__c(Name='LAI1', CCN__c='LAI101', Title__c='Literature, Arts and the Humanities: Analysis and Interpretation', CompetencyUnits__c=2, isTestData__c=true, PAMSID__c=27));
            courses.add(new WGUCourse__c(Name='GEO1', CCN__c='GEO101', Title__c='Geography', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=28));
            courses.add(new WGUCourse__c(Name='INP1', CCN__c='INP101', Title__c='Introduction to Programming', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=29));
            courses.add(new WGUCourse__c(Name='DBF1', CCN__c='DBF101', Title__c='Database Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=30));
            courses.add(new WGUCourse__c(Name='WDV1', CCN__c='WDV101', Title__c='Database I', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=31));
            courses.add(new WGUCourse__c(Name='OOD1', CCN__c='OOD101', Title__c='Object Oriented Design and Development', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=32));
            courses.add(new WGUCourse__c(Name='TPV1', CCN__c='TPV101', Title__c='Project Management', CompetencyUnits__c=6, isTestData__c=true, PAMSID__c=33));
            courses.add(new WGUCourse__c(Name='SFW1', CCN__c='SFW101', Title__c='Software I', CompetencyUnits__c=6, isTestData__c=true, PAMSID__c=34));
            courses.add(new WGUCourse__c(Name='WPV1', CCN__c='WPV101', Title__c='Software II', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=35));
            courses.add(new WGUCourse__c(Name='TWA1', CCN__c='TWA101', Title__c='Technical Writing', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=36));
            courses.add(new WGUCourse__c(Name='CPW5', CCN__c='CPW501', Title__c='IT - Software Capstone Written Project', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=37));
            //courses.add(new WGUCourse__c(name='CLC1', title__c='Reasoning and Problem Solving', competencyUnits__c=6, isTestData__c=true, PAMSID__c=21));
            //courses.add(new WGUCourse__c(name='CLC1', title__c='Reasoning and Problem Solving', competencyUnits__c=3, isTestData__c=true, PAMSID__c=20));
            //courses.add(new WGUCourse__c(name='CLC1', title__c='Reasoning and Problem Solving', competencyUnits__c=3, isTestData__c=true, PAMSID__c=20));
            prevCourses.add(new WGUCourse__c(Name='IOS1', CCN__c='IOS101', Title__c='Apple OS Fundamentals', CompetencyUnits__c=3, isTestData__c=true, PAMSID__c=117));
            prevCourses.add(new WGUCourse__c(Name='IOS2', CCN__c='IOS201', Title__c='Advanced Apple OS', CompetencyUnits__c=4, isTestData__c=true, PAMSID__c=118));
            List<WGUCourse__c> allCourses = new List<WGUCourse__c>();
            allCourses.addAll(courses);
            allCourses.addAll(prevCourses);
            insert allCourses;
        }

        public List<WGUCourseVersion__c> createCourseVersions(List<WGUCourse__c> courss) {
          Integer i=1;
          List<WGUCourseVersion__c> courseVersions = new List<WGUCourseVersion__c>();
          for(WGUCourse__c c : courss) {
            courseToCourseVersions.put(Integer.valueOf(c.PAMSID__c),new List<WGUCourseVersion__c>());
            WGUCourseVersion__c cv = new WGUCourseVersion__c();
            cv.WGUCourse__c = c.Id;
            cv.Name = c.Name;
            cv.MajorVersion__c = 1;
            cv.PamsCourseId__c = c.PAMSId__c;
            cv.PAMSVERSIONID__c = i++;
            cv.CourseOfStudyId__c = i+1;
            courseVersions.add(cv);
            courseToCourseVersions.get(Integer.valueOf(c.PAMSID__c)).add(cv);
            if(math.mod(i,6)==0) {
              WGUCourseVersion__c cv2 = new WGUCourseVersion__c();
              cv2.WGUCourse__c = c.Id;
              cv2.Name = c.Name;
              cv2.MajorVersion__c = 2;
              cv2.PAMSVERSIONID__c = i++;
              cv2.CourseOfStudyId__c = i+1;
              cv2.PAMSCourseId__c = c.PAMSId__c;
              courseVersions.add(cv2);
              courseToCourseVersions.get(Integer.valueOf(c.PAMSID__c)).add(cv2);
            }
          }
          return courseVersions;
        }

        public void createCourseVersions() {
          courseToCourseVersions = new Map<Integer,List<WGUCourseVersion__c>>();
          List<WGUCourseVersion__c> wcv = new List<WGUCourseVersion__c>();
          wcv.addAll(createCourseVersions(courses));
          wcv.addAll(createCourseVersions(prevCourses));
          insert wcv;
        }

        public void selectCompletionTasks() {
          tasks = [select Name,
            Title__c,
            BannerCode__c,
            RecordTypeId,
            Type__c,
            Active__c,
            IsTestData__c,
            PAMSID__c
            from WGUCourseCompletionTask__c];
        }

        public void createCompletionTasks() {
          tasks = new List<WGUCourseCompletionTask__c>();
          List<WGUCompletionTaskInCourseVersion__c> ct2cvs = new List<WGUCompletionTaskInCourseVersion__c>();
          ID assessmentRT = [SELECT ID FROM RecordType WHERE sobjecttype = 'WGUCourseCompletionTask__c' AND name='Assessment' LIMIT 1].get(0).id;
          Integer i=0;
          for(WGUCourse__c c : courses) {
            WGUCourseCompletionTask__c cct = new WGUCourseCompletionTask__c();
            cct.Name = c.Name;
            cct.Title__c = c.Title__c;
            cct.BannerCode__c = c.Name;
            cct.RecordTypeId = assessmentRT;
            if(math.mod(i,4)==0) {
              cct.Type__c = 'Objective';
            } else {
              cct.Type__c = 'Performance';
            }
            cct.Active__c = true;
            cct.IsTestData__c = true;
            cct.PAMSID__c = 'assessment-' + c.Name;
            tasks.add(cct);
            WGUCourseCompletionTask__c cct2;
            if(math.mod(i++,3)==0) {
              cct2 = new WGUCourseCompletionTask__c();
              cct2.Name = c.Name + '2';
              cct2.Title__c = c.Title__c + '2';
              cct2.BannerCode__c = c.Name + '2';
              cct2.RecordTypeId = assessmentRT;
              cct2.Type__c = 'Objective';
              cct2.Active__c = true;
              cct2.IsTestData__c = true;
              cct2.PAMSID__c = 'assessment-' + c.Name + '2';
              tasks.add(cct2);
            }

            for(WGUCourseVersion__c cv : courseToCourseVersions.get(Integer.valueOf(c.PAMSID__c))) {
              WGUCompletionTaskInCourseVersion__c ctcv = new WGUCompletionTaskInCourseVersion__c();
              ctcv.WGUCourseVersion__c = cv.Id;
              ctcv.WGUCourseCompletionTask__r = cct;
              ct2cvs.add(ctcv);
              if(cct2 != null) {
                WGUCompletionTaskInCourseVersion__c ctcv2 = new WGUCompletionTaskInCourseVersion__c();
                ctcv2.WGUCourseVersion__c = cv.Id;
                ctcv2.WGUCourseCompletionTask__r = cct2;
                ct2cvs.add(ctcv2);
              }
            }
          }
          insert tasks;
          for(WGUCompletionTaskInCourseVersion__c ctcv : ct2cvs) {
            ctcv.WGUCourseCompletionTask__c = ctcv.WGUCourseCompletionTask__r.Id;
          }
          insert ct2cvs;
        }

        public void createCourseMapping() {
            List<WGUCourseInProgram__c> mapping = new List<WGUCourseInProgram__c>();
            Integer sequence = 0;
            for (WGUCourse__c course : courses) {
                sequence++;
                for(WGUDegreeProgram__c prog : programs) {
                  mapping.add(new WGUCourseInProgram__c(PAMSCourseId__c=course.PAMSID__c, PAMSProgramId__c=prog.PAMSID__c, sequence__c=sequence, isTestData__c=true));
                }
            }
            insert mapping;
        }

        public void createTuitionData() {
            List<Tuition__c> tuitions = new List<Tuition__c>();
            Date termDate = Date.newInstance(2009,1,1);
            Decimal amount = 2890;
            RecordType rt = [select Name from RecordType where Name = 'Degree Program'];
            while(termDate < Date.newInstance(2030,1,1)) {
                String termCode = FDPUtilities.generateTermCode(termDate);
                for(WGUDegreeProgram__c prog : programs) {
                    Tuition__c t = new Tuition__c(Amount__c = amount,
                    Name=prog.Name,RecordTypeId = rt.Id,TermCode__c=termCode);
                    tuitions.add(t);
                }
                termDate = termDate.addMonths(1);
            }
            insert tuitions;
        }
        public void createLicenserequirements(){
            list<WGUStateLicensure__C> ls=new List<WGUStateLicensure__C> ();
            WGUStateLicensure__C l1= new  WGUStateLicensure__C(name='Utah Teacher licensure',state__C='Utah',isActive__C=true,PAMSID__c=12,PAMSstateID__c=1);
            WGUStateLicensure__C l2= new  WGUStateLicensure__C(name='Penn Teacher licensure',state__C='Pennsylvania',isActive__C=true,PAMSID__c=54345,PAMSstateID__c=2);
            ls.add(l1);
            ls.add(l2);
            insert ls;
            licensures =ls;
            list<WGULicenseRequirement__C> ls2=new  list<WGULicenseRequirement__C>();
            WGULicenseRequirement__C lr1=new WGULicenseRequirement__C(program__C='MSRP',WGUStateLicensure__C=l1.id,isActive__C=true,name='Utah teacher math requirement test',requirementcode__c='UTM1',PAMSLicenseID__c=22);
            WGULicenseRequirement__C lr11=new WGULicenseRequirement__C(program__C='MSRP',WGUStateLicensure__C=l1.id,isActive__C=true,name='Utah teacher math requirement advanced test',requirementcode__c='UTMA',PAMSLicenseID__c=23);
            WGULicenseRequirement__C lr2=new WGULicenseRequirement__C(program__C='MSRP',WGUStateLicensure__C=l2.id,isActive__C=true,name='Pennsylvania teacher English requirement test',requirementcode__c='PETR',PAMSLicenseID__c=24);
            ls2.add(lr1);
           ls2.add(lr11);
           ls2.add(lr2);
            insert ls2;

        }
        public void createData() {
            createProgram();
            createCourses();
            createCourseVersions();
            createCompletionTasks();
            createCourseMapping();
            createTuitionData();
            createLicenserequirements();
        }
    }

    public void createEulaData() {
      String eulaText = '<div>\n'
        + '    <p>\n'
        + 'Western Governors University is committed to ensuring your privacy as a visitor to this website, as an interested party in one of WGU’s degree programs, and as a student in our university. Generally speaking, here’s how we ensure your privacy:\n'
        + '</p><ul>\n'
        + '<li>We require our employees to keep your personal information confidential.</li>\n'
        + '<li>We only authorize access to your personal information to employees and third parties (only AFTER you become a student) who need your information to perform their duties (Further explained below).</li>\n'
        + '<li>We safeguard your personal information through electronic, procedural, and physical means.</li>\n'
        + '</ul><p></p>\n'
        + '\n'
        + '<h3>WEBSITE INFORMATION:</h3>\n'
        + '<p>When you visit the WGU.edu website, the only personal information WGU collects about you is the information you voluntarily provide through our online inquiry or application forms. Any personally identifiable information collected about you on this website is used by WGU to contact you about the university’s programs, administer your application to the university, and provide additional information as needed, potentially including contact via phone or email.</p>\n'
        + '<p>\n'
        + '<strong>WGU will not release, sell, rent, or trade your personal information gathered on the website to any third party for the promotion of other services or products. </strong></p>\n'
        + '<p>\n'
        + 'WGU will collect anonymous non-personally identifiable information about your website visit through pixel tags, sometimes known as cookies. These tags help us track information about your visit and are used to deliver banner advertisements to you on the Internet.\n'
        + '</p>\n'
        + '\n'
        + '<h3>HOW WE TREAT YOUR PERSONAL INFORMATION AS A PROSPECTIVE STUDENT:</h3>\n'
        + '<p>\n'
        + 'As a prospective student, your email address and other personal information will never be shared with third parties. Your assigned WGU Enrollment Counselor and other departments in the university will use your email address and other personal information to provide you with the information you request about your degree program of interest, tuition, financial aid, and any other topics pertaining to enrollment in the university.</p>\n'
        + '<p>\n'
        + 'If you apply or enroll as a WGU student, WGU uses passwords to protect the privacy of applicants and students who use personalized areas of its sites. The highest level of security is used for storing information (SSL encryption). WGU staff monitors the sites for technical reliability.\n'
        + '</p>\n'
        + '\n'
        + '<h3>HOW WE TREAT YOUR PERSONAL INFORMATION AS A STUDENT:</h3>\n'
        + '<p>\n'
        + 'As a WGU student, your personal information (including email address) may be shared with third-party learning resources, assessment sites, and other external vendors who support the academic programs. These vendors are obligated through their agreements with WGU to maintain the privacy of WGU students. Student directory information may be shared with outside institutions and corporations.</p>\n'
        + '\n'
        + '<h3>WGU OPT-OUT POLICY:</h3>\n'
        + '<p>\n'
        + 'At any time, you have the option and the right to request that WGU discontinue further communications via email, phone, or direct mail.</p>\n'
        + '<p>\n'
        + '<strong>To opt out by postal mail, send a written request containing your name and mailing address to:</strong></p>\n'
        + '<p>\n'
        + 'Western Governors University<br>\n'
        + 'ATTN: Enrollment Department<br>\n'
        + '4001 South 700 East, Suite 700<br>\n'
        + 'Salt Lake City, UT 84107</p>\n'
        + '<p>\n'
        + '<strong>To opt out by phone:</strong></p>\n'
        + '<p>\n'
        + 'Call the WGU Enrollment Department toll-free 1-866-225-5948</p>\n'
        + '<p>\n'
        + '<strong>To opt out via WGU’s website:</strong><br>\n'
        + '<a href="https://www.wgu.edu/wgu/unsubscribe">Visit the WGU Preference Center</a></p>\n'
        + '<p>\n'
        + 'You can also send your request via email to <a href="mailto:unsubscribe@wgu.edu">unsubscribe@wgu.edu</a>.</p>\n'
        + '\n'
        + '<h3>FERPA COMPLIANCE:</h3>\n'
        + '<p>\n'
        + 'WGU complies with the protections established under the <strong class="accent">Family Education Rights and Privacy Acts of 1974 (FERPA).</strong> FERPA is a federal law designed to protect the privacy of student education records. FERPA governs the release of education records and access to education records.</p>\n'
        + '<p>\n'
        + 'The FERPA policy is intended to ensure students have the right to inspect and review their education records; the right to amend their education records as appropriate; and the right to control access to their education records. Students have the right to: (1) inspect and review their education records, (2) request amendment to their education records, (3) consent to disclosures of non-directory information, except to the extent that FERPA authorizes disclosure without consent, and (4) file a complaint with the U.S. Department of Education concerning alleged failures by WGU to comply with FERPA requirements.</p>\n'
        + '<p>\n'
        + 'Students have the right to request that their records be amended if they believe the content is inaccurate, misleading, or in violation of their privacy rights. Student directory information may be shared with outside institutions and corporations.</p>\n'
        + '<p>\n'
        + 'For details about WGU’s policy on the use of student information and the procedures WGU has established in accordance with FERPA, please see the <a href="http://kb.wgu.edu/article.asp?article=1161&amp;p=3">WGU Student Handbook</a>. </p>\n'
        + '<p>\n'
        + 'Students who do not wish to be listed in the student directory or to be included on WGU mailing lists may send their request via email to <a href="mailto:unsubscribe@wgu.edu">unsubscribe@wgu.edu</a>.\n'
        + '</p>\n'
        + '  </div>\n';

      WGUEula__c fdpEula = new WGUEula__c();
      fdpEula.EulaText__c = eulaText;
      fdpEula.Name = 'FDP';
      fdpEula.Version__c = 1;
      insert fdpEula;
    }
}