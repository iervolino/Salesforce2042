@isTest
public class TestDegreePlanController {

    @isTest
    public static void test1Integration() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        Test.startTest();
        System.runAs(s) {
          PageReference pageRef = new PageReference('/apex/FDP');
          Test.setCurrentPage(pageRef);
          DegreePlanController dpc = new DegreePlanController();
          dpc.initialize();
          ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
          dpc.createNewDegreePlan();
          StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
        }
        /*User m = [select Name from User where PIDM__c = '16'];
        System.runAs(m) {
        StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
        PageReference pageRef = new PageReference('/apex/FDP');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pidm', '11');
        DegreePlanController dpc = new DegreePlanController();
        dpc.initialize();
        }*/
        Test.stopTest();
    }

    @isTest
    public static void formatNumbersTest() {
      System.assert(DegreePlanController.formatNumberedDate(Date.newInstance(2012,1,1)) == '01/01/2012');
      System.assert(DegreePlanController.formatNumberedDate(Date.newInstance(2012,12,5)) == '12/05/2012');
      System.assert(DegreePlanController.formatShortDate(Date.newInstance(2012,1,1)) == 'January 1st');
      System.assert(DegreePlanController.formatShortDate(Date.newInstance(2012,1,2)) == 'January 2nd');
      System.assert(DegreePlanController.formatShortDate(Date.newInstance(2012,1,3)) == 'January 3rd');
      System.assert(DegreePlanController.formatShortDate(Date.newInstance(2012,1,4)) == 'January 4th');
      System.assert(DegreePlanController.formatNumberedDate(null) == '');
      System.assert(DegreePlanController.formatShortDate(null) == '');
    }

    @isTest
    public static void testSaveStudentLicense() {
      SetupFDPDevelopmentBox.refreshAllData();
      User s = [select Name from User where PIDM__c = '11'];
      Test.startTest();
      System.runAs(s) {
        PageReference pageRef = new PageReference('/apex/FDP');
        Test.setCurrentPage(pageRef);
        DegreePlanController dpc = new DegreePlanController();
        dpc.initialize();
        WGUStateLicensure__c lic = [select id from WGUStateLicensure__c limit 1];
        ApexPages.currentPage().getParameters().put('licenseId',lic.Id);
        dpc.saveStudentLicense();
        dpc.acceptEula();
      }
      Test.stopTest();
    }


    @isTest
    public static void testDeleteDegreePlan() {
      SetupFDPDevelopmentBox.refreshAllData();
      User s = [select Name from User where PIDM__c = '11'];
      Test.startTest();
      System.runAs(s) {
        PageReference pageRef = new PageReference('/apex/FDP');
        Test.setCurrentPage(pageRef);
        DegreePlanController dpc = new DegreePlanController();
        dpc.initialize();
        ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
        dpc.createNewDegreePlan();
        StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
        ApexPages.currentPage().getParameters().put('degreePlanId',plan.Id);
        dpc.deleteDegreePlan();
      }
      Test.stopTest();
    }

    @isTest
    public static void test2Integration() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'].get(0);
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
                ApexPages.currentPage().getHeaders().put('USER-AGENT','Mozilla/4.0(compatible; MSIE 7.0b; Windows NT 6.0)');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            dpc.loadGradSelects();
            Test.stopTest();
        }
    }

    @isTest
    public static void test5LoadDegreePlan() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
                ApexPages.currentPage().getHeaders().put('USER-AGENT','Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
            dpc.createNewDegreePlan();
            ApexPages.currentPage().getParameters().put('planId',dpc.currentPlanId);
            dpc.loadDegreePlan();
            Test.stopTest();
        }
    }

    @isTest
    public static void test7RecalculatePlan() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
            dpc.createNewDegreePlan();
            ApexPages.currentPage().getParameters().put('planId',dpc.planningPlanId);
            ApexPages.currentPage().getParameters().put('desiredCU','12');
            ApexPages.currentPage().getParameters().put('includeCurrentTerm','false');
            dpc.recalculatePlan();
            Test.stopTest();
        }
    }

    @isTest
    public static void TestRecalcPlanIncludeTerm() {
      SetupFDPDevelopmentBox.refreshAllData();
      User s = [select Name from User where PIDM__c = '11'];
      System.runAs(s) {
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/FDP');
        Test.setCurrentPage(pageRef);
        DegreePlanController dpc = new DegreePlanController();
        dpc.initialize();
        ApexPages.currentPage().getParameters().put('planName','TestPlan Gordon');
        dpc.createNewDegreePlan();
        ApexPages.currentPage().getParameters().put('planId',dpc.planningPlanId);
        ApexPages.currentPage().getParameters().put('desiredCU','12');
        ApexPages.currentPage().getParameters().put('includeCurrentTerm','true');
        dpc.recalculatePlan();
        Test.stopTest();
      }
    }

    @isTest
    public static void TestChangeDatesAfterApproval() {
    }

    @isTest
    public static void TestExceptionsEverywhere() {
      SetupFDPDevelopmentBox.refreshAllData();
      User s = [select Name from User where PIDM__c = '11'];
      System.runAs(s) {
        Test.startTest();
        PageReference pageRef = new PageReference('/apex/FDP');
        Test.setCurrentPage(pageRef);
        DegreePlanController dpc = new DegreePlanController();

        ApexPages.currentPage().getParameters().put('throwTestException','1');
        dpc.initialize();
        dpc.deleteDegreePlan();
        dpc.deleteAllPlans();
        dpc.saveStudentLicense();
        dpc.loadGradSelects();
        dpc.acceptEula();
        dpc.loadGradSelects(null);
        dpc.UpdateStartAndEnddateAndReload();
        dpc.UpdateStartAndEnddate();
        dpc.approveTerm();
        dpc.enrollCourses();
        dpc.toggleExpand();
        dpc.togglePastTerms();
        dpc.putCourseInTerm();
        dpc.recalculatePlan();
        dpc.createNewDegreePlan();
        dpc.createNewDegreePlanAndRecalculate();
        dpc.createNewDegreePlanAndMoveCourse();
        dpc.loadDegreePlan();
        dpc.loadDegreePlan(null,null);
        ApexPages.currentPage().getParameters().clear();
        dpc.deleteDegreePlan();
        dpc.deleteAllPlans();


        Test.stopTest();
      }
    }

    @isTest
    public static void test8createNewPlanAndRecalc() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            ApexPages.currentPage().getParameters().put('planName','TestPlan2 Gordon');
            ApexPages.currentPage().getParameters().put('desiredCU','12');
            ApexPages.currentPage().getParameters().put('includeCurrentTerm','false');
            dpc.createNewDegreePlanAndRecalculate();
            Test.stopTest();
        }
    }

    @isTest
    public static void testMoveCourseInCorrectTerm() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            StudentCompletionCourse__c c = new StudentCompletionCourse__c();
            c.BannerActivityDate__c = Date.today();
            c.Complete__c = true;
            c.Name = 'SCF1';
            c.PIDM__c = '11';
            c.StatusDate__c = Date.Today();
            c.TermCode__c = '201102';
            c.Status__c = 'Passed';

            insert c;

            StudentCourseRegistration__c r = new StudentCourseRegistration__c();
            r.BannerActivityDate__c = Date.Today();
            r.CourseCode__c = 'SEC1';
            r.PIDM__c = '11';
            r.TermCode__c = FDPUtilities.generateTermCode(Date.Today());
            r.StartDate__c = Date.Today();
            r.EndDate__c = Date.Today();
            insert r;

            dpc = new DegreePlanController();
            dpc.initialize();
            Test.stopTest();
        }
    }

    @isTest
    public static void test8deletePlan() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '16'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
            dpc.createNewDegreePlan();
            ApexPages.currentPage().getParameters().put('degreePlanId',dpc.planningPlanId);
            dpc.deleteDegreePlan();
            Test.stopTest();
        }
    }

    //@isTest
    public static void test6PutCourseInNewTerm() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
            dpc.createNewDegreePlan();
            string termId = '';
            string courseId = '';
            List<StudentTerm__c> terms = [select Name,
            (select id,Status__c from StudentCourses__r),
            StartDate__c,EndDate__c
            from StudentTerm__c
            where Student__r.Pidm__c = '11'
            and StudentDegreePlan__r.Name = 'Test Plan Gordon'];
            for(StudentTerm__c t : terms) {
                if(t.StartDate__c <= Date.Today().addMonths(12) && t.EndDate__c >= Date.Today().addMonths(12)) {
                  termId = '0';
                  //termId = t.Id;
                } else if(t.StartDate__c <= Date.Today().addMonths(6) && t.EndDate__c >= Date.Today().addMonths(6)) {
                    for(StudentCourse__c c : t.StudentCourses__r) {
                        if(c.Status__c == 'Planned') {
                            courseId = c.Id;
                        }
                    }
                }
            }
            dpc.courseId = courseId;
            dpc.toTermId = termId;
            dpc.putCourseInTerm();
            for(ApexPages.Message m : ApexPages.getMessages()) {
              if(m.getSeverity() == ApexPages.Severity.FATAL
                  || m.getSeverity() == ApexPages.Severity.ERROR) {
                String assertMessage = 'termId: ' + termId;
                assertMessage += ' courseId: ' + courseId;
                if(m.getSummary() != null) {
                  assertMessage += ' message: ' + m.getSummary();
                }
                if(m.getDetail() != null) {
                  assertMessage += ' underlyingException: '
                    + m.getDetail();
                }
                System.assert(false,assertMessage);
              }
            }
            Test.stopTest();
        }
    }

    @isTest
    public static void test4PutCourseInTerm() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '11'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();
            ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
            dpc.createNewDegreePlan();
            string termId = '';
            string courseId = '';
            List<StudentTerm__c> terms = [select Name,
            (select id,Status__c from StudentCourses__r),
            StartDate__c,EndDate__c
            from StudentTerm__c
            where Student__r.Pidm__c = '11'
            and StudentDegreePlan__r.Name = 'Test Plan Gordon'];
            for(StudentTerm__c t : terms) {
                if(t.StartDate__c <= Date.Today().addMonths(6) && t.EndDate__c >= Date.Today().addMonths(6)) {
                    termId = t.Id;
                } else if(t.StartDate__c <= Date.Today() && t.EndDate__c >= Date.Today()) {
                    for(StudentCourse__c c : t.StudentCourses__r) {
                        if(c.Status__c == 'Planned') {
                            courseId = c.Id;
                        }
                    }
                }
            }
            dpc.courseId = courseId;
            dpc.toTermId = termId;
            dpc.putCourseInTerm();
            Test.stopTest();
        }
    }

    @isTest
    public static void test9createNewPlanAndMoveCourse() {
        SetupFDPDevelopmentBox.refreshAllData();
        User s = [select Name from User where PIDM__c = '16'];
        System.runAs(s) {
            Test.startTest();
            //StudentDegreePlans__c plan = [select id from StudentDegreePlans__c where Name = 'Test Plan Gordon' limit 1];
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.initialize();

            string termId = '';
            string courseId = '';
            List<StudentTerm__c> terms = [select Name,
            (select id,Status__c from StudentCourses__r),
            StartDate__c,EndDate__c
            from StudentTerm__c
            where Student__r.Pidm__c = '11'
            and StudentDegreePlan__r.CurrentPlan__c = true
            order by StartDate__c];
            Integer termNumber = 1;
            Integer termNum = 1;
            for(StudentTerm__c t : terms) {
                if(t.StartDate__c <= Date.Today().addMonths(12) && t.EndDate__c >= Date.Today().addMonths(12)) {
                    termNum = termNumber;
                } else if(t.StartDate__c <= Date.Today().addMonths(6) && t.EndDate__c >= Date.Today().addMonths(6)) {
                    for(StudentCourse__c c : t.StudentCourses__r) {
                        if(c.Status__c == 'Planned') {
                            courseId = c.Id;
                        }
                    }
                }
                termNumber++;
            }
            ApexPages.currentPage().getParameters().put('planName', 'Test Plan Gordon');
            ApexPages.currentPage().getParameters().put('courseId',courseId);
            ApexPages.currentPage().getParameters().put('termNumber',String.valueOf(termNum));
            dpc.createNewDegreePlanAndMoveCourse();
            Test.stopTest();
        }
    }

    @isTest
    public static void test3Enrollment() {
        SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
        box.deleteAllData();
        box.createPAMSData();
        box.createAccounts();
        box.saveAccounts();
        box.assignStudentToProgram();
        List<User> usersToGet = [
          select Name,PIDM__c
          from User where PIDM__c in ('16','11')
        ];
        User m = null;
        User s = null;
        for(User u : usersToGet) {
          if(u.PIDM__c == '11') {
            s = u;
          } else {
            m = u;
          }
        }
        List<String> courseIds = new List<String>();
        Test.startTest();
        System.runAs(m) {
            PageReference pageRef = new PageReference('/apex/FDP');
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('pidm', '11');
            DegreePlanController dpc = new DegreePlanController();
            dpc.checkForCoursesInWrongTerm = false;
            dpc.initialize();
            StudentTerm__c term = [select id,(
                select StartDate__c,EndDate__c,Status__c
                from StudentCourses__r
              )
              from StudentTerm__c
              where Student__r.PIDM__c = '11'
              and StudentDegreePlan__r.Name = 'Current Plan'
              and StartDate__c <= Today
              and EndDate__c >= Today];
            for(StudentCourse__c c : term.StudentCourses__r) {
                c.StartDate__c = Date.Today();
                c.EndDate__c = Date.Today();
                if(c.Status__c == 'Planned') {
          courseIds.add(c.Id);
            }
          }
          update term.StudentCourses__r;
          ApexPages.currentPage().getParameters().put('termApprovalStatus','Mentor Approved');
      ApexPages.currentPage().getParameters().put('termId',term.Id);
          dpc.approveTerm();
          List<String> messages = new List<String>();
          for(ApexPages.Message mess : ApexPages.getMessages()) {
            if(mess.getSeverity() == ApexPages.Severity.FATAL) {
              messages.add(String.valueOf(mess));
            }
          }
          
          System.assert(messages.size() == 0,'Got exception: ' + String.valueOf(messages));
        }
        /*
      System.runAs(s) {
          PageReference pageRef = new PageReference('/apex/FDP');
          Test.setCurrentPage(pageRef);
          DegreePlanController dpc = new DegreePlanController();
          dpc.checkForCoursesInWrongTerm = false;
          dpc.initialize();
          String courses = '[';
          courses += '"' + courseIds.remove(0) + '"';
          for(String c : courseIds) {
            courses += ',"' + c + '"';
          }
          courses += ']';
          ApexPages.currentPage().getParameters().put('courseIdsJson', courses);
          dpc.enrollCourses();
        }*/
       Test.stopTest();
    }

    @isTest
    public static void testGetGradOptions() {
      SetupFDPDevelopmentBox.refreshAllData();
      User student = [select Name,Contact.Id from User where PIDM__c = '11'];
      Test.startTest();
      System.runas(student) {
        DegreePlanController controller = new DegreePlanController();
        controller.initialize();
        controller.loadGradSelects(student.Contact);
      }
      Test.stopTest();
    }

    @isTest
    public static void testGetCurrentContactId() {
      SetupFDPDevelopmentBox.refreshAllData();
      User student = [select Name,Contact.Id,Contact.ProgramCode__c from User where PIDM__c = '11'];
      Test.startTest();
      System.runas(student) {
        DegreePlanController controller = new DegreePlanController();
        Contact con=controller.getCurrentContactWithProgramCode();
        System.assertequals(con.ProgramCode__c,student.Contact.ProgramCode__c);
      }
      Test.stopTest();
    }

    @isTest
    public static  void testFormatDate() {
       DegreePlanController controller = new DegreePlanController();
       DegreePlanController.formatDate(date.newInstance(1960, 2, 17));
    }


    @isTest
    public static void testUpdateStartnEndDate() {
      SetupFDPDevelopmentBox.refreshAllData();
      User student = [select Name,Contact.Id from User where PIDM__c = '11'];
      Test.startTest();
      System.runas(student) {
        PageReference pageRef = new PageReference('/apex/FDP');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pidm', '11');
        DegreePlanController controller = new DegreePlanController();
        controller.initialize();
        String courseId = controller.currentTerm.remainingCourses.get(0).Id;
        System.assert(courseId!=null);
        ApexPages.currentPage().getParameters().put('dateCourseId',courseId);
        ApexPages.currentPage().getParameters().put('fromDate','12/27/2012');
        ApexPages.currentPage().getParameters().put('endDate','12/27/2012');
        controller.UpdateStartAndEnddate();
        //controller.updateStartAndEnddate(courseId, '12/27/2012', '12/28/2012');
        StudentCourse__c stc = [
          select StartDate__c,EndDate__c
          from StudentCourse__c
          where id =:courseId];
        System.assert(stc.StartDate__c!=null);
        System.assert(stc.EndDate__c!=null);
      }
      Test.stopTest();
    }

      @isTest
      public static void testUpdateStartnEndDateReload() {
        SetupFDPDevelopmentBox.refreshAllData();
        User student = [select Name,Contact.Id from User where PIDM__c = '11'];
        Test.startTest();
        System.runas(student) {
          PageReference pageRef = new PageReference('/apex/FDP');
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('pidm', '11');
          DegreePlanController controller = new DegreePlanController();
          controller.initialize();
          String courseId = controller.currentTerm.remainingCourses.get(0).Id;
          System.assert(courseId!=null);
          ApexPages.currentPage().getParameters().put('dateCourseId',courseId);
          ApexPages.currentPage().getParameters().put('fromDate','12/27/2012');
          ApexPages.currentPage().getParameters().put('endDate','12/27/2012');
          controller.UpdateStartAndEnddateAndReload();
          //controller.updateStartAndEnddate(courseId, '12/27/2012', '12/28/2012');
          StudentCourse__c stc = [
            select StartDate__c,EndDate__c
            from StudentCourse__c
            where id =:courseId];
          System.assert(stc.StartDate__c!=null);
          System.assert(stc.EndDate__c!=null);
        }
        Test.stopTest();
      }

      @isTest
      public static void testApproval() {
        SetupFDPDevelopmentBox.refreshAllData();
        User m = [select Name from User where PIDM__c = '16'];
        Test.startTest();
        System.runas(m) {
          PageReference pageRef = new PageReference('/apex/FDP');
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('pidm','11');
          DegreePlanController controller = new DegreePlanController();
          controller.initialize();
          List<String> cIds = new List<String>();
          for(DegreePlanController.StudentCourseViewModel c : controller.currentTerm.RemainingCourses) {
            cIds.add(c.Id);
          }
          List<StudentCourse__c> courses = [Select StartDate__c,EndDate__c
            from StudentCourse__c
            where Id in :cIds];
          for(StudentCourse__c c : courses) {
            c.StartDate__c = Date.Today();
            controller.coursesMap.get(c.Id).StartDate = Date.Today();
            c.EndDate__c = Date.Today().addDays(7);
            controller.coursesMap.get(c.Id).EndDate = Date.Today().addDays(7);
          }
          update courses;
          ApexPages.currentPage().getParameters().put('termId',controller.currentTerm.Id);
          controller.approveTerm();
        }
        Test.stopTest();
      }

      @isTest
      public static void testToggleExpand() {
        SetupFDPDevelopmentBox.refreshAllData();
        User student = [select Name,Contact.Id from User where PIDM__c = '11'];
        Test.startTest();
        System.runas(student) {
          PageReference pageRef = new PageReference('/apex/FDP');
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('pidm','11');
          DegreePlanController dpc = new DegreePlanController();
          dpc.initialize();
          ApexPages.currentPage().getParameters().put('toggleTermId',dpc.currentTerm.Id);
          dpc.toggleExpand();
        }
        Test.stopTest();
      }

      @isTest
      public static void testTogglePastTerms() {
        SetupFDPDevelopmentBox.refreshAllData();
        User student = [select Name,Contact.Id from User where PIDM__c = '11'];
        Test.startTest();
        System.runas(student) {
          PageReference pageRef = new PageReference('/apex/FDP');
          Test.setCurrentPage(pageRef);
          ApexPages.currentPage().getParameters().put('pidm', '11');
          DegreePlanController controller = new DegreePlanController();
          controller.initialize();
          System.assert(!controller.showpastTerms);
          controller.togglePastTerms();
          System.assert(controller.showpastTerms);
          controller.togglePastTerms();
          System.assert(!controller.showpastTerms);
        }
        Test.stopTest();
      }
}