/* 
Test Class for MethodOfPaymentUtility and MethodOfPaymentTrigger.
Author- Bhavadeep Raavi
Modified by Mike Slade and Brian Johnson to add 3rd party
*/
@isTest()
private class TestMethodOfPaymentUtility{
    
    private static testmethod void TestMethodOfPaymentUtility(){    
        Test.startTest();
            Opportunity opp1=new Opportunity();
            opp1.Name='Test Opp1';
            opp1.CloseDate=Date.Today().adddays(3);
            opp1.StageName='Prospecting';
            insert opp1;
            System.assertEquals('Test Opp1',opp1.Name);
            System.assertEquals('Prospecting',opp1.StageName);
            
            List<RecordType> lstRecVA=[select id from RecordType where SobjectType='FinancialApplication__c' and developerName='VA'];
            FinancialApplication__c fa=new FinancialApplication__c();
            fa.Name='Test FA';
            fa.Opportunity__c=opp1.id;
            fa.recordtypeId=lstRecVA.get(0).Id;
            insert fa;
            System.assertEquals('Test FA',fa.Name);
            
            MethodOfPayment__c mop=new MethodOfPayment__c();
            mop.CAREProfile__c=opp1.Id;
            mop.PrimaryTuitionSource__c='MTA - Military Tuition Assistance';
            insert mop;
            System.assertEquals('MTA - Military Tuition Assistance',mop.PrimaryTuitionSource__c);
            
            List<FinancialApplication__c> faList=[select id,Opportunity__c from FinancialApplication__c where Opportunity__c =:opp1.Id and RecordtypeId=:lstRecVA.get(0).Id];    
            System.assertEquals(1,faList.size());
            
            Opportunity opp2=new Opportunity();
            opp2.Name='Test Opp2';
            opp2.CloseDate=Date.Today().adddays(3);
            opp2.StageName='Prospecting';
            insert opp2;
            System.assertEquals('Test Opp2',opp2.Name);
            System.assertEquals('Prospecting',opp1.StageName);
                
            MethodOfPayment__c mop1=new MethodOfPayment__c();
            mop1.CAREProfile__c=opp2.Id;
            mop1.PrimaryTuitionSource__c='MTA - Military Tuition Assistance';
            mop1.SecondaryTuitionSource__c = '3P - Third Party';
            insert mop1;
            System.assertEquals('MTA - Military Tuition Assistance',mop.PrimaryTuitionSource__c);
        Test.stopTest();
            List<FinancialApplication__c> faList1=[select id,Opportunity__c from FinancialApplication__c where Opportunity__c =:opp2.Id and RecordtypeId=:lstRecVA.get(0).Id];    
            System.assertEquals(1,faList1.size());                    
    }

}