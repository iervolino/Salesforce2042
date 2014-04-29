/*
*Author John Chan
*Slalom
*@4/24/13 Add new mapping fields to support new reporting fields and data migration from course articles.  New function to remove the latest version from prior reporting records.
*/
public with sharing class KnowledgeBaseReportingUtility {
	public static KnowledgeBaseReporting__c createKbReportByArticle(CourseArticle__kav courseArticle) {
		KnowledgeBaseReporting__c kbReport = new KnowledgeBaseReporting__c();
		kbReport.ArticleCreatedBy__c =  courseArticle.CreatedById;
		kbReport.ArticleCreatedDate__c = courseArticle.CreatedDate;
		kbReport.ArticleLastModifiedBy__c = courseArticle.LastModifiedById;
		kbReport.ArchiveDate__c = courseArticle.ArchivedDate;
		kbReport.KnowledgeArticleId__c = courseArticle.KnowledgeArticleId;
		kbReport.ArticleType__c = courseArticle.ArticleType__c;
		kbReport.KnowledgeArticleVersionId__c = courseArticle.Id;
		kbReport.CreatedDate__c = courseArticle.CreatedDate;
		kbReport.PublishDate__c = courseArticle.LastPublishedDate;
		kbReport.PublishStatus__c = courseArticle.PublishStatus;
		kbReport.Stage__c = courseArticle.Stage__c;
		kbReport.Summary__c = courseArticle.Summary;
		kbReport.Title__c = courseArticle.Title;
		kbReport.UrlName__c = courseArticle.UrlName;
		kbReport.IsVisibleInCsp__c = courseArticle.IsVisibleInCsp;
		kbReport.IsVisibleInApp__c = courseArticle.IsVisibleInApp;
		kbReport.IsVisibleInPrm__c = courseArticle.IsVisibleInPrm;
		kbReport.IsVisibleInPkb__c = courseArticle.IsVisibleInPkb;
		kbReport.IsLatestVersion__c = courseArticle.IsLatestVersion;
		kbReport.VersionNumber__c = courseArticle.VersionNumber;
		return kbReport;
	}
	
	public static String getCourseVersionsStringByRelatedList(List<KnowledgeBaseWguCourseVersionLink__c> courseAssignmentList) {
		String courseVersionString = '';
		for (KnowledgeBaseWguCourseVersionLink__c courseAssignment: courseAssignmentList) {
			if (String.isEmpty(courseVersionString)) {
				courseVersionString = courseAssignment.WGUCourseVersion__c;
			} else {
				courseVersionString += (',' + courseAssignment.WGUCourseVersion__c);
			}
		}
		return courseVersionString;
	}
	
	public static void removeKbArticlesFromLatestVersion(CourseArticle__kav courseArticle) {
		List<KnowledgeBaseReporting__c> kbReports = [SELECT IsLatestVersion__c FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleId__c = :courseArticle.KnowledgeArticleId 
				AND IsLatestVersion__c = true];
		if (kbReports != null && kbReports.size() > 0) {
			for (KnowledgeBaseReporting__c kbReport : kbReports) {
				kbReport.IsLatestVersion__c = false;
			}
			update kbReports;
		}
	}
}