@isTest
private with sharing class TestCourseArticleController {
	public static testMethod void testDraftArticle() {
        CourseArticle__kav ca = new CourseArticle__kav(Stage__c = 'Draft', Summary = 'Test Summary', Title = 'Test Title', UrlName = 'Test-Title');
        insert ca;
    
        PageReference pageRef = Page.CourseArticle;
        Test.setCurrentPage(pageRef);
        ApexPages.KnowledgeArticleVersionStandardController con = new ApexPages.KnowledgeArticleVersionStandardController(ca);
      
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', ca.id);
        ApexPages.currentPage().getParameters().put('searchTerm', 'ethics');
        ApexPages.currentPage().getParameters().put('courseCode', 'HVT1');
        ApexPages.currentPage().getParameters().put('refineSearchTerm', 'origins');
      
        // Instantiate controller with all parameters in the page
        CourseArticleController controller = new CourseArticleController(con); 
        
        // Call Controller methods
        controller.ReturnToSearch();
        controller.EditArticle();
    }

    public static testMethod void testPublishedArticle() {
    	//Datasetup
    	CourseArticle__kav[] ca = null;
    	User systemAdmin = TestUtilityTestHelper.getTestUser('testadmin', 'System Administrator');
    	System.runAs(systemAdmin) {
    		ca = [Select id FROM CourseArticle__kav WHERE PublishStatus = 'Online' AND Language = 'en_US' LIMIT 1];
    	}
    	
    	//test publishing as mentor profile
    	User kbUser = TestUtilityTestHelper.getTestUser('testmentor', 'Mentor');
    	System.runAs(kbUser) {
	    
	        if (ca.size() > 0) {
	            PageReference pageRef = Page.CourseArticle;
	            Test.setCurrentPage(pageRef);
	            ApexPages.KnowledgeArticleVersionStandardController con = new ApexPages.KnowledgeArticleVersionStandardController(ca[0]);
	          
	            // Add parameters to page URL
	            ApexPages.currentPage().getParameters().put('id', ca[0].id);
	            ApexPages.currentPage().getParameters().put('searchTerm', 'ethics');
	            ApexPages.currentPage().getParameters().put('courseCode', 'HVT1');
	            ApexPages.currentPage().getParameters().put('refineSearchTerm', 'origins');
	          
	            // Instantiate controller with all parameters in the page
	            CourseArticleController controller = new CourseArticleController(con); 
	            
	            // Call Controller methods
	            controller.EditArticle();
	        }
    	}
    }
}