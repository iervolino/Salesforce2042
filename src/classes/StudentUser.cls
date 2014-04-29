/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date February 04 2013 @ 1423 hrs 
 * Revised: person Account refactor - Paul Coleman
 * Revised: updated personal info URL - Will Slade 7-11-2013
 * 
 * Class to support Student processes
 *
 */
public virtual with sharing class StudentUser {

    protected transient RestAdapter adapter = (UserInfo.getProfileId() == [Select id FROM Profile WHERE Name = 'Student Profile' LIMIT 1].id? (Test.isRunningTest()?null:new RestAdapter()): null);
    protected User thisStudentUser;
    protected Account thisStudentAccount;
    protected Contact thisStudentContact;
    protected StudentAttributes__c thisStudentAttributes;
    protected ID userId, accountId, contactId;
    protected String contactKeyPrefix;
    protected String accountKeyPrefix;
    protected String userKeyPrefix;
          
    
    private StudentUser() {} //private constructor, to force ID assignment via constructor, see StudentUser(ID sfID)

    public StudentUser(ID sfID) { 
       if ( sfId != null ) { 
          String idString = sfId;
                    Schema.DescribeSObjectResult accountMeta = Schema.SObjectType.Account; 
                    Schema.DescribeSObjectResult userMeta = Schema.SObjectType.User; 
                    Schema.DescribeSObjectResult contactMeta = Schema.SObjectType.Contact;
                     
                    String contactKeyPrefix = contactMeta.getKeyPrefix();
              String accountKeyPrefix = accountMeta.getKeyPrefix();
              String userKeyPrefix = userMeta.getKeyPrefix();
              
              //determine what type of ID record was passed in as the sfId param
              if ( idString.startsWith(userKeyPrefix) ) {
                fetchStudentUser(idString);
              } else if ( idString.startsWith(contactKeyPrefix) ) {
                fetchStudentContact(idString);
              } else if ( idString.startsWith(accountKeyPrefix) ) {
                fetchStudentAccount(idString);
              } else {
            throw new StudentException( 'INVALID ID PARAM: StudentUser constructor must receive a valid User, Contact, or Account record Id (sfID param). The sfId param ' + idString + ' does not appear to be a User, Acccount, or Contact record Id.' );             
              }
       } else {
           throw new StudentException( 'NULL VALUE ERROR: StudentUser constructor must receive a valid record Id (sfID param).' );
       }
    }
    
    private User fetchStudentUser(ID sfID) {
      this.userId = sfID;
      this.thisStudentUser = new User();
      if ( [SELECT count() FROM User WHERE id = :sfID] > 0 ) {
          //gather fields from User schema
          Map<String, Schema.SObjectField> userFieldMap = Schema.SObjectType.User.fields.getMap();
          String soql = 'SELECT ';
          boolean firstField = true;
          for ( Schema.SObjectField field: userFieldMap.values() ) {
              Schema.DescribeFieldResult describe = field.getDescribe();
              String fieldType = String.valueOf(describe.getType());
              if ( describe.isAccessible() && !fieldType.equalsIgnoreCase('LOCATION') ) {
                soql += (firstField? describe.getName(): ','+describe.getName());
                firstField = false;
              }
          }
          soql += ' FROM User WHERE Profile.Name = \'Student Profile\' AND ContactId != null AND id = \''+sfID+'\' LIMIT 1'; 
          System.Debug( LoggingLevel.DEBUG, 'STUDENT USER SOQL: ' + soql );
          this.thisStudentUser = Database.query(soql);
          if ( this.contactId != thisStudentUser.ContactId ) {
            this.contactId = thisStudentUser.ContactId;
          }
          if ( this.accountId != thisStudentUser.AccountId ) {
            this.accountId = thisStudentUser.AccountId;
          }
      } 
      return this.thisStudentUser;
    }
    
    private Account fetchStudentAccount(ID sfID) {
      this.accountId = sfID;
      this.thisStudentAccount = new Account();
      if ( [SELECT count() FROM Account WHERE StudentContact__c != null AND id = :sfID LIMIT 1] == 1 ) {
          Map<String, Schema.SObjectField> accountFieldMap = Schema.SObjectType.Account.fields.getMap();
          String soql = 'SELECT ';
          boolean firstField = true;
          for ( Schema.SObjectField field: accountFieldMap.values() ) {
              Schema.DescribeFieldResult describe = field.getDescribe();
              String fieldType = String.valueOf(describe.getType());
              if ( describe.isAccessible() && !fieldType.equalsIgnoreCase('LOCATION') && !describe.getName().toLowerCase().endsWith('__pc')
                    && !describe.getName().toLowerCase().equals('ispersonaccount')
                                        && !describe.getName().toLowerCase().equals('persontitle')
                                        && !describe.getName().toLowerCase().equals('personotherstreet')
                                        && !describe.getName().toLowerCase().equals('personotherstate')
                                        && !describe.getName().toLowerCase().equals('personotherpostalcode')
                                        && !describe.getName().toLowerCase().equals('personotherphone')
                                        && !describe.getName().toLowerCase().equals('personothercountry')
                                        && !describe.getName().toLowerCase().equals('personothercity')
                                        && !describe.getName().toLowerCase().equals('personmobilephone')
                                        && !describe.getName().toLowerCase().equals('personmailingstreet')
                                        && !describe.getName().toLowerCase().equals('personmailingstate')
                                        && !describe.getName().toLowerCase().equals('personmailingpostalcode')
                                        && !describe.getName().toLowerCase().equals('personmailingcountry')
                                        && !describe.getName().toLowerCase().equals('personmailingcity')
                                        && !describe.getName().toLowerCase().equals('personleadsource')
                                        && !describe.getName().toLowerCase().equals('personlastcuupdatedate')
                                        && !describe.getName().toLowerCase().equals('personlastcurequestdate')
                                        && !describe.getName().toLowerCase().equals('personhomephone')
                                        && !describe.getName().toLowerCase().equals('personhasoptedoutoffax')
                                        && !describe.getName().toLowerCase().equals('personhasoptedoutofemail')
                                        && !describe.getName().toLowerCase().equals('personemailbouncedreason')
                                        && !describe.getName().toLowerCase().equals('personemailbounceddate')
                                        && !describe.getName().toLowerCase().equals('personemail')
                                        && !describe.getName().toLowerCase().equals('persondonotcall')
                                        && !describe.getName().toLowerCase().equals('persondepartment')
                                        && !describe.getName().toLowerCase().equals('personcontactid')
                                        && !describe.getName().toLowerCase().equals('personbirthdate')
                                        && !describe.getName().toLowerCase().equals('personassistantphone')
                                        && !describe.getName().toLowerCase().equals('personassistantname')
               ) {
                soql += (firstField? describe.getName(): ','+describe.getName());
                firstField = false;
              }
          }
          Map<String, Schema.SObjectField> contactFieldMap = Schema.SObjectType.Contact.fields.getMap();
          String contactSoql = '';
          for ( Schema.SObjectField field: contactFieldMap.values() ) {
              Schema.DescribeFieldResult describe = field.getDescribe();
              String fieldType = String.valueOf(describe.getType());
              if ( describe.isAccessible() && !fieldType.equalsIgnoreCase('LOCATION') ) {
                contactSoql += ',StudentContact__r.'+describe.getName();
              }
          }

          soql += (contactSoql+' FROM Account WHERE StudentContact__c != null AND id = \''+sfID+'\' LIMIT 1'); 
          System.Debug( LoggingLevel.DEBUG, 'STUDENT ACCOUNT SOQL: ' + soql );
          this.thisStudentAccount = Database.query(soql);
          if ( this.contactId != thisStudentAccount.StudentContact__c ) {
            this.contactId = thisStudentAccount.StudentContact__c;
          }
          if ( this.userId == null ) {
              if ([SELECT count() FROM User WHERE accountid = :sfID LIMIT 1] == 1) {
                  fetchStudentUser([SELECT id FROM User WHERE accountid = :sfID LIMIT 1].Id);
              }
          }
      }
      return this.thisStudentAccount;
    }
    
    private Contact fetchStudentContact(ID sfID) {
      this.contactId = sfID;
      this.thisStudentContact = new Contact();
      if ( [SELECT count() FROM Contact WHERE AccountId != null AND Account.StudentContact__c != null AND id = :sfID LIMIT 1] == 1 ) {
          //gather fields from Contact schema
                    Map<String, Schema.SObjectField> contactFieldMap = Schema.SObjectType.Contact.fields.getMap();
                    String soql = 'SELECT ';
                    boolean firstField = true;
                    for ( Schema.SObjectField field: contactFieldMap.values() ) {
                        Schema.DescribeFieldResult describe = field.getDescribe();
              			String fieldType = String.valueOf(describe.getType());
                        if ( describe.isAccessible() && !fieldType.equalsIgnoreCase('LOCATION') ) {
                          soql += (firstField? describe.getName(): ','+describe.getName());
                          firstField = false;
                        }
                    }
                    soql += ',Account.RecordTypeId,Account.PIDM__c,Account.AccountEmail__c,Account.BannerId__c,Account.DiscountAmount__c FROM Contact WHERE AccountId != null AND id = \''+sfID+'\' LIMIT 1'; 
          System.Debug( LoggingLevel.DEBUG, 'STUDENT CONTACT SOQL: ' + soql );
          this.thisStudentContact = Database.query(soql);
          if ( this.accountId != thisStudentContact.AccountId ) {
            this.accountId = thisStudentContact.AccountId;
          }
          if ( this.userId == null ) {
              if ( [SELECT count() FROM User WHERE contactId = :sfID LIMIT 1] > 0 ) {
                  fetchStudentUser( [SELECT id FROM User WHERE contactId = :sfID LIMIT 1].Id );
              } 
          }
      } 
      return this.thisStudentContact;
    }
    
    public virtual User getStudentUser() {
      return this.thisStudentUser==null? fetchStudentUser( this.userId ): this.thisStudentUser;
    }
 
    public virtual Account getStudentAccount() {
      return this.thisStudentAccount==null? fetchStudentAccount( this.accountId ): this.thisStudentAccount;
    }
    
    public virtual Contact getStudentContact() {
      return this.thisStudentContact==null? fetchStudentContact( this.contactId ): this.thisStudentContact;
    }
    
    public virtual String getVerifyPersonalInfoURL() {
      return 'https://webapp19.wgu.edu/studentdetails';     
    }
    
    public static String getEnvironment() {
      //in the PRODUCTION ORG, this method returns the string 'prod', as does a non-test call to Runtime__c.getValues('environment').Value__c
      //in a SANDBOX ORG, this method returns the name of the sandbox as parsed FROM a call to URL.getSalesforceBaseUrl()  
      String orgBox = Runtime__c.getValues('environment') == null? '': Runtime__c.getValues('environment').Value__c;  
      
      if ( Test.isRunningTest() && (orgBox==null || orgBox=='') ) {
        String oldProdOrgId = '00D30000001GkGUEA0'; //old person account org
        String newProdOrgId = '00Dd0000000hVl6EAE'; //non person account org
        String thisOrgId = [Select Id From Organization].id;
        
        boolean inProdOrg = ( thisOrgId.equals(oldProdOrgId) || thisOrgId.equals(newProdOrgId) );
        String thisURL = URL.getSalesforceBaseUrl().toExternalForm().toLowerCase();    
        boolean inSRMHost = thisURL.contains('srm--');   
        
        //until the new orgs SRM host name is transfered, the orgBox will result in the host instance name, e.g., cs16
        orgBox = inProdOrg? 'prod': (inSRMHost? thisURL.split('srm--')[1].split('\\.')[0].split('--')[0]: thisURL.split('https://')[1].split('\\.')[0].split('--')[0]);   
        
        String runtimeJson = '[{"attributes":{"type":"Runtime__c"},"Name":"environment","Value__c":"'+orgBox+'"},{"attributes":{"type":"Runtime__c"},"Name":"s3images.manager.url","Value__c":"http://s3images.appspot.com/wgu"},{"attributes":{"type":"Runtime__c"},"Name":"web3_domain","Value__c":"l2web3.wgu.edu"}]';
        List<Runtime__c> runtimes = (List<Runtime__c>)JSON.deserialize(runtimeJson, List<Runtime__c>.class);
         //modified by PBC Oct 8 2013 @0911 hrs to better handle MIXED DML Exceptions in Test contexts
        try { insert runtimes; } catch (Exception e) { System.debug(LoggingLevel.DEBUG, e.getMessage() ); } //inserts may fail in tests if the context creates a mixed DML exception
      } 
      
      return orgBox;  
    }
}