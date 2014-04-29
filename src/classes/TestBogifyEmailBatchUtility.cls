/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date January 22, 2013 @ 1044 hrs
 * 
 * Test class for BogifyEmailBatchUtility class 
 *
 *
 */

@isTest
private class TestBogifyEmailBatchUtility {

    static testMethod void testBogifyEmail() {
        
      String environment = TestStudentUser.getEnvironment();
        ID studentRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
        Contact studentContact = new Contact( Status__c='AS', pidm__c='p002233', firstName='Dudley', Email='dasterdlytesterson@bogify.edu', WGUEmail__c='dasterdlytesterson@bogify.edu', OtherEmail__c='dasterdlytesterson@bogify.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentRecordTypeId );
        insert studentContact;
        
        User testUser = TestStudentUser.getSAdminUser();
        System.RunAs( testUser ) {   

   
       Test.StartTest();
          
          BogifyEmailBatchUtility bogify = new BogifyEmailBatchUtility('select Id, Email, WGUEmail__c, OtherEmail__c from Contact WHERE id = \'' + studentContact.Id +'\'');
          ID batchprocessid = Database.executeBatch(bogify);
          
       Test.StopTest();

      String newEmail = [select Email from Contact where Id = :studentContact.Id].Email;
      System.Assert( ( environment=='prod'? newEmail==studentContact.Email: true ), 'Email has not been processed correctly by BogifyEmailBatchUtility in org (' + environment + ')');     
   }
        
    }
}