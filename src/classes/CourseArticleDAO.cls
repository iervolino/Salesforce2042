/*
*Author John Chan
*Slalom
*@4/9/13 Article delete and Online article search
*@4/24/13 Add new query fields to support new reporting fields and data migration from course articles
*@5/22/13 New view object to hold css class, view count.
*@5/24/13 New static method to build new internal wrapper view class
*/
public with sharing class CourseArticleDAO {
	private static final String kbReportDataMigrationQuery = 'SELECT Id, CreatedById, CreatedDate, LastModifiedById, ArchivedDate, KnowledgeArticleId, ArticleType__c,' + 
							' LastPublishedDate, PublishStatus, Stage__c, Summary, Title, UrlName, IsVisibleInCsp, IsVisibleInApp, IsVisibleInPrm, IsVisibleInPkb,' + 
							' IsLatestVersion, VersionNumber FROM CourseArticle__kav WHERE ';
	public static List<CourseArticle__kav> getForKnowledgeBaseReportBatch(String publishStatus, String language) {
		String query = kbReportDataMigrationQuery;
		query += ' PublishStatus = \'' + string.escapeSingleQuotes(publishStatus) + '\'';
		query += 'AND Language = \'' + string.escapeSingleQuotes(language) + '\'';
		
		return Database.query(query); 
	}
	
	public static CourseArticle__kav getForKnowledgeBaseUpsert(Id knoweldgeArticleVersionId) {
		String query = kbReportDataMigrationQuery;
		query += 'Id = \'' + knoweldgeArticleVersionId + '\'';
		return Database.query(query);
	}
	
	public static CourseArticle__kav getForCreateArticleControllerDisplay(String Id) {
		return [SELECT Id, PublishStatus, ArticleNumber, CreatedBy.Name, LastModifiedBy.Name, Title, ArticleType__c, Summary, RichTextArea__c, FileUpload__Name__s, 
			KnowledgeArticleId, InternalTagging__c FROM CourseArticle__kav WHERE Id = :Id];
	}
	
	public static final integer maxPublishStatusSize = 5;
	//TODO: Need to chunk out in case it reaches character limit for soql
	public static Map<Id, CourseArticle__kav> getForKnowledgeBaseReportCleanupBatch(KbArticleConstants.PublicationStatus[] publishStatus, String[] languages) {
		//Because we are doing a forloop that contains a soql call we are restricting this call to no more then 5 status.  In theory there are only 3 Publish Status.
		if (publishStatus.size() > maxPublishStatusSize) {
			throw new CourseArticleDAOException('Unable to call CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch.  Limiting DAO call to 5 publish status because this function loops through the publish status to make SOQL calls to prevent hitting governer limits.');
		}
		Map<Id, CourseArticle__kav> courseArticles = new Map<Id, CourseArticle__kav>();	
		for (KbArticleConstants.PublicationStatus status : publishStatus) {
			//String query = queryToken.replace(publishStatusToken, status);
			Map<Id, CourseArticle__kav> courseArticlePartialList = null;
			if (status == KbArticleConstants.PublicationStatus.Draft) {
				courseArticlePartialList = new Map<Id, CourseArticle__kav>([SELECT Id from CourseArticle__kav where PublishStatus = 'Draft' and Language in :languages]);
			} else if (status == KbArticleConstants.PublicationStatus.Online) {
				courseArticlePartialList = new Map<Id, CourseArticle__kav>([SELECT Id from CourseArticle__kav where PublishStatus = 'Online' and Language in :languages]);
			} else if (status == KbArticleConstants.PublicationStatus.Archived) {
				courseArticlePartialList = new Map<Id, CourseArticle__kav>([SELECT Id from CourseArticle__kav where PublishStatus = 'Archived' and Language in :languages]);
			}
			if (courseArticlePartialList != null && courseArticlePartialList.size() > 0) {
				courseArticles.putAll(courseArticlePartialList);
			}
		}
		
		return courseArticles;
	}
	
	/*DELETE ARTICLE BEGIN*/
	public static void deleteKnowledgeBaseArticle(CourseArticle__kav courseArticle) {
		if (courseArticle.PublishStatus == KbArticleConstants.PublicationStatus.Draft.name()) {
    		KbManagement.PublishingService.deleteDraftArticle(courseArticle.KnowledgeArticleId);
    	} else if (courseArticle.PublishStatus == KbArticleConstants.PublicationStatus.Archived.name()) {
        	KbManagement.PublishingService.deleteArchivedArticle(courseArticle.KnowledgeArticleId);
    	}
    	delete [SELECT Id FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id];
	}
	
	public static void deleteKnowledgeBaseArticles(List<CourseArticle__kav> courseArticles) {
		//Should we just let the batch job delete this?  This might run into potential governer limits if mass records are selected
    	List<Id> knowledgeArticleVersionIds = new List<Id>();
        for (CourseArticle__kav article : courseArticles) {
        	knowledgeArticleVersionIds.add(article.Id);
        	if (article.PublishStatus == KbArticleConstants.PublicationStatus.Draft.name()) {
        		KbManagement.PublishingService.deleteDraftArticle(article.KnowledgeArticleId);
        	} else if (article.PublishStatus == KbArticleConstants.PublicationStatus.Archived.name()) {
            	KbManagement.PublishingService.deleteArchivedArticle(article.KnowledgeArticleId);
        	}
        }
        delete [SELECT Id FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c IN :knowledgeArticleVersionIds];
	}
	/*DELETE ARTICLE END*/
	
	/*ONLINE ARTICLE SEARCH BEGIN*/
	public static List<CourseArticle__kav> searchEnglishUsArticles(SearchAppType searchAppType, String publishStatus, String courseCode, String courseOfStudyId, String searchTerm, List<Id> courseVersionIds,
			String ownerId) {
		List<List<sObject>> courseArticlesSearch = null;
		List<CourseArticle__kav> courseArticleList = null;
		final String searchTermToken = '[[searchTerm]]';
		final String publishStatusToken = '[[publishStatus]]';
		final String courseArticleIdFilterToken = '[[courseArticleIdFilter]]';
		final String queryFieldsToken = '[[queryFields]]';
		final String ownerFilterToken = '[[ownerFilter]]';
		final String queryFieldsInteral = 'Id, Title, ArticleType__c, CreatedDate, LastModifiedDate, KnowledgeArticleId';
		final String queryFieldsStudent = 'Id, KnowledgeArticleId, Title, UrlName, Summary, LastPublishedDate, ArticleType__c';
		final String soslQuery = 'FIND ' + searchTermToken + ' IN ALL FIELDS RETURNING CourseArticle__kav (' + queryFieldsToken + ' WHERE PublishStatus = \'' + publishStatusToken + 
				'\' AND Language = \'en_US\' ' + courseArticleIdFilterToken + ownerFilterToken + ')';
		final String soqlQuery = 'SELECT ' + queryFieldsToken + ' FROM CourseArticle__kav WHERE PublishStatus = \'' + publishStatusToken + '\' AND Language = \'en_US\' ' + courseArticleIdFilterToken + ownerFilterToken;
		
		boolean filteredByCourseVersion = (String.isNotEmpty(courseCode) || String.isNotEmpty(courseOfStudyId) || (courseVersionIds != null && courseVersionIds.size() > 0));
		List<AggregateResult> kbCourseVersionLinks = null;
		if (String.isNotEmpty(courseCode)) {
			kbCourseVersionLinks = [SELECT KnowledgeArticleVersionId__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE WGUCourseVersion__r.Name = :courseCode GROUP BY KnowledgeArticleVersionId__c];
		} else if (String.isNotEmpty(courseOfStudyId)) {
			kbCourseVersionLinks = [SELECT KnowledgeArticleVersionId__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE WGUCourseVersion__r.CourseOfStudyId__c = :Decimal.valueOf(courseOfStudyId) GROUP BY KnowledgeArticleVersionId__c];
		} else if (courseVersionIds != null && courseVersionIds.size() > 0) {
			kbCourseVersionLinks = [SELECT KnowledgeArticleVersionId__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE WGUCourseVersion__c IN :courseVersionIds GROUP BY KnowledgeArticleVersionId__c];
		}
		
		//query only if we have linked course versions or we are not querying by linked course versions.
		if ((!filteredByCourseVersion || kbCourseVersionLinks != null && kbCourseVersionLinks.size() > 0) && String.isNotEmpty(publishStatus)) {
			String query = '';
			String commaSeperateArticleVersionIds = null;
			if (kbCourseVersionLinks != null && kbCourseVersionLinks.size() > 0) {
				for (AggregateResult versionLink : kbCourseVersionLinks) {
					if (String.isEmpty(commaSeperateArticleVersionIds)) {
						commaSeperateArticleVersionIds = '\'' + versionLink.get('KnowledgeArticleVersionId__c') + '\'';
					} else {
						commaSeperateArticleVersionIds += (',\'' + versionLink.get('KnowledgeArticleVersionId__c') + '\'');
					}
				}
			}
			
			if (String.isNotEmpty(searchTerm)) {
				query = soslQuery.replace(searchTermToken, '{' + searchTerm + '}');
			} else {
				query = soqlQuery;
			}
			if (String.isNotEmpty(ownerId))  {
				query = query.replace(ownerFilterToken, ' AND OwnerId = \'' + ownerId + '\'');
			} else {
				query = query.replace(ownerFilterToken, '');
			}
			query = query.replace(publishStatusToken, publishStatus);
			
			if (searchAppType == CourseArticleDAO.SearchAppType.Internal) {
				query = query.replace(queryFieldsToken, queryFieldsInteral);
			} else if (searchAppType == CourseArticleDAO.SearchAppType.Student) {
				query = query.replace(queryFieldsToken, queryFieldsStudent);
			}
			
			if (String.isNotEmpty(commaSeperateArticleVersionIds)) {
				query = query.replace(courseArticleIdFilterToken, 'AND Id IN (' + commaSeperateArticleVersionIds + ')');
				//Salesforce has a limit of 10,000 characters in dynamic soql/sosl.  We will throw an exception preventing them from hitting this limit
				if (query.length() >= 10000) {
					throw new CourseArticleDAOException('Unable to perform search.  Please narrow your search parameters and try again.');
				}
			} else {
				query = query.replace(courseArticleIdFilterToken, '');
			}
			
			system.debug('searchEnglishUsArticles query string: ' + query);
			//search term exists then we use a sosl query
			if (String.isNotEmpty(searchTerm)) {
				courseArticlesSearch = search.query(query);
			} else {
				courseArticleList = Database.query(query);
			}
		}
		 
		if (courseArticlesSearch != null && courseArticlesSearch.size() > 0 && courseArticlesSearch[0].size() > 0) {
			return (List<CourseArticle__kav>)courseArticlesSearch[0];
		} else if (courseArticleList != null && courseArticleList.size() > 0) {
			return courseArticleList;
		}else {
			return null;
		}
	}
	
	public static List<CourseArticleStudentView> getCourseArticleStudentView(List<CourseArticle__kav> courseArticles) {
		if (courseArticles != null && courseArticles.size() > 0) {
			Map<Id, CourseArticleStudentView> articleViewMap = new Map<Id, CourseArticleStudentView>();
			for (CourseArticle__kav courseArticle : courseArticles) {
				articleViewMap.put(courseArticle.KnowledgeArticleId, new CourseArticleStudentView(courseArticle));
			}
			
			for (CourseArticle__ViewStat articleViewStat : [SELECT ParentId, ViewCount FROM CourseArticle__ViewStat WHERE ParentId IN :articleViewMap.keySet() AND Channel = :KbArticleConstants.Channel.Csp.Name()]) {
				articleViewMap.get(articleViewStat.ParentId).viewCount = articleViewStat.ViewCount;
			}
			return articleViewMap.values();
		}
		return null;
	}
	
	public class CourseArticleStudentView {
		public CourseArticleStudentView(CourseArticle__kav courseArticle) {
			this.courseArticle = courseArticle;
			setImageClass();
		}
		public CourseArticle__kav courseArticle { get; private set; }
		private String imageClass;
		public integer viewCount { get; set; }
		
		public String getImageClass() {
			return this.imageClass;
		}
		
		private void setImageClass() {
			if (courseArticle.ArticleType__c == KbArticleConstants.ArticleTypeWelcomeVideo) {
				imageClass = 'welcome-video-icon';
			} else if (courseArticle.ArticleType__c == KbArticleConstants.ArticleTypeGettingStarted) {
				imageClass = 'getting-started-icon';
			} else if (courseArticle.ArticleType__c == KbArticleConstants.ArticleTypeLearningResource) {
				imageClass = 'learning-resource-icon';
			} else if (courseArticle.ArticleType__c == KbArticleConstants.ArticleTypeCourseAtAGlance) {
				imageClass = 'course-at-a-glance-icon';
			} else if (courseArticle.ArticleType__c == KbArticleConstants.ArticleTypeOther) {
				imageClass = 'other-icon';
			}
		}
	}
	
	public static List<CourseArticleInternalView> getCourseArticleInternalView(List<CourseArticle__kav> courseArticles) {
		if (courseArticles != null && courseArticles.size() > 0) {
			Map<Id, CourseArticleInternalView> articleViewMap = new Map<Id, CourseArticleInternalView>();
			for (CourseArticle__kav courseArticle : courseArticles) {
				articleViewMap.put(courseArticle.Id, new CourseArticleInternalView(courseArticle));
			}
			
			for (KnowledgeBaseReporting__c kbReport : [SELECT KnowledgeArticleVersionId__c, ScheduledArchiveDate__c, ScheduledPublishDate__c FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c IN :articleViewMap.keySet()]) {
				articleViewMap.get(kbReport.KnowledgeArticleVersionId__c).ScheduledPublishDate = kbReport.ScheduledPublishDate__c;
				articleViewMap.get(kbReport.KnowledgeArticleVersionId__c).ScheduledArchiveDate = kbReport.ScheduledArchiveDate__c;
			}
			return articleViewMap.values();
		}
		return null;
	}
	
	public enum SearchAppType {
		Internal,
		Student
	}
	/*ONLINE ARTICLE SEARCH END*/
	
	public class CourseArticleDAOException extends Exception { }
}