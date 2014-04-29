public with sharing class PersonalPortalControler {


	public String o; 
	public PersonalPortalControler() {
		

	
	}

	public void initAcftionFuction()
	{

			String   userContactId = getUserInfoFromUser();


	}



	public String getUserInfoFromUser()
	{


	String logedinuser = UserInfo.getUserId();

    List<User> u = [Select Contact.id,Email,contact.Email from User where Id = :logedinuser ];

 	System.debug(u);

    return u.get(0).contactid;

	}

	public String getO()
	{

		return getContactInfo('003a000001nIQhd');
	}

	public String getContactInfo( String contactStudent)
	{

	

      List<Contact> c = [Select id, email from contact where id = :contactStudent];

      System.debug(c);

	  List<Opportunity> studentInfo  = [SELECT Id, OwnerId, Owner.FirstName, Owner.LastName, 
	  CareStatus__c, PIDM__c , StudentID__c, PersonalPageIdentifier__c 
	  FROM Opportunity WHERE StudentContact__c = :contactStudent ];

	  Opportunity o = studentInfo.get(0);

return JSON.serialize(o);
		
	

}
}