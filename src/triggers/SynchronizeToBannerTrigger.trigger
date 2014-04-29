trigger SynchronizeToBannerTrigger on SynchronizeToBanner__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        try {    
            CAREforceUtility.updateValuesFromPushToBanner(JSON.serialize(Trigger.New), JSON.serialize(Trigger.Old));   
        } catch(AsyncException ex) {
            // Do nothing, should not fire on existing future call.
        } 
    }    
    
    if (Trigger.isAfter) {
        // CAREforce SynchronizeToBanner update on SynchronizeToBanner Insert/Update Change. This function triggers a formula update that should always occur no
        // matter what the change is to this object. No conditions are required. This is a future method. Single SOQL read operation only.
        
        Set<String> allIds = new Set<String>();
        
        for (SynchronizeToBanner__c sync : Trigger.new) {
            allIds.add(sync.Id);
        }
        
        if (System.isFuture() || Limits.getFutureCalls() > 8) {
            CAREforceUtility.updateSynchronizeToBannerSync('SynchronizeToBanner', allIds);          
        } else {
            CAREforceUtility.updateSynchronizeToBanner('SynchronizeToBanner', allIds); 
        }   
    }
}