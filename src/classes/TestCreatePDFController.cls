/*
Test class  for CreatePDFController
Author- Bhavadeep Raavi
*/

@isTest
private with sharing class TestCreatePDFController{
     
     private static testmethod void TestCreatePDFController1(){
     
     Contact con = new Contact();
     con.LastName='testCon';
     con.FirstName ='testFname';
     con.Email='test@test.com';
     con.StudentID__c ='12345';
     con.ProgramStartDate__c =Date.Today();
     insert con;
     
     StudentProcess__c sp=new StudentProcess__c();
     sp.Name='SP Test';
     sp.Student__c=con.Id;
     sp.RequirementsCompletedOn__c =Date.Today();
     insert sp;
     
     // This code runs as the system user
     User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
      
     System.runAs(testUser){
     Test.startTest();
     PageReference pr1 = Page.createPDF;    
     Test.setCurrentPage(pr1);
     pr1.getParameters().put('Id', sp.Id);
     ApexPages.StandardController stdController1 = new ApexPages.StandardController(sp);
     CreatePDFController cpdf1= new CreatePDFController(stdController1);
     String Id1 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates'and AccessType ='Shared' LIMIT 1].Id;
     List<EmailTemplate> listEmailTemps1=[select Id,name,body,HtmlValue  from EmailTemplate where FolderId =:Id1 and name like 'RECPDF%' order By Name];
     System.debug('raavi2 '+listEmailTemps1.get(0));
     cpdf1.selET=listEmailTemps1.get(0).Id;
     cpdf1.emailContent();
     cpdf1.selET=listEmailTemps1.get(1).Id;
     cpdf1.emailContent();
     cpdf1.selET=listEmailTemps1.get(2).Id;
     cpdf1.emailContent();
     cpdf1.viewPDF();
     cpdf1.sendEmail();
     cpdf1.cancel();
     cpdf1.cancel1();
     Test.stopTest();
}
}
    private static testmethod void TestCreatePDFController2(){
     
     Contact con = new Contact();
     con.LastName='testCon';
     con.FirstName ='testFname';
     con.Email='test@test.com';
     con.StudentID__c ='12345';
     con.ProgramStartDate__c =Date.Today();
     insert con;
     
     StudentProcess__c sp=new StudentProcess__c();
     sp.Name='SP Test';
     sp.Student__c=con.Id;
     sp.RequirementsCompletedOn__c =Date.Today();
     insert sp;
     
     User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
     System.runAs(testUser){
     Test.startTest();
     
     PageReference pr = Page.createPDF;    
     Test.setCurrentPage(pr);
     pr.getParameters().put('Id', sp.Id);
     ApexPages.StandardController stdController = new ApexPages.StandardController(sp);
     CreatePDFController cpdf= new CreatePDFController(stdController );
     String Id = [Select Id from Folder where DeveloperName='RecordsEmailTemplates'and AccessType ='Shared' LIMIT 1].Id;
     List<EmailTemplate> listEmailTemps=[select Id,name,body,HtmlValue  from EmailTemplate where FolderId =:Id and name like 'RECPDF%'];
     cpdf.selET=listEmailTemps.get(0).Id;
     cpdf.emailContent();
     cpdf.viewPDF();
     cpdf.savePDF(); 
     
     System.assertEquals(con.Email,'test@test.com');
     System.assertEquals(sp.Name,'SP Test');
     
     Test.stopTest();
     }

}
    private static testmethod void TestCreatePDFController3(){
     
     Contact con = new Contact();
     con.LastName='testCon';
     con.FirstName ='testFname';
     con.Email='test@test.com';
     con.StudentID__c ='12345';
     con.ProgramStartDate__c =Date.Today();
     insert con;
     
     StudentProcess__c sp=new StudentProcess__c();
     sp.Name='SP Test';
     sp.Student__c=con.Id;
     sp.RequirementsCompletedOn__c =Date.Today();
     insert sp;
     
     User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
     System.runAs(testUser){
     Test.startTest();
     PageReference pr2 = Page.createPDF;    
     Test.setCurrentPage(pr2);
     pr2.getParameters().put('Id', sp.Id);
     ApexPages.StandardController stdController2 = new ApexPages.StandardController(sp);
     CreatePDFController cpdf2= new CreatePDFController(stdController2 );
     String Id2 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates'and AccessType ='Shared' LIMIT 1].Id;
     List<EmailTemplate> listEmailTemps2=[select Id,name,body,HtmlValue  from EmailTemplate where FolderId =:Id2 and name like 'RECPDF%' order By Name desc];
     cpdf2.selET=listEmailTemps2.get(0).Id;
     cpdf2.emailContent();
     cpdf2.viewPDF();
     cpdf2.savePDF();
     
     
     
     System.assertEquals(con.Email,'test@test.com');
     System.assertEquals(sp.Name,'SP Test');
     
     Test.stopTest();
     }

}
}