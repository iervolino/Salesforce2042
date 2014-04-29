@isTest
global class TestEvalOppController
{
    static testMethod void textEvalOppExt()
    {
        RecordType trDegRT = [SELECT Id FROM RecordType WHERE SObjectType = 'KeyValue__c' AND DeveloperName = 'TransferDegree' LIMIT 1];
        
        KeyValue__c noDegree = new KeyValue__c(RecordTypeId = trDegRT.Id, ExternalID__c = 'ND', Value__c = 'ND', NumericValue__c = 0);
        insert noDegree; 
            
        CAREProgram__c testCAREProgram = new CAREProgram__c(Name = 'TestCAREProgram124');
        insert testCAREProgram;
        
        WGUDegreeProgram__c testWGUDegreeProgram = new WGUDegreeProgram__c(Name = 'TestWGUDegP124', PAMSID__c = 124124124);
        insert testWGUDegreeProgram;

        CAREProgramMiddleEarth__c testCAREProgramMiddleEarth = new CAREProgramMiddleEarth__c(CareProgramCode__c = testCAREProgram.Id, BannerProgramCode__c = testWGUDegreeProgram.Id);
        insert testCAREProgramMiddleEarth;
        
        Opportunity testOpportunity = new Opportunity(Name = 'testEvalCourseTriggerOpp', CloseDate = Date.Today(), StageName = 'Applicant', MarketingProgram__c = testCAREProgramMiddleEarth.Id);
        insert testOpportunity;

        TransferEvaluation__c testTransferEvaluation = new TransferEvaluation__c(Name = 'testTransferEval124', Opportunity__c = testOpportunity.Id, EvaluationStatus__c = 'Pending');
        insert testTransferEvaluation;

        StudentTranscript__c testInstitution = new StudentTranscript__c(Opportunity__c = testOpportunity.Id);
        insert testInstitution;

        RecordType transDegreeRT = [SELECT Id FROM RecordType WHERE Name = 'Transfer Degree' AND SobjectType = 'KeyValue__c' LIMIT 1];
        
        KeyValue__c testBS = new KeyValue__c(RecordTypeId = transDegreeRT.Id, Name = 'testBS421', Value__c = '3', UsageNotes__c = 'Test421 Bachelor of Science');
        KeyValue__c testAS = new KeyValue__c(RecordTypeId = transDegreeRT.Id, Name = 'testAS421', Value__c = '2', UsageNotes__c = 'Test421 Associate of Science');
        insert testBS;
        insert testAS;       
        
        TransferAttendance__c testAttendance = new TransferAttendance__c(StudentTransferInstitution__c = testInstitution.Id, DegreeAwarded__c = testBS.Id, DegreeRelatesToWGUProgram__c = True);
        insert testAttendance;
        
        WGUCourseInProgram__c crsInProg1 = new WGUCourseInProgram__c(Transferable__c = True, TransferMinimumDegree__c = testAS.Id);
        WGUCourseInProgram__c crsInProg2 = new WGUCourseInProgram__c(Transferable__c = True, TransferDegree__c = testBS.Id, TransferRelatedProgram__c = True);  
        insert crsInProg1;
        insert crsInProg2;      
        
        StudentTransferredCourse__c transCourse1 = new StudentTransferredCourse__c(StudentTransferInstitution__c = testInstitution.Id);  
        StudentTransferredCourse__c transCourse2 = new StudentTransferredCourse__c(StudentTransferInstitution__c = testInstitution.Id); 
        insert transCourse1;
        insert transCourse2;
        
        StudentEquivalentCourse__c equivCourse1 = new StudentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id, WGUCourseInProgram__c = crsInProg1.Id);
        StudentEquivalentCourse__c equivCourse2 = new StudentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id, WGUCourseInProgram__c = crsInProg2.Id);
        insert equivCourse1;
        insert equivCourse2;         
        
        ApexPages.StandardController stdCont = new ApexPages.standardController(testOpportunity);
               
        OppTranscriptController testController = new OppTranscriptController(stdCont);
        
        testController.getInstCourses(); 
        testController.NewSubject = 'TestSubject1';
        testController.NewCrseName = 'TestCrseName1';
        testController.CurrentInstId = testInstitution.Id;         
        testController.add();
        testController.save();      
    }
}