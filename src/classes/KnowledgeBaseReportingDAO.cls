/*
*Author John Chan
*Slalom
*/
public with sharing class KnowledgeBaseReportingDAO {
	public static void updateCourseVersionLink(List<KnowledgeBaseWguCourseVersionLink__c> kbCourseVersionLinks, 
			String knowledgeArticleVersionId, Id kbReportId, Set<String> courseVersionIds) {
		//Add
		Map<Id, KnowledgeBaseWguCourseVersionLink__c> existingCourseVersions = new Map<Id, KnowledgeBaseWguCourseVersionLink__c>();
		if (kbCourseVersionLinks != null) {
			for (KnowledgeBaseWguCourseVersionLink__c courseVersionLink : kbCourseVersionLinks) {
				existingCourseVersions.put(courseVersionLink.WGUCourseVersion__c, courseVersionLink);
			}
		}
		
		List<KnowledgeBaseWguCourseVersionLink__c> newKbCourseVersionLinks = null;
		for (String courseVersionId : courseVersionIds) {
			if (!existingCourseVersions.containsKey(courseVersionId)) {
				if (newKbCourseVersionLinks == null) {
					newKbCourseVersionLinks = new List<KnowledgeBaseWguCourseVersionLink__c>();
				}
				newKbCourseVersionLinks.add(new KnowledgeBaseWguCourseVersionLink__c(KnowledgeArticleVersionId__c = knowledgeArticleVersionId, KnowledgeBaseReporting__c = kbReportId, 
					WGUCourseVersion__c = courseVersionId));
			}
		}
		system.debug(newKbCourseVersionLinks);
		if (newKbCourseVersionLinks != null) {
			insert newKbCourseVersionLinks;
		}
		
		//Delete
		List<KnowledgeBaseWguCourseVersionLink__c> deleteCourseVersionLinks = null;
		for (Id courseVersionId : existingCourseVersions.keySet()) {
			if (!courseVersionIds.contains(courseVersionId)) {
				if (deleteCourseVersionLinks == null) {
					deleteCourseVersionLinks = new List<KnowledgeBaseWguCourseVersionLink__c>();
				}
				deleteCourseVersionLinks.add(existingCourseVersions.get(courseVersionId));
			}
		}
		if (deleteCourseVersionLinks != null) {
			delete deleteCourseVersionLinks;
		}
	}
}