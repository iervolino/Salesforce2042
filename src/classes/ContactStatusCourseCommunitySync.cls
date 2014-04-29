public class ContactStatusCourseCommunitySync {

    public void processCourseCommunityGroupChanges(List<Contact> updatedStatusList) {
        Set<String> addContactIdSet = new Set<String>();
        Set<String> removeContactIdSet = new Set<String>();
        Map<String, String> contactProgramIdMap  = new Map<String, String>();
        for(Contact c : updatedStatusList) {
            if(c.Status__c.equals('AS')) {
                addContactIdSet.add(c.id);
                contactProgramIdMap.put(c.id, c.WGUDegreeProgram__c);
            }
            else if(c.Status__c.equals('DR')
                    || c.Status__c.equals('DD')
                    || c.Status__c.equals('WI')
                    || c.Status__c.equals('TB'))
            {
                removeContactIdSet.add(c.id);
            }
        }
        
        if(addContactIdSet.isEmpty() && removeContactIdSet.isEmpty()) {
            return;
        }
        
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        if(!addContactIdSet.isEmpty()) {
            addUsersToGroups(addContactIdSet, networkId, contactProgramIdMap);
        }
        
        if(!removeContactIdSet.isEmpty()) {
            removeUsersFromGroups(removeContactIdSet, networkId);
        }
    }
    
    private void addUsersToGroups(Set<String> addContactIdSet, String networkId, 
                                  Map<String, String> contactProgramIdMap) 
    {
        List<User> addUserList = [SELECT Id, ContactId FROM User WHERE ContactId IN :addContactIdSet];
        Set<String> addUserIdSet = new Set<String>();
        Map<String, String> userContactMap = new Map<String, String>();
        for(User u : addUserList) {
            addUserIdSet.add(u.id);
            userContactMap.put(u.id, u.contactId);
        }
        
        CourseCommunitySyncUtil util = new CourseCommunitySyncUtil();
        
        Set<String> programIdSet = new Set<String>();
        programIdSet.addAll(contactProgramIdMap.values());
        Map<String, List<String>> programCourseMap = new Map<String, List<String>>();
        Set<String> courseIdSet = new Set<String>();
        util.populateCourseMapAndSet(programIdSet, programCourseMap, courseIdSet);
        
        Map<String, String> groupCourseMap = util.getGroupCourseMap(courseIdSet);
        Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap = util.getExistingPermissionMap(addUserIdSet);
        Map<String, Map<String, CollaborationGroupMember>> existingGroupMap = util.getExistingGroupMap(addUserIdSet);
        
        processUsers(addUserIdSet, contactProgramIdMap, groupCourseMap, networkId, 
                     userContactMap, existingPermissionMap, existingGroupMap, programCourseMap);
    }
    
    
    
    private void processUsers(Set<String> addUserIdSet, Map<String, String> contactProgramIdMap, 
                              Map<String, String> groupCourseMap,
                              String networkId, Map<String, String> userContactMap, Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap,
                              Map<String, Map<String, CollaborationGroupMember>> existingGroupMap, Map<String, List<String>> programCourseMap) 
    {
        String groupAccessRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access' AND sObjectType = 'CommunityAccessControl__c'].id;
        
        List<CollaborationGroupMember> insertGroupMemberList = new List<CollaborationGroupMember>();
        List<CollaborationGroupMember> updateGroupMemberList = new List<CollaborationGroupMember>();
        List<CommunityAccessControl__c> insertCacList = new List<CommunityAccessControl__c>();
        List<CommunityAccessControl__c> updateCacList = new List<CommunityAccessControl__c>();
        for(String userId : addUserIdSet) {
            String contactId = userContactMap.get(userId);
            String wguProgramId = contactProgramIdMap.get(contactId);
            List<String> courseIdList = programCourseMap.get(wguProgramId);
            if(courseIdList == null || courseIdList.isEmpty()) {
                continue;
            }
            processUser(userId, courseIdList, networkId, groupCourseMap, groupAccessRecordTypeId,
                        insertGroupMemberList, updateGroupMemberList,
                        insertCacList, updateCacList, existingPermissionMap, existingGroupMap);
        }
        
        if(!insertGroupMemberList.isEmpty()) {
            insert insertGroupMemberList;
        }
        
        if(!insertCacList.isEmpty()) {
            CourseCommunitiesGroupAnnouncementsUtil.addAnnouncementsForNewUsersGroups(insertCacList);
            insert insertCacList;
        }
            
        if(!updateGroupMemberList.isEmpty()) {
            update updateGroupMemberList;
        }
                
        if(!updateCacList.isEmpty()) {
            update updateCacList;
        }
    }
    
    private void processUser(String userId, List<String> courseIdList, String networkId, Map<String, String> groupCourseMap, String groupAccessRecordTypeId,
                             List<CollaborationGroupMember> insertGroupMemberList, List<CollaborationGroupMember> updateGroupMemberList,
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
                CommunityAccessControl__c cac = existingPermissionMap.get(userId).get(groupId);
                if(!cac.CommunityStatus__c.equals('Viewer')) {
                    cac.CommunityStatus__c = 'Viewer';
                    updateCacList.add(cac); 
                }
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
                CollaborationGroupMember groupMember = existingGroupMap.get(userId).get(groupId);
                if(!groupMember.NotificationFrequency.equals('N')) {
                    groupMember.NotificationFrequency = 'N';
                    updateGroupMemberList.add(groupMember);
                }
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
    }
    
    private void removeUsersFromGroups(Set<String> removeContactIdSet, String networkId) {
        List<User> removeUserList = [SELECT Id FROM User WHERE ContactId IN :removeContactIdSet];
        Set<String> removeUserIdSet = new Set<String>();
        for(User u : removeUserList) {
            removeUserIdSet.add(u.id);
        }
        
        Map<String, Map<String, CollaborationGroupMember>> memberGroupMap = getMemberGroupMap(removeUserIdSet, networkId);
        
        if(memberGroupMap.isEmpty()) {
            return;
        }
        
        List<CommunityAccessControl__c> cacList = [SELECT Id, GroupId__c, StudentUser__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c IN :removeUserIdSet 
                                                      AND RecordType.Name = 'Group Access'];
        
        List<CollaborationGroupMember> deleteList = new List<CollaborationGroupMember>();
        List<CommunityAccessControl__c> updateList = new List<CommunityAccessControl__c>();
        for(CommunityAccessControl__c cac : cacList) {
            cac.CommunityStatus__c = 'Removed';
            updateList.add(cac);
            
            Map<String, CollaborationGroupMember> cgmMap = memberGroupMap.get(cac.StudentUser__c);
            if(cgmMap.containsKey(cac.GroupId__c)) {
                deleteList.add(cgmMap.get(cac.GroupId__c));
            }
        }
        
        if(!updateList.isEmpty()) {
            update updateList;
        }
        
        if(!deleteList.isEmpty()) {
            delete deleteList;
        }
    }
    
    private Map<String, Map<String, CollaborationGroupMember>> getMemberGroupMap(Set<String> removeUserIdSet, String networkId) {
        List<CollaborationGroupMember> cgmList = [SELECT CollaborationGroupId, MemberId 
                                                    FROM CollaborationGroupMember 
                                                   WHERE MemberId IN :removeUserIdSet 
                                                     AND CollaborationGroup.NetworkId = :networkId
                                                   ORDER BY MemberId];
        
        String currentUserId = null;
        Map<String, Map<String, CollaborationGroupMember>> memberGroupMap = new Map<String, Map<String, CollaborationGroupMember>>();
        for(CollaborationGroupMember cgm : cgmList) {
            if(currentUserId == null || !currentUserId.equals(cgm.MemberId)) {
                currentUserId = cgm.MemberId;
                memberGroupMap.put(cgm.MemberId, new Map<String, CollaborationGroupMember>());
            }
            memberGroupMap.get(cgm.MemberId).put(cgm.CollaborationGroupId, cgm);
        }
        return memberGroupMap;
    }
    
}