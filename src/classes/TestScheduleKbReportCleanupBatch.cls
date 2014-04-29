/*
*Author John Chan
*Slalom
*/
@isTest
private with sharing class TestScheduleKbReportCleanupBatch {
	public static testMethod void testSchedule() {
		User systemAdmin = TestCourseArticleHelper.getTestUser('testadmin', 'System Administrator', true);
    	System.runAs(systemAdmin) {
    		TestCourseArticleHelper.setGlobalSettingKbBatchEmail();
			Test.startTest();
			Id jobId = System.schedule('ScheduleKbReportCleanupBatch', ScheduleKbReportCleanupBatch.CRON_EXP, new ScheduleKbReportCleanupBatch());

      		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

		  	System.assertEquals(ScheduleKbReportCleanupBatch.CRON_EXP, ct.CronExpression);
      		System.assertEquals(0, ct.TimesTriggered);
			Test.stopTest();
    	}
	}
}