/*
*Author Stefan Schwaab
*Slalom
*@4/24/13 - John Chan: Add null check for return url
*@5/15/13 - John Chan: Refactored the whole page... Ran into a bug where the outputLink that was linked to a downloadable file would throw permissions error when a portal user 
*           attempted to post back to the controller in anyway even if it was back to the standard controller (eg: rating the article).  This would only happen for extensions
*           and if you did not manually select the file fields via SOQL
*/
public class CourseArticleController {
    public boolean isInternalUser { get; private set; }
    public final CourseArticle__kav courseArticle { get; private set; }
    
    private final String standardUserType = 'Standard';
    
    public CourseArticleController(ApexPages.StandardController stdController) {
        this.courseArticle = [SELECT FileUpload__Name__s FROM CourseArticle__kav WHERE Id = :((CourseArticle__kav)stdController.getRecord()).Id];
        isInternalUser = (UserInfo.getUserType() == standardUserType);
    }
    
    //TODO: Move this to javascript
    public PageReference ReturnToSearch() {
        String ReturnToPage = isInternalUser ? Page.WGUArticles.getUrl() : Page.SearchArticles.getUrl();
        if (String.isNotEmpty(ApexPages.currentPage().getParameters().get('rtn'))) {
            ReturnToPage = ApexPages.currentPage().getParameters().get('rtn') + '?searchTerm=' + ApexPages.currentPage().getParameters().get('searchTerm') ;
            if (String.isNotEmpty(ApexPages.currentPage().getParameters().get('courseCode'))) {
                ReturnToPage += '&courseCode=' + ApexPages.currentPage().getParameters().get('courseCode');
            }
            if (String.isNotEmpty(ApexPages.currentPage().getParameters().get('courseId'))) {
                ReturnToPage += '&courseId=' + ApexPages.currentPage().getParameters().get('courseId');
            }
            if (String.isNotEmpty(ApexPages.currentPage().getParameters().get('refineSearchTerm'))) {
                ReturnToPage += '&refineSearchTerm=' + ApexPages.currentPage().getParameters().get('refineSearchTerm');
            }
            if (String.isNotEmpty(ApexPages.currentPage().getParameters().get('groupId'))) {
                ReturnToPage += '&groupId=' + ApexPages.currentPage().getParameters().get('groupId');
            }
        }
        PageReference RedirectPage = new PageReference(ReturnToPage);
        RedirectPage.setRedirect(true);
        return RedirectPage;
    }
    
    //TODO: Move this to javascript
    public PageReference EditArticle() {
        PageReference RedirectPage = new PageReference(Page.CourseArticleEditor.getUrl() + '?Id=' + this.courseArticle.Id);
        RedirectPage.setRedirect(true);
        return RedirectPage;
    }
}