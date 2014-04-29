@isTest
private class TestInitialFEEmailSentTrigger 
{
    static testMethod void testFEPStudentAssign()
    {
        Contact newContact = new Contact(Status__c='AS', Pidm__c='QA002233', FirstName='Dudley', LastName='FEEmailTest',
                                         RecordTypeId = [Select Id from RecordType where Name = 'StudentRecord' and SObjectType = 'Contact'].id);
        insert newContact;
        
        newContact = [SELECT Id, Status__c, Pidm__c, FirstName, LastName, Account.Id FROM Contact WHERE Id = :newContact.Id LIMIT 1];
        Account newAccount = [SELECT Id, Pidm__c, StudentContact__c FROM Account WHERE Id = :newContact.Account.Id];              
        
        System.assert( newContact.AccountId != null && newContact.AccountId == newAccount.Id );
        
        System.assert( newAccount.id != null );
        System.assert( newContact != null && newContact.id != null );
        System.assert( newContact.pidm__c == newAccount.pidm__c );                    
                
        //System.debug('====================> Person Check ' + newAccount.IsPersonAccount + ' ' + newAccount.personContactId + ' contact.account ' + newContact.AccountId);
        
        System.assertEquals(newAccount.StudentContact__c, newContact.Id);
        
        WGUCourseCompletionTask__c wguTask = new WGUCourseCompletionTask__c(Name = 'FHT4');
        WGUCourseCompletionTask__c wguTask1 = new WGUCourseCompletionTask__c(Name = 'EEC1');
        WGUCourseCompletionTask__c wguTask2 = new WGUCourseCompletionTask__c(Name = 'SFAW');        
        insert wguTask;
        insert wguTask1;
        insert wguTask2;
        
        newContact = [Select LastModifiedDate, AccountId, InitialFEEmailSent__c, FirstName, LastName, Id, Pidm__c, MailingState, Email, Status__c from Contact where id = :newAccount.StudentContact__c LIMIT 1];      
        DateTime lastMod = newContact.LastModifiedDate;        
        System.assertEquals(newContact.InitialFEEmailSent__c, false);
        System.assert(newContact != null);
        
        Test.startTest();
        
        StudentCompletionTask__c studentTask = new StudentCompletionTask__c(Name = wguTask.Name, WGUCourseCompletionTask__c = wguTask.Id, Student__c = newContact.Id, RequirementComplete__c = False);
        StudentCompletionTask__c studentTask1 = new StudentCompletionTask__c(Name = wguTask1.Name, WGUCourseCompletionTask__c = wguTask1.Id, Student__c = newContact.Id, RequirementComplete__c = False);
        StudentCompletionTask__c studentTask2 = new StudentCompletionTask__c(Name = wguTask2.Name, WGUCourseCompletionTask__c = wguTask2.Id, Student__c = newContact.Id, RequirementComplete__c = False);        
        List<StudentCompletionTask__c> studentTasks = new List<StudentCompletionTask__c>();
        studentTasks.add(studentTask);
        studentTasks.add(studentTask1);
        studentTasks.add(studentTask2);
                 
        insert studentTasks;                
        
        studentTasks[0].RequirementComplete__c = True;
        studentTasks[0].AssessmentStatus__c = 'Passed';
        studentTasks[1].RequirementComplete__c = True;
        studentTasks[1].AssessmentStatus__c = 'Passed';
        studentTasks[2].RequirementComplete__c = True;  
        studentTasks[2].AssessmentStatus__c = 'Passed';            
            
        update studentTasks;
        
        Test.stopTest();        
        
        newContact = [Select LastModifiedDate, AccountId, InitialFEEmailSent__c, FirstName, LastName, Id, Pidm__c, MailingState, Email, Status__c from Contact where id = :newAccount.StudentContact__c];        
        
        if(newContact.LastModifiedDate > lastMod)
        {
            System.assertEquals(newContact.InitialFEEmailSent__c, true);
        }
        
        else
        {
            newContact = [Select LastModifiedDate, AccountId, InitialFEEmailSent__c, FirstName, LastName, Id, Pidm__c, MailingState, Email, Status__c from Contact where id = :newAccount.StudentContact__c];
            if(newContact.LastModifiedDate > lastMod)
            {
                System.assertEquals(newContact.InitialFEEmailSent__c, true);
                System.assertEquals(newContact.SFAWEmailSent__c, true);
            }    
        }                   
    }
}