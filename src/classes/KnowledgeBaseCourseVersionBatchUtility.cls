/*
*Author John Chan
*Slalom
Migrate from old ArticleCourseVersionLink__c to new junction object.  This should only be need to ran once or twice to migrate the data over.
*/
global with sharing class KnowledgeBaseCourseVersionBatchUtility implements Database.Batchable<sObject>{
	private final String query = 'SELECT KnowledgeArticleVersionId__c, WGUCourseVersion__c FROM ArticleCourseVersionLink__c';
	
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		Map<String, Id> knowledgeBaseReportMap = new Map<String, Id>();
		for (KnowledgeBaseReporting__c kbReport : [SELECT Id, KnowledgeArticleVersionId__c FROM KnowledgeBaseReporting__c]) {
			knowledgeBaseReportMap.put(kbReport.KnowledgeArticleVersionId__c, kbReport.Id);
		}
		
		Set<String> knoweldgeBaseCourseVersionLinkIds = new Set<String>();
		for (KnowledgeBaseWguCourseVersionLink__c kbCourseVersionLink : [SELECT KnowledgeArticleVersionId__c, WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c]) {
			knoweldgeBaseCourseVersionLinkIds.add(kbCourseVersionLink.KnowledgeArticleVersionId__c + kbCourseVersionLink.WGUCourseVersion__c);
		}
		
		List<KnowledgeBaseWguCourseVersionLink__c> knowledgeBaseCourseVersionLinkUpdates = new List<KnowledgeBaseWguCourseVersionLink__c>();
		for (ArticleCourseVersionLink__c articleCourseLink : ((List<ArticleCourseVersionLink__c>)scope)) {
			//Check to make sure neither Id's are empty and that it does not exist already in the new junction object
			if ((string.isNotEmpty(articleCourseLink.KnowledgeArticleVersionId__c) && articleCourseLink.WGUCourseVersion__c != null) && (knoweldgeBaseCourseVersionLinkIds.size() == 0 
					|| !knoweldgeBaseCourseVersionLinkIds.contains(articleCourseLink.KnowledgeArticleVersionId__c + articleCourseLink.WGUCourseVersion__c))) {
				if (knowledgeBaseReportMap.get(articleCourseLink.KnowledgeArticleVersionId__c) != null) {
					KnowledgeBaseWguCourseVersionLink__c knowledgeBaseCourseVersion = new KnowledgeBaseWguCourseVersionLink__c();
					knowledgeBaseCourseVersion.KnowledgeArticleVersionId__c = articleCourseLink.KnowledgeArticleVersionId__c;
					knowledgeBaseCourseVersion.WGUCourseVersion__c = articleCourseLink.WGUCourseVersion__c;
					knowledgeBaseCourseVersion.KnowledgeBaseReporting__c = knowledgeBaseReportMap.get(articleCourseLink.KnowledgeArticleVersionId__c);
					knowledgeBaseCourseVersionLinkUpdates.add(knowledgeBaseCourseVersion);
				} else {
					system.debug('cannot find knoweldgeArticleVersionId in reporting table for Id: ' + articleCourseLink.KnowledgeArticleVersionId__c);
				}
			}
		}
		
		insert knowledgeBaseCourseVersionLinkUpdates;
	}

	global void finish(Database.BatchableContext BC){
   	}
}