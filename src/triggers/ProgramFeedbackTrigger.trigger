trigger ProgramFeedbackTrigger on ProgramFeedback__c (Before Insert, Before Update) 
{
///////////////////// Update Queue__c Field /////////////////////
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
    {
        Map<Id, String> ownerToTypeMap = new Map<Id, String>();
        List<Id> ownerIds = new List<Id>();
        List<QueueSObject> queueList = new List<QueueSObject>(); 
        List<Id> queueIds = new List<Id>();                             
    
        for (ProgramFeedback__c pf : Trigger.new)
        {
            ownerIds.add(pf.OwnerId); 
        }
        
        queueList = [SELECT QueueId, Queue.Name FROM QueueSObject WHERE QueueId IN :ownerIds LIMIT 100];
        
        for (QueueSObject thisQueue : queueList)
        {
            queueIds.add(thisQueue.QueueId);
            if (!ownerToTypeMap.containsKey(thisQueue.QueueId))
            {
                ownerToTypeMap.put(thisQueue.QueueId, thisQueue.Queue.Name);
            }               
        }
        
        for (ProgramFeedback__c pf : Trigger.new)
        {
            if (ownerToTypeMap.containsKey(pf.OwnerId) && pf.Queue__c != ownerToTypeMap.get(pf.OwnerId)) 
            {
                pf.Queue__c = ownerToTypeMap.get(pf.OwnerId);
            }
        }
    }        
}
/////////////////// End Update Queue__c Field ///////////////////