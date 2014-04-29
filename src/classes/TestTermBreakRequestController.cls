/*
Test class  for TermBreakRequestController
Author- Bhavadeep Raavi

Revised: 12/02/2013 Comment out work submitted after term and graduation application submitted questions - Kristin Hasna
*/
@isTest
private with sharing class TestTermBreakRequestController{
     
     private static testmethod void TestTermBreakRequestController(){
        User testUser = [SELECT Id,pidm__c from User WHERE Profile.Name = 'Mentor' AND isActive = true LIMIT 1];
        System.runAs(testUser){
           
        Contact contact= new Contact();
        contact.LastName=UserInfo.getLastName();
        contact.FirstName=UserInfo.getFirstName();
        contact.pidm__c=testUser.pidm__c;
        contact.studentId__c ='12345';
        contact.BalanceDue__c = true;
        insert contact;
        
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.ApplicationReceived__c=System.now();
        insert sp;
        
        
        Test.startTest();
        System.assertEquals(sp.name,'Test sp');
        
        System.assertEquals(contact.LastName,UserInfo.getLastName());
        System.assertEquals(contact.FirstName,UserInfo.getFirstName());
        
        TermBreakRequestController tb1= new TermBreakRequestController();
        tb1.stdId= '12345';
        tb1.selReqMonths ='1';
        tb1.getStudentRecord();
        tb1.sp = sp;
        /* tb1.sp.TBGradAppSubmitted__c = 'Yes';*/
        tb1.saveTermBreak();
        tb1.cancel();
        TermBreakRequestController tb2= new TermBreakRequestController();
        tb2.sp=null;
        tb2.stdId= '12345';
        tb2.getStudentRecord();
        tb2.selReqMonths ='1';
        tb2.sp.TBReason__c ='Financial';
        /*tb2.sp.WorkSubmittedAfterTerm__c ='Yes';*/
        /*tb2.sp.TBGradAppSubmitted__c ='No';*/
        tb2.sp.TBReasonComments__c = 'test';
        tb2.sp.BestTimeToContact__c ='9:00 - 10:00 AM';
        tb2.saveTermBreak();
       
        System.assertEquals(tb2.sp.TBReasonComments__c, 'test');
        System.assertEquals(tb2.sp.TBReason__c,'Financial');
        
     
        Test.stopTest();
        }
     }
    
  private static testmethod void TestTermBreakRequestController1(){
        User testUser = [SELECT Id,pidm__c from User WHERE Profile.Name = 'Student Profile' AND isActive = true LIMIT 1];
        System.runAs(testUser){
        
        
        Contact contact= new Contact();
        contact.LastName=UserInfo.getLastName();
        contact.FirstName=UserInfo.getFirstName();
        contact.pidm__c=testUser.pidm__c;
        contact.studentId__c ='12345';
        contact.BalanceDue__c = false;
        insert contact;
        
        Test.startTest();
        TermBreakRequestController tb1= new TermBreakRequestController();
        tb1.selReqMonths ='1';   
        tb1.saveTermBreak();
        tb1.cancel();
        TermBreakRequestController tb2= new TermBreakRequestController(); 
        tb2.selReqMonths = '';
        tb2.saveTermBreak();
        
        Test.stopTest();
        }
     }
     private static testmethod void TestTermBreakRequestController2(){
        User testUser = [SELECT Id,pidm__c from User WHERE Profile.Name = 'Mentor' AND isActive = true LIMIT 1];
        System.runAs(testUser){
        
           
        Contact contact= new Contact();
        contact.LastName=UserInfo.getLastName();
        contact.FirstName=UserInfo.getFirstName();
        contact.pidm__c=testUser.pidm__c;
        contact.studentId__c ='00012345';
        contact.BalanceDue__c = true;
        insert contact;
        
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.ApplicationReceived__c=System.now();
        insert sp;
        
        
        Test.startTest();
        System.assertEquals(contact.LastName,UserInfo.getLastName());
       
        TermBreakRequestController tb2= new TermBreakRequestController();
        tb2.sp=null;
        tb2.stdId= '12345';
        tb2.getStudentRecord();
        tb2.selReqMonths ='1';
        tb2.sp.TBReason__c ='Financial';
        /*tb2.sp.WorkSubmittedAfterTerm__c ='Yes';*/
        /*tb2.sp.TBGradAppSubmitted__c ='No';*/
        tb2.sp.TBReasonComments__c = 'test';
        tb2.sp.BestTimeToContact__c ='9:00 - 10:00 AM';
        tb2.saveTermBreak();
        
        System.assertEquals(tb2.sp.TBReasonComments__c, 'test');
        System.assertEquals(tb2.sp.TBReason__c,'Financial');
     
        Test.stopTest();
        }
     }
    

}