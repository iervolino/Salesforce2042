trigger StudentCompletionTaskTrigger on StudentCompletionTask__c ( before insert, before update,after insert, after update) {
     if (Trigger.isBefore){
          if (Trigger.isInsert || Trigger.isUpdate) {
                Map<String, String> pidmMap = new Map<String, String>();
                List<String> studentPidms = new List<String>();
                Map<String, String> completionMap = new Map<String, String>();
                List<String> completionCodes = new List<String>();
        
                for (StudentCompletionTask__c task : Trigger.new) {
                    if (task.studentpidm__c != null) {
                        studentPidms.add(task.studentpidm__c);
                    }
                    if (task.name != null) {
                        completionCodes.add(task.name);
                    }
                }
                if(!studentPidms.isEmpty()){
                    List<Contact> contacts = [
                      select Id, pidm__c
                      from Contact
                      where pidm__c in :studentPidms
                    ];
                    for(Contact contact : contacts){
                        pidmMap.put(contact.pidm__c, contact.id);
                    }
                }               
                if (!completionCodes.isEmpty()) {
                    List<WGUCourseCompletionTask__c> tasks = [
                      select Id, Name
                      from WGUCourseCompletionTask__c
                      where Name in :completionCodes
                    ];
                    for(WGUCourseCompletionTask__c task : tasks){
                        completionMap.put(task.name, task.id);
                    }
                }
                for(StudentCompletionTask__c task : Trigger.new) {                
                    if(task.studentpidm__c != null) {                    
                        task.student__c = pidmMap.get(task.studentpidm__c);
                    }
                    if (task.name != null) {
                        task.wguCourseCompletionTask__c = completionMap.get(task.name);
                    }
                }
            }
        
            // Mark task as complete id passed or given equivalent credit.
            for (StudentCompletionTask__c task : Trigger.new) {
                if (task.assessmentStatus__c == 'Passed'
                    || task.assessmentStatus__c == 'Waived'
                    || task.assessmentStatus__c == 'Transferred'
                    || task.assessmentStatus__c == 'Requirement Satisfied'
                    || task.assessmentStatus__c == 'Requirement Met')
                    task.requirementComplete__C = true;
                else
                    task.requirementComplete__C = false;
            }
             
     
     
     }
    
    //Will S - functionality to send Field Experience emails via field update 8-15-2012 - merged from SendPCEEmailTrigger
    else if (Trigger.isAfter)
    {
        if ( [SELECT COUNT() 
             FROM StudentCompletionTask__c 
             WHERE Id IN :Trigger.new 
             AND Name IN ('FHT4', 'EEC1', 'MZC1', 'ABP1')
             AND Student__r.InitialFEEmailSent__c = FALSE 
             AND isDeleted = false
             AND RequirementComplete__c = True] > 0 )
        {
            PCEUtility.updateContactPCEEmailSent (JSON.serialize(Trigger.new), JSON.serialize(Trigger.old));    
        }
        
        if ( [SELECT COUNT() 
             FROM StudentCompletionTask__c 
             WHERE Id IN :Trigger.new 
             AND Name = 'SFAW'
             AND Student__r.SFAWEmailSent__c = FALSE 
             AND isDeleted = false
             AND RequirementComplete__c = True] > 0 )
        {
             PCEUtility.updateContactSFAWEmailSent (JSON.serialize(Trigger.new), JSON.serialize(Trigger.old));
        }                     
    }       
}