public class CourseCommunitySyncUtil {
    
    public void populateCourseMapAndSet(Set<String> programIdSet, Map<String, List<String>> programCourseMap,
                                         Set<String> courseIdSet) 
    {
        List<WGUCourseInProgram__c> courseInProgramList = [SELECT Program__c, Course__c 
                                                             FROM WGUCourseInProgram__c 
                                                            WHERE Program__c IN :programIdSet
                                                            ORDER BY Program__c];
        
        String currentProgramId = null;
        for(WGUCourseInProgram__c courseInProgram : courseInProgramList) {
            if(currentProgramId == null || !currentProgramId.equals(courseInProgram.Program__c)) {
                currentProgramId = courseInProgram.Program__c;
                programCourseMap.put(courseInProgram.Program__c, new List<String>());
            }
            programCourseMap.get(courseInProgram.Program__c).add(courseInProgram.Course__c);
            courseIdSet.add(courseInProgram.Course__c);
        }
    }

    public Map<String, String> getGroupCourseMap(Set<String> courseIdSet) {
        List<CommunityAccessControl__c> cacList = [SELECT GroupId__c, WGUCourse__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE WGUCourse__c IN :courseIdSet 
                                                      AND recordType.Name = 'Group Assignment'];

        Map<String, String> groupCourseMap = new Map<String, String>();
        for(CommunityAccessControl__c cac : cacList) {
            groupCourseMap.put(cac.WGUCourse__c, cac.GroupId__c);
        }
        return groupCourseMap;
    }
    
    public Map<String, Map<String, CommunityAccessControl__c>> getExistingPermissionMap(Set<String> userIdSet) {
        List<CommunityAccessControl__c> existingPermissionList = [SELECT GroupId__c, StudentUser__c, CommunityStatus__c
                                                                    FROM CommunityAccessControl__c 
                                                                   WHERE StudentUser__c IN :userIdSet 
                                                                     AND recordType.Name = 'Group Access'
                                                                   ORDER BY StudentUser__c];
        Map<String, Map<String, CommunityAccessControl__c>> existingPermissionMap = new Map<String, Map<String, CommunityAccessControl__c>>();
        String currentUserId = null;
        for(CommunityAccessControl__c cac : existingPermissionList) {
            if(currentUserId == null || !currentUserId.equals(cac.StudentUser__c)) {
                currentUserId = cac.StudentUser__c;
                existingPermissionMap.put(cac.StudentUser__c, new Map<String, CommunityAccessControl__c>());
            }
            existingPermissionMap.get(cac.StudentUser__c).put(cac.GroupId__c, cac);
        }
        return existingPermissionMap;
    }
    
    public Map<String, Map<String, CollaborationGroupMember>> getExistingGroupMap(Set<String> userIdSet) {
        List<CollaborationGroupMember> existingGroupList = [SELECT MemberId,
                                                                   CollaborationGroupId,
                                                                   NotificationFrequency
                                                              FROM CollaborationGroupMember
                                                             WHERE MemberId IN :userIdSet
                                                             ORDER BY MemberId];
        Map<String, Map<String, CollaborationGroupMember>> existingGroupMap = new Map<String, Map<String, CollaborationGroupMember>>();
        String currentMemberId = null;
        for(CollaborationGroupMember cgm : existingGroupList) {
            if(currentMemberId == null || !currentMemberId.equals(cgm.MemberId)) {
                currentMemberId = cgm.MemberId;
                existingGroupMap.put(cgm.MemberId, new Map<String, CollaborationGroupMember>());
            }
            existingGroupMap.get(cgm.MemberId).put(cgm.CollaborationGroupId, cgm);
        }
        return existingGroupMap;
    }
    
}