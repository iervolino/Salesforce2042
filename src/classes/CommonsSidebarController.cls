public class CommonsSidebarController{
    
    public Integer remainingAnnouncements { get; set; }
    public Integer remainingQuickTips { get; set; }
    
    private Integer NUMBER_OF_ANNOUNCEMENTS_ON_SIDEBAR = 3;
    private Integer NUMBER_OF_QUICK_TIPS_ON_SIDEBAR = 3;
    
    public String groupId { get; set; }
    public String courseCode { get; set; }
    
    public CommonsSidebarController() {
        String groupIdParam = Apexpages.currentPage().getParameters().get('groupId');
        String courseCode = Apexpages.currentPage().getParameters().get('code');
        if(groupIdParam != null) {
            groupId = groupIdParam;
        }
        else {
            groupIdFromCourseCode();
        }
    }
    
    private void groupIdFromCourseCode() {
        Map<String, String> groupMap = CommonsChatterUtil.getUserGroupMap();
        courseCode = Apexpages.currentPage().getParameters().get('code');
        if(groupMap.size() != 0 && new Set<String>(groupMap.values()).contains(courseCode)) {
            for(String commonsGroupId : groupMap.keySet()) { //Set the group to the course param we received from Study Plan
                if(groupMap.get(commonsGroupId).equals(courseCode)) {
                    groupId = commonsGroupId;
                }
            }
        }
        else {
            List<WGUCourse__c> courseList = [SELECT Id FROM WGUCourse__c WHERE bannercode__c = :courseCode];
            if(courseList.isEmpty()) {
                return;
            }
            String courseId = courseList.get(0).Id;
            List<CommunityAccessControl__c> groupAssignmentList = [SELECT GroupId__c FROM CommunityAccessControl__c WHERE WGUCourse__c = :courseId AND RecordType.Name = 'Group Assignment' LIMIT 1];
            if(groupAssignmentList.isEmpty()) {
                return;
            }
            groupId = groupAssignmentList.get(0).GroupId__c;
        }
    }
    
    public List<CommunityAccessControl__c> getCourseCommunityAnnouncementWithLimit() {
        if(groupId == null) {
            remainingAnnouncements = 0;
            return null;
        }
        
        List<CommunityAccessControl__c> cacList = getCacListByType('Announcement');
        List<CommunityAccessControl__c> trimmedList = trimList(cacList, NUMBER_OF_ANNOUNCEMENTS_ON_SIDEBAR);
        remainingAnnouncements = cacList.size() - trimmedList.size();
        return trimmedList;
    }

    public List<CommunityAccessControl__c> getCourseCommunityAnnouncement() {
        if(groupId == null) {
            return null;
        }
        return getCacListByType('Announcement');
    }
    
    private List<CommunityAccessControl__c> trimList(List<CommunityAccessControl__c> cacList, Integer intLimit) {
        if(intLimit >= cacList.size()) {
            return cacList;
        }
        List<CommunityAccessControl__c> tempList = new List<CommunityAccessControl__c>();
        for(Integer i = 0; i < intLimit; i++) {
            tempList.add(cacList.get(i));
        }
        return tempList;
    }
    
    public List<CommunityAccessControl__c> getCourseCommunityQuickTipWithLimit() {
        if(groupId == null) {
            remainingQuickTips = 0;
            return null;
        }
        
        List<CommunityAccessControl__c> cacList = getCacListByType('Quick Tip');
        List<CommunityAccessControl__c> trimmedList = trimList(cacList, NUMBER_OF_QUICK_TIPS_ON_SIDEBAR);
        remainingQuickTips = cacList.size() - trimmedList.size();
        return trimmedList;
    }
    
    public List<CommunityAccessControl__c> getCourseCommunityQuickTip() {
        if(groupId == null) {
            return null;
        }
        return getCacListByType('Quick Tip');
    }

    private List<CommunityAccessControl__c> getCacListByType(String type) {
        return [SELECT MyResponse__c,
                       CreatedDate
                  FROM CommunityAccessControl__c 
                 WHERE AdministrationType__c = :type
                   AND GroupId__c = :groupid
                   AND RecordType.Name = 'Community Administration'
                   AND AnnouncementStatus__c = 'Active'
                 ORDER BY CreatedDate DESC];
    }

    public void markAnnouncementsAsViewed() {
        List<CommunityAccessControl__c> cacList = [SELECT Id, ViewedByStudent__c
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :UserInfo.getUserId() 
                                                      AND RecordType.Name = 'Course Announcement' 
                                                      AND ViewedByStudent__c = false
                                                      AND AnnouncementRecord__r.GroupId__c = :groupId
                                                      AND AnnouncementRecord__r.AnnouncementStatus__c = 'Active'
                                                      AND AnnouncementRecord__r.AdministrationType__c = 'Announcement'];
        for(CommunityAccessControl__c cac : cacList) {
            cac.ViewedByStudent__c = true;
        }
        update cacList;
    }

    public Integer getUnviewedAnnouncementCount() {
        return [SELECT COUNT() 
                  FROM CommunityAccessControl__c 
                 WHERE StudentUser__c = :UserInfo.getUserId() 
                   AND RecordType.Name = 'Course Announcement' 
                   AND ViewedByStudent__c = false
                   AND AnnouncementRecord__r.GroupId__c = :groupId
                   AND AnnouncementRecord__r.AnnouncementStatus__c = 'Active'
                   AND AnnouncementRecord__r.AdministrationType__c = 'Announcement'];
    }
    
}