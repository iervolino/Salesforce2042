Trigger TaskStreamTaskTrigger on TaskStreamTask__c (before insert) {
    //fill up look up fields student__c and studentcourseregistration__c in utility class by given pidm and course code
    // utility class id:  01pe00000004Ici   
         
        Taskstreamutility.processLookUpFieldsOfTask(trigger.new );

}