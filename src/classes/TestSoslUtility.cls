/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestSoslUtility {
	public static testMethod void testSoslSearchTerm() {
		string searchText = 'and test';
		SoslUtility.SoslSearchTerm searchTerm = new SoslUtility.SoslSearchTerm(searchText, false);
		system.assert(!searchTerm.exactPhrase);
		string formattedSearchTerm = SoslUtility.generateSearchTerm(searchTerm);
		system.assertEquals('"' + searchText.replaceAll('\\p{Punct}+', '').ToLowerCase() + '"', formattedSearchTerm);
		system.assert(searchTerm.exactPhrase);
	}
	
	public static testMethod void testSoslSearchGroups() {
		string searchText1 = 'test1';
		string searchText2 = 'test2';
		List<SoslUtility.SoslSearchTermGroup> searchTermGroups = new List<SoslUtility.SoslSearchTermGroup>();
		SoslUtility.SoslSearchTermGroup searchTermGroup1 = new SoslUtility.SoslSearchTermGroup(1, null);
		searchTermGroup1.addSearchTerm(new SoslUtility.SoslSearchTerm(searchText1, false));
		searchTermGroup1.addSearchTerm(new SoslUtility.SoslSearchTerm(searchText2, false, SoslUtility.SoslOperator.AndJoin));
		searchTermGroups.add(searchTermGroup1);
		
		SoslUtility.SoslSearchTermGroup searchTermGroup2 = new SoslUtility.SoslSearchTermGroup(2, SoslUtility.SoslOperator.AndNotJoin);
		searchTermGroup2.addSearchTerm(new SoslUtility.SoslSearchTerm(searchText1, false));
		searchTermGroup2.addSearchTerm(new SoslUtility.SoslSearchTerm(searchText2, false, SoslUtility.SoslOperator.OrJoin));
		searchTermGroups.add(searchTermGroup2);
		
		string formattedSearchTerm = SoslUtility.generateSearchTerm(searchTermGroups);
		system.assertEquals(('(' + searchText1 + ' AND ' + searchText2 + ')' + ' AND NOT ' + '(' + searchText1 + ' OR ' + searchText2 + ')'), 
				formattedSearchTerm);
	}
}