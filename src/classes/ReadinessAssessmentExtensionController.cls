public class ReadinessAssessmentExtensionController {
    private ApexPages.StandardController controller;
    public String actionURL {set;get;}
    
    public ReadinessAssessmentExtensionController(ApexPages.StandardController controller) {
        this.controller = controller;
        
        Runtime__c domain = Runtime__c.getValues('web3_domain');
        this.actionURL = 'https://' + domain.Value__c + '/care2/AA_Assesment_Details.asp';
    }
    
    
}