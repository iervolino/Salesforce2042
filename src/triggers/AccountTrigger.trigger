/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Created Aug 1 2013 @ 1320 hrs

 * Account object's Trigger class
 *
 * 
 * Date Sep 20, 2013
 * Revised: Modify contact creation and contact--account 2 way association to AFTER INSERT. Also, delete contacts whenever delete THEIR PARENT account. - Yemeng Zhu 
 *
 *
 * Date Apr 28, 2014
 * Edit the test case and it nolonger test governer limit of insert 200+ records.
 * Caution: If you made any change on this trigger, make sure test your change by insert/update at least 200 records at one time without hit governer limit.  
 *
 *
 */
trigger AccountTrigger on Account (after update,after insert, before insert, before update) {
   
   //PUSH StudentAPI record Shares for Students after update (ONLY pushes Student Accounts with User records, i.e., isCustomerPortal = true)
   if (Trigger.isAfter && Trigger.isUpdate && !AccountUtility.isInsertAccount) {
    
      //Hand off all Updated Accounts to Utility future method
      AccountUtility.forwardAccountRecords( JSON.serialize(Trigger.New) );
        
   } 
   
   //======================= START SECTION: BEFORE INSERT|UPDATE :STOP BLEEDING====================== 
    //                          STOP BLEEDING: 
    //===============================================================================
    if (Trigger.isBefore &&  (Trigger.isUpdate || Trigger.isInsert) ) {// edit by yemeng
        for ( Account student: Trigger.new ) {
            if ( student.isInvalid__c ) { //if studentContact__c is not null but point to other contact
                 student.addError('One contact should only associate with one account, it is invalid to associate the account of student  '+student.Name + '  with the existing contact ['+student.StudentContact__c+']');
            }
        }
        
    }
   // 9-20-2013 - yemeng :if (students') account dont have a contact record, then create contact for those accouts
   if(trigger.isAfter && trigger.isInsert)
   {   AccountUtility.isInsertAccount=true;
       AccountUtility.createContactsForAccounts(Trigger.new);
       AccountUtility.isInsertAccount=false;
   }
    
}