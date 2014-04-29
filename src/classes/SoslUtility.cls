/*
*Author John Chan
*Slalom
* Helps in construction of search term and parsing out reserved characters/operators
*/
public with sharing class SoslUtility {
	private static List<String> soslReservedOperators = new List<String> { 'and', 'or', 'and not' };
	
	public static String generateSearchTerm(List<SoslSearchTermGroup> searchTermGroups) {
		String generatedSearchTerm = '';
		if (searchTermGroups != null && searchTermGroups.size() > 0) {
			searchTermGroups.sort();
			for (integer i = 0; i < searchTermGroups.size(); i++) {
				if (string.isEmpty(generatedSearchTerm) && searchTermGroups.size() > 1) {
					generatedSearchTerm = '(';
				} else if (i > 0) {
					generatedSearchTerm += getSoslOperator(searchTermGroups.get(i).operatorGroup) + '(';
				}
				for (SoslSearchTerm searchTerm : searchTermGroups.get(i).getSearchTerm()) {
					if (String.isNotEmpty(searchTerm.term)) {
						if (searchTerm.operator != null) {
							generatedSearchTerm += getSoslOperator(searchTerm.operator) + generateSearchTerm(searchTerm);
						} else {
							generatedSearchTerm += generateSearchTerm(searchTerm);
						}
					}
				}
				
				if (searchTermGroups.size() > 1) {
					generatedSearchTerm += ')';
				}
			}
		}
		
		return generatedSearchTerm;
	}
	
	public static String generateSearchTerm(SoslSearchTerm searchTerm) {
		String generatedSearchTerm = '';
		if (String.isNotEmpty(searchTerm.term)) {
			//escaping special characters and phrases
			generatedSearchTerm = searchTerm.term.replaceAll('\\p{Punct}+', '');
			String searchTermLowerCase = generatedSearchTerm.ToLowerCase();
			for (String reservedOperator : soslReservedOperators) {
				if (searchTermLowerCase.contains(reservedOperator)) { //if the search term contains reserverd operators we match it by exact phrase by default
					searchTerm.exactPhrase = true;
				}
			}
			
			if (searchTerm.exactPhrase) {
				generatedSearchTerm = '"' + generatedSearchTerm + '"';
			}
			
		}
		
		return generatedSearchTerm;
	}
	
	public class SoslSearchTermGroup implements Comparable {
		public SoslSearchTermGroup() {
			this.termGroup = 2147483647;
		}
		public SoslSearchTermGroup(integer termGroup, SoslOperator operatorGroup) {
			this.termGroup = termGroup;
			this.operatorGroup = operatorGroup;
		}
		
		public integer termGroup { get; private set; }
		public SoslOperator operatorGroup { get; private set; }
		private List<SoslSearchTerm> searchTerms = new List<SoslSearchTerm>();
		private integer searchOrder = 0;
		
		public void addSearchTerm(SoslSearchTerm searchTerm) {
			searchTerm.searchOrder = searchOrder;
			searchTerms.add(searchTerm);
			searchOrder++;
		}
		
		public List<SoslSearchTerm> getSearchTerm() {
			searchTerms.sort();
			return searchTerms;
		}
		
		public Integer compareTo(Object compareTo) {
	        SoslSearchTermGroup compareToTerm = (SoslSearchTermGroup)compareTo;
	        if (compareToTerm == null) {
	        	throw new SoslUtilityException('Unable to compare and sort SoslSearchTermGroup compareTo returned null.');
	        }
	        if (termGroup == compareToTerm.termGroup) return 0;
	        if (termGroup > compareToTerm.termGroup) return 1;
	        return -1;        
	    }
	}
	
	public class SoslSearchTerm implements Comparable {
		public SoslSearchTerm(String term, boolean exactPhrase) {
			this.term = term;
			this.exactPhrase = exactPhrase;
		}
		public SoslSearchTerm(String term, boolean exactPhrase, SoslOperator operator) {
			this.term = term;
			this.exactPhrase = exactPhrase;
			this.operator = operator;
		}
		
		public String term { get; private set; }
		public SoslOperator operator { get; private set; }
		public boolean exactPhrase { get; private set; }
		public integer searchOrder { get; set; }
		
		public Integer compareTo(Object compareTo) {
	        SoslSearchTerm compareToSearch = (SoslSearchTerm)compareTo;
	        if (compareToSearch == null) {
	        	throw new SoslUtilityException('Unable to compare and sort SoslSearchTermGroup compareTo returned null.');
	        }
	        if (searchOrder == compareToSearch.searchOrder) return 0;
	        if (searchOrder > compareToSearch.searchOrder) return 1;
	        return -1;        
	    }
	}
	
	public enum SoslOperator {
		AndJoin,
		OrJoin,
		AndNotJoin
	}
	
	private static String getSoslOperator(SoslOperator operator) {
		if (operator == SoslOperator.AndJoin) {
			return ' AND ';
		} else if (operator == SoslOperator.OrJoin) {
			return ' OR ';
		} else if (operator == SoslOperator.AndNotJoin) {
			return ' AND NOT ';
		}
		
		return null;
	}
	
	public class SoslUtilityException extends Exception { }
}