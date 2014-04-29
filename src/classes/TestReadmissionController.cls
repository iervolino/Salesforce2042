/*
Test class  for Readmission Controller
Author- Bhavadeep Raavi
*/

@isTest
private with sharing class TestReadmissionController{
    
    private static testmethod void TestMethodReadmissionController(){
        
        Contact contact= new Contact();
        contact.LastName='Test Cont';
        insert contact;
        
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.ReadmissionDesiredDate__c=Date.today();
        insert sp;
        
        User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
      
            System.runAs(testUser){
            Test.startTest();
            //sp=[select StudentProcessAutoNumber__c from StudentProcess__c where id=:sp.Id];
            PageReference pr = Page.Readmission;
            ///pr.getParameters().put('StudentProcessAutoNumber',sp.StudentProcessAutoNumber__c);
            Test.setCurrentPage(pr);
            ApexPages.StandardController sc = new ApexPages.StandardController(sp);
            ReadmissionController rac= new ReadmissionController(sc);
            rac.stdProcess.ApplicationProgramOfStudy__c='';
            rac.stdProcess.ReadmissionDesiredDate__c=null;
            rac.stdProcess.FinancePaymentType__c='';
            rac.stdProcess.ReadmissionAppeal__c='';
            rac.stdProcess.ApplicationInstitution__c ='test';
            rac.stdProcess.WaiveFee__c=false;
            rac.incrementRowFlg();
            rac.decrementRowFlg();
            rac.saveReadmission();
            rac.cancel();
            System.assertEquals('',rac.stdProcess.ApplicationProgramOfStudy__c);
            System.assertEquals('',rac.stdProcess.FinancePaymentType__c);
            rac.stdProcess.ReadmissionDesiredDate__c=Date.today().adddays(22);
            ReadmissionController.StdAdditionalInfo sai=new ReadmissionController.StdAdditionalInfo();
            sai.inName='Test';
            sai.doa=Date.today().adddays(-30)+'';
            rac.studentProcessList.add(sai);
            rac.saveReadmission();
            rac.cancel();
            Test.stopTest();
        }
    }
    private static testmethod void TestMethodReadmissionController2(){
        
        Contact contact= new Contact();
        contact.LastName='Test Cont';
        insert contact;
        
        StudentProcess__c sp=new StudentProcess__c();
        sp.name='Test sp';
        sp.student__c=contact.id;
        sp.ReadmissionDesiredDate__c=Date.today();
        insert sp;
        
        User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
      
            System.runAs(testUser){
            Test.startTest();
            //sp=[select StudentProcessAutoNumber__c from StudentProcess__c where id=:sp.Id];
            PageReference pr = Page.Readmission;
            //pr.getParameters().put('StudentProcessAutoNumber',sp.StudentProcessAutoNumber__c);
            Test.setCurrentPage(pr);
            ApexPages.StandardController sc = new ApexPages.StandardController(sp);
            ReadmissionController rac= new ReadmissionController(sc);
            rac.stdProcess.ReadmissionDesiredDate__c=Date.today().adddays(29);
            rac.stdProcess.WaiveFee__c=true;
            rac.stdProcess.FinancePaymentType__c='Self Pay';
            rac.stdProcess.ReadmissionAppeal__c='Test';
            rac.stdProcess.ApplicationInstitution__c ='test';
            rac.stdProcess.College__c='Business';
            rac.stdProcess.ProgramName__c='M.B.A.';
           
            rac.saveReadmission();
            rac.cancel();
            System.assertEquals('Self Pay',rac.stdProcess.FinancePaymentType__c);
            rac.stdProcess=null;
            rac.saveReadmission();
            
            Test.stopTest();
        }
    }
    
}