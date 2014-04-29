/*
* Katarina Melki
* 8/1/2013
* 
* Controller for StudentsAtRisk page.
*/
global with sharing class StudentsAtRiskController
{
    public StudentsAtRiskController(ApexPages.StandardController controller)
    {

    }
    
    @RemoteAction
    global static String getAtRiskRecords(String mentorUserId)
    {
        //Retrieve the Mentor Role
        //String MentorRole=[select MentorRole__c from Mentor__c where User__c=:mentorUserId limit 1].MentorRole__c;
        String MentorRole='Student Mentor';
        
        Set<Id> students=new Set<Id>();
        
        //Query for all student Id's assigned to the mentor based on the Mentor Role
        if (MentorRole=='Course Mentor')
        {
            //Course Mentor handling is currently disabled until Course Mentor student assignments are enabled or otherwise requested for inclusion
            /*List<CourseMentorStudentAssignment__c> tempList=[select Student__c, Student__r.Status__c, Student__r.CurrentTerm__c from CourseMentorStudentAssignment__c where Student__r.Status__c='AS' and Student__r.CurrentTermEnrolledCUs__c>0 and User__c=:mentorUserId];
            
            for (CourseMentorStudentAssignment__c tempItem :tempList)
            {
                if (Date.today()>=Date.newInstance(Integer.valueOf(tempItem.Student__r.CurrentTerm__c.substring(0, 4)), Integer.valueOf(tempItem.Student__r.CurrentTerm__c.substring(4)), 1))
                {
                    students.add(tempItem.Student__c);
                }
            }*/
        }
        else
        {
            List<Contact> tempList=[select Id, CurrentTerm__c, Status__c from Contact where Status__c='AS' and CurrentTermEnrolledCUs__c>0 and Mentor__c=:mentorUserId];
            
            for (Contact tempItem :tempList)
            {
                if (Date.today()>=Date.newInstance(Integer.valueOf(tempItem.CurrentTerm__c.substring(0, 4)), Integer.valueOf(tempItem.CurrentTerm__c.substring(4)), 1))
                {
                    students.add(tempItem.Id);
                }
            }
        }
        
        //Call function to create/update At Risk records
        processGenerateAtRisk(students);
        
        //Query and return all At Risk records for the mentor
        return JSON.serialize([select Id, Name, ActivityConcerns__c, LastRiskEventDate__c, LastRiskEventType__c, LastTotalRiskCount__c, LastTrendUpdated__c, ObjectiveFailCount__c, PastEndDateCount__c, PerformanceFailCount__c, RiskTrend__c, Student__c, StudentDisplayName__c, StudentName__c, StudentID__c, TotalRiskCount__c, TrendCalculatedSince__c from AtRiskStudent__c where Student__c in :students]);
    }
    
    //Function to call to create/update At Risk records
    public static void generateAtRisk(Set<Id> students)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled())
        {
            processGenerateAtRisk(students);
        }
        else
        {
            try
            {
                asyncGenerateAtRisk(students);
            }
            catch (Exception e)
            {
                processGenerateAtRisk(students);
            }
        }
    }
    
    @future
    private static void asyncGenerateAtRisk(Set<Id> students)
    {
        processGenerateAtRisk(students);
    }
    
    //Creates and updates At Risk records for students using the set of student Contact ID's passed in.
    private static void processGenerateAtRisk(Set<Id> students)
    {
        Map<Id, Integer> AtRiskIndex=new Map<Id, Integer>();
        Map<Id, Double> YesCount=new Map<Id, Double>();
        Map<Id, Double> NoCount=new Map<Id, Double>();
        Map<Id, Double> PartialCount=new Map<Id, Double>();
        Map<Id, String> StudentCurrentTerm=new Map<Id, String>();
        
        //Add all student ID's to the AtRiskIndex map
        for (Id student :students)
        {
            AtRiskIndex.put(student, null);
            YesCount.put(student, 0);
            NoCount.put(student, 0);
            PartialCount.put(student, 0);
        }
        
        //Query all the things!!!
        List<Contact> StudentContacts=[select Id, Name, FirstName, LastName, PIDM__c, StudentID__c, CurrentTerm__c from Contact where Id in :students];
        List<AtRiskStudent__c> ExistingAtRisk=[select Id, Name, ActivityConcerns__c, LastRiskEventDate__c, LastRiskEventType__c, LastTotalRiskCount__c, LastTrendUpdated__c, ObjectiveFailCount__c, PastEndDateCount__c, PerformanceFailCount__c, RiskTrend__c, Student__c, StudentDisplayName__c, StudentName__c, StudentID__c, TotalRiskCount__c, TrendCalculatedSince__c from AtRiskStudent__c where Student__c in :students];
        List<StudentCourseVersion__c> StudentCourses=[select Id, EnrollTermCode__c, Student__c, StudentCourseRegistration__r.enddate__c from StudentCourseVersion__c where StudentCompletionCourse__r.Complete__c=null and StudentCourseRegistration__r.enddate__c<LAST_N_DAYS:6 and Student__c in :students];
        List<StudentCompletionTask__c> CompletionTasks=[select Id, TermCode__c, Student__c, LastFailedAssessmentAttemptDate__c from StudentCompletionTask__c where NumberFailedAssessmentAttempts__c>=2 and RequirementComplete__c=false and Student__c in :students];
        List<TaskStreamTaskFailure__c> TaskStreamFailures=[select Id, Student__c, LastFailedAttempt__c, TaskStartDate__c from TaskStreamTaskFailure__c where NumberFailedAttempts__c>=2 and TaskCompletedDate__c=null and Student__c in :students];
        List<WGUStudentPerformanceSurvey__c> PerformanceSurveys=[select Id, Student__c, CreatedDate, GoalPerformanceSinceLastCall__c from WGUStudentPerformanceSurvey__c where CreatedDate=LAST_N_DAYS:30 and Student__c in :students];
        
        //Temp test scenario goes back 60 days for surveys
        //List<WGUStudentPerformanceSurvey__c> PerformanceSurveys=[select Id, Student__c, CreatedDate, GoalPerformanceSinceLastCall__c from WGUStudentPerformanceSurvey__c where CreatedDate=LAST_N_DAYS:60 and Student__c in :students];
        
        //Update the AtRiskIndex to include the index value in ExistingAtRisk for each student
        for (Integer i=0; i<ExistingAtRisk.size(); i++)
        {
            AtRiskIndex.put(ExistingAtRisk[i].Student__c, i);
            
            //Reset all risk counters
            ExistingAtRisk[i].ActivityConcerns__c=true;
            ExistingAtRisk[i].ObjectiveFailCount__c=0;
            ExistingAtRisk[i].PastEndDateCount__c=0;
            ExistingAtRisk[i].PerformanceFailCount__c=0;            
            
            ExistingAtRisk[i].TrendCalculatedSince__c=ExistingAtRisk[i].LastTrendUpdated__c.date()<Date.today()?ExistingAtRisk[i].LastTrendUpdated__c:ExistingAtRisk[i].TrendCalculatedSince__c;
            ExistingAtRisk[i].LastTotalRiskCount__c=ExistingAtRisk[i].LastTrendUpdated__c.date()<Date.today()?ExistingAtRisk[i].TotalRiskCount__c:ExistingAtRisk[i].LastTotalRiskCount__c;
            
            ExistingAtRisk[i].TotalRiskCount__c=0;
        }
        
        //Generate AtRisk records for students lacking them
        for (Contact StudentContact :StudentContacts)
        {
            if (AtRiskIndex.get(StudentContact.Id)==null)
            {
                ExistingAtRisk.add(new AtRiskStudent__c(Name=StudentContact.PIDM__c, ActivityConcerns__c=true, LastTotalRiskCount__c=0, TrendCalculatedSince__c=Date.today().addDays(-1), LastTrendUpdated__c=Date.today().addDays(-1), ObjectiveFailCount__c=0, PastEndDateCount__c=0, PerformanceFailCount__c=0, RiskTrend__c=0, Student__c=StudentContact.Id, StudentDisplayName__c=StudentContact.LastName+', '+StudentContact.FirstName, StudentName__c=StudentContact.FirstName+' '+StudentContact.LastName, StudentID__c=StudentContact.StudentID__c, TotalRiskCount__c=0));
                AtRiskIndex.put(StudentContact.Id, ExistingAtRisk.size()-1);
            }
            
            //Add Student Term Code to map
            StudentCurrentTerm.put(StudentContact.Id, StudentContact.CurrentTerm__c);
        }
        
        //Loop through all StudentCourseVersion results and update accordingly
        for (StudentCourseVersion__c StudentCourse :StudentCourses)
        {
            if (StudentCourse.EnrollTermCode__c==StudentCurrentTerm.get(StudentCourse.Student__c))
            {
                ExistingAtRisk[AtRiskIndex.get(StudentCourse.Student__c)].PastEndDateCount__c++;
                ExistingAtRisk[AtRiskIndex.get(StudentCourse.Student__c)]=checkLastRiskEvent(ExistingAtRisk[AtRiskIndex.get(StudentCourse.Student__c)], StudentCourse.StudentCourseRegistration__r.enddate__c, 'End Date > 7 Days');
            }
        }
        
        //Loop through all StudentCompletionTask results and update accordingly
        for (StudentCompletionTask__c CompletionTask :CompletionTasks)
        {
            if (CompletionTask.TermCode__c==StudentCurrentTerm.get(CompletionTask.Student__c))
            {
                ExistingAtRisk[AtRiskIndex.get(CompletionTask.Student__c)].ObjectiveFailCount__c++;
                ExistingAtRisk[AtRiskIndex.get(CompletionTask.Student__c)]=checkLastRiskEvent(ExistingAtRisk[AtRiskIndex.get(CompletionTask.Student__c)], CompletionTask.LastFailedAssessmentAttemptDate__c, 'Exam or Task Failure');
            }
        }
        
        //Loop through all TaskStreamFailure results and update accordingly
        for (TaskStreamTaskFailure__c TaskStreamFailure :TaskStreamFailures)
        {
            if (TaskStreamFailure.TaskStartDate__c>=date.newinstance(Integer.valueOf(StudentCurrentTerm.get(TaskStreamFailure.Student__c).substring(0, 4)), Integer.valueOf(StudentCurrentTerm.get(TaskStreamFailure.Student__c).substring(4)), 1))
            {
                ExistingAtRisk[AtRiskIndex.get(TaskStreamFailure.Student__c)].PerformanceFailCount__c++;
                ExistingAtRisk[AtRiskIndex.get(TaskStreamFailure.Student__c)]=checkLastRiskEvent(ExistingAtRisk[AtRiskIndex.get(TaskStreamFailure.Student__c)], TaskStreamFailure.LastFailedAttempt__c, 'Exam or Task Failure');
            }
        }
        
        //Loop through all PerformanceSurvey results and update accordingly
        for (WGUStudentPerformanceSurvey__c PerformanceSurvey :PerformanceSurveys)
        {
            //Update counts for Goal Performance for the student
            if (PerformanceSurvey.GoalPerformanceSinceLastCall__c=='Yes - 100%')
            {
                YesCount.put(PerformanceSurvey.Student__c, YesCount.get(PerformanceSurvey.Student__c)+1);
            }
            else if (PerformanceSurvey.GoalPerformanceSinceLastCall__c=='No - 0%')
            {
                NoCount.put(PerformanceSurvey.Student__c, NoCount.get(PerformanceSurvey.Student__c)+1);
            }
            else
            {
                PartialCount.put(PerformanceSurvey.Student__c, PartialCount.get(PerformanceSurvey.Student__c)+1);
            }
            
            //Check goal performance counters to determine how the Inactive field should be set.
            //NoCount percentage must be greater than or equal to 50% and YesCount percentage less than 50% of all total performance surveys in the past 30 days for a true value.
            if ((NoCount.get(PerformanceSurvey.Student__c)/(NoCount.get(PerformanceSurvey.Student__c)+PartialCount.get(PerformanceSurvey.Student__c)+YesCount.get(PerformanceSurvey.Student__c)))>=0.50 && (YesCount.get(PerformanceSurvey.Student__c)/(NoCount.get(PerformanceSurvey.Student__c)+PartialCount.get(PerformanceSurvey.Student__c)+YesCount.get(PerformanceSurvey.Student__c)))<0.50)
            {
                ExistingAtRisk[AtRiskIndex.get(PerformanceSurvey.Student__c)].ActivityConcerns__c=true;
                ExistingAtRisk[AtRiskIndex.get(PerformanceSurvey.Student__c)]=checkLastRiskEvent(ExistingAtRisk[AtRiskIndex.get(PerformanceSurvey.Student__c)], PerformanceSurvey.CreatedDate, 'Activity Concern');
            }
            else
            {
                ExistingAtRisk[AtRiskIndex.get(PerformanceSurvey.Student__c)].ActivityConcerns__c=false;
            }
        }
        
        //Loop through all At Risk records for final processing
        for (AtRiskStudent__c AtRisk :ExistingAtRisk)
        {
            //Set the At Risk events for any records that did not have any performance surveys in the past 30 days and do not have a more recent At Risk event.
            AtRisk=AtRisk.ActivityConcerns__c?checkLastRiskEvent(AtRisk, Date.today().addDays(-30), 'Activity Concern'):AtRisk;
            
            //Total all At Risk items
            AtRisk.TotalRiskCount__c=AtRisk.ActivityConcerns__c?1:0;
            AtRisk.TotalRiskCount__c=AtRisk.TotalRiskCount__c+AtRisk.PastEndDateCount__c+AtRisk.ObjectiveFailCount__c+AtRisk.PerformanceFailCount__c;
            
            //Check Trend
            AtRisk.RiskTrend__c=AtRisk.LastTrendUpdated__c.date()<Date.today()?AtRisk.TotalRiskCount__c-AtRisk.LastTotalRiskCount__c:AtRisk.RiskTrend__c;
            AtRisk.LastTrendUpdated__c=AtRisk.LastTrendUpdated__c.date()<Date.today()?Datetime.now():AtRisk.LastTrendUpdated__c;
        }
        
        Database.upsert(ExistingAtRisk, false);
    }
    
    //Helper function to handle Last Risk Events (used to make it easier to get greater code coverage by reducing If statements).
    private static AtRiskStudent__c checkLastRiskEvent(AtRiskStudent__c AtRiskRecord, DateTime NewEvent, String EventType)
    {
        if (AtRiskRecord.LastRiskEventDate__c<NewEvent || AtRiskRecord.LastRiskEventDate__c==null)
        {
            AtRiskRecord.LastRiskEventDate__c=NewEvent;
            AtRiskRecord.LastRiskEventType__c=EventType;
        }
        
        return AtRiskRecord;
    }
}