public class CommonsExpandedSearchController {

    public String groupId { get; private set; }
    public String searchTerm { get; private set; }
    public String refineSearchTerm { get; private set; }
    public String courseCode { get; private set; }
    public String courseTitle { get; private set; }
    public List<CourseArticleDAO.CourseArticleStudentView> articleViewList { get; private set; }
    
    public CourseSearchPaginator paginator { get; private set; }
    
    public CommonsExpandedSearchController() {
        groupId = Apexpages.currentPage().getParameters().get('groupId');
        searchTerm = Apexpages.currentPage().getParameters().get('searchTerm');
        refineSearchTerm = Apexpages.currentPage().getParameters().get('refineSearchTerm');
        courseCode = Apexpages.currentPage().getParameters().get('courseCode');
        populateCourseTitle();
        if(!String.isEmpty(courseCode) && !String.isEmpty(searchTerm)) {
            doSearch();
        }
    }
    
    private void populateCourseTitle() {
        if(String.isEmpty(courseCode)) {
            return;
        }
        List<WGUCourse__c> courseList = [SELECT Title__c FROM WGUCourse__c WHERE bannercode__c = :courseCode];
        if(courseList.isEmpty()) {
            return;
        }
        String title = courseList.get(0).Title__c;
        if(title.length() > 35) {
            title = title.subString(0, 35) + '...';
        }
        courseTitle = title;
    }
    
    private void doSearch() {
        SoslUtility.SoslSearchTermGroup searchTermGroup = new SoslUtility.SoslSearchTermGroup();
        searchTermGroup.addSearchTerm(new SoslUtility.SoslSearchTerm(searchTerm, true));
        if (String.isNotBlank(refineSearchTerm)) {
            searchTermGroup.addSearchTerm(new SoslUtility.SoslSearchTerm(refineSearchTerm, true, SoslUtility.SoslOperator.AndJoin));
        }
        
        String formattedSearchTerm = SoslUtility.generateSearchTerm(new List<SoslUtility.SoslSearchTermGroup> { searchTermGroup });
        List<CourseArticle__kav> courseArticles = CourseArticleDAO.searchEnglishUsArticles(CourseArticleDAO.SearchAppType.Student, KbArticleConstants.PublicationStatus.Online.Name(), 
                                                                                           courseCode, null, formattedSearchTerm, null, null);
        articleViewList = CourseArticleDAO.getCourseArticleStudentView(courseArticles);
        paginator = new CourseSearchPaginator(articleViewList, 10);
    }
    
    public void redoSearch() {
        searchTerm = Apexpages.currentPage().getParameters().get('redoSearchTerm');
        System.debug(searchTerm);
        refineSearchTerm = null;
        doSearch();
    }

    public void refineSearch() {
        refineSearchTerm = Apexpages.currentPage().getParameters().get('refineSearchTerm');
        doSearch();
    }
    
    public void postMessageToChatter() {
        if(groupId == null) {
            return;
        }
        
        String message = Apexpages.currentPage().getParameters().get('message');
        String question = Apexpages.currentPage().getParameters().get('question');
        String feedItemId = Apexpages.currentPage().getParameters().get('feedItemId');
        
        String communityId = CommonsChatterUtil.getWGUCommonsCommunityId();
        CommonsChatterUtil util = new CommonsChatterUtil();
        util.postMessageToChatter(message, question, feedItemId, groupId, communityId, null);
    }
    
}