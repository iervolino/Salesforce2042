/*
Test class  for ProgramChange Controller
Author- Bhavadeep Raavi
*/


@isTest
private with sharing class TestProgramChangeController{
    
    private static testmethod void TestMethodProgramChangeController(){
       
        Contact contact= new Contact();
        contact.LastName='Test Cont';
        insert contact;
       
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.Stage__c='MOU Accepted by Student';
        insert sp;
        
        User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
        
        System.runAs(testUser){
            Test.startTest();
            PageReference pr = Page.ProgramChange;
            //pr.getParameters().put('StudentProcessAutoNumber__c',sp.StudentProcessAutoNumber__c);
            Test.setCurrentPage(pr);
            ApexPages.StandardController sc = new ApexPages.StandardController(sp);
            ProgramChangeController rac= new ProgramChangeController(sc);    
            rac.approveNonPCE();
            rac.approvePCE();
            rac.cancel();  
            
            rac.q1='Yes';
            rac.q2='Yes';
            rac.q3='Yes';
            rac.q4='Yes';
            rac.q5='Yes';
            rac.approveNonPCE();
            
            rac.stdProcess.Name=null;
            rac.q4='No'; 
            rac.approveNonPCE();
            rac.approvePCE(); 
            System.assertEquals('Test Cont',contact.LastName);
            System.assertEquals('Test sp',sp.name);
            rac.stdProcess=null;
            rac.approveNonPCE();
            rac.approvePCE(); 
            Test.stopTest();
        }
    }
}