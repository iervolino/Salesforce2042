public class SelectOptionGroupTypeComparable implements Comparable {
        
    public SelectOption option { get; set; }
    public CommunityAccessControl__c cac { get; set; }
    
    public SelectOptionGroupTypeComparable(SelectOption option, CommunityAccessControl__c cac) {
        this.option = option;
        this.cac = cac;
    }
    
    //This will sort the list so that the college is first, degree program second, and courses after in alphabetical order
    public Integer compareTo(Object otherObject) {
        SelectOptionGroupTypeComparable other = (SelectOptionGroupTypeComparable)otherObject;
        if(cac == null && other.cac != null) {
            return 1;
        }
        
        if(cac != null && other.cac == null) {
            return -1;
        }
        
        if(cac == null && other.cac == null) {
            return 0;
        }
        
        if(cac.GroupLevel__c == 'College' && other.cac.GroupLevel__c != 'College') {
            return -1;
        }
        
        if(cac.GroupLevel__c == 'Program' && other.cac.GroupLevel__c == 'College') {
            return 1;
        }
        
        if(cac.GroupLevel__c == 'Program' && other.cac.GroupLevel__c == 'Course') {
            return -1;
        }
        
        if(cac.GroupLevel__c == 'Course' && other.cac.GroupLevel__c != 'Course') {
            return 1;
        }
        
        return option.getLabel().compareTo(other.option.getLabel()) * -1;
    }
    
}