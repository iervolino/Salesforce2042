/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 * 
 */
@isTest
private with sharing class TestFindStudentController {

//////////////////////////TEST SSN HASH

  static testmethod void testSSNHashSearchSSNAndLast4 () {
    
    Contact studentContact = TestStudentUser.getTestStudentContact();    
    
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

         Test.startTest();
         
			    studentContact.DateOfBirth__c = '01/01/1966';
			    studentContact.SocialSecurityNumber__c = '444556666';
			    update studentContact;
          
         Test.stopTest();
         
         //Assert after Future methods return
         FindStudentController controller = new FindStudentController ();
         System.assert( FindStudentController.searchSSN( '444556666', false).contains(studentContact.id) );
         System.assert( FindStudentController.searchSSN( '6666', true ).contains(studentContact.id) );
         System.assert( FindStudentController.searchBirthDate( '01/01/1966' ).contains( studentContact.id ) ); 
    }
  }  
/////////////////////////END TEST SSN HASH  

}