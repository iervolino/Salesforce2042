public class CommonsChatterController {
    
    public Map<String, String> groupMap;
    
    public String groupId { get; set; }
    public String communityId { get; set; }
    
    public Blob fileBlob { get; set; }
    public String filename { get; set; }
    public String fileType { get; set; }
    public Integer fileSize { get; set; }
    public String fileMessage { get; set; }
    public String fileQuestion { get; set; }
    public String fileFeedItemId { get; set; }
    
    public CommonsChatterController() {
        if(!Test.isRunningTest()) {
            groupMap = CommonsChatterUtil.getUserGroupMap();
            if(groupMap.size() > 0) { //Set the group to the course param we received from Study Plan
                String courseCode = Apexpages.currentPage().getParameters().get('code');
                String groupIdParam = Apexpages.currentPage().getParameters().get('groupId');
                if(groupIdParam != null) {
                	groupId = groupIdParam;
                }
                else if(new Set<String>(groupMap.values()).contains(courseCode)) {
                    for(String commonsGroupId : groupMap.keySet()) {
                        if(groupMap.get(commonsGroupId).equals(courseCode)) {
                            groupId = commonsGroupId;
                        }
                    }
                }
                else {
                    groupId = new List<String>(groupMap.keySet()).get(0);
                }
            }
        }
    }
    
    public String getCommunityId() {
        if(communityId == null) {
            communityId = CommonsChatterUtil.getWGUCommonsCommunityId();
        }
        return communityId;
    }
 
    public List<SelectOption> getGroupOptions() {
        return CommonsChatterUtil.getGroupOptions(groupMap);
    }
    
    public String getSelectedGroupName() {
        if(groupId == null) {
            return null;
        }
        return groupMap.get(groupId);
    }
    
    public List<FeedItemWithUserType> getFeedItemsWithUserType() {
        if (String.isEmpty(groupId)) {
            return null;
        }
        ConnectApi.FeedItemPage itemPage = ConnectApi.ChatterFeeds.getFeedItemsFromFeed(getCommunityId(), ConnectApi.FeedType.Record, groupId);
        List<ConnectApi.FeedItem> itemList = itemPage.items;
        while (itemPage.nextPageToken != null) {
            itemPage = ConnectApi.ChatterFeeds.getFeedItemsFromFeed(getCommunityId(), ConnectApi.FeedType.Record, groupId, itemPage.nextPageToken, 100, ConnectApi.FeedSortOrder.CreatedDateDesc);
            itemList.addAll(itemPage.items);
        }
        CommonsChatterUtil chatterUtil = new CommonsChatterUtil();
        return chatterUtil.convertFeedItemListToFeedItemWithUserType(itemList,getCommunityId());
    }
    
    /*public List<FeedItemWithUserType> getFeedItemsWithUserType() {
        if (String.isEmpty(groupId)) {
            return null;
        }
        
        List<FeedItem> feedItemList = [SELECT Id, Type,
                                              CreatedById, CreatedBy.FirstName, CreatedBy.LastName,
                                              ParentId, Parent.Name,
                                              Body, Title, LinkUrl, ContentData, ContentFileName,
                                                  (SELECT Id, CommentBody, CreatedDate,
                                                   CreatedById, CreatedBy.FirstName, CreatedBy.LastName
                                                   FROM FeedComments ORDER BY CreatedDate)
                                         FROM FeedItem
                                        WHERE ParentId = :groupId
                                        ORDER BY CreatedDate DESC, Id DESC];
        
        Set<String> userIdSet = new Set<String>();
        Set<String> feedItemIdSet = new Set<String>();
        for(FeedItem item : feedItemList) {
            feedItemIdSet.add(item.id);
            userIdSet.add(item.CreatedById);
            for(FeedComment comment : item.feedComments) {
                userIdSet.add(comment.CreatedById);
            }
        }
        
        Map<String, Boolean> questionMap = new Map<String, Boolean>();
        List<CommunityAccessControl__c> cacList = ([SELECT OriginalPostId__c, Question__c FROM CommunityAccessControl__c WHERE OriginalPostId__c IN :feedItemIdSet]);
        for(CommunityAccessControl__c cac : cacList) {
            questionMap.put(cac.OriginalPostId__c, !String.isEmpty(cac.Question__c));
        }
        
        Map<String, User> userMap = new Map<String, User>([SELECT id, Profile.name FROM User WHERE id IN :userIdSet]);
        List<FeedItemWithUserType> resultList = new List<FeedItemWithUserType>();
        for(FeedItem item : feedItemList) {
            boolean isStudent = userIsStudent(item.CreatedById, userMap);
            boolean isQuestion = questionMap.containsKey(item.id) && questionMap.get(item.id);
            String shortenedFeedBody = item.body.abbreviate(105);
            List<CommentWithUserType> commentList = new List<CommentWithUserType>();
            for(FeedComment comment : item.feedComments) {
                boolean commentIsStudent = userIsStudent(comment.CreatedById, userMap);
                CommentWithUserType commentWithUserType = new CommentWithUserType(comment, commentIsStudent);
                commentList.add(commentWithUserType);
            }
            FeedItemWithUserType feedItemWithType = new FeedItemWithUserType(item, isStudent, commentList, shortenedFeedBody, 
                    item.CreatedBy.FirstName, item.CreatedBy.LastName, isQuestion);
            resultList.add(feedItemWithType);
        }
        return resultList;
    }*/
    
    public List<GroupMemberWithUserType> getGroupMembers() {
        if(groupId == null) {
            return null;
        }
        
        List<ConnectApi.GroupMember> groupMemberList = ConnectApi.ChatterGroups.getMembers(getCommunityId(), groupId, 0, 1000).members;
        
        Set<String> userIdSet = new Set<String>();
        for(ConnectApi.GroupMember member : groupMemberList) {
            userIdSet.add(member.user.id);
        }
        
        Set<String> usersWithContributorSet = new Set<String>();
        List<CommunityAccessControl__c> cacList = [SELECT StudentUser__c FROM CommunityAccessControl__c WHERE StudentUser__c IN :userIdSet AND GroupId__c = :groupId AND CommunityStatus__c = 'Contributor'];
        for(CommunityAccessControl__c cac : cacList) {
            usersWithContributorSet.add(cac.StudentUser__c);
        }

        Map<String, User> userMap = new Map<String, User>([SELECT id, Profile.name FROM User WHERE id IN :usersWithContributorSet]);
        List<GroupMemberWithUserType> memberList = new List<GroupMemberWithUserType>();
        CommonsChatterUtil chatterUtil = new CommonsChatterUtil();
        for(ConnectApi.GroupMember member : groupMemberList) {
            if(!usersWithContributorSet.contains(member.user.id)) {
                continue;
            }
            boolean isStudent = chatterUtil.userIsStudent(member.user.id, userMap);
            memberList.add(new GroupMemberWithUserType(member, isStudent));
        }
        return memberList;
    }
    
    /*public void userGroups() {
        String userId = UserInfo.getUserId();
        List<CollaborationGroup> groupList = [SELECT Id, Name 
                                                FROM CollaborationGroup 
                                               WHERE NetworkId = :communityId
                                                 AND Id IN (SELECT CollaborationGroupId FROM CollaborationGroupMember WHERE MemberId = :userId)];
                                                 
        groupMap = new Map<String, String>();
        for(CollaborationGroup groupRec : groupList) {
            groupMap.put(groupRec.id, groupRec.name);
        }
    }*/
    
    public void postMessageToChatter() {
        String message = Apexpages.currentPage().getParameters().get('message');
        String question = Apexpages.currentPage().getParameters().get('question');
        String feedItemId = Apexpages.currentPage().getParameters().get('feedItemId');
        
        CommonsChatterUtil util = new CommonsChatterUtil();
        util.postMessageToChatter(message, question, feedItemId, groupId, getCommunityId(), null);
    }
    
    public void postFileToChatter() {
        Map<String, String> pageParameters = Apexpages.currentPage().getParameters();
        
        CommonsChatterUtil util = new CommonsChatterUtil();
        util.postFileToChatter(pageParameters, fileName, fileBlob, fileType, 
                               fileMessage, fileQuestion, fileFeedItemId, groupId, 
                               getCommunityId(), null);
        fileBlob = null;
    }
    
    public void postLinkToChatter() {
        String message = Apexpages.currentPage().getParameters().get('message');
        String linkUrl = Apexpages.currentPage().getParameters().get('linkUrl');
        String linkTitle = Apexpages.currentPage().getParameters().get('linkTitle');
        String question = Apexpages.currentPage().getParameters().get('question');
        String feedItemId = Apexpages.currentPage().getParameters().get('feedItemId');
        
        System.debug('linkUrl~' + linkUrl);
        System.debug('linkTitle~' + linkTitle);
        
        CommonsChatterUtil util = new CommonsChatterUtil();
        util.postLinkToChatter(message, linkUrl, linkTitle, question, feedItemId, groupId, getCommunityId());
    }
    
    
    
    public List<CommunityAccessControl__c> getFilesForGroup() {
        if(groupId == null) {
            return null;
        }
        
        return [SELECT (SELECT Id, Name FROM Attachments) FROM CommunityAccessControl__c WHERE GroupId__c = :groupId AND AdministrationType__c = 'Document' AND RecordType.Name = 'Community Administration'];
    }
    
    public boolean getIsReadOnly() {
        if(String.isEmpty(groupId)) {
            return true;
        }
        String userId = UserInfo.getUserId();
        List<CommunityAccessControl__c> cacList = [SELECT CommunityStatus__c
                                                     FROM CommunityAccessControl__c 
                                                    WHERE GroupId__c = :groupId
                                                      AND RecordType.Name = 'Group Access'
                                                      AND StudentUser__c = :userId];
        
        if(cacList.isEmpty()) {
        	return true;
        }
        
        CommunityAccessControl__c cac = cacList.get(0);
        if(cac.CommunityStatus__c == null
           || cac.CommunityStatus__c.equals('Viewer')
           || cac.CommunityStatus__c.equals('Removed')) 
        {
            return true;
        }
        return false;
    }
        
}