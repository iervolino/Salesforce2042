/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestKnowledgeBaseReportingBatchUtility {
    public static testMethod void testInsert() {
        //Insert
        User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
        System.runAs(systemAdmin) {
            TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
            String language = Schema.SObjectType.CourseArticle__kav.fields.Language.getPickListValues()[0].getValue();
            List<CourseArticle__kav> courseArticles = TestCourseArticleHelper.createCourseArticle(2);
            List<KnowledgeBaseReporting__c> kbReports = [SELECT Id FROM KnowledgeBaseReporting__c];
            System.AssertEquals(0, kbReports.size());
            
            Test.startTest();
            KnowledgeBaseReportingBatchUtility kbReportBatch = new KnowledgeBaseReportingBatchUtility(KbArticleConstants.PublicationStatus.Draft.name(), language);
            Database.executeBatch(kbReportBatch);
            Test.stopTest();
            
            kbReports = [SELECT Id FROM KnowledgeBaseReporting__c];
            System.AssertEquals(courseArticles.size(), kbReports.size());
        }
    }
    
    public static testMethod void testUpdate() {
        User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
        System.runAs(systemAdmin) {
            //Update
            TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
            String language = Schema.SObjectType.CourseArticle__kav.fields.Language.getPickListValues()[0].getValue();
            TestCourseArticleHelper.createCourseArticle(2);
            List<CourseArticle__kav> courseArticles = CourseArticleDAO.getForKnowledgeBaseReportBatch(KbArticleConstants.PublicationStatus.Draft.name(), language);
            List<KnowledgeBaseReporting__c> kbReportUpdates = new List<KnowledgeBaseReporting__c>();
            for (CourseArticle__kav courseArticle : courseArticles) {
                kbReportUpdates.add(KnowledgeBaseReportingUtility.createKbReportByArticle(courseArticle));
            }
            upsert kbReportUpdates;
            CourseArticle__kav updatedCourseArticle = TestCourseArticleHelper.getCourseArticleById(courseArticles[0].Id);
            KnowledgeBaseReporting__c kbReport = TestCourseArticleHelper.getKbReportByCourseArticleVersionId(courseArticles[0].Id);
            System.assertEquals(updatedCourseArticle.Summary, kbReport.Summary__c);
            
            final String SummaryTestText = 'Unit Test Summary'; 
            courseArticles[0].Summary = SummaryTestText;
            upsert courseArticles;
            
            updatedCourseArticle = TestCourseArticleHelper.getCourseArticleById(courseArticles[0].Id);
            kbReport = TestCourseArticleHelper.getKbReportByCourseArticleVersionId(courseArticles[0].Id);
            System.assertNotEquals(updatedCourseArticle.Summary, kbReport.Summary__c);
            
            Test.startTest();
            KnowledgeBaseReportingBatchUtility kbReportBatch = new KnowledgeBaseReportingBatchUtility(KbArticleConstants.PublicationStatus.Draft.name(), language);
            Database.executeBatch(kbReportBatch);
            Test.stopTest();
            
            kbReport = TestCourseArticleHelper.getKbReportByCourseArticleVersionId(courseArticles[0].Id);
            System.assertEquals(updatedCourseArticle.Summary, kbReport.Summary__c);
        }
    }
}