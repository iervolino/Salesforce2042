public class CourseCommunitiesDegreeChangeUtil {

    public void updateCourseCommunitiesForNewDegree(List<Contact> updatedContactList) {
        Map<String, String> contactProgramIdMap = new Map<String, String>();
        Set<String> programIdSet = new Set<String>();
        for(Contact c : updatedContactList) {
            if(c.WGUDegreeProgram__c == null) {
                continue;
            }
            
            contactProgramIdMap.put(c.id, c.WGUDegreeProgram__c);
            programIdSet.add(c.WGUDegreeProgram__c);
        }
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        addUsersToGroups(networkId, contactProgramIdMap, programIdSet);
    }
    
    private void addUsersToGroups(String networkId, Map<String, String> contactProgramIdMap, Set<String> programIdSet) {
        List<User> addUserList = [SELECT Id, ContactId FROM User WHERE ContactId IN :contactProgramIdMap.keySet()];
        Set<String> addUserIdSet = new Set<String>();
        Map<String, String> userContactMap = new Map<String, String>();
        for(User u :addUserList) {
            addUserIdSet.add(u.id);
            userContactMap.put(u.id, u.ContactId);
        }
        
        CourseCommunitySyncUtil util = new CourseCommunitySyncUtil();
        
        Map<String, List<String>> programCourseMap = new Map<String, List<String>>();
        Set<String> courseIdSet = new Set<String>();
        util.populateCourseMapAndSet(programIdSet, programCourseMap, courseIdSet);
        
        Map<String, String> groupCourseMap = util.getGroupCourseMap(courseIdSet);
        Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap = util.getExistingPermissionMap(addUserIdSet);
        Map<String, Map<String, CollaborationGroupMember>> existingGroupMap = util.getExistingGroupMap(addUserIdSet);
        
        processUsers(addUserIdSet, contactProgramIdMap, groupCourseMap, networkId, 
                     userContactMap, existingPermissionMap, existingGroupMap, programCourseMap);
    }
    
    private void processUsers(Set<String> addUserIdSet, Map<String, String> contactProgramIdMap, Map<String, String> groupCourseMap,
                              String networkId, Map<String, String> userContactMap, Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap,
                              Map<String, Map<String, CollaborationGroupMember>> existingGroupMap, Map<String, List<String>> programCourseMap) 
    {
        String groupAccessRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access'].id;
        
        List<CollaborationGroupMember> insertGroupMemberList = new List<CollaborationGroupMember>();
        List<CollaborationGroupMember> deleteGroupMemberList = new List<CollaborationGroupMember>();
        List<CommunityAccessControl__c> insertCacList = new List<CommunityAccessControl__c>();
        List<CommunityAccessControl__c> updateCacList = new List<CommunityAccessControl__c>();
        for(String userId : addUserIdSet) {
            String contactId = userContactMap.get(userId);
            String wguProgramId = contactProgramIdMap.get(contactId);
            List<String> courseIdList = programCourseMap.get(wguProgramId);
            processUser(userId, courseIdList, networkId, groupCourseMap, groupAccessRecordTypeId,
                        insertGroupMemberList, deleteGroupMemberList, insertCacList, updateCacList,
                        existingPermissionMap, existingGroupMap);
        }
        
        if(!insertGroupMemberList.isEmpty()) {
            insert insertGroupMemberList;
        }
        
        if(!deleteGroupMemberList.isEmpty()) {
            delete deleteGroupMemberList;
        }
        
        if(!insertCacList.isEmpty()) {
            CourseCommunitiesGroupAnnouncementsUtil.addAnnouncementsForNewUsersGroups(insertCacList);
            insert insertCacList;
        }
        
        if(!updateCacList.isEmpty()) {
            update updateCacList;
        }
    }
    
    private void processUser(String userId, List<String> courseIdList, String networkId, Map<String, String> groupCourseMap, String groupAccessRecordTypeId,
                             List<CollaborationGroupMember> insertGroupMemberList, List<CollaborationGroupMember> deleteGroupMemberList,
                             List<CommunityAccessControl__c> insertCacList, List<CommunityAccessControl__c> updateCacList,
                             Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap, Map<String, Map<String, CollaborationGroupMember>> existingGroupMap) 
    {
        for(String courseId : courseIdList) {
            String groupId = groupCourseMap.get(courseId);
            if(groupId == null) {
                continue;
            }
            
            //Check to see if they already have the correct permissions
            if(existingPermissionMap.containsKey(userId) && existingPermissionMap.get(userId).containsKey(groupId)) {
                continue;
            }
            else {
                CommunityAccessControl__c cac = new CommunityAccessControl__c();
                cac.CommunityStatus__c = 'Viewer';
                cac.StudentUser__c = userId;
                cac.GroupId__c = groupId;
                cac.CommunityId__c = networkId;
                cac.RecordTypeId = groupAccessRecordTypeId;
                cac.WGUCourse__c = courseId;
                insertCacList.add(cac);
            }
            
            if(existingGroupMap.containsKey(userId) && existingGroupMap.get(userId).containsKey(groupId)) {
                continue;
            }
            else {
                CollaborationGroupMember groupMember = new CollaborationGroupMember();
                groupMember.CollaborationGroupId = groupId;
                groupMember.MemberId = userId;
                groupMember.CollaborationRole = 'Standard';
                groupMember.NotificationFrequency = 'N';
                insertGroupMemberList.add(groupMember);
            }
        }
        
        removeGroupsFromOldDegree(userId, courseIdList, groupCourseMap, existingPermissionMap, existingGroupMap, deleteGroupMemberList, updateCacList);
    }
    
    private void removeGroupsFromOldDegree(String userId, List<String> courseIdList, Map<String, String> groupCourseMap,
                                           Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap, 
                                           Map<String, Map<String, CollaborationGroupMember>> existingGroupMap,
                                           List<CollaborationGroupMember> deleteGroupMemberList, List<CommunityAccessControl__c> updateCacList) 
    {
        if(!existingGroupMap.containsKey(userId)) {
            return;
        }
        Map<String, CollaborationGroupMember> groupMap = existingGroupMap.get(userId);
        Set<String> groupIdSet = groupMap.keySet();
        
        Set<String> commonGroups = new Set<String>();
        for(String courseId : courseIdList) {
            if(!groupCourseMap.containsKey(courseId)) {
                continue;
            }
            String groupId = groupCourseMap.get(courseId);
            if(groupIdSet.contains(groupId)) {
                commonGroups.add(groupId);
            }
        }
        
        Map<String, CommunityAccessControl__c> permissionMap = existingPermissionMap.get(userId);
        for(String groupId : groupIdSet) {
            if(commonGroups.contains(groupId)) {
                continue;
            }
            deleteGroupMemberList.add(groupMap.get(groupId));
            
            if(permissionMap != null && permissionMap.containsKey(groupId)) {
                CommunityAccessControl__c cac = permissionMap.get(groupId);
                cac.CommunityStatus__c = 'Removed';
                updateCacList.add(cac);
            }
        }
    }
    
}