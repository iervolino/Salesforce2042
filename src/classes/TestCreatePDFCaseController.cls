/*
Test class  for CreatePDFCaseController
Author- Bhavadeep Raavi
*/

@isTest
private with sharing class TestCreatePDFCaseController{
     
     private static testmethod void TestCreatePDFCaseController1(){
     
     // This code runs as the system user
     User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
      
     System.runAs(testUser)    {
          
     Contact con = new Contact();
     con.LastName='testCon';
     con.FirstName ='testFname';
     con.Email='test@test.com';
     con.StudentID__c ='12345';
     con.ProgramStartDate__c =Date.Today();
     insert con;
     
     Case cs=new Case();
     cs.Status='New';
     cs.contactId=con.Id;
     cs.Origin='Email';
     insert cs;
     
     Test.startTest();
     
     PageReference pr1 = Page.createPDFCase;    
     Test.setCurrentPage(pr1);
     pr1.getParameters().put('Id', cs.Id);
     ApexPages.StandardController stdController1 = new ApexPages.StandardController(cs);
     CreatePDFCaseController cpdf1= new CreatePDFCaseController(stdController1);
     String Id1 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates'and AccessType ='Shared' LIMIT 1].Id;
     List<EmailTemplate> listEmailTemps1=[select Id,name,body,HtmlValue  from EmailTemplate where FolderId =:Id1 and name like 'RECPDFCASE%' order By Name];
     cpdf1.selET=listEmailTemps1.get(0).Id;
     cpdf1.emailContent();
     cpdf1.viewPDF();
     cpdf1.savePDF();
     cpdf1.sendEmail();
     cpdf1.cancel();
     cpdf1.cancel1();
     
     System.assertEquals(con.Email,'test@test.com');
     System.assertEquals(cs.Status,'New');
     
     Test.stopTest();
    }
  }
}