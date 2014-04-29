/*
Test class  for IncompleteCourseSubmissionController
Author- Bhavadeep Raavi
*/


@isTest
private with sharing class TestIncompleteCourseSubmissionController {
    
    private static testmethod void TestMethodIncompleteCourseSubmissionController (){
       
        Contact contact= new Contact();
        contact.LastName='Test Cont';
        insert contact;
       
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.Stage__c='MOU Accepted by Student';
        insert sp;
        
       // User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
        
   
            Test.startTest();
            PageReference pr = Page.IncompleteCourseSubmission;
            //pr.getParameters().put('StudentProcessAutoNumber__c',sp.StudentProcessAutoNumber__c);
            Test.setCurrentPage(pr);
            ApexPages.StandardController sc = new ApexPages.StandardController(sp);
            IncompleteCourseSubmissionController ics= new IncompleteCourseSubmissionController(sc);    
            ics.getNextPage();
        }
 }