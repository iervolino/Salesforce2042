public with sharing class FDPUtilities {

    public static final Decimal MINUNITSPERTERM = 12;
    public static final String CURRENTPLANNAME='Current Plan';
    public static final String PLANNINGPLANNAME='Planning';
    public static final Integer TERMLENGTHINMONTHS = 6;
    public static String formatDateLong(Date pdate) {
      String formatted = '';
        Map <Integer,String> mToMonth = new Map<Integer,String>();
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

    public static void checkThrowExceptionTest() {
      if(ApexPages.currentPage().getParameters().get('throwTestException') != null) {
        throw new DegreePlanController.DegreePlanException('Throwing a test exception');
      }
    }

    public static Integer getTermInterval(String termCode) {
      return getTermInterval(
        getTermStartDateByCode(termCode)
      );
    }

    public static Integer getTermInterval(Date termStartDate) {
      if(termStartDate == null)
        return null;
      Integer month = termStartDate.month();
      if(month > 6) {
        month -= 6;
      }
      return month;
    }

    public static String formatVeryShortDate(Date pDate) {
      String formatted = '';
      formatted += pDate.year();
      Integer month = pDate.month();
      if(month < 10) {
        formatted += '0';
      }
      formatted += month;
      Integer day = pDate.day();
      if(day < 10) {
        formatted += '0';
      }
      formatted += day;
      return formatted;
    }

    public static String formatDateLongMonthYear(Date pdate) {
        // There's no formatter in apex code for date :)
        String formatted = '';
        Map <Integer,String> mToMonth = new Map<Integer,String>();
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

    public static void deletePlan(String planId) {
        List<StudentDegreePlans__c> plan = [select Id,CurrentPlan__c
            from StudentDegreePlans__c
            where id = :planId];
        if(plan.size() == 0) {
            throw new FDPUtilitiesException('Degree plan does not exist');
        }
        if(plan[0].CurrentPlan__c) {
            throw new FDPUtilitiesException('Cannot delete the current plan');
        }
        List<StudentTerm__c> terms = [select id
            from StudentTerm__c
            where StudentDegreePlan__c = :plan[0].id];
        List<StudentCourse__c> courses = [select id
            from StudentCourse__c
            where StudentTerm__c in :terms];
        if(courses.size() > 0)
            delete courses;
        if(terms.size() > 0)
            delete terms;
        delete plan;
    }

    //4/3/2012 see if they have a way of doing it in force.com
    public static String formatCurrency(Decimal dollarAmount,Integer decimalPlaces) {
     //String.format does not support formatting of anything other than strings *FAIL*
     //TODO: Implement Decimal Places
     String output = '';
     String dollarString = String.valueOf((Integer)dollarAmount);
     for(Integer i=0;i<dollarString.length();i++) {
        Integer index=dollarString.length() - 1 - i;
        output = dollarString.substring(index,index+1) + output;
        if(math.mod(i, 3)==2 && i!=dollarString.length()-1) {
            output = ',' + output;
        }
     }
     return '$'+output;
  }

  public static Date getTermStartDateFromStatusDateAndCurrentTerm(Date statusDate,Date currentTerm) {
    if(currentTerm == null || statusDate == null) {
      return null;
    }
    if(statusDate == Date.newInstance(1900,1,1)
      || statusDate == Date.newInstance(1901,1,1)) {
      return statusDate;
    }
    Date termBeginDate = currentTerm;
    Date termEndDate = getTermEndDateFromStartDate(termBeginDate);
    Integer iterations = 0;
    Boolean found = false;
    while(!(termBeginDate <= statusDate && statusDate <= termEndDate) && iterations < 30) {
      termBeginDate = getPreviousTermStartDateFromStartDate(termBeginDate);
      termEndDate = getTermEndDateFromStartDate(termBeginDate);
      iterations++;
    }
    if(iterations < 30) {
      return termBeginDate;
    }
    return null;
  }

    //reviewed 4/6/2012
    public static String getTermCodeFromContact(Contact student) {
        //return student.TermCode__c;
        // BETA code (trying this out)
        String termCode = student.TermCode__c;
        while(termCode != null && termCodeIsInPast(termCode)) {
          termCode = nextTermCodeFromTermCode(termCode);
        }
        return termCode;
    }

    public static Boolean termCodeIsInPast(String termCode) {
      return getTermEndDateByCode(termCode) < Date.Today();
    }
    //reviewed 4/6/2012
    public static Date getCurrentTermStartDateFromContact(Contact student) {
        String termCode = getTermCodeFromContact(student);
        return getTermStartDateByCode(termCode);
    }

    //reviewed 4/3/2012
    public static Date getPlanStartDate(String planId) {
        StudentDegreePlans__c plan = [select Id,Name,Student__c,
            (
              select Id,Name,StartDate__c
              from StudentTerms__r
              order by StartDate__c
              limit 1
            )
            from StudentDegreePlans__c
            where id = :planId];
        if(plan.StudentTerms__r.size() < 1 || plan.StudentTerms__r[0].StartDate__c == null) {
            return getNextTermStartDate();
        } else {
            return plan.StudentTerms__r[0].StartDate__c;
        }
    }
    //reviewed 4/3/2012
    public static Date getNextTermStartDate() {
        Date cur = Date.today();
        // Get next month then set the first of the month as the start date.
        Date nextstartdate = cur.addMonths(1);
        nextStartdate = Date.newInstance(nextStartdate.year(), nextStartdate.month(), 1);
        return nextStartdate;
    }

    public static String nextTermCodeFromTermCode(String termCode) {
      return generateTermCode(
        getNextTermStartDateFromStartDate(
          getTermStartDateByCode(
            termCode
          )
        )
      );
    }


    public static Date getTermStartDateByCode(String code) {
        if(code == null)
            return null;
        if(code == '000000')
          return Date.newInstance(1901,1,1);
        if(code == '111111')
          return Date.newInstance(1900,1,1);
        try{
            Integer codeYear = Integer.valueOf(code.substring(0, 4));
            Integer codeMonth = Integer.valueOf(code.substring(4, 6));
            return Date.newInstance(codeYear,codeMonth,1);
        }
        catch (exception e){
            return null;
        }
    }

    //reviewed 4/6/2012
    public static Date getTermEndDateFromStartDate(Date startDate) {
        if(startDate == null)
          return null;
        if(startDate == Date.newInstance(1901,1,1)
          || startDate == Date.newInstance(1900,1,1))
          return startDate;
        return startDate.addMonths(TERMLENGTHINMONTHS).addDays(-1);
    }
    //reviewed 4/6/2012
    public static Date getNextTermStartDateFromStartDate(Date startDate) {
        return startDate.addMonths(TERMLENGTHINMONTHS);
    }
    //reviewed 4/6/2012
    public static Date getPreviousTermStartDateFromStartDate(Date startDate) {
        return startDate.addMonths(-1*TERMLENGTHINMONTHS);
    }

    //reviewed 4/3/2012
    public static Date getTermEndDateByCode(String code) {
        Date startDate = getTermStartDateByCode(code);
        if(startDate == null)
            return null;
        return getTermEndDateFromStartDate(startDate);
    }

    public static void refreshNonDegreeRequirements(Contact student,String spoofid) {
      List<StudentLicenseHistory__c> li = [select Id,
        WGUStateLicensure__c
        from StudentLicenseHistory__c
        where Student__c =: student.Id
        order by SelectDate__c
        limit 1];
      if (li.size() == 0) {
        return;
      }
      List<WGULicenseRequirement__c> req = [select Id,
        Name,
        RequirementCode__c
        from WGULicenseRequirement__c
        where WGUStateLicensure__c =:li[0].WGUStateLicensure__c];
      List<StudentCourse__c> NonDegreeCourses = [select Name,
        CourseType__c,
        Student__c,
        Status__c,
        StudentTerm__c,
        StudentTerm__r.Name,
        StudentTerm__r.StudentDegreePlan__r.Id,
        WGULicenseRequirement__c,
        WGULicenseRequirement__r.RequirementCode__c
        from StudentCourse__c
        where Student__c = :student.Id
        and CourseType__c = 'Non Degree Requirement'];
      List<StudentDegreePlans__c> degreePlans = [select Id
        from StudentDegreePlans__c
        where Student__c = :student.Id];
      List<StudentTerm__c> terms = [select Id,
        StudentDegreePlan__r.Id,
        (select Id
          from StudentCourses__r)
        from StudentTerm__c
        where Student__c = :student.Id
        and Name = '111111'];
      Map<String,List<StudentCourse__c>> degreePlanToCourses = new Map<String,List<StudentCourse__c>>();
      Map<String,StudentTerm__c> degreePlanToTerm = new Map<String,StudentTerm__c>();
      for(StudentDegreePlans__c p : degreePlans) {
        degreePlanToCourses.put(p.Id,new List<StudentCourse__c>());
      }
      for(StudentCourse__c c : NonDegreeCourses) {
        degreePlanToCourses.get(c.StudentTerm__r.StudentDegreePlan__r.Id).add(c);
      }
      for(StudentTerm__c t : terms) {
        degreePlanToTerm.put(t.StudentDegreePlan__r.Id,t);
      }
      for(StudentDegreePlans__c plan : degreePlans) {
        Set<Id> existingReqs = new Set<Id>();
        for(StudentCourse__c c : degreePlanToCourses.get(plan.Id)) {
          existingReqs.add(c.WGULicenseRequirement__c);
        }
        StudentTerm__c nonDegreeTerm;
        if(degreePlanToTerm.containsKey(plan.Id)) {
          nonDegreeTerm = degreePlanToTerm.get(plan.Id);
        } else {
          nonDegreeTerm = new StudentTerm__c();
          nonDegreeTerm.Name = '111111';
          nonDegreeTerm.StartDate__c = Date.newInstance(1900,1,1);
          nonDegreeTerm.EndDate__c = Date.newInstance(1900,1,1);
          nonDegreeTerm.Approved__c = false;
          nonDegreeTerm.ApprovalStatus__c = 'Pending Mentor Approval';
          nonDegreeTerm.ApprovalDate__c = null;
          nonDegreeTerm.Student__c = student.Id;
          nonDegreeTerm.StudentDegreePlan__c = plan.Id;
          if(spoofid!=null) {
            nonDegreeTerm.ownerid=spoofid;
          }
          terms.add(nonDegreeTerm);
          degreePlanToTerm.put(plan.Id,nonDegreeTerm);
        }
        for(WGULicenseRequirement__c lr : req) {
          if(existingReqs.contains(lr.Id)) {
            continue;
          }
          StudentCourse__c course = new StudentCourse__c();
          course.Name = lr.Name;
          course.CourseType__c='Non Degree Requirement';
          course.Student__c = student.Id;
          course.Status__c ='Planned';
          course.WGULicenseRequirement__c=lr.id;
          course.WGULicenseRequirement__r=lr;
          course.StudentTerm__r = nonDegreeTerm;
          nonDegreeTerm.StudentCourses__r.add(course);
          if(spoofid!=null) {
            course.ownerid=spoofid;
          }
          NonDegreeCourses.add(course);
          degreePlanToCourses.get(plan.Id).add(course);
        }
      }
      upsert terms;
      for(StudentCourse__c c : NonDegreeCourses) {
        if(c.StudentTerm__c == null) {
          c.StudentTerm__c = c.StudentTerm__r.Id;
        }
      }
      upsert NonDegreeCourses;
    }

    // Reviewed 3/12/2012
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
    //10/2/2012
    public static StudentDegreePlans__c cloneStudentDegreePlan(String planid, String planName) {
        if(planName.length() >= 80) {
            throw new DegreePlanController.PlanNameTooLongException('Plan name is too long');
        }
        List<StudentTerm__c> terms = [select
          Name,
          Student__c,
          StudentDegreePlan__r.IsIncludeCurrentTerm__c,
          StudentDegreePlan__r.Student__c,
          StudentDegreePlan__r.OwnerId,
          StudentDegreePlan__r.BasedOnProgram__c,
          StartDate__c,
          EndDate__c,
          OwnerId,
          CompetencyUnits__c,
          (
            select Name,
            Student__c,
            Status__c,
            StudentCourseVersion__c,
            WGULicenseRequirement__c,
            TermSequence__c,
            StartDate__c,
            EndDate__c,
            Completed__c,
            CompletedDate__c,
            EnrollDate__c,
            CourseType__c,
            OwnerId
            from StudentCourses__r
            where Status__c = 'Planned'
            and StudentCourseVersion__r.Status__c = 'Planned'
          )
          from StudentTerm__c
          where StudentDegreePlan__r.Id = :planid
          and (EndDate__c >= Today
            or Name = '111111'
          )];

        AggregateResult res = [select count(id) numDegreePlans
          from StudentDegreePlans__c
          where Student__c = :terms[0].Student__c];
        if(Integer.valueOf(res.get('numDegreePlans')) >= 20) {
          throw new DegreePlanController.TooManyDegreePlansException('Too Many Degree Plans.');
        }
        StudentDegreePlans__c plan = null;
        List<StudentTerm__c> newTerms = new List<StudentTerm__c>();
        List<StudentCourse__c> newCourses = new List<StudentCourse__c>();
        for(StudentTerm__c oldTerm : terms) {
            if(plan == null) {
               plan = new StudentDegreePlans__c(
               Name                    = planName,
               IsIncludeCurrentTerm__c = oldTerm.StudentDegreePlan__r.IsIncludeCurrentTerm__c,
               Student__c              = oldTerm.StudentDegreePlan__r.Student__c,
               OwnerId                 = oldTerm.StudentDegreePlan__r.OwnerId,
               BasedOnProgram__c       = oldTerm.StudentDegreePlan__r.BasedOnProgram__c,
               ApprovalStatus__c       = 'Pending Mentor Approval',
               IsApproved__c           = false
               );
            }
            //if(oldTerm.StudentCourses__r.size() > 0) {
              StudentTerm__c term = new StudentTerm__c(
                Name               = oldTerm.Name,
                Student__c         = oldTerm.Student__c,
                StartDate__c       = oldTerm.StartDate__c,
                EndDate__c         = oldTerm.EndDate__c,
                OwnerId            = oldTerm.OwnerId,
                CompetencyUnits__c = oldTerm.CompetencyUnits__c
              );
              for(StudentCourse__c oldCourse : oldTerm.StudentCourses__r) {
                StudentCourse__c course = new StudentCourse__c(
                  Name                     = oldCourse.Name,
                  WGULicenseRequirement__c = oldcourse.WGULicenseRequirement__c,
                  Student__c               = oldCourse.Student__c,
                  Status__c                = oldCourse.Status__c,
                  CourseType__c            = oldCourse.CourseType__c,
                  TermSequence__c          = oldCourse.TermSequence__c,
                  StartDate__c             = oldCourse.StartDate__c,
                  EndDate__c               = oldCourse.EndDate__c,
                  OwnerId                  = oldCourse.OwnerId,
                  StudentCourseVersion__c  = oldCourse.StudentCourseVersion__c,
                  CompletedDate__c         = oldCourse.CompletedDate__c,
                  EnrollDate__c            = oldCourse.EnrollDate__c,
                  Completed__c             = oldCourse.Completed__c
                );
                course.StudentTerm__r = term;
                newCourses.add(course);
              }
              newTerms.add(term);
            //}
        }

        insert plan;
        for(StudentTerm__c term : newTerms) {
            term.StudentDegreePlan__c = plan.Id;
        }
        insert newTerms;
        List<StudentCourse__c> courses = new List<StudentCourse__c>();
        for(StudentCourse__c course : newCourses) {
            course.StudentTerm__c = course.StudentTerm__r.Id;
            courses.add(course);
        }
        insert courses;
        return plan;
    }

    public class FDPUtilitiesException extends Exception {}
    public static void doCourseCancelation(List<FDPCourseCancel__C> TriggerNew){
      if(Test.isRunningTest() || Limits.getFutureCalls() == Limits.getLimitFutureCalls()) {
           processCourseCancel(TriggerNew);
       } else {
          try {
            String jsontriggernew=JSON.serialize(TriggerNew);
            asyncCourseCancl( jsontriggernew);
          } catch (System.AsyncException e) {
            if ( e.getMessage().contains( 'Future method cannot be called from a future' ) ) {
               processCourseCancel(TriggerNew);
            } else {
              throw e;
            }
          }
       }

    }

    @future
    public static void asyncCourseCancl(String ListNewJSON){
     List<FDPCourseCancel__C> TriggerNew = (List<FDPCourseCancel__C>)JSON.deserialize( ListNewJSON, List<FDPCourseCancel__C>.class );
     processCourseCancel(TriggerNew);
    }
    public static void processCourseCancel(List<FDPCourseCancel__c> TriggerNew){

      
        Set<String> cr =new Set<String>();
        for (FDPCourseCancel__c a : TriggerNew) {
            String mergedkey=a.uniqueid__C;
            cr.add(mergedkey);
        }
         List<studentCourseRegistration__C > scr=[select id from studentcourseregistration__c st where st.uniqueid__C in :cr] ;
         List<StudentCourse__C> sts=[select id,student__C,studentterm__r.name,studentterm__C,StudentCourseVersion__c,status__C from studentcourse__c st where st.courseregistrationid__C in :cr and status__C not in ('Completed','Failed','Planned')] ;
         List<String> cvs=new List<String>();
         Set<String> userids=new Set<String>();
         Map<String,List<StudentCourse__c>> usermap=new Map<String,List<StudentCourse__c>>();
         for (StudentCourse__C course:sts){                  
                         course.startdate__c=null;
                         course.enddate__C=null;
                         course.EnrollDate__c = null;
                         course.status__C='Planned';
                         cvs.add(course.StudentCourseVersion__c);
                         userids.add(course.student__C);
                         List<StudentCourse__c> ccs=usermap.get(course.student__C);
                         if (ccs==null){
                            ccs=new List<StudentCourse__c>();
                            usermap.put(course.student__C,ccs);
                         }
                         ccs.add(course);
         }
         
         List<studentdegreeplans__C> dps= [select id,student__c, (select id,name,student__c from studentterms__r where startdate__C> TODAY  or (startdate__C<TODAY and enddate__C > TODAY)  order by startdate__C asc limit 2) from studentdegreeplans__C  where currentplan__C=false and student__C in :userids]; 
         List<studentcourse__C> othercourses=new list<Studentcourse__C>();
         for (studentdegreeplans__C plan:dps){
           if (plan.studentterms__r.size()>0){
            studentterm__C term=plan.studentterms__r[0];
            if (plan.studentterms__r.size()>1)
              term=plan.studentterms__r[1];
             List<StudentCourse__c> ccs=usermap.get(plan.student__C);
             for (StudentCourse__c c:ccs){
                StudentCourse__c sc=new Studentcourse__c();
                sc.name=c.name;
                sc.student__C=c.student__C;
                sc.studentterm__c=term.id;
                sc.studentcourseversion__c=c.studentcourseversion__c;
                sc.status__c='Planned';
                othercourses.add(sc);
             }
           }
         }
         
         List<StudentCourseversion__C> stcvs=[select id,EnrollDate__c,EnrollTermCode__c,StudentCourseRegistration__c,status__C from studentcourseversion__c st where id in :cvs and status__C not in ('Completed','Failed')] ;
          for (StudentCourseversion__C cv:stcvs){                  
                         cv.EnrollDate__c = null;
                        cv.EnrollTermCode__c=null;
                        cv.StudentCourseRegistration__c=null;
                         cv.status__C='Planned';
                     
         }
          if (othercourses.size()>0)
         insert othercourses;
         if (stcvs.size()>0)
       update stcvs;
       if (sts.size()>0)
       update sts;
       if(scr.size()>0)
       delete scr;
    }

    @future
    public static void asyncUpdateCourseLatestVersion(String ListNewJSON) {
      List<WGUCourseVersion__c> TriggerNew = (List<WGUCourseVersion__c>)JSON.deserialize(ListNewJSON,List<WGUCourseVersion__c>.class);
      processUpdateCourseLatestVersion(TriggerNew);
    }

    public static void processUpdateCourseLatestVersion(List<WGUCourseVersion__c> TriggerNew) {
      Set<Id> wguCourseIds = new Set<Id>();
      for(WGUCourseVersion__c cv : TriggerNew) {
        wguCourseIds.add(cv.WGUCourse__c);
      }
      List<WGUCourse__c> wguCourses = [
        select Name,LatestVersion__c,
        (
          select Name,MajorVersion__c
          from WGUCourseVersions__r
          where active__C=true and (LaunchDate__c <= TODAY
          or
          LaunchDate__c = null)
          order by MajorVersion__c desc
          limit 1
        )
        from WGUCourse__c
        where Id in :wguCourseIds
      ];
      List<WGUCourse__c> updateCourses = new List<WGUCourse__c>();
      for(WGUCourse__c c : wguCourses) {
        if(c.LatestVersion__c != c.WGUCourseVersions__r[0].Id) {
          c.LatestVersion__c = c.WGUCourseVersions__r[0].Id;
          updateCourses.add(c);
        }
      }
      update updateCourses;
    }

    public static void updateCourseLatestVersion(List<WGUCourseVersion__c> TriggerNew) {
      if(Test.isRunningTest() || Limits.getFutureCalls() == Limits.getLimitFutureCalls()) {
        processUpdateCourseLatestVersion(TriggerNew);
      } else {
        try {
          String jsonTriggerNew = JSON.serialize(TriggerNew);
          asyncUpdateCourseLatestVersion(jsontriggernew);
        } catch(System.AsyncException e) {
          if(e.getMessage().contains('Future method cannot be called from a future')) {
            processUpdateCourseLatestVersion(TriggerNew);
          } else {
            throw e;
          }
        }
      }
    }

    public static void linkCompletionCourse(List<StudentCompletionCourse__c> TriggerNew) {
      Map<String, String> pidmMap = new Map<String, String>();
      List<String> studentPidms = new List<String>();
      Map<String, WGUCourse__c> completionMap = new Map<String, WGUCourse__C>();
      List<String> completionCodes = new List<String>();


      for(StudentCompletionCourse__c task : TriggerNew) {
        if(task.PIDM__c != null) {
          studentPidms.add(task.PIDM__c);
        }
        if(task.Name != null) {
          completionCodes.add(task.Name);
        }
      }
      if(!studentPidms.isEmpty()){
        List<Contact> contacts = [
          select Id, pidm__c
          from Contact
          where pidm__c in :studentPidms
        ];
        for(Contact contact : contacts){
          pidmMap.put(contact.PIDM__c, contact.id);
        }
      }
      List<WGUCourse__c> updateLatestVersion = new List<WGUCourse__c>();
      if(!completionCodes.isEmpty()) {
        List<WGUCourse__c> courses = [
          select Id, Name,LatestVersion__c,
            LatestVersion__r.Version__c
          from WGUCourse__c
          where Name in :completionCodes
        ];
        for(WGUCourse__c course : courses){
          completionMap.put(course.name, course);
        }
      }
      for(StudentCompletionCourse__c task : TriggerNew) {
        if(task.PIDM__c != null) {
          task.Student__c = pidmMap.get(task.PIDM__c);
        }
        if (completionMap.get(task.name) != null) {
          task.WGUCourse__c = completionMap.get(task.Name).Id;
          //task.WGUCourseVersion__c = completionMap.get(task.Name).LatestVersion__c;
        }
      }

      // Mark task as complete id passed or given equivalent credit.
      for(StudentCompletionCourse__c task : TriggerNew) {
        if (task.Status__c == 'Passed'
          || task.Status__c == 'Waived'
          || task.Status__c == 'Transferred'
          || task.Status__c == 'Requirement Satisfied'
          || task.Status__c == 'Requirement Met')
          task.Complete__c = true;
        else
          task.Complete__c = false;
      }
    }

    @future
    public static void asyncUpdateCompletedCourses(String ListNewJson, String MapOldJson) {
      List<StudentCompletionCourse__c> TriggerNew = (List<StudentCompletionCourse__c>)JSON.deserialize(ListNewJson,List<StudentCompletionCourse__c>.class);
      Map<Id,StudentCompletionCourse__c> TriggerOldMap = (Map<Id,StudentCompletionCourse__c>)JSON.deserialize(MapOldJson,Map<Id,StudentCompletionCourse__c>.class);
      processUpdateCompletedOrEnrolledCourses(TriggerNew,TriggerOldMap);
    }

    public static List<GenericCourse> getCoursesList(List<sObject> cObjects) {
      Map<sObjectType,Map<String,String>> fNames = new Map<sObjectType,Map<String,String>>();
      Map<String,String> sccTypes = new Map<String,String>();
      sccTypes.put('Id','Id');
      sccTypes.put('Name','Name');
      sccTypes.put('BannerActivityDate','BannerActivityDate__c');
      sccTypes.put('Complete','Complete__c');
      sccTypes.put('CourseCode','Name');
      sccTypes.put('EndDate','undef');
      sccTypes.put('PIDM','PIDM__c');
      sccTypes.put('StartDate','undef');
      sccTypes.put('Status','status__c');
      sccTypes.put('StatusDate','StatusDate__c');
      sccTypes.put('Student','Student__c');
      sccTypes.put('TermCode','TermCode__c');
      sccTypes.put('UniqueId','UniqueId__c');
      sccTypes.put('WGUCourse','WGUCourse__c');
      sccTypes.put('WGUCourseVersion','WGUCourseVersion__c');
      Map<String,String> scrTypes = new Map<String,String>();
      scrTypes.put('Id','Id');
      scrTypes.put('Name','Name');
      scrTypes.put('BannerActivityDate','Banneractivitydate__c');
      scrTypes.put('Complete','undef');
      scrTypes.put('CourseCode','CourseCode__c');
      scrTypes.put('EndDate','enddate__c');
      scrTypes.put('PIDM','pidm__c');
      scrTypes.put('StartDate','startdate__c');
      scrTypes.put('Status','undef');
      scrTypes.put('StatusDate','undef');
      scrTypes.put('Student','Student__c');
      scrTypes.put('TermCode','Termcode__c');
      scrTypes.put('UniqueId','uniqueid__c');
      scrTypes.put('WGUCourse','WGUCourse__c');
      scrTypes.put('WGUCourseVersion','undef');
      fNames.put(StudentCompletionCourse__c.sObjectType,sccTypes);
      fNames.put(StudentCourseRegistration__c.sObjectType,scrTypes);
      List<GenericCourse> cs = new List<GenericCourse>();
      for(sObject c : cObjects) {
        cs.add(new GenericCourse(c,fNames.get(c.getSObjectType())));
      }
      return cs;
    }

    public with sharing class GenericCourse {
      public Id Id;
      public String Name;
      public Date BannerActivityDate;
      public Boolean Complete;
      public String CourseCode;
      public Date EndDate;
      public String PIDM;
      public Date StartDate;
      public String Status;
      public Date StatusDate;
      public Id Student;
      public String TermCode;
      public String UniqueId;
      public Id WGUCourse;
      public Id WGUCourseVersion;
      public Boolean IsEnrollment;
      public Boolean IsCompletion;

      public Object get(sObject c, String type) {
        if(type == 'undef')
          return null;
        return c.get(type);
      }

      public GenericCourse(sObject c,Map<String,String> types) {
        this.Id                 = (Id)      get(c,types.get('Id'));
        this.Name               = (String)  get(c,types.get('Name'));
        this.BannerActivityDate = (Date)    get(c,types.get('BannerActivityDate'));
        this.Complete           = (Boolean) get(c,types.get('Complete'));
        this.CourseCode         = (String)  get(c,types.get('CourseCode'));
        this.EndDate            = (Date)    get(c,types.get('EndDate'));
        this.PIDM               = (String)  get(c,types.get('PIDM'));
        this.StartDate          = (Date)    get(c,types.get('StartDate'));
        this.Status             = (String)  get(c,types.get('Status'));
        this.StatusDate         = (Date)    get(c,types.get('StatusDate'));
        if(this.StatusDate == null) {
          this.StatusDate = this.BannerActivityDate;
        }
        this.Student            = (Id)      get(c,types.get('Student'));
        this.TermCode           = (String)  get(c,types.get('TermCode'));
        this.UniqueId           = (String)  get(c,types.get('UniqueId'));
        this.WGUCourse          = (Id)      get(c,types.get('WGUCourse'));
        this.WGUCourseVersion   = (Id)      get(c,types.get('WGUCourseVersion'));
        if(this.Complete == null)
          this.Complete = false;
        this.IsEnrollment = StudentCourseRegistration__c.sObjectType == c.getSObjectType();
        this.IsCompletion = !this.IsEnrollment;
      }
    }

    public static Map<Id,GenericCourse> getCoursesMap(Map<Id,sObject> TriggerOldMap) {
      if(TriggerOldMap == null) {
        return null;
      }
      List<GenericCourse> l = getCoursesList(TriggerOldMap.values());
      Map<Id,GenericCourse> courses = new Map<Id,GenericCourse>();
      for(GenericCourse c : l) {
        if(c.Id != null) {
          courses.put(c.Id,c);
        }
      }
      return courses;
    }

    public static void processUpdateCompletedOrEnrolledCourses(List<sObject> TriggerNew, Map<Id,sObject> TriggerOldMap) {
      List<GenericCourse> genericCourses = getCoursesList(TriggerNew);
      Map<Id,GenericCourse> genericOldCoursesMap = getCoursesMap(TriggerOldMap);

      Set<String> completedids = new Set<String>();
      Set<String> wguCourseIds = new Set<String>();
      Set<String> pidms = new Set<String>();
      for(GenericCourse c : genericCourses) {
        wguCourseIds.add(c.WGUCourse);
        pidms.add(c.PIDM);
        if(c.Complete
            || c.IsEnrollment
              ) {
          completedids.add(c.Student + '-' + c.WGUCourse);
        } else {
          String shortDate = formatVeryShortDate(c.StatusDate);
          completedids.add(c.Student+'-'+c.WGUCourse+'-'+shortDate);
        }
      }
      List<User> users = [select PIDM__c,Id,ContactId
        from User
        where PIDM__c in :pidms];
      Map<String,Id> pidmToUserId = new Map<String,Id>();
      for(User u : users) {
        pidmToUserId.put(u.PIDM__c,u.Id);
      }
      List<StudentCourseVersion__c> studentCourseVersions = [
        select Id,
        Name,
        WGUCourseVersion__c,
        WGUCourseVersion__r.WGUCourse__c,
        Completed__c,
        CompletedTermCode__c,
        StatusDate__c,
        Status__c,
        Student__c,
        StudentCompletionCourse__c,
        StudentCourseRegistration__c,
        WGUCourseVersion__r.WGUCourse__r.Name,
        EnrollTermCode__c,
        (
          select StudentTerm__r.Name,
          StudentTerm__r.StudentDegreePlan__r.CurrentPlan__c,
          StudentTerm__r.StudentDegreePlan__r.Name,
          StartDate__c,
          EndDate__c,
          EnrollDate__c,
          Completed__c,
          Status__c
          from StudentCourses__r
        )
        from StudentCourseVersion__c
        where Name in :completedids];
      Map<Id,WGUCourseVersion__c> latestCourseVersions = new Map<Id,WGUCourseVersion__c>();
      List<WGUCourse__c> wguCourses = [
        select Id,
        (select Id,MajorVersion__c
         from WGUCourseVersions__r)
        from WGUCourse__c
        where Id in :wguCourseIds];
      for(WGUCourse__c c : wguCourses) {
        for(WGUCourseVersion__c cv : c.WGUCourseVersions__r) {
          if(latestCourseVersions.get(c.Id) == null
            || latestCourseVersions.get(c.Id).MajorVersion__c <
                cv.MajorVersion__c) {
            latestCourseVersions.put(c.Id,cv);
          }
        }
      }

      Map<String,StudentCourseVersion__c> studentcvmap=new Map<String,StudentCourseVersion__c>();
      Map<String,StudentCourseVersion__c> studentcvfailedmap=new Map<String,StudentCourseVersion__c>();
      for(StudentCourseVersion__c cv : studentCourseVersions) {
        studentcvmap.put(cv.Name,cv);
      }
      List<StudentCourse__c> upsertCourses = new List<StudentCourse__c>();
      List<StudentCourse__c> deleteCourses = new List<StudentCourse__c>();
      List<StudentCourseVersion__c> upsertCourseVersions = new List<StudentCourseVersion__c>();
      Map<StudentCourse__c,StudentCourseVersion__c> updateCourseWithCourseVersion
       = new Map<StudentCourse__c,StudentCourseVersion__c>();
      for(GenericCourse c : genericCourses) {
        boolean foundSCV = false;
        if((c.IsCompletion && c.Complete == true) || c.IsEnrollment) {
          // passed course or enrolled course
          // finds the existing course and marks it as complete
          // if the degree plan hasn't been generated yet then
          // it creates the StudentCourseVersion only
          // searches by StudentId + CourseId
          // deletes the courses that are not in the current plan
          StudentCourseVersion__c cvOld= studentcvmap.get(c.Student+'-'+c.WGUCourse);
          if(cvOld!=null){
            // Only update the fields that need to be updated
            // Not everything
            StudentCourseVersion__c cv = new StudentCourseVersion__c(Id=cvOld.Id);
            foundSCV = true;
            Boolean addedCV = false;
            if(
                (c.IsEnrollment && cvOld.Status__c != 'Enrolled' && !cvOld.Completed__c)
                 ||
                (c.IsCompletion && !cvOld.Completed__c)
              ) {
              for(StudentCourse__c coOld : cvOld.StudentCourses__r) {
                StudentCourse__c co = new StudentCourse__c(Id=coOld.Id);
                if(!coOld.StudentTerm__r.StudentDegreePlan__r.CurrentPlan__c) {
                  deleteCourses.add(co);
                } else {
                  co.Status__c = c.IsEnrollment ? 'Enrolled' : 'Completed';
                  co.Completed__c = !c.IsEnrollment;
                  if(c.IsEnrollment) {
                    co.EnrollDate__c = c.BannerActivityDate;
                    co.StartDate__c = c.StartDate;
                    co.EndDate__c = c.EndDate;
                  } else {
                    co.CompletedDate__c = c.StatusDate;
                  }
                  upsertCourses.add(co);
                }
              }
              cv.Status__c = c.IsEnrollment ? 'Enrolled' : 'Completed';
              cv.Completed__c = c.IsCompletion;
              if(c.IsEnrollment) {
                cv.EnrollDate__c = c.BannerActivityDate;
                cv.EnrollTermCode__c = c.TermCode;
              } else {
                cv.CompletedDate__c = c.StatusDate;
                cv.CompletedTermCode__c = c.TermCode;
              }
              addedCV = true;
              upsertCourseVersions.add(cv);
            }
            if(c.IsCompletion && cvOld.StudentCompletionCourse__c == null) {
              cv.StudentCompletionCourse__c = c.Id;
              if(!addedCV) {
                upsertCourseVersions.add(cv);
              }
            } else if(c.IsEnrollment && cvOld.StudentCourseRegistration__c == null) {
              cv.StudentCourseRegistration__c = c.Id;
              if(!addedCV) {
                upsertCourseVersions.add(cv);
              }
            }
          }
          if(!foundSCV) {
            StudentCourseVersion__c scv = new StudentCourseVersion__c();
            scv.Student__c = c.Student;
            scv.Completed__c = c.IsCompletion;
            if(c.IsEnrollment) {
              scv.EnrollTermCode__c = c.TermCode;
              scv.EnrollDate__c = c.BannerActivityDate;
              scv.StudentCourseRegistration__c = c.Id;
            } else {
              scv.CompletedTermCode__c = c.TermCode;
              scv.CompletedDate__c = c.StatusDate;
              scv.StudentCompletionCourse__c = c.Id;
            }
            scv.Status__c = c.IsEnrollment ? 'Enrolled' : 'Completed';
            scv.Name = c.Student+'-'+c.WGUCourse;
            if(latestCourseVersions.get(c.WGUCourse) != null) {
              scv.WGUCourseVersion__c = latestCourseVersions.get(c.WGUCourse).Id;
            }
            StudentCourse__c sc = new StudentCourse__c();
            sc.Student__c = c.Student;
            sc.Completed__c = c.IsCompletion;
            if(pidmToUserId.containsKey(c.PIDM)) {
              sc.OwnerId = pidmToUserId.get(c.PIDM);
              scv.OwnerId = pidmToUserId.get(c.PIDM);
            }
            sc.Status__c = c.IsEnrollment ? 'Enrolled' : 'Completed';
            if(c.IsCompletion) {
              sc.CompletedDate__c = c.StatusDate;
            } else {
              sc.EnrollDate__c = c.BannerActivityDate;
              sc.StartDate__c = c.StartDate;
              sc.EndDate__c = c.EndDate;
            }
            sc.CourseType__c = 'Course';
            sc.Name = c.CourseCode;
            if (scv.WGUCourseVersion__c!=null){// only studentcourseversion that has a wgucourseversion will be created.
              upsertCourses.add(sc);
              upsertCourseVersions.add(scv);
              updateCourseWithCourseVersion.put(sc,scv);
            }
          }
        } else {
          // failed course
          // creates a new StudentCourseVersion and StudentCourse
          // if it hasn't been created already
          // searches by Student + CourseVersion + Term Code + Status = failed
         // boolean found = false;
         /* for(StudentCourseVersion__c cv : studentCourseversions) {
            if(cv.Status__c == 'Failed'
              && cv.Student__c == c.Student__c
              && cv.WGUCourseVersion__c == c.WGUCourseVersion__c
              && cv.StatusDate__c == c.StatusDate__c) {
              found = true;
              break;
            }
          }*/
          String shortDate = formatVeryShortDate(c.StatusDate);
          StudentCourseVersion__c cv= studentcvmap.get(c.Student+'-'+c.WGUCourse+'-'+shortDate);
          if(cv==null) {
            StudentCourseVersion__c scv = new StudentCourseVersion__c();
            scv.Student__c = c.Student;
            scv.Completed__c = false;
            scv.CompletedTermCode__c = c.TermCode;
            scv.StudentCompletionCourse__c = c.Id;
            scv.Status__c = 'Failed';
            scv.Name = c.Student+'-'+c.WGUCourse+'-'+shortDate;
            scv.StatusDate__c = c.StatusDate;
            if(latestCourseVersions.get(c.WGUCourse) != null) {
              scv.WGUCourseVersion__c = latestCourseVersions.get(c.WGUCourse).Id;
            }
            StudentCourse__c sc = new StudentCourse__c();
            sc.Student__c = c.Student;
            sc.Completed__c = false;
            sc.EndDate__c = c.StatusDate;
            if(pidmToUserId.containsKey(c.PIDM)) {
              scv.OwnerId = pidmToUserId.get(c.PIDM);
              sc.OwnerId = pidmToUserId.get(c.PIDM);
            }
            sc.Status__c = 'Failed';
            sc.Name = c.CourseCode;
            if(pidmToUserId.containsKey(c.PIDM)) {
              sc.OwnerId = pidmToUserId.get(c.PIDM);
              scv.OwnerId = pidmToUserId.get(c.PIDM);
            }
            scv.StudentCompletionCourse__c = c.Id;
              if (scv.wgucourseversion__C!=null){
                upsertCourses.add(sc);
                upsertCourseVersions.add(scv);
                updateCourseWithCourseVersion.put(sc,scv);
              }
          } else if(cv.StudentCompletionCourse__c == null) {
            //Only update the single field not everything
            StudentCourseVersion__c cvNew = new StudentCourseVersion__c(Id=cv.Id);
            cvNew.StudentCompletionCourse__c = c.Id;
            upsertCourseVersions.add(cvNew);
          }
        }
      }
      if(upsertCourseVersions.size() > 0)
        upsert upsertCourseVersions;
      for(StudentCourse__c c : updateCourseWithCourseVersion.keySet()) {
        c.StudentCourseVersion__c = updateCourseWithCourseVersion.get(c).Id;
      }
      if(upsertCourses.size() > 0)
        upsert upsertCourses;
      if(deleteCourses.size() > 0)
        delete deleteCourses;
    }

    public static void updateCompletedCourses(List<StudentCompletionCourse__c> TriggerNew, Map<Id,StudentCompletionCourse__c> TriggerOld) {
      if(Test.isRunningTest() || Limits.getFutureCalls() == Limits.getLimitFutureCalls()) {
        processUpdateCompletedOrEnrolledCourses(TriggerNew,TriggerOld);
      } else {
        try {
          String jsonTriggerNew = JSON.serialize(TriggerNew);
          String jsonTriggerOld = JSON.serialize(TriggerOld);
          asyncUpdateCompletedCourses(jsonTriggerNew,jsonTriggerOld);
        } catch(System.AsyncException e) {
          if(e.getMessage().contains('Future method cannot be called from a future')) {
            processUpdateCompletedOrEnrolledCourses(TriggerNew,TriggerOld);
          } else {
            throw e;
          }
        }
      }
    }

    @future
    public static void asyncUpdateEnrolledCourses(String ListNewJson, String MapOldJson) {
      List<StudentCourseRegistration__c> TriggerNew = (List<StudentCourseRegistration__c>)JSON.deserialize(ListNewJson,List<StudentCourseRegistration__c>.class);
      Map<Id,StudentCourseRegistration__c> TriggerOld = (Map<Id,StudentCourseRegistration__c>)JSON.deserialize(MapOldJson,Map<Id,StudentCourseRegistration__c>.class);
      processUpdateCompletedOrEnrolledCourses(TriggerNew,TriggerOld);
    }

    public static void updateEnrolledCourses(List<StudentCourseRegistration__c> TriggerNew,Map<Id,StudentCourseRegistration__c> TriggerOld) {
      if(Test.isRunningTest() || Limits.getFutureCalls() == Limits.getLimitFutureCalls()) {
        processUpdateCompletedOrEnrolledCourses(TriggerNew,TriggerOld);
      } else {
        try {
          String jsonTriggerNew = JSON.serialize(TriggerNew);
          String jsonTriggerOld = JSON.serialize(TriggerOld);
          asyncUpdateEnrolledCourses(jsonTriggerNew,jsonTriggerOld);
        } catch(System.AsyncException e) {
          if(e.getMessage().contains('Future method cannot be called from a future')) {
            processUpdateCompletedOrEnrolledCourses(TriggerNew,TriggerOld);
          } else {
            throw e;
          }
        }
      }
    }

    public static String getLastDegreePlan(String userId,String studentId) {
        List<FDPUserLastPlan__c> plans = [Select Name,LastPlanViewed__c
        from FDPUserLastPlan__c
        where Name = :userId
        and Student__c = :studentId];
        if(plans.size() == 0) {
            return null;
        }
        return plans.get(0).LastPlanViewed__c;
    }

    public static void setLastDegreePlan(String userId,String studentId, String LastPlanViewed) {
        List<FDPUserLastPlan__c> plans = [select name,LastPlanViewed__c
        from FDPUserLastPlan__c
        where Name = :userId
        and Student__c = :studentId];
        FDPUserLastPlan__c lastP;
        if(plans.size() ==0) {
            lastP = new FDPUserLastPlan__c(Name=userId,Student__c=studentId,LastPlanViewed__c=LastPlanViewed);
        } else {
            lastP = plans.get(0);
            lastP.LastPlanViewed__c = LastPlanViewed;
        }
        upsert lastP;
    }

    public class PAMSMappings {
        public Map<decimal,string> programidmap = null;
        public Map<decimal,string> courseidmap = null;

        private void loadcourseprogramMaps(){
             programidmap = new Map<decimal,String>();
             courseidmap = new Map<decimal,String>();
             list<WGUCourse__C> courses=[select id, PAMSID__c from wgucourse__C];
                for(WGUCourse__C onecourse:courses){
                courseidmap.put(onecourse.PAMSID__C,onecourse.id);
             }
            list<WGUDegreeProgram__c> programs=[select id, PAMSID__c from WGUDegreeProgram__c];
                 for(WGUDegreeProgram__c oneprogram:programs){
                 programidmap.put(oneprogram.PAMSID__C,oneprogram.id);
            }

        }
        public String getidfromcoursepamsid(decimal pamsid){
            if (courseidmap==null)loadcourseprogramMaps();
            return courseidmap.get(pamsid);

        }
         public String getidfromprogrampamsid(decimal pamsid){
            if (programidmap==null)loadcourseprogramMaps();
            return programidmap.get(pamsid);
        }
    }

    //this will work on current selected plan. it will set the course start, end date and point the term to the termcode in selectedplan. Then set the status to enrolled.
     public static void mapEnrolledCourses(Contact contact, String planid,String termcode) {
          List<StudentCourseRegistration__c > crs =[select startdate__C, enddate__C,pidm__C,coursecode__C,Banneractivitydate__c from StudentCourseRegistration__c where Student__c=:contact.Id and termcode__C=:termcode];
            List<String> coursecodes=new List<String>();
            Map<String, StudentCourseRegistration__c > registers=new Map<String, StudentCourseRegistration__c>();
            for (StudentCourseRegistration__c a : crs) {

                coursecodes.add(a.coursecode__C);
                registers.put(a.coursecode__C,a);

             }
              List<StudentTerm__C> term=[select name,id from studentTerm__c st where st.student__r.pidm__C=:contact.pidm__C and st.name=:termcode and StudentDegreePlan__r.id=:planid] ;
             List<StudentCourse__C> scs=[select id,name,status__C,studentterm__r.studentdegreeplan__C,student__c from studentcourse__c st where st.student__c=:contact.id and st.name in :coursecodes and st.studentterm__r.studentdegreeplan__C=:planid] ;
             /*List<StudentCourse__C> enrolled=[select id from studentcourse__c st where st.student__c=:contact.id and st.status__C='Enrolled' and st.studentterm__r.studentdegreeplan__C=:planid] ;
             Set<StudentCourse__C> all=new  Set<StudentCourse__C>(enrolled);
             all.removeall(scs);//here we get all enrolled courses in salesforce,which implys that they were enrolled but now are not enrolled in banner.
             for (StudentCourse__C course:all){
              course.status__C='Planned';
             }
              */
             for (StudentCourse__C course:scs){
                 StudentCourseRegistration__c a=registers.get(course.name);

                 course.startdate__c=a.startdate__C;
                 course.enddate__C=a.enddate__C;
                 course.EnrollDate__c = a.Banneractivitydate__c;
                 if (course.Status__c != 'Completed' && course.Status__c != 'Failed'){
                    if (term.size()>0){
                     course.StudentTerm__c=term[0].id;
                    }
                     course.status__C='Enrolled';
                 }
             }
            // scs.addall(all);

             update scs;
     }

     public static void batchdelete() {
        String termcode = generateTermCode(
          Date.Today().addMonths(-7)
        );
        String query = 'select Id '
          + ' from StudentCourseRegistration__c '
          + ' where TermCode__c < \'' + termcode + '\' ';
        Database.executeBatch(new BatchDelete(query));
     }


     public static void cleandegreeplanwithpidm(String mystudentpidm){

        List<studentdegreeplans__C>plans=[select id from studentdegreeplans__C where student__r.pidm__C=:mystudentpidm];
        List<StudentCourse__c> courses = [Select Id From studentcourse__C where student__r.pidm__C=:mystudentpidm ];
        List<StudentTerm__c> terms = [select id from StudentTerm__c where StudentDegreePlan__r.student__r.pidm__C=:mystudentpidm];
        List<studentCourseVersion__C> cvs=[select id from studentcourseversion__C where student__r.pidm__C=:mystudentpidm];
        delete courses;
        delete cvs;
        delete terms;
        delete plans;
        List<StudentCourseRegistration__c> registrations = [select id,
          Student__c,WGUCourse__c,CourseCode__c,PIDM__c,
          BannerActivityDate__c,TermCode__c,EndDate__c,
          StartDate__c,Name,UniqueId__c
          from StudentCourseRegistration__c
          where pidm__C=:mystudentpidm ];
        Map<Id,StudentCourseRegistration__c> rMap = new Map<Id,StudentCourseRegistration__c>();
        for(StudentCourseRegistration__c scr : registrations) {
          rMap.put(scr.Id,scr);
        }
        FDPUtilities.processUpdateCompletedOrEnrolledCourses(registrations,rMap);

        List<StudentCompletionCourse__c> completions = [select id,
          WGUCourse__c,PIDM__c,Student__c,StatusDate__c,
          TermCode__c,Complete__c,Name,Status__c,UniqueId__c,
          WGUCourseVersion__c,BannerActivityDate__c
          from StudentCompletionCourse__c
          where pidm__C=:mystudentpidm];
        Map<Id,StudentCompletionCourse__c> cMap = new Map<Id,StudentCompletionCourse__c>();
        for(StudentCompletionCourse__c scc : completions) {
          cMap.put(scc.Id,scc);
        }
        FDPUtilities.processUpdateCompletedOrEnrolledCourses(completions,cMap);
     }
}