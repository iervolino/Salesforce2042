@IsTest
public class CommonsChatterManagementControlTest{

    @IsTest static void getGroupOptionsTest() {
        Map<String, String> groupMap = new Map<String, String>();
        groupMap.put('1', 'AAAA');
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupMap = groupMap;
        Test.startTest();
        List<SelectOption> resultList = control.getGroupOptions();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('1', resultList.get(0).getValue());
        System.assertEquals('AAAA', resultList.get(0).getLabel());
    }
    
    @IsTest static void getSelectedGroupNameTest_Null() {
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        Test.startTest();
        String result = control.getSelectedGroupName();
        Test.stopTest();
        
        System.assertEquals(null, result);
    }
    
    @IsTest static void getSelectedGroupNameTest() {
        Map<String, String> groupMap = new Map<String, String>();
        groupMap.put('1', 'AAAA');        
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupMap = groupMap;
        control.groupId = '1';
        Test.startTest();
        String result = control.getSelectedGroupName();
        Test.stopTest();
        
        System.assertEquals('AAAA', result);
    }
    
    @IsTest static void getUnansweredQuestionCountTest_Null() {
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        Test.startTest();
        Integer result = control.getUnansweredQuestionCount();
        Test.stopTest();
        
        System.assertEquals(null, result);
    }
    
    @IsTest static void getUnansweredQuestionCountTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.groupId__c = '1';
        cac.PostStatus__c = 'Unanswered';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Post' AND SobjectType = 'CommunityAccessControl__c'].id;
        insert cac;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        Test.startTest();
        Integer result = control.getUnansweredQuestionCount();
        Test.stopTest();
        
        System.assertEquals(1, result);
    }
    
    @IsTest static void getCourseCommunityAnnouncementsTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.groupId__c = '1';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND SobjectType = 'CommunityAccessControl__c'].id;
        cac.MyResponse__c = 'This is an announcement';
        cac.AdministrationType__c = 'Announcement';
        cac.DateAnnouncementExpires__c = System.today().addDays(5);
        insert cac;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        Test.startTest();
        List<CommonsChatterManagementControl.CourseCommunitiesAnnouncementOrTip> resultList = control.getCourseCommunityAnnouncements();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is an announcement', resultList.get(0).announcementOrTip.MyResponse__c);
    }
    
    @IsTest static void getCourseCommunityQuickTipsTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.groupId__c = '1';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND SobjectType = 'CommunityAccessControl__c'].id;
        cac.MyResponse__c = 'This is a tip';
        cac.AdministrationType__c = 'Quick Tip';
        cac.DateAnnouncementExpires__c = System.today().addDays(5);
        insert cac;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        Test.startTest();
        List<CommonsChatterManagementControl.CourseCommunitiesAnnouncementOrTip> resultList = control.getCourseCommunityQuickTips();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is a tip', resultList.get(0).announcementOrTip.MyResponse__c);
    }
    
    @IsTest static void editAdminCommunityAccessControlTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.groupId__c = '1';
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND SobjectType = 'CommunityAccessControl__c'].id;
        cac.MyResponse__c = 'This is a tip';
        cac.AdministrationType__c = 'Quick Tip';
        insert cac;
        
        ApexPages.currentPage().getParameters().put('itemId', String.valueOf(cac.id));
        ApexPages.currentPage().getParameters().put('updatedMessage', 'This is an updated tip');
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        Test.startTest();
        control.editAdminCommunityAccessControl();
        Test.stopTest();
        
        List<CommunityAccessControl__c> resultList = [SELECT MyResponse__c 
                                                        FROM CommunityAccessControl__c 
                                                       WHERE GroupId__c = '1' 
                                                         AND RecordType.Name = 'Community Administration' 
                                                         AND AdministrationType__c = 'Quick Tip'];
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is an updated tip', resultList.get(0).MyResponse__c);
    }
    
    @IsTest static void createAdminCommunityAccessControlTest() {
        ApexPages.currentPage().getParameters().put('message', 'This is a tip');
        ApexPages.currentPage().getParameters().put('adminType', 'Quick Tip');
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        Test.startTest();
        control.createAdminCommunityAccessControl();
        Test.stopTest();
        
        List<CommunityAccessControl__c> resultList = [SELECT MyResponse__c 
                                                        FROM CommunityAccessControl__c 
                                                       WHERE GroupId__c = '1' 
                                                         AND RecordType.Name = 'Community Administration' 
                                                         AND AdministrationType__c = 'Quick Tip'];
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is a tip', resultList.get(0).MyResponse__c);
    }

    @IsTest static void createAnnouncementTest() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;

        ApexPages.currentPage().getParameters().put('message', 'This is an announcement');
        ApexPages.currentPage().getParameters().put('adminType', 'Announcement');
        ApexPages.currentPage().getParameters().put('numberOfDaysToExpiration', '5');
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = testGroup.id;
        Test.startTest();
        control.createAdminCommunityAccessControl();
        Test.stopTest();
        
        List<CommunityAccessControl__c> resultList = [SELECT Id, MyResponse__c, DateAnnouncementExpires__c
                                                        FROM CommunityAccessControl__c 
                                                       WHERE GroupId__c = :testGroup.id 
                                                         AND RecordType.Name = 'Community Administration' 
                                                         AND AdministrationType__c = 'Announcement'];
        
        System.assertEquals(1, resultList.size());

        CommunityAccessControl__c result = resultList.get(0);

        System.assertEquals('This is an announcement', result.MyResponse__c);
        System.assertEquals(System.today().addDays(5), result.DateAnnouncementExpires__c);

        //By default the user running the test is the only member of the group
        List<CommunityAccessControl__c> studentAnnouncementRecords = [SELECT Id 
                                                                        FROM CommunityAccessControl__c 
                                                                       WHERE StudentUser__c = :UserInfo.getUserId()
                                                                         AND RecordType.Name = 'Course Announcement'
                                                                         AND AnnouncementRecord__c = :result.id
                                                                         AND ViewedByStudent__c = false];
        System.assertEquals(1, studentAnnouncementRecords.size());
    }
    
    @IsTest(SeeAllData=true) static void getCommunityAccessControlListUnansweredTest_FeedItemIsAQuestion() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a test post');
        ConnectApi.Comment comment = ConnectApi.ChatterFeeds.postComment(networkId, feedItem.id, 'This is a test comment');
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.OriginalPostId__c = feeditem.id;
        cac.PostStatus__c = 'Unanswered';
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Post' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac.GroupId__c = testGroup.id;
        insert cac;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = testGroup.id;
        Test.startTest();
        List<CommonsCommunityManagementControlResult> resultList = control.getCommunityAccessControlListUnanswered();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is a test post', resultList.get(0).feedItem.feedItem.body.text);
        System.assertEquals('This is a test comment', resultList.get(0).feedItem.commentList.get(0).comment.body.text);
    }
    
    @IsTest(SeeAllData=true) static void getCommunityAccessControlListUnansweredTest_FeedCommentIsAQuestion() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a test post');
        ConnectApi.Comment comment = ConnectApi.ChatterFeeds.postComment(networkId, feedItem.id, 'This is a test comment');
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.OriginalPostId__c = comment.id;
        cac.PostStatus__c = 'Unanswered';
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Post' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac.GroupId__c = testGroup.id;
        insert cac;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = testGroup.id;
        Test.startTest();
        List<CommonsCommunityManagementControlResult> resultList = control.getCommunityAccessControlListUnanswered();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is a test post', resultList.get(0).feedItem.feedItem.body.text);
        System.assertEquals('This is a test comment', resultList.get(0).feedItem.commentList.get(0).comment.body.text);
    }
    
    @IsTest(SeeAllData=true) static void getCommunityAccessControlListUnansweredTest_FeedItemAndCommentIsAQuestion() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a test post');
        ConnectApi.Comment comment = ConnectApi.ChatterFeeds.postComment(networkId, feedItem.id, 'This is a test comment');
        
        CommunityAccessControl__c cac2 = new CommunityAccessControl__c();
        cac2.OriginalPostId__c = feedItem.id;
        cac2.PostStatus__c = 'Unanswered';
        cac2.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Post' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac2.GroupId__c = testGroup.id;
        insert cac2;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.OriginalPostId__c = comment.id;
        cac.PostStatus__c = 'Unanswered';
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Post' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac.GroupId__c = testGroup.id;
        insert cac;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = testGroup.id;
        Test.startTest();
        List<CommonsCommunityManagementControlResult> resultList = control.getCommunityAccessControlListUnanswered();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('This is a test post', resultList.get(0).feedItem.feedItem.body.text);
        System.assertEquals('This is a test comment', resultList.get(0).feedItem.commentList.get(0).comment.body.text);
    }
    
    @IsTest static void getFilesForGroupTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac.GroupId__c = '1';
        cac.AdministrationType__c = 'Document';
        insert cac;
        
		Attachment att = new Attachment();
        att.name = 'Test attachment';
        att.parentId = cac.id;
        att.body = Blob.valueOf('Test file content');
        insert att;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        
        Test.startTest();
        List<CommunityAccessControl__c> resultList = control.getFilesForGroup();
        Test.stopTest();
        
        System.assertEquals(1, resultList.size());
        System.assertEquals('Test attachment', resultList.get(0).attachments.get(0).name);
    }
    
    @IsTest(SeeAllData=true) static void postFileToChatterTest() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a post.');
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.PostStatus__c = 'Unanswered';
        cac.GroupId__c = testGroup.id;
        cac.OriginalPostId__c = feedItem.id;
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Post' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert cac;
        
        CommonsChatterManagementControl controller = new CommonsChatterManagementControl();
        controller.groupId = testGroup.Id;
        
        controller.fileBlob = Blob.valueOf('This is some text for the blob');
        controller.fileName = 'Test.txt';
        controller.fileType = 'text/plain';
        controller.fileSize = 30;
        controller.fileMessage = 'This is a test message.';
    	controller.fileFeedItemId = feedItem.id;
        controller.postStatus = 'Mentor Satisfied';
        
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
        
        List<CommunityAccessControl__c> cacList = [SELECT PostStatus__c FROM CommunityAccessControl__c WHERE id = :cac.id];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Mentor Satisfied', cacList.get(0).PostStatus__c);
    }
    
    @IsTest(SeeAllData=true) static void postMessageToChatterTest() {
        String networkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = networkId;
        insert testGroup;
        
        ConnectApi.FeedItem feedItem = ConnectApi.ChatterFeeds.postFeedItem(networkId, ConnectApi.FeedType.Record, testGroup.id, 'This is a post.');
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.PostStatus__c = 'Unanswered';
        cac.GroupId__c = testGroup.id;
        cac.OriginalPostId__c = feedItem.id;
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Post' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert cac;
        
        ApexPages.currentPage().getParameters().put('message', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('question', 'false');
        ApexPages.currentPage().getParameters().put('feedItemId', feedItem.id);
        ApexPages.currentPage().getParameters().put('postStatus', 'Mentor Satisfied');
        
        CommonsChatterManagementControl controller = new CommonsChatterManagementControl();
        controller.groupId = testGroup.Id;
        
        Test.startTest();
        controller.postMessageToChatter();
        Test.stopTest();
        
        List<FeedItem> feedItemList = [SELECT Id, (SELECT CommentBody FROM FeedComments) FROM FeedItem WHERE ParentId = :testGroup.Id];
        System.assertEquals(1, feedItemList.size());
        System.assertEquals(1, feedItemList.get(0).FeedComments.size());
        System.assertEquals('This is a test message.', feedItemList.get(0).FeedComments.get(0).CommentBody);
        
        List<CommunityAccessControl__c> cacList = [SELECT PostStatus__c FROM CommunityAccessControl__c WHERE id = :cac.id];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Mentor Satisfied', cacList.get(0).PostStatus__c);
    }
    
    @IsTest static void deleteCommunityAccessControlTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac.GroupId__c = '1';
        cac.AdministrationType__c = 'Document';
        insert cac;
        
		Attachment att = new Attachment();
        att.name = 'Test attachment';
        att.parentId = cac.id;
        att.body = Blob.valueOf('Test file content');
        insert att;
        
        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', String.valueOf(cac.id));
        control.deleteCommunityAccessControl();
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT id FROM CommunityAccessControl__c WHERE id = :cac.id];
        System.assertEquals(0, cacList.size());
    }

    @IsTest static void renewCourseTipTest() {
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        cac.GroupId__c = '1';
        cac.AdministrationType__c = 'Quick Tip';
        cac.DateAnnouncementExpires__c = System.today().addDays(3);
        insert cac;

        CommonsChatterManagementControl control = new CommonsChatterManagementControl();
        control.groupId = '1';

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', String.valueOf(cac.id));
        control.renewCourseTip();
        Test.stopTest();

        List<CommunityAccessControl__c> tip1List = [SELECT Id, DateAnnouncementExpires__c
                                                      FROM CommunityAccessControl__c 
                                                     WHERE id = :cac.id];
        System.assertEquals(System.today().addDays(-1), tip1List.get(0).DateAnnouncementExpires__c);

        List<CommunityAccessControl__c> tip2List = [SELECT Id, DateAnnouncementExpires__c
                                                      FROM CommunityAccessControl__c 
                                                     WHERE id != :cac.id];
        System.assertEquals(1, tip2List.size());
    }

    @IsTest static void validateHelperMethodsOnCourseCommunitiesAnnouncementOrTip() {
        CommunityAccessControl__c tipCac = new CommunityAccessControl__c();
        tipCac.DateAnnouncementExpires__c = System.today().addDays(6);
        tipCac.AdministrationType__c = 'Quick Tip';

        CommonsChatterManagementControl.CourseCommunitiesAnnouncementOrTip tip = new CommonsChatterManagementControl.CourseCommunitiesAnnouncementOrTip(tipCac);
        System.assertEquals(6, tip.getDaysToExpiration());
        System.assertEquals(1, tip.getDaysToRenewalEligibility());
        System.assertEquals(false, tip.getEligibleForRenewal());
        System.assertEquals(datetime.newInstance(System.today().addDays(6), time.newInstance(0,0,0,0)).format('MM/dd/yyyy'),
            tip.getMMDDYYYYFormattedExpirationDate());
        System.assertEquals(datetime.newInstance(System.today().addDays(6), time.newInstance(0,0,0,0)).format('yyyy-MM-dd'),
            tip.getYYYYMMDDFormattedExpirationDate());

        tipCac.DateAnnouncementExpires__c = System.today().addDays(1);
        System.assertEquals(true, tip.getEligibleForRenewal());

        //Also checking for null DateAnnouncementExpires__c
        CommunityAccessControl__c announcementCac = new CommunityAccessControl__c();
        announcementCac.AdministrationType__c = 'Announcement';

        CommonsChatterManagementControl.CourseCommunitiesAnnouncementOrTip announcement = new CommonsChatterManagementControl.CourseCommunitiesAnnouncementOrTip(announcementCac);
        System.assertEquals(false, announcement.getEligibleForRenewal());
        System.assertEquals(null, announcement.getDaysToExpiration());
        System.assertEquals(null, announcement.getDaysToRenewalEligibility());
        System.assertEquals(null, announcement.getMMDDYYYYFormattedExpirationDate());
        System.assertEquals(null, announcement.getYYYYMMDDFormattedExpirationDate());
    }
    
}