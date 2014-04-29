/*
*Author Stefan Schwaab
*Slalom
*@4/2/13 - John Chan: Update to use new junction object
*@5/1/13 - John Chan: Refactor to use shared search code
*@5/7/13 - John Chan: Using new search term refinment
*@5/22/13 - John Chan: Update to use new view object to display image and view count for results
*@6/25/13 - John Chan: Hacked to just create case and support 4 other courses.  Need to stop hacking into this and just refactor the whole thing...
*@7/26/13 - John Chan: Refactored to move Contact My Mentor to its own component and cleaned up and attempted to remove most of the hardcoded sections.
*/
public class SearchArticlesController {
	
	public String courseCode { get; private set; }
	public String courseId { get; private set; }
	public String searchTerm { get;set; }
	public String refineSearchTerm { get; set; }
	public String majorVersionToDisplay { get; private set; }
	public boolean showContactMyMentorButton { get; private set; }
	public CourseKbContactMentorAttributes componentAttributes { get; set; }
    public String CombinedSearchTerm { get; set; }
    public String soslSearchString { get; set; }
    public String Categories { get; set; }
    public List<CourseArticleDAO.CourseArticleStudentView> articleViewList { get; private set; }
    public String mentorEmail { get; private set; }
    public String mentorName { get; private set; }
    
    private Contact itMentorsContact;

    public SearchArticlesController()
    {
		componentAttributes = new CourseKbContactMentorAttributes();

        // Get Search parameters
        searchTerm = ApexPages.currentPage().getParameters().get('searchTerm');
        courseCode = ApexPages.currentPage().getParameters().get('courseCode');
        courseId = ApexPages.currentPage().getParameters().get('courseId');
        refineSearchTerm = ApexPages.currentPage().getParameters().get('refineSearchTerm');
        majorVersionToDisplay = 'All';
        
        if (!String.isBlank(CourseId)) {
            WGUCourseVersion__c[] courseVersions = [SELECT Id, WGUCourse__r.Name, MajorVersion__c FROM WGUCourseVersion__c WHERE CourseOfStudyId__c = :decimal.valueOf(string.escapeSingleQuotes(courseId)) LIMIT 1];
            if (courseVersions.size() > 0) {
                courseCode = courseVersions[0].WGUCourse__r.Name;
                majorVersionToDisplay = String.valueOf(courseVersions[0].MajorVersion__c);
            }
        }

		//TODO: Temporary object used to display contact my mentors button until case creation is finalized
        showContactMyMentorButton = false;
        if (String.isNotEmpty(courseCode)) {
			List<CourseArticleMentorContact__c> mentorContacts = [SELECT MentorEmail__c, MentorName__c FROM CourseArticleMentorContact__c WHERE CourseCode__c = :string.escapeSingleQuotes(courseCode) LIMIT 1];
	       	if (mentorContacts.size() > 0) {
				showContactMyMentorButton = true;
				mentorEmail = mentorContacts[0].MentorEmail__c;
				mentorName =  mentorContacts[0].MentorName__c;
	       	}
        }
        
        doSearch();
    }
    
    public void showPopup() {
        componentAttributes.isVisible = true; 
    }
    
    public void doSearch() {
        if (validateSearch()) {
        	SoslUtility.SoslSearchTermGroup searchTermGroup = new SoslUtility.SoslSearchTermGroup();
        	searchTermGroup.addSearchTerm(new SoslUtility.SoslSearchTerm(searchTerm, true));
            if (String.isNotBlank(refineSearchTerm)) {
                searchTermGroup.addSearchTerm(new SoslUtility.SoslSearchTerm(refineSearchTerm, true, SoslUtility.SoslOperator.AndJoin));
            }
            
            String formattedSearchTerm = SoslUtility.generateSearchTerm(new List<SoslUtility.SoslSearchTermGroup> { searchTermGroup });
            List<CourseArticle__kav> courseArticles = CourseArticleDAO.searchEnglishUsArticles(CourseArticleDAO.SearchAppType.Student, KbArticleConstants.PublicationStatus.Online.Name(), 
            		courseCode, CourseId, formattedSearchTerm, null, null);
            articleViewList = CourseArticleDAO.getCourseArticleStudentView(courseArticles);
        }
    }
    
    private boolean validateSearch() {
    	boolean isValid = true;
    	if (String.isBlank(searchTerm)) {
    		ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Search Term may not be blank.'));
    		isValid = false;
    	} else if (searchTerm.length() == 1) {
    		ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Search Term must be longer than one character.'));
    		isValid = false;
    	}
    	return isValid;
    }

    public void refineSearch() {
        doSearch();
    }
    
    public String getBaseURL() {
       	return URL.getSalesforceBaseUrl().toExternalForm() + '/';
    }
}