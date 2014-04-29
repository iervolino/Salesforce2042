/*****************************************************************************************
* Name: TestEvalCreateEquivalentsTrigger
* Author: Will Slade
* Purpose: Test that EvalCreateEquivalentsTrigger is creating equiv courses appropriately
* Revisions: 
*    - 10/1/12 Created Class
******************************************************************************************/

@isTest
global class TestEvalCreateEquivalentsTrigger
{
    static testMethod void testMe()
    {
        CAREProgram__c testCAREProgram = new CAREProgram__c(Name = 'TestCAREProgram124');
        insert testCAREProgram;
        
        WGUDegreeProgram__c testWGUDegreeProgram = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124124, Active__c = true, CatalogTerm__c = '201106');
        WGUDegreeProgram__c testWGUDegreeProgram1 = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124125, Active__c = true, CatalogTerm__c = '201206');
        WGUDegreeProgram__c testWGUDegreeProgram2 = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124126, Active__c = false, CatalogTerm__c = '201306');
        insert testWGUDegreeProgram;
        insert testWGUDegreeProgram1;
        insert testWGUDegreeProgram2;
        
        WGUCourse__c testWGUCourse1 = new WGUCourse__c(Name = 'TestWGUCourse1', PAMSID__c = 1241241241);
        WGUCourse__c testWGUCourse2 = new WGUCourse__c(Name = 'TestWGUCourse2', PAMSID__c = 1241241242);        
        insert testWGUCourse1;
        insert testWGUCourse2;
        
        testWGUCourse1 = [SELECT Id, Name FROM WGUCourse__c WHERE Name = 'TestWGUCourse1' LIMIT 1];
        testWGUCourse2 = [SELECT Id, Name FROM WGUCourse__c WHERE Name = 'TestWGUCourse2' LIMIT 1];
        
        WGUCourseInProgram__c testWGUCourseInProgram1 = new WGUCourseInProgram__c(Course__c = testWGUCourse1.Id, Program__c = testWGUDegreeProgram1.Id, Transferable__c = true);
        WGUCourseInProgram__c testWGUCourseInProgram2 = new WGUCourseInProgram__c(Course__c = testWGUCourse2.Id, Program__c = testWGUDegreeProgram1.Id, Transferable__c = true);        
        insert testWGUCourseInProgram1; 
        insert testWGUCourseInProgram2;
        
        CAREProgramMiddleEarth__c testCAREProgramMiddleEarth = new CAREProgramMiddleEarth__c(CareProgramCode__c = testCAREProgram.Id, BannerProgramCode__c = testWGUDegreeProgram.Id);
        insert testCAREProgramMiddleEarth;
        
        Opportunity testOpportunity = new Opportunity(Name = 'testEvalCourseTriggerOpp', CloseDate = Date.Today(), StageName = 'Applicant', 
                                                      MarketingReferID__c = '549519sdfa8', MarketingProgram__c = testCAREProgramMiddleEarth.Id);
        insert testOpportunity;
        
        TransferEvaluation__c testTransferEvaluation = new TransferEvaluation__c(Name = 'testTransferEval124', Opportunity__c = testOpportunity.Id, EvaluationStatus__c = 'Pending');
        insert testTransferEvaluation;
        
        testTransferEvaluation = [SELECT Name, Opportunity__c, EvaluationStatus__c, WGUDegreeProgram__c FROM TransferEvaluation__c WHERE Id = :testTransferEvaluation.Id LIMIT 1];        
        
        studentEquivalentCourse__c equivCourse = new studentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id);
        insert equivCourse;
        
        List<StudentEquivalentCourse__c> testStudentEquivalentCourses = [SELECT Id, Name FROM StudentEquivalentCourse__c WHERE TransferEvaluation__c = :testTransferEvaluation.Id];     
        
        System.assertEquals(testTransferEvaluation.WGUDegreeProgram__c, TestWGUDegreeProgram1.Id);
        System.assertEquals(testStudentEquivalentCourses.size(), 3);
    }                     
}