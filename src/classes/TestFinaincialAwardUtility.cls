/*
This test class is for code coverage for FinancialAwardUtility class and FinancialAwardTrigger
Author- Bhavadeep Raavi
Updated 02/01/2013 By Mike Slade for Person Account Refactor.  Changed to contact and added appropriate assertions
*/
@isTest(SeeAllData=false)
public class TestFinaincialAwardUtility{
private static testmethod void FinaincialAwardUtilityTest()
{
    Contact con =  TestStudentUser.getTestStudentContact();
    
    User testUser = [Select id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
    System.RunAs( testUser ) 
    {   
    Test.startTest();
    FinancialApplication__c fapp = new FinancialApplication__c(Name='Test',Student__c = con.Id ,FinancialAwardAmount__c=0,TotalTermAmount__c=0);
    insert fapp;
    
    FinancialAward__c fa = new FinancialAward__c(FinancialApplication__c =fapp.Id,TotalAmount__c=400,TermAmount__c=200);
    insert fa;
    Test.stopTest();
        
    list<financialApplication__c> fappAfter=[select FinancialAwardAmount__c,TotalTermAmount__c from financialApplication__c where id = :fapp.id];
   
    System.assert(fappAfter[0].FinancialAwardAmount__c== 400, 'Award Amount Updated');
    System.assert(fappAfter[0].TotalTermAmount__c== 200, 'Term Amount Updated');
     }

   }
    
//This method test the deletion of the award which should zero out the applciation award amount
private static testmethod void FinaincialAwardUtilityDeleteTest()
{
      Contact con =  TestStudentUser.getTestStudentContact();
    
    User testUser = [Select id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
    System.RunAs( testUser ) 
    {   
    Test.startTest();
    FinancialApplication__c fapp = new FinancialApplication__c(Name='Test',Student__c = con.Id ,FinancialAwardAmount__c=0,TotalTermAmount__c=0);
    insert fapp;
    
    FinancialAward__c fa = new FinancialAward__c(FinancialApplication__c =fapp.Id,TotalAmount__c=400,TermAmount__c=200);
    insert fa;
        
    delete fa;
   Test.stopTest();
        list<financialApplication__c> fappAfterDel=[select FinancialAwardAmount__c,TotalTermAmount__c 
                                             from financialApplication__c 
                                             where id = :fapp.id];
    System.assert(fappAfterDel[0].FinancialAwardAmount__c== 0, 'Award Amount Removed');
    System.assert(fappAfterDel[0].TotalTermAmount__c== 0, 'Term Amount Removed');
    }
}
}