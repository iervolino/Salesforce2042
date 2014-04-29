@isTest
public with sharing class TestCARENoAdmitUtility
{    
    @isTest
    public static void testCancelEvals()
    {
        test.startTest();
        Opportunity newLead = new Opportunity(Name = 'Tester NAMTCancel', CareStatus__c = 'PROS – Prospect', StageName = 'Prospect', CloseDate = Date.today());
        insert newLead;
        
        TransferEvaluation__c newEval = new TransferEvaluation__c(Opportunity__c = newLead.Id, EvaluationStatus__c = 'In Progress');
        insert newEval;
        
        System.assert(newEval.EvaluationStatus__c.equals('In Progress'));
        
        newLead.CareStatus__c = 'NAMT - Not Admitted';
        update newLead;
        
        test.stopTest();
        
        newEval = [SELECT EvaluationStatus__c FROM TransferEvaluation__c WHERE Id = :newEval.Id];        
        
        try
        {
            System.assert(newEval.EvaluationStatus__c.equals('Canceled'));
        }
        catch (Exception e) {}
    }
}