/*
*Author John Chan
*Slalom
*@4/2/13 - John Chan: Update to use new editor, and reporting objects
*@4/11/13 - John Chan: Delete for draft articles, search for all published articles 
*@4/16/13 - John Chan: Overall refactor of code and to use remoting and reduce VF component usage to speed up page response
*@4/24/13 - John Chan: Add remoting for course list to support filtering of course articles by course
*@5/7/13 - John Chan: Using new search term refinment, update to global to work within iframes/console for remote actions
*@5/24/13 - John Chan: Refactor Archive and Publish, and add scheduled publish/archive.
*/
global class WGUArticlesController {
    // Page variables
    public String PublishStatus { get; set; }
    public String FilterString { get; set; }
    public String knowledgeArticleVersionIds { get; set; }
    public Date scheduledDate { get; set; }
    
    public WGUArticlesController() {
        // Get page parameters
        FilterString = ApexPages.currentPage().getParameters().get('searchTerm');
        PublishStatus = ApexPages.currentPage().getParameters().get('publishStatus');
        // Set default for parameters
        if ((PublishStatus == null) || (PublishStatus == '')) {
            PublishStatus = KbArticleConstants.PublicationStatus.Draft.name();
        }
    }

    private List<CourseArticle__kav> GetSelectedArticles()
    {
        List<CourseArticle__kav> courseArticles = null;
        if (knowledgeArticleVersionIds != null) {
            Set<String> knowledgeArticleVersionIdsSet = new Set<String>(knowledgeArticleVersionIds.split(','));
            if (knowledgeArticleVersionIdsSet != null && knowledgeArticleVersionIdsSet.size() > 0) {
                courseArticles = [SELECT Id, KnowledgeArticleId, PublishStatus, ArticleType__c, Summary, RichTextArea__c FROM CourseArticle__kav WHERE Id IN :knowledgeArticleVersionIdsSet];
            }
        }
        return courseArticles;
    }

    public PageReference submitScheduleRequest() {
        if (scheduledDate != null && scheduledDate <= Date.Today()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Can only schedule article actions to a future date.'));
        } else {
            boolean noExceptions = true;
            List<CourseArticle__kav> courseArticles = GetSelectedArticles();
            integer invalidArticleCount = 0;
            if (courseArticles != null && courseArticles.size() > 0 && (PublishStatus == KbArticleConstants.PublicationStatus.Draft.name() || PublishStatus == KbArticleConstants.PublicationStatus.Online.name())) {
                Savepoint sp = Database.setSavepoint();
                try {
                    List<KnowledgeBaseReporting__c> kbReports = new List<KnowledgeBaseReporting__c>();
                    for (CourseArticle__kav courseArticle : courseArticles) {
                        if ((PublishStatus == KbArticleConstants.PublicationStatus.Draft.name() && CourseArticleUtility.validatePublishArticle(courseArticle)) ||
                                PublishStatus == KbArticleConstants.PublicationStatus.Online.name()) {
                            if (scheduledDate == null) {
                                if (PublishStatus == KbArticleConstants.PublicationStatus.Draft.name()) {
                                    KbManagement.PublishingService.publishArticle(courseArticle.KnowledgeArticleId, false);
                                } else {
                                    KbManagement.PublishingService.archiveOnlineArticle(courseArticle.KnowledgeArticleId, null);
                                }                  
                            } else {
                                if (PublishStatus == KbArticleConstants.PublicationStatus.Draft.name()) {
                                    KbManagement.PublishingService.scheduleForPublication(courseArticle.KnowledgeArticleId, 
                                        DateTime.newInstance(scheduledDate.Year(), scheduledDate.Month(), scheduledDate.Day(), 0, 0, 0));
                                    kbReports.add(new KnowledgeBaseReporting__c(KnowledgeArticleVersionId__c = courseArticle.Id, KnowledgeArticleId__c =  courseArticle.KnowledgeArticleId,
                                        ScheduledPublishDate__c = scheduledDate));
                                } else {
                                    KbManagement.PublishingService.archiveOnlineArticle(courseArticle.KnowledgeArticleId, 
                                        DateTime.newInstance(scheduledDate.Year(), scheduledDate.Month(), scheduledDate.Day(), 0, 0, 0));
                                    kbReports.add(new KnowledgeBaseReporting__c(KnowledgeArticleVersionId__c = courseArticle.Id, KnowledgeArticleId__c =  courseArticle.KnowledgeArticleId, 
                                        ScheduledArchiveDate__c = scheduledDate));
                                }
                            }
                        } else {
                            invalidArticleCount++;
                        }
                    }
                    
                    if (scheduledDate != null && (courseArticles.size() - invalidArticleCount) > 0) {
                        upsert kbReports KnowledgeArticleVersionId__c;
                    }
                } catch (Exception ex) {
                    noExceptions = false;
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An Error occurred attempting to publish the selected articles.\n\nError Message: ' + ex.getMessage()));
                }
            }
            if (noExceptions) {
                String action = PublishStatus == KbArticleConstants.PublicationStatus.Draft.name() ? 'Publish' : 'Archive';
                setMessagesForMassArticleAction(action, courseArticles, invalidArticleCount, scheduledDate);
            }
        }
        scheduledDate = null;
        return null;
    }
    
    public PageReference CreateArticle() {
        PageReference CreateArticlePage = new PageReference('/apex/CourseArticleEditor?publishStatus='+PublishStatus+'&searchTerm='+FilterString+'&rtn=/apex/WGUArticles?publishStatus='+PublishStatus);
        CreateArticlePage.setRedirect(true);
        return CreateArticlePage;       
    }
    
    private void setMessagesForMassArticleAction(String action, List<CourseArticle__kav> courseArticles, integer invalidArticleCount, Date scheduledDate) {
        if (courseArticles != null && courseArticles.size() > 0) {
            if (invalidArticleCount > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, invalidArticleCount + ' Article(s) missing required information and cannot be ' + action + 'ed'));
            }
            
            integer processedArticles = courseArticles.size() - invalidArticleCount; 
            if (processedArticles == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No Article(s) were successfully ' + action + 'ed'));
            } else {
                if (scheduledDate == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, processedArticles + ' Article(s) successfully ' + action + 'ed'));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, processedArticles + ' Article(s) successfully scheduled to be ' + action + 'ed on ' + 
                        scheduledDate.month() + '/' + scheduledDate.day() + '/' + scheduledDate.year()));
                }
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please select one or more Articles to ' + action));
        }
    }
    
    public PageReference DeleteArticle() {
        final String action = 'Delete';
        boolean noExceptions = true;
        List<CourseArticle__kav> selectedList = GetSelectedArticles();
        if (selectedList != null && selectedList.size() > 0) {
            Savepoint sp = Database.setSavepoint();
            try {
                CourseArticleDAO.deleteKnowledgeBaseArticles(selectedList);
            } catch (Exception ex) {
                noExceptions = false;
                Database.rollback(sp);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An Error occurred attempting to delete the selected articles.\n\nError Message: ' + ex.getMessage()));
            }
        }
        if (noExceptions) {
            setMessagesForMassArticleAction(action, selectedList, 0, null);
        }
        return null;
    }

    public String getDraftValue() {
        return KbArticleConstants.PublicationStatus.Draft.name();
    }
    
    public String getOnlineValue() {
        return KbArticleConstants.PublicationStatus.Online.name();
    }
    
    public String getArchivedValue() {
        return KbArticleConstants.PublicationStatus.Archived.name();
    }
    
    public String getCourseArticleUrl() {
        return Page.CourseArticle.getUrl();
    }
    
    public String getWguArticlesUrl() {
        return Page.WGUArticles.getUrl();
    }
    
    public String getCourseArticleEditorUrl() {
        return Page.CourseArticleEditor.getUrl();
    }
    
    @RemoteAction
    global static List<CourseArticleInternalView> getCourseArticle(String publishStatus, String searchTerm, List<Id> courseIds, String ownerId) {
        List<Id> courseVersionIds = null;
        if (courseIds != null && courseIds.size() > 0) {
            for (WGUCourseVersion__c courseVersion : [SELECT Id FROM WGUCourseVersion__c WHERE WGUCourse__c IN :courseIds]) {
                if (courseVersionIds == null) {
                    courseVersionIds = new List<Id>();
                }
                courseVersionIds.add(courseVersion.Id);
            }
        }
        String formattedSearchTerm = SoslUtility.generateSearchTerm(new SoslUtility.SoslSearchTerm(searchTerm, true));
        List<CourseArticle__kav> courseArticles = CourseArticleDAO.searchEnglishUsArticles(CourseArticleDAO.SearchAppType.Internal, publishStatus, null, null, formattedSearchTerm, courseVersionIds, ownerId);
        return CourseArticleDAO.getCourseArticleInternalView(courseArticles);
    }
    
    @RemoteAction
    global static List<WGUCourse__c> getCourseList() {
        return [SELECT Id, Name FROM WGUCourse__c];
    }
    
    public class WGUArticlesControllerException extends Exception { }
}