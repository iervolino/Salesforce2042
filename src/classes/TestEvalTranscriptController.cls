/*****************************************************************************************
* Name: TestEvalTranscriptController
* Author: Will Slade
* Purpose: Test class EvalTranscriptController including applyDegrees method
* Revisions: 
*    - 10/1/12 Created Class
*    - 4/25/13 Updated for TranscriptToBanner object functionality
*    - 6/19/13 Split into two methods to avoid SOQL limit
*    - 8/06/13 Refactored to bring code into compliance with WGU test pattern - Paul Coleman
******************************************************************************************/

@isTest
global class TestEvalTranscriptController
{
    static testMethod void TestEvalTranscriptController()
    {
        CAREProgram__c testCAREProgram = new CAREProgram__c(Name = 'TestCAREProgram124');
        insert testCAREProgram;
        
        WGUDegreeProgram__c testWGUDegreeProgram = new WGUDegreeProgram__c(Name = 'TestWGUDegP124', PAMSID__c = 124124124);
        insert testWGUDegreeProgram;       
        
        CAREProgramMiddleEarth__c testCAREProgramMiddleEarth = new CAREProgramMiddleEarth__c(CareProgramCode__c = testCAREProgram.Id, BannerProgramCode__c = testWGUDegreeProgram.Id);
        insert testCAREProgramMiddleEarth;
        
        Id StudentAccountRecordId;
        
        List<RecordType> rts = [SELECT Id, Name FROM RecordType WHERE Name = 'StudentRecord' AND sObjectType = 'Account' LIMIT 1];
        for(RecordType rt : rts) 
        {
            if(rt.Name == 'StudentRecord') 
            {
                StudentAccountRecordId = rt.id;        
            }
        }
        
        Account studentAccount = new Account( pidm__c='p002233', Name='Dudley DasterdlyTesterson', BannerId__c = 'QA01234', RecordTypeId = studentAccountRecordId );
        insert studentAccount;
        
        RecordType trDegRT = [SELECT Id FROM RecordType WHERE SObjectType = 'KeyValue__c' AND DeveloperName = 'TransferDegree' LIMIT 1];
        
        KeyValue__c noDegree = new KeyValue__c(RecordTypeId = trDegRT.Id, ExternalID__c = 'ND', Value__c = 'ND', NumericValue__c = 0);
        insert noDegree;             
        
        Contact testContact1 = new Contact();
        
        testContact1.FirstName = 'Willtest';
        testContact1.Lastname = 'Slayedtest';
        testContact1.Email = 'wslayed@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';          
        
        insert testContact1;        
        
        Opportunity testOpportunity = new Opportunity(Account = studentAccount, Name = 'testEvalCourseTriggerOpp', CloseDate = Date.Today(), 
                                                      StudentContact__c = testContact1.Id, StageName = 'Applicant', MarketingProgram__c = testCAREProgramMiddleEarth.Id);
        insert testOpportunity;
        
	        RecordType transDegreeRT = [SELECT Id FROM RecordType WHERE Name = 'Transfer Degree' AND SobjectType = 'KeyValue__c' LIMIT 1];

	        KeyValue__c testBS = new KeyValue__c(RecordTypeId = transDegreeRT.Id, ExternalId__c = 'testBS421', NumericValue__c = 100, Value__c = 'Test421 Bachelor of Science');
	        KeyValue__c testAS = new KeyValue__c(RecordTypeId = transDegreeRT.Id, ExternalId__c = 'testAS421', NumericValue__c = 50, Value__c = 'Test421 Associate of Science');
	        insert testBS;
	        insert testAS;       


        Test.startTest();
 
	        TransferEvaluation__c testTransferEvaluation = new TransferEvaluation__c(Name = 'testTransferEval124', Opportunity__c = testOpportunity.Id, EvaluationStatus__c = 'Pending');
	        insert testTransferEvaluation;        
	        
	        StudentTranscript__c testInstitution = new StudentTranscript__c(Opportunity__c = testOpportunity.Id);
	        insert testInstitution;
		        
	        TransferAttendance__c testAttendance = new TransferAttendance__c(StudentTransferInstitution__c = testInstitution.Id, DegreeAwarded__c = testBS.Id, DegreeRelatesToWGUProgram__c = True);
	        insert testAttendance;
	        
	        WGUCourseInProgram__c crsInProg1 = new WGUCourseInProgram__c(Transferable__c = True, TransferMinimumDegree__c = testAS.Id);
	        WGUCourseInProgram__c crsInProg2 = new WGUCourseInProgram__c(Transferable__c = True, TransferDegree__c = testBS.Id, TransferRelatedProgram__c = True);  
	        insert crsInProg1;
	        insert crsInProg2;      
	        
	        StudentTransferredCourse__c transCourse1 = new StudentTransferredCourse__c(StudentTransferInstitution__c = testInstitution.Id,
	                                                                                   CourseGroup__c = '12');     
	        StudentTransferredCourse__c transCourse2 = new StudentTransferredCourse__c(StudentTransferInstitution__c = testInstitution.Id); 
	        insert transCourse1;
	        insert transCourse2;
	        
	        StudentEquivalentCourse__c equivCourse1 = new StudentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id, 
	                                                                                 WGUCourseInProgram__c = crsInProg1.Id,
	                                                                                 TransferredGroup__c = '12');
	        StudentEquivalentCourse__c equivCourse2 = new StudentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id, 
	                                                                                 WGUCourseInProgram__c = crsInProg2.Id,
	                                                                                 TransferredGroup__c = '11');                                                                                
	        insert equivCourse1;
	        insert equivCourse2;
	
	        ApexPages.StandardController stdCont = new ApexPages.standardController(testTransferEvaluation);
	               
	        EvalTranscriptController testController = new EvalTranscriptController(stdCont);
	                        
	        testController.saveEval();
	        testController.applyDegrees();  
	        testController.saveEquivCourses();
        
        Test.stopTest();
      
        List<StudentEquivalentCourse__c> equivCourses = [SELECT Id, TransferAttendance__c, EvalComments__c, WGUCourseInProgram__r.TransferRelatedProgram__c, SatisfiedInd__c,
                                                                WGUCourseInProgram__r.TransferDegree__c, WGUCourseInProgram__r.TransferMinimumDegree__c, TransferredCourse__c
                                                         FROM StudentEquivalentCourse__c 
                                                         WHERE TransferEvaluation__c = :testTransferEvaluation.Id 
                                                         LIMIT 2];
                                                         
        for (StudentEquivalentCourse__c equivCourse : equivCourses)                                                 
        {
            System.assert(equivCourse.TransferAttendance__c != null);
            System.assertEquals(equivCourse.SatisfiedInd__c, 'Y');
        }
    }
    
    static testMethod void TestEvalTranscriptController2()
    {
        CAREProgram__c testCAREProgram = new CAREProgram__c(Name = 'TestCAREProgram124');
        insert testCAREProgram;
        
        WGUDegreeProgram__c testWGUDegreeProgram = new WGUDegreeProgram__c(Name = 'TestWGUDegP124', PAMSID__c = 124124124);
        insert testWGUDegreeProgram;       
        
        CAREProgramMiddleEarth__c testCAREProgramMiddleEarth = new CAREProgramMiddleEarth__c(CareProgramCode__c = testCAREProgram.Id, BannerProgramCode__c = testWGUDegreeProgram.Id);
        insert testCAREProgramMiddleEarth;
        
        Id StudentAccountRecordId;
        
        List<RecordType> rts = [SELECT Id, Name FROM RecordType WHERE Name = 'StudentRecord' AND sObjectType = 'Account' LIMIT 1];
        for(RecordType rt : rts) 
        {
            if(rt.Name == 'StudentRecord') 
            {
                StudentAccountRecordId = rt.id;        
            }
        }
        
        Account studentAccount = new Account( pidm__c='p002233', Name='Dudley DasterdlyTesterson', 
                                              BannerId__c = 'QA01234', RecordTypeId = studentAccountRecordId );
        insert studentAccount;
        
        RecordType trDegRT = [SELECT Id FROM RecordType WHERE SObjectType = 'KeyValue__c' AND DeveloperName = 'TransferDegree' LIMIT 1];
        
        KeyValue__c noDegree = new KeyValue__c(RecordTypeId = trDegRT.Id, ExternalID__c = 'ND', Value__c = 'ND', NumericValue__c = 0);
        insert noDegree;             
        
        Contact testContact1 = new Contact();
        
        testContact1.FirstName = 'Willtest';
        testContact1.Lastname = 'Slayedtest';
        testContact1.Email = 'wslayed@my.wgu.edu';
        testContact1.PIDM__c = 'EMQAPIDM1';          
        
        insert testContact1;        
        
        Opportunity testOpportunity = new Opportunity(Account = studentAccount, Name = 'testEvalCourseTriggerOpp', CloseDate = Date.Today(), 
                                                      StudentContact__c = testContact1.Id, StageName = 'Applicant', MarketingProgram__c = testCAREProgramMiddleEarth.Id);
        insert testOpportunity;
 
	        RecordType transDegreeRT = [SELECT Id FROM RecordType WHERE Name = 'Transfer Degree' AND SobjectType = 'KeyValue__c' LIMIT 1];
	        
	        KeyValue__c testBS = new KeyValue__c(RecordTypeId = transDegreeRT.Id, ExternalId__c = 'testBS421', NumericValue__c = 100, Value__c = 'Test421 Bachelor of Science');
	        KeyValue__c testAS = new KeyValue__c(RecordTypeId = transDegreeRT.Id, ExternalId__c = 'testAS421', NumericValue__c = 50, Value__c = 'Test421 Associate of Science');
	        insert testBS;
	        insert testAS;       
 
        Test.startTest();
        
	        TransferEvaluation__c testTransferEvaluation = new TransferEvaluation__c(Name = 'testTransferEval124', Opportunity__c = testOpportunity.Id, EvaluationStatus__c = 'Pending');
	        insert testTransferEvaluation;        
	        
	        StudentTranscript__c testInstitution = new StudentTranscript__c(Opportunity__c = testOpportunity.Id);
	        insert testInstitution;
		        
	        TransferAttendance__c testAttendance = new TransferAttendance__c(StudentTransferInstitution__c = testInstitution.Id, DegreeAwarded__c = testBS.Id, DegreeRelatesToWGUProgram__c = True);
	        insert testAttendance;
	        
	        WGUCourseInProgram__c crsInProg1 = new WGUCourseInProgram__c(Transferable__c = True, TransferMinimumDegree__c = testAS.Id);
	        WGUCourseInProgram__c crsInProg2 = new WGUCourseInProgram__c(Transferable__c = True, TransferDegree__c = testBS.Id, TransferRelatedProgram__c = True);  
	        insert crsInProg1;
	        insert crsInProg2;      
	        
	        StudentTransferredCourse__c transCourse1 = new StudentTransferredCourse__c(StudentTransferInstitution__c = testInstitution.Id,
	                                                                                   CourseGroup__c = '12');     
	        StudentTransferredCourse__c transCourse2 = new StudentTransferredCourse__c(StudentTransferInstitution__c = testInstitution.Id); 
	        insert transCourse1;
	        insert transCourse2;
	        
	        StudentEquivalentCourse__c equivCourse1 = new StudentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id, 
	                                                                                 WGUCourseInProgram__c = crsInProg1.Id,
	                                                                                 TransferredGroup__c = '12');
	        StudentEquivalentCourse__c equivCourse2 = new StudentEquivalentCourse__c(TransferEvaluation__c = testTransferEvaluation.Id, 
	                                                                                 WGUCourseInProgram__c = crsInProg2.Id,
	                                                                                 TransferredGroup__c = '11');                                                                                
	        insert equivCourse1;
	        insert equivCourse2;
	
	        ApexPages.StandardController stdCont = new ApexPages.standardController(testTransferEvaluation);
	               
	        EvalTranscriptController testController = new EvalTranscriptController(stdCont);
	        
	        testController.getInstCourses();
	        testController.getequivCourses();
	        testController.getTransAttendances(); 
	        
        Test.stopTest();   
    }    
}