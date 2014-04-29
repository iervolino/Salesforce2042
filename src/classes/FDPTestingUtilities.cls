/* For Unit Testing Only, Do Not Use In a Regular Class, Faked records are inserted and will be rolled back in a unit test; unlike a regular class. */
@isTest
public class FDPTestingUtilities {

    public static String pidm = 'testpidm';
    public static String firstname = 'Testy';
    public static String lastname = 'Testerson';
    public static String alias = 'standt';
    public static String email = 'ttesterson@test.wgu.edu';
    public static String username = 'ttesterson@test.wgu.edu';
    public static String emailencodingkey = 'UTF-8';
    public static String languagelocalekey = 'en_US';
    public static String localesidkey = 'en_US';
    public static String timezonesidkey = 'America/Los_Angeles';
    public static String recordType = 'StudentRecord';
    public static String objectType = 'Account';
    public static String userProfileName = 'Student Profile';
    public static String adminProfileName = 'System Administrator';
    public static String programName = 'Test Program';
    public static String programTitle = 'Test Program';
    public static String planName = 'Test Plan';
    public static String termName = 'Test Term';
    public static String definitionName1 = 'Test Definition 1';
    public static String definitionName2 = 'Test Definition 2';
    public static String definitionName3 = 'Test Definition 3';
    public static String definitionName4 = 'Test Definition 4';
    public static final Integer TERMLENGTHINMONTHS = 6;
   

    public Account account {get;set;}
    public User user {get;set;}
    public Contact contact {get;set;}
    public WGUDegreeProgram__c program {get;set;}
    public StudentDegreePlans__c plan {get;set;}  
    public List<StudentDegreePlans__c> plans {get;set;}
    public StudentTerm__C term {get;set;}
    public List<StudentTerm__c> terms {get;set;}
    public List<StudentTerm__c> currentPlanTerms {get;set;}
    public List<WGUCourse__c> definitions {get;set;}
    public List<StudentCourse__c> courses {get;set;}
    public List<StudentCourse__c> currentPlanCourses {get;set;}
    public List<WGUCourseInProgram__c> ties {get;set;}
    public List<WGUCourseCompletionTask__c> wgutasks {get;set;}
  
    // Review 3/12/2012
    public FDPTestingUtilities() {
        definitions = new List<WGUCourse__c>();
        courses = new List<StudentCourse__c>();
        currentPlanCourses = new List<StudentCourse__c>();
        ties = new List<WGUCourseInProgram__c>();
        generateFullTestData();
    }
     public FDPTestingUtilities(boolean isFullTestData) {
        definitions = new List<WGUCourse__c>();
        courses = new List<StudentCourse__c>();
        currentPlanCourses = new List<StudentCourse__c>();
        ties = new List<WGUCourseInProgram__c>();
        if( isFullTestData)
        generateFullTestData();
        else generateUserDataWithoutStudyPlan();
    }
     
     private void generateUserDataWithoutStudyPlan() {
    
        // For each of the new objects, the minimum number of fields
        // have been filled in. Feel free to augment by filling in
        // the values of any other object's fields as seen fit in order
        // for your tests to have ample data.
        
     
            // Insert a new Account
            account = obtainAccount();
            
            // Insert a new User
            user = obtainUser();
            
            //Insert a new WGUDegreeProgram
            program = obtainWGUDegreeProgram();
                        
            // Insert new WGUCourse(s)/Definition(s)
            definitions.add(obtainWGUCourse(definitionName1, 4));
            definitions.add(obtainWGUCourse(definitionName2, 5));
            definitions.add(obtainWGUCourse(definitionName3, 6));
            definitions.add(obtainWGUCourse(definitionName4, 8));
                 
            // Insert new WGUCourseInProgram(s)
            ties.add(obtainWGUCourseInProgram(1, program, definitions.get(0)));
            ties.add(obtainWGUCourseInProgram(2, program, definitions.get(1)));
            ties.add(obtainWGUCourseInProgram(3, program, definitions.get(2)));
            ties.add(obtainWGUCourseInProgram(4, program, definitions.get(3)));
            
            Contact con= [SELECT id FROM Contact WHERE id = :user.ContactId];
            con.ProgramCode__c=program.name;
            con.WGUDegreeProgram__r=program;
            con.WGUDegreeProgram__c=program.id;
            update con;
            contact = con;
        
    }
    
    // Review 3/12/2012 - See todo next code review.
    private void generateFullTestData() {
    
        // For each of the new objects, the minimum number of fields
        // have been filled in. Feel free to augment by filling in
        // the values of any other object's fields as seen fit in order
        // for your tests to have ample data.
        
        // TODO - review in future sprint, remove if not needed.
        /*Profile adminProfile = [select id from profile where name = :FDPTestingUtilities.adminProfileName limit 1];    
        User adminUser = [select id from user where profileid = :adminProfile.id limit 1];        
        System.runAs(adminUser) {   */ 
        
            // Insert a new Account
            account = obtainAccount();
            
            // Insert a new User
            user = obtainUser();
            
            //Insert a new WGUDegreeProgram
            program = obtainWGUDegreeProgram();
            
            // Insert a new StudentDegreePlan
            plan = obtainStudentDegreePlan();
            
            // Create Student Term
            terms = obtainStudentTerms();
            
            // Insert new WGUCourse(s)/Definition(s)
            definitions.add(obtainWGUCourse(definitionName1, 1));
            definitions.add(obtainWGUCourse(definitionName2, 2));
            definitions.add(obtainWGUCourse(definitionName3, 3));
       
            // Create new StudentCourse(s)
            courses.add(obtainStudentCourse(definitions.get(0), terms[0]));
            courses.add(obtainStudentCourse(definitions.get(1), terms[0]));
            courses.add(obtainStudentCourse(definitions.get(2), terms[0]));
            
            currentPlanCourses.add(obtainStudentCourse(definitions.get(0), currentPlanTerms[0]));
            currentPlanCourses.add(obtainStudentCourse(definitions.get(1), currentPlanTerms[0]));
            currentPlanCourses.add(obtainStudentCourse(definitions.get(2), currentPlanTerms[0]));
            
            // Insert new WGUCourseInProgram(s)
            ties.add(obtainWGUCourseInProgram(1, program, definitions.get(0)));
            ties.add(obtainWGUCourseInProgram(2, program, definitions.get(1)));
            ties.add(obtainWGUCourseInProgram(3, program, definitions.get(2)));
            
            Contact con= [SELECT id FROM Contact WHERE id = :user.ContactId];
            con.ProgramCode__c=program.name;
            con.WGUDegreeProgram__c=program.id;
            con.WGUDegreeProgram__r = program;
            Date startDate = Date.Today().addMonths(-1);
            con.TermStartDate__c = startDate;
            contact=con;
            update con;
       // }
        
    }
    
    // Review 3/12/2012
    public static User getStudent() {
    
        // Insert a new Account
        Account account = new Account();
        account.firstname = FDPTestingUtilities.firstname;
        account.lastname = FDPTestingUtilities.lastname;
        account.pidm__c = pidm;
        account.recordtypeid = [select id from recordtype where name = :FDPTestingUtilities.recordType and sobjecttype = :FDPTestingUtilities.objectType limit 1].id;
        insert account;
        Contact c = [select Name from Contact where LastName = :FDPTestingUtilities.lastname limit 1];
        
        // Insert a new User
        User user = null;
        try {
            user = [ select alias,
              email,
              firstname,
              lastname,
              username,
              pidm__c,
              emailencodingkey,
              languagelocalekey,
              localesidkey,
              timezonesidkey,
              profileid,
              contactid
              from User
              where ContactId = :c.Id];
        } catch (Exception ex) {}
        if(user == null) {
            user = new User();
            user.alias = FDPTestingUtilities.alias;
            user.email = FDPTestingUtilities.email;
            user.firstname = FDPTestingUtilities.firstname;
            user.lastname = FDPTestingUtilities.lastname;
            user.username = FDPTestingUtilities.username;
            user.pidm__c = FDPTestingUtilities.pidm;
            user.emailencodingkey = FDPTestingUtilities.emailencodingkey;
            user.languagelocalekey = FDPTestingUtilities.languagelocalekey;
            user.localesidkey = FDPTestingUtilities.localesidkey;
            user.timezonesidkey = FDPTestingUtilities.timezonesidkey;
            user.profileid = [select id from profile where name = :FDPTestingUtilities.userProfileName limit 1].id;
            user.contactid = [select id from contact where lastname = :FDPTestingUtilities.lastname limit 1].id;
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            user.setOptions(dmo);
            insert user;
        }
        
        return user;
    
    }
    
    // Review 3/12/2012
    private Account obtainAccount() {
        // Create required key value pair needed by account triggers.
        KeyValue__c keyvalue = new KeyValue__c(Name='environment',Value__c='devbox');
        Insert keyvalue;
        
        Contact contact = new Contact(FirstName=FDPTestingUtilities.firstname,LastName=FDPTestingUtilities.lastname,WGUEmail__c='user@user.test',Email='user@user.test',PIDM__c ='108201',recordTypeId=[SELECT id from RecordType WHERE DeveloperName='StudentRecord' AND SobjectType='Contact'].id);
        insert contact;
        // Insert a new Account
        /* Modified by Paul Coleman, Mar 15, 2013 due to test failures after record type conversion
        account = new Account();
        account.firstname = FDPTestingUtilities.firstname;
        account.lastname = FDPTestingUtilities.lastname;
        account.AccountEmail__c = 'user@user.test';
        account.PIDM__c = '108201';
        account.recordtypeid = [select id from recordtype where name = :FDPTestingUtilities.recordType and sobjecttype = :FDPTestingUtilities.objectType limit 1].id;
        insert account;
        */
        account = [SELECT Name,Id,AccountEmail__c,PIDM__c,RecordTypeId FROM Account WHERE StudentContact__c = :contact.Id LIMIT 1];
        account.AccountEmail__c = contact.WGUEmail__c;
        update account;
        
        return account;
    
    }
    
    // Review 3/12/2012
    private User obtainUser() {
    
        // Insert a new User
        user = new User();
        user.alias = FDPTestingUtilities.alias;
        user.email = FDPTestingUtilities.email;
        user.firstname = FDPTestingUtilities.firstname;
        user.lastname = FDPTestingUtilities.lastname;
        user.username = FDPTestingUtilities.username;
        user.pidm__c = FDPTestingUtilities.pidm;
        user.emailencodingkey = FDPTestingUtilities.emailencodingkey;
        user.languagelocalekey = FDPTestingUtilities.languagelocalekey;
        user.localesidkey = FDPTestingUtilities.localesidkey;
        user.timezonesidkey = FDPTestingUtilities.timezonesidkey;
        user.profileid = [select id from profile where name = :FDPTestingUtilities.userProfileName limit 1].id;
        user.contactid = [select id from contact where lastname = :FDPTestingUtilities.lastname limit 1].id;
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.EmailHeader.triggerUserEmail = false;
        user.setOptions(dmo);
        system.debug(user);
        insert user;
        
        return user;
    
    }
    
    // Review 3/12/2012
    private WGUDegreeProgram__c obtainWGUDegreeProgram() {
    
        //Insert a new WGUDegreeProgram
        program = new WGUDegreeProgram__c();
        program.PAMSID__C = 1;
        program.name = FDPTestingUtilities.programName;
        program.title__c = FDPTestingUtilities.programTitle;
        insert program;
        
        return program;
        
    }
    
    // Review 3/12/2012
    private StudentDegreePlans__c obtainStudentDegreePlan() {
        
        plans = new List<StudentDegreePlans__c>();
        // Insert a new StudentDegreePlan
        StudentDegreePlans__c plan1 = new StudentDegreePlans__c();
        plan1.name = 'Current Plan';
        plan1.basedonprogram__c = program.id;
        plan1.currentplan__c = true;
        plan1.student__c = [select id from contact where lastname = :FDPTestingUtilities.lastname limit 1].id;
        insert plan1;
        plans.add(plan1);
        plan = plan1;
        return plan1;
        
    }
    
    public static Date getNextTermStartDate() {
        Date cur = Date.today();
        // Get next month then set the first of the month as the start date.
        Date nextstartdate = cur.addMonths(1);
        nextStartdate = Date.newInstance(nextStartdate.year(), nextStartdate.month(), 1);
        return nextStartdate;
    }    
    
    public static Date getTermEndDateFromStartDate(Date startDate) {
        return startDate.addMonths(TERMLENGTHINMONTHS).addDays(-1);
    }
    
    // Review 3/12/2012
    private List<StudentTerm__c> obtainStudentTerms() {
         terms=new List<StudentTerm__c>();
         currentPlanTerms = new List<StudentTerm__c>();
        // Create Student Term

        for(StudentDegreePlans__c oneplan : plans) {
            StudentTerm__c myterm;
            myterm = new StudentTerm__c();
            myterm.name = FDPTestingUtilities.termName;
            myterm.student__c = [select id from contact where lastname = :FDPTestingUtilities.lastname limit 1].id;
            myterm.studentdegreeplan__c = oneplan.id;
            myterm.termnumber__c = 1;
            myterm.CompetencyUnits__c=12;
            myterm.StartDate__c= getNextTermStartDate();
            myterm.endDate__c=getTermEndDateFromStartDate(myterm.StartDate__c);
            insert myterm;
            term = myterm;
            currentPlanTerms.add(myterm);
            terms.add(myterm);

            StudentTerm__c term2 = new StudentTerm__c();
            term2.name = FDPTestingUtilities.termName;
            term2.student__c = [select id from contact where lastname = :FDPTestingUtilities.lastname limit 1].id;
            term2.studentdegreeplan__c = oneplan.id;
            term2.termnumber__c = 2;
            term2.CompetencyUnits__c=12;
            term2.StartDate__c=getNextTermStartDateFromStartDate( myterm.StartDate__c);
            term2.endDate__c=getTermEndDateFromStartDate(term2.StartDate__c);
            insert term2;
            currentPlanTerms.add(term2);
            terms.add(term2);
        }
        return terms;
        
    }
    
    public static Date getNextTermStartDateFromStartDate(Date startDate) {
        return startDate.addMonths(TERMLENGTHINMONTHS);
    }    
    
    // Review 3/12/2012
    private WGUCourse__c obtainWGUCourse(String defName, Decimal cus) {
    
        // Insert new WGUCourse(s)/Definition(s)
        WGUCourse__c definition = new WGUCourse__c();
        definition.name = defName;
        definition.competencyunits__c = cus;
        definition.PAMSID__c = Math.random();
        insert definition;
        
        return definition;
    
    }
    
    // Review 3/12/2012
    private StudentCourse__c obtainStudentCourse(WGUCourse__c definition, StudentTerm__c term) {
    
        // Create new StudentCourse(s)
        StudentCourse__c course = new StudentCourse__c();
        course.coursedefinition__c = definition.id;
        course.student__c = [select id from contact where lastname = :FDPTestingUtilities.lastname limit 1].id;
        course.studentterm__c = term.id;
        course.status__C='Planned';
        insert course;
        
        return course;
    
    }
    
    // Review 3/12/2012
    private WGUCourseInProgram__c obtainWGUCourseInProgram(Decimal seq, WGUDegreeProgram__c program, WGUCourse__c definition) {
        
        // Insert new WGUCourseInProgram(s)
        WGUCourseInProgram__c tie = new WGUCourseInProgram__c();
        tie.sequence__c = seq;
        tie.program__c = program.id;
        tie.course__c = definition.id;
        insert tie;
        
        return tie;
        
    }
    public WGUCourseCompletionTask__c generateWGUCourseCompletionTask(WGUCourse__c definition){
           
        WGUCourseCompletionTask__c tie = new WGUCourseCompletionTask__c();
        tie.WGUCourse__c = definition.id;
        System.debug('definition.id:'+definition.id);
        insert tie;
        
        return tie;
    }
    
    public static void createCompletionTasksForStudent(String studentId, Integer num, String completionTaskType) {
        String programId = getProgramIdForStudent(studentId);
        Contact student = [select TermCode__c,TermStartDate__c from Contact where id = :studentId];
        List<String> completedCourses = new List<String>();
        for(StudentCompletionTask__c task : [select Name,
            WGUCourseCompletionTask__r.Name,
            WGUCourseCompletionTask__r.WGUCourse__r.Name
            from StudentCompletionTask__c
          where Student__c = :studentId]) {
          completedCourses.add(task.WGUCourseCompletionTask__r.WGUCourse__r.Id);    
        }
        WGUDegreeProgram__c program = [select id,Name,
            (
                select id,Name,Course__r.Name,
                Sequence__c,
                Course__r.CompetencyUnits__c
                from WGUCourseInPrograms__r
                where Course__r.Id not in :completedCourses
                order by Sequence__c
                limit :num
            )
            from WGUDegreeProgram__c
            where id = :programId];

        RecordType rc = [select Name
            from RecordType
            where SobjectType = 'WGUCourseCompletionTask__c'
            and Name = 'Assessment'];
        Date termStart = FDPUtilities.getPreviousTermStartDateFromStartDate(student.TermStartDate__c);
        Integer CUsInTerm = 0;
        Integer minCUsInTerm = 12;
        List<WGUCourseCompletionTask__c> ccts = new List<WGUCourseCompletionTask__c>();
        List<StudentCompletionTask__c> scts = new List<StudentCompletionTask__c>();
        for(Integer i=program.WGUCourseInPrograms__r.size()-1;i>=0;i--) {
            WGUCourseInProgram__c cip = program.WGUCourseInPrograms__r[i];
            WGUCourseCompletionTask__c task;
            try {
               task = [select id
                 from WGUCourseCompletionTask__c
                 where WGUCourse__c = :cip.Course__r.Id];
            } catch(Exception ex) {
              task = new WGUCourseCompletionTask__c();
              task.RecordTypeId = rc.Id;
              task.Type__c = 'Objective';
              task.WGUCourse__c = cip.Course__r.Id;
              ccts.add(task);
            }
            if(CUsInTerm >= minCUsInTerm) {
                CUsInTerm=0;
                termStart = FDPUtilities.getPreviousTermStartDateFromStartDate(termStart);
            }
            CUsInTerm += Integer.valueOf(cip.Course__r.CompetencyUnits__c);
            StudentCompletionTask__c sct = new StudentCompletionTask__c();
            sct.Student__c = studentId;
            if(completionTaskType == 'Transfer') {
            	sct.StatusDate__c = Date.newInstance(1901, 1, 1);
                sct.TermCode__c = '000000';
                sct.RequirementComplete__c = true;
                sct.AssessmentStatus__c = 'Passed';
            } else if(completionTaskType == 'Current' || ((completionTaskType == 'Both' || completionTaskType=='All') && i==0)) {
            	sct.StatusDate__c = student.TermStartDate__c;
            	sct.TermCode__c = FDPTestingUtilities.generateTermCode(student.TermStartDate__c);
            	sct.RequirementComplete__c = true;
            	sct.AssessmentStatus__c = 'Passed';
            } else if(completionTaskType == 'Failed' || (completionTaskType == 'All' && (i==1|| i==4 ))) {
            	sct.StatusDate__c = termStart;
            	sct.TermCode__c = FDPTestingUtilities.generateTermCode(termStart);
            	sct.RequirementComplete__c = false;
            	sct.AssessmentStatus__c = 'Failed';
            } else if(CompletionTaskType == 'FailedCurrent' || (completionTaskType == 'All' && (i==2))) {
            	sct.StatusDate__c = student.TermStartDate__c;
            	sct.TermCode__c = FDPTestingUtilities.generateTermCode(student.TermStartDate__c);
            	sct.RequirementComplete__c = false;
            	sct.AssessmentStatus__c = 'Failed';
            } else {
            	sct.StatusDate__c = termStart;
                sct.TermCode__c = FDPTestingUtilities.generateTermCode(termStart);
                sct.RequirementComplete__c = true;
                sct.AssessmentStatus__c = 'Passed';
            }
            sct.WGUCourseCompletionTask__r = task;
            scts.add(sct);
        }
        insert ccts;
        for(StudentCompletionTask__c sct: scts) {
            sct.WGUCourseCompletionTask__c = sct.WGUCourseCompletionTask__r.Id;
        }
        insert scts;
    }
    
    public static String getProgramIdForStudent(String studentId) {
        Contact student = [select Name,WGUDegreeProgram__c
          from Contact
          where Id = :studentId];
        return student.WGUDegreeProgram__c;
    }
    
    public static void deleteCompletionTasksForStudent(String studentId) {
        String programId = getProgramIdForStudent(studentId);
        WGUDegreeProgram__c program = [select id,Name,
            (
                select id,Name,Course__r.Name,course__r.id,Sequence__c
                from WGUCourseInPrograms__r
                order by Sequence__c
            )
            from WGUDegreeProgram__c
            where id = :programId];
        List<String> cips = new List<String>();
        for(WGUCourseInProgram__c cip : program.WGUCourseInPrograms__r) {
            cips.add(cip.Course__c);
        }
        
        List<StudentCompletionTask__c> stasks = [select
          Name
          from StudentCompletionTask__c
          where WGUCourseCompletionTask__r.WGUCourse__c in :cips
        ];
        delete stasks;
        
        List<WGUCourseCompletionTask__c> tasks = [select name
        from WGUCourseCompletionTask__c
        where WGUCourse__c in :cips];
        delete tasks;
    }
    
    public static void putTermsBackForStudent(String studentId, Integer numTerms) {
        List<StudentDegreePlans__c> plans = [select id,name
          from StudentDegreePlans__c
          where Student__c = :studentId];
         List<String> planIds = new List<String>();
         for(StudentDegreePlans__c plan : plans) {
            planIds.add(plan.Id);
         }
         List<StudentTerm__c> terms = [select id,name,StartDate__c,EndDate__c
            from StudentTerm__c
            where StudentDegreePlan__c in :planIds];
         for(StudentTerm__c term : terms) {
            for(Integer i=0;i<numTerms;i++) {
                term.StartDate__c = getPreviousTermStartDateFromStartDate(term.StartDate__c);
            }
            term.Name = generateTermCode(term.StartDate__c);
            term.EndDate__c = getTermEndDateFromStartDate(term.StartDate__c);
         }
         update terms;
    }
    
    public static Date getPreviousTermStartDateFromStartDate(Date startDate) {
        return startDate.addMonths(-1*TERMLENGTHINMONTHS);
    }    
    
    public static void deleteDegreePlansForStudent(String studentId) {
        List<StudentCourse__c> deletedCourses = new List<StudentCourse__c>();
        List<StudentTerm__c> deletedTerms = new List<StudentTerm__c>();
        List<StudentDegreePlans__c> deletedPlans = new List<StudentDegreePlans__c>();
        List<String> plans = new List<String>();
        List<String> terms = new List<String>();
        for(StudentDegreePlans__c plan: [select id
            from StudentDegreePlans__c
            where Student__r.Id = :studentId]) {
            plans.add(plan.Id);
            deletedPlans.add(plan);
        }
        
        for(StudentTerm__c term :
            [select id
            from StudentTerm__c
            where Student__c = :studentid]) {
            terms.add(term.Id);
            deletedTerms.add(term);
        }
    
        for(StudentCourse__c course:
            [select id
            from StudentCourse__c
            where Student__c = :studentId]) {
            deletedCourses.add(course);
        }
    
        delete deletedCourses;
        delete deletedTerms;
        delete deletedPlans;
    }
    
    public static String generateTermCode(Date termStart) {
        if(termStart == Date.newInstance(1901,1,1))
          return '000000';
        if(termStart == Date.newInstance(1900,1,1))
          return '111111';
        String code;
        Integer month = termStart.month();
        
        // Term name is term code 'yyyyMM'.
        if (month < 10)
            code = String.valueOf(termStart.year()) + '0' + String.valueOf(month);
        else
            code = String.valueOf(termStart.year()) + String.valueOf(month);
                
        return code;
    }

    public static void data() {
      // Get List of existing WGUCourseVersions
      List<WGUCourseVersion__c> wguCVs = [select Id,
        WGUCourse__c
        from WGUCourseVersion__c];
      List<Id> courseIds = new List<Id>();
      for(WGUCourseVersion__c v : wguCVs) {
        courseIds.add(v.WGUCourse__c);
      }

      // Get all WGUCourses that don't have a courseVersion
      List<WGUCourse__c> wguCourses = [select id,
        Name
        from WGUCourse__c
        where Id not in :courseIds];
      for(WGUCourse__c c : wguCourses) {
        WGUCourseVersion__c v = new WGUCourseVersion__c();
        v.WGUCourse__c = c.Id;
        v.Name = c.Name;
        wguCVs.add(v);
      }
      upsert wguCVs;

      // Create a map of Course to Course Version
      Map<Id,WGUCourseVersion__c> wguCtoWguCV = new Map<Id,WGUCourseVersion__c>();
      for(WGUCourseVersion__c v : wguCVs) {
        wguCtoWguCV.put(v.WGUCourse__c,v);
      }

      List<StudentCourseVersion__c> SCVs = [select Id,
        WGUCourseVersion__c,
        WGUCourseVersion__r.WGUCourse__c,
        Student__c
        from StudentCourseVersion__c];
      Map<Id,StudentCourseVersion__c> wguCVtoSCV = new Map<Id,StudentCourseVersion__c>();
      for(StudentCourseVersion__c scv : SCVs) {
        wguCVtoSCV.put(scv.WGUCourseVersion__c,scv);
      }

      List <StudentCourse__c> courses = [select id,
        StudentCourseVersion__c,
        StudentCourseVersion__r.Student__c,
        CourseDefinition__c,
        Student__c
        from StudentCourse__c];
      Map<Id,StudentCourseVersion__c> scToSCV =
        new Map<Id,StudentCourseVersion__c>();
      for(StudentCourse__c c : courses) {
        if(c.StudentCourseVersion__c == null) {
          WGUCourseVersion__c wgv = wguCtoWguCV.get(c.CourseDefinition__c);
          StudentCourseVersion__c scv = wguCVtoSCV.get(wgv.Id);
          if(scv == null) {
            scv = new StudentCourseVersion__c();
            wguCvtoSCV.put(wgv.Id,scv);
            scv.WGUCourseVersion__c = wgv.Id;
            SCVs.add(scv);
          }
          scv.Student__c = c.Student__c;
          scToSCV.put(c.Id,scv);
        } else {
          c.StudentCourseVersion__r.Student__c = c.Student__c;
          scToSCV.put(c.Id,c.StudentCourseVersion__r);
        }
      }
      upsert SCVs;

      for(StudentCourse__c c : courses) {
        c.StudentCourseVersion__c = scToSCV.get(c.Id).Id;
      }

      upsert courses;
    }
    public void clean(){
    

SetupFDPDevelopmentBox.refreshAllData();
delete [select id from studentcourse__C];
contact st=[select id,EulaAgreementDate__c from contact where pidm__C='11'];
st.EulaAgreementDate__c=null;
update st;
    }
}