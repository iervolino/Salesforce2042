/*****************************************************************************************
* Name: TestStudentProcessUtility
* Author: Will Slade
* Purpose: Testing for Student Process Utility class and Trigger
* Revisions: 
*    1-1-2013 - Created Class
*    4-1-2013 - Updated for validation rules - Julio Rojo
*    5-31-2013 - Updated to add testing for withdrawals
*
******************************************************************************************/

@isTest
private class TestStudentProcessUtility
{
    /**
    * Verify that User Account is Created for contacts applying for readmission
    */
    static testMethod void testInsertReadmission()
    {
        RecordType record = [SELECT id FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'StudentRecord'];
        RecordType sprt = [SELECT id FROM RecordType WHERE sObjectType = 'StudentProcess__c' AND DeveloperName = 'Readmission'];
        //Test.startTest();
        Contact testContact = new Contact(RecordTypeId = record.Id, FirstName = 'Test', LastName = 'ContactReadmission', PIDM__c = 'test12', Status__c = 'DR');
        insert testContact;
        //Test.stopTest();
        
        List<Account> testAccount = [SELECT id, isCustomerPortal FROM Account WHERE StudentContact__c = :testContact.Id LIMIT 1];
        
        System.assert(testAccount.size() != 0);
        
        List<User> testUser = [SELECT id FROM User WHERE Contact.Id = :testContact.Id];
        
        System.assert(testUser.size() == 0);
        System.assert(testAccount[0].isCustomerPortal == false);
        
        //TODO Create and insert new Student Process
        StudentProcess__c studentProcess = new StudentProcess__c(RecordTypeId = sprt.Id, Student__c = testContact.Id, Stage__c = 'Requested', HoldsExist__c = 'No');
        
        Test.startTest();
        insert studentProcess;
        Test.stopTest();
        
        testAccount[0] = [SELECT isCustomerPortal FROM Account WHERE Id = :testAccount[0].Id];
        testUser = [SELECT id FROM User WHERE Contact.Id = :testContact.Id];
        
        //TODO Assert that the user record was created again and the field is now true
        System.assertEquals(testAccount[0].isCustomerPortal, true);
        System.assert(testUser.size() > 0);
        
        testContact = [SELECT id, Status__c FROM Contact WHERE Id = :testContact.Id];
        
        System.assertEquals(testContact.Status__c, 'DR');
    }
    
    static testMethod void testApprovalSuccess() 
    {      
         User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
         StudentProcess__c sp=new StudentProcess__c();
         sp.Name='SP Test';
         sp.Type__c ='Appeal';
         sp.ApprovingManager__c =testUser.Id;
         insert sp;
         sp.Type__c='Incomplete Course Request';
         update sp;
     
        // ensure that the opp was submitted for approval
        List<ProcessInstance> processInstances = [select Id, Status from ProcessInstance where TargetObjectId = :sp.id];
        System.assertEquals(processInstances.size(),1);
     
    }
                  
    static testMethod void testStdprocFe() 
    {          
         User testUser = [SELECT Id from User WHERE Profile.Name = 'Records User' AND isActive = true LIMIT 1];
         System.runAs(testUser)
         {
             Test.startTest();
             Contact testContact = new Contact(FirstName = 'Test', LastName = 'testContact', PIDM__c = '12345');
             insert testContact;
             RecordType sprt = [SELECT id FROM RecordType WHERE sObjectType = 'StudentProcess__c' AND DeveloperName = 'TermBreak'];
             StudentProcess__c sp=new StudentProcess__c();
             sp.Name='SP Test';
             sp.Student__c = testContact.Id;
             sp.RecordtypeId = sprt.Id;
             insert sp;
             FieldExperience__c fe = new FieldExperience__c(Student__c=testContact.Id,Active__c=true);
                        insert fe;
             Test.stopTest();
         }     
    }
    
    static testMethod void testCreateWithdrawalsToBanner()
    {
        ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
        QueueSObject wdQ = [SELECT QueueId FROM QueueSObject WHERE SObjectType = 'StudentProcess__c' AND Queue.Name = 'Withdraw Recovery' LIMIT 1]; 
        RecordType wdRT = [SELECT Id FROM RecordType WHERE SObjectType = 'StudentProcess__c' AND DeveloperName = 'Withdrawal' LIMIT 1];
        
        Contact student = new Contact( Status__c = 'AS', PIDM__c = 'p002233', FirstName='Dodley', Email='dasterdlytestersun@bleh.wgu.edu', 
                                       MailingState='UT', LastName='DasterdlyTestersun', RecordTypeId=studentContactRecordTypeId );
        insert student;                                       
                                       
        StudentProcess__c wd = new StudentProcess__c(RecordTypeId = wdRT.Id, Name = 'testWD1124', Student__c = student.Id);
        
        Test.startTest();
            insert wd;
        Test.stopTest();
        
        List<WithdrawalToBanner__c> wtbList = [SELECT Id, ActionNeeded__c, StudentPidm__c, StudentProcess__c, RefId__c FROM WithdrawalToBanner__c LIMIT 100];
        wd = [SELECT Id, OwnerId FROM StudentProcess__c WHERE Id = :wd.Id LIMIT 1];
        
        System.assertEquals(wtbList.size(), 1, 'There should be 1 and only 1 Withdrawal To Banner record based on the insert of the single Withdrawal.');
        System.assertEquals(wd.OwnerId, wdQ.QueueId, 'Owner should have been set to Withdraw Recovery queue based on before insert trigger.');
        System.assertEquals(wd.Id, wtbList[0].StudentProcess__c, 'Lookup record for student process was not properly matched.');
        System.assertEquals(String.valueOf(wd.Id), wtbList[0].RefId__c, 'Ref ID string field was not properly matched to student process record ID.');
        System.assertEquals(wtbList[0].ActionNeeded__c, 'Insert', 'Action needed for new record should be Insert');
        
        delete wd;
        
        wtbList = [SELECT Id, ActionNeeded__c, StudentPidm__c, StudentProcess__c, RefId__c FROM WithdrawalToBanner__c LIMIT 100];
        
        System.assertEquals(wtbList.size(), 1, 'There should be 1 and only 1 Withdrawal To Banner record based on the insert of the single Withdrawal.');
        System.assertEquals(wtbList[0].ActionNeeded__c, 'Delete', 'Action needed for deleted record should be Delete');
    }       
}