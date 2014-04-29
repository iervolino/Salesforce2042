/*
This Controller is for TranscriptAppealCase VF page.
Author- Bhavadeep Raavi

*/

public with sharing class TranscriptAppealCaseController {
    public TransferEvaluation__c tEvaluation{get;set;}
    public String accId{get;set;}
    public String conId{get;set;}
    public String evalId{get;set;}
    public Boolean flag{get;set;}
    public Boolean appealFlag{get;set;}
    public TranscriptAppealCaseController(ApexPages.StandardController controller) {
        evalId = ApexPages.currentPage().getParameters().get('Id');
        tEvaluation = new TransferEvaluation__c();
        tEvaluation = [SELECT Id, Opportunity__r.AccountId,StudentEmail__c,EvaluationStatus__c FROM TransferEvaluation__c WHERE Id = :evalId];       
        
        accId = tEvaluation.Opportunity__r.AccountId;
        conId = [SELECT StudentContact__c FROM Account WHERE Id = :accId].StudentContact__c;
                
    }

   public PageReference SaveAppeal(){
        
        //RecordType RecordTypeObj = [Select Id, SobjectType, Name, DeveloperName From RecordType where sobjecttype ='Case' and DeveloperName='Transcripts'];
        String scURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + evalId;
        StudentCase__c sc = new StudentCase__c(Contact__c = conId, TransferEvaluation__c = evalId, StudentCaseReason__c = 'Appeal', ParentURL__c = scURL);
        insert sc;
        tEvaluation.EvaluationStatus__c = 'Appealed';
        Update tEvaluation;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Your Appeal has been Saved'));
        flag =true;
        return null;
    
    }
    public PageReference Cancel(){
        return new PageReference('/'+evalId);
    }
}