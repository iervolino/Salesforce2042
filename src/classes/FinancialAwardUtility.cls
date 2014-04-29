/***************************************************************************************************************
*
* This class is for FinancialAwardTrigger that Rollup the Total Award Amount and update on Financial Application.
* Author- Bhavadeep Raavi
* No Sharing rules, the current sharing rules remain in effect
*    ---Modified 8/28/2012 by Will Slade to comply with @future specifications
*
****************************************************************************************************************/

public class FinancialAwardUtility
{
    public static void awardAmtRollup(String listFA)
    {
        awardAmtRollup(listFA, !Test.isRunningTest());    
    }
    
    public static void awardAmtRollup(String listFA, Boolean runFuture)
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() )
        {
            processAwardAmtRollup(listFA);
        }
        else
        {
            asyncAwardAmtRollup(listFA);
        }
    }
    
    @future
    public static void asyncAwardAmtRollup(String listFA)
    {
        processAwardAmtRollup(listFA);
    }

    public static void processAwardAmtRollup(String listFA)
    {
        List<FinancialAward__c> lstFA = (List<FinancialAward__c>) JSON.deserialize(listFA, List<FinancialAward__c>.class);
    
        Set<Id> finAppId=new Set<Id>();
        List<FinancialAward__c> AwardList;
        List<FinancialApplication__c> FAList=new List<FinancialApplication__c>();
        for(FinancialAward__c fa:lstFA)
        {
             if(fa.FinancialApplication__c!=null)
            {
                finAppId.add(fa.FinancialApplication__c); 
            }      

        }        
       
        //get aggregate list of total amounts
        AggregateResult[] groupedResults = [select sum(TermAmount__c) termAmt, sum(TotalAmount__C) totAmt,FinancialApplication__c 
                        from FinancialAward__c 
                        where FinancialApplication__c in :finAppID
                        group by FinancialApplication__c  ];
        
       Map<id, AggregateResult> awardTotalMap=new Map<id, AggregateResult>();
        for (AggregateResult ar : groupedResults) //map the results
        {
            awardTotalMap.put((ID)ar.get('FinancialApplication__c'), ar);
        }   
        
           list <FinancialApplication__c> FApps= [select id,FinancialAwardAmount__c,TotalTermAmount__c 
                                             from FinancialApplication__c 
                                             where id in :finAppId ];
               
           //Map<id,FinancialApplication__c> mapFApp=new Map<id,FinancialApplication__c>();
           for(FinancialApplication__c FApp:Fapps)
           {
              // mapFApp.put(FApp.Id,FApp);    
      
               if (awardTotalMap.get(FApp.id) != null) //if there are no awards left leave it set to 0, if not get the total amounts
               {   
                   FApp.FinancialAwardAmount__c=(decimal)awardTotalMap.get(FApp.id).get('totAmt');
                   FApp.TotalTermAmount__c=(decimal)awardTotalMap.get(FApp.id).get('termAmt');
               }
               else
               {
                  FApp.TotalTermAmount__c =0;
                  FApp.FinancialAwardAmount__c =0;
               }
 
           }
        
        if(fapps!=null)
        {
            try
            {
                update fapps; 
            }
            catch(Exception e){}   
        }
    }                
}