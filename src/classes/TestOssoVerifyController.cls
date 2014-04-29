@isTest
public class TestOssoVerifyController {
  @isTest
  public static void testWithIframe() {
    PageReference pageRef = new PageReference('/apex/OssoVerify');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('iframe','1');
    OssoVerifyController a = new OssoVerifyController();
    a.initialize();
  }

  @isTest
  public static void testWithoutIframe() {
    PageReference pageRef = new PageReference('/apex/OssoVerify');
    Test.setCurrentPage(pageRef);
    OssoVerifyController a = new OssoVerifyController();
    a.initialize();
  }
}