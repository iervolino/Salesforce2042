/*
Test class  for Withdrawal Controller
Author- Bhavadeep Raavi
*/


@isTest
private with sharing class TestWithdrawalController{
    
    private static testmethod void TestMethodWithdrawalController(){
        User testUser = [SELECT Id,pidm__c from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
        System.runAs(testUser){
        Test.startTest();
        WithdrawalController wc1= new WithdrawalController();    
        
        Contact contact= new Contact();
        contact.LastName=UserInfo.getLastName();
        contact.FirstName=UserInfo.getFirstName();
        contact.pidm__c=testUser.pidm__c;
        insert contact;
        System.assertEquals(contact.LastName,UserInfo.getLastName());
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.Stage__c='MOU Accepted by Student';
        sp.ApplicationReceived__c=System.now();
        sp.reason__c='Customer Service;Death in the Family;Demonstration Teaching (DT);Military;Nursing Clinical Alignment;Pers Circ - Bereavement;Technical Issues;Posting Delay;Term Break';
        insert sp;
        System.assertEquals(sp.name,'Test sp');
        System.assertEquals(sp.Stage__c,'MOU Accepted by Student');
        WithdrawalController wc2= new WithdrawalController();  
        wc2.sp=sp;
        wc2.submit(); 
        wc2.sp=null;
        wc2.submit();    
        Test.stopTest();
        }
     }
    
    private static testmethod void TestMethodWithdrawalController2(){
        User testUser = [SELECT Id,pidm__c from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
        System.runAs(testUser){
        Test.startTest();
        Contact contact= new Contact();
        contact.LastName=UserInfo.getLastName();
        contact.FirstName=UserInfo.getFirstName();
        contact.pidm__c=testUser.pidm__c;
        insert contact;
        StudentProcess__c sp1=new StudentProcess__c();
        sp1.name='Test sp';
        sp1.student__c=contact.id;
        sp1.Stage__c='MOU Accepted by Student';
        sp1.ApplicationReceived__c=System.now();
        sp1.reason__c='Demonstration Teaching (DT);Military;Nursing Clinical Alignment;Pers Circ - Bereavement';    
        WithdrawalController wc= new WithdrawalController();    
        wc.sp=sp1;
        wc.submit();
        wc.cancel();      
        Test.stopTest();
        }
     }
}