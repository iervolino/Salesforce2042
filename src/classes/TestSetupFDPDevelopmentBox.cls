@IsTest
public class TestSetupFDPDevelopmentBox {
  @IsTest
  public static void testAccountCreation() {
      SetupFDPDevelopmentBox devbox = new SetupFDPDevelopmentBox(SetupFDPDevelopmentBox.getRandomString(10));
      devbox.createPAMSData();
      devbox.createAccounts();
      devbox.saveAccounts();
      devbox.assignStudentToProgram();
      devbox.createStudentCompletionTasks();
      devbox.createStudentTuitionData();
      devbox.createStudentLicenseHistory();
  }
}