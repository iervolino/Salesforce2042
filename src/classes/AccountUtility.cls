/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Created Date Aug 4, 2013 @ 1352 hrs
 *
 * Trigger Utility for Account Trigger processing 
 *
 * 9-20-2013 Yemeng : 2 method for account trigger and contact trigger, 2 method to find 'wired' accounts/contacts, and 2 method for web call.
 *
 */ 
global with sharing class AccountUtility { 

	public static boolean isInsertContact = false;
	public static boolean isInsertAccount = false;
	//call by AFTER INSERT Accounttrigger:  create 1 contact for each student type accounts (if they don't have contact yet).
	public static boolean createContactsForAccounts(List<Account> accounts)
	{   isInsertAccount = true;
		Id studentAccountRecordTypeId;
		Id prospectAccountRecordTypeId;
		Id alumniAccountRecordTypeId;
		Id studentContactRecordTypeId;
		Id prospectContactRecordTypeId;
		Id alumniContactRecordTypeId;
		Map<String,Id> recordTypesMap = new Map<String,Id>();
		Map<Id,RecordType> studentContactRecordTypes = new Map<Id,RecordType>();
		//get Student record types
		for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) 
		{
			recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
			if ( rt.SobjectType == 'Contact' ) {
				studentContactRecordTypes.put( rt.id, rt );
			}
			if ( rt.DeveloperName == 'StudentRecord' ) {
				if (rt.sObjectType == 'Contact') {
					studentContactRecordTypeId = rt.id;
				} else {
					studentAccountRecordTypeId = rt.id;       
				}
			} else if ( rt.DeveloperName == 'ProspectRecord' ) {
				if (rt.sObjectType == 'Contact') {
					prospectContactRecordTypeId = rt.id;
				} else {
					prospectAccountRecordTypeId = rt.id;        
				}
			} else {
				if (rt.sObjectType == 'Contact') {
					alumniContactRecordTypeId = rt.id;
				} else {
					alumniAccountRecordTypeId = rt.id;        
				}

			}
		}

		//find out the account who dont have contact
		List<id> ids= new List<id>(); 
		for(Account student:accounts)
		{	//if this account don't have StudentContact__c or relate list Contacts is null
			if(student.StudentContact__c==null||student.Contacts==null)
			{
				ids.add(student.id);
			}
		}
		//Re-query accounts  
		List<account> updateAccounts=[select id, StudentContact__c,RecordTypeId, Name, pidm__c from Account where id in :ids and studentContact__c = null and RecordTypeid in (:studentAccountRecordTypeId,:prospectAccountRecordTypeId,:alumniAccountRecordTypeId)];
		if(updateAccounts.size()==0)
		{
			return false;
		}

		Id sadminId = [select id from user where username like 'sadmin@%wgu.edu%' LIMIT 1].id;//get system admin
		Map<String,Contact> contactsForInsert = new Map<String,Contact>(); //(pidm, account) map 
		Map<Account,Contact> acmap=new Map<Account,Contact> (); //(account, contact)map
		for ( Account student: updateAccounts ) 
		{
			if ( (student.RecordTypeId == prospectAccountRecordTypeId || student.RecordTypeId == studentAccountRecordTypeId || student.RecordTypeId == alumniAccountRecordTypeId) && student.studentContact__c== null )
			{

				student.OwnerId = sadminId;  //place all new student contact and account records under sadmin ownership 

				//create new Contact for this account record
				Contact newContact = new Contact(PIDM__c=student.PIDM__c);
				newContact.RecordTypeId = (student.RecordTypeId==prospectAccountRecordTypeId)? prospectContactRecordTypeId: ((student.RecordTypeId==studentAccountRecordTypeId)?studentContactRecordTypeId:alumniContactRecordTypeId);
				//split to array
				String [] names =  student.Name.split(' ');
				if(names.size()==2)
				{
					newContact.FirstName = names[0];
					newContact.LastName = names[1];
				}else
				{

					newContact.LastName = student.Name;
				}
				newContact.OwnerId = sadminId;  
				newContact.AccountId = student.id;
				newContact.PIDM__c =  student.PIDM__c;
				newContact.IsPersonAccount__c=true;
				contactsForInsert.put( student.id, newContact );
				acmap.put(student,newContact);
			}
		}
		//insert new contacts into SF
		if ( !contactsForInsert.isEmpty() ) {
			insert contactsForInsert.values();
		} 
		//update account with contact.id
		for( Account student:updateAccounts)
		{
			student.StudentContact__c = acmap.get(student).id;
			student.OwnerId = sadminid;
		}

		update updateAccounts;
		isInsertAccount = false;
		return true;

	}
	//9-20-2013 Yemeng : call by AFTER INSERT contact trigger, the pass in contacts are 'wired' contacts which need a account for each of them.
	public static boolean  createAccountsForContacts(List<Contact> contacts)
	{	//get recordtypes
		isInsertContact = true;
		Id studentAccountRecordTypeId;
		Id prospectAccountRecordTypeId;
		Id alumniAccountRecordTypeId;
		Id studentContactRecordTypeId;
		Id prospectContactRecordTypeId;
		Id alumniContactRecordTypeId;
		Map<String,Id> recordTypesMap = new Map<String,Id>();
		Map<Id,RecordType> studentContactRecordTypes = new Map<Id,RecordType>();
		//get Student record types
		for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) 
		{
			recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
			if ( rt.SobjectType == 'Contact' ) {
				studentContactRecordTypes.put( rt.id, rt );
			}
			if ( rt.DeveloperName == 'StudentRecord' ) {
				if (rt.sObjectType == 'Contact') {
					studentContactRecordTypeId = rt.id;
				} else {
					studentAccountRecordTypeId = rt.id;       
				}
			} else if ( rt.DeveloperName == 'ProspectRecord' ) {
				if (rt.sObjectType == 'Contact') {
					prospectContactRecordTypeId = rt.id;
				} else {
					prospectAccountRecordTypeId = rt.id;        
				}
			} else {
				if (rt.sObjectType == 'Contact') {
					alumniContactRecordTypeId = rt.id;
				} else {
					alumniAccountRecordTypeId = rt.id;        
				}

			}
		}

		Id sadminId = [select id from user where username like 'sadmin@%wgu.edu%' LIMIT 1].id;

		Map<Contact,Account> caMap = new Map<Contact,Account>(); //(contact, account) map

		for(Contact con:contacts)
		{
			//for 3 types of contact, create an account for each
			if ( (con.RecordTypeId == prospectContactRecordTypeId || con.RecordTypeId == studentContactRecordTypeId || con.RecordTypeId == alumniContactRecordTypeId) && con.AccountId == null ) {

				Account acc=new Account();
				acc.StudentContact__c=con.id;//account->contact
				acc.RecordTypeId = (con.RecordTypeId==prospectContactRecordTypeId)? prospectAccountRecordTypeId: ((con.RecordTypeId==studentContactRecordTypeId)?studentAccountRecordTypeId:alumniAccountRecordTypeId);
				acc.Name = con.FirstName!=null? con.FirstName+' '+con.LastName: con.LastName;
				acc.OwnerId = sadminId; 
				acc.WGUCreatedDate__c = date.today();
				acc.pidm__c= con.pidm__c;
				caMap.put(con,acc);
			}

		}
		//insert the account back to SF
		if(caMap.size()>0)
		{
			insert caMap.values();
		}
		//associate the inserted account with existing contact
		for(Contact con:contacts)
		{
			con.AccountId = caMap.get(con).id; //contact->account
			con.WGUCreatedDate__c = con.WGUCreatedDate__c==null? date.today(): con.WGUCreatedDate__c;           
			con.ownerid = sadminid;
			con.IsPersonAccount__c=true;
		}

		update contacts;
		isInsertContact = false;
		return true;

	}

	/**
		Find a list Invalid studnet account( might be limited to 100 or 200)by Following criteria
		1. RecordType is student, prospect or alumni (dont know bussiness or company type)
		2. have more than 1 contacts in relatedlist 'Contacts',
		   or studentcontact__c=null ,
		   or have 1 studentcontact but this contact associate with other account.
		Basicly covers all cases of invalid account.

	 */
	webservice static List<Account> huntInvalidAccounts()
	{

		Id studentAccountRecordTypeId;
		Id prospectAccountRecordTypeId;
		Id alumniAccountRecordTypeId;
		Id studentContactRecordTypeId;
		Id prospectContactRecordTypeId;
		Id alumniContactRecordTypeId;
		Map<String,Id> recordTypesMap = new Map<String,Id>();
		Map<Id,RecordType> studentContactRecordTypes = new Map<Id,RecordType>();
		//get Student record types
		for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) 
		{
			recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
			if ( rt.SobjectType == 'Contact' ) {
				studentContactRecordTypes.put( rt.id, rt );
			}
			if ( rt.DeveloperName == 'StudentRecord' ) {
				if (rt.sObjectType == 'Contact') {
					studentContactRecordTypeId = rt.id;
				} else {
					studentAccountRecordTypeId = rt.id;       
				}
			} else if ( rt.DeveloperName == 'ProspectRecord' ) {
				if (rt.sObjectType == 'Contact') {
					prospectContactRecordTypeId = rt.id;
				} else {
					prospectAccountRecordTypeId = rt.id;        
				}
			} else {
				if (rt.sObjectType == 'Contact') {
					alumniContactRecordTypeId = rt.id;
				} else {
					alumniAccountRecordTypeId = rt.id;        
				}

			}
		}
		List<Account> result=new List<Account>();
		List<id> ids= new List<id>();
		//1 account vs n contacts
		AggregateResult[] groupedResults =[select count(id) cont , accountid from contact where recordTypeid in (:alumniContactRecordTypeId , :prospectContactRecordTypeId,:studentContactRecordTypeId) group by accountid order by count(id) desc limit 500];
		for(AggregateResult r:groupedResults)
		{
			if( (integer)r.get('cont')>1)
			{
				ids.add((id)r.get('accountid'));
			}
		}
		// 0 contacts , isInvalid : (StudentContact__c != null && StudentContact__r.AccountId != Id )
		for(Account acc:[select id from account where RecordTypeid in (:alumniAccountRecordTypeId, :prospectAccountRecordTypeId,:studentAccountRecordTypeId) and (studentContact__c=null or isInvalid__c=true)])
		{
			ids.add(acc.id);
		}

		return [select id, Name, pidm__c, studentContact__c,studentContact__r.FirstName, studentContact__r.LastName, Owner.Username, RecordTypeId, RecordType.DeveloperName, PersonEmail,PersonMobilePhone, Phone,  CreatedDate, isInvalid__c, (select id, FirstName, LastName, pidm__c from Contacts ) from account where id in :ids limit 200];
	}

	/**
	Find a List of Invalid Contacts:( might be limited to 100 or 200)
	Only dealing with student, perspect and alumni recordtypes.
	1. Have multiple accounts' studentcontact__c field link to this contact
	2. Don not have account, accountid==null
	3. Have a account but its StudentContact__c relate to other contact

	 */
	webservice static List<Contact> huntInvalidContacts()
	{
		Id studentAccountRecordTypeId;
		Id prospectAccountRecordTypeId;
		Id alumniAccountRecordTypeId;
		Id studentContactRecordTypeId;
		Id prospectContactRecordTypeId;
		Id alumniContactRecordTypeId;
		Map<String,Id> recordTypesMap = new Map<String,Id>();
		Map<Id,RecordType> studentContactRecordTypes = new Map<Id,RecordType>();
		//get Student record types
		for ( RecordType rt: [select id,DeveloperName,sObjectType from RecordType where DeveloperName IN ('StudentRecord','ProspectRecord','AlumniRecord') and sObjectType IN ('Contact','Account')]) 
		{
			recordTypesMap.put( rt.SobjectType+'_'+rt.DeveloperName, rt.id );
			if ( rt.SobjectType == 'Contact' ) {
				studentContactRecordTypes.put( rt.id, rt );
			}
			if ( rt.DeveloperName == 'StudentRecord' ) {
				if (rt.sObjectType == 'Contact') {
					studentContactRecordTypeId = rt.id;
				} else {
					studentAccountRecordTypeId = rt.id;       
				}
			} else if ( rt.DeveloperName == 'ProspectRecord' ) {
				if (rt.sObjectType == 'Contact') {
					prospectContactRecordTypeId = rt.id;
				} else {
					prospectAccountRecordTypeId = rt.id;        
				}
			} else {
				if (rt.sObjectType == 'Contact') {
					alumniContactRecordTypeId = rt.id;
				} else {
					alumniAccountRecordTypeId = rt.id;        
				}

			}
		}


		List<Contact> result=new List<Contact>();
		List<id> ids= new List<id>();
		//multiple account to 1 contact
		AggregateResult[] groupedResults =[select count(id) cont , studentcontact__c from account where RecordTypeId in (:alumniAccountRecordTypeId, :prospectAccountRecordTypeId,:studentAccountRecordTypeId) group by studentcontact__c order by count(id) desc limit 200];
		System.debug('#######duplicate account ->1 contact'+groupedResults);
		for(AggregateResult r:groupedResults)
		{
			if( (integer)r.get('cont')>1)
			{
				ids.add((id)r.get('studentcontact__c'));
			}
		}
		// 0 account
		List<Contact> invalids=[select id from Contact where recordTypeid in (:alumniContactRecordTypeId , :prospectContactRecordTypeId,:studentContactRecordTypeId) and (accountid=null or isInvalid__c=true)];

		System.debug('#######null accountid or invalid account setting'+invalids);
		for(Contact c: invalids)
		{
			ids.add(c.id);
		}
		SYstem.debug('####final ids'+ids);
		return [select id, FirstName,LastName, pidm__c, CreatedDate,Email, Fax, MobilePhone,MailingCity,MailingStreet,MailingState,MailingPostalCode, OtherPhone, HomePhone,Department, Mentor__r.username, accountid, account.StudentContact__c,isInvalid__c  ,RecordTypeId, RecordType.DeveloperName  from contact where id in :ids limit 200]; 
	}


	webservice static boolean createContactsForAccountsWebCall(List<id> Ids)
	{
		return createContactsForAccounts([select id, Name, pidm__c, studentContact__c,studentContact__r.FirstName, studentContact__r.LastName, Owner.Username, RecordTypeId, RecordType.DeveloperName, PersonEmail,PersonMobilePhone, Phone,  CreatedDate, isInvalid__c, (select id, FirstName, LastName, pidm__c from Contacts ) from account where id in :Ids limit 200]);
	}
	webservice static boolean createAccountsForContactsWebCall(List<id> Ids)
	{
		return createAccountsForContacts([select id, FirstName,LastName, pidm__c, CreatedDate,Email, Fax, MobilePhone,MailingCity,MailingStreet,MailingState,MailingPostalCode, OtherPhone, HomePhone,Department, Mentor__r.username, accountid, account.StudentContact__c,isInvalid__c,RecordTypeId, RecordType.DeveloperName  from contact where id in :Ids limit 200]);
	}
	
	
	//////////////////////////// START SECTION: FORWARD Student ACCOUNTS TO S2S Connection: Student API Org /////////////////////////////////////// 

	//Account: AFTER UPDATE
	//could not delete this method due to future dependencies in Banner Utility Tests
	public static void forwardAccountRecords( String listNewJSON ) {
		if ( Limits.getFutureCalls() > 8 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
			return; //do not process records if can't be done in a future method
		} else {
			asyncForwardAccountRecords(listNewJSON);
		}
	}

	@future
	private static void asyncForwardAccountRecords( String listNewJSON ) {
		//could not delete this method due to future dependencies in Banner Utility Tests
		//processForwardAccountRecords(listNewJSON);
	}

	//Account: AFTER UPDATE
	/*
	private static void processForwardAccountRecords( String listNewJSON ) {

		List<Account> triggernew = (List<Account>)JSON.deserialize(listNewJSON, List<Account>.class);

		//modified by PBC Oct 8 2013 @0911 hrs to better handle MIXED DML Exceptions in Test contexts
		String studentapiConxId = Runtime__c.getValues('StudentAPIConnectionId')!=null? Runtime__c.getValues('StudentAPIConnectionId').Value__c : '';
		if ( Test.isRunningTest() && (studentapiConxId==null || studentapiConxId=='' ) ) {
			List<PartnerNetworkConnection> partners = [Select id from PartnerNetworkConnection WHERE ConnectionName like 'WGU STUDENT API%' AND ConnectionStatus = 'Accepted'];
			studentapiConxId = partners[0].Id;
			try { 
				insert new Runtime__c(Name='StudentAPIConnectionId',Value__c=studentapiConxId); 
			} catch (Exception e) { 
				System.debug(LoggingLevel.DEBUG, e.getMessage() ); //inserts may fail in tests if the context creates a mixed DML exception
			} 
		}
		
		Set<Id> sharedIds = new Set<Id>();
		//Gather exisiting shares for triggered Account records if any
		for ( PartnerNetworkRecordConnection share: [Select LocalRecordId From PartnerNetworkRecordConnection WHERE LocalRecordId IN :triggernew AND Status = 'Sent' AND ConnectionId = :studentapiConxId ]) {
			sharedIds.add( share.LocalRecordId );   	  	
		}

		//create new Share records if necesssary. ONLY Forward Accounts that already have a User record, i.e., isCustomerPortal = true
		List<Account> newShares = new List<Account>();
		for ( Account a: [SELECT id,Name,RecordType.DeveloperName,PIDM__c FROM Account WHERE isCustomerPortal = true AND Id IN :triggernew AND Id NOT IN :sharedIds AND PIDM__c != null AND RecordType.DeveloperName = 'StudentRecord'] ) {
			newShares.add( a );
		}

		System.debug( LoggingLevel.FINEST, 'New Account Shares: ' + JSON.serialize( newShares ) );
		if ( !newShares.isEmpty() ) {
			//S2SStudentApiBatchUtility.doS2SBatch(newShares);
		}        	
	}	
	*/

	////////////////////////// END SECTION: FORWARD ACCOUNTS TO S2S Connection: Student API Org ///////////////////////////////////////// 
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 


}