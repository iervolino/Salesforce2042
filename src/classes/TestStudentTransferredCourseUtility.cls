/***************************************************************************************
 * Class: TestStudentTransferredCourseUtility
 * Author: Will Slade
 * Western Governors University 
 *
 * Purpose: Test StudentTransferredCourseTrigger and Utility
 *
 * Revisions:
 *     4/22/2013 - Created Class 
 *     10/8/2013 - PBC commented out User record creation, replaced with active User lookup for test runs
 *
 ***************************************************************************************/

@isTest
private with sharing class TestStudentTransferredCourseUtility
{
    private static testMethod void testInsertUpdateDeleteLink()
    {
        //Id profileId = [SELECT Id FROM Profile WHERE Name = 'Transcript Team' LIMIT 1].Id;
        
        User testUser = [SELECT id from User WHERE isActive=true AND Profile.Name = 'Transcript Team' LIMIT 1];//new User();
        /*
        testUser.Firstname = 'TestFEPlEm';
        testUser.Lastname = 'UserFEPlEm';
        testUser.Pidm__c = 'QA95050QA';
        testUser.Username = 'testuserFEPlEm@testuser.testuser';
        testUser.Email = 'testuserFEPlEm@testuser.testuser.wgu.edu';
        testUser.Alias = 'testFEPl';
        testUser.CommunityNickname = 'testua6123se';
        testUser.TimeZoneSidKey = 'America/Denver';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = profileId;
        testUser.LanguageLocaleKey = 'en_US';     
        insert testUser;
        */
        
        RecordType trDegRT = [SELECT Id FROM RecordType WHERE SObjectType = 'KeyValue__c' AND DeveloperName = 'TransferDegree' LIMIT 1];
        
        KeyValue__c noDegree = new KeyValue__c(RecordTypeId = trDegRT.Id, ExternalID__c = 'ND', Value__c = 'ND', NumericValue__c = 0);
        insert noDegree;        
        
        CAREProgram__c testCAREProgram = new CAREProgram__c(Name = 'TestCAREProgram124');
        insert testCAREProgram;
        
        WGUDegreeProgram__c testWGUDegreeProgram = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124124, Active__c = true, CatalogTerm__c = '201106');
        WGUDegreeProgram__c testWGUDegreeProgram1 = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124125, Active__c = true, CatalogTerm__c = '201206');
        WGUDegreeProgram__c testWGUDegreeProgram2 = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124126, Active__c = false, CatalogTerm__c = '201306');
        insert testWGUDegreeProgram;
        insert testWGUDegreeProgram1;
        insert testWGUDegreeProgram2;        
        
        CAREProgramMiddleEarth__c testCAREProgramMiddleEarth = new CAREProgramMiddleEarth__c(CareProgramCode__c = testCAREProgram.Id, BannerProgramCode__c = testWGUDegreeProgram.Id);
        insert testCAREProgramMiddleEarth;
        
        Opportunity testOpportunity = new Opportunity(Name = 'testEvalCourseTriggerOpp', CloseDate = Date.Today(), StageName = 'Applicant', 
                                                      MarketingReferID__c = '549519sdfa8', MarketingProgram__c = testCAREProgramMiddleEarth.Id);
        insert testOpportunity;                
        
        TransferEvaluation__c testTransferEvaluation = new TransferEvaluation__c(Name = 'testTransferEval124', Opportunity__c = testOpportunity.Id, 
                                                                                 EligibilityStatus__c = 'Eligible', EvaluationStatus__c = 'Pending');
        testTransferEvaluation.assignedTo__c = testUser.Id;                                                                                
        insert testTransferEvaluation;  
        
        StudentTranscript__c testTranscript1 = new studentTranscript__c(Opportunity__c = testOpportunity.Id);
        StudentTranscript__c testTranscript2 = new studentTranscript__c(Opportunity__c = testOpportunity.Id);
        insert testTranscript1;                      
        insert testTranscript2;
        
        TransferAttendance__c testAttendance = new TransferAttendance__c(StudentTransferInstitution__c = testTranscript1.Id); 
        insert testAttendance;              
        
        StudentTransferredCourse__c transCourse1 = new studentTransferredCourse__c(StudentTransferInstitution__c = testTranscript1.Id, TransferAttendance__c = testAttendance.Id);
        StudentTransferredCourse__c transCourse2 = new studentTransferredCourse__c(StudentTransferInstitution__c = testTranscript2.Id, pushedToBanner__c = true);
        StudentTransferredCourse__c transCourse3 = new studentTransferredCourse__c(StudentTransferInstitution__c = testTranscript1.Id);
        
        Test.startTest();
        
            insert transCourse1;
            insert transCourse2; 
            insert transCourse3;                 

        Test.stopTest();
        
        System.assertEquals(transCourse1.TransferAttendance__c, testAttendance.Id);

        transCourse2 = [SELECT Id, TransferAttendance__c FROM StudentTransferredCourse__c WHERE Id = :transCourse2.Id];    
        transCourse3 = [SELECT Id, TransferAttendance__c FROM StudentTransferredCourse__c WHERE Id = :transCourse3.Id]; 
        
        System.assert(transCourse2.TransferAttendance__c != null);
        System.assertEquals(transCourse3.TransferAttendance__c, testAttendance.Id);
        
        TranscriptToBanner__c trToBan = [SELECT Id, ActionNeeded__c, RefId__c, STudentTransferredCourse__c 
                                         FROM TranscriptToBanner__c 
                                         WHERE StudentTransferredCourse__c = :transCourse2.Id 
                                         LIMIT 1];
        
        System.assertEquals(trToBan.ActionNeeded__c, 'Insert');
        
        String trCr2Id = String.valueOf(transCourse2.Id);
        
        StudentEquivalentCourse__c eqCrs = new StudentEquivalentCourse__c (TransferEvaluation__c = testTransferEvaluation.Id, TransferredCourse__c = transCourse1.Id);
        insert eqCrs;
        
        String errorMessage = null;
        
        try
        {
            delete transCourse1;                   
        }
        catch (Exception e)
        {
            errorMessage = e.getMessage();
        }
        
        System.assert(errorMessage != null);
        
        delete transCourse2;
        
        trToBan = [SELECT Id, ActionNeeded__c, RefId__c, STudentTransferredCourse__c 
                   FROM TranscriptToBanner__c 
                   WHERE RefId__c = :transCourse2.Id 
                   LIMIT 1];
        
        System.assertEquals(trToBan.ActionNeeded__c, 'Delete');                        
    }    
}