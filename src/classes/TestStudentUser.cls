/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date January 28, 2013 @ 1447 hrs
 * Revised: Person Account Refactor 
 * 
 * Date December 5, 2012 @ 1101 hrs
 * Revised: Create User record if it is created corretly by the Account/Contact Trigger (getTestStudentUser method)
 *
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 * 
 * Tests the methods of StudentUser base class
 *
 */
@isTest()  
public with sharing class TestStudentUser {

    public static User getSAdminUser() {
    	return [SELECT id FROM User WHERE username LIKE 'sadmin@%wgu.edu%' AND isActive = true LIMIT 1];
    }
    
    public static User getTestStudentUser() {
          return getTestStudentUser( getTestStudentContact().Id );
    }
    
    public static User getTestStudentUser(Id contactId) {
        User student;
        if ( Test.isRunningTest() ) {
          if ( [SELECT count() from User where ContactId = :contactId LIMIT 1] == 1) {
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
              soql += ' FROM User WHERE Profile.Name = \'Student Profile\' AND ContactId = \''+contactId+'\' LIMIT 1'; 
              student = Database.query(soql);
          } else {
              //Test User does not exist in Test environment yet, fabricate one for testing purposes
              Contact thisContact = getTestStudentContact();
              User studentUser = ContactUtility.createStudentUser(thisContact, null, null, null);
              //modified by PBC Oct 8 2013 @0911 hrs to better handle MIXED DML Exceptions in Test contexts
              studentUser.FederationIdentifier += '._'+ String.valueOf( Crypto.getRandomInteger() + '.wgu.edu' ); //create a unique value for fed id in testing
          	  System.debug( LoggingLevel.INFO, 'TEST USER JSON: ' + Json.serialize(studentUser) );
              try { 
              	insert studentUser; 
              } catch (DMLException e) { 
              	if ( e.getMessage().contains('DUPLICATE_USERNAME') ) { 
              		studentUser.Username = studentUser.Username + '._' +String.ValueOf(Crypto.getRandomInteger() + '.wgu.edu') ; 
              		insert studentUser; 
          		} else { 
          			throw e;
      			} 
          	  }
              
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
              soql += ' FROM User WHERE Profile.Name = \'Student Profile\' AND ContactId = \''+thisContact.Id+'\' LIMIT 1'; 
              student = Database.query(soql);
              
          }
        } 
        return student;
    }
       
    public static Account getTestStudentAccount() {
        Account student;
        if ( Test.isRunningTest() ) {
          Map<String, Schema.SObjectField> accountFieldMap = Schema.SObjectType.Account.fields.getMap();
          String soql = 'SELECT ';
          boolean firstField = true;
          for ( Schema.SObjectField field: accountFieldMap.values() ) {
              Schema.DescribeFieldResult describe = field.getDescribe();
              //exclude OLD Person Account fields
              //NOTE: this code can be removed when/if migrating to a non-person account org
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
          Contact studentContact = getTestStudentContact(); 
          soql += (contactSoql + ',StudentContact__r.RecordType.DeveloperName,RecordType.DeveloperName FROM Account WHERE RecordType.DeveloperName IN (\'StudentRecord\', \'ProspectRecord\',\'AlumniRecord\' , \'ProspectAccount\' , \'StudentAccount\' , \'AlumniAccount\') AND StudentContact__c = \''+studentContact.Id+'\' LIMIT 1');
          student = [SELECT count() FROM Account where StudentContact__c=:studentContact.Id]==1? Database.query(soql): new Account();
        }
      return student;
    }
       
    public static Contact getTestStudentContact() {
        Contact student;
        if ( Test.isRunningTest() ) {
          //gather fields from Contact schema
          student = [SELECT count() FROM Contact where FirstName = 'Khadijah_test' AND LastName = 'Abdullah_test' and PIDM__c = 'pctestka2']==1? getContact() : setupStudentTestData();
        }
      return student;
    }
       
    private static Contact getContact() {
        Contact student;
        if ( Test.isRunningTest() ) {
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
          soql += ',RecordType.DeveloperName,Account.RecordType.DeveloperName FROM Contact WHERE AccountId != null AND FirstName = \'Khadijah_test\' AND LastName = \'Abdullah_test\' and PIDM__c = \'pctestka2\' LIMIT 1'; 
          student = [SELECT count() FROM Contact where FirstName = 'Khadijah_test' AND LastName = 'Abdullah_test' and PIDM__c = 'pctestka2']==1? Database.query(soql) :new Contact();
        }
      return student;
    }
       
   public static String getEnvironment() {
      //in the PRODUCTION ORG, this method returns the string 'prod', as does a non-test call to Runtime__c.getValues('environment').Value__c
      //in a SANDBOX ORG, this method returns the name of the sanbox as parsed from a call to URL.getSalesforceBaseUrl() 
      setupCustomSettingTestData();       
      return StudentUser.getEnvironment();
  }
  
  public static void setupCustomSettingTestData() {
  
      if ( Test.isRunningTest() ) {

         //Setup some TimeZoneByZip__c custom setting data for testing
        if ( [select count() from TimeZoneByZip__c] == 0 ) {
         List<TimeZoneByZip__c> timezones = new List<TimeZoneByZip__c>();
         timezones.add( new TimeZoneByZip__c(Name='84044',TimeZoneKey__c='America/Denver'));
         timezones.add( new TimeZoneByZip__c(Name='84070',TimeZoneKey__c='America/Denver'));
         insert timezones;
        }
        
        //Setup some States__c custom setting data for testing
        if ( [select count() from States__c] == 0 ) {
         String statesJson = '[{"attributes": {"type": "States__c"},"Name": "AA","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "AA - Armed Forces America"},{"attributes": {"type": "States__c"},"Name": "AE","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "AE - Armed Forces Europe"},{"attributes": {"type": "States__c"},"Name": "AP","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "AP - Armed Forces Pacific"},{"attributes": {"type": "States__c"},"Name": "AK","DefaultTimeZoneKey__c": "America/Anchorage","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Alaska"},{"attributes": {"type": "States__c"},"Name": "AL","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "ADPT","StateFullName__c": "Alabama"},{"attributes": {"type": "States__c"},"Name": "AR","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Arkansas"},{"attributes": {"type": "States__c"},"Name": "AS","DefaultTimeZoneKey__c": "Pacific/Pago_Pago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "American Samoa"},{"attributes": {"type": "States__c"},"Name": "AZ","DefaultTimeZoneKey__c": "America/Phoenix","EducatorBasicSkillsCodes__c": "AEPA PXST","StateFullName__c": "Arizona"},{"attributes": {"type": "States__c"},"Name": "CA","DefaultTimeZoneKey__c": "America/Los_Angeles","EducatorBasicSkillsCodes__c": "ACBC","StateFullName__c": "California"},{"attributes": {"type": "States__c"},"Name": "CO","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST ACOT","StateFullName__c": "Colorado"},{"attributes": {"type": "States__c"},"Name": "CT","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Connecticut"},{"attributes": {"type": "States__c"},"Name": "DC","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "District of Columbia"},{"attributes": {"type": "States__c"},"Name": "DE","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Delaware"},{"attributes": {"type": "States__c"},"Name": "FL","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "AFTT","StateFullName__c": "Florida"},{"attributes": {"type": "States__c"},"Name": "FM","DefaultTimeZoneKey__c": "Australia/Sydney","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Federated States of Micronesia"},{"attributes": {"type": "States__c"},"Name": "GA","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "GATS","StateFullName__c": "Georgia"},{"attributes": {"type": "States__c"},"Name": "GU","DefaultTimeZoneKey__c": "Australia/Sydney","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Guam"},{"attributes": {"type": "States__c"},"Name": "HI","DefaultTimeZoneKey__c": "Pacific/Honolulu","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Hawaii"},{"attributes": {"type": "States__c"},"Name": "IA","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Iowa"},{"attributes": {"type": "States__c"},"Name": "ID","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Idaho"},{"attributes": {"type": "States__c"},"Name": "IL","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "AITT","StateFullName__c": "Illinois"},{"attributes": {"type": "States__c"},"Name": "IN","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Indiana"},{"attributes": {"type": "States__c"},"Name": "KS","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Kansas"},{"attributes": {"type": "States__c"},"Name": "KY","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Kentucky"},{"attributes": {"type": "States__c"},"Name": "LA","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Louisiana"},{"attributes": {"type": "States__c"},"Name": "MA","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "AMAT","StateFullName__c": "Massachusetts"},{"attributes": {"type": "States__c"},"Name": "MD","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Maryland"},{"attributes": {"type": "States__c"},"Name": "ME","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Maine"},{"attributes": {"type": "States__c"},"Name": "MH","DefaultTimeZoneKey__c": "Pacific/Fiji","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Marshall Islands"},{"attributes": {"type": "States__c"},"Name": "MI","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "AMTT","StateFullName__c": "Michigan"},{"attributes": {"type": "States__c"},"Name": "MN","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "MI01,MI02,MI03","StateFullName__c": "Minnesota"},{"attributes": {"type": "States__c"},"Name": "MO","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Missouri"},{"attributes": {"type": "States__c"},"Name": "MP","DefaultTimeZoneKey__c": "Australia/Sydney","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Northern Mariana Islands"},{"attributes": {"type": "States__c"},"Name": "MS","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Mississippi"},{"attributes": {"type": "States__c"},"Name": "MT","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Montana"},{"attributes": {"type": "States__c"},"Name": "NC","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "North Carolinas"},{"attributes": {"type": "States__c"},"Name": "ND","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "North Dakotas"},{"attributes": {"type": "States__c"},"Name": "NE","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Nebraska"},{"attributes": {"type": "States__c"},"Name": "NH","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "New Hampshire"},{"attributes": {"type": "States__c"},"Name": "NJ","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "New Jersey"},{"attributes": {"type": "States__c"},"Name": "NM","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "ANMT","StateFullName__c": "New Mexico"},{"attributes": {"type": "States__c"},"Name": "NV","DefaultTimeZoneKey__c": "America/Los_Angeles","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Nevada"},{"attributes": {"type": "States__c"},"Name": "NY","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "NY01 LAST","StateFullName__c": "New York"},{"attributes": {"type": "States__c"},"Name": "OH","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Ohio"},{"attributes": {"type": "States__c"},"Name": "OK","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "OK74","StateFullName__c": "Oklahoma"},{"attributes": {"type": "States__c"},"Name": "OR","DefaultTimeZoneKey__c": "America/Los_Angeles","EducatorBasicSkillsCodes__c": "ACBC AWBT PXST","StateFullName__c": "Oregon"},{"attributes": {"type": "States__c"},"Name": "PA","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "SGAF","StateFullName__c": "Pennsylvania"},{"attributes": {"type": "States__c"},"Name": "PR","DefaultTimeZoneKey__c": "America/Puerto_Rico","EducatorBasicSkillsCodes__c": "SGAI","StateFullName__c": "Puerto Rico"},{"attributes": {"type": "States__c"},"Name": "PW","DefaultTimeZoneKey__c": "Asia/Tokyo","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Palau"},{"attributes": {"type": "States__c"},"Name": "RI","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Rhode Island"},{"attributes": {"type": "States__c"},"Name": "SC","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "South Carolina"},{"attributes": {"type": "States__c"},"Name": "SD","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "South Dakota"},{"attributes": {"type": "States__c"},"Name": "TN","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Tennessee"},{"attributes": {"type": "States__c"},"Name": "TX","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "ATHT PXST","StateFullName__c": "Texas"},{"attributes": {"type": "States__c"},"Name": "UT","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Utah"},{"attributes": {"type": "States__c"},"Name": "VA","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Virginia"},{"attributes": {"type": "States__c"},"Name": "VI","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "VCLT","StateFullName__c": "Virgin Islands"},{"attributes": {"type": "States__c"},"Name": "VT","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Vermont"},{"attributes": {"type": "States__c"},"Name": "WA","DefaultTimeZoneKey__c": "America/Los_Angeles","EducatorBasicSkillsCodes__c": "AWBT","StateFullName__c": "Washington"},{"attributes": {"type": "States__c"},"Name": "WI","DefaultTimeZoneKey__c": "America/Chicago","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Wisconsin"},{"attributes": {"type": "States__c"},"Name": "WV","DefaultTimeZoneKey__c": "America/New_York","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "West Virginia"},{"attributes": {"type": "States__c"},"Name": "WY","DefaultTimeZoneKey__c": "America/Denver","EducatorBasicSkillsCodes__c": "PXST","StateFullName__c": "Wyoming"}]';
         List<States__c> states = (List<States__c>)JSON.deserialize(statesJson, List<States__c>.class);
         insert states;
        }
     
     }  //END Test.isRunningTest()           
        
  } //END setupCustomSettingTestData()
  
  
  public static void setupKeyValueTestData() {

        if ( Test.isRunningTest() && [select count() from KeyValue__c] == 0 ) { //Setup some KeyValue__c custom setting data for testing

            //Capture the RecordType Ids for the current Org
            Map<String,Id> keyValueRecordTypesMap = new Map<String,Id>();
            for ( RecordType rt: [SELECT DeveloperName,Id from RecordType where sObjectType = 'KeyValue__c']){
              keyValueRecordTypesMap.put( rt.DeveloperName, rt.Id );
            }        
            System.debug( LoggingLevel.DEBUG, 'KEYVALUE__C RecordTypes: ' + keyValueRecordTypesMap );
          
          //IF THE NEED ARISES TO REFRESH THE KEYVALUE__C STATIC RESOURCE LIST BELOW, USE THE CODE BELOW (Execute Anonymous) AND REPLACE THE JSON STRING ARRAY (keyValuesJSON)
          //REFRESH CODE START 
          /*
              List<KeyValue__c> values = [Select Value__c, RecordTypeId, RecordType.DeveloperName,  NumericValue__c, Name, ExternalID__c From KeyValue__c];
              List<KeyValue__c> valuesForInsert = new List<KeyValue__c>();
              String[] inserts = new String[values.size()]; 
              for ( Integer x = 0; x < values.size(); x++ ) {
                KeyValue__c k = values[x];
                KeyValue__c newValue = new KeyValue__c();
                newValue.Value__c = k.Value__c;
                newValue.RecordTypeId = k.RecordTypeId;
                newValue.Name = k.Name;
                newValue.NumericValue__c = k.NumericValue__c;
                newValue.ExternalID__c = k.ExternalID__c;
                inserts[x] = String.escapeSingleQuotes(JSON.serialize(newValue)).replace( k.RecordTypeId, '\'+keyValueRecordTypesMap.get(\''+k.RecordType.DeveloperName+'\')+\'' );
              }
              
              String script = 'String[] keyValuesJSON = new String[]{\n';
              boolean firstString = true;
              for ( String s: inserts ) {
                script += (firstString? '\''+s+'\'': ',\''+s+'\'')+',\n';
              }
              script = script.substring(0, script.length()-2);
              System.debug('RESULT:   '+script + '\n};');
          */
          //REFRESH CODE END

          //This is designed to populate KeyValue__c records for testing purposes in an Org-independent way (RecordTypeId values can differ across Orgs) 
          String[] keyValuesJSON = new String[]{
                    '{"attributes":{"type":"KeyValue__c"},"Name":"12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"Concentration12","NumericValue__c":null,"Value__c":"(5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"Concentration8","NumericValue__c":null,"Value__c":"5-8"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"9","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"Concentration9","NumericValue__c":null,"Value__c":"(5-9)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"B12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationB12","NumericValue__c":null,"Value__c":"Biological Science (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"B12P","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationB12P","NumericValue__c":null,"Value__c":"Biological Science (5-12) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BI","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationBI","NumericValue__c":null,"Value__c":"Biology"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BI12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationBI12","NumericValue__c":null,"Value__c":"Biology (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CH12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationCH12","NumericValue__c":null,"Value__c":"Chemistry (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CNE","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationCNE","NumericValue__c":null,"Value__c":"Certified Novell Engineer"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DB","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationDB","NumericValue__c":null,"Value__c":"Databases Emphasis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DBPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationDBPT","NumericValue__c":null,"Value__c":"Databases Emphasis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ED","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationED","NumericValue__c":null,"Value__c":"Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EDGR","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationEDGR","NumericValue__c":null,"Value__c":"Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EDUG","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationEDUG","NumericValue__c":null,"Value__c":"Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"G12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationG12","NumericValue__c":null,"Value__c":"Geosciences (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"G12P","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationG12P","NumericValue__c":null,"Value__c":"Geosciences (5-12) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GS12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationGS12","NumericValue__c":null,"Value__c":"Geoscience (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HR","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationHR","NumericValue__c":null,"Value__c":"HR Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HRPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationHRPT","NumericValue__c":null,"Value__c":"Business - HR Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ISK8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationISK8","NumericValue__c":null,"Value__c":"Interdisciplinary Study (K-8)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ISP8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationISP8","NumericValue__c":null,"Value__c":"Interdisciplinary Studies PK-8"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ISPB","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationISPB","NumericValue__c":null,"Value__c":"Interdisp. Studies (K-8) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ITM","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationITM","NumericValue__c":null,"Value__c":"IT Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ITPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationITPT","NumericValue__c":null,"Value__c":"IT Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"K-6","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationK-6","NumericValue__c":null,"Value__c":"(K-6)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"K-8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationK-8","NumericValue__c":null,"Value__c":"(K-8)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"K6","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationK6","NumericValue__c":null,"Value__c":"(K-6)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"K8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationK8","NumericValue__c":null,"Value__c":"(K-8)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LM","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationLM","NumericValue__c":null,"Value__c":"Leadership and Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LMGR","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationLMGR","NumericValue__c":null,"Value__c":"Leadership and Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LMUG","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationLMUG","NumericValue__c":null,"Value__c":"Leadership and Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"M12P","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationM12P","NumericValue__c":null,"Value__c":"Mathematics (5-12) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationMA","NumericValue__c":null,"Value__c":"Mathematics"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationMA12","NumericValue__c":null,"Value__c":"(5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA9","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationMA9","NumericValue__c":null,"Value__c":"(5-9)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA9P","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationMA9P","NumericValue__c":null,"Value__c":"Mathematics (5-9) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NA","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationNA","NumericValue__c":null,"Value__c":"IT-Network Administration"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ND","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationND","NumericValue__c":null,"Value__c":"Network Design & Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NDPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationNDPT","NumericValue__c":null,"Value__c":"Networks Design & Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NM","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationNM","NumericValue__c":null,"Value__c":"Network Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NW","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationNW","NumericValue__c":null,"Value__c":"Network Administration"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NWPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationNWPT","NumericValue__c":null,"Value__c":"Networks Administration Emph"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"P12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationP12","NumericValue__c":null,"Value__c":"(PreK-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"P8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationP8","NumericValue__c":null,"Value__c":"PK-8"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PH12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationPH12","NumericValue__c":null,"Value__c":"Physics (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PK-8","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationPK-8","NumericValue__c":null,"Value__c":"PreK-8"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PK12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationPK12","NumericValue__c":null,"Value__c":"(PreK-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PM","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationPM","NumericValue__c":null,"Value__c":"Project Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationPT","NumericValue__c":null,"Value__c":"Part-time"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PX12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationPX12","NumericValue__c":null,"Value__c":"Social Science (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"S12P","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationS12P","NumericValue__c":null,"Value__c":"Social Science (5-12) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SC","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSC","NumericValue__c":null,"Value__c":"Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SC12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSC12","NumericValue__c":null,"Value__c":"Science 5-12"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SC9","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSC9","NumericValue__c":null,"Value__c":"Science (5-9)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SC9P","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSC9P","NumericValue__c":null,"Value__c":"Science (5-9) PB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SD","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSD","NumericValue__c":null,"Value__c":"Software Development"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SEC","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSEC","NumericValue__c":null,"Value__c":"Security Emphasis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SEPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSEPT","NumericValue__c":null,"Value__c":"Security Emphasis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SF","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSF","NumericValue__c":null,"Value__c":"Software Emphasis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SFPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSFPT","NumericValue__c":null,"Value__c":"Software Emphasis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SS","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSS","NumericValue__c":null,"Value__c":"Social Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SS12","RecordTypeId":"'+keyValueRecordTypesMap.get('Concentration')+'","ExternalID__c":"ConcentrationSS12","NumericValue__c":null,"Value__c":"Social Science (5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"0","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision0","NumericValue__c":null,"Value__c":"Developmental"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"1","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision1","NumericValue__c":null,"Value__c":"General Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"2","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision2","NumericValue__c":null,"Value__c":"Lower Division Major"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"3","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision3","NumericValue__c":null,"Value__c":"Upper Division Major"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"4","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision4","NumericValue__c":null,"Value__c":"Senior"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"5","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision5","NumericValue__c":null,"Value__c":"First Year Master\'s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"6","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision6","NumericValue__c":null,"Value__c":"Second Year Master\'s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"7","RecordTypeId":"'+keyValueRecordTypesMap.get('CourseDivision')+'","ExternalID__c":"CourseDivision7","NumericValue__c":null,"Value__c":"Doctoral"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"000000","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"000000","NumericValue__c":0.00,"Value__c":"Undeclared"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AA","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"AA","NumericValue__c":50.00,"Value__c":"Associate of Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AAS","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"AAS","NumericValue__c":40.00,"Value__c":"Associate of Applied Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AS","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"AS","NumericValue__c":50.00,"Value__c":"Associate of Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BA","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"BA","NumericValue__c":100.00,"Value__c":"Bachelor of Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BS","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"BS","NumericValue__c":100.00,"Value__c":"Bachelor of Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CERT","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"CERT","NumericValue__c":0.00,"Value__c":"Certificate"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"END","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"END","NumericValue__c":0.00,"Value__c":"Endorsement Preparation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"MA","NumericValue__c":200.00,"Value__c":"Master of Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MAT","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"MAT","NumericValue__c":200.00,"Value__c":"Master of Arts in Teaching"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MBA","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"MBA","NumericValue__c":200.00,"Value__c":"Master of Business Admin"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MED","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"MED","NumericValue__c":200.00,"Value__c":"Master of Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MS","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"MS","NumericValue__c":200.00,"Value__c":"Master of Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ND","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"ND","NumericValue__c":0.00,"Value__c":"Non Degree"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PB","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"PB","NumericValue__c":0.00,"Value__c":"Post Baccalaureate"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STF","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"STF","NumericValue__c":0.00,"Value__c":"Second Teaching Field"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TEND","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"TEND","NumericValue__c":0.00,"Value__c":"Endorsement Preparation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TEST","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"TEST","NumericValue__c":0.00,"Value__c":"Test"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TP","RecordTypeId":"'+keyValueRecordTypesMap.get('TransferDegree')+'","ExternalID__c":"TP","NumericValue__c":0.00,"Value__c":"Content Preparation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"000","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"Department000","NumericValue__c":null,"Value__c":"Default value for LRs"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"0000","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"Department0000","NumericValue__c":null,"Value__c":"Undeclared"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BU","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentBU","NumericValue__c":null,"Value__c":"Business"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CP","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentCP","NumericValue__c":null,"Value__c":"Capstone"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EC","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentEC","NumericValue__c":null,"Value__c":"Early Childhood Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ED","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentED","NumericValue__c":null,"Value__c":"Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EDL","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentEDL","NumericValue__c":null,"Value__c":"Educational Leadership"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EL","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentEL","NumericValue__c":null,"Value__c":"Elementary Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GR","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentGR","NumericValue__c":null,"Value__c":"Graduate Core"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HP","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentHP","NumericValue__c":null,"Value__c":"Health Professions"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IT","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentIT","NumericValue__c":null,"Value__c":"Information Technology"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LA","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentLA","NumericValue__c":null,"Value__c":"Liberal Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LL","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentLL","NumericValue__c":null,"Value__c":"English Language Learning"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentMA","NumericValue__c":null,"Value__c":"Mathematics"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SC","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentSC","NumericValue__c":null,"Value__c":"Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SP","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentSP","NumericValue__c":null,"Value__c":"Special Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SS","RecordTypeId":"'+keyValueRecordTypesMap.get('Department')+'","ExternalID__c":"DepartmentSS","NumericValue__c":null,"Value__c":"Social Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"0000","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"Major0000","NumericValue__c":null,"Value__c":"Undeclared"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AC","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorAC","NumericValue__c":null,"Value__c":"Accounting"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BU","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorBU","NumericValue__c":null,"Value__c":"Business"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BUS","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorBUS","NumericValue__c":null,"Value__c":"Business"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CHS","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorCHS","NumericValue__c":null,"Value__c":"Community Health Services"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CI","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorCI","NumericValue__c":null,"Value__c":"Computer Information Systems"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CIC","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorCIC","NumericValue__c":null,"Value__c":"Clinical Instructor"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CIN","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorCIN","NumericValue__c":null,"Value__c":"Curriculum and Instruction"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CTA","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorCTA","NumericValue__c":null,"Value__c":"Clinical Teaching Assistant"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ECE","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorECE","NumericValue__c":null,"Value__c":"Early Childhood Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EDL","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorEDL","NumericValue__c":null,"Value__c":"Educational Leadership"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EL","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorEL","NumericValue__c":null,"Value__c":"Elementary Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ELL","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorELL","NumericValue__c":null,"Value__c":"English Language Learning"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ES","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorES","NumericValue__c":null,"Value__c":"Educational Studies"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EV","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorEV","NumericValue__c":null,"Value__c":"Measurement and Evaluation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"FI","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorFI","NumericValue__c":null,"Value__c":"Finance"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GE","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorGE","NumericValue__c":null,"Value__c":"General Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GSC","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorGSC","NumericValue__c":null,"Value__c":"General Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HE","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorHE","NumericValue__c":null,"Value__c":"Health Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HI","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorHI","NumericValue__c":null,"Value__c":"Health Informatics"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HM","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorHM","NumericValue__c":null,"Value__c":"Healthcare Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ID","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorID","NumericValue__c":null,"Value__c":"Instructional Design"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ISA","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorISA","NumericValue__c":null,"Value__c":"Info Security & Assurance"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IT","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorIT","NumericValue__c":null,"Value__c":"Information Technology"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ITM","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorITM","NumericValue__c":null,"Value__c":"IT Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ITNM","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorITNM","NumericValue__c":null,"Value__c":"IT Network Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LT","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorLT","NumericValue__c":null,"Value__c":"Learning and Technology"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMA","NumericValue__c":null,"Value__c":"Mathematics"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA12","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMA12","NumericValue__c":null,"Value__c":"(5-12)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MAC","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMAC","NumericValue__c":null,"Value__c":"Management Accounting"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ME","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorME","NumericValue__c":null,"Value__c":"Mathematics Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MEV","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMEV","NumericValue__c":null,"Value__c":"Measurement and Evaluation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MG","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMG","NumericValue__c":null,"Value__c":"Business Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MGPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMGPT","NumericValue__c":null,"Value__c":"Business Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MI","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMI","NumericValue__c":null,"Value__c":"Management and Innovation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MK","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMK","NumericValue__c":null,"Value__c":"Marketing Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MKPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMKPT","NumericValue__c":null,"Value__c":"Marketing Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MS","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorMS","NumericValue__c":null,"Value__c":"Management and Strategy"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NU","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorNU","NumericValue__c":null,"Value__c":"Nursing"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ONE","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorONE","NumericValue__c":null,"Value__c":"One"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PRN","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorPRN","NumericValue__c":null,"Value__c":"Nursing - Pre-Nurse Curriculum"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PS","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorPS","NumericValue__c":null,"Value__c":"Professional Studies"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PSPT","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorPSPT","NumericValue__c":null,"Value__c":"Professional Studies"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"RN","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorRN","NumericValue__c":null,"Value__c":"Nursing (Pre-Licensure)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"RNNU","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorRNNU","NumericValue__c":null,"Value__c":"Nursing (RN to MSN)"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SC","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSC","NumericValue__c":null,"Value__c":"Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SE","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSE","NumericValue__c":null,"Value__c":"Science Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SL","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSL","NumericValue__c":null,"Value__c":"Strategic Leadership"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SM","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSM","NumericValue__c":null,"Value__c":"Sales and Sales Management"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SP","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSP","NumericValue__c":null,"Value__c":"Special Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPNV","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSPNV","NumericValue__c":null,"Value__c":"Special Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SS","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorSS","NumericValue__c":null,"Value__c":"Social Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TE","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorTE","NumericValue__c":null,"Value__c":"Technology"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TPLU","RecordTypeId":"'+keyValueRecordTypesMap.get('Major')+'","ExternalID__c":"MajorTPLU","NumericValue__c":null,"Value__c":"T-PLUS"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GR","RecordTypeId":"'+keyValueRecordTypesMap.get('ProgramLevel')+'","ExternalID__c":"ProgramLevelGR","NumericValue__c":null,"Value__c":"Graduate"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"UG","RecordTypeId":"'+keyValueRecordTypesMap.get('ProgramLevel')+'","ExternalID__c":"ProgramLevelUG","NumericValue__c":null,"Value__c":"Undergraduate"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"000000","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"Degree000000","NumericValue__c":null,"Value__c":"Undeclared"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AA","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeAA","NumericValue__c":null,"Value__c":"Associate of Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AAS","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeAAS","NumericValue__c":null,"Value__c":"Associate of Applied Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AS","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeAS","NumericValue__c":null,"Value__c":"Associate of Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BA","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeBA","NumericValue__c":null,"Value__c":"Bachelor of Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BS","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeBS","NumericValue__c":null,"Value__c":"Bachelor of Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CERT","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeCERT","NumericValue__c":null,"Value__c":"Certificate"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"END","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeEND","NumericValue__c":null,"Value__c":"Endorsement Preparation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MA","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeMA","NumericValue__c":null,"Value__c":"Master of Arts"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MAT","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeMAT","NumericValue__c":null,"Value__c":"Master of Arts in Teaching"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MBA","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeMBA","NumericValue__c":null,"Value__c":"Master of Business Admin"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MED","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeMED","NumericValue__c":null,"Value__c":"Master of Education"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MS","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeMS","NumericValue__c":null,"Value__c":"Master of Science"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ND","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeND","NumericValue__c":null,"Value__c":"Non Degree"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PB","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreePB","NumericValue__c":null,"Value__c":"Post Baccalaureate"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STF","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeSTF","NumericValue__c":null,"Value__c":"Second Teaching Field"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TEND","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeTEND","NumericValue__c":null,"Value__c":"Endorsement Preparation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TEST","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeTEST","NumericValue__c":null,"Value__c":"Test"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TP","RecordTypeId":"'+keyValueRecordTypesMap.get('Degree')+'","ExternalID__c":"DegreeTP","NumericValue__c":null,"Value__c":"Content Preparation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"FAFSA","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"FAFSA","NumericValue__c":null,"Value__c":"Fed. Aid Appl."}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MILITARY","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"Military Verification"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EMPLR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"Employer Verification"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MEMBERSHIP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"Membership Verification"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"UNEMPLE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"Unemployment Essay"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"RESUME","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"The Resume of an applicaiton"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LOR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"Letter(s) of Recommendation"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TRANSCRIPT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":null,"NumericValue__c":null,"Value__c":"Transcript Status"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SSIGN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SSIGN","NumericValue__c":null,"Value__c":"Student Signature"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DEPOVR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DEPOVR","NumericValue__c":null,"Value__c":"Dependency Override"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DRUG","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DRUG","NumericValue__c":null,"Value__c":"Drug Worksheet"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"BNKRPT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"BNKRPT","NumericValue__c":null,"Value__c":"Active Bankruptcy"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DEFALT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DEFALT","NumericValue__c":null,"Value__c":"Student Loan Default"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PASSET","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PASSET","NumericValue__c":null,"Value__c":"DNU Parent Asset Frm"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SASSET","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SASSET","NumericValue__c":null,"Value__c":"Student Asset Form"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PSIGN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PSIGN","NumericValue__c":null,"Value__c":"Parent Signature"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GPLUS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"GPLUS","NumericValue__c":null,"Value__c":"Graduate Plus App"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SCHAGR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SCHAGR","NumericValue__c":null,"Value__c":"DNU-Scholarship Agmt"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AUTHOR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AUTHOR","NumericValue__c":null,"Value__c":"Release Authorizatio"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DVER09","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DVER09","NumericValue__c":null,"Value__c":"0809 Dep Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CONSOL","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CONSOL","NumericValue__c":null,"Value__c":"DNU-Consol Loan Info"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DD214","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DD214","NumericValue__c":null,"Value__c":"DD214"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DPLSMP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DPLSMP","NumericValue__c":null,"Value__c":"DNU-Dep. Plus MPN"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IVWS09","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"IVWS09","NumericValue__c":null,"Value__c":"0809 Ind Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LOANMX","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"LOANMX","NumericValue__c":null,"Value__c":"Agg Loan Maximum"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"REJECT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"REJECT","NumericValue__c":null,"Value__c":"FAFSA Reject"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ENTRNC","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ENTRNC","NumericValue__c":null,"Value__c":"Entrance Counseling"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DISABI","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DISABI","NumericValue__c":null,"Value__c":"Disability Form"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTX07","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTX07","NumericValue__c":null,"Value__c":"Spouse\'s 2007 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTX06","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTX06","NumericValue__c":null,"Value__c":"Spouse\'s 2006 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TERMBK","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TERMBK","NumericValue__c":null,"Value__c":"DNU-Term Break"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"APEAL1","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"APEAL1","NumericValue__c":null,"Value__c":"1st Appeal"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EXIT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"EXIT","NumericValue__c":null,"Value__c":"Exit Counseling"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"OVRPMT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"OVRPMT","NumericValue__c":null,"Value__c":"Grant Overpayment"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"221990","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"221990","NumericValue__c":null,"Value__c":"Form 22-1990"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"APEAL2","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"APEAL2","NumericValue__c":null,"Value__c":"2nd Appeal"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"HSGED","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"HSGED","NumericValue__c":null,"Value__c":"HS Diploma or GED"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TIV","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TIV","NumericValue__c":null,"Value__c":"Pay non-inst charges"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"FFLMPN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"FFLMPN","NumericValue__c":null,"Value__c":"FFEL MPN"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"VA","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"VA","NumericValue__c":null,"Value__c":"DNU-VA Benefits"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"LOANDS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"LOANDS","NumericValue__c":null,"Value__c":"Loan Discharge"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NONCIT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"NONCIT","NumericValue__c":null,"Value__c":"Proof of Non Citizen"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"OVERLP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"OVERLP","NumericValue__c":null,"Value__c":"Overlapping Loan"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PMARDI","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PMARDI","NumericValue__c":null,"Value__c":"Parent Marriage/Div"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PRIVAT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PRIVAT","NumericValue__c":null,"Value__c":"Private Loan App"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"REPMNT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"REPMNT","NumericValue__c":null,"Value__c":"DNU-Repayment Letter"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SBIRTH","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SBIRTH","NumericValue__c":null,"Value__c":"Student\'s Birth Cert"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SEPINC","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SEPINC","NumericValue__c":null,"Value__c":"Separation of Income"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SMARDI","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SMARDI","NumericValue__c":null,"Value__c":"Student Marriage/Div"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STAX06","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STAX06","NumericValue__c":null,"Value__c":"Student 2006 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STAX07","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STAX07","NumericValue__c":null,"Value__c":"Student 2007 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PTAX07","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PTAX07","NumericValue__c":null,"Value__c":"Parent 2007 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PW207","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PW207","NumericValue__c":null,"Value__c":"Parent 2007 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPW206","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPW206","NumericValue__c":null,"Value__c":"Spouse 2006 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPW207","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPW207","NumericValue__c":null,"Value__c":"Spouse 2007 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SW206","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SW206","NumericValue__c":null,"Value__c":"Student 2006 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SW207","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SW207","NumericValue__c":null,"Value__c":"Student 2007 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPEC09","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPEC09","NumericValue__c":null,"Value__c":"0809 Special Circ"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"WKSABC","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"WKSABC","NumericValue__c":null,"Value__c":"Worksheet ABC"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ADMIT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ADMIT","NumericValue__c":null,"Value__c":"Admissions Decision"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CITZEN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CITZEN","NumericValue__c":null,"Value__c":"Resolve Issues w/SSA"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"INTAPP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"INTAPP","NumericValue__c":null,"Value__c":"WGU Inst. App"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SELSER","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SELSER","NumericValue__c":null,"Value__c":"Selective Service"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SOCSEC","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SOCSEC","NumericValue__c":null,"Value__c":"Social Sec. Verif."}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SAP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SAP","NumericValue__c":null,"Value__c":"SAP"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PRYEAR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PRYEAR","NumericValue__c":null,"Value__c":"Pay Prior Year"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CORECT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CORECT","NumericValue__c":null,"Value__c":"FAFSA Correction"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PRTERM","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PRTERM","NumericValue__c":null,"Value__c":"Pay Prior Term"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STUSTA","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STUSTA","NumericValue__c":null,"Value__c":"Student Statement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CANLET","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CANLET","NumericValue__c":null,"Value__c":"Cancelation Letter"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DISHOM","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DISHOM","NumericValue__c":null,"Value__c":"DNU - Displaced Home"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TCHENT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TCHENT","NumericValue__c":null,"Value__c":"TEACH Entrance"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SCHACC","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SCHACC","NumericValue__c":null,"Value__c":"Accept Scholarship"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TCHEXT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TCHEXT","NumericValue__c":null,"Value__c":"TEACH Exit"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TCHATS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TCHATS","NumericValue__c":null,"Value__c":"TEACH ATS"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PEND","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PEND","NumericValue__c":null,"Value__c":"Pend for FA Review"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"OVRAGG","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"OVRAGG","NumericValue__c":null,"Value__c":"Over Agg Limit"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SW209","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SW209","NumericValue__c":null,"Value__c":"Student 2009 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"START","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"START","NumericValue__c":null,"Value__c":"Start date"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NORESP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"NORESP","NumericValue__c":null,"Value__c":"DNU-No Response"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"OLPAWD","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"OLPAWD","NumericValue__c":null,"Value__c":"Overlap loan awarded"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"T&C","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"T&C","NumericValue__c":null,"Value__c":"Terms and Conditions"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TRANS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TRANS","NumericValue__c":null,"Value__c":"Transfer Question"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"WARDCT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"WARDCT","NumericValue__c":null,"Value__c":"Ward of the Court"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DECLIN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DECLIN","NumericValue__c":null,"Value__c":"Declined Aid"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"OLPAGR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"OLPAGR","NumericValue__c":null,"Value__c":"Overlap Agreement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"COPREP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"COPREP","NumericValue__c":null,"Value__c":"Content Prep"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"1040X","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"1040X","NumericValue__c":null,"Value__c":"Amended Tax Forms"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MISCTX","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"MISCTX","NumericValue__c":null,"Value__c":"Other Tax Documents"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NSLDS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"NSLDS","NumericValue__c":null,"Value__c":"NSLDS Review"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"COSOVR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"COSOVR","NumericValue__c":null,"Value__c":"Cross over award"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MIDAY","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"MIDAY","NumericValue__c":null,"Value__c":"DNU-Mid Award Year"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PTAX08","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PTAX08","NumericValue__c":null,"Value__c":"Parent 2008 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STAX08","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STAX08","NumericValue__c":null,"Value__c":"Student 2008 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PW208","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PW208","NumericValue__c":null,"Value__c":"Parent 2008 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPW208","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPW208","NumericValue__c":null,"Value__c":"Spouse 2008 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CNSLDS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CNSLDS","NumericValue__c":null,"Value__c":"NSLDS Continuing Stu"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SW208","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SW208","NumericValue__c":null,"Value__c":"Student 2008 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IVWS10","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"IVWS10","NumericValue__c":null,"Value__c":"0910 Ind Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DVER10","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DVER10","NumericValue__c":null,"Value__c":"0910 Dep Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPEC10","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPEC10","NumericValue__c":null,"Value__c":"0910 Special Circ"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTX08","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTX08","NumericValue__c":null,"Value__c":"Spouse\'s 2008 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PJ","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PJ","NumericValue__c":null,"Value__c":"Prof Judgement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CPEND","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CPEND","NumericValue__c":null,"Value__c":"Pended for Review"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TPTC","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TPTC","NumericValue__c":null,"Value__c":"Teach Prep T&C"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PELL66","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PELL66","NumericValue__c":null,"Value__c":"DNUPell 66 error cod"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DISWOR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DISWOR","NumericValue__c":null,"Value__c":"DNU - Disloc  Worker"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DVER11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DVER11","NumericValue__c":null,"Value__c":"1011 Dep Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EWB","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"EWB","NumericValue__c":null,"Value__c":"EWB"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IVWS11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"IVWS11","NumericValue__c":null,"Value__c":"1011 Ind Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SSACI","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SSACI","NumericValue__c":null,"Value__c":"Indiana Grant"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SAPACP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SAPACP","NumericValue__c":null,"Value__c":"Academic Plan"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"APEALD","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"APEALD","NumericValue__c":null,"Value__c":"Appeal Denied"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"QUES52","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"QUES52","NumericValue__c":null,"Value__c":"FAFSA Foster Care"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"QUES53","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"QUES53","NumericValue__c":null,"Value__c":"FAFSA Emancipated"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"QUES54","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"QUES54","NumericValue__c":null,"Value__c":"FAFSA Legal Guardian"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"QUES55","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"QUES55","NumericValue__c":null,"Value__c":"FAFSA Unaccompanied"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"QUES56","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"QUES56","NumericValue__c":null,"Value__c":"FAFSA Unaccompanied"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PW209","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PW209","NumericValue__c":null,"Value__c":"Parent 2009 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPEC11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPEC11","NumericValue__c":null,"Value__c":"1011 Special Circ"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTX09","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTX09","NumericValue__c":null,"Value__c":"Spouse\'s 2009 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPW209","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPW209","NumericValue__c":null,"Value__c":"Spouse 2009 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STAX09","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STAX09","NumericValue__c":null,"Value__c":"Student 2009 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CFLAG","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CFLAG","NumericValue__c":null,"Value__c":"SAR C-FLAG"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"VERIFY","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"VERIFY","NumericValue__c":null,"Value__c":"Verification Complet"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ACCEPT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ACCEPT","NumericValue__c":null,"Value__c":"Accept Award"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AGGCLO","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AGGCLO","NumericValue__c":null,"Value__c":"Agg Limit Almost Max"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"INELIG","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"INELIG","NumericValue__c":null,"Value__c":"FA Issue"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CANDLL","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CANDLL","NumericValue__c":null,"Value__c":"DL Pend Disbursement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"QUES57","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"QUES57","NumericValue__c":null,"Value__c":"FAFSA Unaccompanied"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"FICAAD","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"FICAAD","NumericValue__c":null,"Value__c":"Additional Documents"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLCONV","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLCONV","NumericValue__c":null,"Value__c":"DNU Decide DL Switch"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLGMPN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLGMPN","NumericValue__c":null,"Value__c":"DL Grad PLUS MPN"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLPMPN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLPMPN","NumericValue__c":null,"Value__c":"DL Plus MPN"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLGENT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLGENT","NumericValue__c":null,"Value__c":"DL Grad Entrance"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLPENT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLPENT","NumericValue__c":null,"Value__c":"DL Plus Entrance"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PLCRCK","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PLCRCK","NumericValue__c":null,"Value__c":"Plus Credit Check"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AGGAGR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AGGAGR","NumericValue__c":null,"Value__c":"Aggregate Agreement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SSFEMA","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SSFEMA","NumericValue__c":null,"Value__c":"Sel Service Female"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PREFUS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PREFUS","NumericValue__c":null,"Value__c":"Parnt Refusal Letter"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"UNDR18","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"UNDR18","NumericValue__c":null,"Value__c":"Under 18"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"REINST","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"REINST","NumericValue__c":null,"Value__c":"Reinstate Aid"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EXITMA","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"EXITMA","NumericValue__c":null,"Value__c":"Exit Letter Mailed"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TMRCHK","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TMRCHK","NumericValue__c":null,"Value__c":"NSLDS Recheck"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SAPRE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SAPRE","NumericValue__c":null,"Value__c":"SAP Reinstatement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PJTELE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PJTELE","NumericValue__c":null,"Value__c":"Termination Letter"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLENTR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLENTR","NumericValue__c":null,"Value__c":"DL Entr. Counseling"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLMPN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLMPN","NumericValue__c":null,"Value__c":"DL MPN"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EXIT2","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"EXIT2","NumericValue__c":null,"Value__c":"Exit Counseling"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EXIT3","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"EXIT3","NumericValue__c":null,"Value__c":"Exit Counseling"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"EXIT4","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"EXIT4","NumericValue__c":null,"Value__c":"Exit Counseling"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"REVINP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"REVINP","NumericValue__c":null,"Value__c":"Revision In Process"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PJPAYS","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PJPAYS","NumericValue__c":null,"Value__c":"Paystub"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PJUNBE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PJUNBE","NumericValue__c":null,"Value__c":"Unemployment Benefit"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLMPNY","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLMPNY","NumericValue__c":null,"Value__c":"DL MPN"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DLENTY","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DLENTY","NumericValue__c":null,"Value__c":"DNU - DL Entr. Coun."}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AUTHPY","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AUTHPY","NumericValue__c":null,"Value__c":"Prior Year Auth"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AUTHT4","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AUTHT4","NumericValue__c":null,"Value__c":"Title IV Auth"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PREQ","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PREQ","NumericValue__c":null,"Value__c":"PLUS Loan Request"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTX10","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTX10","NumericValue__c":null,"Value__c":"Spouse\'s 2010 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPW210","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPW210","NumericValue__c":null,"Value__c":"Spouse 2010 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PTAX09","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PTAX09","NumericValue__c":null,"Value__c":"Parent 2009 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STAX10","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STAX10","NumericValue__c":null,"Value__c":"Student 2010 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"NOFILE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"NOFILE","NumericValue__c":null,"Value__c":"Non-Filer Statement"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ALTPRO","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ALTPRO","NumericValue__c":null,"Value__c":"Alternative Loan Pro"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ALTENT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ALTENT","NumericValue__c":null,"Value__c":"Alternative Ent"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ALTSCR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ALTSCR","NumericValue__c":null,"Value__c":"Self Certification"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DVER12","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DVER12","NumericValue__c":null,"Value__c":"1112 Dep Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IVWS12","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"IVWS12","NumericValue__c":null,"Value__c":"1112 Ind Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PTAX10","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PTAX10","NumericValue__c":null,"Value__c":"Parent 2010 Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PW210","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PW210","NumericValue__c":null,"Value__c":"Parent 2010 W2\'s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPEC12","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPEC12","NumericValue__c":null,"Value__c":"1112 Special Circ"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SW210","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SW210","NumericValue__c":null,"Value__c":"Student 2010 W2\'s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MSRNAG","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"MSRNAG","NumericValue__c":null,"Value__c":"MS Nursing Program"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"WILLFI","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"WILLFI","NumericValue__c":null,"Value__c":"Will File Taxes"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AGI10K","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AGI10K","NumericValue__c":null,"Value__c":"Income Docs"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TRACON","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TRACON","NumericValue__c":null,"Value__c":"Conflicting Trans"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SAPAPL","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SAPAPL","NumericValue__c":null,"Value__c":"SAP Appeal App"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"UNACO","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"UNACO","NumericValue__c":null,"Value__c":"Unaccompanied Youth"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"AGI10D","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"AGI10D","NumericValue__c":null,"Value__c":"Income Docs"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"VAADDN","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"VAADDN","NumericValue__c":null,"Value__c":"WGU Addendum"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"FADENI","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"FADENI","NumericValue__c":null,"Value__c":"Financial Aid Denial"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PSISIR","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PSISIR","NumericValue__c":null,"Value__c":"Post Screen ISIR"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TAXEXT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TAXEXT","NumericValue__c":null,"Value__c":"Tax Return Extension"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TXTR11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TXTR11","NumericValue__c":null,"Value__c":"Tax Transcript"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"199095","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"199095","NumericValue__c":null,"Value__c":"VA Form 22-199x"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"549095","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"549095","NumericValue__c":null,"Value__c":"VA Form 22-549X"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"CNFLCT","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"CNFLCT","NumericValue__c":null,"Value__c":"Conflicting Info"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DVER13","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DVER13","NumericValue__c":null,"Value__c":"1213 Dep Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"IVWS13","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"IVWS13","NumericValue__c":null,"Value__c":"1213 Ind Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PTAX11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PTAX11","NumericValue__c":null,"Value__c":"\'11 Parent Tax Info"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PW211","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PW211","NumericValue__c":null,"Value__c":"Parent 2011 W2\'s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPEC13","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPEC13","NumericValue__c":null,"Value__c":"1213 Special Circ"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPW211","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPW211","NumericValue__c":null,"Value__c":"Spouse 2011 W2s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTX11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTX11","NumericValue__c":null,"Value__c":"\'11 Spouse Tax Trans"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"221995","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"221995","NumericValue__c":null,"Value__c":"Form 22-1995"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"225490","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"225490","NumericValue__c":null,"Value__c":"Form 22-5490"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"225495","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"225495","NumericValue__c":null,"Value__c":"Form 22-5495"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"22199E","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"22199E","NumericValue__c":null,"Value__c":"Form 22-1990E"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"1905","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"1905","NumericValue__c":null,"Value__c":"Form 1905"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ADDEND","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"ADDEND","NumericValue__c":null,"Value__c":"Addendum"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"COE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"COE","NumericValue__c":null,"Value__c":"Cert of Eligibility"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TAFORM","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TAFORM","NumericValue__c":null,"Value__c":"Authorized TA Form"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"TRSEVL","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"TRSEVL","NumericValue__c":null,"Value__c":"Transcrpt Eval Satis"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"GRADPE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"GRADPE","NumericValue__c":null,"Value__c":"Grad Loans Pell Elig"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DISSUE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DISSUE","NumericValue__c":null,"Value__c":"Dependancy Issue"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STAX11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STAX11","NumericValue__c":null,"Value__c":"\'11 Student Tax Info"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SW211","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SW211","NumericValue__c":null,"Value__c":"Student 2011 W2\'s"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"FDSTMP","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"FDSTMP","NumericValue__c":null,"Value__c":"Food Stamp Verify"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"MARCHG","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"MARCHG","NumericValue__c":null,"Value__c":"Marital Status Chng"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"PTXF11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"PTXF11","NumericValue__c":null,"Value__c":"Parent 2011 1040"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"SPTF11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"SPTF11","NumericValue__c":null,"Value__c":"Spouse 2011 1040"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"STXF11","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"STXF11","NumericValue__c":null,"Value__c":"Student\'s 2011 1040"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"UN1040","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"UN1040","NumericValue__c":null,"Value__c":"Un Needed 1040 Form"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"DESITE","RecordTypeId":"'+keyValueRecordTypesMap.get('FinRequirement')+'","ExternalID__c":"DESITE","NumericValue__c":null,"Value__c":"Resp Borrowing Init"}',
                    '{"attributes":{"type":"KeyValue__c"},"Name":"ND","RecordTypeId":"'+keyValueRecordTypesMap.get('ProgramLevel')+'","ExternalID__c":"ProgramLevelND","NumericValue__c":null,"Value__c":"Non Degree"}'
                    };
                    
            List<KeyValue__c> keyValues = new List<KeyValue__c>();
                    for ( String keyValueJSON : keyValuesJSON ) {
                         KeyValue__c keyValue = (KeyValue__c)JSON.deserialize(keyValueJSON, KeyValue__c.class);
                         keyValues.add( keyValue );
                    }
            
            insert keyValues;
        } //END Setup Test KeyValue records
            
  }
  
  public static Contact setupStudentTestData() {

      Contact testStudent;
      if ( Test.isRunningTest() ) {
      
         User testUser = getSAdminUser();
         System.RunAs( testUser ) {
         
            getEnvironment();
            setupCustomSettingTestData();

            //setup up dummy student for testing
            if ( [SELECT count() FROM Contact where Name = 'Khadijah_test Abdullah_test' and PIDM__c = 'pctestka2'] == 0 ) {
               
               //CREATE Standard Test Student
               Id studentRecordId = [SELECT Id from RecordType where DeveloperName = 'StudentRecord' AND sObjectType = 'Contact'].Id; 
               String studentTestJson = '{  "attributes" : {    "type" : "Contact" },  "LastName" : "Abdullah_test",  "FirstName" : "Khadijah_test",  "RecordTypeId" : "'+studentRecordId+'",  "Phone" : "8015555555",  "MailingState" : "UT",  "MailingPostalCode" : "84044", "Email" : "khadijah.bogus.tester@bogus.wgu.edu",  "Title" : "Happy Khadijah", "PIDM__c" : "pctestka2", "FERPAIndicator__c" : false,  "ProgramCode__c" : "BAISK8",  "ProgramName__c" : "Bachelors In Something Very Important",  "StatusDate__c" : null,  "Status__c" : "AS",  "StudentID__c" : "QA1231231", "StudentOnManualRecheck__c" : false,  "StudentOnTermBreak__c" : false, "Deceased__c" : false, "IsActive__c" : true,  "OtherEmail__c" : "khadijah.bogus.tester@bogus.wgu.edu", "WGUEmail__c" : "khadijah.bogus.tester@bogus.wgu.edu", "OwnerId" : "'+testUser.Id+'"}';
               testStudent = (Contact)JSON.deserialize(studentTestJson, Contact.class);
               testStudent.SFAWEmailSent__c = true;
               testStudent.InitialFEEmailSent__c = true;
                   Date t = Date.today();
                   Integer tmonth = t.month();
                                 String month = (tmonth < 10)? '0'+String.valueOf(tmonth): String.ValueOf(tmonth);
                                 String year = String.valueOf(t.year());
                                 String programCode = year+month;
               testStudent.ProgramCatalogTerm__c = programCode;
               insert testStudent;
               testStudent = getContact();
               
               //ADD Student Completion Tasks for Testing
               if ( [select count() from StudentCompletionTask__c where Student__c = :testStudent.Id] == 0 ) {
                    List<StudentCompletionTask__c> academics = new List<StudentCompletionTask__c>();
                   academics.add( new StudentCompletionTask__c(Name='SFAW', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='PXST', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='HABR', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='LAST', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='NY01', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='MI01', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='MI02', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                   academics.add( new StudentCompletionTask__c(Name='MI03', RequirementComplete__c=true, Version__c=1, IsTestData__c=true, AssessmentStatus__c='Passed', Classification__c='Performance', Student__c=testStudent.Id) );
                 insert academics;
               }
                              
            } //END if ( [SELECT count() FROM Contact where Name = 'Khadijah_test Abdullah_test'] == 0 ) 
            
         } //System.RunAs   
      }  //END Test.isRunningTest()  
           
      return testStudent;       
  } //END setupStudentTestData()
  
  
  
  static testmethod void testStudentUserByUserId() {
  
    Contact studentContact = getTestStudentContact();    
    System.debug(LoggingLevel.DEBUG, 'TEST STUDENT CONTACT JSON: '+JSON.serialize(studentContact) );

    Test.startTest();

	    User studentUserRec = getTestStudentUser(studentContact.Id);
   		System.debug(LoggingLevel.DEBUG, 'TEST STUDENT USER JSON: '+JSON.serialize(studentUserRec) );
        
        StudentUser studentUser = new StudentUser(studentUserRec.id);  
        
        User testStudentUser = studentUser.getStudentUser(); 
        Contact testStudentContact = studentUser.getStudentContact(); 
            
    Test.stopTest();
    
        Account testStudentAccount = studentUser.getStudentAccount(); 
        
        System.debug(LoggingLevel.DEBUG, 'StudentUser.getStudentUser() TEST STUDENT USER JSON: '+JSON.serialize( testStudentUser) );
        System.debug(LoggingLevel.DEBUG, 'StudentUser.getStudentUser() TEST STUDENT CONTACT JSON: '+JSON.serialize( testStudentContact) );
        System.debug(LoggingLevel.DEBUG, 'StudentUser.getStudentUser() TEST STUDENT ACCOUNT JSON: '+JSON.serialize( testStudentAccount) );
        
        System.assert( testStudentUser.Id == studentUserRec.id , 'TEST USER ID does NOT match created studentUser.Id' );
        System.assert( testStudentContact.Id == studentContact.Id, 'TEST CONTACT ID does NOT match created studentContact.Id' );
        System.assert( testStudentAccount.Id == studentContact.AccountId, 'TEST ACCOUNT ID does NOT match created studentContact.AccountId' );
        System.assert( studentUser.getVerifyPersonalInfoURL() != null, 'ASSERTION FAILURE: getVerifyPersonalInfoURL() is null after creating StudentUser object instance with studentContact.Id of ('+studentContact.Id+')' );

            //grab code coverage
        getTestStudentUser(studentContact.Id); 
            getTestStudentContact();    

  }  
  
  
  static testmethod void testStudentUserByContactId() {
  
    Contact studentContact = getTestStudentContact();    

    Test.startTest();
	    User studentUserRec = getTestStudentUser(studentContact.Id);
        
        StudentUser studentUser = new StudentUser(studentContact.id);  
        
        Contact testStudentContact = studentUser.getStudentContact(); 
        User testStudentUser = studentUser.getStudentUser(); 
            
    Test.stopTest();
    
        Account testStudentAccount = studentUser.getStudentAccount(); 
        
        System.assert( testStudentUser.Id == studentUserRec.id , 'TEST USER ID does NOT match created studentUser.Id' );
        System.assert( testStudentContact.Id == studentContact.Id, 'TEST CONTACT ID does NOT match created studentContact.Id' );
        System.assert( testStudentAccount.Id == studentContact.AccountId, 'TEST ACCOUNT ID does NOT match created studentContact.AccountId' );
        System.assert( studentUser.getVerifyPersonalInfoURL() != null, 'ASSERTION FAILURE: getVerifyPersonalInfoURL() is null after creating StudentUser object instance with studentContact.Id of ('+studentContact.Id+')' );

  }  
  



  static testmethod void testStudentUserContactIdRunAsStudent() {
  
    Contact studentContact = getTestStudentContact();    
        
        Test.startTest();
		User studentUserRec = getTestStudentUser(studentContact.Id);
	    System.runAs( studentUserRec ) {
	    
	            StudentUser contactProfile = new StudentUser( studentContact.Id );  
	            System.assert( contactProfile.getStudentContact().Id == studentContact.Id, 'ASSERTION FAILURE: RunAs(Student), getStudentContact().Id does not equal studentContact.Id after creating StudentUser object instance with studentContact.Id of ('+studentContact.Id+')' );
	            System.assert( contactProfile.getStudentUser().Id == studentUserRec.Id, 'ASSERTION FAILURE: RunAs(Student), getStudentUser().Id does not equal studentContact.Id after creating StudentUser object instance with studentContact.Id of ('+studentContact.Id+')' );
	            System.assert( contactProfile.getStudentAccount().Id == studentContact.AccountId, 'ASSERTION FAILURE: RunAs(Student), getStudentAccount().Id does not equal studentContact.Id after creating StudentUser object instance with studentContact.Id of ('+studentContact.Id+')' ); 
	                
	    }
        Test.stopTest();
          
  }  


  static testmethod void testStudentUserInvalidId() {
  
    setupStudentTestData();
    
      Test.startTest();
          
          try {
            StudentUser accountProfile = new StudentUser( [select id from States__c LIMIT 1].id );
          } catch (StudentException e) {
            System.Assert( e.getMessage().startsWith('INVALID ID PARAM'), 'StudenException does not start with INVALID ID PARAM' );
          }  
            
          try {
            StudentUser accountProfile = new StudentUser( null );
          } catch (StudentException e) {
            System.Assert( e.getMessage().startsWith('NULL VALUE ERROR'), 'StudenException does not start with NULL VALUE ERROR' );
          }  
            
      Test.stopTest();
    
  }

  static testmethod void testStudentUserAccountId() {
        
      Contact studentContact = getTestStudentContact();    
      Account studentAccount = getTestStudentAccount();

      Test.startTest();
		    User studentUserRec = getTestStudentUser();
          
            StudentUser accountProfile = new StudentUser( studentAccount.Id );  
            System.assert( accountProfile.getStudentAccount().Id == studentAccount.Id, 'ASSERTION FAILURE: getStudentAccount().Id does not equal studentContact.Id after creating StudentUser object instance with studentAccount.Id of ('+studentAccount.Id+')' );
            System.assert( accountProfile.getStudentContact().Id == studentAccount.StudentContact__c, 'ASSERTION FAILURE: getStudentContact().Id does not equal studentContact.Id after creating StudentUser object instance with studentAccount.Id of ('+studentAccount.Id+')' );
            System.assert( accountProfile.getStudentUser().Id == studentUserRec.id, 'ASSERTION FAILURE: getStudentUser().Id does not equal studentContact.Id after creating StudentUser object instance with studentAccount.Id of ('+studentAccount.Id+')' );
            
      Test.stopTest();

      //grab code coverage using existing Account record
      studentAccount = getTestStudentAccount();
  }
  

  static testmethod void testSetupKeyValueTestRecords() {
        
      Test.startTest();

          setupKeyValueTestData();
          System.assert( [SELECT count() from KeyValue__c] > 0, 'CREATE TEST KeyValue__c records FAILURE in TestStudentUser.setupKeyValueTestData');  
            
      Test.stopTest();

  }
  
 }