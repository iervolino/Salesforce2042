/*****************************************************************************************
* Name: TestStudentCaseTrigger
* Author: Will Slade
* Purpose: Test class for StudentCaseTrigger
* Revisions: 
*    - 12/1/12 Created Class
*    - 1/24/13 Updated for person account refactor
******************************************************************************************/

@isTest
global class TestStudentCaseTrigger
{
    static testMethod void TestStudentCaseTrigger()
    {
        CAREProgram__c testCAREProgram = new CAREProgram__c(Name = 'TestCAREProgram124');
        insert testCAREProgram;
        
        WGUDegreeProgram__c testWGUDegreeProgram = new WGUDegreeProgram__c(Name = 'TestWGUDegreeProgram124', PAMSID__c = 124124124);
        insert testWGUDegreeProgram;       
        
        CAREProgramMiddleEarth__c testCAREProgramMiddleEarth = new CAREProgramMiddleEarth__c(CareProgramCode__c = testCAREProgram.Id, BannerProgramCode__c = testWGUDegreeProgram.Id);
        insert testCAREProgramMiddleEarth;
        
        RecordType RTA = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Institution of Higher Ed'];             

        Contact newContact = new Contact(Status__c='AS', Pidm__c='QA002233', FirstName='Dudley', LastName='FEEmailTest',
                                         RecordTypeId = [Select Id from RecordType where Name = 'StudentRecord' and SObjectType = 'Contact'].id);
        insert newContact;
        
        newContact = [SELECT Id, Status__c, Pidm__c, FirstName, LastName, Account.Id FROM Contact WHERE Id = :newContact.Id LIMIT 1];
        Account acct = [SELECT Id, Pidm__c, StudentContact__c FROM Account WHERE Id = :newContact.Account.Id];              
        
        System.assert( newContact.AccountId != null && newContact.AccountId == acct.Id );        
        System.assert( acct.id != null );
        System.assert( newContact != null && newContact.id != null );
        System.assert( newContact.pidm__c == acct.pidm__c );                    
        
        System.assertEquals(acct.StudentContact__c, newContact.Id);
        
        Account acct2 = new Account(Name = 'TestWeber1', RecordTypeId = RTA.Id);        
        insert acct2;
        
        Contact testContact = new Contact(FirstName = 'Willtest1', Lastname = 'Slayedtest1', Email = 'wslayed@my.wgu.edu', Account = acct);        
        insert testContact;        
        
        Opportunity testOpportunity = new Opportunity(Name = 'testEvalCourseTriggerOpp', CloseDate = Date.Today(), StageName = 'Applicant', 
                                                      Account = acct, MarketingProgram__c = testCAREProgramMiddleEarth.Id);
        insert testOpportunity;
 
        TransferEvaluation__c testTransferEvaluation = new TransferEvaluation__c(Name = 'testTransferEval124', Opportunity__c = testOpportunity.Id, EvaluationStatus__c = 'Pending');
        insert testTransferEvaluation;        
        
        StudentTranscript__c testInstitution = new StudentTranscript__c(Opportunity__c = testOpportunity.Id);
        insert testInstitution;
        
        StudentCase__c testStudentCase = new StudentCase__c(Contact__c = testContact.Id, TransferEvaluation__c = testTransferEvaluation.Id, StudentCaseReason__c = 'Appeal', 
                                                            ParentURL__c = 'http://www.espn.com');
        Test.startTest();
        insert testStudentCase;
        Test.stopTest();
        String scId = testStudentCase.Id;
        testStudentCase = [SELECT Id, Contact__c, TransferEvaluation__c, StudentCaseReason__c, Case__c FROM StudentCase__c WHERE Id = :scId];        
        
        List<Case> cases = [SELECT Id, Reason, TransferEvaluation__c FROM Case WHERE TransferEvaluation__c = :testStudentCase.TransferEvaluation__c LIMIT 1];
        System.assert(cases.size() > 0);
        System.assertEquals(testStudentCase.Case__c, cases[0].Id);
    }
}