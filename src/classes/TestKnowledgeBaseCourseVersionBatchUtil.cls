/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestKnowledgeBaseCourseVersionBatchUtil {
	public static testMethod void test() {
		List<KnowledgeBaseReporting__c> kbReports = TestCourseArticleHelper.createKnowledgeBaseReporting(3);
		List<CourseArticle__kav> courseArticles = TestCourseArticleHelper.createCourseArticleLink(kbReports);
		List<WGUCourseVersion__c> courseVersions = TestCourseArticleHelper.createCourseVersions(3, 'TestCourse');
		List<ArticleCourseVersionLink__c> articleCourseVersionLinks = new List<ArticleCourseVersionLink__c>();
		for (integer i = 0; i < 2; i++) {
			ArticleCourseVersionLink__c link = new ArticleCourseVersionLink__c();
			link.WGUCourseVersion__c = courseVersions.get(i).Id;
			link.KnowledgeArticleVersionId__c = courseArticles.get(i).Id;
			articleCourseVersionLinks.add(link);
		}
		upsert articleCourseVersionLinks;
		
		List<KnowledgeBaseWguCourseVersionLink__c> kbCourseVersionLinks = [SELECT Id FROM KnowledgeBaseWguCourseVersionLink__c];
		System.assertEquals(0, kbCourseVersionLinks.size());
		
		Test.startTest();
		KnowledgeBaseCourseVersionBatchUtility kbBatch = new KnowledgeBaseCourseVersionBatchUtility();
		Database.executeBatch(kbBatch);
		Test.stopTest();
		
		kbCourseVersionLinks = [SELECT Id FROM KnowledgeBaseWguCourseVersionLink__c];
		System.assertEquals(articleCourseVersionLinks.size(), kbCourseVersionLinks.size());
	}
}