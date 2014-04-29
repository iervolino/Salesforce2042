/*******************************************************************
 * Author Will Slade
 * Western Governors University 
 *
 * Created Date Aug 29, 2013 
 *
 * Test Trigger Utility for StudentAttributes Trigger processing
 *
 *******************************************************************/
 
 @isTest
 public with sharing class TestStudentAttributesUtility
 {
     private static testMethod void TestCreateSAToBanner()
     {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();

        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAttributes__c testSA = new StudentAttributes__c(StudentContact__c = baggins.Id, ParentsAttendedACollegeOrUniversity__c = 'Yes',
                                                               ParentsGraduated__c = 'No', Nickname__c = 'CleverHobbitses', MilitaryStatus__c = 'Active Army Duty',
                                                               MaritalStatus__c = 'Divorced', CommunityType__c = 'Urban', CitizenshipStatus__c = 'U.S. Citizen',
                                                               Affiliation__c = 'WGU-TX');
        insert testSA;
        testSA.Nickname__c='test';
        Test.startTest();
            update testSA;
        Test.stopTest();  
        
        List<StudentAttributesToBanner__c> testSATBList = [SELECT Id, CampusCodeOUT__c, CitizenshipOUT__c, CommunityTypeOUT__c, MaritalStatusOUT__c, MilitaryStatusOUT__c,
                                                             NicknameOUT__c, ParentsAttendedCollegeOUT__c, ParentsGraduatedCollegeOUT__c, StudentAttributes__c
                                                             FROM StudentAttributesToBanner__c
                                                             WHERE StudentAttributes__c = :testSA.Id
                                                             LIMIT 5];
        System.assertEquals(testSATBList.size(), 1, 'Excess control records created - expected 1, found ' + testSATBList.size() );                                                             
        System.assertEquals(testSATBList[0].StudentAttributes__c,testSA.Id, 'Control record linked to incorrect Student Attributes record');
        System.assertEquals(testSATBList[0].CampusCodeOUT__c,testSA.Affiliation__c, 'Incorrect campus code control record' );
        System.assertEquals(testSATBList[0].CitizenshipOUT__c,testSA.CitizenshipStatus__c, 'Incorrect Citizenship Status on control record' );
        System.assertEquals(testSATBList[0].CommunityTypeOUT__c,testSA.CommunityType__c, 'Incorrect Community Type found on control record' );
        System.assertEquals(testSATBList[0].MaritalStatusOUT__c,testSA.MaritalStatus__c, 'Incorrect Marital Status found on control record' );
        System.assertEquals(testSATBList[0].MilitaryStatusOUT__c ,testSA.MilitaryStatus__c, 'Incorrect Military Status found on control record' );
        System.assertEquals(testSATBList[0].NicknameOUT__c,'test', 'Incorrect Nickname found on control record' ); 
        System.assertEquals(testSATBList[0].ParentsAttendedCollegeOUT__c,testSA.ParentsAttendedACollegeOrUniversity__c, 'Incorrect Parents College found on control record' );
        System.assertEquals(testSATBList[0].ParentsGraduatedCollegeOUT__c,testSA.ParentsGraduated__c, 'Incorrect Parents Graduation found on control record' );

     }
 }