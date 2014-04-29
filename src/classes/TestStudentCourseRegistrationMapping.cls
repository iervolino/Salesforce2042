@isTest
public with sharing class TestStudentCourseRegistrationMapping {
  static testmethod void testBatchDeletion() {
    SetupFDPDevelopmentBox.refreshAllData();
    Test.startTest();
    StudentCourseRegistration__c c = new StudentCourseRegistration__c();
    c.TermCode__c = '201109';
    c.PIDM__c = '11';
    insert c;

    FDPUtilities.batchdelete();
   Test.stopTest();
   List<StudentCourseRegistration__c> rs = [
      select Id
      from StudentCourseRegistration__c
      where Id = :c.Id
    ];
    System.AssertEquals(rs.size(),0);
    
     
  }

  static testmethod void testBatchMapping() {
    SetupFDPDevelopmentBox.refreshAllData();
        Test.startTest();
    StudentCourseRegistration__c c = new StudentCourseRegistration__c();
    c.PIDM__c = '11';
    c.TermCode__c = '201209';
    c.Student__c = null;
    insert c;
    c.Student__c = null;
    update c;

    // completing code coverage
    new StudentCourseRegistrationBatchMapping();
    List<String> finishNotificationEmails = 
      new List<String>{};
    Database.executeBatch(
      new StudentCourseRegistrationBatchMapping(finishNotificationEmails)
    );
    Test.stopTest();
    Contact con = [select PIDM__c from Contact where PIDM__c = '11'];
    StudentCourseRegistration__c x = [select PIDM__c,Student__c
      from StudentCourseRegistration__c
      where Id = :c.Id];
    System.AssertEquals(x.Student__c,con.Id);
  }

  static testmethod void testTriggerMapping() {
    SetupFDPDevelopmentBox.refreshAllData();
     Test.startTest();
    StudentCourseRegistration__c c = new StudentCourseRegistration__c();
    c.PIDM__c = '11';
    c.TermCode__c = '201209';
    c.Student__c = null;
    insert c;
    Contact con = [select PIDM__c from Contact where PIDM__c = '11'];
    StudentCourseRegistration__c x = [select PIDM__c,Student__c
      from StudentCourseRegistration__c
      where Id = :c.Id];
         Test.stopTest();
    System.AssertEquals(x.Student__c,con.Id);
  }

}