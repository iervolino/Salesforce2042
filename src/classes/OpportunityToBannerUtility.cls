public with sharing class OpportunityToBannerUtility{
    
    public static boolean firstRun = true;
    public static boolean firstCheck = true;
    
    ///////////////// START SECTION: Create OpportunityToBanner ///////////
    
    public static void createOpportunityToBanner(String listNewJSON){
        if( Limits.getFutureCalls()>3 || System.isFuture() || System.isBatch() || System.isScheduled() ){
            processCreateOpportunityToBanner(listNewJSON);
        }else{
            try{
                asyncCreateOpportunityToBanner(listNewJSON);
            }catch(Exception e){
                processCreateOpportunityToBanner(listNewJSON);
            }
        }
    }
    
    @future
    private static void asyncCreateOpportunityToBanner(String listNewJSON){
        processCreateOpportunityToBanner(listNewJSON);
    }
    
    private static void processCreateOpportunityToBanner(String listNewJSON){
        List<Opportunity> oppList = (List<Opportunity>)JSON.deserialize(listNewJSON, List<Opportunity>.class);
        List<Id> oppIdList = new List<Id>();
        Map<Id,Id> oppToCtrlMap = new Map<Id,Id>();
        List<OpportunityToBanner__c> insertList = new List<OpportunityToBanner__c>();
        
        for(Opportunity thisOpp : oppList){
            oppIdList.add(thisOpp.Id);
            oppToCtrlMap.put(thisOpp.Id, null);
        }
        
        List<OpportunityToBanner__c> oppToBanList = [ SELECT Id, Opportunity__c, CurrentStatus__c
                                                      FROM OpportunityToBanner__c
                                                      WHERE Opportunity__c IN :oppIdList ];
        for(OpportunityToBanner__c oppToBan : oppToBanList){
            oppToCtrlMap.put(oppToBan.Opportunity__c, oppToBan.Id);
        }
        
        for(Opportunity opp : oppList){
            if(oppToCtrlMap.get(opp.Id) == null){
                insertList.add( new OpportunityToBanner__c(Opportunity__c = opp.Id) );
            }
        }
        insert insertList;
    }
    
    ///////////////// END SECTION: Create OpportunityToBanner   ///////////
    
    public static void updateStatus(String newJson){
        if(Limits.getFutureCalls()>3 || System.isFuture() || System.isBatch() || System.isScheduled() ){
            processUpdateStatus(newJson);
        }else{
            asyncUpdateStatus(newJson);
        }
    }
    @future
    public static void asyncUpdateStatus(String newJson){
        processUpdateStatus(newJson);
    }
    public static void processUpdateStatus(String newJson){
        List<OpportunityToBanner__c> optbList = new List<OpportunityToBanner__c>();
        List<Opportunity> opList = (List<Opportunity>)JSON.deserialize(newJson, List<Opportunity>.class);
        List<Id> opIdList = new List<Id>();
        for(Opportunity op : opList){
            opIdList.add(op.Id);
        }
        optbList = [select id, pidmOUT__c,SynchronizationError__c from OpportunityToBanner__c
                    where Opportunity__c IN :opIdList];
        for(OpportunityToBanner__c optb : optbList){
            if(optb.PIDMOUT__c != null && optb.SynchronizationError__c != null && optb.SynchronizationError__c.startsWith('No pidm')){
                optb.SynchronizationError__c = null;
            }
        }
        update optbList;
    }
}