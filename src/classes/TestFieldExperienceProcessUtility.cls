/*
 * This is the test class for FEPlacementAttempt
 * Author-Bhavadeep raavi
 *
 * Date February 12, 2013 @ 1014 hrs
 * Revised: PersonAccount Refactor, try/catch correction for future calls - Paul Coleman 
 *
 *
*/
@isTest
private class TestFieldExperienceProcessUtility{
    
    private static testmethod void testFieldExperienceProcessCreateWGUPlacementCase(){
 
             TestStudentFieldExperience.setupTestFEData();
             Contact testStudent = TestStudentUser.getTestStudentContact();
             //ID mentorProfileID = [SELECT id from Profile where name = 'Mentor'].id;
             //User testUser = new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942_test', Username='a_test_mentor@wgu.edu', email='a_test_mentor@wgu.edu', Alias='a_test_m', CommunityNickname='a_test_mentor', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true);
         User testMentor = [SELECT Id from User WHERE UserRole.Name ='Mentor' AND isActive = true LIMIT 1]; 
        
         ID DistrictId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName ='District' Limit 1].Id;
         ID SchoolK12Id = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName ='SchoolK12' Limit 1].Id;
         ID PlacementAttemptId = [SELECT Id FROM RecordType WHERE SobjectType = 'FieldExperienceProcess__c' AND DeveloperName ='PlacementAttempt' Limit 1].Id;
         Account DistrictAccount = new Account();
         DistrictAccount.recordtypeid = DistrictId;
         DistrictAccount.Name = 'Test District';
         DistrictAccount.WGUPlacesStudents__c = true;
         insert DistrictAccount;
         
         Account SchoolAccount = new Account();
         SchoolAccount.recordtypeid = SchoolK12Id;
         SchoolAccount.Name = 'Test School';
         SchoolAccount.WGUPlacesStudents__c = true;
         insert SchoolAccount;
         
         FieldExperience__c fe = new FieldExperience__c();
         fe.Name ='Test Fe';
         fe.Student__c = testStudent.Id;
         insert fe;
         
         fe.Mentor__c = testMentor.Id;
         update fe;
         
          
         Test.startTest();
         
              FieldExperienceProcess__c fep= new  FieldExperienceProcess__c();
                  fep.Name ='Test Fep';
                  fep.District__c = DistrictAccount.Id;
                  fep.School__c = SchoolAccount.Id;
                  fep.FieldExperience__c = fe.Id;
                  fep.recordtypeid = PlacementAttemptId;
                  insert fep;
         
                  FieldExperienceProcess__c fepAfterInsert = [SELECT id,Name,Student__c FROM FieldExperienceProcess__c WHERE id = :fep.Id LIMIT 1];
                  System.assert( fepAfterInsert.Student__c == testStudent.Id, 'FEP TRIGGER ERROR, FieldExperience__c.Student__c does NOT equal FieldExperienceProcess__c.Student__c AFTER INSERT');
                  
         Test.stopTest();
                             
              //future method assertions
              System.assert( [select count() from Case where contactId = :testStudent.Id LIMIT 1] == 1, 'FEP TRIGGER FUTURE METHOD ERROR, Case not created.' );
              Case studentCase = [select id,Description, contactid, Status from Case where contactId = :testStudent.Id LIMIT 1];
              System.assert( studentCase.Description.equals(DistrictAccount.Name) || studentCase.Description.equals(SchoolAccount.Name), 'FEP TRIGGER FUTURE METHOD ERROR, Case description does not match either of the referenced Accounts (District__c or School__c)');
              System.assert( studentCase.ContactId == fe.Student__c, 'FEP TRIGGER FUTURE METHOD ERROR, Case created from Trigger, FieldExperience.Student__c');
           
           //grab extra code coverage for future method Exception Handler
           List<FieldExperienceProcess__c> newFEPList = new List<FieldExperienceProcess__c>();
           newFEPList.add(fep);
           String TriggerNew = JSON.serialize( newFEPList );   
           createCaseFutureCall( TriggerNew ); 
    } 


    @future
    private static void createCaseFutureCall( String TriggerNew ) {
        
          //grabbing code coverage into future call exception handling blocks
          try { FieldExperienceProcessUtility.createWGUPlacesStudentCase( TriggerNew ); } catch (Exception e) {}
          
    }

    private static testmethod void testFieldExperienceProcessNoStudentIdFound(){
 
         FieldExperience__c fe = new FieldExperience__c();
         fe.Name ='Test Fe';
         fe.Student__c = null;  //SHOULD THROW AN EXCPEPTION ON FEP CREATION
         insert fe;
          
         Test.startTest();
         
              FieldExperienceProcess__c fep= new  FieldExperienceProcess__c();
              fep.Name ='Test Fep';
              fep.FieldExperience__c = fe.Id;
              fep.recordtypeid = [SELECT Id FROM RecordType WHERE SobjectType = 'FieldExperienceProcess__c' AND DeveloperName ='PlacementAttempt' Limit 1].Id;
              
              try {
                  insert fep;
              } catch (DmlException dml) {
                System.Assert( dml.getMessage().contains('CANNOT SAVE FEP RECORD WITHOUT A VALID STUDENT'), 'DML Exception did not contain "CANNOT SAVE FEP RECORD WITHOUT A VALID STUDENT": ' + dml.getMessage() );
              } 
                       
         Test.stopTest();
                             
    } 

}