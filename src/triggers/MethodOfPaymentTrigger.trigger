/* 
Trigger on Method of Payment Object
Author- Bhavadeep Raavi
Modified by Mike Slade and Brian Johnson to add 3rd party
Modified 3/18/2013 by Will Slade to use future methods in utility class
*/

trigger MethodOfPaymentTrigger on MethodOfPayment__c (After Insert, After Update) 
{
    Set<String> chkVal = new Set<String>{'MTA - Military Tuition Assistance', 'VA - Veterans Assistance', 'MVR - Military Vocational Rehab'};
    Set<String> chkVal3p = new Set<String> {'3P - Third Party'};
    List<Id> oppIdsVa = new List<Id>();
    List<Id> oppIds3p = new List<Id>();
    
    for(MethodOfPayment__c mop:Trigger.new)
    {
        if(chkVal.contains(mop.PrimaryTuitionSource__c) || chkVal.contains(mop.SecondaryTuitionSource__c) || chkVal.contains(mop.ThirdTuitionSource__c))
        {
            if (mop.CAREProfile__c != null)
            {
                OppIdsVa.add(mop.CAREProfile__c);
            }    
        }
        
        if (chkVal3p.contains(mop.PrimaryTuitionSource__c) || chkVal3p.contains(mop.SecondaryTuitionSource__c) || chkVal3p.contains(mop.ThirdTuitionSource__c))
        {
            if (mop.CAREProfile__c != null)
            {
                OppIds3p.add(mop.CAREProfile__c);
            }    
        }
    }
    
    if (oppIdsVa != null && oppIdsVa.size() > 0)
    {
        MethodOfPaymentUtility.createFinApp(JSON.serialize(oppIdsVa), 'VA');
    }
    
    if (oppIds3p !=null && oppIds3p.size() > 0)
    {
        MethodOfPaymentUtility.createFinApp(JSON.serialize(oppIds3p), 'ThirdParty');
    }
}