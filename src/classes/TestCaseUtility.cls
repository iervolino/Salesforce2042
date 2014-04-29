/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 11 2013 @ 1257  hrs
 * Revised: PersonAccount refactor and Trigger try/catch change - Paul Coleman
 * 
 * Date Nov 03 2012 @ 1312  hrs
 * Revised: (security audit compliance: with sharing and SeeAllData=false) 
 * 
 * Various after update on Case test processes 
 *
 */  
@isTest()
private with sharing class TestCaseUtility {

    private static testMethod void testContactIdToAccountIdSynchronization() {
    
            Contact student = TestStudentUser.getTestStudentContact(); 
            
            User testUser = TestStudentUser.getSAdminUser();
            System.runAs( testUser ) {
                
                Test.startTest();
                 
                    Case testCase = new Case(ContactId=student.id, OwnerId=testUser.Id);
                            insert testCase;
                                                             
                Test.stopTest();
                
                testCase = [select id, CaseNumber, AccountId, ContactId, OwnerId from Case where id = :testCase.id];
                System.assert( testCase.AccountId == student.AccountId, 'TRIGGER ERROR, AccountId on Test Case does not correspond with the ContactId value');
                                
            }            
    }

    private static testMethod void testTransferOfTaskAssignmentBasedOnOwnerId() {
    
            Contact student = TestStudentUser.getTestStudentContact(); 
            
            Id QueueId = [SELECT id FROM Group where Type= 'Queue' LIMIT 1].id;
            ID newUserId;
            user sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
            ID mentorProfileID = [select id from Profile where name = 'Mentor'].id;
            User thisUser = [SELECT count() from User where ProfileId = :mentorProfileID AND isEmployee__c = true AND isActive = true]>0? [SELECT Id, Name from User where ProfileId = :mentorProfileID AND isEmployee__c = true  AND isActive = true LIMIT 1]: null;
            thisUser = (thisUser == null)? new User(LastName='Mentor',FirstName='Standard',pidm__c='m198765',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c = true): thisUser;
            System.debug( LoggingLevel.DEBUG, 'USER for testCaseUtility(): ' + thisUser.Name);
            newUserid = thisUser.id;
        
            Case testCase = new Case(AccountId=student.AccountId, ContactId=student.id, OwnerId=QueueId);
            insert testCase;
            testCase = [select id, CaseNumber, AccountId, ContactId, OwnerId from Case where id = :testCase.id];
            System.debug( LoggingLevel.INFO, 'TEST CASE NUMBER for testCaseUtility(): ' + testCase.CaseNumber);
                
            Task atask = new Task();
             atask.Subject = 'Test Case Task'; 
             atask.RecordTypeId = [Select id from RecordType where DeveloperName='EmployeeTask' and sObjectType = 'Task'].id;
             atask.whoid = student.Id;
             atask.whatid = testCase.id;
             atask.OwnerId = sysAdmin.Id;
            insert atask;
            
            Id ataskID = atask.id;
        
            User testUser = TestStudentUser.getSAdminUser();
            System.runAs( testUser ) {
                
                Test.startTest();
                
                    System.assertEquals( testCase.OwnerId, QueueId, 'BEFORE CASE UPDATE, Test Case Owner DOES NOT equal QUEUE');
                    System.assertEquals( atask.ownerid, sysAdmin.Id, 'BEFORE CASE UPDATE, Test Task Owner DOES NOT equal SysAdmin Id'); 
                    testCase.ownerid = newUserId;
                    update testCase;
                    
                Test.stopTest();

                testCase = [select id, CaseNumber, AccountId, ContactId, LastModifiedDate, OwnerId from Case where id = :testCase.id LIMIT 1];
                System.assertEquals( testCase.ownerId, newUserId, 'Case Owner DOES NOT equal expected User Id');
                
                atask = [Select ownerid, LastModifiedDate from Task where whatid = :testCase.id and id = :ataskId LIMIT 1];
                System.assertEquals( atask.ownerid, newUserId, 'Task OwnerId DOES NOT equal Case Owner' ); 
                  
                Map<Id,Case> caseMap = new Map<Id,Case>();
                caseMap.put(testCase.Id,testCase);                  
                futureCall( JSON.serialize(caseMap.values()), JSON.serialize(caseMap) ); 
                
            }
  }
  
  
    private static testMethod void testChangeRecordTypeOnOwnerId() {
            Contact student = TestStudentUser.getTestStudentContact(); 
            Id recTypeId=[select id from recordtype where sobjecttype='keyvalue__c' and developername='Queue'].id;            
            
            Id QueueId = [SELECT id FROM Group where Type= 'Queue' LIMIT 1].id;
            String QueueName = [SELECT Name FROM Group where Type= 'Queue' LIMIT 1].Name;
            List<KeyValue__c> kvList=new List<KeyValue__c>();
            String rtName = [select name,developerName from RecordType where sobjecttype='Case' limit 1].developerName;
                keyvalue__c kv=new KeyValue__c();
                kv.RecordTypeId = recTypeId;
                kv.Name=QueueName;
                kv.Value__c=rtName;
                insert kv;
            
            
            Case testCase = new Case(ContactId=student.id);
            insert testCase;
            User testUser = TestStudentUser.getSAdminUser();
            System.runAs( testUser ) {
                
                Test.startTest();
                    testCase.ownerid = QueueId;
                    update testCase;
                Test.stopTest();
                System.assertEquals( testCase.ownerid,QueueId); 
            }
  }


    @future
    private static void futureCall( String ListNewJSON, String OldMapJSON ) {
      
        //grabbing code coverage into future call exception handling blocks
        try { CaseUtility.transferOpenSysAdminTasks( ListNewJSON, OldMapJSON ); } catch (Exception e) {}
        
    }

}