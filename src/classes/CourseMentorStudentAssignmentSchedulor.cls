/*schedulor of CourseMentorStudentAssignmentUtility class.
WGU 
yemeng zhu

This is the schedulor of Course mentor case load project.
  it will create assignment daily and remove passed assignment daily.
  
Tester:
Because it invoke functions via batch, so the test class does not run it immediatetly and the test.start/stop doesn't work.
 we have to test functional method seperately.

TermRoll Change: use term code for removal.


Edit 1/9/14:  change Registration to Academic

*/
/* 


//scheduling script: following lines are the code can be used to schedule job: 


    CourseMentorStudentAssignmentSchedulor assignment= new CourseMentorStudentAssignmentSchedulor ();
    
    String seconds = '0'; //Execute at Zero Seconds
    String minutes = '30'; //Execute at every 30th minute of hour
    String hours = '*'; // Execute Every Hour
    String dayOfMonth = '*'; // Execute Every Day of the Month
    String month = '*'; //Execute only in November(11)
    String dayOfWeek = '?'; //Execute on all 7 days of the Week
    String year = '*'; //Execute only for year 2013
    
    //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
    String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek + ' ' + year;
     
    
    system.schedule('CourseMentor Batch Assignment', sch, assignment); 
 

*/
global class CourseMentorStudentAssignmentSchedulor implements schedulable
{
   global void execute(SchedulableContext ctx) 
   {
    
        String queryFields =  'Select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,   Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,(Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c  From StudentAcademicCourseRequirements__r) '
                            + ' from StudentAcademicCourse__c ';
        
   		//daily removal (on termroll)
   		//e.g.  for course of termcode 201302 will be de-assigned at 2013 8 1
   		Datetime dt = Datetime.NOW().addMonths(-6);
		String termCode=dt.format('yyyyMM');
		// 11/14/13 no longer catch StudentCourseRegistration__c = null, 
		//  Reg removeal sync with SF every 5 min, but the completion sync with SF every 1 hr.
		//    Even when student passed a course, Reg removed prior to completion, 
		//      and the scheduler will more likely to catch the removal earlier than complete.
		//  if TermCode__c is null the record also treat as 'Term End'
        //10-31-13 remove drop student
        //			find all existing active assignment whose status__c is 'DR' 
        //3-11-14 merge to 1 batch, then use 3 batch jobs to recalculate CaseLoads for all mentors.
        Id batchInstanceId1 = Database.executeBatch(
            new CourseMentorStudentAssignmentUtility(
              'TERMROLL',
              'select id, StudentCourseRegistration__c,StudentCourseRegistration__r.TermCode__c, StudentAcademicCourse__c,StudentAcademicCourse__r.Term__c,mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, coursecode__c, student__c, IsActive__c,Termcode__c'
              +' from CourseMentorStudentAssignment__c '
              +'where    ( (TermCode__c!=null and TermCode__c <= \''+termCode+'\') OR  (StudentCourseRegistration__c !=null and StudentCourseRegistration__r.TermCode__c <= \''+termCode+'\') OR (StudentAcademicCourse__c!=null  and StudentAcademicCourse__r.Term__c <= \''+termCode+'\')  or  student__r.status__c IN ( \'DR\',\'DD\',\'WA\',\'WE\',\'WI\')) and IsActive__c = true  ' 
		
        )); 
      /*  Id batchInstanceId3 = Database.executeBatch(
            new CourseMentorStudentAssignmentUtility(
              'TERMROLL',
              'select id, StudentCourseRegistration__c,StudentCourseRegistration__r.TermCode__c,StudentAcademicCourse__c,StudentAcademicCourse__r.Term__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, coursecode__c, student__c, IsActive__c,Termcode__c'
              +' from CourseMentorStudentAssignment__c '
              +'where   student__r.status__c IN ( \'DR\',\'DD\',\'WA\',\'WE\',\'WI\') and IsActive__c = true  ' 
               
        ));*/
        // TODO: registered but then withdrawed 
         
        //daily creation:
        // all courses turned on at Martch 2014.
        List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10]; 
		if(courselist.size()!=1 ||  (courselist.size()==1&&(courselist[0].CourseLong__c == null || courselist[0].CourseLong__c.length()==0))  )
		{
		    system.debug('Dont create any CM-student assignment');
		    return;
		} 
		else if(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all'))
        {   //create assignment for all courses which registered within -6 months but start soon
            Id batchInstanceId2 = Database.executeBatch(
            new CourseMentorStudentAssignmentUtility(
                 'DAILYCREATE',
                 queryFields
                 +' where  startdate__c <= NEXT_N_DAYS:3 and Term__c > \''+termCode+'\'' 
                 +' and studentContact__r.status__c = \'AS\' '
                 +' and (Status__c = \'Registered\'  or Status__c = \'Planned\' )'
                 +' and StudentContact__r.IsTestData__c = false '
               
             )); 
		}else  if(courselist.size()==1&&courselist[0].CourseLong__c.length()>0 )
        {   //create assignment for given courses which registered within -6 months but start soon
                Id batchInstanceId2 = Database.executeBatch(
                new CourseMentorStudentAssignmentUtility(
                     'DAILYCREATE',
                      queryFields
                     +' where  startdate__c <= NEXT_N_DAYS:3 and Term__c > \''+termCode+'\''
                     +' and CourseCode__c In (' + courselist[0].CourseLong__c + ') '
                     +' and studentContact__r.status__c = \'AS\' '
                     +' and (Status__c = \'Registered\'  or Status__c = \'Planned\' )' 
                 	 +' and StudentContact__r.IsTestData__c = false '
                       
                )); 
		}
         
         
       //calculate case load balance
       Id batchInstanceId5 = Database.executeBatch(new CourseMentorStudentAssignmentUtility('CALCULATE1234','select id from CourseMentorStudentAssignment__c limit 1'  )); 
       Id batchInstanceId6 = Database.executeBatch(new CourseMentorStudentAssignmentUtility('CALCULATE567','select id from CourseMentorStudentAssignment__c limit 1'  )); 
       Id batchInstanceId7 = Database.executeBatch(new CourseMentorStudentAssignmentUtility('CALCULATE890','select id from CourseMentorStudentAssignment__c limit 1'  )); 
            
   }
}