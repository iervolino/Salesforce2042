/*
Test class  for StudentDispositionTrigger
Author- Bhavadeep Raavi
*/

@isTest
private with sharing class TestStudentDispositionTrigger{
     
     private static testmethod void TestStudentDispositionTrigger(){
     
     // This code runs as the system user
     User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
      
     System.runAs(testUser)    {
     
     Test.startTest();
     
     ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;     
     Contact con = new Contact();
     con.RecordTypeId = studentContactRecordTypeId ;
     con.LastName='testCon';
     con.FirstName ='testFname';
     con.Email='test@test.com';
     con.StudentID__c ='000123456';
     con.pidm__c ='0000101';
     insert con;
     
     System.assertEquals(con.Email,'test@test.com');
     System.assertEquals(con.LastName,'testCon');
     
     ID sdRecordTypeId = [Select Id from RecordType where DeveloperName = 'ArticulationConcern' and SObjectType = 'StudentDisposition__c'].id;     
     StudentDisposition__c sd= new StudentDisposition__c();
     sd.RecordTypeId = sdRecordTypeId;
     sd.Name = 'test';
     sd.StudentID__c ='123456';
     sd.AssessmentName__c ='tsa test';
     insert sd;
     
     System.assertEquals(sd.Name,'test');
     System.assertEquals(sd.StudentID__c,'123456');
     
     TaskStreamAssessment__c tsa = new TaskStreamAssessment__c();
     tsa.Name = 'tsa test';
     tsa.PIDM__c ='0000101';
     tsa.AssessmentCode__c ='test code';
     tsa.Student__c = con.Id;
     tsa.AssessmentIDKey__c =12345;
     tsa.OverallStatus__c ='ns';
     insert tsa;
     
      
     Test.stopTest();
    }
  }
  
    private static testmethod void TestStudentDispositionTrigger1(){
     
     // This code runs as the system user
     User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
      
     System.runAs(testUser)    {
     
     Test.startTest();
     
     ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;     
     Contact con = new Contact();
     con.RecordTypeId = studentContactRecordTypeId ;
     con.LastName='testCon';
     con.FirstName ='testFname';
     con.Email='test@test.com';
     con.StudentID__c ='000123456';
     con.pidm__c ='0000102';
     insert con;
     
     System.assertEquals(con.Email,'test@test.com');
     System.assertEquals(con.LastName,'testCon');
     
     ID sdRecordTypeId = [Select Id from RecordType where DeveloperName = 'ArticulationConcern' and SObjectType = 'StudentDisposition__c'].id;     
     StudentDisposition__c sd= new StudentDisposition__c();
     sd.RecordTypeId = sdRecordTypeId;
     sd.Name = 'test';
     sd.StudentID__c ='000123456';
     sd.AssessmentName__c ='tsa test';
     insert sd;
    
     
     Test.stopTest();
    }
  }
}