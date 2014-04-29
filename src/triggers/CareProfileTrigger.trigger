trigger CareProfileTrigger on Opportunity (after insert, after update) 
{
    // Update 4-25-2014 - Added the following for the Orientation group.  If the opportunity was moved to the stage 'CLRD - Cleard to Start',
    // it will call a separate class to build a new Orientation record
    if (triggerPass.firstRun) {
        for (Opportunity opp:Trigger.new)
        {
            // Test that status is CLRD first this avoids the null pointer that shows up 
            // if this is a new record and doesn't have a previous value for care status.
            if(Trigger.newMap.get(opp.id).CareStatus__c == 'CLRD - Cleared to Start'
              && Trigger.oldMap.get(opp.id).CareStatus__c != Trigger.newMap.get(opp.id).CareStatus__c)
              {
              CAREForceOrientation.createOrientation(Trigger.newMap);
              triggerPass.firstRun=false;
              }
        }
    }
    // end Orientation check

    // If a Synchronize To Banner Object does notexist on the opportunity, create it and assign it in a future method.
    if (Trigger.isAfter) {
        Set<Id> ids = new Set<Id>();
        Map<Id, Opportunity> opportunitiesToProcess = new Map<Id, Opportunity>();
        
        for (Opportunity opp : Trigger.new) {
            ids.add(opp.Id);
            opportunitiesToProcess.put(opp.Id, opp);
        }
        
        List<SynchronizeToBanner__c> syncs = [SELECT Id, ActiveOpportunity__c FROM SynchronizeToBanner__c WHERE ActiveOpportunity__c = :ids];
        
        for (SynchronizeToBanner__c sync : syncs) {
            opportunitiesToProcess.remove(sync.ActiveOpportunity__c);
        }

        CAREforceUtility.processCAREProfilesForSynchronization(JSON.serialize(opportunitiesToProcess.values()));      
        
        // CAREforce SynchronizeToBanner update on Opportunity Insert/Update Change. This function triggers a formula update that should always occur no
        // matter what the change is to this object. No conditions are required. This is a future method. Single SOQL read operation only.
        
        Set<String> allIds = new Set<String>();
        
        for (Opportunity opp : Trigger.new) {
            allIds.add(opp.Id);
        }
        
        if (System.isFuture() || Limits.getFutureCalls() > 3) {
            CAREforceUtility.updateSynchronizeToBannerSync('Opportunity', allIds);          
        } else {
            CAREforceUtility.updateSynchronizeToBanner('Opportunity', allIds); 
        }
    }

    ////This portion will cancel any active transcript evaluations when an Opportunity is set to NAMT status - Will Slade///
    if (Trigger.isAfter)
    {       
        //Create a list of records in trigger that are NAMT status
        List<Opportunity> oppListNAMT = [SELECT Id, CAREStatus__c
                                         FROM Opportunity
                                         WHERE Id IN :Trigger.new
                                         AND CAREStatus__c = 'NAMT - Not Admitted'
                                         AND isDeleted = false];
                                        
        if (oppListNAMT.size() > 0)                                         
        {
            List<Id> oppIds = new List<Id>();
            //Create a list of NAMT IDs            
            for (Opportunity opp : oppListNAMT)
            {
                oppIds.add(opp.Id);
            }
            
            //Query transcript evaluations to see if there are any active for these opportunities
            List<TransferEvaluation__c> evalsToCancel = [SELECT Id
                                                         FROM TransferEvaluation__c
                                                         WHERE Opportunity__c IN :oppIds
                                                         AND (NOT EvaluationStatus__c IN ('Canceled', 'Complete', 'Sent'))];
            if (evalsToCancel.size() > 0)
            {   
                if (Test.isRunningTest())
                {
                    CARENoAdmitUtility.cancelTransferEvals (JSON.serialize(evalsToCancel), true);    
                }                                                                                  
                CARENoAdmitUtility.cancelTransferEvals (JSON.serialize(evalsToCancel));                                                                         
            }
        }                                                 
    }
    
/////////////////////////////// Begin Mark Ready For Banner Push Section /////////////////////////////////    
    if (Trigger.isAfter && Trigger.isUpdate)
    {
        ContactToBannerUtilities.updateBannerReady(JSON.serialize(Trigger.old), JSON.serialize(Trigger.new));
        CAREforceIntegrationUtility.sendExternalNotificationOnUpdate(JSON.serialize(Trigger.old), JSON.serialize(Trigger.new));
    }
//////////////////////////////// End Mark Ready For Banner Push Section //////////////////////////////////

/////////////////////////////// Begin create OpportunityToBanner Section ////////////////////////////////    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        if(OpportunityToBannerUtility.firstRun == true){
            OpportunityToBannerUtility.createOpportunityToBanner(JSON.serialize(Trigger.new));
            OpportunityToBannerUtility.firstRun = false;
        }
    }
/////////////////////////////// End create OpportunityToBanner Section //////////////////////////////////
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        if(OpportunityToBannerUtility.firstCheck == true){
            OpportunityToBannerUtility.updateStatus(JSON.serialize(Trigger.new));
            OpportunityToBannerUtility.firstCheck = false;
        }
    }
    
}