/*
*Author John Chan
*Slalom
*Refactor to include Add and Edit articles to one location
*@4/9/13 add delete for draft articles
*@4/25/13 add validation for rich text field, and requiring course association when creating an article
*@5/7/13 - Update to global to work within iframes/console for remote actions
*/
global with sharing class CourseArticleEditorController {
    
    public enum EditorType {
        Create,
        Edit
    }
    
    public String subHeaderTitle { get; private set; }
    public String displayProperty { get; private set; }
    
    public transient Blob uploadFileContents {get;set;}
    public transient Integer uploadFileSize { get;set; }
    public String uploadContentType { get;set; }
    public String uploadFileName { get;set; }
    public String uploadFileTitle { get; set; }
    public CourseArticle__kav courseArticle { get; private set; }
    public String previousUrl { get; private set; } 
    public String courseAssignmentsString { get; set; }
    public List<KnowledgeBaseWguCourseVersionLink__c> courseAssignmentList { get; private set; }
    public String errorMessage { get; private set; }
    public boolean updateArticle { get; set; }
    
    private Id newKnoweldgeArticleVersionId;
    private EditorType currentEditorType;
    public final String createText = 'Create';
    public final String editText = 'Edit';
    public final String displayPropertyNone = 'none';
    public final String displayPropertyBlock = 'table'; 
    
    public CourseArticleEditorController() {
        //construct return url TODO: Need to update those pages to return this as a single param... why constrcut it here...
        if (string.isNotEmpty(ApexPages.currentPage().getParameters().get('rtn'))) {
            previousUrl =  ApexPages.currentPage().getParameters().get('rtn');
            if (string.isNotEmpty(ApexPages.currentPage().getParameters().get('searchTerm'))) {
                previousUrl += '&SearchTerm=' + ApexPages.currentPage().getParameters().get('searchTerm');
            }
            if (string.isNotEmpty(ApexPages.currentPage().getParameters().get('courseCode'))) {
                previousUrl += '&CourseCode=' + ApexPages.currentPage().getParameters().get('courseCode');
            }
            if (string.isNotEmpty(ApexPages.currentPage().getParameters().get('courseId'))) {
                previousUrl += '&CourseId=' + ApexPages.currentPage().getParameters().get('courseId');
            }
            if (string.isNotEmpty(ApexPages.currentPage().getParameters().get('refineSearchTerm'))) {
                previousUrl += '&RefineSearchTerm=' + ApexPages.currentPage().getParameters().get('refineSearchTerm');
            }
        } else {
            previousUrl = Page.WGUArticles.getUrl();
        }
        
        updateArticle = false;
        //Create Article init
        String knoweldgeArticleVersionId = ApexPages.currentPage().getParameters().get('id');
        if (String.isNotEmpty(knoweldgeArticleVersionId)) {
            setEditDisplay(knoweldgeArticleVersionId);
        } else {
            currentEditorType = EditorType.Create;
            subHeaderTitle = createText;
            displayProperty = displayPropertyNone;
            courseArticle = new CourseArticle__kav(isVisibleInCsp = true);
        }
    }
    
    public List<SelectOption> getArticleTypes() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('None','--None--'));
        for(Schema.PicklistEntry pickList : CourseArticle__kav.ArticleType__c.getDescribe().getPickListValues()) {
            options.add(new SelectOption(pickList.getValue(), pickList.getValue()));
        }        
        return options;
    }
    
    @RemoteAction
    global static JsTreeUtility.JsTree getCourseListJson(String courseAssignments) {
    	Set<String> courseVersionIds = null;
        if (string.isNotEmpty(courseAssignments)) {
            courseVersionIds = new Set<String>(courseAssignments.split(','));
        }
        List<WGUCourse__c> courseList = [SELECT Id, Name, (Select Id, Name, MajorVersion__c, Title__c From WGUCourseVersions__r) FROM WGUCourse__c 
            WHERE Id IN (SELECT Course__c FROM KBCourseManagement__c WHERE Mentor__r.User__c = :UserInfo.getUserId())];
		courseList.addAll([SELECT Name, (Select Id, Name, MajorVersion__c, Title__c From WGUCourseVersions__r) FROM WGUCourse__c 
            WHERE Id IN (SELECT WGUCourse__c FROM WGUCourseVersion__c WHERE Id IN :courseVersionIds) AND Id NOT IN :courseList]);
        
        return JsTreeUtility.createJsTreeFromCourseList(courseList, courseVersionIds);
    }
    
    public PageReference publishArticle() {
        if (saveArticle(true)) {
            PageReference pageRef = new PageReference(previousUrl);
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
    
    public PageReference save() {
        if(saveArticle(false)) {
            PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?id=' + newKnoweldgeArticleVersionId);
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
    
    public PageReference saveAndClose() {
        if (saveArticle(false)) {
            PageReference pageRef = new PageReference(previousUrl);
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
    
    public PageReference deleteArticle() {
        Savepoint sp = Database.setSavepoint();
        try {
        	errorMessage = null;
            CourseArticleDAO.deleteKnowledgeBaseArticle(courseArticle);
            PageReference pageRef = new PageReference(previousUrl);
            pageRef.setRedirect(true);
            return pageRef;
        } catch (Exception ex) {
            displayException(ex);
            Database.rollback(sp);
        }
        return null;
    }
    
    private boolean saveArticle(boolean publishArticle) {
    	errorMessage = null;
        boolean succesful = false;
        boolean editOnlineArticle = false;
        if (courseArticle.PublishStatus == kbArticleConstants.PublicationStatus.Online.name()) {
            publishArticle = true;
            editOnlineArticle = true;
        }
        if (validateInput(publishArticle)) {
            Savepoint sp = Database.setSavepoint(); //Ran into some weird saving issues so trying to employ a rollback just in case
            try {
                if (editOnlineArticle) {
                    courseArticle.Id = KBManagement.PublishingService.editOnlineArticle(courseArticle.KnowledgeArticleId, true);
                    courseAssignmentList = null; //reset courseAssignmentList as this is a new version and prior version should keep all it's existing links and new version needs to create all new links
                    KnowledgeBaseReportingUtility.removeKbArticlesFromLatestVersion(courseArticle); //update reporting table to remove all previous versions as the latest version.
                }
                
                CourseArticle__kav courseArticleUpdate = courseArticle.clone(true, true, false, true);
                
                //set file properties for course article if file was uploaded
                if (uploadFileContents != null || updateArticle) {
                    courseArticleUpdate.FileUpload__Body__s = uploadFileContents;
                    courseArticleUpdate.FileUpload__Name__s = uploadFileName;
                    courseArticleUpdate.FileUpload__ContentType__s = uploadContentType;
                    updateArticle = false;
                }
                CourseArticleUtility.upsertCourseArticle(courseArticleUpdate, uploadFileTitle);
                
                if (publishArticle) {
                    KBManagement.PublishingService.publishArticle(courseArticle.KnowledgeArticleId, false); //Is there a reason we are only doing minor versions?
                }
                
                courseArticleUpdate = CourseArticleDAO.getForKnowledgeBaseUpsert(courseArticleUpdate.Id);
                KnowledgeBaseReporting__c kbReport = KnowledgeBaseReportingUtility.createKbReportByArticle(courseArticleUpdate);
                upsert kbReport KnowledgeArticleVersionId__c;
                
                //Create KnowledgeBaseWguCourseVersionLink__c 
                if (String.isNotEmpty(courseAssignmentsString)) {
                    KnowledgeBaseReportingDAO.updateCourseVersionLink(courseAssignmentList, courseArticleUpdate.Id, kbReport.Id, new Set<String>(courseAssignmentsString.split(',')));
                }
                
                newKnoweldgeArticleVersionId = courseArticleUpdate.Id; 
                succesful = true;
            } catch (Exception ex) {
                displayException(ex);
                Database.rollback(sp);
            }
        }
        return succesful;
    }
    
    private Boolean validateInput(boolean publishArticle) {
        Boolean returnValue = true;
        if (publishArticle) {
            String[] validationMsgs = new String[] {};
            returnValue = CourseArticleUtility.validatePublishArticle(courseArticle, courseAssignmentsString, validationMsgs);
            for (String message : validationMsgs) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
            }
        }
        
        if(uploadFileSize > 5242880){  
            //maximum attachment size is 5MB.  Show an error
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'The file was NOT uploaded, because it is too big. 5MB is the limit.'));
            returnValue = false;
        }
        
        if (String.isEmpty(courseAssignmentsString)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Course Assignment is required.'));   
            returnValue = false;        
        }
        
        if (uploadFileContents != null) {
            if (String.isEmpty(uploadFileTitle)) { //If no file title is declared we use the file name
                if (uploadFileName.length() > 40) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Upload File Name is too long (maximum 40 characters). Please enter a File Title that is less than 40 characters long.'));
                    returnValue = false;
                }
            } else {
                if (uploadFileTitle.length() > 40) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Upload File Title is too long (maximum 40 characters). Please enter a File Title that is less than 40 characters long.'));
                    returnValue = false;
                }
            }
        }
        
        //SFDC strips out newlines and blank space encodings before inserting into rich text, so had to strip those out to get the correct character count for now...  This might eventually break if SFDC decides to change this
        if (String.isNotEmpty(courseArticle.RichTextArea__c)) {
            String richTextArea = courseArticle.RichTextArea__c.replace('\n', '').replace('&nbsp;', ' ').trim();
            if (richTextArea.length() > 32768) {
                returnValue = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Article Body is too long (maximum 32768 characters; current ' + richTextArea.length() + ' characters). Please enter a Article Body that is less than 32768 characters long.'));
            }
        }
        return returnValue;
    }
    
    private void setEditDisplay(String knowledgeArticleVersionId) {
        courseArticle = CourseArticleDAO.getForCreateArticleControllerDisplay(knowledgeArticleVersionId);
        uploadFileTitle = courseArticle.FileUpload__Name__s;
        currentEditorType = EditorType.Edit;
        subHeaderTitle = editText;
        displayProperty = displayPropertyBlock;
        courseAssignmentList = [SELECT Id, WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :knowledgeArticleVersionId];
        courseAssignmentsString = KnowledgeBaseReportingUtility.getCourseVersionsStringByRelatedList(courseAssignmentList);
    }
    
    private void displayException(Exception ex) {
        //TODO: Move this to a exception handler and potentially with logging to a custom object
        errorMessage = 'Errors occurred while saving the Article information.\n\nError Type: '+ ex.getTypeName() + '\nError Cause: ' + ex.getCause() + 
            '\nError Message: ' + ex.getMessage() + '\nError Line: ' + ex.getLineNumber() + ex.getStackTraceString();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to process article action.'));
    }
    
    public class CourseArticleEditorControllerException extends Exception { }
}