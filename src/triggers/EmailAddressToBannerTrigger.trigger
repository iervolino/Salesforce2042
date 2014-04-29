trigger EmailAddressToBannerTrigger on EmailAddressToBanner__c (after insert, after update) {    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        List<EmailAddressToBanner__c> needsLinking = new List<EmailAddressToBanner__c>();
        
        for (EmailAddressToBanner__c sync : Trigger.New) {
            if (sync.EmailAddress__c == null)
            	needsLinking.add(sync);
        }
        
        // Synchronise call to set Id of EmailAddress__c or create the object and set the id.
        if (!needsLinking.isEmpty()) {
            EmailAddressToBannerUtilities.matchIdOrCreateSync(JSON.serialize(needsLinking)); 
        }
        
        // Asynchronise call to set values in EmailAddress__c.
        if (System.isFuture() || Limits.getFutureCalls() > 8) {
            EmailAddressToBannerUtilities.processUpdate(JSON.serialize(Trigger.New));          
        } else {
            EmailAddressToBannerUtilities.processUpdateSync(JSON.serialize(Trigger.New)); 
        }            
    }
}