/*****************************************************************************************
* Name: IntakeInterviewFlowController
* Author: Will Slade
* Purpose: Controller for IntakeInterviewFlow
* Revisions: 
*    - 6/1/12 Created Class
*    - 1/23/13 Changed Account.PersonContactId to Account.StudentContact__c per refactor
******************************************************************************************/

public class IntakeInterviewFlowController
{
    private final Opportunity opp;
    private List<StudentTranscript__c> myTranscripts = new List<StudentTranscript__c>();
    private Opportunity testOpp;   

    public IntakeInterviewFlowController(ApexPages.StandardController stdController) 
    {
        opp = (Opportunity)stdController.getRecord();
        List<Opportunity> opp1 = [SELECT Id, Account.StudentContact__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        if (Opp1.size() != 0)
        {     
            myTranscripts = [SELECT Id, Name, TranscriptInstitution__r.name, StartMonthYear__c, EndMonthYear__c, InstitutionCity__c, 
                             InstitutionState__c, DegreeType__c, TranscriptStatus__c, Contact__c 
                             FROM StudentTranscript__c 
                             WHERE Contact__c = :opp1[0].Account.StudentContact__c];
            testOpp = opp1[0];
        }               
    }
    
    public List<StudentTranscript__c> getMyTranscripts()
    {    
        return myTranscripts;                                                                                                                                        
    }
    
    public Opportunity getTestOpp()
    {
        return testOpp;
    }         
}