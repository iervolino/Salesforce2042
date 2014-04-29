/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestKnowledgeBaseReportCleanupBatchUtil {
	
	private static final String apexJobStatusCompleted = 'Completed';
	private static final Integer defaultKbReportSize = 3;
	private static KnowledgeBaseReportCleanupBatchUtility batchUtility;
	
	public static testMethod void testAllKbReportsFound() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
    		TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
			batchUtility = new KnowledgeBaseReportCleanupBatchUtility(KbArticleConstants.PublicationStatus.values(), TestCourseArticleHelper.getCourseArticleLanguageList());
	    	List<KnowledgeBaseReporting__c> kbReportList = TestCourseArticleHelper.createKnowledgeBaseReporting(defaultKbReportSize);
	    	TestCourseArticleHelper.createCourseArticleLink(kbReportList);
	    	System.Assert(kbReportList.size() == defaultKbReportSize);
	        
	        Test.startTest();
	        ID BatchProcessId = Database.executeBatch(batchUtility);
	        Test.stopTest();
	       	AsyncApexJob apexJob = [SELECT NumberOfErrors, Status FROM AsyncApexJob WHERE Id = :BatchProcessId];
	       	System.AssertEquals(apexJobStatusCompleted, apexJob.Status);
	       	System.Assert(apexJob.NumberOfErrors == 0);
	       	
	       	kbReportList = [SELECT Id FROM KnowledgeBaseReporting__c];
	        System.AssertEquals(defaultKbReportSize, kbReportList.size());
    	}
	}
	
    public static testMethod void testRemoveKBReports() {
    	User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
    		TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
	    	final integer reduceCourseArticleCount = 1;
	    	batchUtility = new KnowledgeBaseReportCleanupBatchUtility(KbArticleConstants.PublicationStatus.values(), TestCourseArticleHelper.getCourseArticleLanguageList());
	    	List<KnowledgeBaseReporting__c> kbReportList = TestCourseArticleHelper.createKnowledgeBaseReporting(defaultKbReportSize);
	    	System.Assert(kbReportList.size() == defaultKbReportSize);
	    	TestCourseArticleHelper.createCourseArticleLink(kbReportList);
	        List<CourseArticle__ka> courseArticles = [SELECT Id FROM CourseArticle__ka];
	        KbManagement.PublishingService.deleteDraftArticle(courseArticles.get(reduceCourseArticleCount - 1).Id);
	        
	        Test.startTest();
	        ID BatchProcessId = Database.executeBatch(batchUtility);
	        Test.stopTest();
	       	AsyncApexJob apexJob = [SELECT NumberOfErrors, Status FROM AsyncApexJob WHERE Id = :BatchProcessId];
	       	System.AssertEquals(apexJobStatusCompleted, apexJob.Status);
	       	System.Assert(apexJob.NumberOfErrors == 0);
	       	
	       	kbReportList = [SELECT Id FROM KnowledgeBaseReporting__c];
	        System.AssertEquals((defaultKbReportSize - reduceCourseArticleCount), kbReportList.size());
    	}

    }

    public static testMethod void testNoReportsFound() {
    	User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
    		TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
	    	batchUtility = new KnowledgeBaseReportCleanupBatchUtility(KbArticleConstants.PublicationStatus.values(), TestCourseArticleHelper.getCourseArticleLanguageList());
	    	
			//test no reports found in reporting table
	        List<KnowledgeBaseReporting__c> kbReportList = [SELECT Id FROM KnowledgeBaseReporting__c];
	        System.Assert(kbReportList.size() == 0);
	        Test.startTest();
	        ID BatchProcessId = Database.executeBatch(batchUtility);
	        Test.stopTest();
	        
	       	AsyncApexJob apexJob = [SELECT NumberOfErrors, Status FROM AsyncApexJob WHERE Id = :BatchProcessId];
	       	System.AssertEquals(apexJobStatusCompleted, apexJob.Status);
	       	System.Assert(apexJob.NumberOfErrors == 0);
    	}
    }
    
    public static testMethod void testNoKnowledgeBaseReportsFound() {
    	User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
    		TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
	    	batchUtility = new KnowledgeBaseReportCleanupBatchUtility(KbArticleConstants.PublicationStatus.values(), TestCourseArticleHelper.getCourseArticleLanguageList());
	    	List<KnowledgeBaseReporting__c> kbReportList = TestCourseArticleHelper.createKnowledgeBaseReporting(defaultKbReportSize);
	    	TestCourseArticleHelper.createCourseArticleLink(kbReportList);
	    	
	        for (CourseArticle__ka courseArticle : [SELECT Id FROM CourseArticle__ka]) {
	        	KbManagement.PublishingService.deleteDraftArticle(courseArticle.Id);
	        }
	        
	        Test.startTest();
			ID BatchProcessId = Database.executeBatch(batchUtility);
	        Test.stopTest();
	       	AsyncApexJob apexJob = [SELECT NumberOfErrors, Status FROM AsyncApexJob WHERE Id = :BatchProcessId];
	       	System.AssertEquals(apexJobStatusCompleted, apexJob.Status);
	       	System.Assert(apexJob.NumberOfErrors == 0);
	        
	       	kbReportList = [SELECT Id FROM KnowledgeBaseReporting__c];
	        System.AssertEquals(0, kbReportList.size());
    	}
    }
}