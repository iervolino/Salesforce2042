@IsTest
public class TestFDPTestingUtilities {
  @IsTest
  public static void testTermCode() {
      Date myDate = Date.newInstance(2012,5,1);
      System.assertEquals('201205',FDPTestingUtilities.generateTermCode(myDate));
      myDate = myDate.addMonths(6);
      System.assertEquals('201211',FDPTestingUtilities.generateTermCode(myDate));
  }

  //@IsTest
  public static void testFull() {
      FDPTestingUtilities util = new FDPTestingUtilities(true);

      for (WGUCourse__c course : util.definitions) {
          util.generateWGUCourseCompletionTask(course);
      }
      FDPTestingUtilities.createCompletionTasksForStudent(util.contact.id,2,'Standard');
      FDPTestingUtilities.deleteCompletionTasksForStudent(util.contact.id);
      FDPTestingUtilities.putTermsBackForStudent(util.contact.id,1);
      FDPTestingUtilities.deleteDegreePlansForStudent(util.contact.id);
  }

  //@IsTest
  public static void testStudentOnly() {
      FDPTestingUtilities util = new FDPTestingUtilities(false);
      FDPTestingUtilities.getStudent();
  }
}