/*
 * Test class  for code coverage of FEAppealsController
 * Author- Bhavadeep Raavi
 *
 * Date January 31, 2013 @ 1447 hrs
 * Revised: Person Account Refactor - Paul Coleman 
 * 
 *
*/

@isTest(SeeAllData=false)
private with sharing class TestFEAppealsController {

static testmethod void FEAppealsControllerTestMethod(){
    TestStudentFieldExperience.setupTestFEData();
    Contact studentContact = TestStudentUser.getTestStudentContact();
    
    FieldExperience__c fe=new FieldExperience__c();
    fe.Name='Test FE';
    fe.Student__c = studentContact.Id;
    fe.Cohort__c = [SELECT id FROM Cohort__c WHERE AvailableForStudents__c=true LIMIT 1].Id;
    insert fe;
    
    FieldExperienceProcess__c fep=new FieldExperienceProcess__c();
    fep.Name='Test FEP';
    fep.FieldExperience__c=fe.Id;
    insert fep;
    
    List<SelectOption> test_options = new List<SelectOption>();
    test_options.add(new SelectOption('Yes', 'Yes'));
    test_options.add(new SelectOption('No', 'No'));
    
    List<SelectOption> test_options1 = new List<SelectOption>();
    test_options1.add(new SelectOption('Failed', 'Failed'));
    test_options1.add(new SelectOption('Not Taken', 'Not Taken'));
    
    FEAppealsController ac=new FEAppealsController();
    
    ac.getAppealTypeValues();
    List<SelectOption> q1Options=ac.getQOne();
    System.assertEquals(test_options.size(),q1Options.size());    
    List<SelectOption> q3aOptions=ac.getQ3a();
    System.assertEquals(test_options.size(),q3aOptions.size()); 
    List<SelectOption> q3bOptions=ac.getQ3b();
    System.assertEquals(test_options.size(),q3bOptions.size()); 
    List<SelectOption> q3cOptions=ac.getQ3c();
    System.assertEquals(test_options.size(),q3cOptions.size()); 
    List<SelectOption> q3dOptions=ac.getQ3d();
    System.assertEquals(test_options.size(),q3dOptions.size()); 
    List<SelectOption> q3eOptions=ac.getQ3e();
    System.assertEquals(test_options.size(),q3eOptions.size()); 
    List<SelectOption> q3fOptions=ac.getQ3f();
    System.assertEquals(test_options.size(),q3fOptions.size()); 
    List<SelectOption> q3gOptions=ac.getQ3g();
    System.assertEquals(test_options.size(),q3gOptions.size()); 
    List<SelectOption> q11Options=ac.getQ11();
    System.assertEquals(test_options1.size(),q11Options.size()); 

    User testUser = [SELECT id FROM User WHERE Profile.Name = 'Field Experiences User' AND isActive = true LIMIT 1];
    System.RunAs( testUser ) {

    
  Test.startTest();
  
    ApexPages.currentPage().getParameters().put('fe',fe.Id);
    ac.q1AnsrSel='Yes';  
    System.assertEquals('Yes',ac.q1AnsrSel);  
    PageReference pf=ac.save();
    String str=pf.getUrl();
    System.assertEquals('/'+fe.Id,str);
    PageReference pf1=ac.cancel();
    
    System.assert('/'+fe.Id==pf1.getUrl(), 'APPEALS TEST FAILURE, resulting URL does not equal /' + fe.id);
    
    Test.stopTest();
    }
} 

}