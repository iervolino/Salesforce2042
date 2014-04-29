/* 
Utility class for MethodOfPaymentTrigger.
Author- Bhavadeep Raavi
Modified by Mike Slade and Brian Johnson to add 3rd party
Sharing rules are enforced
Modified 3/18/2013 by Will Slade to use future method
*/

public with sharing class MethodOfPaymentUtility{

// To create a Financial Application for Military Funding
    public static void createFinApp( String oppIdListJSON, String recordTypeName )
    {
        if (Limits.getFutureCalls() > 8 || System.isFuture())
        {
            processCreateFinApp( oppIdListJSON, recordTypeName);
        }
        else
        {
            asyncCreateFinApp( oppIdListJSON, recordTypeName);
        }
    }
    
    @future
    private static void asyncCreateFinApp(String oppIdListJSON, String recordTypeName)
    {
        processCreateFinApp( oppIdListJSON, recordTypeName);
    }

    private static void processCreateFinApp(String oppIdListJSON, String recordTypeName )
    {
        List<Id> oppIdList = (List<Id>)JSON.deserialize( oppIdListJSON, List<Id>.class );        
        Map<Id,Id> oppFAMap = new Map<Id,Id>();
        List<FinancialApplication__c> faListNew=new List<FinancialApplication__c>();
        id RtId =[select id from RecordType 
                    where SobjectType='FinancialApplication__c'  
                    and developerName = :recordTypeName limit 1].id;
        
        List<FinancialApplication__c> faList=[select id,Opportunity__c, recordTypeId
                                              from FinancialApplication__c 
                                              where Opportunity__c in:oppIdList 
                                              and RecordtypeId=:RtId];
        for(FinancialApplication__c fa: faList)
        {
            oppFAMap.put(fa.Opportunity__c,fa.Id);    
        }
        List<Opportunity> oppList=[select id,StudentContact__c from Opportunity where id in:oppIdList];
        for(Opportunity opp: oppList){
            if((oppFAMap!=null && oppFAMap.get(opp.id)==null) || (faList.isEmpty())){
                FinancialApplication__c faNew=new FinancialApplication__c();
                faNew.Opportunity__c = opp.id;
                faNew.Student__c =opp.StudentContact__c;
                faNew.recordtypeId=RtId;
                faNew.ApplicationStatus__c='New Application';
                faListNew.add(faNew);        
            }                    
        }
        if(faListNew!=null && faListNew.size()>0){
            insert faListNew;
        }   
    
    }


}