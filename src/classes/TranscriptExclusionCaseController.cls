/*
This Controller is for TranscriptExclusionCase VF page.
Author- Bhavadeep Raavi

*/

public with sharing  class TranscriptExclusionCaseController {
    public StudentTranscript__c sTranscript{get;set;}
    public String accId{get;set;}
    public String conId{get;set;}
    public String sTranscriptId{get;set;}
    public Boolean flag{get;set;}
    
    public TranscriptExclusionCaseController(ApexPages.StandardController controller) {
        sTranscriptId= ApexPages.currentPage().getParameters().get('Id');
        sTranscript= new StudentTranscript__c();
        sTranscript= [SELECT Id, Opportunity__r.AccountId,TranscriptStatus__c FROM StudentTranscript__c WHERE Id = :sTranscriptId];       
        accId = sTranscript.Opportunity__r.AccountId;
        conId = [SELECT StudentContact__c FROM Account WHERE Id = :accId].StudentContact__c;

    }
    public PageReference SaveExclusion(){
        
        //RecordType RecordTypeObj = [Select Id, SobjectType, Name, DeveloperName From RecordType where sobjecttype ='Case' and DeveloperName='Transcripts'];
        String scURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sTranscriptId;
        StudentCase__c sc = new StudentCase__c(Contact__c = conId,StudentCaseReason__c = 'Exclusion', ParentURL__c = scURL,StudentTransferInstitution__c=sTranscriptId);
        insert sc;
        sTranscript.TranscriptStatus__c = 'Appealed';
        Update sTranscript;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Your Appeal has been Saved'));
        flag =true;
        return null;
    
    }
    public PageReference Cancel(){
        return new PageReference('/'+sTranscriptId);
    }
    

}