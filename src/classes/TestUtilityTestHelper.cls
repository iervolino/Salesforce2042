@isTest
public with sharing class TestUtilityTestHelper {
	public static User getTestUser(String userName, String profileName) {
		Profile profile = [select Id from Profile where Name = :profileName limit 1];
		User user = new User(UserName=(userName + '@wgu.edu'), Alias=userName.substring(0,7), Email=(userName + '@wgu.edu'), EmailEncodingKey='UTF-8', LastName='User', FirstName = 'Test', 
			LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='America/Los_Angeles', ProfileId=profile.Id, PIDM__c=userName);
		return user;
	}
}