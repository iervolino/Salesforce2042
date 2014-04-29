/*
Author Katarina Melki 
Western Governer University
8/9/2013

Test class for StudentsAtRiskController class.
*/
@IsTest
private class TestStudentsAtRiskContoller
{
    //Function to create student test data
    static private Set<Id> setupTestStudents()
    {
        List<Contact> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');
        String testTerm=String.valueOf(Date.today().year());
        
        if (Date.today().month()<10)
        {
            testTerm=testTerm+'0'+String.valueOf(Date.today().month());
        }
        else
        {
            testTerm=testTerm+String.valueOf(Date.today().month());
        }
        
        contacts[0].CurrentTerm__c=testTerm;
        contacts[1].CurrentTerm__c=testTerm;
        contacts[0].CurrentTermEnrolledCUs__c=4;
        contacts[1].CurrentTermEnrolledCUs__c=4;
        update contacts;
        
        List<WGUStudentNote__c> Notes=new List<WGUStudentNote__c>();
        Notes.add(new WGUStudentNote__c(Student__c=contacts[0].Id));
        Notes.add(new WGUStudentNote__c(Student__c=contacts[1].Id));
        insert Notes;
        
        //Setup test data for student 1
        AtRiskStudent__c ExistingAtRisk=new AtRiskStudent__c(Name=contacts[0].PIDM__c, ActivityConcerns__c=true, LastTotalRiskCount__c=2, LastTrendUpdated__c=Date.today().addDays(-3), ObjectiveFailCount__c=1, PastEndDateCount__c=1, PerformanceFailCount__c=1, RiskTrend__c=0, Student__c=contacts[0].Id, StudentDisplayName__c=contacts[0].LastName+', '+contacts[0].FirstName, StudentName__c=contacts[0].FirstName+' '+contacts[0].LastName, StudentID__c='0001111', TotalRiskCount__c=4);
        List<WGUStudentPerformanceSurvey__c> PerformanceSurveys=new List<WGUStudentPerformanceSurvey__c>();
        PerformanceSurveys.add(new WGUStudentPerformanceSurvey__c(Student__c=contacts[0].Id, WGUStudentNote__c=[select Id from WGUStudentNote__c where Student__c=:contacts[0].Id Limit 1].Id, GoalPerformanceSinceLastCall__c='Yes - 100%'));
        PerformanceSurveys.add(new WGUStudentPerformanceSurvey__c(Student__c=contacts[0].Id, WGUStudentNote__c=[select Id from WGUStudentNote__c where Student__c=:contacts[0].Id Limit 1].Id, GoalPerformanceSinceLastCall__c='Partially Met'));
        PerformanceSurveys.add(new WGUStudentPerformanceSurvey__c(Student__c=contacts[0].Id, WGUStudentNote__c=[select Id from WGUStudentNote__c where Student__c=:contacts[0].Id Limit 1].Id, GoalPerformanceSinceLastCall__c='No - 0%'));
        PerformanceSurveys.add(new WGUStudentPerformanceSurvey__c(Student__c=contacts[0].Id, WGUStudentNote__c=[select Id from WGUStudentNote__c where Student__c=:contacts[0].Id Limit 1].Id, GoalPerformanceSinceLastCall__c='No - 0%'));
        PerformanceSurveys.add(new WGUStudentPerformanceSurvey__c(Student__c=contacts[0].Id, WGUStudentNote__c=[select Id from WGUStudentNote__c where Student__c=:contacts[0].Id Limit 1].Id, GoalPerformanceSinceLastCall__c='No - 0%'));
        
        //Setup test data for student 2
        PerformanceSurveys.add(new WGUStudentPerformanceSurvey__c(Student__c=contacts[1].Id, WGUStudentNote__c=[select Id from WGUStudentNote__c where Student__c=:contacts[1].Id Limit 1].Id, GoalPerformanceSinceLastCall__c='Yes - 100%'));
        StudentCourseRegistration__c tempReg=new StudentCourseRegistration__c(pidm__c=contacts[1].PIDM__c, enddate__c=Date.today().addDays(-10), Student__c=contacts[1].Id, Termcode__c='test123');
        insert tempReg;
        
        StudentCourseVersion__c StudentCourse=new StudentCourseVersion__c(Student__c=contacts[1].Id, StudentCourseRegistration__c=[select Id from StudentCourseRegistration__c where Termcode__c='test123' Limit 1].Id, EnrollTermCode__c=testTerm);
        StudentCompletionTask__c CompletionTask=new StudentCompletionTask__c(Student__c=contacts[1].Id, LastFailedAssessmentAttemptDate__c=Date.today(), NumberFailedAssessmentAttempts__c=4, RequirementComplete__c=false, TermCode__c=testTerm);
        TaskStreamAssessment__c tempTask=new TaskStreamAssessment__c(AssessmentCode__c='Test1', AssessmentIDKey__c=123456, OverallStatus__c='IP', pidm__c=contacts[1].PIDM__c, Student__c=contacts[1].Id);
        insert tempTask;
        
        TaskStreamTaskFailure__c TaskStreamFailure=new TaskStreamTaskFailure__c(AssessmentIDKey__c=123456, TaskFailureKey__c=123456, pidm__c=contacts[1].PIDM__c, Student__c=contacts[1].Id, LastFailedAttempt__c=Date.today(), NumberFailedAttempts__c=4, TaskTitle__c='Test stuff', TaskStreamAssessment__c=[select Id from TaskStreamAssessment__c where AssessmentIDKey__c=123456 and AssessmentCode__c='Test1'].Id, TaskStartDate__c=Date.today());
        
        //Insert test data for both students
        insert ExistingAtRisk;
        insert PerformanceSurveys;
        insert StudentCourse;
        insert CompletionTask;
        insert TaskStreamFailure;
        
        Set<Id> students=new Set<Id>();
        students.add(contacts[0].Id);
        students.add(contacts[1].Id);
        
        return students;
    }
    
    //Tests StudentsAtRiskController.generateAtRisk
	static testmethod void testAtRiskCreation()
    {
        String environment = TestStudentUser.getEnvironment();
        
        Set<Id> students=setupTestStudents();
        
        Test.startTest();
        	StudentsAtRiskController.generateAtRisk(students);
        Test.stopTest();
        
        System.assert([select id from AtRiskStudent__c where Student__c in :students].size()==2);
    }
    
    //StudentsAtRiskController.getAtRiskRecords
    static testmethod void testAtRiskRetrieval()
    {
        String environment = TestStudentUser.getEnvironment();
        
        //Setup mentor
        Profile prof = [SELECT id from profile where name = 'Lockdown'];
        Profile mentorProfile = [select ID from Profile where Name='Mentor'];
        UserRole mentorRole = [select ID from UserRole where Name='Mentor'];
        
        User testUser=new User(LastName='Mentor', FirstName='Standard', pidm__c='123123', Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', ProfileId=prof.ID, LanguageLocaleKey='en_US');
        insert testUser;
        
        Id MentorId=[select Id from User where pidm__c='123123' and Username='a@wgu.edu' Limit 1].Id;
        
        //Setup students
        Set<Id> students=setupTestStudents();
        
        List<Contact> studentContacts=[select Id from Contact where Id in :students];
        for (Contact studentContact :studentContacts)
        {
            studentContact.Mentor__c=MentorId;
        }
        update studentContacts;
        
        String AtRisk;
        
        Test.startTest();
        	AtRisk=StudentsAtRiskController.getAtRiskRecords(MentorId);
        Test.stopTest();
        
        //List<AtRiskStudent__c> AtRiskList=JSON.deserialize(AtRisk);
        
        system.assert(AtRisk!=null);
        
    }
}