/*****************************************************************************************
* Name: IntakeInterviewFlowController
* Author: Will Slade
* Purpose: Test IntakeInterviewFlowController
* Revisions: 
*    - 6/1/12 Created Class
*    - 1/24/13 Updated for person account refactor
******************************************************************************************/

@isTest
Public class TestIntakeInterviewFlowController 
{
    @IsTest
    public static void testIntakeInterviewFlowController() 
    { 
             
        /*Account student = new Account( Status__pc='AS', pidm__c='QA002233', pidm__pc='QA002233', firstName='Dudley', personEmail='FEEmailTest@test.com', personMailingState='UT', LastName='StudleyIntake', RecordTypeId = [Select Id from RecordType where Name = 'Student Account' and SObjectType = 'Account'].id );
        insert student;
        student = [Select Id, MentorPidm__pc, Mentor__pc, StudentMentor__pc, FirstName, LastName, PersonEmail, PersonContactId, RecordTypeId, Pidm__c, StudentContact__c, isPersonAccount, PersonMailingState, Status__pc from Account where ID = :student.Id LIMIT 1].get(0);
        */
        Contact newContact = new Contact(Status__c='AS', Pidm__c='QA002233', FirstName='Dudley', LastName='FEEmailTest',
                                         RecordTypeId = [Select Id from RecordType where Name = 'StudentRecord' and SObjectType = 'Contact'].id);
        insert newContact;
        
        newContact = [SELECT Id, Status__c, Pidm__c, FirstName, LastName, Account.Id FROM Contact WHERE Id = :newContact.Id LIMIT 1];
        Account newAccount = [SELECT Id, Pidm__c, StudentContact__c FROM Account WHERE Id = :newContact.Account.Id];              
        
        System.assert( newContact.AccountId != null && newContact.AccountId == newAccount.Id );
        
        System.assert( newAccount.id != null );
        System.assert( newContact != null && newContact.id != null );
        System.assert( newContact.pidm__c == newAccount.pidm__c );                    
        
        System.assertEquals(newAccount.StudentContact__c, newContact.Id);
        
        Account Institution = new Account (Name='DCS University', RecordTypeId = [Select Id from RecordType where Name = 'Institution of Higher Ed' and SObjectType = 'Account'].id);
        insert Institution;
        Institution = [Select Id, Name from Account where ID = :Institution.Id LIMIT 1].get(0);
        
        Opportunity care = new Opportunity(AccountId=newAccount.Id, Name='Dudley Schults', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        insert care;
        care = [select id, AccountId from Opportunity where id = :care.id];
        
        StudentTranscript__c transcript = new StudentTranscript__c (Opportunity__c=care.id, CollegeEndDate__c=date.today(), CollegeStartDate__c=date.today(), Contact__c=newAccount.StudentContact__c, TranscriptInstitution__c=Institution.Id);
        insert transcript;
        
        System.assert(transcript.Opportunity__c != null);
        System.assertEquals(transcript.Opportunity__c, care.Id);
               
        PageReference pageTest0 = Page.IntakeInterview;
        pageTest0.getParameters().put('Id',null);
        Test.setCurrentPage(pageTest0);
        ApexPages.Standardcontroller stdcon0 = new ApexPages.Standardcontroller(care);
        IntakeInterviewFlowController con = new IntakeInterviewFlowController(stdcon0);

        PageReference pageTest1 = Page.IntakeInterview;
        pageTest1.getParameters().put('Id',care.id);
        Test.setCurrentPage(pageTest1);
        
        List<StudentTranscript__c> transcripts = con.getMyTranscripts();
        Opportunity testOpp = con.getTestOpp();
        
        System.assert(testOpp.Id != null);
        System.assertEquals(testOpp.Id, care.Id);
        //System.assert(transcripts.size() == 1);
        //System.assert(transcripts.get(0).Contact__c == newAccount.StudentContact__c);
    }
}