Trigger TaskStreamAssessmentTrigger on TaskStreamAssessment__c (before insert) {
    //fill up look up fields student__c in utility class by given pidm  
    // utility class id:  01pe00000004Ici   
         
        Taskstreamutility.processLookUpFieldsOfAssessment(trigger.new );

}