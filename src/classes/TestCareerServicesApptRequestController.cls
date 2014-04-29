/*
Test class  for CareerServicesApptRequestController
Author- Bhavadeep Raavi
*/


@isTest
private with sharing class TestCareerServicesApptRequestController{
    
    private static testmethod void TestMethodCareerServicesApptRequestController(){
        User testUser = [SELECT Id,pidm__c from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
        System.runAs(testUser){
        Test.startTest();
        CareerServicesApptRequestController csar1= new CareerServicesApptRequestController();    
        
        Contact contact= new Contact();
        contact.LastName=UserInfo.getLastName();
        contact.FirstName=UserInfo.getFirstName();
        contact.pidm__c=testUser.pidm__c;
        insert contact;
        csar1.submit(); 
        System.assertEquals(contact.LastName,UserInfo.getLastName());
        
        CareerServicesApptRequestController csar2= new CareerServicesApptRequestController();
        contact.pidm__c='1232';
        update contact;  
        csar2.submit(); 
        csar2.cancel(); 
            
        Test.stopTest();
        }
     }
}