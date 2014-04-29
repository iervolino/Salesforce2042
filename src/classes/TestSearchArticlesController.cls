@isTest
private class TestSearchArticlesController {
	
	private static final String courseMajorVersionDefault = 'All';
	private static final String courseCode = 'UT1';
	private static final String mentorEmail = 'unit.test@test.com';
	private static final String mentorName = 'Unit Test';
	private static User studentUser;
	static {
		User adminUser = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
		System.runAs(adminUser) {
			studentUser = TestCourseArticleHelper.getTestStudent('teststudent', 'Test', 'Student');
			TestCourseArticleHelper.createCourseArticleFull('SearchArticles', KbArticleConstants.ArticleTypeCourseAtAGlance,
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), courseCode);
		}
	}

    public static testMethod void testInitByCourseIdNoMentor() {
    	System.runAs(studentUser) {
	    	TestCourseArticleHelper.createMentorContact('NOTFOUND', mentorEmail, mentorName);
	    	WGUCourseVersion__c courseVersion = [SELECT CourseOfStudyId__c FROM WGUCourseVersion__c WHERE WGUCourse__r.Name = :courseCode LIMIT 1];
	    	PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?searchTerm=Unit Test&courseId=' + courseVersion.CourseOfStudyId__c);
			Test.setCurrentPage(pageRef);
			
			Test.startTest();
			SearchArticlesController controller = new SearchArticlesController();
			Test.stopTest();
			
			System.assertEquals(courseCode, controller.courseCode);
			System.assertNotEquals(courseMajorVersionDefault, controller.majorVersionToDisplay);
			System.assert(!controller.showContactMyMentorButton);
    	}
    }
    
    public static testMethod void testInitByCourseCodeWithMentor() {
    	System.runAs(studentUser) {
	    	TestCourseArticleHelper.createMentorContact(courseCode, mentorEmail, mentorName);
	    	PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?searchTerm=Unit Test&courseCode=' + courseCode);
			Test.setCurrentPage(pageRef);
			
			Test.startTest();
			SearchArticlesController controller = new SearchArticlesController();
			Test.stopTest();
			
			System.assertEquals(courseCode, controller.courseCode);
			System.assertEquals(courseMajorVersionDefault, controller.majorVersionToDisplay);
	    	System.assert(controller.showContactMyMentorButton);
	    	System.assertEquals(mentorName, controller.mentorName);
	    	System.assertEquals(mentorEmail, controller.mentorEmail);
	    	
	    	System.assert(!controller.componentAttributes.isVisible);
	    	controller.showPopup();
	    	System.assert(controller.componentAttributes.isVisible);
	    	System.assertEquals(URL.getSalesforceBaseUrl().toExternalForm() + '/', controller.getBaseURL());
    	}
    }
    
    public static testMethod void testSearchArticleValidation() {
    	System.runAs(studentUser) {
	    	PageReference pageRef = Page.SearchArticles;
	        Test.setCurrentPage(pageRef);
	        
	        Test.startTest();
	        SearchArticlesController controller = new SearchArticlesController();
	        system.debug('testSearchArticleValidation messages: ' + ApexPages.getMessages());
	        System.assertEquals(1, ApexPages.getMessages().size());
	        System.assert(ApexPages.getMessages()[0].getSummary().contains('Search Term may not be blank.'));
	        
	        controller.searchTerm = 'a';
	        controller.doSearch();
	        System.assertEquals(2, ApexPages.getMessages().size());
	        System.assert(ApexPages.getMessages()[1].getSummary().contains('Search Term must be longer than one character.'));
	        Test.stopTest();
    	}
    }
}