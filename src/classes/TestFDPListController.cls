@IsTest
public with sharing class TestFDPListController {

  @IsTest
  public static void testChangeMentor(){
    SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
    box.deleteAllData();
    box.createPAMSData();
    box.createAccounts();
    box.saveAccounts();
    box.assignStudentToProgram();

    DegreePlanGenerator gen = new DegreePlanGenerator(
        box.atu.student1.contact,
        12.0,
        null,
        'Current Plan'
    );
    gen.generateAndSave();
    User u = [select id from User where PIDM__c = '16'];

    Test.startTest();
    System.runAs(u) {
      PageReference pageRef = new PageReference('/apex/FDPList');
      Test.setCurrentPage(pageRef);
      FDPListController ls = new FDPListController();
      ls.initialize();
      ApexPages.currentPage().getParameters().put('MentorId',u.Id);
      ls.changeMentor();
    }
    Test.stopTest();
  }

  @IsTest
  public static void testPageWithData() {
    SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
    box.deleteAllData();
    box.createPAMSData();
    box.createAccounts();
    box.saveAccounts();
    box.assignStudentToProgram();

    DegreePlanGenerator gen = new DegreePlanGenerator(
        box.atu.student1.contact,
        12.0,
        null,
        'Current Plan'
    );
    gen.generateAndSave();
    User u = [select id from User where PIDM__c = '16'];

    Test.startTest();
    System.runAs(u) {
      PageReference pageRef = new PageReference('/apex/FDPList');
      Test.setCurrentPage(pageRef);
      FDPListController ls = new FDPListController();
      ls.initialize();
    }
    Test.stopTest();
  }
}