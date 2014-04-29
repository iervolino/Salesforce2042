@isTest
private with sharing class TestWGUArticlesController {

    private static testMethod void testWGUArticlesControllerCreateArticle() {
        User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
        
        Test.setCurrentPage(Page.WGUArticles);
        WGUArticlesController controller = new WGUArticlesController(); 
        
        Test.startTest();
        system.runAs(mentorUser) {
            PageReference createArticleRef = controller.createArticle();
            system.assert(createArticleRef.getRedirect());
            system.debug('create redirect url: ' + createArticleRef.getUrl() + 'create base url: ' + Page.CourseArticleEditor.getUrl());
            system.assert(createArticleRef.getUrl().toLowerCase().contains(Page.CourseArticleEditor.getUrl()));
        }
        Test.stopTest();
    }

    private static testMethod void testWGUArticlesControllerPublishArticle() {
 
        List<CourseArticle__kav> courseArticles;
    
        // Create Test Data
        User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
        Test.setCurrentPage(Page.WGUArticles);
        ApexPages.currentPage().getParameters().put('publishStatus', KbArticleConstants.PublicationStatus.Draft.name());
        WGUArticlesController controller = new WGUArticlesController();

        system.runAs(mentorUser) {
        	TestCourseArticleHelper.createCourseArticleFull('Publish Article 1', 
				Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
				Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'HVC');
			TestCourseArticleHelper.createCourseArticleFull('Publish Article 2', 
				Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
				Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'HCVC');

			Test.startTest();
            // Nothing Selected
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US'];
            system.assertEquals(2, courseArticles.size());      
            controller.submitScheduleRequest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(0, courseArticles.size());

            // One Article Selected - Publish Now
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US'];
            system.assertEquals(2, courseArticles.size());
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;
            controller.submitScheduleRequest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            
            
            //One article scheduled future
            Date futureDt = Date.today().addDays(3);
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;
            controller.scheduledDate = futureDt;
            controller.submitScheduleRequest();
            
            courseArticles = [SELECT Id, KnowledgeArticleId FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            KnowledgeBaseReporting__c kbReport = [SELECT KnowledgeArticleId__c, ScheduledPublishDate__c FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c = :courseArticles.get(0).Id];
            system.assertEquals(futureDt, kbReport.ScheduledPublishDate__c);
            system.assertEquals(courseArticles.get(0).KnowledgeArticleId, kbReport.KnowledgeArticleId__c);
            Test.stopTest();
        }
    }

    private static testMethod void testWGUArticlesControllerPublishInvalidArticle() {
 
        List<CourseArticle__kav> courseArticles;
        User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
        Test.setCurrentPage(Page.WGUArticles);
        ApexPages.currentPage().getParameters().put('publishStatus', 'Draft');
        WGUArticlesController controller = new WGUArticlesController();

        system.runAs(mentorUser) {
        	TestCourseArticleHelper.createCourseArticle(1);
        	
        	Test.startTest();
            // One Article Selected
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            system.assertEquals(0, ApexPages.getMessages().size());
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;
            controller.submitScheduleRequest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(0, courseArticles.size());
            system.assertEquals(2, ApexPages.getMessages().size());
            for (ApexPages.Message message : ApexPages.getMessages()) {
            	system.assertEquals(ApexPages.Severity.WARNING, message.getSeverity());
            }
            Test.stopTest();
        }
    }
    
    private static testMethod void testSubmitSchedulRequestInvalidDate() {
    	List<CourseArticle__kav> courseArticles;
        User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
        Test.setCurrentPage(Page.WGUArticles);
        ApexPages.currentPage().getParameters().put('publishStatus', 'Draft');
        WGUArticlesController controller = new WGUArticlesController();

        system.runAs(mentorUser) {
        	TestCourseArticleHelper.createCourseArticle(1);
        	
        	Test.startTest();
            // One Article Selected
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            system.assertEquals(0, ApexPages.getMessages().size());
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;
            controller.scheduledDate = Date.today();
            controller.submitScheduleRequest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(0, courseArticles.size());
            system.assertEquals(1, ApexPages.getMessages().size());
            system.assertEquals(ApexPages.Severity.WARNING, ApexPages.getMessages()[0].getSeverity());
            Test.stopTest();
        }
    }

    private static testMethod void testWGUArticlesControllerArchiveArticle() {
 
        List<CourseArticle__kav> courseArticles;

        User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
        Test.setCurrentPage(Page.WGUArticles);
        ApexPages.currentPage().getParameters().put('publishStatus', KbArticleConstants.PublicationStatus.Online.name());
        WGUArticlesController controller = new WGUArticlesController();

        // Create CourseArticle as Test User
        system.runAs(mentorUser) {
        	TestCourseArticleHelper.createCourseArticleFull('Archive Article 1', 
				Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
				Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'HVC');
			TestCourseArticleHelper.createCourseArticleFull('Archive Article 2', 
				Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
				Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'HCVC');
				
            courseArticles = [SELECT KnowledgeArticleId FROM CourseArticle__kav WHERE PublishStatus='Draft' AND Language='en_US'];
            KbManagement.PublishingService.publishArticle(courseArticles[0].KnowledgeArticleId, false);
            KbManagement.PublishingService.publishArticle(courseArticles[1].KnowledgeArticleId, false);
        
        	Test.startTest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(2, courseArticles.size());  
            controller.submitScheduleRequest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Archived' AND Language = 'en_US'];
            system.assertEquals(0, courseArticles.size());

            // One Article Selected - Archive Now
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(2, courseArticles.size());
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;           
            controller.submitScheduleRequest();
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Archived' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            
            //One article scheduled future
            Date futureDt = Date.today().addDays(1);
            courseArticles = [SELECT Id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;
            controller.scheduledDate = futureDt;
            controller.submitScheduleRequest();
            
            courseArticles = [SELECT KnowledgeArticleId FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US'];
            system.assertEquals(1, courseArticles.size());
            KnowledgeBaseReporting__c kbReport = [SELECT KnowledgeArticleId__c, ScheduledArchiveDate__c FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c = :courseArticles.get(0).Id];
            system.assertEquals(futureDt, kbReport.ScheduledArchiveDate__c);
            system.assertEquals(courseArticles.get(0).KnowledgeArticleId, kbReport.KnowledgeArticleId__c);
            Test.stopTest();
        }
    }

    private static testMethod void testWGUArticlesControllerDeleteArticle() {
        // Create Test Data
        User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		List<CourseArticle__kav> courseArticles;
        system.runAs(mentorUser) {
            courseArticles = TestCourseArticleHelper.createCourseArticle(4);
            TestCourseArticleHelper.archiveCourseArticle(new List<Id> { courseArticles[0].Id, courseArticles[1].Id });
        }
        // Set up page reference
        Test.setCurrentPage(Page.WGUArticles);
      
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('publishStatus', KbArticleConstants.PublicationStatus.Archived.name());
      
        // Instantiate controller with all parameters in the page
        WGUArticlesController controller = new WGUArticlesController(); 
        
        // Execute Controller methods
        Test.startTest();
        system.runAs(mentorUser) {
            // Nothing Selected
            System.assertEquals(2, [SELECT COUNT() FROM CourseArticle__kav WHERE PublishStatus = 'Archived' AND Language = 'en_US']);
            controller.deleteArticle();
            system.assertEquals(1, ApexPages.getMessages().size());
            system.assertEquals(2, [SELECT COUNT() FROM CourseArticle__kav WHERE PublishStatus = 'Archived' AND Language = 'en_US']);

            // One Archived Article Selected
            controller.knowledgeArticleVersionIds = courseArticles[0].Id;
            controller.deleteArticle();
            system.assertEquals(1, [SELECT COUNT() FROM CourseArticle__kav WHERE PublishStatus = 'Archived' AND Language = 'en_US']);
            
            System.assertEquals(2, [SELECT COUNT() FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US']);
            controller.knowledgeArticleVersionIds = courseArticles[2].Id + ',' + courseArticles[3].Id;
            controller.deleteArticle();
            system.assertEquals(0, [SELECT COUNT() FROM CourseArticle__kav WHERE PublishStatus = 'Draft' AND Language = 'en_US']);
        }
        Test.stopTest();
    }
    
    private static testMethod void testGetPublicationStatusValue() {
    	User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
    	WGUArticlesController controller = new WGUArticlesController();
    	System.runAs(mentorUser) {
    		System.assertEquals(KbArticleConstants.PublicationStatus.Draft.name(), controller.getDraftValue());
    		System.assertEquals(KbArticleConstants.PublicationStatus.Online.name(), controller.getOnlineValue());
    		System.assertEquals(KbArticleConstants.PublicationStatus.Archived.name(), controller.getArchivedValue());
    	}
    }
    
    private static testMethod void testGetPageUrlsForController() {
    	User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
    	WGUArticlesController controller = new WGUArticlesController();
    	System.runAs(mentorUser) {
    		System.assertEquals(Page.CourseArticle.getUrl(), controller.getCourseArticleUrl());
    		System.assertEquals(Page.WGUArticles.getUrl(), controller.getWguArticlesUrl());
    		System.assertEquals(Page.CourseArticleEditor.getUrl(), controller.getCourseArticleEditorUrl());
    	}
    }
    
    private static testMethod void testGetCourseList() {
    	User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
    	Set<String> courseNames = new Set<String> { 'HVC', 'BSB', 'ZAZ' };
    	System.runAs(mentorUser) {
	    	List<WGUCourse__c> unitTestCourses = new List<WGUCourse__c>();
	    	integer i = 0;
	    	for (String courseName : courseNames) {
	    		unitTestCourses.add(TestCourseArticleHelper.createCourse(courseName, 1, i));
	    		i++;
	    	}
		
    		Test.startTest();
    		List<WGUCourse__c> courseList = WGUArticlesController.getCourseList();
    		System.assertEquals(unitTestCourses.size(), courseList.size());
    		for (WGUCourse__c course : courseList) {
    			System.assert(courseNames.contains(course.Name));
    		}
    		Test.stopTest();
    	}
    }
    
    private static testMethod void testGetCourseArticle() {
    	User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
    	User mentorUserOther = TestCourseArticleHelper.getTestUser('testmentorother', 'Mentor', true);
    	CourseArticle__kav courseArticleOther;
    	System.runAs(mentorUserOther) {
    		String articleTitle = 'Article Test Other';
    		courseArticleOther = TestCourseArticleHelper.createCourseArticleFull(articleTitle,
    				Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'Test Course Other');
    	}
    	System.runAs(mentorUser) {
    		String articleTitle = 'Article Test';
    		CourseArticle__kav courseArticle = TestCourseArticleHelper.createCourseArticleFull(articleTitle,
    				Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'Test Course');
			WGUCourse__c course = TestCourseArticleHelper.createCourse('HVC', 3, 1);
					
			Test.startTest();
			//No publish articles nothing should be found
			System.assertEquals(null, WGUArticlesController.getCourseArticle(null, null, null, null));
			
			//Draft articles self
			System.assertEquals(1, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Draft.name(), null, null, mentorUser.Id).size());
			
			//Draft everyone
			System.assertEquals(2, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Draft.name(), null, null, null).size());
			
			Test.setFixedSearchResults(new Id[] { courseArticle.Id });
			KBManagement.PublishingService.publishArticle([SELECT KnowledgeArticleId FROM CourseArticle__kav WHERE Id = :courseArticle.Id].KnowledgeArticleId, false);
			//Find publish article by title everyone
			System.assertEquals(1, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Online.name(), articleTitle, null, null).size());
			
			//Find publish article by course version
			System.assertEquals(1, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Online.name(), null, new List<String> {
						[SELECT WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id].get(0).WGUCourseVersion__c
					}, null).size());
			
			//Find publish artible by title and course version and owner
			System.assertEquals(1, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Online.name(), articleTitle, new List<String> {
						[SELECT WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id].get(0).WGUCourseVersion__c
					}, mentorUser.Id).size());
			
			Test.setFixedSearchResults(null);		
			//No publish articles for course version
			System.assertEquals(null, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Online.name(), null, new List<String> { course.Id }, null));
			
			//associate course version to article and search for articles associate to course version
			Set<String> courseVersionIds = new Set<String>();
			for(WGUCourseVersion__c courseVersion : [SELECT Id FROM WGUCourseVersion__c WHERE WGUCourse__c = :course.Id]) {
				courseVersionIds.add(courseVersion.Id);
			}
			KnowledgeBaseReporting__c kbReport = [SELECT Id FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id];
			KnowledgeBaseReportingDAO.updateCourseVersionLink(null, courseArticle.Id, kbReport.Id, courseVersionIds);
			
			System.assertEquals(1, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Online.name(), null, new List<String> { course.Id }, null).size());
			
			//No publish articles by title
			System.assertEquals(null, WGUArticlesController.getCourseArticle(KbArticleConstants.PublicationStatus.Online.name(), 'No Article Title Found', null, null));
			Test.stopTest();
    	}
    }
}