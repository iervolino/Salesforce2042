/*
*Author John Chan
*Slalom
*Scheduling class for KnowledgeBaseReportCleanupBatchUtility
*/
global with sharing class ScheduleKbReportCleanupBatch implements Schedulable {
	public static final String CRON_EXP = '0 0 1 ? * MON-SUN';
	
	global void execute(SchedulableContext scheduleContext) {
		String[] languages = new String[] { };
		for (Schema.PicklistEntry language : Schema.SObjectType.CourseArticle__kav.fields.Language.getPickListValues()) {
			languages.add(language.getValue());
		}
		KnowledgeBaseReportCleanupBatchUtility kbReportCleanupBatch = new KnowledgeBaseReportCleanupBatchUtility(KbArticleConstants.PublicationStatus.values(), languages);
		Database.executeBatch(kbReportCleanupBatch);
	}
}