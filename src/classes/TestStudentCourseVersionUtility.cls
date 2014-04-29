/*****************************************************************************************
* Name: TestStudentCourseVersionUtility
* Author: Will Slade
* Purpose: Test StudentCourseVersionUtility class
* Revisions: 
*    -  2/26/2014 Created Class
*
******************************************************************************************/
@isTest
public class TestStudentCourseVersionUtility
{
    private static testmethod void testDeleteNonProgramCourses()
    {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName, WGUDegreeProgram__c FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        
        WGUCourse__c testWGUCourse1 = new WGUCourse__c(Name = 'TWC1', PAMSId__c = 45);
        WGUCourse__c testWGUCourse2 = new WGUCourse__c(Name = 'TWC2', PAMSId__c = 46);
        insert testWGUCourse1;
        insert testWGUCourse2;         
        
        WGUCourseVersion__c testWGUCourseV1 = new WGUCourseVersion__c(Name = 'TCV1', WGUCourse__c = testWGUCourse1.Id, Version__c = 1, PamsCourseId__c = 45);
        WGUCourseVersion__c testWGUCourseV2 = new WGUCourseVersion__c(Name = 'TCV2', WGUCourse__c = testWGUCourse2.Id, Version__c = 2, PamsCourseId__c = 46);
        insert testWGUCourseV1;
        insert testWGUCourseV2;
        
        testWGUCourseV1 = [SELECT Id, Name, WGUCourse__c, Version__c FROM WGUCourseVersion__c WHERE Id = :testWGUCourseV1.Id];
        testWGUCourseV2 = [SELECT Id, Name, WGUCourse__c, Version__c FROM WGUCourseVersion__c WHERE Id = :testWGUCourseV2.Id];              
        
        WGUDegreeProgram__c testDegProg1 = new WGUDegreeProgram__c(Name = 'TESTME8', PAMSId__c = 47);
        WGUDegreeProgram__c testDegProg2 = new WGUDegreeProgram__c(Name = 'TESTME9', PAMSId__c = 48);
        insert testDegProg1;  
        insert testDegProg2;
        
        WGUCourseInProgram__c testCrsInProg1 = new WGUCourseInProgram__c(Course__c = testWGUCourse1.Id, Program__c = testDegProg1.Id);
        WGUCourseInProgram__c testCrsInProg2 = new WGUCourseInProgram__c(Course__c = testWGUCourse2.Id, Program__c = testDegProg2.Id);
        insert testCrsInProg1;
        insert testCrsInProg2;
        
        StudentCourseVersion__c testSCV1 = new StudentCourseVersion__c(Name = 'TESTSCV1', WGUCourseVersion__c = testWGUCourseV1.Id, Student__c = baggins.Id);
        StudentCourseVersion__c testSCV2 = new StudentCourseVersion__c(Name = 'TESTSCV2', WGUCourseVersion__c = testWGUCourseV2.Id, Student__c = baggins.Id);
        insert testSCV1;
        insert testSCV2;
        
        baggins.WGUDegreeProgram__c = testDegProg1.Id;
        update baggins;
        
        List<StudentCourseVersion__c> scvList = [SELECT Id FROM StudentCourseVersion__c WHERE Student__c = :baggins.Id LIMIT 20];
        System.assertEquals(scvList.size(), 2);
        
        Test.startTest();
            baggins.WGUDegreeProgram__c = testDegProg2.Id;
            update baggins;            
        Test.stopTest();
        
        scvList = [SELECT Id FROM StudentCourseVersion__c WHERE Student__c = :baggins.Id LIMIT 20];
        System.assertEquals(scvList.size(), 1);
        System.assertEquals(scvList[0].Id, testSCV2.Id);                                  
    }
}