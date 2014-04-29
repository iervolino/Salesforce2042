trigger StudentCaseTrigger on StudentCase__c (after insert)//, after update) 
{
    if (trigger.isAfter && trigger.isInsert)
    {
        StudentCaseUtility.relateCaseToStudentCase(JSON.serialize(Trigger.new), JSON.serialize(Trigger.old));
    }
    
    /*if (trigger.isAfter && trigger.isUpdate)
    {
        List<StudentCase__c> recordsOfInterest = [SELECT Id FROM StudentCase__c WHERE Id IN :Trigger.new];
        StudentCaseUtility.updateCaseFromStudent(JSON.serialize(Trigger.new), JSON.serialize(Trigger.old));
    }*/
}