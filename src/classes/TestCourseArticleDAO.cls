/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestCourseArticleDAO {
	public static testMethod void testGetForKnowledgeBaseReportBatch() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
			//No values returned because test data isn't setup
			String language = Schema.SObjectType.CourseArticle__kav.fields.Language.getPickListValues()[0].getValue();
			List<CourseArticle__kav> courseArticles = CourseArticleDAO.getForKnowledgeBaseReportBatch(KbArticleConstants.PublicationStatus.Draft.name(), language);
			System.assertEquals(0, courseArticles.size());
			
			//Draft
			List<CourseArticle__kav> createdCourseArticles = TestCourseArticleHelper.createCourseArticle(3);
			courseArticles = CourseArticleDAO.getForKnowledgeBaseReportBatch(KbArticleConstants.PublicationStatus.Draft.name(), language);
			System.assertEquals(createdCourseArticles.size(), courseArticles.size());
			
			//Online
			courseArticles = CourseArticleDAO.getForKnowledgeBaseReportBatch(KbArticleConstants.PublicationStatus.Online.name(), language);
			System.assertEquals(0, courseArticles.size());
			TestCourseArticleHelper.publishCourseArticle(createdCourseArticles);
			courseArticles = CourseArticleDAO.getForKnowledgeBaseReportBatch(KbArticleConstants.PublicationStatus.Online.name(), language);
			System.assertEquals(createdCourseArticles.size(), courseArticles.size());
    	}
	}
	
	public static testMethod void testGetForKnowledgeBaseReportCleanupBatch() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
			//test exception
			String[] languages = TestCourseArticleHelper.getCourseArticleLanguageList();
			KbArticleConstants.PublicationStatus[] publicationStatus = new KbArticleConstants.PublicationStatus[] {};
			for (integer i = 0; (CourseArticleDAO.maxPublishStatusSize + 1) > i; i++) {
				publicationStatus.add(KbArticleConstants.PublicationStatus.Online);
			}
			
			try {
				CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(publicationStatus, languages);
			} catch (CourseArticleDAO.CourseArticleDAOException cadEx) {
				System.assert(true); 
			} catch (Exception ex) {
				System.assert(false);
			}
			
			//Draft
			List<CourseArticle__kav> createdCourseArticles = TestCourseArticleHelper.createCourseArticle(3);
			Map<Id, CourseArticle__kav> courseArticleMap = CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(
															new KbArticleConstants.PublicationStatus[] { KbArticleConstants.PublicationStatus.Online }, languages);
			System.assertEquals(0, courseArticleMap.size());
			courseArticleMap = CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(
								new KbArticleConstants.PublicationStatus[] { KbArticleConstants.PublicationStatus.Draft }, languages);
			System.assertEquals(createdCourseArticles.size(), courseArticleMap.size());
			
			//Mixed
			TestCourseArticleHelper.publishCourseArticle(new Id[] { createdCourseArticles.get(0).Id });
			courseArticleMap = CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(
								new KbArticleConstants.PublicationStatus[] { KbArticleConstants.PublicationStatus.Draft }, languages);
			System.assertEquals((createdCourseArticles.size() - 1), courseArticleMap.size());
			
			courseArticleMap = CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(KbArticleConstants.PublicationStatus.values(), languages);
			System.assertEquals(createdCourseArticles.size(), courseArticleMap.size());
    	}
	}
	
	public static testMethod void testGetCourseArticleStudentView() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
		Map<String, String> articleTypeToIconClass = new Map<String, String> { KbArticleConstants.ArticleTypeWelcomeVideo => 'welcome-video-icon', KbArticleConstants.ArticleTypeGettingStarted => 'getting-started-icon',
			KbArticleConstants.ArticleTypeLearningResource => 'learning-resource-icon', KbArticleConstants.ArticleTypeCourseAtAGlance => 'course-at-a-glance-icon', KbArticleConstants.ArticleTypeOther => 'other-icon'};
    	System.runAs(systemAdmin) {
    		List<CourseArticle__kav> createdCourseArticles = TestCourseArticleHelper.createCourseArticle(5);
    		createdCourseArticles[0].ArticleType__c = KbArticleConstants.ArticleTypeWelcomeVideo;
    		createdCourseArticles[1].ArticleType__c = KbArticleConstants.ArticleTypeCourseAtAGlance;
    		createdCourseArticles[2].ArticleType__c = KbArticleConstants.ArticleTypeGettingStarted;
    		createdCourseArticles[3].ArticleType__c = KbArticleConstants.ArticleTypeLearningResource;
    		createdCourseArticles[4].ArticleType__c = KbArticleConstants.ArticleTypeOther;
    		update createdCourseArticles;
    		TestCourseArticleHelper.publishCourseArticle(createdCourseArticles);
    		createdCourseArticles = [SELECT Id, KnowledgeArticleId, ArticleType__c FROM CourseArticle__kav WHERE ID IN :createdCourseArticles];
    		
    		List<CourseArticleDAO.CourseArticleStudentView> articleViews = CourseArticleDAO.getCourseArticleStudentView(createdCourseArticles);
    		System.assertEquals(5, articleViews.size());
    		for (CourseArticleDAO.CourseArticleStudentView articleView : articleViews) {
    			System.assertEquals(articleTypeToIconClass.get(articleView.courseArticle.ArticleType__c), articleView.getImageClass());
    		} 
    	}
	}
	
	public static testMethod void testGetCourseArticleInternalView() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
		Date publishDt = Date.today().addDays(3);
		Date archiveDt = Date.today().addDays(10);
    	System.runAs(systemAdmin) {
    		List<CourseArticle__kav> createdCourseArticles = TestCourseArticleHelper.createCourseArticle(2);
    		TestCourseArticleHelper.publishCourseArticle(createdCourseArticles);
    		createdCourseArticles = [SELECT Id, KnowledgeArticleId, ArticleType__c FROM CourseArticle__kav WHERE ID IN :createdCourseArticles];
    		List<KnowledgeBaseReporting__c> kbReports = new List<KnowledgeBaseReporting__c> { 
    			new KnowledgeBaseReporting__c(KnowledgeArticleVersionId__c = createdCourseArticles.get(0).Id, KnowledgeArticleId__c =  createdCourseArticles.get(0).KnowledgeArticleId, ScheduledPublishDate__c = publishDt),
    			new KnowledgeBaseReporting__c(KnowledgeArticleVersionId__c = createdCourseArticles.get(1).Id, KnowledgeArticleId__c =  createdCourseArticles.get(1).KnowledgeArticleId, ScheduledArchiveDate__c = archiveDt) 
    		};
    		insert kbReports;
    		
    		Map<Id, CourseArticleInternalView> articleViewMap = new Map<Id, CourseArticleInternalView>();
    		for (CourseArticleInternalView articleView : CourseArticleDAO.getCourseArticleInternalView(createdCourseArticles)) {
    			articleViewMap.put(articleView.courseArticle.Id, articleView);
    		}
    		System.assertEquals(2, articleViewMap.size());
    		System.assertEquals(publishDt, articleViewMap.get(createdCourseArticles.get(0).Id).ScheduledPublishDate);
    		System.assertEquals(null, articleViewMap.get(createdCourseArticles.get(0).Id).ScheduledArchiveDate);
    		System.assertEquals(null, articleViewMap.get(createdCourseArticles.get(1).Id).ScheduledPublishDate);
    		System.assertEquals(archiveDt, articleViewMap.get(createdCourseArticles.get(1).Id).ScheduledArchiveDate);
    	}
	}
}