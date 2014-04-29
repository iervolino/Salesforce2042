/*
*Author John Chan
*Slalom
*/
global with sharing class KnowledgeBaseReportCleanupBatchUtility implements Database.Batchable<KnowledgeBaseReporting__c>, Database.Stateful {
	public KbArticleConstants.PublicationStatus[] publishStatus { get; private set; }
	public String[] languages { get; private set; }
	global integer deletedRecordCount { get; private set; }
	
	public KnowledgeBaseReportCleanupBatchUtility(KbArticleConstants.PublicationStatus[] publishStatus, String[] languages) {
		this.publishStatus = publishStatus;
		this.languages = languages;
		this.deletedRecordCount = 0;
	}
	
	global Iterable<KnowledgeBaseReporting__c> start(Database.BatchableContext batchContext) {
		//return CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(publishStatus, languages);
		return [SELECT KnowledgeArticleVersionId__c FROM KnowledgeBaseReporting__c];
	}
	
	global void execute(Database.BatchableContext batchConext, List<KnowledgeBaseReporting__c> kbReportList) {
		Map<Id, CourseArticle__kav> courseArticles = CourseArticleDAO.getForKnowledgeBaseReportCleanupBatch(publishStatus, languages);
		List<KnowledgeBaseReporting__c> kbReportCleanup = new List<KnowledgeBaseReporting__c>();
		for (KnowledgeBaseReporting__c kbReportBase : kbReportList) {
			if (string.isNotEmpty(kbReportBase.KnowledgeArticleVersionId__c) && !courseArticles.containsKey(((Id)kbReportBase.KnowledgeArticleVersionId__c))) {
				kbReportCleanup.add(kbReportBase);
			}
		}
		
		if (kbReportCleanup.size() > 0) {
			delete kbReportCleanup;
			deletedRecordCount = deletedRecordCount + kbReportCleanup.size();
		}
	}
	
	global void finish(Database.BatchableContext batchContext) {
		if (Runtime__c.getValues(KnowledgeBaseReportingBatchUtility.reportBatchContactEmailsName) != null && 
			String.isNotEmpty(Runtime__c.getValues(KnowledgeBaseReportingBatchUtility.reportBatchContactEmailsName).Value__c)) {
			KnowledgeBaseReportingBatchUtility.sendBatchCompletedEmail(batchContext, Runtime__c.getValues(KnowledgeBaseReportingBatchUtility.reportBatchContactEmailsName).Value__c.split(';'),
					'KnowledgeBaseReportCleanupBatchUtility', 'Deleted Records: ' + deletedRecordCount);
		}
	}
}