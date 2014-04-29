/*****************************************************************************************
* Name: TestStudentTranscriptUtility
* Author: Will Slade
* Purpose: Tests StudentTranscriptTrigger and StudentTranscriptUtility
* Revisions: 
*    4-17-2013 - Created Class
*
******************************************************************************************/

@isTest
private with sharing class TestStudentTranscriptUtility
{
    private static testMethod void testInsert()
    {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'Developer' AND isActive = true LIMIT 1];
        
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
    
        StudentTranscript__c testTranscript1 = new studentTranscript__c(Opportunity__c = testOpportunity.Id);  
        StudentTranscript__c testTranscript2 = new studentTranscript__c(Opportunity__c = testOpportunity.Id);                                           
             
        Test.startTest();
        
            insert testTranscript1;
            insert testTranscript2;
            
            TransferAttendance__c trAtt1 = new TransferAttendance__c(StudentTransferInstitution__c = testTranscript1.Id);                                                                
            insert trAtt1;                                              
        
        Test.stopTest();
                
        List<TranscriptToBanner__c> ctrlObjList = [SELECT Id, ActionNeeded__c, RefId__c 
                                                   FROM TranscriptToBanner__c 
                                                   WHERE StudentTransferInstitution__c = :testTranscript1.Id 
                                                   LIMIT 5];
        
        System.assertEquals(ctrlObjList.size(), 2);
        System.assertEquals(ctrlObjList[0].ActionNeeded__c, 'Insert');                
        
        String errorMessage = null;
        
        try
        {
            delete testTranscript1;                   
        }
        catch (Exception e)
        {
            errorMessage = e.getMessage();
        }
        
        System.assert(errorMessage != null);
                               
        delete testTranscript2;   
        
        ctrlObjList = [SELECT Id, ActionNeeded__c, RefId__c 
                       FROM TranscriptToBanner__c 
                       WHERE RefId__c = :testTranscript2.Id 
                       LIMIT 1];   
                       
        System.assertEquals(ctrlObjList[0].ActionNeeded__c, 'Delete');                     
    }
}