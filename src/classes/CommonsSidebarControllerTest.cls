@IsTest
public class CommonsSidebarControllerTest {

    @IsTest(SeeAllData=true) static void gettingGroupFromCourseCodeParamTest() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        
        System.runAs(u) {
            Test.startTest();
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            Test.stopTest();
            System.assertEquals(groupId, controller.groupId);
        }
    }

    @IsTest(SeeAllData=true) static void gettingGroupFromCourseCodeParamTest_UserNotPartOfChatterGroup() {
        String groupId = setupGroup();
        setupCourseAndAssignment(groupId);
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        
        System.runAs(u) {
            Test.startTest();
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            Test.stopTest();
            System.assertEquals(groupId, controller.groupId);
        }
    }
    
    @IsTest(SeeAllData=true) static void gettingGroupFromGroupIdParamTest() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        
        System.runAs(u) {
            Test.startTest();
            ApexPages.currentPage().getParameters().put('groupId', groupId);
            CommonsSidebarController controller = new CommonsSidebarController();
            Test.stopTest();
            System.assertEquals(groupId, controller.groupId);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityAnnouncementWithLimitTest_ValidGroup() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        setupCac(groupId, 'Announcement', 'This is an announcement.');
            
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityAnnouncementWithLimit();
            Test.stopTest();
            
            System.assertEquals(1, resultList.size());
            System.assertEquals(0, controller.remainingAnnouncements);
            System.assertEquals('This is an announcement.', resultList.get(0).MyResponse__c);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityAnnouncementWithLimitTest_AnnouncementsOverLimit() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityAnnouncementWithLimit();
            Test.stopTest();
            
            System.assertEquals(3, resultList.size());
            System.assertEquals(1, controller.remainingAnnouncements);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityAnnouncementTest() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        setupCac(groupId, 'Announcement', 'This is an announcement.');
        
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityAnnouncement();
            Test.stopTest();
            
            System.assertEquals(4, resultList.size());
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityAnnouncementWithLimitTest_NoGroup() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
            
        System.runAs(u) {
            CommonsSidebarController controller = new CommonsSidebarController();
            controller.groupId = null;
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityAnnouncementWithLimit();
            Test.stopTest();
            
            System.assertEquals(null, resultList);
            System.assertEquals(0, controller.remainingAnnouncements);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityAnnouncement_NoGroup() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
            
        System.runAs(u) {
            CommonsSidebarController controller = new CommonsSidebarController();
            controller.groupId = null;
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityAnnouncement();
            Test.stopTest();
            
            System.assertEquals(null, resultList);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityQuickTipWithLimitTest_ValidGroup() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
            
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityQuickTipWithLimit();
            Test.stopTest();
            
            System.assertEquals(1, resultList.size());
            System.assertEquals(0, controller.remainingQuickTips);
            System.assertEquals('This is a quick tip.', resultList.get(0).MyResponse__c);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityQuickTipWithLimitTest_QuickTipsOverLimit() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
            
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityQuickTipWithLimit();
            Test.stopTest();
            
            System.assertEquals(3, resultList.size());
            System.assertEquals(1, controller.remainingQuickTips);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityQuickTipTest() {
        String groupId = setupGroup();
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        addUserToGroup(groupId, u.id);
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
        setupCac(groupId, 'Quick Tip', 'This is a quick tip.');
            
        System.runAs(u) {
            ApexPages.currentPage().getParameters().put('code', 'AAAA');
            CommonsSidebarController controller = new CommonsSidebarController();
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityQuickTip();
            Test.stopTest();
            
            System.assertEquals(4, resultList.size());
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityQuickTipWithLimitTest_NoGroup() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
            
        System.runAs(u) {
            CommonsSidebarController controller = new CommonsSidebarController();
            controller.groupId = null;
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityQuickTipWithLimit();
            Test.stopTest();
            
            System.assertEquals(null, resultList);
            System.assertEquals(0, controller.remainingQuickTips);
        }
    }
    
    @IsTest(SeeAllData=true) static void getCourseCommunityQuickTip_NoGroup() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
            
        System.runAs(u) {
            CommonsSidebarController controller = new CommonsSidebarController();
            controller.groupId = null;
            
            Test.startTest();
            List<CommunityAccessControl__c> resultList = controller.getCourseCommunityQuickTip();
            Test.stopTest();
            
            System.assertEquals(null, resultList);
        }
    }

    @IsTest(SeeAllData=true) static void markAnnouncementsAsViewed() {
        String groupId = setupGroup();
        setupUnviewedAnnouncementForUser(groupId);
        CommonsSidebarController controller = new CommonsSidebarController();
        controller.groupId = groupId;

        Test.startTest();
        controller.markAnnouncementsAsViewed();
        Test.stopTest();

        System.assertEquals(0, controller.getUnviewedAnnouncementCount());
    }

    @IsTest(SeeAllData=true) static void getUnviewedAnnouncementCount() {
        String groupId = setupGroup();
        setupUnviewedAnnouncementForUser(groupId);
        CommonsSidebarController controller = new CommonsSidebarController();
        controller.groupId = groupId;

        Test.startTest();
        System.assertEquals(1, controller.getUnviewedAnnouncementCount());
        Test.stopTest();
    }

    private static void setupUnviewedAnnouncementForUser(String groupId) {
        CommunityAccessControl__c announcement = new CommunityAccessControl__c();
        announcement.GroupId__c = groupId;
        announcement.DateAnnouncementExpires__c = System.today().addDays(30);
        announcement.AdministrationType__c = 'Announcement';
        announcement.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert announcement;

        CommunityAccessControl__c unviewedAnnouncementRecord = new CommunityAccessControl__c();
        unviewedAnnouncementRecord.StudentUser__c = UserInfo.getUserId();
        unviewedAnnouncementRecord.AnnouncementRecord__c = announcement.id;
        unviewedAnnouncementRecord.ViewedByStudent__c = false;
        unviewedAnnouncementRecord.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Course Announcement' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert unviewedAnnouncementRecord;
    }
    
    private static String setupGroup() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        return newGroup.Id;
    }

    private static void setupCourseAndAssignment(String groupId) {
        WGUCourse__c course = new WGUCourse__c();
        course.Name = 'AAAA';
        course.PAMSID__c = -1;
        insert course;

        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = groupId;
        cac.WGUCourse__c = course.Id;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'CommunityAccessControl__c' AND Name = 'Group Assignment'].id;
        insert cac;
    }

    private static void setupCac(String groupId, String adminType, String text) {
        CommunityAccessControl__c cac1 = new CommunityAccessControl__c();
        cac1.GroupId__c = groupId;
        cac1.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration'].id;
        cac1.AdministrationType__c = adminType;
        cac1.DateAnnouncementExpires__c = System.today().addDays(5);
        cac1.MyResponse__c = text;
        insert cac1;   
    }
    
    private static void addUserToGroup(String groupId, String userId) {
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = groupId;
        groupMember.MemberId = userId;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
    }
    
}