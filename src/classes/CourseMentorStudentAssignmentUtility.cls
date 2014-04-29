/**
    Utility class for assign(associate) course mentors with students
    
    1. auto assignment for a list of mentors
    2. create assignment with types ( engagement, manual, data start, course passed)
    
    3. check department? can IT mentor handle Child Education student?
    4. check courses? can calculus II mentor take care Number theory or PDE student?
    5. sent notification to mentor?
    6. sent notification to student?
    7. 
    
    
    
     
*/

global class CourseMentorStudentAssignmentUtility implements  Database.Batchable<sObject>
{
   
// batch apex : contructor, start, execute, finish  
   global final String Option;
   global final String Query; 
   String queryFields =  'Select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,   Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,(Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c  From StudentAcademicCourseRequirements__r) '
                            + ' from StudentAcademicCourse__c ';
   global CourseMentorStudentAssignmentUtility(String o,String q)
   {
         Option=o;
         Query=q;
   } 
   global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(Query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
        System.debug('##### Case Load Batch#####'+BC);
        if(Option.equals('COURSECOMPLETE'))
        {
            removeAssignmentsForPassedCourses(scope,'Pass');
            return;
      
        }else if(Option.equals('DAILYCREATE'))
        { 
            createAssignmentsByStudentAcademicCourses(scope);
            return;
        } else if(Option.equals('TERMROLL'))
        {
             
            removeAssignmentDaily(scope);
            return;
        } else if(Option.equals('DELETE'))
        {
             
            deleteAssignments(scope);
            return;
        } else if(Option.equals('UPGRADE'))
        {
             
            upgradeAssignments(scope);
            return;
        } else if(Option.contains('CALCULATE')) //alternative way to calculate case load.
        {	System.debug('Calculate case load balance '+Option); 
        	for(Integer i=0;i<=9;i++)
        	{	
        		String pidmEnd=''+i;
        		if(Option.contains(pidmEnd)||Option.equals('CALCULATE'))
        		{  
        			calculateCurrentCaseLoadForMentors(pidmEnd);
        		}
        	}
        	return;
        }
        createAssignmentsByStudentAcademicCourses(scope);
    }

   global void finish(Database.BatchableContext BC){
        System.debug(Logginglevel.INFO,'Course mentor autoassignment from student course registration is done by CourseMentorStudentAssignmentUtility '+date.today());
   }
    
    
    
    
    //=================================================  functions ================================================================
    
    
    /* 
        method for VF page : 
            apex/CourseMentorStudentAssignment?id=xxxx
        one vs. one assignment(manual assign)
    */
    webservice static boolean createAssignmentManual(Mentor__c mentor, StudentAcademicCourse__c course )
    {    
        return createAssignment(mentor, course, 'Manual Assignment');
    }

    /* 
        ===============Basic method: create single assignment. ==============
                    * Don't cal this method from trigger , it will hit governer limit real soon.
        one vs. one assignment:
    */
    webservice static boolean createAssignment(Mentor__c mentor,   StudentAcademicCourse__c Course ,  String type)
    {  if(course==null ||course.id==null||mentor==null)
        {
            return false;
        }
        Date startdate=Course.startdate__c; 
        Date enddate=Course.enddate__c;
        String CourseCode=Course.CourseCode__c; 
        course = [select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,  Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,(Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c  From StudentAcademicCourseRequirements__r)
                from StudentAcademicCourse__c where id = :course.id];
        // 1. Do not create duplicate assignment: refuse if this assignment (mentor, course, student)pair already exist, it should not be assigned again.
        if([select Id, Mentor__c,Mentor__r.CurrentStudents__c, Student__c,CourseCode__c ,StudentAcademicCourse__c, 
                        StudentAcademicCourse__r.status__c, TermCode__c, IsActive__c
                         from CourseMentorStudentAssignment__c 
                         where Mentor__c = :mentor.id 
                         and Student__c = :course.studentContact__c 
                         and CourseCode__c=:CourseCode 
                         and IsActive__c = true].size()>0)
        {   
            System.debug(Logginglevel.INFO,'Course Mentor Assignment already exist [  Student: ' +course.studentContact__c +' mentor:'+mentor.id + '   course:'+ coursecode  );
            return false;
        }
        // 2. Change mentor if new mentor != old mentor:   if the course-student pair aleady assigned to another mentor, considere this as switch a new mentor.
        if(mentor!=null && [select Id, CourseCode__c,Mentor__c, Mentor__r.CurrentStudents__c, Student__c, StudentAcademicCourse__c, 
                        StudentAcademicCourse__r.status__c,  TermCode__c,  IsActive__c 
                        from CourseMentorStudentAssignment__c 
                        where Mentor__c != :mentor.id  
                        and CourseCode__c=:CourseCode 
                        and Student__c = :course.StudentContact__c  
                        and IsActive__c =true ].size()>0)
        {   
        //  system.assert( [select Id, CourseCode__c,Mentor__c, Mentor__r.CurrentStudents__c, Student__c,StudentCourseRegistration__c , IsActive__c from CourseMentorStudentAssignment__c where Mentor__c != :mentor.id  and CourseCode__c=:CourseCode and Student__c = :course.Student__c  and IsActive__c =true ].size()==1);
            return reassignMentor([select Id, CourseCode__c, Mentor__c, Mentor__r.CurrentStudents__c,Student__c,TermCode__c, IsActive__c  from CourseMentorStudentAssignment__c where Mentor__c != :mentor.id  and CourseCode__c=:CourseCode and Student__c = :course.studentContact__c and IsActive__c =true ][0],mentor);
        }
        // 3. create new assignment, insert it and increase the load in mentor's record 
        if(mentor!=null && course.studentContact__c!=null && CourseCode!=null && /*startDate!=null && */CourseCode.length()!=0 && type!=null && mentor.Available__c==true  /*mentor.CurrentStudents__c<mentor.MaxStudents__c &&(mentor.MentorRole__c == 'Course Mentor'||mentor.MentorRole__c == 'Student Mentor / Course Mentor')*/)
        {
            CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c();
            ass.Mentor__c=mentor.id;
            ass.StudentAcademicCourse__c=course.id;
            ass.MentorPidm__c=mentor.pidm__c;
            ass.Student__c=course.studentContact__c;
            ass.PIDM__c=course.StudentContact__r.pidm__c;
            ass.CourseCode__c=CourseCode;
            ass.ReasonOfAssignment__c= type; 
            ass.User__c = mentor.User__c;
            ass.IsActive__c= true;
            ass.AssignmentStartDate__c= date.today();
            ass.TermCode__c = course.Term__c;
            mentor.CurrentStudents__c++;    //here we allowed CurrentStudent__c > max Student in same case. 
                                            //mentor loads can be solved later on , but students should not be left alone.
            update mentor;
            insert ass;
             
            
             //backward lookup field
             StudentAcademicCourse__c sac=[select id, CourseMentorStudentAssignment__c from StudentAcademicCourse__c where id = : ass.StudentAcademicCourse__c];
             sac.CourseMentorStudentAssignment__c = ass.id;
             update sac;
            System.debug(Logginglevel.INFO,'Course Mentor Assignment Created [  Student: ' +course.studentContact__c +' mentor:'+mentor.id + '   course:'+ coursecode + ' startDate:'+startDate+ '  Reason:'+type);
            return true;
        }
        return false;
    }
    
    /*
    DAILY CREATION:
        Suppose to run in daily basis as batch apex call over mass number of studentcourseregistration no more than 50000 .
        can also be used in student course registration object's trigger, which dealing with 200 object per batch.
        
        
        given a list of student course registration which startdate < today, and enddate > today, 
         1. check to see if those assignments already exist
         2. if not exist,
            2.1 check available mentors
            2.2 create assignment 
        
        Attention:
        * because the salesforce has governer limit of 100 query, 150 dml operation on each call, for object with mass number of record , we have
        to sacr     
        * salesforce's log size can not be larger than 2MB, so a big portion of log will be truncated in real world excution. Shame on them. 
    */
    public static void createAssignmentsByStudentAcademicCourses(List<StudentAcademicCourse__c> sacs)
    {
        if(sacs==null||sacs.size()==0)
        {
            return;
        }
        sacs = [Select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,   Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c 
                             from StudentAcademicCourse__c where id IN :sacs];
        Set<String> pidms=new Set<String>();
        Set<String> coursecodes=new Set<String>(); 
        Set<String> uniquePairs=new Set<String>();
        Set<Id> ids=new Set<Id>();
        for(StudentAcademicCourse__c sac:sacs)
        {
                ids.add(sac.id);
                pidms.add(sac.StudentContact__r.pidm__c);
                coursecodes.add(sac.CourseCode__c);
                uniquePairs.add(sac.CompositeKey__c);
                
        }
        
  // PART 1: remove registrations which already have assignments    
  // edit 3/11: if some assignment still associate with StudentCourseRegistration rather than StudentAcademicCourse, we dont want to create case load again.
  //    or the existing SAC has been removed and re-imported, we dont want to have 2 Case load for this course/student pair.
        for(CourseMentorStudentAssignment__c ass:[select id, IsActive__c, StudentAcademicCourse__c ,CourseCode__c, TermCode__c, pidm__c,Student__c 
         											from CourseMentorStudentAssignment__c     
         											where ( (StudentAcademicCourse__c IN :ids )
        											or( pidm__c in :pidms and coursecode__c IN :CourseCodes)) 
        											and IsActive__c = true])
        {
        	if(ids.contains(ass.StudentAcademicCourse__c) || uniquePairs.contains(ass.pidm__c+'-'+ass.CourseCode__c+'-'+ass.TermCode__c))
        	{
            	ids.remove(ass.StudentAcademicCourse__c);
        	}
        }
        
        pidms.clear();
        coursecodes.clear();
        // re-query a list of StudentCourseRegistration__c to work with, avoid the risk of modifing trigger.new or trigger.old and missing fields
        List<StudentAcademicCourse__c> workList=[select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,
                                                    StudentContact__r.pidm__c,  Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c, 
                                                     RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c, 
                                                      MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c, 
                                                       CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,
                                                       (Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, 
                                                       FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c 
                                                        From StudentAcademicCourseRequirements__r)
                                                    from StudentAcademicCourse__c 
                                                    where id IN :ids and (status__c = 'Registered' or status__c = 'Planned')];
        
        
        for(integer i=0;i<workList.size();i++)
        {
            StudentAcademicCourse__c aca=workList[i];  
            if(aca.startdate__c > date.today().addDays(3) || aca.Term__c <= Datetime.NOW().addMonths(-6).format('yyyyMM')) 
            {
                System.debug('##- Ignore Courses not registered in current term : '+workList[i]);
                workList.remove(i); 
                i--;
            }else
            {
                pidms.add(aca.StudentContact__r.pidm__c); //all students pidms who need to take care of
                coursecodes.add(aca.CourseCode__c); //all course codes need to take care of
            }
        }   
        
      
        System.debug('3: size of worklist:'+ workList.size()); 
        // now the worklist should contains courses which are ready to be assigned with mentors
        
        if(workList.size()==0)
        {
            return;
        }
        
//PART 2 LOAD MENTOR: for each course, find out the best mentor for it, store it in map courseCode->list<Mentor__c>
        // create course-mentor map of: coursecode => List <mentors> who can potentially handle this course
        Map<String, set<String>> courseMentorMap=new Map<String, set<String>>();
        for(String coursecode:coursecodes){
            courseMentorMap.put(coursecode,new set<String>());
        }
        // create mentor map pidm->mentor ( all valid course mentors,  becuase they are not too many compare with other data sets)
        Map<String, Mentor__c> mentorMap=new Map<String, Mentor__c> ();
        List<Mentor__c> allValidMentors=[SELECT Id, Name, AssignedCollege__c, MentorRole__c, PIDM__c, ProgramCodes__c, MaxStudents__c, CurrentStudents__c, AvailableSpots__c , Available__c ,User__c FROM Mentor__c where Available__c=true  /*and MentorRole__c IN( 'Course Mentor', 'Student Mentor / Course Mentor')*/];
        for(Mentor__c m:allValidMentors)
        {
            mentorMap.put(m.PIDM__c, m);
        }
        
        System.debug('4  mentor map:'+ mentorMap.size()); 
        //build course to mentor map 
        //create the association of 'AAC1'=> ['Adam smith', 'Ron paul', 'Abraham Lincoln']
        for(MentorCourseAssignment__c mca:[select Id, CourseNumber__c, Mentor__c, MentorPidm__c, WGUCourse__c FROM MentorCourseAssignment__c where ( ActiveChk__c = '1' or ActiveChk__c = 'True') and  CourseNumber__c in :Coursecodes])
        {
            Set<String> mentors= courseMentorMap.get(mca.CourseNumber__c); 
            if(mentorMap.get(mca.MentorPidm__c)!=null)  //* strange case: a mentor setted to a course in mentorCourseAssignment__c but not found in valid mentor__c 
            {
                mentors.add(mca.MentorPidm__c);
            }
            courseMentorMap.put(mca.CourseNumber__c, mentors);
        }
         
        System.debug('5 courseMentorMap'+ courseMentorMap.size()); 
 //PART 3: CREATE A LIST OF ASSIGNMENTs
        List<CourseMentorStudentAssignment__c> insertAss=new List<CourseMentorStudentAssignment__c>();
        Set<String> updateMentors=new Set<String>(); 
        //3.1 iterate through courses
        for(StudentAcademicCourse__c sac:workList)
        {
            // all valid mmentors who can handle this course
            Set<String> candidates= courseMentorMap.get(sac.CourseCode__c);
            if(candidates==null || candidates.size()==0)
            {
                //no mentors can handle this course code ,  let the student cry.  
                // TODO: might want to email mentor manager about this?
                System.debug(Logginglevel.INFO ,'##- Cannot find proper mentor for course: '+sac);
                
            }else
            {
                //(un)fortunately , dear student you got a mentor!
                Mentor__c mentor= mentorMap.get( bestMentor(candidates,mentorMap)); 
                 
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c();
                ass.Mentor__c=mentor.id;
                ass.MentorPidm__c=mentor.pidm__c;
                ass.Student__c=sac.StudentContact__c;
                ass.PIDM__c=sac.StudentContact__r.pidm__c;
                ass.CourseCode__c=sac.CourseCode__c;
                ass.ReasonOfAssignment__c= 'Standard Daily';
                ass.StudentAcademicCourse__c = sac.id;
                ass.User__c=mentor.user__c;
                ass.IsActive__c=true;
                ass.AssignmentStartDate__c=date.today();
                ass.TermCode__c = sac.Term__c;
                mentor.CurrentStudents__c++;    //here we allowed CurrentStudent__c > max Student in same case. 
                                                 //mentor loads can be solved later on , but students should not be left alone.
                mentorMap.put(mentor.pidm__c, mentor); 
                System.debug(Logginglevel.INFO,'##+ Course Mentor Assignment Created from record of student course registration'+sac);
                insertAss.add(ass);
                updateMentors.add(mentor.pidm__c); //update mentors is a Set of mentor pidm, not a set of <mentor__c> because set can hold 2 mentors with same id
                 
                //backword
            }
        }
        
 //PART 4: commit creation
        insert insertAss;
        
        
        
        //Post Process: update backword association from StudentAcademicCourse record back to case load
        Map<id,id> academicToCaseLoadMap = new Map<id,id>();
        for(CourseMentorStudentAssignment__c ass:insertAss)
        {
            academicToCaseLoadMap.put(ass.StudentAcademicCourse__c, ass.id);
        }
        for(StudentAcademicCourse__c sac:workList)
        {
            sac.CourseMentorStudentAssignment__c = academicToCaseLoadMap.get(sac.id);
        }
        update workList;
        
        
        System.debug(Logginglevel.INFO,'!!! Create '+ insertAss.size()  + 'Mentor course student assignments records');
         
        List<Mentor__c> finalMentors=new List<Mentor__c>();
        for(String pidm:updateMentors)
        {
            finalMentors.add(mentorMap.get(pidm));
        }
        update finalMentors;
        System.debug(Logginglevel.INFO,'!!! Update ' +finalMentors.size() + 'mentor__c records');       
    }
     
     
    /** 
        (earlier version of create assignment on daily basis, might be removed)
     Reason of Assignment #1:
            A course mentor should be assigned to a student at the date he/she planned to start a new course. 
         Planned start: 
         1. given course code, and start date. 
         2. search students at that date will take that course
         3. for each student , search mentors and chain them up.
         4. match them
          
    */
    public static boolean createAssignmentsFromPlannedStartDate(String courseCode, Date startDate)
    {
        List<StudentAcademicCourse__c> sacs=[select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c, StudentContact__r.StudentRiskScore__c,  Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,(Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c  From StudentAcademicCourseRequirements__r) 
        from StudentAcademicCourse__c 
        where StartDate__c = :startDate and CourseCode__c =  :courseCode];
        boolean result=true;
      //  System.debug(' registration list '+ studentcourseregistrations);
        //for each student course registration record with given course code and given date, assign an apropriate mentor to him/her
        for(StudentAcademicCourse__c sac:sacs)
        {   //get a list of   mentors for this course code (e.g. AAA1) from mentor course assignment 
            List<Mentor__c> mentors = getMentorsByCourseCode(courseCode);
            if(mentors==null||mentors.size()==0)    {    continue;     }
            else{
                Contact student=sac.StudentContact__r;
            //    System.debug(' each student '+ student);
                result=result&createAssignment(mentors[0], sac ,  'Standard Daily');
            }
        }
          
        return result;
   }
   /**  relate to engagement check box in catarina's page 
   *   requirement confirmed with Mark O. at 10-21: ---ignore the action after course start date -3 .
   *    Reason of Assignment #2: Engagement click
                Student can requires to start a course for certain reason. When this request approved----checked at the student engagement page------a mentor should be assigned to 
                him/her for the course.
           1. triggered by click the check box of Student Engagement VF page.
           2. if check=true ,                    , no assignment yet---> create an assignment
           3. if check=false, before course start, have assignment--> delete the assignment.
           
           Edit 11/7:  check event will create assignment regardless whether startdate is earlier than today
           
   */
   webservice static boolean createAssignmentFromEngagement(Id studentid, String coursecode,boolean check)
   {    System.debug('######Engagement click#####'+ studentid + coursecode + check);
        //check to see what course we are piloting right now.
        List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10];  
        if(courselist.size()!=1)
        { 
            system.debug('Dont create any CM-student assignment');
            return false;
        }
        else if(courselist.size()==1&& (courselist[0].CourseLong__c == null || courselist[0].CourseLong__c.length()==0))
        {  
            system.debug('Dont create any CM-student assignment');
            return false;
        }
        if(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all'))
        {   //create assignment for all 
             
        }else  if(courselist.size()==1&&courselist[0].CourseLong__c.length()>0 && !courselist[0].CourseLong__c.toLowerCase().contains(coursecode.toLowerCase()) )
        {    
            //if given coursecode NOT in CourseList__c, quit this call.
            return false;
        }
        
        //re-query student , becaue we cannot pass contact in this method from web page.
        Contact student = [select Id, FirstName, LastName, Pidm__c, status__c from contact where id = :studentid];
        List<CourseMentorStudentAssignment__c> asss=[select id, student__c, CourseCode__c, mentor__c, Mentor__r.CurrentStudents__c, IsActive__c ,startdate__c, TermCode__c, enddate__c
                                                from CourseMentorStudentAssignment__c  
                                                where student__c=:student.id and CourseCode__c = :coursecode and IsActive__c=true];
        List<StudentAcademicCourse__c> sacs=[select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,  Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,(Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c  From StudentAcademicCourseRequirements__r) 
                                             from StudentAcademicCourse__c 
                                               where StudentContact__c = :student.id and CourseCode__c=:coursecode];
    //create a assignment if checked and not assigned yet and before its start date.            
    //  system.debug(asss); 
    //    system.debug(scrs);   
    //  if engagement clicked and no assignment created yet 
    //                     and the studentCourseRegistration do exist for this student.     
    //                     and before the daily scheduler start work.   
       if(check==true && asss.isEmpty() && !sacs.isEmpty())//Edit: 11/7 ----discard startdate "&& scrs[0].startdate__c > Date.today().addDays(3) )"
       {
           //create an assignment for this engagement
           List<Mentor__c> mentors = getMentorsByCourseCode(coursecode);   
           if(mentors!=null && mentors.size()>0)
           {
                createAssignment(mentors[0],sacs[0],'Engagement On');
                return true;
           }
           return false;
       }else if(check ==false && !asss.isEmpty() && !sacs.isEmpty()&& (sacs[0].startdate__c > Date.today().addDays(3)|| sacs[0].startdate__c ==null))
       {
         // system.assert([select id, student__c, CourseCode__c, mentor__c, Mentor__r.CurrentStudents__c, IsActive__c from CourseMentorStudentAssignment__c  where student__c=:student.id and CourseCode__c = :coursecode and IsActive__c=true].size()==1);
         return removeAssignment(asss[0],' Engagement Off');
       }
       return false;
   }
     /** 
        (Not in use. might be removed)
         many vs. one assignment:
             Given a list of mentor, and one student with his/her course code and the date this course should start.
             Assign the mentor who have more free spots to a this student.
     */
   /*  public static boolean createAssignment(List<Mentor__c> mentors, Contact student, String CourseCode,Date startDate,String type)
     {
         
         if(mentors!=null && mentors.size()>0 && student!=null && CourseCode!=null && CourseCode.length()!=0 && mentors.size()!=0)
         {
             integer max=0;
             //pick up the mentor who has more 'free spot' than others 
             for(integer i=0;i<mentors.size();i++)
             {
                 if(  mentors[i].Available__c==true && (mentors[max].MaxStudents__c-mentors[max].CurrentStudents__c) < (mentors[i].MaxStudents__c-mentors[i].CurrentStudents__c) )
                 {
                     max=i;
                 }
             }
             //assign it 
             if(mentors[max].MaxStudents__c > mentors[max].CurrentStudents__c )
             {
                 createAssignment(mentors[max],student,CourseCode,startDate,type);
                 return true;
             }
         }
         return false;
     }
     */
     /**
        (Not in use, hit governer limit real easy. might be removed)
         many to many assignment:
         Given a list of mentor,and a list of students , associate them to each other.
     */
  /*   public static boolean createAssignments (List<Mentor__c> mentors, List<Contact> students, String CourseCodes,Date startDate ,String type)
     {
          for(integer i=0;i<students.size();i++)
          {
              createAssignment(mentors, students[i],CourseCodes ,startDate, type);
          }
          return true;
     }*/
     
     
    /** 
         Basic Operation: deactive 1 assignment
         VF page call from : /apex/CourseMentorStudentAssignment?id= xxxx
    */
    webservice static boolean removeAssignment(CourseMentorStudentAssignment__c ass, String type)
    { 
        if(ass!=null)
        {   //re-query object with fields in case the pass-in object don't have required fields.
            ass=[select id, mentor__c, Mentor__r.CurrentStudents__c, mentor__r.name, student__c, student__r.Name, CourseCode__c, IsActive__c ,TermCode__c, ReasonOfDeassignment__c from CourseMentorStudentAssignment__c  where id=:ass.id and IsActive__c=true ][0];
            if(ass.Mentor__c != null && ass.Mentor__r.CurrentStudents__c>0)
            {
                ass.Mentor__r.CurrentStudents__c--;
                update ass.Mentor__r;
            }
            System.debug(Logginglevel.INFO,'Course Mentor Student Assignment deleted [  id: ' +ass.id +' mentor '+ ass.Mentor__r.name+':'+ass.mentor__c +' student '+ ass.Student__r.Name+ ':' + ass.student__c +' course:'+ass.CourseCode__c +']');
           
           //NO Longer delete old assignment, we keep it as IsActive__c=false 
            ass.IsActive__c=false;
            ass.AssignmentEndDate__c=date.today();
            ass.ReasonOfDeassignment__c=type;
            update ass;
            return true;
        }
        return false;
        
    }
    //helper function:  completely delete record, not de-assign!
    //   wipe off records 
    webservice static void deleteAssignments(List<CourseMentorStudentAssignment__c> asss)
    {   List<CourseMentorStudentAssignment__c> assList  = [select id , Mentor__c, Mentor__r.CurrentStudents__c from CourseMentorStudentAssignment__c where id in :asss];
        if(assList!=null)
        {  
            Map<Id, Mentor__c> mentorMap=new Map<Id, Mentor__c>();
        
            for(CourseMentorStudentAssignment__c ass:assList)
            {
                if(mentorMap.get(ass.Mentor__c)!=null)
                {
                    Mentor__c mentor=mentorMap.get(ass.Mentor__c); 
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor);
                }else
                { 
                    Mentor__c mentor=ass.Mentor__r;
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor); 
                } 
            } 
             
            update mentorMap.values();
            delete assList;
        //  calculateCurrentCaseLoadForMentors(); 
        } 
        
    }
    // fetch all case loads for each mentor
    // the Mentor__r.CurrentStudents__c field might goes wrong , so this method will recalculate the number of case load of
    // each mentor and re-assign the correct value to them.
    // * might be a good idea for each scheduler run 
    //2-28-14
    // we have 70k+ record for all courses, the aggregate result will exceed the 50k query row governer limit( even the count() will count raw data)
    // seperate the query by mentorpidm's end digit: 
    // e.g.: pidm end with 0,1,2 ....
    webservice static void calculateCurrentCaseLoadForMentors(String pidmTail)
    { 
    	AggregateResult[] groupedResults;
    	if(pidmTail==null)   //all mentors
    	{
    		groupedResults = [select Mentor__c,  count(Id)   from CourseMentorStudentAssignment__c where isActive__c = true   group by Mentor__c];
        }else				//only mentors with give pidm tail number
    	{
    		String format = '%'+pidmTail;
        	groupedResults = [select Mentor__c,  count(Id)   from CourseMentorStudentAssignment__c where isActive__c = true and mentor__r.pidm__c like :format group by Mentor__c];
        }
        Map<Id, Integer> mentorMap=new Map<Id, Integer>(); 
        for (AggregateResult ar : groupedResults)  {
            System.debug('Mentor Id' + ar.get('Mentor__c')); 
            System.debug('Count:' + ar.get('expr0'));
            mentorMap.put(String.valueOf(ar.get('Mentor__c')),  Integer.valueOf( ar.get('expr0')) );
        }
        System.debug(mentorMap);
        List<Mentor__c> mentors;
        if(pidmTail==null) //update all mentors  * set 0 for mentors who dont have case loads
        {
        	//edit 3/21: currently  we have 1200+ mentors in devfull
			//add limit 5000 to avoid Queries_With_No_Where_Or_Limit_Clause  
        	mentors = [select id, CurrentStudents__c from Mentor__c limit 5000]; 
        }else              //only selected mentors
        {
        	mentors = [select id, CurrentStudents__c from Mentor__c where id IN :mentorMap.keySet()];
        }
        for(Mentor__c mentor:mentors)
        {
            
            
            mentor.CurrentStudents__c = 0;
            if(mentorMap.containsKey(mentor.id))
            {
                mentor.CurrentStudents__c = mentorMap.get(mentor.id);
                System.debug('Mentor : ' + mentor); 
            }
             
        }
        update mentors;
         
        
    }
    
    //Upgrade: 
    // this is helper function convert for course versioning change. 
    // For each Case load:
    //   1. check its  studentcourseregistraion record of
    //   2.  and find corresponding  studentacademiccourse__c   record and link to it.
    //   3. create a 2-way backforce lookup from the studnetAcadmeicCourse__c back to case load.
    public static void upgradeAssignments(List<CourseMentorStudentAssignment__c> asss)
    {
        if(asss==null||asss.size()==0)
        {
            return;
        }
        
        system.debug('Begin upgrade:'+asss);
        Set<Id> ids=new Set<Id>();
        for(CourseMentorStudentAssignment__c ass:asss)
        {
                ids.add(ass.id);
        }
        List<CourseMentorStudentAssignment__c> workList = [select id, mentor__c, Mentor__r.CurrentStudents__c, mentor__r.name, student__c, student__r.Name, pidm__c, CourseCode__c, IsActive__c ,TermCode__c, ReasonOfDeassignment__c ,
        StudentAcademicCourse__c,StudentAcademicCourse__r.term__c,StudentAcademicCourse__r.CourseCode__c,StudentCourseRegistration__c, StudentCourseRegistration__r.TermCode__c,StudentCourseRegistration__r.CourseCode__c
         from CourseMentorStudentAssignment__c where id IN :ids ];
        
        system.debug('UPGRADE size:'+workList.size());
  // PART 1: remove registrations which already have assignments , and store all student/coursecode/term into sets  
        Set<id> students=new Set<id>();
        Set<String> coursecodes=new Set<String>();     
        Map<String, CourseMentorStudentAssignment__c> studentCourseTermMap =  new Map<String, CourseMentorStudentAssignment__c>();
        for(Integer i=0;i<workList.size();i++)
        {
            CourseMentorStudentAssignment__c ass = workList[i];
            
           /* if(ass.StudentAcademicCourse__c != null  )
            {
                workList.remove(i);
                i--;
                continue;
            }else 
            {*/
                String coursecode = ass.CourseCode__c;
                String termcode = ass.TermCode__c;
                Id studentid = ass.student__c;
                if(ass.StudentCourseRegistration__c !=null && ass.StudentCourseRegistration__r.CourseCode__c !=null)
                {
                    coursecode = ass.StudentCourseRegistration__r.CourseCode__c ;
                } 
                if(ass.StudentCourseRegistration__c !=null && ass.StudentCourseRegistration__r.TermCode__c !=null)
                {
                    termcode = ass.StudentCourseRegistration__r.TermCode__c ;
                }
                //
                if(studentid!=null&&coursecode!=null&&termcode!=null)
                {
                    students.add(studentid); 
                    coursecodes.add(coursecode);     
                    studentCourseTermMap.put(studentid+coursecode+ termcode, ass);
                }
           // }
             
        }
        // re-query a list of StudentCourseRegistration__c to work with, avoid the risk of modifing trigger.new or trigger.old and missing fields
        List<StudentAcademicCourse__c> sacs=[select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,
                                                    StudentContact__r.pidm__c,  Status__c,   Name,   Id,   
                                                       CourseCode__c,   CourseMentorStudentAssignment__c
                                                    from StudentAcademicCourse__c 
                                                    where StudentContact__c in :students and coursecode__c in :coursecodes];
        // use studentid+coursecode+ termcode as unique id for matching.
        for(integer i=0;i<sacs.size();i++)
        {
            StudentAcademicCourse__c sac=sacs[i];  
            CourseMentorStudentAssignment__c ass = studentCourseTermMap.get(sac.studentContact__c+sac.CourseCode__c+sac.term__c);
            if(ass!=null) 
        	{
                System.debug('##- find a match for  : '+sac.studentContact__c +' course :'+sac.CourseCode__c+ 'at: '+sac.term__c);
                if(sac.CourseMentorStudentAssignment__c==null)
            	{
                    sac.CourseMentorStudentAssignment__c = ass.id;
            	}
                if(ass.StudentAcademicCourse__c==null)
                {
                    ass.StudentAcademicCourse__c = sac.id;
        		}   
        		//In case the studentCourseVersion__c haven't completed yet, but the Academic records already flagged as 'Passed'
        		// then we de-assign the Case Load at same time
        		//* ignore the mentor count right here, let the daily scheduler fix it.
        		if(sac.Status__c =='Passed' && ass.IsActive__c == true)
        		{ 
        			ass.IsActive__c=false;
	                ass.AssignmentEndDate__c=Date.today();
	                ass.ReasonOfDeassignment__c='Pass';
        		}
            }
        }
        
        update sacs;
        update studentCourseTermMap.values(); 
        system.debug('End upgrade:'+sacs);
    }
         
     /** 
     ================== student 'complete' course before end of date=======
         List Operation: delete multiple assignments
         
            "When ever a student finished/passed his/her courses, the coursem mentor should be released form him/her".
            
            Given a list of student course registrations currently 'PASSED', remove corresponding assignments.
            
         Fired by  StudentCourseVersionNameTrigger -> StudentCourseVersionUtility.
         This method does not exceed any govener limit, because it only have 2 queries and 2 DML operation, 
            but,
         together with other triggers it might exceed 100 queries and 150 DML operation limits in future, especially the mentor's update trigger.
    
    Edit 11/5/2013 :  studentCourseRegistration removed prior to this method call, so we change to StudentCourseVersion ,
                and the trigger of StudentCourseVersion will call this method.
     Edit 1-10-14 Academic
     
    
    */
    public static void removeAssignmentsForPassedCourses(List<StudentAcademicCourse__c> courses, String type)
    { 
        if(courses.size()==0)
        {
            return;
        }
   // PART 0: re-qurey  all student academic course with necessary fields( in case if the pass-in objects dont contains them)
        List<Id> ids=new List<Id>();
        for(StudentAcademicCourse__c sac:courses)
        {
            ids.add(sac.id);
        }
        Set<String> pidmCoursePair =new Set<String>(); 
        Set<String> pidms =new Set<String>(); 
        Set<String> coursecodes =new Set<String>(); 
        Set<Id> students = new Set<id>();
        
        List<StudentAcademicCourse__c> workList=[select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,   Status__c,  StartDate__c,    Name,    Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c
                                             from StudentAcademicCourse__c  where id IN :ids];
         
         
        for(StudentAcademicCourse__c sac:workList)
        {
            if(sac.Status__c == 'Passed')
            {
                pidmCoursePair.add(sac.StudentContact__r.pidm__c+sac.CourseCode__c);  
                pidms.add(sac.StudentContact__r.pidm__c);
                students.add(sac.StudentContact__c);
                coursecodes.add(sac.CourseCode__c);      
            }   
        }
   // PART 1: find assignments correspind to courses passed in  
        //find course mentor student assignments 
        // a list of assignment but contains more records 
        //  e.g.:       assList  :  pidmA -> CourseA , pidmB->CourseB  ,pidmA -> CourseB , pidmB->CourseA
        List<CourseMentorStudentAssignment__c> assList=[select id, mentor__c, Mentor__r.CurrentStudents__c, mentor__r.name, student__c,
                                                         pidm__c, student__r.Name, CourseCode__c ,IsActive__c,TermCode__c, ReasonOfDeassignment__c, StudentAcademicCourse__c 
                                                         from CourseMentorStudentAssignment__c  
                                                         where ( CourseCode__c IN :coursecodes and student__c in :students and IsActive__c =true)or (StudentAcademicCourse__c in :ids) ];
        Map<Id, Integer> mentors=new Map<Id, Integer>();//the map of mentors to be updated 
   //PART 2: acturally remove assignment     
        for(integer i=0;i<assList.size();i++)
        {   
            CourseMentorStudentAssignment__c ass=assList[i];
            if( !pidmCoursePair.contains(ass.pidm__c+ass.CourseCode__c)) //'innocent' assignments
            {   
                assList.remove(i);                 // remove  :pidmA -> CourseB , pidmB->CourseA 
                i--;
                
            }
            else                                                       //assignments should be removed*/
            {   //If 1 mentor have multiple n assignment removed, the n should be subtract after ward.
                if(ass.Mentor__c != null  )
                { 
                    if(mentors.get(ass.mentor__r.id)==null)
                    {
                         mentors.put(ass.mentor__r.id, 1);
                    }else
                    { 
                        mentors.put(ass.mentor__r.id, mentors.get(ass.mentor__r.id)+1);
                    } 
                } 
                ass.IsActive__c=false;
                ass.AssignmentEndDate__c=Date.today();
                ass.ReasonOfDeassignment__c=type;
            }
        }
        List<Mentor__c> changeMentors = [select id ,CurrentStudents__c from mentor__c where id in:mentors.keySet()];
        for(Mentor__c m:changeMentors)
        {
            m.currentStudents__c -= mentors.get(m.id);
        }
        
     //Part 3: operation on list (rather than each one record)   
        update assList;
        update changeMentors;
        return;
        
    }
    
    /**
    
        ===================DAILY DELETION=================
        Remove assignment of following symptom:
            PASS DUE
            StudentCourseRegistration__c == null
            Mentor==null || unavailable
        
        
    */
    public static void removeAssignmentDaily(List<CourseMentorStudentAssignment__c> assList)
    {
        List<id> ids=new List<id>();
        for(CourseMentorStudentAssignment__c ass:assList)
        {
            ids.add(ass.id);
        }
        if(ids.size()==0)
        {
            return;
        }
        
        List<CourseMentorStudentAssignment__c> workList=[select id, student__c, student__r.status__c,StudentCourseRegistration__c,StudentCourseRegistration__r.TermCode__c,StudentAcademicCourse__r.Term__c,StudentAcademicCourse__c,StudentAcademicCourse__r.Status__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,TermCode__c, enddate__c, 
        coursecode__c,  IsActive__c ,ReasonOfDeassignment__c from CourseMentorStudentAssignment__c where id IN :ids and IsActive__c=true ];
        
        List<CourseMentorStudentAssignment__c> deleteList=new List<CourseMentorStudentAssignment__c> (); 
        Map<Id, Mentor__c> mentorMap=new Map<Id, Mentor__c>();
        
        for(CourseMentorStudentAssignment__c ass:workList)
        {
              //==================BLOCK B===========================
            //  Droped students but still have active assignment -> kill them all
            if(ass.student__r.status__c =='DR'||ass.student__r.status__c =='DD'||ass.student__r.status__c =='WA'||ass.student__r.status__c =='WE'||ass.student__r.status__c =='WI')
            {
                ass.IsActive__c=false;
                ass.AssignmentEndDate__c=date.today();
                ass.ReasonOfDeassignment__c='Drop';
                deleteList.add(ass);
                 
                if(mentorMap.get(ass.Mentor__c)!=null)
                {
                    Mentor__c mentor=mentorMap.get(ass.Mentor__c); 
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor);
                }else
                {
                    Mentor__c mentor=ass.Mentor__r;
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor);
                }
                  
            }//=====================BLOCK A==========================
            //  'Ended' courses determined by the TermCode < this month -6 month
            //  * if TermCode__c is null it also works
            else if(ass.Termcode__c <= Datetime.NOW().addMonths(-6).format('yyyyMM')
            || (ass.StudentCourseRegistration__c!=null && ass.StudentCourseRegistration__r.TermCode__c <= Datetime.NOW().addMonths(-6).format('yyyyMM'))
            || (ass.StudentAcademicCourse__c!=null && ass.StudentAcademicCourse__r.Term__c <= Datetime.NOW().addMonths(-6).format('yyyyMM')))
            {
                ass.IsActive__c=false;
                ass.AssignmentEndDate__c=date.today();
                ass.ReasonOfDeassignment__c='Term End';
                deleteList.add(ass);
                 
                if(mentorMap.get(ass.Mentor__c)!=null)
                {
                    Mentor__c mentor=mentorMap.get(ass.Mentor__c); 
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor);
                }else
                { 
                    Mentor__c mentor=ass.Mentor__r;
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor);
                }
                  
            }
            //BLOCK C: what if student withdraw his/her course? 
            // what if studentCourseRegistration__c removed?
            //2/25/14 ignore this case temporarily.
            else if(ass.StudentCourseRegistration__c==null && ass.StudentCourseVersion__c!=null && (ass.StudentCourseVersion__r.Status__c == 'Planned'||ass.StudentCourseVersion__r.Status__c == 'Failed'))
            {
              /*  ass.IsActive__c=false;
                ass.AssignmentEndDate__c=date.today();
                ass.ReasonOfDeassignment__c='Withdraw or Failed';
                deleteList.add(ass);
                
                if(mentorMap.get(ass.Mentor__c)!=null)
                {
                    Mentor__c mentor=mentorMap.get(ass.Mentor__c); 
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor);
                }else
                { 
                    Mentor__c mentor=ass.Mentor__r;
                    mentor.CurrentStudents__c = (mentor.CurrentStudents__c > 0 ? mentor.CurrentStudents__c-1:0);
                    mentorMap.put(mentor.id,mentor); 
                }*/ 
            }
         
        } 
        update mentorMap.values();
        update deleteList;
        
    }
    
    
  
    /**
        Basic Operation
          re-assign to another mentor
     */
     public static boolean reassignMentor(CourseMentorStudentAssignment__c ass, Mentor__c mentor)
     {
         if(ass==null|| mentor==null||ass.Mentor__c==mentor.id)
         {
             return false;
         }
      /*   system.assert(ass.id!=null);
         system.assert([select id, StudentCourseRegistration__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, 
        coursecode__c, student__c ,ReasonOfAssignment__c, AssignmentStartDate__c, AssignmentEndDate__c, IsActive__c from CourseMentorStudentAssignment__c where id = :ass.id ].size()>0);
       
         system.assert([select id, StudentCourseRegistration__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, 
        coursecode__c, student__c ,ReasonOfAssignment__c, AssignmentStartDate__c, AssignmentEndDate__c, IsActive__c from CourseMentorStudentAssignment__c where id = :ass.id and IsActive__c=true ].size()>0);
         system.assert(ass.IsActive__c==true);*/
         
         ass=[select id, StudentAcademicCourse__c,StudentAcademicCourse__r.Status__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, 
        coursecode__c, student__c ,ReasonOfAssignment__c, ReasonOfDeassignment__c,AssignmentStartDate__c, AssignmentEndDate__c, TermCode__c, IsActive__c from CourseMentorStudentAssignment__c where id = :ass.id and IsActive__c=true][0];
       
         mentor=[select id, pidm__c ,MaxStudents__c ,MentorRole__c ,CurrentStudents__c, Available__c ,User__c from Mentor__c where id=:mentor.id].get(0);
         if(mentor.Available__c/*mentor.CurrentStudents__c<mentor.MaxStudents__c &&(mentor.MentorRole__c == 'Course Mentor'||mentor.MentorRole__c == 'Student Mentor / Course Mentor') */)
         {
            
            //old assignment
            ass.IsActive__c=false;
            ass.AssignmentEndDate__c=date.today();
            ass.ReasonOfDeassignment__c='Manual Un-Assignment';
             if(ass.Mentor__c!=null){
                 //update the old mentor
                 ass.Mentor__r.CurrentStudents__c--;
                 update ass.Mentor__r;
             }
             update ass;
             //new assignment value
             CourseMentorStudentAssignment__c newone=new CourseMentorStudentAssignment__c();
             newone.CourseCode__c=ass.CourseCode__c;
             newone.ReasonOfAssignment__c='Manual Assignment';
             newone.StudentAcademicCourse__c=ass.StudentAcademicCourse__c;
             newone.StudentCourseRegistration__c=ass.StudentCourseRegistration__c;
             newone.TermCode__c = ass.TermCode__c;
             
             newone.pidm__c=ass.pidm__c;
             newone.student__c=ass.student__c;  
             newone.isActive__c=true;
             newone.AssignmentStartDate__c=date.today();
             
             //changed field
             newone.Mentor__c=mentor.id;
             newone.MentorPidm__c=mentor.Pidm__c;
             newone.User__c=mentor.User__c;
             
             insert newone;
             System.debug(Logginglevel.INFO,'Course Mentor Re-assigned to student [  assignment: ' +ass.id +' mentor:'+mentor.id +']' );
             //update new mentor
             mentor.CurrentStudents__c++;
             update mentor; 
             
             //backward lookup field
             StudentAcademicCourse__c sac=[select id, CourseMentorStudentAssignment__c from StudentAcademicCourse__c where id = : ass.StudentAcademicCourse__c];
             sac.CourseMentorStudentAssignment__c = newone.id;
             update sac;
             return true;
         }
         return false;
     }
     
     /**
     Helper function: Needed by VF page and other method
         find a list of mentor by given cource code 
         1. SELECT Id, CourseNumber__c, Mentor__c, MentorPidm__c, WGUCourse__c FROM MentorCourseAssignment__c 
         2. SELECT Id, AssignedCollege__c, MentorRole__c, ProgramCodes__c FROM Mentor__c where  Pidm__c =  'xxxx' 
         * 11-12-13 comments out the mentorrole restriction. 
         Katarina's mentor to course tool don't restrict mentor role so we have mentor assignment without course mentor role.
         Assume mentor manager knows what they are doing.
     */
     webservice static List<Mentor__c> getMentorsByCourseCode(String coursecode)
     {
         List<MentorCourseAssignment__c> mentorcourses=[select Id, CourseNumber__c, Mentor__c, MentorPidm__c, WGUCourse__c FROM MentorCourseAssignment__c  where ( ActiveChk__c = '1' or ActiveChk__c = 'True') and CourseNumber__c = :coursecode];
         List<String> pidms= new List<String>();
         for(MentorCourseAssignment__c m:mentorcourses)
         {
             pidms.add(m.MentorPidm__c);
         }
           
         
         return [SELECT Id, Name, AssignedCollege__c, MentorRole__c, PIDM__c, ProgramCodes__c, MaxStudents__c, CurrentStudents__c, AvailableSpots__c , Available__c, User__c 
         FROM Mentor__c 
         where pidm__c in :pidms 
                // and MentorRole__c IN( 'Course Mentor', 'Student Mentor / Course Mentor')  
                 and Available__c = true 
         order by AvailableSpots__c desc nulls last];
         
     }
     
     
   
   /** 
        Fired by a button in mentor__c layout:
   *           if a mentor quit (e.g. vacation, sick), all his assignments should be removed and re-assigned to other mentors.
   */
    
   webservice static boolean reassignmentsWhenMentorLeave(String mentorpidm)
   {
        if(!isCaseLoadManager())
        {
            throw new CaseLoadException('Failed! This action is limited to Program Managers in Course Mentoring and Senior Managers.');
        }
        //disable this mentor who went out for vacation
        Mentor__c mentor  = [select id, Name, AssignedCollege__c, MentorRole__c, PIDM__c, ProgramCodes__c, MaxStudents__c, CurrentStudents__c, AvailableSpots__c , Available__c ,User__c
                            from Mentor__c where PIDM__c = :mentorpidm][0];
        System.debug(Logginglevel.INFO,'Course Mentor Leave, reassign all his/her tasks to other mentors.  [   mentor:'+mentor.id +']' );
        mentor.Available__c=false;
         
        boolean result=true;
        
        //find out all old assignments of this mentor
        List<CourseMentorStudentAssignment__c> oldasss=[select id, StudentAcademicCourse__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, 
        coursecode__c, student__c ,ReasonOfAssignment__c,ReasonOfDeassignment__c, AssignmentStartDate__c, AssignmentEndDate__c, TermCode__c, IsActive__c from CourseMentorStudentAssignment__c where  IsActive__c=true and MentorPidm__c=:mentorpidm];
         
        //assignment can be reassigned to new mentors
        List<CourseMentorStudentAssignment__c> newass=new List<CourseMentorStudentAssignment__c>();
        // assignment should be delete due to lack of mentors
        List<CourseMentorStudentAssignment__c> changedass=new List<CourseMentorStudentAssignment__c>();
        // new assigned mentors who should be updated
        Set<String> changedMentors=new Set<String>();
        List<Mentor__c> finalMentors=new List<Mentor__c>();
        
        //map shows assignments and their new mentors, if null means no mentor fit for this course
        Map<CourseMentorStudentAssignment__c,Mentor__c> assignmentMap=new Map<CourseMentorStudentAssignment__c,Mentor__c>(); 
        // all course codes of old assignments
        Set<String> coursecodes=new Set<String>(); 
        for(CourseMentorStudentAssignment__c ass:oldasss)
        {
            coursecodes.add(ass.CourseCode__c);
            assignmentMap.put(ass,null);    //dont know who new mentor is
        }
        //map of: coursecode => mentors who can potentially handle this course
        Map<String, set<String>> courseMentorMap=new Map<String, set<String>>();
        for(String coursecode:coursecodes){
            courseMentorMap.put(coursecode,new set<String>());
        }
        //mentor map pidm_>mentor ( all valid course mentors,  becuase they are not too many compare with other data sets)
        Map<String, Mentor__c> mentorMap=new Map<String, Mentor__c> ();
        for(Mentor__c m:[SELECT Id, Name, AssignedCollege__c, MentorRole__c, PIDM__c, ProgramCodes__c, MaxStudents__c, CurrentStudents__c, AvailableSpots__c , Available__c,User__c  FROM Mentor__c where Available__c=true and PIDM__c != :mentorpidm /*and MentorRole__c IN( 'Course Mentor', 'Student Mentor / Course Mentor')*/])
        {
            mentorMap.put(m.PIDM__c, m); 
        }
        
        //build course to mentor map 
        //create the association of 'AAC1'=> ['Adam smith', 'Ron paul', 'Abraham Lincoln']
        for(MentorCourseAssignment__c mca:[select Id, CourseNumber__c, Mentor__c, MentorPidm__c, WGUCourse__c FROM MentorCourseAssignment__c where ( ActiveChk__c = '1' or ActiveChk__c = 'True') and MentorPidm__c != :mentorpidm and CourseNumber__c in :Coursecodes])
        {
            Set<String> mentors= courseMentorMap.get(mca.CourseNumber__c); 
            if(mentorMap.get(mca.MentorPidm__c)!=null)  //* strange case: a mentor setted to a course in mentorCourseAssignment__c but not found in valid mentor__c 
            {
                mentors.add(mca.MentorPidm__c);
            }
            courseMentorMap.put(mca.CourseNumber__c, mentors);
        }
        
        //assign new mentors
        for(CourseMentorStudentAssignment__c ass:oldasss)
        {
            //old assignment deactivate
            ass.AssignmentEndDate__c=date.today();
            ass.IsActive__c=false;
            ass.ReasonOfDeassignment__c='Mass Un-Assignment';
            changedass.add(ass);
            Mentor.CurrentStudents__c--;
            
            Set<String> candidates= courseMentorMap.get(ass.CourseCode__c);
            if(candidates!=null && candidates.size()> 0)
            { 
                //(un)fortunately , dear student you got a new mentor!
                Mentor__c newmentor= mentorMap.get(bestMentor(candidates,mentorMap));
                 //new assignment value
                 CourseMentorStudentAssignment__c newone=new CourseMentorStudentAssignment__c();
                 newone.CourseCode__c=ass.CourseCode__c;
                 newone.ReasonOfAssignment__c='Standard Event';
                 newone.StudentAcademicCourse__c=ass.StudentAcademicCourse__c;
                 newone.StudentCourseRegistration__c=ass.StudentCourseRegistration__c;
                 newone.TermCode__c = ass.TermCode__c;
                 
                 newone.pidm__c=ass.pidm__c;
                 newone.student__c=ass.student__c;  
                 newone.isActive__c=true;
                 newone.AssignmentStartDate__c=date.today();
                 
                 newone.Mentor__c=newmentor.id;
                 newone.MentorPidm__c=newmentor.Pidm__c;
                 newone.User__c=newmentor.User__c;
                 newass.add(newone); 
                 //update new mentor
                 newmentor.CurrentStudents__c++; 
                 changedMentors.add(newmentor.pidm__c);
                 
            }
        }
         
        system.debug('&&&'+changedMentors);
        //apex can not update set, so it takes one more step convert set to list
        for(String pidm:changedMentors)
        {
            finalMentors.add (mentorMap.get(pidm));
        } 
         //final changes, uses only 3 dml operation
        insert newass;
        
         //Post Process: update backword association from StudentAcademicCourse record back to case load
        Map<id,id> academicToCaseLoadMap = new Map<id,id>();
        for(CourseMentorStudentAssignment__c ass:newass)
        {
            academicToCaseLoadMap.put(ass.StudentAcademicCourse__c, ass.id);
        }
        List<StudentAcademicCourse__c> workList = [select id, CourseMentorStudentAssignment__c from StudentAcademicCourse__c where id in :academicToCaseLoadMap.keyset()];
        for(StudentAcademicCourse__c sac:workList)
        {
            sac.CourseMentorStudentAssignment__c = academicToCaseLoadMap.get(sac.id);
        }
        update workList;
        
        
        update finalMentors;
        update changedass;
        update mentor;
            
     
        return result;
    
   
   }
   
   
   
   /** 
       
        Fired by MentorCourseAssignmentTrigger:
        Remove case loads if MentorCourseAssignment:
             1. Removed from salesforce
             2. Flag to inactive at its ActiveChk__c field
             
        * student will not be re-assigned immediately due to governer limit, 200 Mentors might hit 100000 DB update limit.
        * Schedulor will pickup those released students next day.
        
   */
    
   webservice static boolean removeIfMentorCourseAssignmentChange(List<MentorCourseAssignment__c> triggerList,boolean isDelete)
   {
        if(!isCaseLoadManager())
        {
            throw new CaseLoadException('Failed! This action is limited to Program Managers in Course Mentoring and Senior Managers.');
        }
        
        Set<String> mentorpidms =new Set<String>();
        Set<String> courseCodes = new Set<String>();
        Map<String, MentorCourseAssignment__c> pairMap = new Map<String, MentorCourseAssignment__c>();
        
        for(MentorCourseAssignment__c mca :triggerList)
        {
            //Remove case load if MentorCourseAssignment:
            // 1. Removed from salesforce
            // 2. Flag to inactive at its ActiveChk__c field
            if(mca.ActiveChk__c=='False'||mca.ActiveChk__c=='false'||mca.ActiveChk__c=='0'||isDelete)
            {
                mentorpidms.add(mca.mentorPidm__c);
                coursecodes.add(mca.courseNumber__c);
                pairMap.put(mca.mentorPidm__c+mca.courseNumber__c,mca);
            }
        }
        if(mentorpidms.size()==0||coursecodes.size()==0)
        {
            return false;
        }
        //find out all mentors
        List<Mentor__c> mentors  = [select id, Name, AssignedCollege__c, MentorRole__c, PIDM__c, ProgramCodes__c, MaxStudents__c, CurrentStudents__c, AvailableSpots__c , Available__c ,User__c
                            from Mentor__c where PIDM__c IN :mentorpidms];
        Map<String, Mentor__c> mentorMap = new Map<String, Mentor__c>();
        for(Mentor__c m:mentors)
        {
            mentorMap.put(m.pidm__c, m);
        }
        System.debug(Logginglevel.INFO,'Course Mentors: ' + mentors  );
        System.debug(Logginglevel.INFO,'Courses:        ' + courseCodes  );
        
         
        boolean result=true;
        
        //find out all old assignments of this mentor of the given course code
        List<CourseMentorStudentAssignment__c> oldasss=[select id, StudentAcademicCourse__c, mentor__c,mentor__r.CurrentStudents__c, mentor__r.pidm__c,user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, 
        coursecode__c, student__c ,ReasonOfAssignment__c,ReasonOfDeassignment__c, AssignmentStartDate__c, AssignmentEndDate__c, 
        TermCode__c, IsActive__c 
        from CourseMentorStudentAssignment__c 
        where  IsActive__c=true and MentorPidm__c IN :mentorpidms and CourseCode__c IN :courseCodes];
          
       
        
        //assign new mentors
        for(CourseMentorStudentAssignment__c ass:oldasss)
        {
            //old assignment deactivate
            ass.AssignmentEndDate__c=date.today();
            ass.IsActive__c=false;
            ass.ReasonOfDeassignment__c='Mentor No Longer handle this Course';
            Mentor__c mentor=mentorMap.get(ass.mentor__r.pidm__c);
            mentor.currentStudents__c--;
            mentorMap.put(mentor.pidm__c, mentor);
             
        }
        update oldasss;
        update mentorMap.values();
       // calculateCurrentCaseLoadForMentors();
            
     
        return result;
    
   
   }
   /**
        future call of mentor leave, might not needed anymore
   */
   @future  
   webservice static void asyncReassignmentsWhenMentorLeave(String mentorpidm)
   {
         reassignmentsWhenMentorLeave(mentorpidm);
   }
   
   
   /**
     helper function:
      given a list of mentor, find out the one who has more free spot than all others.
   */
   public static String bestMentor(Set<String> mentorPidms,Map<String,Mentor__c> mentorMap)
   {     system.debug('!Best Mentor!');
         List<Mentor__c> mentors=new List<Mentor__c>();
         for(String pidm:mentorPidms)
         {
            mentors.add(mentorMap.get(pidm));
         } 
         system.debug('all mentors'+mentors);
         if(mentors!=null && mentors.size()>0 )
         {
             integer max=0;
             //pick up the mentor who has more 'free spot' than others 
             for(integer i=0;i<mentors.size();i++)
             {
                //  system.debug(i+'----'+max);
                 if(  mentors[i].Available__c==true && (mentors[max].MaxStudents__c-mentors[max].CurrentStudents__c) < (mentors[i].MaxStudents__c-mentors[i].CurrentStudents__c) )
                 {
                     max=i;
                 }
             }
              
             return mentors[max].pidm__c;
         }
         return null;
    }
    
    /**
        see if this user have 'Records for PMs'
    */
    webservice static boolean isCaseLoadManager()
    {
        Id profileId=UserInfo.getProfileId();
        Profile p=[select name from Profile where id =:profileId];
        Id currentUserId = UserInfo.getUserId();
        List<PermissionSetAssignment> psas=[SELECT PermissionSetId,Assignee.Name, Assigneeid,PermissionSet.Label
                                    FROM PermissionSetAssignment 
                                    WHERE Assigneeid = :currentUserId and PermissionSet.Label = 'Mentor PMCM'   ];
         
        return (p.Name=='Developer'||p.Name=='System Administrator'||psas.size()==1);                          
    }
    public class CaseLoadException extends Exception {}  
}