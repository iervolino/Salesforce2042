/*
This Test Class is for TranscriptExclusionCaseController.
Author- Bhavadeep Raavi
    -Modified by Will Slade 1/24/13 to comply with person account refactor
*/

@isTest
private class TestTranscriptExclusionCaseController {

static testmethod void TranscriptExclusionCaseControllerTestMethod(){
    Test.startTest();
    
    PageReference pr = Page.TranscriptExclusionCase;
    Test.setCurrentPage(pr);
    Contact con = new Contact();
    con.FirstName = 'testCon';
    con.LastName='testTact';
    con.RecordTypeId = [Select Id from RecordType where Name = 'StudentRecord' and SObjectType = 'Contact'].id;
    insert con;
    system.assertEquals('testTact', con.LastName);
    
    //ID studentRecordTypeId = [Select Id from RecordType where Name = 'Student Account' and SObjectType = 'Account'].id;    
    //acc.RecordTypeId = studentRecordTypeId ;
    //acc.LastName='TestAcc';
    //acc.StudentContact__c =con.Id;
    //insert acc;
    Account acc = [SELECT Id, Name, StudentContact__c FROM Account WHERE StudentContact__c = :con.Id]; //new Account();
    system.assertEquals('testCon testTact', acc.Name);
    system.assertEquals(acc.StudentContact__c, con.Id);
    
    Opportunity opp = new Opportunity();
    opp.Name='Test Opp';
    opp.AccountId=acc.Id;
    opp.StageName='Prospect';
    opp.CloseDate=Date.Today();
    insert opp;
    system.assertEquals('Test Opp',opp.Name);
    
    StudentTranscript__c st= new StudentTranscript__c();
    st.Opportunity__c = opp.Id;
    st.TranscriptStatus__c='Appealed';
    insert st;
    system.assertEquals('Appealed', st.TranscriptStatus__c);
    
    pr.getParameters().put('Id', st.Id);
    ApexPages.StandardController stdController = new ApexPages.StandardController(st);
    TranscriptExclusionCaseController tecc= new TranscriptExclusionCaseController(stdController ); 
    tecc.SaveExclusion();
    tecc.Cancel();  
    
    Test.stopTest();
} 

}