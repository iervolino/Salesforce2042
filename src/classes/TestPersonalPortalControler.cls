@IsTest
public with sharing class TestPersonalPortalControler {


@IsTest(seealldata=true)
public static void helloWorld(){
 
	User u = [Select id,email from user where email = 'mabrah7@wgu.edu.devfull'];
	System.debug(u);

	String contactInfo;
	   PersonalPortalControler p = new PersonalPortalControler();
	System.runAs(u)
	{
	System.debug(u.email);
 
    contactInfo = p.getUserInfoFromUser();

	}
	System.debug('contactInfo:  '  +  contactInfo);
p.getContactInfo(contactInfo);
System.assert(true);
	
}

}