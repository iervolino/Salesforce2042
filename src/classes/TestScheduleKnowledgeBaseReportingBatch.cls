/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestScheduleKnowledgeBaseReportingBatch {
	public static testMethod void testSchedule() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
    		TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
			
			Test.startTest();
			Id jobId = System.schedule('ScheduleKnowledgeBaseReportingBatchUtility', ScheduleKnowledgeBaseReportingBatch.CRON_EXP, new ScheduleKnowledgeBaseReportingBatch());

      		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

		  	System.assertEquals(ScheduleKnowledgeBaseReportingBatch.CRON_EXP, ct.CronExpression);
      		System.assertEquals(0, ct.TimesTriggered);
			Test.stopTest();
    	}
	}
}