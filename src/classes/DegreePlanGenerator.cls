//reviewed 4/6/2012
public with sharing class DegreePlanGenerator {
    public with sharing class StudentCourseComparable implements Comparable{
      public StudentCourse__c c;
      public StudentCourseComparable(StudentCourse__c sc) {
        c = sc;
      }

      public Integer compareTo(Object compareTo) {
        StudentCourseComparable ct = (StudentCourseComparable)compareTo;
        if(ct.c.TermSequence__c < this.c.TermSequence__c) {
          return 1;
        } else if(ct.c.TermSequence__c > this.c.TermSequence__c) {
          return -1;
        }
        return 0;
      }
    }

    public static List<StudentCourse__c> sortCourses(List<StudentCourse__c> all) {
      List<StudentCourseComparable> sortMe = new List<StudentCourseComparable>();
      for(StudentCourse__c c : all) {
        sortMe.add(new StudentCourseComparable(c));
      }
      sortMe.sort();
      List<StudentCourse__c> sorted = new List<StudentCourse__c>();
      for(StudentCourseComparable scc : sortMe) {
        sorted.add(scc.c);
      }
      return sorted;
    }
    public with sharing class DegreePlanGeneratorException extends Exception{}

    public StudentDegreePlans__c DegreePlan {get;set;}
    public Contact Student
      {
        get {
          return Student;
        }
        set {
          Student = value;
          StudentId = Student.Id;
        }
      }
    public String StudentId;
    public String planId;
    public String planName;
    public Decimal MaxCUPerTerm;
    public Decimal MinCUPerTerm;
    public Integer MaxTerms;
    public Boolean IncludeCurrentTerm;
    public Boolean IsInitialGeneration;
    private List<StudentCourse__c> Courses;
    private List<StudentCourse__c> AllCourses;
    private List<StudentCourse__c> PlannedCourses;
    private List<StudentCourse__c> CompletedCourses;
    private List<StudentCourse__c> NonDegreeCourses;
    private List<StudentCourseVersion__c> CourseVersions;
    private List<StudentTerm__c> AllTerms;
    private String termCodeIndex;
    private String firstTermCodeIndex;
    private Integer completedEnrolledCUInCurrentTerm;
    public string spoofid;
        //reviewed 4/6/2012
    public DegreePlanGenerator(Contact Student,Decimal MinCUPerTerm,String planId, String planName) {
        if(MinCUPerTerm == null) {
            throw new DegreePlanGeneratorException('Min Units per Term cannot be empty.');
        }
        this.Student = Student;
        this.MinCUPerTerm = MinCUPerTerm;
        this.planId = planId;
        this.planName=planName;
        this.IncludeCurrentTerm = true;
        this.IsInitialGeneration = false;
    }
    public DegreePlanGenerator(Contact Student,Decimal MinCUPerTerm,String planId, String planName,String spoof) {
        if(MinCUPerTerm == null) {
            throw new DegreePlanGeneratorException('Min Units per Term cannot be empty.');
        }
        this.Student = Student;
        this.MinCUPerTerm = MinCUPerTerm;
        this.planId = planId;
        this.planName=planName;
        this.spoofid=spoof;
        this.IncludeCurrentTerm = true;
        this.IsInitialGeneration = false;
    }

    public DegreePlanGenerator() {
        this.IncludeCurrentTerm = true;
        this.IsInitialGeneration = false;
    }
    // The contact provided need to have Student.WGUDegreeProgram__r populated.
        //reviewed 4/6/2012
    public DegreePlanGenerator(Contact student,Decimal MinCUPerTerm, String planName) {
        if(MinCUPerTerm == null) {
            throw new DegreePlanGeneratorException('Min Units per Term cannot be empty.');
        }
        this.planId = '';
        this.Student = Student;
        this.MinCUPerTerm = MinCUPerTerm;
        this.planName = planName;
        this.IncludeCurrentTerm = true;
        this.IsInitialGeneration = false;
    }
    /*10/28 by Jeffwang
    */
    public List<WGULicenseRequirement__c> getNonDegreeRequirements(){
      List<WGULicenseRequirement__c> requires=new List<WGULicenseRequirement__c>();
      List<StudentLicenseHistory__c> li = [select Id,
        WGUStateLicensure__c
        from StudentLicenseHistory__c
        where Student__c =: StudentId
        order by SelectDate__c
        limit 1];
      if (li.size() > 0) {
        requires= [select Id,
          Name,
          RequirementCode__c
          from WGULicenseRequirement__c
          where WGUStateLicensure__c =:li[0].WGUStateLicensure__c];
      }
     List<WGULicenseRequirement__c> fes= [select Id,
          Name,
          RequirementCode__c
          from WGULicenseRequirement__c
          where WGUFEToDo__c !=null and Program__c=:student.ProgramName__c];
          requires.addall(fes);
      return requires;
    }
    /*10/28 by Jeffwang
    */
    public List <StudentCourse__C> getNonDegreeRequirementCourses(){
        List<WGULicenseRequirement__C> lis=getNonDegreeRequirements();
        NonDegreeCourses = [select Name,
          CourseType__c,
          Student__c,
          Status__c,
          StudentTerm__c,
          StudentTerm__r.Name,
          WGULicenseRequirement__c,
          WGULicenseRequirement__r.RequirementCode__c,
          InCorrectTerm__c,
          TermSequence__c
          from StudentCourse__c
          where Student__c = :StudentId
          and CourseType__c = 'Non Degree Requirement'
          and StudentTerm__r.StudentDegreePlan__c = :planId];
        Set<Id> existingReqs = new Set<Id>();
        for(StudentCourse__c c : NonDegreeCourses) {
          existingReqs.add(c.WGULicenseRequirement__c);
        }
        for(WGULicenseRequirement__c lr : lis) {
          if(existingReqs.contains(lr.Id)) {
            continue;
          }
          StudentCourse__c course = new StudentCourse__c();
          course.Name = lr.Name;
          course.CourseType__c='Non Degree Requirement';
          course.Student__c = StudentId;
          course.Status__c ='Planned';
          course.WGULicenseRequirement__c=lr.id;
          course.WGULicenseRequirement__r=lr;
          if(spoofid!=null) {
            course.ownerid=spoofid;
          }
          NonDegreeCourses.add(course);
        }
        return NonDegreeCourses;
    }
        //reviewed 4/6/2012
    public StudentDegreePlans__c getDegreePlan() {
        if(DegreePlan != null) {
            return DegreePlan;
        }
        if((planId != '')&& (planId !=null)) {
            try {
                DegreePlan = [select Name,	IsApproved__c,
                  IsIncludeCurrentTerm__c,
                  BasedOnProgram__c,
                  (
                    select Name,StartDate__c,
                    EndDate__c,
                    CompetencyUnits__c,
                    Student__c
                    from StudentTerms__r
                    order by Name
                  )
                  from StudentDegreePlans__c
                  where Student__c = :StudentId
                  and Id = :planId
                  limit 1];
            } catch (Exception ex) {}
        }
        if(DegreePlan == null) {
            if(Student == null)
                throw new DegreePlanGeneratorException('Need a Student to generate a degree plan');
            if(Student.WGUDegreeProgram__r == null) {
                throw new DegreePlanGeneratorException('Need WGUDegreeProgram__r on the student passed');
            }
            WGUDegreeProgram__c program = Student.WGUDegreeProgram__r;
            DegreePlan = new StudentDegreePlans__c();
            DegreePlan.BasedOnProgram__c = program.Id;
            DegreePlan.Student__c = StudentId;
            if (spoofid!=null)DegreePlan.ownerid=spoofid;
            if(planName == null) {
                planName = program.Name;
            }
            DegreePlan.CurrentPlan__c = planName == FDPUtilities.CURRENTPLANNAME;
            DegreePlan.Name = planName;
        } else {
            planName = DegreePlan.Name;
        }
        return DegreePlan;
    }
    //reviewed 4/6/2012
    private List<WGUCourseInProgram__c> getCoursesInProgram() {
        return [select Course__r.CompetencyUnits__c,
                Course__r.Name,
                Course__r.LatestVersion__c,
                Course__r.LatestVersion__r.WGUCourse__r.CompetencyUnits__c,
                Course__r.LatestVersion__r.Name,
                Sequence__c
                from WGUCourseInProgram__c
                where Program__c = :DegreePlan.BasedOnProgram__c
                order by Sequence__c];
    }

    private List<StudentCourseVersion__c> getStudentCourseVersions() {
      if(CourseVersions != null) {
        return CourseVersions;
      }
      List<StudentCourseVersion__c> existingSCVs = [
        select Id,
        Name,
        WGUCourseVersion__c,
        Status__c,
        CompletedDate__c,
        CompletedTermCode__c,
        Completed__c,
        EnrollDate__c,
        EnrollTermCode__c,
        Sequence__c,
        StudentCompletionCourse__r.InPreviousProgram__c,
        WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
        WGUCourseVersion__r.WGUCourse__r.Name,
        WGUCourseVersion__r.Name,
        StatusDate__c
        from StudentCourseVersion__c
        where Student__c = :StudentId
      ];
      Map<String,StudentCourseVersion__c> scvMap = new Map<String,StudentCourseVersion__c>();
      for(StudentCourseVersion__c scv : existingSCVs) {
        if(scv.Status__c != 'Failed') {
          scvMap.put(scv.WGUCourseVersion__r.WGUCourse__r.Name,scv);
        }
      }
      List<WGUCourseInProgram__c> wguCoursesInProgram = getCoursesInProgram();
      Map<String,WGUCourseInProgram__c> coursesInProgram = new Map<String,WGUCourseInProgram__c>();
      for(WGUCourseInProgram__c cip : wguCoursesInProgram) {
        coursesInProgram.put(cip.Course__r.Name,cip);
        if(!scvMap.containsKey(cip.Course__r.Name)) {
          StudentCourseVersion__c scv = new StudentCourseVersion__c();
          scvMap.put(cip.Course__r.Name,scv);
          scv.WGUCourseVersion__c = cip.Course__r.LatestVersion__c;
          scv.WGUCourseVersion__r = cip.Course__r.LatestVersion__r;
          scv.CompletedTermCode__c = null;
          scv.Status__c = 'Planned';
          scv.Student__c = StudentId;
          scv.Sequence__c = cip.Sequence__c;
          scv.Name = StudentId + '-' + cip.Course__c;
          if(spoofid != null)
            scv.OwnerId = spoofid;
        }
      }
      for(StudentCourseVersion__c scv : existingSCVs) {
        Boolean inPreviousProgram = scv.StudentCompletionCourse__r.InPreviousProgram__c;
        if(!coursesInProgram.containsKey(scv.WGUCourseVersion__r.WGUCourse__r.Name)
            && inPreviousProgram != null
            && inPreviousProgram == true) {
          scvMap.remove(scv.WGUCourseVersion__r.WGUCourse__r.Name);
        }
      }
      CourseVersions = scvMap.values();
      return CourseVersions;
    }

    private Integer getCompletedAndEnrolledCUInCurrentTerm() {
        if(completedEnrolledCUInCurrentTerm != null)
          return completedEnrolledCUInCurrentTerm;
        AggregateResult[] res = [select sum(StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c) completedCUInCurrentTerm
        from StudentCourse__c
        where Student__c = :StudentId
          and Status__c <> 'Planned'
          and Status__c <> 'Failed'
          and StudentTerm__r.StartDate__c <= Today
          and StudentTerm__r.EndDate__c >= Today];
        try {
          completedEnrolledCUInCurrentTerm = Integer.valueOf((Decimal)res[0].get('completedCUInCurrentTerm'));
        } catch(Exception ex) {
          completedEnrolledCUInCurrentTerm=0;
        }
        if(completedEnrolledCUInCurrentTerm==null) {
          completedEnrolledCUInCurrentTerm = 0;
        }
        return completedEnrolledCUInCurrentTerm;
    }

        //reviewed 4/6/2012
    private List<StudentCourse__c> getCourses() {
        if(PlannedCourses != null) {
            return PlannedCourses;
        }
        List<StudentCourse__c> prefiltered = [select Name,
                StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c,
                StudentCourseVersion__r.WGUCourseVersion__r.Name,
                StudentCourseVersion__r.WGUCourseVersion__c,
                StudentCourseVersion__r.StatusDate__c,
                StudentCourseVersion__r.EnrollDate__c,
                StudentCourseVersion__r.EnrollTermCode__c,
                StudentCourseVersion__r.CompletedTermCode__c,
                StudentCourseVersion__r.StudentCompletionCourse__r.InPreviousProgram__c,
                StudentTerm__r.Name,
                StudentTerm__r.StartDate__c,
                StudentTerm__r.EndDate__c,
                StudentTerm__c,
                InCorrectTerm__c,
                Status__c,
                CompletedDate__c,
                Completed__c,
                CourseType__c,
                TermSequence__c
                from StudentCourse__c
                where Student__c = :student.Id
                  and (StudentTerm__r.StudentDegreePlan__r.Id = :DegreePlan.Id
                    or StudentTerm__c = null
                  )
                  and CourseType__c != 'Non Degree Requirement'];
        CompletedCourses = new List<StudentCourse__c>();
        PlannedCourses = new List<StudentCourse__c>();
        NonDegreeCourses = getNonDegreeRequirementCourses();
        List<StudentCourseVersion__c> cvs = getStudentCourseVersions();
        Map<String,StudentCourse__c> existingCourses = new Map<String,StudentCourse__c>();
        Map<String,StudentCourse__c> finalCourses = new Map<String,StudentCourse__c>();
        for(StudentCourse__c c : prefiltered) {
          if(c.Status__c != 'Failed') {
            existingCourses.put(c.StudentCourseVersion__r.WGUCourseVersion__r.Name,c);
          }
        }
        for(StudentCourseVersion__c cv : cvs) {
          if(!existingCourses.containsKey(cv.WGUCourseVersion__r.Name)) {
            StudentCourse__c course = new StudentCourse__c();
            existingCourses.put(cv.WGUCourseVersion__r.Name,course);
            course.Name = cv.WGUCourseVersion__r.Name;
            course.StudentCourseVersion__c = cv.Id;
            course.StudentCourseVersion__r = cv;
            course.TermSequence__c = cv.Sequence__c;
            course.Student__c = StudentId;
            course.Status__c = cv.Status__c;
            course.Completed__c = cv.Completed__c;
            course.CompletedDate__c = cv.CompletedDate__c;
            course.EnrollDate__c = cv.EnrollDate__c;
            course.CourseType__c='Course';
            if (spoofid!=null)
              course.ownerid=spoofid;
          }
          finalCourses.put(cv.WGUCourseVersion__r.Name,existingCourses.get(cv.WGUCourseVersion__r.Name));
        }
        AllCourses = finalCourses.values();
        for(StudentCourse__c c : AllCourses) {
          if(c.Status__c != 'Planned') {
            CompletedCourses.add(c);
          } else {
            PlannedCourses.add(c);
          }
        }
        AllCourses.addAll(NonDegreeCourses);
        return PlannedCourses;
    }

    //reviewed 4/6/2012
    private List<StudentTerm__c> getTerms() {
        if(AllTerms != null) {
            return AllTerms;
        }
        if(AllTerms == null)
          AllTerms = new List<StudentTerm__c>();
        if(DegreePlan.StudentTerms__r.size() > 0) {
          for(StudentTerm__c t : DegreePlan.StudentTerms__r) {
            if(t.StartDate__c <= Date.Today()
                && t.EndDate__c >= Date.Today()) {
              t.CompetencyUnits__c = getCompletedAndEnrolledCUInCurrentTerm();
            } else {
              t.CompetencyUnits__c = 0;
            }
            AllTerms.add(t);
          }
        }
        return AllTerms;
    }
    //reviewed 4/6/2012
    private StudentTerm__c getNextTerm() {
        if(termCodeIndex == null) {
          termCodeIndex = FDPUtilities.getTermCodeFromContact(Student);
          while(this.IsInitialGeneration
              && termCodeIndex != null
              && FDPUtilities.termCodeIsInPast(termCodeIndex)) {
            termCodeIndex = FDPUtilities.nextTermCodeFromTermCode(termCodeIndex);
          }
          if(termCodeIndex == null) {
            FDPUtilities.generateTermCode(FDPUtilities.getNextTermStartDate());
          } else if(!this.IncludeCurrentTerm) {
            termCodeIndex = FDPUtilities.nextTermCodeFromTermCode(termCodeIndex);
          }
          firstTermCodeIndex = termCodeIndex;
          return getTermWithTermCode(termCodeIndex);
        }
        termCodeIndex = FDPUtilities.nextTermCodeFromTermCode(termCodeIndex);
        StudentTerm__c t = getTermWithTermCode(termCodeIndex);
        t.CompetencyUnits__c = 0;
        return t;
    }
    //reviewed 4/6/2012

    private StudentTerm__c getTermWithTermCode(String termCode) {
      if(termCode == null) {
        throw new DegreePlanGeneratorException('GeneratorException: no term code passed to getTermWithTermCode');
      }
      if(AllTerms == null) {
        AllTerms = new List<StudentTerm__c>();
      }
      for(StudentTerm__c t : AllTerms) {
        if(t.Name == termCode) {
          return t;
        }
      }
      StudentTerm__c term = new StudentTerm__c();
      term.Name = termCode;
      term.StudentDegreePlan__c = DegreePlan.Id;
      term.Student__c = StudentId;
      term.StartDate__c = FDPUtilities.getTermStartDateByCode(termCode);
      term.EndDate__c = FDPUtilities.getTermEndDateFromStartDate(term.StartDate__c);
      if(term.StartDate__c <= Date.Today()
          && term.EndDate__c >= Date.Today()) {
        term.CompetencyUnits__c = getCompletedAndEnrolledCUInCurrentTerm();
      } else {
        term.CompetencyUnits__c = 0;
      }
      term.Approved__c = false;
      term.ApprovalStatus__c = 'Pending Mentor Approval';
      term.ApprovalDate__c = null;
      if(spoofid != null)
        term.ownerid = spoofid;
      AllTerms.add(term);
      return term;
    }

    public Integer getTermCount() {
      Integer termCount = 0;
      for(StudentTerm__c t : AllTerms) {
        if(t.StartDate__c > Date.Today()
            && t.CompetencyUnits__c > 0) {
          termCount++;
        }
      }
      return termCount;
    }

    public Integer getFutureTermCount() {
      return getTermCount();
    }

    public StudentTerm__c getLastTerm() {
      StudentTerm__c lastTerm = null;
      for(StudentTerm__c t : AllTerms) {
        if((lastTerm == null
            || t.StartDate__c > lastTerm.StartDate__c)
            && t.CompetencyUnits__c > 0) {
          lastTerm = t;
        }
      }
      return lastTerm;
    }

    //reviewed 4/6/2012
    public StudentDegreePlans__c generateStudentDegreePlan() {
        getDegreePlan();
        getStudentCourseVersions();
        getCourses();
        getTerms();
        Integer completedAndEnrolledCUInCurrentTerm = getCompletedAndEnrolledCUInCurrentTerm();
        for(StudentTerm__c t : AllTerms) {
          if(t.StartDate__c <= Date.Today()
              && t.EndDate__c >= Date.Today()) {
            t.CompetencyUnits__c = completedAndEnrolledCUInCurrentTerm;
          } else {
            t.CompetencyUnits__c = 0;
          }
        }
        termCodeIndex = firstTermCodeIndex;
        StudentTerm__c term = null;
        for(StudentCourse__c c : NonDegreeCourses) {
          if(c.Status__c == 'Completed') {
            term = getTermWithTermCode(c.StudentCourseVersion__r.CompletedTermCode__c);
          } else if(c.StudentTerm__c != null) {
            // don't move the course if it has been assigned to a term
            continue;
          } else {
            term = getTermWithTermCode('000000');
          }
          term.StudentDegreePlan__r = DegreePlan;
          term.Approved__c = false;
          term.ApprovalStatus__c = 'Pending Mentor Approval';
          term.ApprovalDate__c = null;
          c.StudentTerm__r = term;
          term.StudentCourses__r.add(c);
        }
        Boolean hasEnrolledCoursesInCurrentTerm = false;
        if(DegreePlan.Name == FDPUtilities.CURRENTPLANNAME) {
          for(StudentCourse__c course : CompletedCourses) {
            if(course.Status__c == 'Failed') {
              term = getTermWithTermCode(course.StudentCourseVersion__r.CompletedTermCode__c);
            } else if(course.Status__c == 'Enrolled') {
              term = getTermWithTermCode(course.StudentCourseVersion__r.EnrollTermCode__c);
              if(Student.TermCode__c == null
                  || Student.TermCode__c == course.StudentCourseVersion__r.EnrollTermCode__c) {
                hasEnrolledCoursesInCurrentTerm = true;
              }
            } else {
              term = getTermWithTermCode(
                course.StudentCourseVersion__r.StudentCompletionCourse__r.InPreviousProgram__c != true
                ? course.StudentCourseVersion__r.CompletedTermCode__c
                : '000000'
              );
            }
            term.StudentDegreePlan__r = DegreePlan;
            term.CompetencyUnits__c += course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c;
            term.Approved__c = false;
            term.ApprovalStatus__c = 'Pending Mentor Approval';
            term.ApprovalDate__c = null;
            course.StudentTerm__r = term;
            term.StudentCourses__r.add(course);
          }
        }
        term = getNextTerm();
        if(this.IsInitialGeneration) {
          //ALWAYS sort on initial generation
          PlannedCourses = sortCourses(PlannedCourses);

          // don't put any new planned courses in the current term if they are already enrolled
          // gkc dec 14, 2012
          // also approve the plan if they're already enrolled
          if(hasEnrolledCoursesInCurrentTerm) {
            term = getNextTerm();
            term.StudentDegreePlan__r = DegreePlan;
            degreeplan.IsApproved__c=true;//STUPROGTERMS-906
          }
        }
        for (StudentCourse__c course : PlannedCourses) {
          if(!includeCurrentTerm) {
            if(course.StudentTerm__r.StartDate__c != null
              && course.StudentTerm__r.EndDate__c != null
              && course.StudentTerm__r.StartDate__c <= Date.Today()
              && course.StudentTerm__r.EndDate__c >= Date.Today()) {
              continue;
            }
          }
          if (
              term.CompetencyUnits__c >= MinCUPerTerm
              ||
              (
                term.StartDate__c <= Date.Today()
                && term.EndDate__c >= Date.Today()
                && !includeCurrentTerm
              )
            ) {
            term = getNextTerm();
            term.StudentDegreePlan__r = DegreePlan;
          }

          if (course.StudentCourseVersion__r!=null) {
            if(term.CompetencyUnits__c == null) {
              //throw new DegreePlanGeneratorException('could not get term competency units');
              term.CompetencyUnits__c = 0;
            }
            if(course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c != null) {
              term.CompetencyUnits__c += course.StudentCourseVersion__r.WGUCourseVersion__r.WGUCourse__r.CompetencyUnits__c;
            }
          }
          term.Approved__c = false;
          term.ApprovalStatus__c = 'Pending Mentor Approval';
          term.ApprovalDate__c = null;
          course.StudentTerm__r = term;
          term.StudentCourses__r.add(course);
        }
        DegreePlan.ApprovalStatus__c = 'Pending Mentor Approval';
        DegreePlan.ApprovalDate__c = null;
        DegreePlan.IsApproved__c = false;
        DegreePlan.ApprovedBy__c = null;
        return DegreePlan;
    }
        //reviewed 4/6/2012

    private void save() {
        if(DegreePlan.IsIncludeCurrentTerm__c != this.IncludeCurrentTerm)
          DegreePlan.IsIncludeCurrentTerm__c = this.IncludeCurrentTerm;
        upsert DegreePlan;
        this.planid=degreeplan.id;
        for(StudentTerm__c term : AllTerms) {
            term.StudentDegreePlan__c = DegreePlan.Id;
        }
        upsert AllTerms;
        upsert CourseVersions;
        for(StudentCourse__c course: AllCourses) {
            course.StudentTerm__c = course.StudentTerm__r.Id;
            course.StudentCourseVersion__c = course.StudentCourseVersion__r.Id;
            course.StudentDegreePlan__c = DegreePlan.Id;
        }
        if (degreeplan.CurrentPlan__c)
        upsert AllCourses;
        else upsert plannedcourses;
    }
    //reviewed 4/6/2012
    public StudentDegreePlans__c generateAndSave(){
        StudentDegreePlans__c plan=generateStudentDegreePlan();
        save();
        return plan;
    }
}