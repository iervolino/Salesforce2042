@isTest
public class TestSimpleJSONApiController {
  @isTest
  public static void testSimpleTest() {
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('function', 'test');
    SimpleJSONApiController a = new SimpleJSONApiController();
    a.initialize();
    Map<String,String> data = (Map<String,String>)System.JSON.deserialize(a.jsonData,Map<String,String>.class);
    System.assertEquals(data.get('success'),'1');
    System.assertEquals(data.get('data'),'test was good');
  }

  @isTest
  public static void testSimpleTestWithCallback() {
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('function','test');
    ApexPages.currentPage().getParameters().put('callback','foobarFunk');
    SimpleJSONApiController a = new SimpleJSONApiController();
    a.initialize();
    Pattern p = Pattern.compile('^foobarFunk\\((.*)\\)$');
    Matcher m = p.matcher(a.jsonData);
    String fooData = '';
    if(m.find()) {
      fooData = m.group(1);
    } else {
      System.assert(false);
    }
    Map<String,String> data = (Map<String,String>)System.JSON.deserialize(fooData,Map<String,String>.class);
    System.assertEquals(data.get('success'),'1');
    System.assertEquals(data.get('data'),'test was good');
  }

  @isTest
  public static void testSimpleTestException() {
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('function', 'test');
    ApexPages.currentPage().getParameters().put('throwException', '1');

    SimpleJSONApiController a = new SimpleJSONApiController();
    a.initialize();
    Map<String,String> data = (Map<String,String>)System.JSON.deserialize(a.jsonData,Map<String,String>.class);
    System.assertEquals(data.get('success'),'0');
    System.assertEquals(data.get('error_message'),'threw test exception successfully');
  }

  @isTest
  public static void testNoFunctionProvided() {
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);

    SimpleJSONApiController a = new SimpleJSONApiController();
    a.initialize();
    Map<String,String> data = (Map<String,String>)System.JSON.deserialize(a.jsonData,Map<String,String>.class);
    System.assertEquals('0',data.get('success'));
    System.assertEquals('No function provided',data.get('error_message'));
  }

  @isTest
  public static void testFunctionNotFound() {
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('function', 'helloworld');

    SimpleJSONApiController a = new SimpleJSONApiController();
    a.initialize();
    Map<String,String> data = (Map<String,String>)System.JSON.deserialize(a.jsonData,Map<String,String>.class);
    System.assertEquals('0',data.get('success'));
    System.assertEquals('Function not found: \'helloworld\'',data.get('error_message'));
  }

    
    @isTest
  public static void testGetMentorPhoto_mentor() {
    SetupFDPDevelopmentBox.refreshAllData();
    List<User> users = [select
      PIDM__c,Id,Name,FullPhotoUrl,SmallPhotoUrl
      from User
      where PIDM__c in ('11','16')];
    User mentor;
    User student;
    for(User u : users) {
      if(u.PIDM__c == '11')
        student = u;
      if(u.PIDM__c == '16')
        mentor = u;
    }
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('function', 'getMentorPhoto');

    Test.startTest();
    System.runAs(mentor) {
      SimpleJSONApiController a = new SimpleJSONApiController();
      a.initialize();
      Map<String,String> data = (Map<String,String>)System.JSON.deserialize(a.jsonData,Map<String,String>.class);
      System.assertEquals('0',data.get('success'));
      System.assertEquals('No mentor found for the current user.',data.get('error_message'));
    }
    Test.stopTest();
  }
    
    @isTest
  public static void testGetMentorPhoto_student() {
    SetupFDPDevelopmentBox.refreshAllData();
    List<User> users = [select
      PIDM__c,Id,Name,FullPhotoUrl,SmallPhotoUrl
      from User
      where PIDM__c in ('11','16')];
    User mentor;
    User student;
    for(User u : users) {
      if(u.PIDM__c == '11')
        student = u;
      if(u.PIDM__c == '16')
        mentor = u;
    }
    PageReference pageRef = new PageReference('/apex/SimpleJSONApi');
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('function', 'getMentorPhoto');

    Test.startTest();
    System.runAs(student) {
      SimpleJSONApiController a = new SimpleJSONApiController();
      a.initialize();
      Map<String,Object> result = (Map<String,Object>)System.JSON.deserializeUntyped(a.jsonData);
      System.assertEquals('0',result.get('success'));
    }
    Test.stopTest();
  }
  
}