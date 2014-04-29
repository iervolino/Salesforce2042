/**
Test case for AccountUtility
yemeng zhu
9/19/2013

*/

@IsTest
public class TestAccountUtility{

    private static final Id accountStudentRecordTypeId = [select id from RecordType WHERE DeveloperName='StudentRecord' AND Sobjecttype = 'Account'].Id;
    private static final Id contactStudentRecordTypeId = [select id from RecordType WHERE DeveloperName='StudentRecord' AND Sobjecttype = 'Contact'].Id;
    private static final Id accountDistrictRecordTypeId = [select id from RecordType WHERE DeveloperName='District' AND Sobjecttype = 'Account'].Id;
    private static final Id contactProctorRecordTypeId = [select id from RecordType WHERE DeveloperName='Proctor' AND Sobjecttype = 'Contact'].Id;
 //create a account, and a contact should be generated at the same time 
@IsTest
public static void testCreateOneAccount() { 
     
    Test.startTest();
        Account studentAccount = new Account(Name='Test TestStudent',RecordTypeId=accountStudentRecordTypeId,PIDM__c='xxxxx');
        insert studentAccount; 
    Test.stopTest();
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
    System.assert([select FirstName from contact][0].FirstName=='Test');
    System.assert([select LastName from contact][0].LastName=='TestStudent');
    System.assert([select PIDM__C from contact][0].PIDM__C=='xxxxx');
}

//create a contact , and a account should be generated at the same time
@IsTest
public static void testCreateOneContactA() {
    Test.startTest();
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test1',WGUEmail__c='t1@noworky.wgu.edu'
    ,Email='t1@noworky.wgu.edu',PIDM__c='1111',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    insert studentContact;
    Test.stopTest();
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
    System.assert([select Name from account][0].Name=='Test1 TestStudent');
    System.assert([select PIDM__C from account][0].PIDM__c=='1111'); 
    //see if user exist
    //System.assert([select id from User where pidm__c = '1111'].size()==0); //should have 0 user created
    delete studentContact;                                                  //deletion failed means user create successed, deletion passed means user failed
     
    
}
//create a contact , and a account should be generated at the same time
@IsTest
public static void testCreateOneContactB() {
    Test.startTest();
     Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test',WGUEmail__c='stest.student@bogus.wgu.edu'
    ,Email='test.student@bogus.wgu.edu',PIDM__c='xxxxxx',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    insert studentContact;
    Test.stopTest();
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
    System.assert([select Name from account][0].Name=='Test TestStudent');
    System.assert([select PIDM__C from account][0].PIDM__c=='xxxxxx'); 
    //see if user exist
    //System.assert([select id from User where pidm__c = 'xxxxxx'].size()==0); //should have 0 user created
    delete studentContact;                                                  //deletion failed means user create successed, deletion passed means user failed
     
    
}
//create a contact , and a account should be generated at the same time
@IsTest
public static void testCreateOneContactC() {
    Test.startTest();
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test1',WGUEmail__c='tt1@noworky.wgu.edu'
    ,Email='tt1@noworky.wgu.edu',PIDM__c='1111',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    insert studentContact;
    Test.stopTest();
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
    System.assert([select Name from account][0].Name=='Test1 TestStudent');
    System.assert([select PIDM__C from account][0].PIDM__c=='1111'); 
    //see if user exist
    //System.assert([select id from User where pidm__c = '1111'].size()==0); //should have 0 user created
    delete studentContact;                                                  //deletion failed means user create successed, deletion passed means user failed
     
    
}

@IsTest
public static void testCreateFiveContacts() { 
     
    Test.startTest();
    List<Contact> contacts=new List<Contact>();
    for(integer i=0;i<5;i++)
    {
        
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test'+i,WGUEmail__c='tt'+i+'@noworky.wgu.edu'
    ,Email='tt'+i+'@noworky.wgu.edu',PIDM__c='m'+i+i+i,RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    contacts.add(studentContact);
    } 
    insert contacts;
    Test.stopTest();
    System.assert([select id from account].size()==5);
    System.assert([select id from contact].size()==5); 
    delete contacts;
    //delete should no longer cause trouble
    //* not really sure if we need to delete corresponding account
  //  System.assert([select id from account].size()==0);
   // System.assert([select id from contact].size()==0); 
}

@IsTest
public static void testCreateFiveAccounts() { 
     
    Test.startTest();
    List<Account> accounts=new List<account>();
    for(integer i=0;i<5;i++)
    {
        
    account studentaccount = new account( Name='Test'+i+' TestStudent'  ,PIDM__c='m'+i+i+i,RecordTypeId=accountStudentRecordTypeId  );
    accounts.add(studentAccount);
    } 
    insert accounts;
    Test.stopTest();
    System.assert([select id from account].size()==5);
    System.assert([select id from contact].size()==5); 
    delete accounts;
    System.assert([select id from account].size()==0);
    System.assert([select id from contact].size()==0); 
}

@IsTest
public static void testCreateFiveContactsAndPortalUser() { 
     
    Test.startTest();
    List<Contact> contacts=new List<Contact>();
    List<String> pidms =new List<String>();
    for(integer i=0;i<5;i++)
    {
        
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test'+i,WGUEmail__c='tt'+i+'@noworky.wgu.edu'
    ,Email='tt'+i+'@noworky.wgu.edu',PIDM__c='m'+i+i+i,RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    contacts.add(studentContact);
    pidms.add('m'+i+i+i);
    } 
    insert contacts;
    update contacts;
    Test.stopTest();
    System.assert([select id from account].size()==5);
    System.assert([select id from contact].size()==5);  
    System.assert([select id from User where pidm__c in :pidms].size()==5); 
  //  delete contacts;//should not be able to delete any of those records because Users is un-deleteable
    
}
@IsTest
public static void testCreateOneContactByUserAsync() {
    system.debug('### Test two ###');
        /**
        if the salesforce already contains sertain user, the loading Test Data won't work: 
        "
            List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData'); 
            update contacts;
        "
           t1 already exist.--->
            'System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION, The specified Federation ID already exists for this organization: [FederationIdentifier]''
           
           
    */
         Test.startTest();
        Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test1',WGUEmail__c='ttt1@noworky.wgu.edu'
        ,Email='ttt1@noworky.wgu.edu',PIDM__c='1111',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
        System.assert(AccountUtility.isInsertContact==false);  
        insert studentContact;  
        System.debug('###stuCon##'+studentContact); 
        System.assert([select id from account where pidm__c = '1111'].size()==1); 
        System.assert([select id from contact where pidm__c = '1111'].size()==1);
        System.assert([select id from User where pidm__c = '1111'].size()==0);   
        System.assert(AccountUtility.isInsertContact==false);  
        update studentContact; 
        Test.stopTest(); 
        System.assert(AccountUtility.isInsertContact==false);
        System.assert([select id from User where pidm__c = '1111'].size()==1);   
        
        
}
 
//web service call,will also test the createContactsForAccounts
@IsTest
public static void testCreateOneAccountWeb() {
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test',WGUEmail__c='stest.student@bogus.wgu.edu'
    ,Email='test.student@bogus.wgu.edu',PIDM__c='xxxxxx',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    insert studentContact;
    delete studentContact;
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==0);
    List<id> ids=new List<id>();
    ids.add([select id from account][0].id);
    Test.startTest();
        AccountUtility.createContactsForAccountsWebCall(ids);
    Test.stopTest();
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
}

//for web call, will also test the createAccountsForContacts
@IsTest
public static void testCreateOneContactWeb() {
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test',WGUEmail__c='stest.student@bogus.wgu.edu'
    ,Email='test.student@bogus.wgu.edu',PIDM__c='xxxxxx',RecordTypeId=contactProctorRecordTypeId,Status__c='AS' );
    insert studentContact;
    studentContact.recordTypeId=contactStudentRecordTypeId;
    update studentContact;
    System.assert([select id from account].size()==0);
    System.assert([select id from contact].size()==1);
    List<id> ids=new List<id>();
    ids.add([select id from contact][0].id);
    Test.startTest();
        AccountUtility.createAccountsForContactsWebCall(ids);
    Test.stopTest();
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
}

//find wired accounts
@IsTest
public static void testHuntAccount() {
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test',WGUEmail__c='stest.student@bogus.wgu.edu'
    ,Email='test.student@bogus.wgu.edu',PIDM__c='xxxxxx',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
    insert studentContact;
    delete studentContact;
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==0); 
    Test.startTest();
        System.assert(AccountUtility.huntInvalidAccounts().size()==1);
    Test.stopTest(); 
}

//find wired contacts 
@IsTest
public static void testHuntContact() {
    
    Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test',WGUEmail__c='stest.student@bogus.wgu.edu'
    ,Email='test.student@bogus.wgu.edu',PIDM__c='xxxxxx',RecordTypeId=contactProctorRecordTypeId,Status__c='AS' );
    insert studentContact;
    studentContact.recordTypeId=contactStudentRecordTypeId;
    update studentContact;
    System.assert([select id from account].size()==0);
    System.assert([select id from contact].size()==1);  
    Test.startTest();
        System.assert(AccountUtility.huntInvalidContacts().size()==1);
    Test.stopTest(); 
}

//delete a account should recursively delete its relate contact
@IsTest
public static void testDeleteAccount() {
    Account studentAccount = new Account(Name='Test TestStudent',RecordTypeId=accountStudentRecordTypeId,PIDM__c='xxxxx');
    insert studentAccount; 
    System.assert([select id from account].size()==1);
    System.assert([select id from contact].size()==1);
    Test.startTest();
    delete studentAccount;
    Test.stopTest();
    System.assert([select id from account].size()==0);
    System.assert([select id from contact].size()==0);  

}

@IsTest
public static void testContactTestDataManual() { 
    Test.startTest();
    ID mentorProfileID = [SELECT  id from Profile where name = 'Mentor'].id;
        User thisUser = new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942', Username='a@wgu.edu', email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true);
        System.runAs(thisUser){ 
    List<Contact> contacts=new List<Contact>();
    contacts.add(  new Contact(LastName='Testcontact',FirstName='Tester1',Email='t1@noworky.wgu.edu',PIDM__c='1111', Status__c='AS' ));
    contacts.add(  new Contact(LastName='Testcontact',FirstName='Tester2',Email='t2@noworky.wgu.edu',PIDM__c='2222', Status__c='AS' ));
    contacts.add(  new Contact(LastName='Testcontact',FirstName='Tester3',Email='t3@noworky.wgu.edu',PIDM__c='3333', Status__c='AS' ));
    contacts.add(  new Contact(LastName='Testcontact',FirstName='Tester4',Email='t4@noworky.wgu.edu',PIDM__c='4444', Status__c='AS' ));
    contacts.add(  new Contact(LastName='Testcontact',FirstName='Tester5',Email='t5@noworky.wgu.edu',PIDM__c='5555', Status__c='AS' ));
    insert contacts;
        }
    Test.stopTest();
    System.debug('#########recordtype###'+[select id, FirstName, pidm__c, recordTypeId, recordType.Name, recordType.DeveloperName from contact]); 
    System.assert([select id from contact].size()==5); 
    System.assert([select id from account].size()==5);

}

@IsTest
public static void testContactTestData() { 
    Test.startTest();
        ID mentorProfileID = [SELECT  id from Profile where name = 'Mentor'].id;
        User thisUser = new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942', Username='a@wgu.edu', email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true);
        System.runAs(thisUser){ 
            List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData'); 
        }
    Test.stopTest();
    System.debug('#########recordtype###'+[select id, FirstName, pidm__c, recordTypeId, recordType.Name, recordType.DeveloperName from contact]); 
    System.assert([select id from contact].size()==5); 
    System.assert([select id from account].size()==5);

}    

@IsTest
public static void testContactTestDataRunAs() {
    Test.startTest();
        ID mentorProfileID = [SELECT  id from Profile where name = 'Mentor'].id;
        User thisUser = new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942', Username='a@wgu.edu', email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true);
        
        System.runAs(thisUser){
            List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');   
            System.debug('###################0#'+contacts);
            System.debug('###################0.5#'+[select id, pidm__c, email, firstname, lastname, status__c from contact]);
        }
  
    Test.stopTest();
    System.debug('#########recordtype###'+[select id, FirstName, pidm__c, recordTypeId, recordType.Name, recordType.DeveloperName from contact]); 
    System.assert([select id from contact].size()==5); 
    System.assert([select id from account].size()==5);

}     

@IsTest
public static void testBeforeUpdateContact() { 
     
    Test.startTest();
        Account studentAccount = new Account(Name='Test TestStudent',RecordTypeId=accountStudentRecordTypeId,PIDM__c='xxxxx');
        insert studentAccount;  
        System.assert([select id from account].size()==1);
        System.assert([select id from contact].size()==1);
        System.assert([select FirstName from contact][0].FirstName=='Test');
        System.assert([select LastName from contact][0].LastName=='TestStudent');
        System.assert([select PIDM__C from contact][0].PIDM__C=='xxxxx');
        Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test1',WGUEmail__c='t1@noworky.wgu.edu'
            ,Email='t1@noworky.wgu.edu',PIDM__c='1111',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' ,accountid=studentAccount.id);
        boolean exc =false;
        
        try{    
            insert studentContact;
        }catch(System.DmlException e)
        {   exc=true;
            System.assert([select id from account].size()==1);
            System.assert([select id from contact].size()==1);
        }
        System.assert(exc);
    Test.stopTest(); 
}
@isTest
public static  void testBeforeUpdateAccount() {
        Test.startTest();
            Contact studentContact = new Contact(LastName='TestStudent',FirstName='Test1',WGUEmail__c='t1@noworky.wgu.edu'
            ,Email='t1@noworky.wgu.edu',PIDM__c='1111',RecordTypeId=contactStudentRecordTypeId,Status__c='AS' );
            insert studentContact;
            System.assert([select id from account].size()==1);
            System.assert([select id from contact].size()==1);
            System.assert([select Name from account][0].Name=='Test1 TestStudent');
            System.assert([select PIDM__C from account][0].PIDM__c=='1111'); 
            
            Account studentAccount = new Account(Name='Test TestStudent',RecordTypeId=accountStudentRecordTypeId,PIDM__c='xxxxx',StudentContact__c=StudentContact.id);
            boolean exc =false;
            try{ 
                insert studentAccount;
            }catch(System.DmlException e)
            {   exc=true;
                System.assert([select id from account].size()==1);
                System.assert([select id from contact].size()==1);
            }
            
            System.assert(exc);
        Test.stopTest(); 
        //see if user exist
        //System.assert([select id from User where pidm__c = '1111'].size()==0); //should have 0 user created
        delete studentContact;                                                  //deletion failed means user create successed, deletion passed means user failed
     
    }
}