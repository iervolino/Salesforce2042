public class CommonsChatterManagementControl {

    public String groupId { get; set; }
    public Map<String, String> groupMap { get; set; }
    
    //File upload
    public Blob fileBlob { get; set; }
    public String filename { get; set; }
    public String fileType { get; set; }
    public Integer fileSize { get; set; }
    public String fileMessage { get; set; }
    public String fileFeedItemId { get; set; }
    public String postStatus { get; set; }
    
    public String quickTipText { get; set; }
    public String announcementText { get; set; }
    
    /*public CourseCommonsModeratorPaginator unansweredPaginator { get; set; }
    public CourseCommonsModeratorPaginator qaPaginator { get; set; }
    public CourseCommonsModeratorPaginator waitingForClarificationPaginator { get; set; }
    public CourseCommonsModeratorPaginator resolvedPaginator { get; set; }*/
    
    private String communityId;
    
    public CommonsChatterManagementControl() {
        groupId = Apexpages.currentPage().getParameters().get('groupId');
        if(!Test.isRunningTest()) {
            groupMap = CommonsChatterUtil.getUserGroupMap();
            if(groupId == null && groupMap.size() > 0) { //Default to the first item on the list
                groupId = new List<String>(groupMap.keySet()).get(0);
                
                //TODO:Remove this, only for testing
                /*if(new Set<String>(groupMap.values()).contains('MKC1')) {
                    for(String commonsGroupId : groupMap.keySet()) {
                        if(groupMap.get(commonsGroupId).equals('MKC1')) {
                            groupId = commonsGroupId;
                        }
                    }
                }*/
            }
            //setupPaginators();
        }
    }
    
    /*private void setupPaginators() {
        unansweredPaginator = setupCommunityAccessControlPaginator(new String[]{'Unanswered','Student Responded'});
        qaPaginator = setupCommunityAccessControlPaginator(new String[]{'Q/A'});
        waitingForClarificationPaginator = setupCommunityAccessControlPaginator(new String[]{'Waiting for Clarification'});
        resolvedPaginator = setupCommunityAccessControlPaginator(new String[]{'Course Mentor Satisfied', 'Q/A Resolved'});
    }*/
    
    public List<SelectOption> getGroupOptions() {
        return CommonsChatterUtil.getGroupOptions(groupMap);
    }
    
    public String getSelectedGroupName() {
        if(groupId == null) {
            return null;
        }
        return groupMap.get(groupId);
    }
    
    private String getCommunityId() {
        if(communityId == null) {
            communityId = CommonsChatterUtil.getWGUCommonsCommunityId();
        }
        return communityId;
    }
    
    public List<CommonsCommunityManagementControlResult> getCommunityAccessControlListUnanswered() {
        return getCommunityAccessControlList(new String[] {'Unanswered', 'Student Responded'});
    }
    
    /*public List<CommonsCommunityManagementControlResult> getCommunityAccessControlListStudentResponded() {
        return getCommunityAccessControlList('Student Responded');
    }
    
    public List<CommonsCommunityManagementControlResult> getCommunityAccessControlListWaitingForClarification() {
        return getCommunityAccessControlList('Waiting for Clarification');
    }
    
    public List<CommonsCommunityManagementControlResult> getCommunityAccessControlListCourseMentorSatisfied() {
        return getCommunityAccessControlList('Course Mentor Satisfied');
    }*/
    
    public Integer getUnansweredQuestionCount() {
        if(groupId == null) {
            return null;
        }
        
        return [SELECT COUNT()
                  FROM CommunityAccessControl__c 
                 WHERE PostStatus__c IN ('Unanswered', 'Student Responded')
                   AND GroupId__c = :groupId
                   AND RecordType.Name = 'Post'];
    }
    
    public List<CommonsCommunityManagementControlResult> getCommunityAccessControlList(String[] listType) {
        if(groupId == null) {
            return null;
        }
        
        Set<String> listSet = new Set<String>();
        listSet.addAll(listType);
        
        List<CommunityAccessControl__c> cacList = [SELECT id, 
                                                          createdById, 
                                                          createdDate, 
                                                          GroupId__c, 
                                                          CaseId__c, 
                                                          Student__c, 
                                                          Question__c, 
                                                          StudentResponse__c, 
                                                          OriginalPostId__c,
                                                          MyResponse__c
                                                     FROM CommunityAccessControl__c 
                                                    WHERE PostStatus__c IN :listSet
                                                      AND GroupId__c = :groupId
                                                      AND RecordType.Name = 'Post'
                                                    ORDER BY CreatedDate
                                                    LIMIT 50];
        
        Map<String, FeedItemWithUserType> feedItemMap = new Map<String, FeedItemWithUserType>();
        Map<String, String> commentFeedItemMap = new Map<String, String>();
        getFeedItemMap(cacList, feedItemMap, commentFeedItemMap);
        //Map<String, CollaborationGroup> groupNameMap = getGroupNameMap(cacList);
        //Map<String, Contact> contactMap = getContactMap(cacList);
        //return createResultList(cacList, groupNameMap, contactMap, feedItemMap);
        
        return createResultList(cacList, feedItemMap, commentFeedItemMap);
    }
    
    /*public CourseCommonsModeratorPaginator setupCommunityAccessControlPaginator(String[] listType) {
        if(groupId == null) {
            return null;
        }
        
        List<CommunityAccessControl__c> cacList = [SELECT id, 
                                                          createdById, 
                                                          createdDate, 
                                                          GroupId__c, 
                                                          CaseId__c, 
                                                          Student__c, 
                                                          Question__c, 
                                                          StudentResponse__c, 
                                                          OriginalPostId__c,
                                                          MyResponse__c
                                                     FROM CommunityAccessControl__c 
                                                    WHERE PostStatus__c = :listType
                                                      AND GroupId__c = :groupId
                                                    ORDER BY CreatedDate];
        
        
        Map<String, FeedItemWithUserType> feedItemMap = new Map<String, FeedItemWithUserType>();
        Map<String, String> commentFeedItemMap = new Map<String, String>();
        getFeedItemMap(cacList, feedItemMap, commentFeedItemMap);
        
        List<CommonsCommunityManagementControlResult> resultList = createResultList(cacList, feedItemMap, commentFeedItemMap);
        return new CourseCommonsModeratorPaginator(resultList, 10);
    }*/
    
    private void getFeedItemMap(List<CommunityAccessControl__c> cacList, Map<String, FeedItemWithUserType> feedItemMap, Map<String, String> commentFeedItemMap) {
        String feedItemPrefix = Schema.SObjectType.FeedItem.getKeyPrefix();
        
        Set<String> commentIdSet = new Set<String>();
        Set<String> feedItemIdSet = new Set<String>();
        for(CommunityAccessControl__c cac : cacList) {
            if(cac.OriginalPostId__c.startsWith(feedItemPrefix)) {
            	feedItemIdSet.add(cac.OriginalPostId__c);
            }
            else {
                commentIdSet.add(cac.OriginalPostId__c);
            }
        }
        
        List<FeedComment> feedCommentList = [SELECT FeedItemId FROM FeedComment WHERE Id IN :commentIdSet];
        for(FeedComment comment : feedCommentList) {
            feedItemIdSet.add(comment.FeedItemId);
            commentFeedItemMap.put(comment.Id, comment.FeedItemId);
        }
        
        String communityId = CommonsChatterUtil.getWGUCommonsCommunityId();
        List<ConnectApi.FeedItem> itemList = new List<ConnectApi.FeedItem>();
        for(String feedItemId : feedItemIdSet) {
            itemList.add(ConnectApi.ChatterFeeds.getFeedItem(communityId, feedItemId));
        }
        
        CommonsChatterUtil chatterUtil = new CommonsChatterUtil();
        List<FeedItemWithUserType> feedItemList = chatterUtil.convertFeedItemListToFeedItemWithUserType(itemList, communityId);
        for(FeedItemWithUserType feedItem : feedItemList) {
            feedItemMap.put(feedItem.feedItem.Id, feedItem);
        }
    }
    
    private List<CommonsCommunityManagementControlResult> createResultList(List<CommunityAccessControl__c> cacList, 
                                                                           //Map<String, CollaborationGroup> groupNameMap, 
                                                                           //Map<String, Contact> contactMap,
                                                                           Map<String, FeedItemWithUserType> feedItemMap,
                                                                           Map<String, String> commentFeedItemMap) 
    {
        List<CommonsCommunityManagementControlResult> resultList = new List<CommonsCommunityManagementControlResult>();
        Set<String> itemAlreadyInList = new Set<String>();
        for(CommunityAccessControl__c cac  : cacList) {
            CommonsCommunityManagementControlResult result = new CommonsCommunityManagementControlResult();
            FeedItemWithUserType item;
            if(feedItemMap.containsKey(cac.OriginalPostId__c)) {
                item = feedItemMap.get(cac.OriginalPostId__c);
            }
            else if(commentFeedItemMap.containsKey(cac.OriginalPostId__c)) {
                String feedItemId = commentFeedItemMap.get(cac.OriginalPostId__c);
                if(feedItemMap.containsKey(feedItemId)) {
                    item = feedItemMap.get(feedItemId);
                }
                else {
                    continue;
                }
            }
            else {
                continue;
            }
            
            if(itemAlreadyInList.contains(item.feeditem.id)) {
                continue;
            }
            
            result.feedItem = item;
            
            itemAlreadyInList.add(item.feeditem.id);
            resultList.add(result);
        }
        /*for(CommunityAccessControl__c cac : cacList) {
            CommonsCommunityManagementControlResult result = new CommonsCommunityManagementControlResult();
            //result.groupName = groupNameMap.get(cac.GroupId__c).name;
            result.question = cac.Question__c;
            result.communityAccessControlId = cac.id;
            result.mentorResponse = cac.MyResponse__c;
            result.studentResponse = cac.StudentResponse__c;
            result.feedItem = feedItemMap.get(cac.OriginalPostId__c);
            
            //if(cac.student__c != null) {
            //    Contact c = contactMap.get(cac.student__c);
            //    result.student = c.firstName + ' ' + c.lastName;
            //}
            
            resultList.add(result);
        }*/
        return resultList;
    }
    
    /*private Map<String, CollaborationGroup> getGroupNameMap(List<CommunityAccessControl__c> cacList) {
        Set<String> groupIdSet = new Set<String>();
        for(CommunityAccessControl__c cac : cacList) {
            groupIdSet.add(cac.GroupId__c);
        }
        return new Map<String, CollaborationGroup>([SELECT id, name FROM CollaborationGroup WHERE id IN :groupIdSet]);
    }
    
    private Map<String, Contact> getContactMap(List<CommunityAccessControl__c> cacList) {
        Set<String> contactIdSet = new Set<String>();
        for(CommunityAccessControl__c cac : cacList) {
            contactIdSet.add(cac.student__c);
        }
        return new Map<String, Contact>([SELECT id, firstName, lastName FROM Contact WHERE id IN :contactIdSet]);
    }*/
    
    /*public PageReference respondToQuestion() {
        String itemId = Apexpages.currentPage().getParameters().get('itemId');
        PageReference responsePage = new PageReference('/apex/CommonsChatterManagementResponse');
        responsePage.getParameters().put('itemId', itemId);
        return responsePage;
    }*/
    
    public List<CommunityAccessControl__c> getFilesForGroup() {
        if(groupId == null) {
            return null;
        }
        
        return [SELECT Id, (SELECT Id, Name FROM Attachments) FROM CommunityAccessControl__c WHERE GroupId__c = :groupId AND AdministrationType__c = 'Document' AND RecordType.Name = 'Community Administration'];
    }
    
    public void deleteCommunityAccessControl() {
        String id = Apexpages.currentPage().getParameters().get('id');
        List<CommunityAccessControl__c> cacList = ([SELECT Id FROM CommunityAccessControl__c WHERE Id = :id]);
        if(cacList.size() == 0) {
            return;
        }
        delete cacList;
    }
    
    public List<CourseCommunitiesAnnouncementOrTip> getCourseCommunityAnnouncements() {
        List<CourseCommunitiesAnnouncementOrTip> announcementList = new List<CourseCommunitiesAnnouncementOrTip>();
        List<CommunityAccessControl__c> cacList = queryCac('Announcement');
        for(CommunityAccessControl__c cac : cacList) {
            announcementList.add(new CourseCommunitiesAnnouncementOrTip(cac));
        }
        return announcementList;
    }
    
    public List<CourseCommunitiesAnnouncementOrTip> getCourseCommunityQuickTips() {
        List<CourseCommunitiesAnnouncementOrTip> tipList = new List<CourseCommunitiesAnnouncementOrTip>();
        List<CommunityAccessControl__c> cacList = queryCac('Quick Tip');
        for(CommunityAccessControl__c cac : cacList) {
            tipList.add(new CourseCommunitiesAnnouncementOrTip(cac));
        }
        return tipList;
    }
    
    private List<CommunityAccessControl__c> queryCac(String adminType) {
        if(groupId == null) {
            return new List<CommunityAccessControl__c>();
        }
    	return [SELECT Id,
                       MyResponse__c,
                       DateAnnouncementExpires__c,
                       AdministrationType__c
                  FROM CommunityAccessControl__c 
                 WHERE AdministrationType__c = :adminType
                   AND GroupId__c = :groupId
                   AND RecordType.Name = 'Community Administration'
                   AND AnnouncementStatus__c = 'Active'
                 ORDER BY CreatedDate DESC];
    }
    
    public void createAdminCommunityAccessControl() {
        String message = Apexpages.currentPage().getParameters().get('message');
        String adminType = Apexpages.currentPage().getParameters().get('adminType');
        String numberOfDaysToExpiration = Apexpages.currentPage().getParameters().get('numberOfDaysToExpiration');
        
        System.debug(message + ' ' + adminType + ' ' +  numberOfDaysToExpiration);

        if(groupId == null) {
            return;
        }
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.groupId__c = groupId;
        cac.MyResponse__c = message;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration'].id;
        cac.AdministrationType__c = adminType;
        
        if(adminType == 'Announcement') {
            Integer daysUntilExpiration = 30;
            if(String.isNotEmpty(numberOfDaysToExpiration) && numberOfDaysToExpiration != '0') {
                daysUntilExpiration = Integer.valueOf(numberOfDaysToExpiration);
            }
            cac.DateAnnouncementExpires__c = System.today().addDays(daysUntilExpiration);
        }
        insert cac;
        System.debug('cac~' + cac);
        if(adminType == 'Announcement') {
            createAnnouncementViewRecords(groupId, cac.id);
        }
    }

    @Future
    private static void createAnnouncementViewRecords(String groupId, String announcementId) {
        List<CommunityAccessControl__c> cacList = new List<CommunityAccessControl__c>();
        List<CollaborationGroupMember> cgmList = [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :groupId];
        String recordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CommunityAccessControl__c' AND Name = 'Course Announcement'].id;
        for(CollaborationGroupMember cgm : cgmList) {
            cacList.add(CourseCommunitiesGroupAnnouncementsUtil.createAnnouncementViewRecord(cgm.MemberId, recordTypeId, announcementId));
        }

        insert cacList;
    }
    
    public void editAdminCommunityAccessControl() {
        String id = Apexpages.currentPage().getParameters().get('itemId');
        String message = Apexpages.currentPage().getParameters().get('updatedMessage');
        String addNumberOfDaysToExpiration = Apexpages.currentPage().getParameters().get('addNumberOfDaysToExpiration');
        
        List<CommunityAccessControl__c> cacList = ([SELECT Id, MyResponse__c, DateAnnouncementExpires__c FROM CommunityAccessControl__c WHERE Id = :id]);
        if(cacList.size() == 0) {
            return;
        }
        
        CommunityAccessControl__c cac = cacList.get(0);
        cac.MyResponse__c = message;
        
        if(String.isNotEmpty(addNumberOfDaysToExpiration) && addNumberOfDaysToExpiration != '0') {
            cac.DateAnnouncementExpires__c = cac.DateAnnouncementExpires__c.addDays(Integer.valueOf(addNumberOfDaysToExpiration));
        }

        update cac;
    }
    
    public void postFileToChatter() {
        Map<String, String> pageParameters = Apexpages.currentPage().getParameters();
        
        CommonsChatterUtil util = new CommonsChatterUtil();
        util.postFileToChatter(pageParameters, fileName, fileBlob, fileType, 
                                  fileMessage, null, fileFeedItemId, groupId, getCommunityId(), postStatus);
        
        fileBlob = null;
    }
    
    public void postMessageToChatter() {
        String message = Apexpages.currentPage().getParameters().get('message');
        String feedItemId = Apexpages.currentPage().getParameters().get('feedItemId');
        String postStatus = Apexpages.currentPage().getParameters().get('postStatus');
        
        CommonsChatterUtil util = new CommonsChatterUtil();
        util.postMessageToChatter(message, null, feedItemId, groupId, getCommunityId(), postStatus);
    }

    public void renewCourseTip() {
        String tipId = Apexpages.currentPage().getParameters().get('id');
        if(String.isEmpty(tipId)) {
            return;
        }

        List<CommunityAccessControl__c> cacList = [SELECT MyResponse__c, AdministrationType__c, RecordTypeId, GroupId__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE Id = :tipId];
        if(cacList.isEmpty()) {
            return;
        }

        CommunityAccessControl__c cac = cacList.get(0);
        cac.DateAnnouncementExpires__c = System.today().addDays(-1);

        CommunityAccessControl__c tip = cac.clone();
        tip.DateAnnouncementExpires__c = null;

        update cac;
        insert tip;
    }

    public class CourseCommunitiesAnnouncementOrTip {
        private final Integer DAYS_BEFORE_EXPIRATION_RENEWABLE = 5;

        public CommunityAccessControl__c announcementOrTip { get; private set; }

        public CourseCommunitiesAnnouncementOrTip(CommunityAccessControl__c announcementOrTip) {
            this.announcementOrTip = announcementOrTip;
        }

        public String getYYYYMMDDFormattedExpirationDate() {
            if(announcementOrTip.DateAnnouncementExpires__c == null) {
                return null;
            }
            return datetime.newInstance(announcementOrTip.DateAnnouncementExpires__c, time.newInstance(0,0,0,0)).format('yyyy-MM-dd');
        }

        public String getMMDDYYYYFormattedExpirationDate() {
            if(announcementOrTip.DateAnnouncementExpires__c == null) {
                return null;
            }
            return datetime.newInstance(announcementOrTip.DateAnnouncementExpires__c, time.newInstance(0,0,0,0)).format('MM/dd/yyyy');
        }

        public Integer getDaysToExpiration() {
            if(announcementOrTip.DateAnnouncementExpires__c == null) {
                return null;
            }
            return System.today().daysBetween(announcementOrTip.DateAnnouncementExpires__c);
        }

        public Integer getDaysToRenewalEligibility() {
            if(announcementOrTip.DateAnnouncementExpires__c == null) {
                return null;
            }
            return getDaysToExpiration() - DAYS_BEFORE_EXPIRATION_RENEWABLE;
        }

        public Boolean getEligibleForRenewal() {
            if(announcementOrTip.AdministrationType__c != 'Quick Tip' || announcementOrTip.DateAnnouncementExpires__c == null) {
                return false;
            }

            if(getDaysToExpiration() >= DAYS_BEFORE_EXPIRATION_RENEWABLE) {
                return false;
            }
            return true;
        }
    }
    
}