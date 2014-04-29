public class CourseCommunitiesGroupAnnouncementsUtil {
	
	public static Map<String, List<CommunityAccessControl__c>> getGroupAnnouncementsMap(Set<String> groupIdSet) {
        List<CommunityAccessControl__c> cacList = [SELECT Id, GroupId__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE GroupId__c IN :groupIdSet 
                                                      AND AdministrationType__c = 'Announcement'
                                                      AND RecordType.Name = 'Community Administration'
                                                      AND AnnouncementStatus__c = 'Active'
                                                    ORDER BY GroupId__c];
        Map<String, List<CommunityAccessControl__c>> announcementMap = new Map<String, List<CommunityAccessControl__c>>();
        String currentGroupId = null;
        for(CommunityAccessControl__c cac : cacList) {
            if(currentGroupId == null || currentGroupId != cac.GroupId__c) {
                announcementMap.put(cac.GroupId__c, new List<CommunityAccessControl__c>());
            }
            announcementMap.get(cac.GroupId__c).add(cac);
        }
        return announcementMap;
    }

    public static void addAnnouncementsForUser(String userId, String courseAnnouncementRecordTypeId,
        List<CommunityAccessControl__c> announcementList, List<CommunityAccessControl__c> insertCacList) 
    {
        for(CommunityAccessControl__c announcement : announcementList) {
            insertCacList.add(createAnnouncementViewRecord(userId, courseAnnouncementRecordTypeId, announcement.id));
        }
    }

    public static void addAnnouncementsForNewUsersGroups(List<CommunityAccessControl__c> groupPermissionCacList) {
        Set<String> groupIdSet = new Set<String>();
        for(CommunityAccessControl__c cac : groupPermissionCacList) {
            groupIdSet.add(cac.GroupId__c);
        }

        String courseAnnoucementRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CommunityAccessControl__c' AND Name = 'Course Announcement'].id;
        Map<String, List<CommunityAccessControl__c>> groupAnnoucementsMap = getGroupAnnouncementsMap(groupIdSet);
        List<CommunityAccessControl__c> recordsToAdd = new List<CommunityAccessControl__c>();
        for(CommunityAccessControl__c cac : groupPermissionCacList) {
            if(!groupAnnoucementsMap.containsKey(cac.GroupId__c)) {
                continue;
            }
            recordsToAdd.addAll(createAnnouncementViewRecords(cac.StudentUser__c, 
                    courseAnnoucementRecordTypeId, groupAnnoucementsMap.get(cac.GroupId__c)));
        }
        groupPermissionCacList.addAll(recordsToAdd);
    }

    private static List<CommunityAccessControl__c> createAnnouncementViewRecords(String userId, String courseAnnoucementRecordTypeId,
        List<CommunityAccessControl__c> annoucementList) 
    {
    	List<CommunityAccessControl__c> resultList = new List<CommunityAccessControl__c>();
        for(CommunityAccessControl__c annoucement : annoucementList) {
            resultList.add(createAnnouncementViewRecord(userId, courseAnnoucementRecordTypeId, annoucement.id));
        }
        return resultList;
    }

    public static CommunityAccessControl__c createAnnouncementViewRecord(String userId, String courseAnnoucementRecordTypeId, String annoucementId) {
    	CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.StudentUser__c = userId;
        cac.ViewedByStudent__c = false;
        cac.RecordTypeId = courseAnnoucementRecordTypeId;
        cac.AnnouncementRecord__c = annoucementId;
        return cac;
    }

}