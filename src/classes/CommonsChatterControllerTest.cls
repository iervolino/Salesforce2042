@IsTest
public class CommonsChatterControllerTest {

    @IsTest static void getFeedItemsWithUserTypeTest_GroupIdNotSet() {
        CommonsChatterController controller = new CommonsChatterController();
        Test.startTest();
        List<FeedItemWithUserType> resultList = controller.getFeedItemsWithUserType();
        System.assertEquals(null, resultList);
        Test.stopTest();
    }
    
    @IsTest(SeeAllData=true) static void getFeedItemsWithUserTypeTest() {
        User user = [SELECT id FROM User WHERE Profile.name = 'Student Profile' LIMIT 1];
        
        ConnectApi.FeedItemPage feedItemPage = new ConnectApi.FeedItemPage();
        List<ConnectApi.FeedItem> itemList = new List<ConnectApi.FeedItem>();
        ConnectApi.FeedItem feedItem = new ConnectApi.FeedItem();
        ConnectApi.UserSummary userSummary = new ConnectApi.UserSummary();
        userSummary.id = user.id;
        feedItem.actor = userSummary;
        ConnectApi.FeedBody feedBody = new ConnectApi.FeedBody();
        feedBody.text  = 'This is the feed body.';
        feedItem.body = feedBody;
        
        ConnectApi.CommentPage commentPage = new ConnectApi.CommentPage();
        List<ConnectApi.Comment> commentList = new List<ConnectApi.Comment>();
        ConnectApi.Comment comment = new ConnectApi.Comment();
        ConnectApi.FeedBody commentBody = new ConnectApi.FeedBody();
        commentBody.text = 'This is a comment';
        comment.body = commentBody;
        comment.user = userSummary;
        commentList.add(comment);
        commentPage.comments = commentList;
        feedItem.comments = commentPage;
        
        itemList.add(feedItem);
        feedItemPage.items = itemList;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = UserInfo.getUserId();//User id will work for the purpose of the unit test
        ConnectApi.ChatterFeeds.setTestGetFeedItemsFromFeed(controller.getCommunityId(), 
                   ConnectApi.FeedType.Record, UserInfo.getUserId(), feedItemPage);
                   
        Test.startTest();
        List<FeedItemWithUserType> resultList = controller.getFeedItemsWithUserType();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        
        FeedItemWithUserType result = resultList.get(0);
        System.assertEquals(true, result.isStudent);
        System.assertEquals('This is the feed body.', result.shortenedFeedBody);
        System.assertEquals(true, result.commentList.get(0).isStudent);        
    }
    
    @IsTest static void getGroupMembers_NullGroupId() {
        CommonsChatterController controller = new CommonsChatterController();
        System.assertEquals(null, controller.getGroupMembers());
    }
    
    @IsTest(SeeAllData=true) static void getGroupMembers() {
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group  asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        insert testGroup;

        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = testGroup.Id;
        cac.StudentUser__c = UserInfo.getUserId();
        cac.CommunityStatus__c = 'Contributor';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert cac;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.id;
        System.assertEquals(1, controller.getGroupMembers().size());
    }

    @IsTest static void getSelectedGroupNameTest_NullGroupId() {
        CommonsChatterController controller = new CommonsChatterController();
        System.assertEquals(null, controller.getSelectedGroupName());
    }
    
    @IsTest static void getFilesForGroupTest_NullGroupId() {
        CommonsChatterController controller = new CommonsChatterController();
        System.assertEquals(null, controller.getFilesForGroup());
    }
    
    @IsTest static void getFilesForGroupTest() {
        String userId = UserInfo.getUserId(); //The users ID will work as a substitute for a group
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = userId;
        cac.AdministrationType__c = 'Document';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration'].id;
        insert cac;
        
        Blob b = Blob.valueOf('a');
        Attachment a = new Attachment();
        a.ParentId = cac.id;
        a.Name = 'file.txt';
        a.Body = b;
        insert a;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = userId;
        Test.startTest();
        List<CommunityAccessControl__c> resultList = controller.getFilesForGroup();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals(a.id, resultList.get(0).Attachments[0].id);
    }

    @IsTest(SeeAllData=true) static void postMessageToChatterTest_PostQuestion() {
        ApexPages.currentPage().getParameters().put('message', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('question', 'true');
        ApexPages.currentPage().getParameters().put('feedItemId', 'null');
        
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        insert testGroup;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        Test.startTest();
        controller.postMessageToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, Body FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).Body);
        
        List<CommunityAccessControl__c> cacList = [SELECT Id, PostStatus__c, CaseId__c, Question__c FROM CommunityAccessControl__c WHERE GroupId__c = :testGroup.Id AND RecordType.Name = 'Post'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Unanswered', cacList.get(0).PostStatus__c);
        System.assertEquals('This is a test message.', cacList.get(0).Question__c);
        
        /*Case c = [SELECT Description FROM Case WHERE Id = :cacList.get(0).CaseId__c];
        System.assertEquals('This is a test message.', c.Description);*/
    }
    
    @IsTest(SeeAllData=true) static void postMessageToChatterTest_PostComment() {
        ApexPages.currentPage().getParameters().put('message', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('question', 'false');
        ApexPages.currentPage().getParameters().put('feedItemId', 'null');
        
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        insert testGroup;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        Test.startTest();
        controller.postMessageToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, Body FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).Body);
        
        List<CommunityAccessControl__c> cacList = [SELECT Id, PostStatus__c, CaseId__c, Question__c FROM CommunityAccessControl__c WHERE GroupId__c = :testGroup.Id AND RecordType.Name = 'Post'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Comment', cacList.get(0).PostStatus__c);
        System.assertEquals(null, cacList.get(0).Question__c);
        System.assertEquals(null, cacList.get(0).CaseId__c);
    }
    
    @IsTest(SeeAllData=true) static void postMessageToChatterTest_Comment() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a post.');
        
        ApexPages.currentPage().getParameters().put('message', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('question', 'false');
        ApexPages.currentPage().getParameters().put('feedItemId', feedItem.id);
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        Test.startTest();
        controller.postMessageToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, (SELECT CommentBody FROM FeedComments) FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals(1, feedItemList.get(0).FeedComments.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).FeedComments.get(0).CommentBody);
    }
    
    @IsTest(SeeAllData=true) static void postLinkToChatterTest_PostQuestion() {
        ApexPages.currentPage().getParameters().put('message', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('question', 'true');
        ApexPages.currentPage().getParameters().put('feedItemId', 'null');
        ApexPages.currentPage().getParameters().put('linkUrl', 'http://www.google.com');
        ApexPages.currentPage().getParameters().put('linkTitle', 'Google');
        
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        Test.startTest();
        controller.postLinkToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, Body, LinkUrl, Title FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).Body);
        System.assertEquals('http://www.google.com', feedItemList.get(0).LinkUrl);
        System.assertEquals('Google', feedItemList.get(0).Title);
        
        List<CommunityAccessControl__c> cacList = [SELECT Id, PostStatus__c, CaseId__c, Question__c FROM CommunityAccessControl__c WHERE GroupId__c = :testGroup.Id AND RecordType.Name = 'Post'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Unanswered', cacList.get(0).PostStatus__c);
        System.assertEquals('This is a test message.', cacList.get(0).Question__c);

        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.getFeedItem(networkId, feedItemList.get(0).Id);
        FeedItemWithUserType item = new FeedItemWithUserType(feedItem, null, null, null, null, null, null, null);
        System.assertEquals(feedItem.createdDate.format('MM/dd/yy \'at\' hh:mm a'), item.getFormattedPostTime());
        System.assertEquals('link', item.getAttachmentType());
        System.assertEquals(false, item.getHasPreview());
        System.assertEquals('http://www.google.com', item.getLinkAttachment().url);
        System.assertEquals('Google', item.getLinkAttachment().title);

        /*Case c = [SELECT Description FROM Case WHERE Id = :cacList.get(0).CaseId__c];
        System.assertEquals('This is a test message.', c.Description);*/
    }
    
    @IsTest(SeeAllData=true) static void postFileToChatterTest_PostQuestion() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        controller.fileBlob = Blob.valueOf('This is some text for the blob');
        controller.fileName = 'Test.txt';
        controller.fileType = 'text/plain';
        controller.fileSize = 30;
        controller.fileMessage = 'This is a test message.';
        controller.fileQuestion = 'true';
        controller.fileFeedItemId = 'null';
        
        Test.startTest();
        controller.postFileToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, Body, ContentData, ContentFileName, ContentType FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).Body);
        System.assertEquals(true, feedItemList.get(0).ContentData != null);
        System.assertEquals('Test.txt', feedItemList.get(0).ContentFileName);
        System.assertEquals('text/plain', feedItemList.get(0).ContentType);
        
        List<CommunityAccessControl__c> cacList = [SELECT Id, PostStatus__c, CaseId__c, Question__c FROM CommunityAccessControl__c WHERE GroupId__c = :testGroup.Id AND RecordType.Name = 'Post'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Unanswered', cacList.get(0).PostStatus__c);
        System.assertEquals('This is a test message.', cacList.get(0).Question__c);

        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.getFeedItem(networkId, feedItemList.get(0).Id);
        FeedItemWithUserType item = new FeedItemWithUserType(feedItem, null, null, null, null, null, null, null);
        System.assertEquals(feedItem.createdDate.format('MM/dd/yy \'at\' hh:mm a'), item.getFormattedPostTime());
        System.assertEquals('file', item.getAttachmentType());
        System.assertEquals(false, item.getHasPreview());
        System.assertEquals('30 B', item.getHumanReadableFileSize());

        /*Case c = [SELECT Description FROM Case WHERE Id = :cacList.get(0).CaseId__c];
        System.assertEquals('This is a test message.', c.Description);*/
    }
    
    @IsTest(SeeAllData=true) static void postFileToChatterTest_PostCommentWithNestedFix() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        controller.fileBlob = Blob.valueOf('This is some text for the blob');
        controller.fileName = 'Test.txt';
        controller.fileType = 'text/plain';
        controller.fileSize = 30;
        
        ApexPages.currentPage().getParameters().put('fileMessage', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('fileQuestion', 'false');
        ApexPages.currentPage().getParameters().put('fileFeedItemId', 'null');
        
        Test.startTest();
        controller.postFileToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, Body, ContentData, ContentFileName, ContentType FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).Body);
        System.assertEquals(true, feedItemList.get(0).ContentData != null);
        System.assertEquals('Test.txt', feedItemList.get(0).ContentFileName);
        System.assertEquals('text/plain', feedItemList.get(0).ContentType);
        
        List<CommunityAccessControl__c> cacList = [SELECT Id, PostStatus__c, CaseId__c, Question__c FROM CommunityAccessControl__c WHERE GroupId__c = :testGroup.Id AND RecordType.Name = 'Post'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Comment', cacList.get(0).PostStatus__c);
    }
    
    @IsTest(SeeAllData=true) static void postFileToChatterTest_Comment() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a post.');
        
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = testGroup.Id;
        
        controller.fileBlob = Blob.valueOf('This is some text for the blob');
        controller.fileName = 'Test.txt';
        controller.fileType = 'text/plain';
        controller.fileSize = 30;
        controller.fileMessage = 'This is a test message.';
        controller.fileQuestion = 'false';
        controller.fileFeedItemId = feedItem.id;
        
        Test.startTest();
        controller.postFileToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, (SELECT CommentBody, RelatedRecordId FROM FeedComments) FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals(1, feedItemList.get(0).FeedComments.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).FeedComments.get(0).CommentBody);
        
        String relatedRecordId = feedItemList.get(0).FeedComments.get(0).RelatedRecordId;
        ContentVersion content = [SELECT Title FROM ContentVersion WHERE Id = :relatedRecordId];
        System.assertEquals('Test.txt', content.Title);

        ConnectApi.Comment comment = ConnectApi.ChatterFeeds.getComment(networkId, feedItemList.get(0).FeedComments.get(0).Id);
        CommentWithUserType item = new CommentWithUserType(comment, null, null, null);
        System.assertEquals(comment.createdDate.format('MM/dd/yy \'at\' hh:mm a'), item.getFormattedPostTime());
        System.assert(item.getContentAttachment() != null, 'Content attachment must not be null');
        System.assertEquals(false, item.getHasPreview());
        System.assertEquals('30 B', item.getHumanReadableFileSize());
    }
    
    @IsTest static void isReadOnlyTest_NoGroupId() {
        CommonsChatterController controller = new CommonsChatterController();
        Test.startTest();
        boolean result = controller.getIsReadOnly();
        Test.stopTest();
        System.assertEquals(true, result);
    }
    
    @IsTest static void isReadOnlyTest_NoGroupCac() {
        CommonsChatterController controller = new CommonsChatterController();
        controller.groupId = 'bogus';
        Test.startTest();
        boolean result = controller.getIsReadOnly();
        Test.stopTest();
        System.assertEquals(true, result);
    }
    
    @IsTest static void isReadOnlyTest_True() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        CollaborationGroup newGroup = setupGroup(networkId);
        
        User u = ([SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1]);
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.Id;
        groupMember.MemberId = u.Id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.CommunityStatus__c = 'Viewer';
        cac.StudentUser__c = u.Id;
        cac.GroupId__c = newGroup.Id;
        cac.CommunityId__c = networkId;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access'].id;
        insert cac;
        
        System.runAs(u) {
            CommonsChatterController controller = new CommonsChatterController();
            controller.groupId = newGroup.id;
            Test.startTest();
            boolean result = controller.getIsReadOnly();
            Test.stopTest();
            System.assertEquals(true, result);
        }
    }
    
    @IsTest static void isReadOnlyTest_False() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        CollaborationGroup newGroup = setupGroup(networkId);
        
        User u = ([SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1]);
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.Id;
        groupMember.MemberId = u.Id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.CommunityStatus__c = 'Contributor';
        cac.StudentUser__c = u.Id;
        cac.GroupId__c = newGroup.Id;
        cac.CommunityId__c = networkId;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access'].id;
        insert cac;
        
        System.runAs(u) {
            CommonsChatterController controller = new CommonsChatterController();
            controller.groupId = newGroup.id;
            Test.startTest();
            boolean result = controller.getIsReadOnly();
            Test.stopTest();
            System.assertEquals(false, result);
        }
    }
    
    private static CollaborationGroup setupGroup(String networkId) {
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        return newGroup;
    }
    
}