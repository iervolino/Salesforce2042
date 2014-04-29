/*
This Test Class is for TranscriptAppealCaseController.
Author- Bhavadeep Raavi
No Sharing rules are enforced, the current sharing rules remain in effect
    -Revision 1/24/13 - Will Slade - updated data creation for person account refactor    
*/


@isTest
private class TestTranscriptAppealCaseController {

static testmethod void TranscriptAppealCaseControllerTestMethod(){
    Contact con = new Contact();
    con.RecordTypeId = [Select Id from RecordType where Name = 'StudentRecord' and SObjectType = 'Contact' LIMIT 1].id;
    con.FirstName = 'testCon';
    con.LastName='testTact';
    insert con;

    Account acc = [SELECT Id, Name FROM Account WHERE StudentContact__c = :con.Id LIMIT 1]; //new Account();
    system.assertEquals('testCon testTact', acc.Name);

    Opportunity opp = new Opportunity();
    opp.Name='Test Opp';
    opp.AccountId=acc.Id;
    opp.StageName='Prospect';
    opp.CloseDate=Date.Today();
    insert opp;

    Test.startTest();
	    PageReference pr = Page.TranscriptAppealCase;
	    Test.setCurrentPage(pr);

	    system.assertEquals('Test Opp',opp.Name);

	    TransferEvaluation__c  te= new TransferEvaluation__c();
	    te.Name='test';
	    te.Opportunity__c = opp.Id;
	    te.EvaluationStatus__c='Appealed';
	    insert te;

	    system.assertEquals('Appealed',te.EvaluationStatus__c);
	    pr.getParameters().put('Id', te.Id);

	    ApexPages.StandardController stdController = new ApexPages.StandardController(te);
	    TranscriptAppealCaseController  tacc= new TranscriptAppealCaseController(stdController ); 
	    tacc.SaveAppeal();
	    tacc.Cancel();  
	        
    Test.stopTest();
} 

}