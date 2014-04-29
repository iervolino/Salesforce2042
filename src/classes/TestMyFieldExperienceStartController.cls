/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 * 
 * Test the MyFieldExperienceStartController class
 *
 */
 @isTest
public with sharing class TestMyFieldExperienceStartController {

   static testmethod void testGetUserProfilePage() {
     
     TestStudentUser.setupStudentTestData();
     
     Test.startTest();
     
     MyFieldExperienceStartController con = new MyFieldExperienceStartController();
     System.assert ( con.getUserProfilePage() != null );
     
     User mentorUser = [SELECT Id FROM User WHERE profileid in (select id from Profile where Name = 'Mentor') and isActive = true LIMIT 1];
     System.RunAs(mentorUser){
       System.assert ( con.getUserProfilePage() != null );
     }
     User studentUser = TestStudentUser.getTestStudentUser();
     System.RunAs(studentUser){
       System.assert ( con.getUserProfilePage() != null );
     }
     User apiOnlyUser = [SELECT Id FROM User WHERE profileid in (select id from Profile where Name = 'APIOnly') and isActive = true LIMIT 1];
     System.RunAs(apiOnlyUser ){
       System.assert ( con.getUserProfilePage() != null );
     }
     User feUser = [SELECT Id FROM User WHERE profileid in (select id from Profile where Name = 'Field Experiences User') and isActive = true LIMIT 1];
     System.RunAs(feUser){
       System.assert ( con.getUserProfilePage() != null );
     }
     
     Test.stopTest();
     
   }
}