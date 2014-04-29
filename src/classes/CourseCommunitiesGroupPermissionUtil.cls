public class CourseCommunitiesGroupPermissionUtil {
    
    public Map<String, Contact> getStudentContactMap(List<StudentAcademicCourse__c> sacList) {
        Set<String> contactIdSet = new Set<String>();
        for(StudentAcademicCourse__c sac : sacList) {
            if(sac.StudentContact__c != null) {
                contactIdSet.add(sac.StudentContact__c);
            }
        }
        return new Map<String, Contact>([SELECT Id, CurrentTerm__c FROM Contact WHERE Id IN :contactIdSet]);
    }
    
    public void updateCourseGroupPermissions(List<StudentAcademicCourse__c> studentCourseList, String notificationFrequency, String communityStatus) {
        if(studentCourseList == null || studentCourseList.isEmpty()) {
            return;
        }
        
        Set<String> studentContactIdSet = new Set<String>();
        for(StudentAcademicCourse__c studentCourse : studentCourseList) {
            studentContactIdSet.add(studentCourse.StudentContact__c);
        }
        
        Map<String, String> userIdMap = createUserIdMap(studentContactIdSet);
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        Map<String, Map<String, CommunityAccessControl__c>> cacUserMap = createCommunityAccessControlUserMap(userIdMap.values());
        Map<String, Map<String, CollaborationGroupMember>> cgmMap = createCollaborationGroupMemberMap(userIdMap.values(), networkId);
        
        processChanges(studentCourseList, userIdMap, cacUserMap, cgmMap, notificationFrequency, communityStatus, networkId);
    }
    
    private Map<String, String> createUserIdMap(Set<String> studentContactIdSet) {
        List<User> userList = ([SELECT Id, ContactId FROM User WHERE ContactId IN :studentContactIdSet]);
        Map<String, String> userIdMap = new Map<String, String>();
        for(User u : userList) {
            userIdMap.put(u.ContactId, u.Id);
        }
        return userIdMap;
    }
    
    private Map<String, Map<String, CommunityAccessControl__c>> createCommunityAccessControlUserMap(List<String> userIdList) {
        List<CommunityAccessControl__c> cacList = [SELECT Id, StudentUser__c, WGUCourse__r.bannercode__c, GroupId__c, CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :userIdList
                                                      AND RecordType.Name = 'Group Access' 
                                                    ORDER BY StudentUser__c];
        Map<String, Map<String, CommunityAccessControl__c>> cacUserMap = new Map<String, Map<String, CommunityAccessControl__c>>();
        String currentUserId = null;
        for(CommunityAccessControl__c cac : cacList) {
            if(currentUserId == null || !currentUserId.equals(cac.StudentUser__c)) {
                currentUserId = cac.StudentUser__c;
                cacUserMap.put(cac.StudentUser__c, new Map<String, CommunityAccessControl__c>());
            }
            cacUserMap.get(cac.StudentUser__c).put(cac.WGUCourse__r.bannercode__c, cac);
        }
        return cacUserMap;
    }
    
    private Map<String, Map<String, CollaborationGroupMember>> createCollaborationGroupMemberMap(List<String> userIdList, String networkId) {
        List<CollaborationGroupMember> cgmList = [SELECT Id, MemberId, CollaborationGroupId, NotificationFrequency
                                                    FROM CollaborationGroupMember 
                                                   WHERE MemberId IN :userIdList 
                                                     AND CollaborationGroup.NetworkId = :networkId 
                                                   ORDER BY MemberId];
        Map<String, Map<String, CollaborationGroupMember>> cgmMap = new Map<String, Map<String, CollaborationGroupMember>>();
        String currentMemberId = null;
        for(CollaborationGroupMember cgm : cgmList) {
            if(currentMemberId == null || !currentMemberId.equals(cgm.MemberId)) {
                currentMemberId = cgm.MemberId;
                cgmMap.put(cgm.MemberId, new Map<String, CollaborationGroupMember>());
            }
            cgmMap.get(cgm.MemberId).put(cgm.CollaborationGroupId, cgm);
        }
        return cgmMap;
    }
    
    private void processChanges(List<StudentAcademicCourse__c> studentCourseList, Map<String, String> userIdMap, 
                                Map<String, Map<String, CommunityAccessControl__c>> cacUserMap,
                                Map<String, Map<String, CollaborationGroupMember>> cgmMap,
                                String notificationFrequency, String communityStatus, String networkId) 
    {
        Map<String, Set<String>> missingUserCourseGroupMap = new Map<String, Set<String>>();
        List<CommunityAccessControl__c> cacUpdateList = new List<CommunityAccessControl__c>();
        List<CollaborationGroupMember> cgmUpdateList = new List<CollaborationGroupMember>();
        for(StudentAcademicCourse__c rec : studentCourseList) {
            if(!userIdMap.containsKey(rec.StudentContact__c)) 
            {
                continue;
            }
            
            String userId = userIdMap.get(rec.StudentContact__c);
            processUserCourse(userId, rec.CourseCode__c, cacUserMap, cgmMap, cacUpdateList, 
                                    cgmUpdateList, notificationFrequency, communityStatus, missingUserCourseGroupMap);
        }
        
        update cacUpdateList;
        update cgmUpdateList;
        if(!missingUserCourseGroupMap.isEmpty()) {
            createMissingUserCourseGroup(missingUserCourseGroupMap, notificationFrequency, communityStatus, networkId);
        }
    }
    
    private void processUserCourse(String userId, String courseCode, 
                                     Map<String, Map<String, CommunityAccessControl__c>> cacUserMap,
                                     Map<String, Map<String, CollaborationGroupMember>> cgmMap, 
                                     List<CommunityAccessControl__c> cacUpdateList,
                                     List<CollaborationGroupMember> cgmUpdateList,
                                     String notificationFrequency, String communityStatus, 
                                     Map<String, Set<String>> missingUserCourseGroupMap) 
    {
        if(!cacUserMap.containsKey(userId)) {
            addRecordToMissingUserCourseGroup(userId, courseCode, missingUserCourseGroupMap);
            return;
        } 
        Map<String, CommunityAccessControl__c> cacMap = cacUserMap.get(userId);
        if(!cacMap.containsKey(courseCode)) {
            addRecordToMissingUserCourseGroup(userId, courseCode, missingUserCourseGroupMap);
            return;
        }
        
        CommunityAccessControl__c cac = cacMap.get(courseCode);
        cac.CommunityStatus__c = communityStatus;
        cacUpdateList.add(cac);
        
        if(cgmMap.containsKey(userId)) {
            Map<String, CollaborationGroupMember> tempMap = cgmMap.get(userId);
            if(tempMap.containsKey(cac.GroupId__c)) {
                CollaborationGroupMember cgm = tempMap.get(cac.GroupId__c);
                if(cgm.NotificationFrequency != notificationFrequency) {
                    cgm.NotificationFrequency = notificationFrequency;
                    cgmUpdateList.add(cgm);
                }
            }
            else {
                addRecordToMissingUserCourseGroup(userId, courseCode, missingUserCourseGroupMap);
            }
        }
        else {
            addRecordToMissingUserCourseGroup(userId, courseCode, missingUserCourseGroupMap);
        }
    }
    
    private void addRecordToMissingUserCourseGroup(String userId, String courseCode, Map<String, Set<String>> missingUserCourseGroupMap) 
    {
        if(!missingUserCourseGroupMap.containsKey(userId)) {
            Set<String> tempList = new Set<String>();
            tempList.add(courseCode);
            missingUserCourseGroupMap.put(userId, tempList);
        }
        else {
            missingUserCourseGroupMap.get(userId).add(courseCode);
        }
    }
    
    private void createMissingUserCourseGroup(Map<String, Set<String>> missingUserCourseGroupMap, 
                                              String notificationFrequency, String communityStatus, String networkId) 
    {
        List<CommunityAccessControl__c> cacInsertList = new List<CommunityAccessControl__c>();
        List<CollaborationGroupMember> cgmInsertList = new List<CollaborationGroupMember>();
        
        Set<String> courseCodeSet = new Set<String>();
        for(String userId : missingUserCourseGroupMap.keySet()) {
            for(String courseCode : missingUserCourseGroupMap.get(userId)) {
                courseCodeSet.add(courseCode);
            }
        }
        Map<String, String> courseCodeToGroupIdMap = new Map<String, String>();
        Map<String, String> courseCodeToCourseIdMap = new Map<String, String>();
        getCourseCodeToGroupIdMap(courseCodeSet, courseCodeToGroupIdMap, courseCodeToCourseIdMap);
        if(courseCodeToGroupIdMap.isEmpty()) {
            return;
        }

        Set<String> groupIdSet = new Set<String>(courseCodeToGroupIdMap.values());
        Map<String, List<CommunityAccessControl__c>> groupAnnoucementsMap = CourseCommunitiesGroupAnnouncementsUtil.getGroupAnnouncementsMap(groupIdSet);

        String courseAnnoucementRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CommunityAccessControl__c' AND Name = 'Course Announcement'].id;
        String groupAccessRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access' AND sObjectType = 'CommunityAccessControl__c'].id;
        for(String userId : missingUserCourseGroupMap.keySet()) {
            for(String courseCode : missingUserCourseGroupMap.get(userId)) {
                if(!courseCodeToGroupIdMap.containsKey(courseCode)) {
                    continue;
                }
                
                String groupId = courseCodeToGroupIdMap.get(courseCode);
                CommunityAccessControl__c cac = new CommunityAccessControl__c();
                cac.CommunityStatus__c = communityStatus;
                cac.StudentUser__c = userId;
                cac.GroupId__c = groupId;
                cac.CommunityId__c = networkId;
                cac.RecordTypeId = groupAccessRecordTypeId;
                cac.WGUCourse__c = courseCodeToCourseIdMap.get(courseCode);
                cacInsertList.add(cac);
                
                CollaborationGroupMember groupMember = new CollaborationGroupMember();
                groupMember.CollaborationGroupId = groupId;
                groupMember.MemberId = userId;
                groupMember.CollaborationRole = 'Standard';
                groupMember.NotificationFrequency = notificationFrequency;
                cgmInsertList.add(groupMember);

                if(groupAnnoucementsMap.containsKey(groupId)) {
                    CourseCommunitiesGroupAnnouncementsUtil.addAnnouncementsForUser(userId, courseAnnoucementRecordTypeId, groupAnnoucementsMap.get(groupId), cacInsertList);
                }
            }
        }
        
        insert cacInsertList;
        insert cgmInsertList;
    }
    
    private void getCourseCodeToGroupIdMap(Set<String> courseCodeSet, Map<String, String> courseCodeToGroupIdMap, 
                                           Map<String, String> courseCodeToCourseIdMap) 
    {
        Map<String, WGUCourse__c> courseMap = new Map<String, WGUCourse__c>([SELECT Id, BannerCode__c FROM WGUCourse__c WHERE BannerCode__c IN :courseCodeSet]);
        for(String courseId : courseMap.keySet()) {
            courseCodeToCourseIdMap.put(courseMap.get(courseId).BannerCode__c, courseId);
        }
        
        Map<String, String> groupCourseMap = new CourseCommunitySyncUtil().getGroupCourseMap(courseMap.keySet());        
        for(String courseId : groupCourseMap.keySet()) {
            courseCodeToGroupIdMap.put(courseMap.get(courseId).BannerCode__c, groupCourseMap.get(courseId));
        }
    } 
    
}