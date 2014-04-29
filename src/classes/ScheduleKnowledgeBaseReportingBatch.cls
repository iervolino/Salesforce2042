/*
*Author John Chan
*Slalom
*Scheduling class for KnowledgeBaseReportingBatchUtility
*/
global with sharing class ScheduleKnowledgeBaseReportingBatch implements Schedulable {
	public static final String CRON_EXP = '0 0 0 ? * MON-SUN';
	
	global void execute(SchedulableContext scheduleContext) {
		for (Schema.PicklistEntry language : Schema.SObjectType.CourseArticle__kav.fields.Language.getPickListValues()) {
			for (Schema.PicklistEntry publishStatus : Schema.SObjectType.CourseArticle__kav.fields.PublishStatus.getPickListValues()) {
				KnowledgeBaseReportingBatchUtility kbReportBatch = new KnowledgeBaseReportingBatchUtility(publishStatus.getValue(), language.getValue());
				Database.executeBatch(kbReportBatch);
			}
		}
	}
}