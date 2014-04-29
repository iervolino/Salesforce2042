/*
*Author John Chan
*Slalom
*/
public with sharing class CourseArticleUtility {
	public static void upsertCourseArticle(CourseArticle__kav courseArticle, String uploadFileTitle) {
		//set file title
		if (courseArticle.FileUpload__Body__s != null && String.isNotEmpty(uploadFileTitle)) {
			if (!uploadFileTitle.contains('.')) { //file title does not contain extension
				Integer fileExtPosition = courseArticle.FileUpload__Name__s.lastIndexOf('.');
                if (fileExtPosition > 0) { 
                    uploadFileTitle += courseArticle.FileUpload__Name__s.substring(fileExtPosition);
                }
			}
			courseArticle.FileUpload__Name__s = uploadFileTitle;
		}
		
		setUniqueUrlName(courseArticle);
		if (courseArticle.Id == null) {
			insert courseArticle;
		} else {
			update courseArticle;
		}
	}
	
	public static void setUniqueUrlName(CourseArticle__kav courseArticle) {
		if (string.isNotEmpty(courseArticle.Title)) {
			string urlName = 'Course-Article-';
			if (string.isNotEmpty(courseArticle.ArticleType__c)) {
				urlName += stripInvalidCharactersForUrlName(courseArticle.ArticleType__c) + '-';
			}
			
			urlName += stripInvalidCharactersForUrlName(courseArticle.Title) + '-' + stripInvalidCharactersForUrlName(String.valueOf(Date.today()));
			
			User currentUser = [SELECT PIDM__c FROM User WHERE Id = :UserInfo.getUserId()];
			if (string.isNotEmpty(currentUser.PIDM__c)) {
				urlName += 	stripInvalidCharactersForUrlName(currentUser.PIDM__c);
			}
			courseArticle.UrlName = urlName;
		} else {
			throw new CourseArticleUtilityException('Cannot create Url Name without having a title set for the Course Article.');
		}
	}
	
	private static String stripInvalidCharactersForUrlName(String urlName) {
		string validUrlName = urlName.replace(' ', '-');
		validUrlName = validUrlName.replaceAll('[^a-zA-Z0-9 -]', '-');
		return validUrlName;
	}
	
	public static boolean validatePublishArticle(CourseArticle__kav article) {
    	List<KnowledgeBaseWguCourseVersionLink__c> kbCourseVersionLinks = [SELECT Id FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :article.Id];
        return validatePublishArticle(article.ArticleType__c, article.Summary, article.RichTextArea__c, null, kbCourseVersionLinks, null);
    }
    
    public static boolean validatePublishArticle(CourseArticle__kav article, String courseVersions, String[] validationMsgs) {
        return validatePublishArticle(article.ArticleType__c, article.Summary, article.RichTextArea__c, courseVersions, null, validationMsgs);
    }
    
    public static boolean validatePublishArticle(String articleType, String articleSummary, String richTextField, String courseVersions, 
    		List<KnowledgeBaseWguCourseVersionLink__c> kbCourseVersionLinks, String[] validationMsgs) {
        boolean isValid = true;
        if ((String.isEmpty(articleType)) || (articleType == 'None')) {
            if (validationMsgs != null) {
                validationMsgs.add('Article Type is required for Publishing.');
            }
            isValid = false;
        }
        if (String.isEmpty(articleSummary)) {
            if (validationMsgs != null) {
                validationMsgs.add('Article Summary is required for Publishing.');
            }
            isValid = false;
        }
        if (String.isEmpty(richTextField)) {
            if (validationMsgs != null) {
                validationMsgs.add('Article Body Text is required for Publishing.');
            }
            isValid = false;
        }
        if (String.isEmpty(courseVersions) && kbCourseVersionLinks == null) {
            if (validationMsgs != null) {
                validationMsgs.add('At least one Course / Version must be assigned prior to Publishing.');
            }
            isValid = false;
        } else if (kbCourseVersionLinks != null && kbCourseVersionLinks.size() == 0) {
        	if (validationMsgs != null) {
                validationMsgs.add('At least one Course / Version must be assigned prior to Publishing.');
            }
            isValid = false;
        }
        return isValid;
    }
	
	public class CourseArticleUtilityException extends Exception { }
}