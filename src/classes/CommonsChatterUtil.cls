public class CommonsChatterUtil {
    
    private static String STUDENT_PROFILE_TYPE = 'Student Profile';
    
    public static String getWGUCommonsCommunityId() {
        List<Network> communityList = [SELECT id FROM Network WHERE name = 'WGU Commons'];
        if(communityList.size() != 1) {
            CommunityException e = new CommunityException();
            e.setMessage('WGU Commons community is not available');
            throw e;
        }
        return communityList.get(0).id;
    }
    
    public static Map<String, String> getUserGroupMap() { 
        Integer page = 0;        
        Integer pageSize = 100;
        String communityId = getWGUCommonsCommunityId();
        ConnectApi.UserGroupPage groupPage = ConnectApi.ChatterUsers.getGroups(communityId, 'me', page, pageSize);
        Map<String, String> groupMap = new Map<String, String>();
        Integer total = groupPage.total;
        while (page * pageSize < total) {
            for (ConnectApi.ChatterGroup grp : groupPage.groups) {
                groupMap.put(grp.id, grp.name);
            }
            page++;
            if (page * pageSize < total) {
                groupPage = ConnectApi.ChatterUsers.getGroups(communityId, 'me', page, pageSize);
            }
        }
        System.debug(groupMap);
        return groupMap;
    }
    
    public static List<SelectOption> getGroupOptions(Map<String, String> groupMap) {
        Set<String> idSet = groupMap.keySet();
        List<CommunityAccessControl__c> cacList = [SELECT GroupId__c, GroupLevel__c
                                                     FROM CommunityAccessControl__c 
                                                    WHERE GroupId__c IN :idSet 
                                                      AND RecordType.Name = 'Group Access'];
        
        Map<String, CommunityAccessControl__c> cacMap = new Map<String, CommunityAccessControl__c>();
        for(CommunityAccessControl__c cac : cacList) {
            cacMap.put(cac.GroupID__c, cac);
        }
        
        List<SelectOptionGroupTypeComparable> comparableList = new List<SelectOptionGroupTypeComparable>();
        for(String id : idSet) {
            String name = groupMap.get(id);
            CommunityAccessControl__c cac;
            if(cacMap.containsKey(id)) {
                cac = cacMap.get(id);
            }
            SelectOptionGroupTypeComparable optionWithGroup = new SelectOptionGroupTypeComparable(new SelectOption(id, name), cac);
            comparableList.add(optionWithGroup);
        }
        
        comparableList.sort();
        List<SelectOption> options = new List<SelectOption>();
        for(SelectOptionGroupTypeComparable optionWithGroup : comparableList) {
            options.add(optionWithGroup.option);
        }
        
        return options;
    }
    
    /*public static void checkForQuestionUpdate(List<FeedComment> commentList) {
        List<FeedComment> studentResponseList = getStudentResponseCommentList(commentList);
        Set<String> postByUserSet = new Set<String>();
        for(FeedComment comment : studentResponseList) {
            postByUserSet.add(comment.FeedItemId);
        }
        for(FeedComment comment : commentList) {
            
        }
        
        List<CommunityAccessControl__c> clarificationList = [SELECT OriginalPostId__c
                                                               FROM CommunityAccessControl__c 
                                                              WHERE OriginalPostId__c IN :studentResponseSet
                                                                AND PostStatus__c = 'Waiting for Clarification'];
        
        System.debug('clarificationList~' + clarificationList);
        
        List<CommunityAccessControl__c> cacList = new List<CommunityAccessControl__c>();                                                                                 
        for(FeedComment comment : studentResponseList) {
            for(CommunityAccessControl__c cac : clarificationList) {
                if(cac.OriginalPostId__c == comment.feedItemId) {
                    cac.PostStatus__c = 'Student Responded';
                    cac.StudentResponse__c = comment.commentBody;
                    cacList.add(cac);
                    break;
                }
            }
        }
        update cacList;
    }
    
    private static List<FeedComment> getStudentResponseCommentList(List<FeedComment> commentList) {
        Set<String> feedItemIdSet = new Set<String>();
        for(FeedComment comment : commentList) {
            feedItemIdSet.add(comment.feedItemId);
        }
        
        List<FeedComment> studentResponseList = new List<FeedComment>();
        Map<String, FeedItem> feedItemMap = new Map<String, FeedItem>([SELECT id, InsertedById FROM FeedItem WHERE id IN :feedItemIdSet]);
        for(FeedComment comment : commentList) {
            if(feedItemMap.containsKey(comment.FeedItemId)) {
                FeedItem item = feedItemMap.get(comment.FeedItemId);
                if(item.insertedById == comment.InsertedById) {
                    System.debug('comment~' + comment);
                    studentResponseList.add(comment);
                }
            }
        }
        return studentResponseList;
    }*/
    
    public List<FeedItemWithUserType> convertFeedItemListToFeedItemWithUserType(List<ConnectApi.FeedItem> itemList, String communityId) {
        Set<String> userIdSet = new Set<String>();
        Set<String> itemIdSet = new Set<String>();
        for(ConnectApi.FeedItem item : itemList) {
            String actorId = getIdFromActor(item.actor);
            userIdSet.add(actorId);
            itemIdSet.add(item.id);
            List<ConnectApi.Comment> commentItemList = new List<ConnectApi.Comment>();
            ConnectApi.CommentPage commentPage = item.comments;
            commentItemList.addAll(commentPage.comments);
            while (commentPage.nextPageToken != null) {
                commentPage = ConnectApi.ChatterFeeds.getCommentsForFeedItem(communityId, item.id, commentPage.nextPageToken, 100);
                commentItemList.addAll(commentPage.comments);
            }
            for(ConnectApi.Comment c : commentItemList) {
                userIdSet.add(c.user.id);
                itemIdSet.add(c.id);
            }
        }
        
        Map<String, Boolean> questionMap = new Map<String, Boolean>();
        Map<String, Boolean> questionRespondedMap = new Map<String, Boolean>();
        List<CommunityAccessControl__c> cacList = ([SELECT OriginalPostId__c, Question__c, PostStatus__c 
                                                      FROM CommunityAccessControl__c 
                                                     WHERE OriginalPostId__c IN :itemIdSet
                                                       AND RecordType.Name = 'Post']);
        
        for(CommunityAccessControl__c cac : cacList) {
            boolean question = false;
            boolean questionResponded = false;
            if(cac.PostStatus__c != null 
               && (cac.PostStatus__c.equals('Unanswered')
                   || cac.PostStatus__c.equals('Student Responded')
                   || cac.PostStatus__c.equals('Waiting for Clarification')
                   || cac.PostStatus__c.equals('Course Mentor Satisfied'))) 
            {
                question = true;
                if(cac.PostStatus__c.equals('Course Mentor Satisfied')
                   || cac.PostStatus__c.equals('Waiting for Clarification')) {
                    questionResponded = true;
                }
            }
            questionMap.put(cac.OriginalPostId__c, question);
            questionRespondedMap.put(cac.OriginalPostId__c, questionResponded);
        }
        
        Map<String, User> userMap = new Map<String, User>([SELECT id, Profile.name FROM User WHERE id IN :userIdSet]);
        List<FeedItemWithUserType> resultList = new List<FeedItemWithUserType>();
        for(ConnectApi.FeedItem item : itemList) {
            String actorId = getIdFromActor(item.actor);
            String shortenedFeedBody;
            if(item.body != null && item.body.text != null) {
            	shortenedFeedBody = item.body.text.abbreviate(105);
            }
            List<CommentWithUserType> commentList = new List<CommentWithUserType>();
            
            List<ConnectApi.Comment> commentItemList = new List<ConnectApi.Comment>();
            ConnectApi.CommentPage commentPage = item.comments;
            commentItemList.addAll(commentPage.comments);
            while (commentPage.nextPageToken != null) {
                commentPage = ConnectApi.ChatterFeeds.getCommentsForFeedItem(communityId, item.id, commentPage.nextPageToken, 100);
                commentItemList.addAll(commentPage.comments);
            }
            
            List<CommentComparable> comparableList = new List<CommentComparable>();
            for(ConnectApi.Comment comment : commentItemList) {
                comparableList.add(new CommentComparable(comment));
            }
            
            comparableList.sort();
            
            for(CommentComparable comp : comparableList) {
                ConnectApi.Comment c = comp.comment;
                boolean commentIsStudent = userIsStudent(c.user.id, userMap);
                boolean commentIsQuestion = questionMap.containsKey(c.id) && questionMap.get(c.id);
            	boolean commentIsQuestionResponded = questionRespondedMap.containsKey(c.id) && questionRespondedMap.get(c.id);
                CommentWithUserType commentWithUserType = new CommentWithUserType(c, commentIsStudent, commentIsQuestion, commentIsQuestionResponded);
                commentList.add(commentWithUserType);
            }
            boolean isStudent = userIsStudent(actorId, userMap);
            boolean isQuestion = questionMap.containsKey(item.id) && questionMap.get(item.id);
            boolean isQuestionResponded = questionRespondedMap.containsKey(item.id) && questionRespondedMap.get(item.id);
            FeedItemWithUserType feedItemWithType = new FeedItemWithUserType(item, isStudent, commentList, shortenedFeedBody, 
                    getFirstNameFromActor(item.actor), getLastNameFromActor(item.actor), isQuestion, isQuestionResponded);
            resultList.add(feedItemWithType);
        }
        
        return resultList;
    }
    
    public String getIdFromActor(ConnectApi.Actor actor) {
        String strVal = actor.toString();
        return getIdFromUserSummary(strVal);
    }
    
    public String getIdFromUserSummary(String actor) {
        Integer startIdx = actor.indexOf('id=') + 3;
        Integer endIdx = actor.indexOf(',', startIdx);
        return actor.substring(startIdx, endIdx);
    }
    
    public String getFirstNameFromActor(ConnectApi.Actor actor) {
        String strVal = actor.toString();
        Integer startIdx = strVal.indexOf('firstName=') + 10;
        Integer endIdx = strVal.indexOf(',', startIdx);
        return strVal.substring(startIdx, endIdx);
    }
    
    public String getLastNameFromActor(ConnectApi.Actor actor) {
        String strVal = actor.toString();
        Integer startIdx = strVal.indexOf('lastName=') + 9;
        Integer endIdx = strVal.indexOf(',', startIdx);
        String lastName = strVal.substring(startIdx, endIdx);
        if(String.isEmpty(lastName)) {
            return '';
        }
        return lastName.substring(0, 1) + '.';
    }
    
    public boolean userIsStudent(String userId, Map<String, User> userMap) {
        return userMap.containsKey(userId) && STUDENT_PROFILE_TYPE.equals(userMap.get(userId).Profile.name);
    }
    
    public void postMessageToChatter(String message, String question, String feedItemId, String groupId, String communityId, String postStatus) {
        boolean isQuestion = false;
        //String caseId;
        if(question != null && question.equalsIgnoreCase('true')) {
            //caseId = createCase(message);
            isQuestion = true;
        }
        
        String postId;
        if(!feedItemId.equalsIgnoreCase('null')) {
            ConnectApi.comment comment = ConnectApi.ChatterFeeds.postComment(communityId, feedItemId, message);
            checkForQuestionUpdate(comment.id, message);
            postId = comment.id;
        }
        else {
            ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(communityId, ConnectApi.FeedType.Record, groupId, message);
            postId = feedItem.id;
        }
        createCommunityAccessControl(message, postId, isQuestion, groupId);
        if(postStatus != null) {
            updateQuestion(postId, postStatus, message);
        }
    }
    
    private void updateQuestion(String postId, String postStatus, String message) {
        Set<String> postIdSet = new Set<String>();
        if(isFeedItem(postId)) {
            postIdSet.add(postId);
            List<FeedComment> commentList = [SELECT Id FROM FeedComment WHERE FeedItemId = :postId];
            for(FeedComment comment : commentList) {
                postIdSet.add(comment.id);
            }
        }
        else {
            List<FeedItem> feedItemList = [SELECT Id, (SELECT Id FROM FeedComments) FROM FeedItem WHERE Id IN (SELECT FeedItemId FROM FeedComment WHERE Id = :postId)];
            for(FeedItem item : feedItemList) {
                postIdSet.add(item.id);
                for(FeedComment comment : item.FeedComments) {
                    postIdset.add(comment.id);
                }
            }
        }
        
        List<CommunityAccessControl__c> cacList = [SELECT PostStatus__c, MyResponse__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE OriginalPostId__c IN :postIdSet 
                                                      AND RecordType.Name = 'Post'
                                                      AND PostStatus__c IN ('Unanswered', 'Student Responded', 'Waiting for Clarification')];
        for(CommunityAccessControl__c cac : cacList) {
            cac.MyResponse__c = message;
        	cac.PostStatus__c = postStatus;
        }
        update cacList;
    }
    
    public void postFileToChatter(Map<String, String> pageParameters, String fileName, Blob fileBlob, String fileType, 
                                  String fileMessage, String fileQuestion, String fileFeedItemId, String groupId, 
                                  String communityId, String postStatus) 
    {
        System.debug(pageParameters);
        //Get the files from the form if they didn't bind properly...
        if(fileMessage == null) {
        	fileMessage = getFormParam(pageParameters, 'fileMessage');
        }
        if(fileQuestion == null) {
        	fileQuestion = getFormParam(pageParameters, 'fileQuestion');
        }
        if(fileFeedItemId == null) {
        	fileFeedItemId = getFormParam(pageParameters, 'fileFeedItemId');
        }
        if(postStatus == null) {
        	postStatus = getFormParam(pageParameters, 'postStatus');
        }
        
        ConnectApi.NewFileAttachmentInput attachment = new ConnectApi.NewFileAttachmentInput();
        attachment.title = filename;
    
        List<ConnectApi.TextSegmentInput> textSegmentList = new List<ConnectApi.TextSegmentInput>();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = fileMessage;
        textSegmentList.add(textSegment);
        
        ConnectApi.BinaryInput binaryInput = new ConnectApi.BinaryInput(fileBlob, filetype, filename);
        
        boolean isQuestion = false;
        //String caseId;
        if(fileQuestion != null && fileQuestion.equalsIgnoreCase('true')) {
            //caseId = createCase(fileMessage);
            isQuestion = true;
        }
        
        String postId;
        if(!fileFeedItemId.equalsIgnoreCase('null')) {
            ConnectApi.CommentInput input = new ConnectApi.CommentInput();
            input.attachment = attachment;
            input.body = new ConnectApi.MessageBodyInput();
            input.body.messageSegments = textSegmentList;
        
            ConnectApi.Comment comment = ConnectApi.ChatterFeeds.postComment(communityId, fileFeedItemId, input, binaryInput);
            checkForQuestionUpdate(comment.id, fileMessage);
            postId = comment.id;
        }
        else {
            /*ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.attachment = attachment;
            input.body = new ConnectApi.MessageBodyInput();
            input.body.messageSegments = textSegmentList;
        
            ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(getCommunityID(), ConnectApi.FeedType.Record, groupId, input, binaryInput);*/
            
            FeedItem item = new FeedItem();
            item.Body = fileMessage;
            item.ContentData = fileBlob;
            item.ContentFileName = fileName;
            item.Title = fileName;
            item.NetworkScope = communityID;
            item.ParentId = groupId;
            item.Type = 'ContentPost';
            insert item;
            
            postId = item.id;
        }
        createCommunityAccessControl(fileMessage, postId, isQuestion, groupId);
        addFileToGroup(fileName, fileBlob, groupId);
        if(postStatus != null) {
            updateQuestion(fileFeedItemId, postStatus, fileMessage);
        }
    }
    
    private void addFileToGroup(String name, Blob file, String groupId) {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.groupId__c = groupId;
        cac.AdministrationType__c = 'Document';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration'].id;
        insert cac;
        
        Attachment a = new Attachment();
        a.ParentId = cac.id;
        a.name = name;
        a.body = file;
        insert a;
    }
    
    private String getFormParam(Map<String, String> pageParameters, String param) {
        for(String key : pageParameters.keySet()) {
            if(key.endsWith(param)) {
                return pageParameters.get(key);
            }
        }
        return null;
    }
    
    public void postLinkToChatter(String message, String linkUrl, String linkTitle, String question, String feedItemId, String groupId, String communityId) {
        ConnectApi.LinkAttachmentInput attachment = new ConnectApi.LinkAttachmentInput();
        attachment.url = linkUrl;
        attachment.urlName = linkTitle;
    
        List<ConnectApi.TextSegmentInput> textSegmentList = new List<ConnectApi.TextSegmentInput>();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = message;
        textSegmentList.add(textSegment);
        
        boolean isQuestion = false;
        //String caseId;
        if(question != null && question.equalsIgnoreCase('true')) {
            //caseId = createCase(message);
            isQuestion = true;
        }
        
        String postId;
        if(!feedItemId.equalsIgnoreCase('null')) {
            ConnectApi.CommentInput input = new ConnectApi.CommentInput();
            input.attachment = attachment;
            input.body = new ConnectApi.MessageBodyInput();
            input.body.messageSegments = textSegmentList;
        
            ConnectApi.Comment comment = ConnectApi.ChatterFeeds.postComment(communityID, feedItemId, input, null);
            checkForQuestionUpdate(comment.id, message);
            postId = comment.id;
        }
        else {
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.attachment = attachment;
            input.body = new ConnectApi.MessageBodyInput();
            input.body.messageSegments = textSegmentList;
        
            ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(communityID, ConnectApi.FeedType.Record, groupId, input, null);
            postId = feedItem.id;
        }
        createCommunityAccessControl(message, postId, isQuestion, groupId);
    }
    
    private void createCommunityAccessControl(String postText, String feedItemId, Boolean isQuestion, String groupId) {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.originalPostId__c = feedItemId;
        cac.GroupId__c = groupId;
        if(isQuestion) {
            cac.postStatus__c = 'Unanswered';
            cac.question__c = postText;
            //cac.CaseId__c = caseId;
        }
        else {
            cac.postStatus__c = 'Comment';
        }
        
        if(isFeedItem(feedItemId)) {
            cac.PostType__c = 'Post';
        }
        else {
            cac.PostType__c = 'Comment';
        }
        
        String userId = UserInfo.getUserId();
        User user = [SELECT contactId FROM User WHERE id = :userId];
        cac.student__c = user.contactId;
        cac.recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Post' AND SobjectType = 'CommunityAccessControl__c'].id;
        insert cac;
    }
    
    private boolean isFeedItem(String itemId) {
        String objectAPIName = Id.valueOf(itemId).getSObjectType().getDescribe().getName();
        if(objectAPIName == 'FeedItem') {
            return true;
        }
        return false;
    }
    
    /*private String createCase(String message) {
        Case newCase = new Case ( 
                    Subject = 'Course Chatter Question',
                    Status = 'New',
                    Priority = 'Medium',
                    Origin = 'Web',
                    Description = message,
                    RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Admin' AND SobjectType = 'Case'].Id
                );
                
        insert newCase;
        return newCase.id;
    }*/
    
    public static void checkForQuestionUpdate(String commentId, String message) {
        String userId = UserInfo.getUserId();
        List<FeedItem> feedItemList = [SELECT id, InsertedById, (SELECT id, InsertedById FROM FeedComments) FROM FeedItem WHERE id IN (SELECT feeditemid FROM FeedComment WHERE id = :commentId)];
        Set<String> userPostedSet = new Set<String>();
        for(FeedItem item : feedItemList) {
            for(FeedComment comment : item.FeedComments) {
                if(comment.insertedById == userId) {
                    userPostedSet.add(comment.id);
                }
            }
            if(item.insertedById == userId) {
                userPostedSet.add(item.id);
            }
        }
        
        List<CommunityAccessControl__c> clarificationList = [SELECT OriginalPostId__c
                                                               FROM CommunityAccessControl__c 
                                                              WHERE OriginalPostId__c IN :userPostedSet
                                                                AND PostStatus__c = 'Waiting for Clarification'];
        
        List<CommunityAccessControl__c> cacList = new List<CommunityAccessControl__c>(); 
        for(CommunityAccessControl__c cac : clarificationList) {
            cac.PostStatus__c = 'Student Responded';
            cac.StudentResponse__c = message;
            cacList.add(cac);
        }
        update cacList;
    }
    
    public class CommunityException extends Exception {}
    
    private class CommentComparable implements Comparable {
        
        private ConnectApi.Comment comment;
        
        public CommentComparable(ConnectApi.Comment comment) {
        	this.comment = comment;
        }
        
        public Integer compareTo(Object obj2) {
    		ConnectApi.Comment comment2 = ((CommentComparable)obj2).comment;
            if(comment.createdDate > comment2.createdDate) {
                return 1;
            }
            else if(comment.createdDate < comment2.createdDate) {
                return -1;
            }
            return 0;
		}
        
    }
    
}