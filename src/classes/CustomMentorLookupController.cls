public class CustomMentorLookupController {
 
  public List<Mentor__c> results{get;set;} // search results
  public string searchString{get;set;} // search keyword
 
  public CustomMentorLookupController() {
    // get the current search string
    searchString = System.currentPageReference().getParameters().get('lksrch');
    runSearch();  
  }
 
  // performs the keyword search
  public PageReference search() {
    runSearch();
    return null;
  }
 
  // prepare the query and issue the search command
  private void runSearch() {
    // TODO prepare query string for complex serarches & prevent injections
    results = performSearch(searchString);               
  } 
 
  // run the search and return the records found. 
  private List<Mentor__c> performSearch(string searchString) {
    List<Mentor__c> mentors;
    if(searchString != '' && searchString != null){
        searchString = '*' + searchString + '*';
        mentors = (List<Mentor__c>)[FIND :searchString RETURNING Mentor__c(user__r.name,id,name,programcodes__c,priority1programcodes__c,mentorrole__c,mentorceiling__c,user__c,soslpriorityprograms__c)][0];        
    }
    return mentors;
 
  }
 
  // used by the visualforce page to send the link to the right dom element
  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }
 
  // used by the visualforce page to send the link to the right dom element for the text box
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }
}