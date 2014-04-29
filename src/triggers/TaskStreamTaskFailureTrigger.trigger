Trigger TaskStreamTaskFailureTrigger on TaskStreamTaskFailure__c (before insert)
{
    //Maps the Student and Task Stream Assessment Master-Detail fields
    Taskstreamutility.processLookUpFieldsOfTaskFailures(trigger.new);
}