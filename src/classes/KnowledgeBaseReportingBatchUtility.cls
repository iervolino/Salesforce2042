/*
*Author John Chan
*Slalom
*Currently only supporting course articles so we are not pulling other articles in that we might not want in the reporting table
*/
global with sharing class KnowledgeBaseReportingBatchUtility implements Database.Batchable<CourseArticle__kav>, Database.Stateful {
	public String publishStatus { get; private set; }
	public String language { get; private set; }
	global integer totalRecordCount { get; private set; }
	public Map<String, String> kbReportPropertyVoteCountMap { get; private set; }
	public Map<String, String> kbReportPropertyViewScoreMap { get; private set; }
	
	public KnowledgeBaseReportingBatchUtility(String publishStatus, string language) {
		this.publishStatus = publishStatus;
		this.language = language;
		this.totalRecordCount = 0;
	}
	
	global Iterable<CourseArticle__kav> start(Database.BatchableContext batchContext) {
		return CourseArticleDAO.getForKnowledgeBaseReportBatch(publishStatus, language);
	}
	
	global void execute(Database.BatchableContext batchConext, List<CourseArticle__kav> courseArticles) {
		//TODO: This might be an issue in the future should put a check in here for heap size
		List<KnowledgeBaseReporting__c> kbReportUpdates = new List<KnowledgeBaseReporting__c>();
        Map<Id, KnowledgeBaseReporting__c> kbLatestVersionMap = new Map<Id, KnowledgeBaseReporting__c>();
        List<ID> kbIDs = new List<ID>();
		for (CourseArticle__kav courseArticle : courseArticles) {
			KnowledgeBaseReporting__c kbReport = KnowledgeBaseReportingUtility.createKbReportByArticle(courseArticle);
			kbReportUpdates.add(kbReport);
            kbLatestVersionMap.put(kbReport.KnowledgeArticleId__c, kbReport);
            kbIds.add(kbReport.KnowledgeArticleId__c);
		}
        
		//TODO: Add vote stat to reporting table        
		for (KnowledgeArticleVoteStat voteStat : [SELECT Channel, NormalizedScore, ParentId FROM KnowledgeArticleVoteStat WHERE ParentId IN :kbLatestVersionMap.keySet()]) {
			
            if (kbLatestVersionMap.containsKey(voteStat.ParentId)) {
				if (voteStat.Channel == KbArticleConstants.Channel.AllChannels.name()) {  
					kbLatestVersionMap.get(voteStat.ParentId).VoteCountAll__c = voteStat.NormalizedScore;
				} else if (voteStat.Channel == KbArticleConstants.Channel.App.name()) {
					kbLatestVersionMap.get(voteStat.ParentId).VoteCountApplication__c = voteStat.NormalizedScore;
				} else if (voteStat.Channel == KbArticleConstants.Channel.Pkb.name()) {
					kbLatestVersionMap.get(voteStat.ParentId).VoteCountPublic__c = voteStat.NormalizedScore;
				} else if (voteStat.Channel == KbArticleConstants.Channel.Csp.name()) {
					kbLatestVersionMap.get(voteStat.ParentId).VoteCountCustomer__c = voteStat.NormalizedScore;
				} else if (voteStat.Channel == KbArticleConstants.Channel.Prm.name()) {
					kbLatestVersionMap.get(voteStat.ParentId).VoteCountPartner__c = voteStat.NormalizedScore;
				}
			}
        }
            
		for (KnowledgeArticleViewStat viewStat : [SELECT Channel, NormalizedScore, ParentId, ViewCount FROM KnowledgeArticleViewStat WHERE ParentId IN :kbLatestVersionMap.keySet()]) {
				if (kbLatestVersionMap.containsKey(viewStat.ParentId)) {
					if (viewStat.Channel == KbArticleConstants.Channel.AllChannels.name()) {
						kbLatestVersionMap.get(viewStat.ParentId).ViewCountAll__c = viewStat.ViewCount;
						kbLatestVersionMap.get(viewStat.ParentId).ViewScoreAll__c = viewStat.NormalizedScore;
					}
					if (viewStat.Channel == KbArticleConstants.Channel.App.name()) {
						kbLatestVersionMap.get(viewStat.ParentId).ViewCountApplication__c = viewStat.ViewCount;
						kbLatestVersionMap.get(viewStat.ParentId).ViewScoreApplication__c = viewStat.NormalizedScore;
					}
					if (viewStat.Channel == KbArticleConstants.Channel.Pkb.name()) {
						kbLatestVersionMap.get(viewStat.ParentId).ViewCountPublic__c = viewStat.ViewCount;
						kbLatestVersionMap.get(viewStat.ParentId).ViewScorePublic__c = viewStat.NormalizedScore;
					}
					if (viewStat.Channel == KbArticleConstants.Channel.Csp.name()) {
						kbLatestVersionMap.get(viewStat.ParentId).ViewCountCustomer__c = viewStat.ViewCount;
						kbLatestVersionMap.get(viewStat.ParentId).ViewScoreCustomer__c = viewStat.NormalizedScore;
					}
					if (viewStat.Channel == KbArticleConstants.Channel.Prm.name()) {
						kbLatestVersionMap.get(viewStat.ParentId).ViewCountPartner__c = viewStat.ViewCount;
						kbLatestVersionMap.get(viewStat.ParentId).ViewScorePartner__c = viewStat.NormalizedScore;
					}
					
				}
		}
		
		upsert kbReportUpdates KnowledgeArticleVersionId__c;
		totalRecordCount = totalRecordCount + kbReportUPdates.size();
	}
	
	global void finish(Database.BatchableContext batchContext) {
		if (Runtime__c.getValues(reportBatchContactEmailsName) != null && String.isNotEmpty(Runtime__c.getValues(reportBatchContactEmailsName).Value__c)) {
			sendBatchCompletedEmail(batchContext, Runtime__c.getValues(reportBatchContactEmailsName).Value__c.split(';'), 'KnowledgeBaseReportingBatchUtility', 
				'Records Processed: ' + totalRecordCount + '\nPublishStatus: ' + publishStatus);
		}
	}
	
	public static final String reportBatchContactEmailsName = 'KbReportBatchContactEmails';
	public static final String environmentName = 'environment';
	public static void sendBatchCompletedEmail(Database.BatchableContext batchContext, String[] emails, String jobName, String additionalMsg) {
		final String apexJobStatusCompleted = 'Completed';
		AsyncApexJob apexJob = [SELECT CompletedDate, TotalJobItems, JobItemsProcessed, NumberOfErrors, Status, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchContext.getJobId()];
		
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(emails);
		email.setSubject(jobName + ': Batch Job ' + (apexJob.NumberOfErrors > 0 ? 'ERROR' : apexJob.Status)); 
		String message =  'Environment Info: ' + (Runtime__c.getValues(environmentName) == null ? UserInfo.getOrganizationId() : Runtime__c.getValues(environmentName).Value__c) + 
			+ '\nCompleted Date: ' + apexjob.CompletedDate + '\nTotal Batches: ' + apexJob.TotalJobItems + '\nBatches Processed: ' + apexJob.JobItemsProcessed;
		if (String.isNotEmpty(additionalMsg)) {
			message += '\n' + additionalMsg;
		}
		if (apexJob.NumberOfErrors > 0 || apexJob.Status != apexJobStatusCompleted) {
			message += '\nNumber Of Errors: ' + apexJob.NumberOfErrors + '\nPartial Error Description: ' + apexJob.ExtendedStatus;
		}
		email.setPlainTextBody(message);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
	}
}