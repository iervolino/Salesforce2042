@isTest
private class TestADAFormController{

static testmethod void ADAFormControllerTestMethod(){
    Test.startTest();

        ADAFile__c d= new ADAFile__c();
        d.Name = 'test';
        insert d;
        
        PageReference pr = Page.ADAFormVF2;
        Test.setCurrentPage(pr);
    
        ApexPages.StandardController controller = new ApexPages.StandardController(d);
        
        ADAFormController ada = new ADAFormController(controller);
        ada.submit();
        ada.cancel();
        ada.homepage();
       
        
    Test.stopTest();
    }
    static testmethod void ADAFormControllerCancelTestMethod(){
    Test.startTest();

        ADAFile__c d= new ADAFile__c();
        d.Name = 'test1';
        insert d;
        
        PageReference pr = Page.ADAFormVF2;
        Test.setCurrentPage(pr);
    
        ApexPages.StandardController controller = new ApexPages.StandardController(d);
        
        ADAFormController ada = new ADAFormController(controller);
        ada.studentinfo = null;
        ada.submit();
        
       
        
    Test.stopTest();
    }
 }