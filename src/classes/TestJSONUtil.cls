/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Created Date January 29, 2013 @ 1006 hrs
 *  
 * 
 * Test JSON serialization utility
 *
 */
@isTest
private with sharing class TestJSONUtil {

  private static testmethod void testJSONSerialization() {
        
    User testUser = TestStudentUser.getSAdminUser();
    System.RunAs( testUser ) {   

        Test.startTest();
          System.assert( JSONUtil.getJSON([select id from User LIMIT 10]).contains('{\"Records\":'), 'JSON List serialization FAILED, result does not contain Records element');
          System.assert( JSONUtil.getJSON([select id from User LIMIT 10][0]).contains('{\"Records\":'), 'JSON single Object serialization FAILED, result does not contain Records element');
        Test.stopTest();
    }
  }
  
  private static testmethod void testJSONSerializationWithQueryLocatorOffset() {
        
    User testUser = [Select id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
    System.RunAs( testUser ) {   

        Test.startTest();
          System.assert( JSONUtil.getJSON([select id from User LIMIT 10 OFFSET 10], true, '10').contains('{\"Records\":'), 'JSON List serialization with OFFSET FAILED, result does not contain Records element');
          System.assert( JSONUtil.getJSON([select id from User LIMIT 10 OFFSET 10][0], true, '10').contains('{\"Records\":'), 'JSON single Object serialization with OFFSET FAILED, result does not contain Records element');
        
        Test.stopTest();
    }
  }
    
  
}