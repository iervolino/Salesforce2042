trigger ContactToBannerTrigger on ContactToBanner__c (after insert, after update) {
    // Check the first record in the insert and see if it has a last synchronized from banner. 
    // If it doesn't then it was created in Salesforce and should be ignored because it is created by Contact.    
    if (Trigger.isAfter && ((Trigger.isInsert && Trigger.New[0].LastNameIN__c != null) || Trigger.isUpdate)) {
        // Asynchronise call to set values in Contact.
        if (Limits.getFutureCalls() > 5 || System.isFuture() || System.isBatch() || System.isScheduled()) {
            ContactToBannerUtilities.updateContactsSync(JSON.serialize(Trigger.Old), JSON.serialize(Trigger.New));          
        } else {
            try {
                ContactToBannerUtilities.updateContacts(JSON.serialize(Trigger.Old), JSON.serialize(Trigger.New));
            } catch (Exception e) {
                ContactToBannerUtilities.updateContactsSync(JSON.serialize(Trigger.Old), JSON.serialize(Trigger.New));
            }
        }
    }
    
/////////////////////////// Begin Notify Student Attributes and Opportunity Control Records //////////////////////////
    if (Trigger.isAfter && Trigger.isUpdate)
    {
        List<ContactToBanner__c> newPIDMList = new List<ContactToBanner__c>();
        
        for (ContactToBanner__c ctb : Trigger.new)
        {
            if ((''.equals(Trigger.oldMap.get(ctb.Id).pidmFromBannerIN__c)
                || Trigger.oldMap.get(ctb.Id).pidmFromBannerIN__c == null)
                && !''.equals(ctb.pidmFromBannerIN__c)
                && ctb.pidmFromBannerIN__c != null)
            {
                newPIDMList.add(ctb);
            }
        }
        
        if (newPIDMList.size() > 0)
        {
            ContactToBannerUtilities.notifyRelatedObjects(JSON.serialize(newPIDMList));
        }
    }
//////////////////////////// End Notify Student Attributes and Opportunity Control Records ///////////////////////////
    
    if(Trigger.isAfter &&(Trigger.isInsert || Trigger.isUpdate)){
        ContactToBannerUtilities.updateOpportunityPidm(JSON.serialize(Trigger.New));
    }
}