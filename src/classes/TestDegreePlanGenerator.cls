@IsTest
public with sharing class TestDegreePlanGenerator {

  @IsTest
  public static void testNewStudent() {
    SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
    box.deleteAllData();
    box.createPAMSData();
    box.createAccounts();
    box.saveAccounts();
    box.assignStudentToProgram();
  }

  @IsTest
  public static void testStudentInMiddleOfPlan() {
    SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
    box.deleteAllData();
    box.createPAMSData();
    box.createAccounts();
    box.saveAccounts();
    box.assignStudentToProgram();
  }

  @IsTest
  public static void testNonDegreeRequirements() {
    SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
    box.deleteAllData();
    box.createPAMSData();
    box.createAccounts();
    box.saveAccounts();
    box.assignStudentToProgram();
    box.createStudentLicenseHistory();

    Test.startTest();
    DegreePlanGenerator dpg = new DegreePlanGenerator(box.atu.student1.contact,12.0,'102801','Current Plan');
    dpg.generateStudentDegreePlan();
    Test.stopTest();
  }

  @IsTest
  public static void testCoverageForConstructor() {
    SetupFDPDevelopmentBox box = new SetupFDPDevelopmentBox();
    box.deleteAllData();
    box.createPAMSData();
    box.createAccounts();
    box.saveAccounts();
    box.assignStudentToProgram();

    DegreePlanGenerator dpg = new DegreePlanGenerator(box.atu.student1.contact,12.0,null,'Current Plan');
    Boolean caughtException = false;
    try {
      dpg = new DegreePlanGenerator(box.atu.student1.contact,null,null,'Current Plan');
    } catch(Exception ex) {
      caughtException = true;
    }
    System.assert(caughtException,'Caught Exception in constructor');

    caughtException = false;
    try {
      dpg = new DegreePlanGenerator(box.atu.student1.contact,null,null,'Current Plan',null);
    } catch(Exception ex) {
      caughtException = true;
    }
    System.assert(caughtException,'Caught exception in constructor');

    caughtException = false;
    try {
      dpg = new DegreePlanGenerator(box.atu.student1.contact,null, 'Current Plan');
    } catch(Exception ex) {
      caughtException = true;
    }
    System.assert(caughtException,'Caught exception in constructor');

  }
}