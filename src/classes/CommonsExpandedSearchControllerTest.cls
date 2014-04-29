@IsTest
public class CommonsExpandedSearchControllerTest {
    
    @IsTest static void constructorTest() {
        ApexPages.currentPage().getParameters().put('groupId', '1');
        ApexPages.currentPage().getParameters().put('searchTerm', 'Test');
        ApexPages.currentPage().getParameters().put('refineSearchTerm', 'Refine test');
        ApexPages.currentPage().getParameters().put('courseCode', 'AAAA');
        
        WGUCourse__c course = new WGUCourse__c();
        course.name = 'AAAA';
        course.title__c = 'Introduction to Underwater Basket Weaving';
        course.pamsid__c = 0;
        insert course;
        
        User u = ([SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1]);
        
        System.runAs(u) {
            Test.startTest();
            CommonsExpandedSearchController controller = new CommonsExpandedSearchController();
            Test.stopTest();
            
            System.assertEquals('1', controller.groupId);
            System.assertEquals('Test', controller.searchTerm);
            System.assertEquals('Refine test', controller.refineSearchTerm);
            System.assertEquals('AAAA', controller.courseCode);
            System.assertEquals('Introduction to Underwater Basket W...', controller.courseTitle);
            System.assert(controller.paginator != null);
        }
    }
    
    @IsTest static void redoSearchTest() {
        CommonsExpandedSearchController controller = new CommonsExpandedSearchController();
        ApexPages.currentPage().getParameters().put('redoSearchTerm', 'Test');
        controller.redoSearch();
        System.assertEquals('Test', controller.searchTerm);
        System.assert(controller.paginator != null);
    }
    
    @IsTest static void refineSearchTest() {
        CommonsExpandedSearchController controller = new CommonsExpandedSearchController();
        ApexPages.currentPage().getParameters().put('refineSearchTerm', 'Refine test');
        controller.refineSearch();
        System.assertEquals('Refine test', controller.refineSearchTerm);
        System.assert(controller.paginator != null);
    }
    
    @IsTest(SeeAllData=true) static void postMessageToChatterTest() {
        CollaborationGroup testGroup = new CollaborationGroup();
        testGroup.name = 'Test group asdf';
        testGroup.CollaborationType = 'Private';
        testGroup.NetworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].Id;
        insert testGroup;
        
        ApexPages.currentPage().getParameters().put('groupId', String.valueOf(testGroup.id));
        CommonsExpandedSearchController controller = new CommonsExpandedSearchController();
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('message', 'This is a test message.');
        ApexPages.currentPage().getParameters().put('question', 'false');
        ApexPages.currentPage().getParameters().put('feedItemId', 'null');
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

}