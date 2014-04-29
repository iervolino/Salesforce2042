@IsTest
public class ChatterSettingsControllerTest {

    @IsTest(SeeAllData=true) static void constructorTest() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        NetworkMember pref = [SELECT PreferencesDisableLaterCommentEmail,PreferencesDisProfPostCommentEmail FROM NetworkMember WHERE MemberId = :u.id AND NetworkId = :networkId];
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.id;
        groupMember.MemberId = u.id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'D';
        insert groupMember;
        
        System.runAs(u) {
            Test.startTest();
            ChatterSettingsController controller = new ChatterSettingsController();
            Test.stopTest();
            
            System.assertEquals(!pref.PreferencesDisableLaterCommentEmail, controller.commentsAfterMe);
            System.assertEquals(!pref.PreferencesDisProfPostCommentEmail, controller.commentsOnMyPost);
            
            boolean groupFound = false;
            for(ChatterSettingsController.GroupEmailFrequency freq : controller.groupEmailFrequencyList) {
                if(freq.groupId.equals(newGroup.id)) {
                    groupFound = true;
                }
            }
            
            System.assert(groupFound);
        }
    }
    
    @IsTest(SeeAllData=true) static void saveChanges() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        NetworkMember pref = [SELECT PreferencesDisableLaterCommentEmail,PreferencesDisProfPostCommentEmail FROM NetworkMember WHERE MemberId = :u.id AND NetworkId = :networkId];
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.id;
        groupMember.MemberId = u.id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
        
        System.runAs(u) {
            ChatterSettingsController controller = new ChatterSettingsController();
            
            boolean commentsOnMyPost = controller.commentsOnMyPost;
            boolean commentsAfterMe = controller.commentsAfterMe;
            
            controller.commentsOnMyPost = !commentsOnMyPost;
            controller.commentsAfterMe = !commentsAfterMe;
            
            for(ChatterSettingsController.GroupEmailFrequency freq : controller.groupEmailFrequencyList) {
                if(freq.groupId.equals(newGroup.id)) {
                    freq.emailFrequency = ConnectApi.GroupEmailFrequency.WeeklyDigest;
                }
            }
            
            Test.startTest();
            controller.saveChanges();
            Test.stopTest();
            
            NetworkMember preferences = [SELECT PreferencesDisableLaterCommentEmail,PreferencesDisProfPostCommentEmail FROM NetworkMember WHERE MemberId = :u.id AND NetworkId = :networkId];
            //Should be the same as the original from the controller due to the settings being inverted
            System.assertEquals(commentsOnMyPost, preferences.PreferencesDisProfPostCommentEmail);
            System.assertEquals(commentsAfterMe, preferences.PreferencesDisableLaterCommentEmail);
            
            CollaborationGroupMember member = [SELECT NotificationFrequency FROM CollaborationGroupMember WHERE id = :groupMember.id];
            System.assertEquals('W', member.NotificationFrequency);
        }
    }
    
    @IsTest static void getDisplayFrequencyTest() {
        ChatterSettingsController.GroupEmailFrequency test1 = new ChatterSettingsController.GroupEmailFrequency(null, null, ConnectApi.GroupEmailFrequency.EachPost);
        System.assertEquals('Each Post', test1.getDisplayFrequency());
        
        ChatterSettingsController.GroupEmailFrequency test2 = new ChatterSettingsController.GroupEmailFrequency(null, null, ConnectApi.GroupEmailFrequency.DailyDigest);
        System.assertEquals('Daily Digest', test2.getDisplayFrequency());
        
        ChatterSettingsController.GroupEmailFrequency test3 = new ChatterSettingsController.GroupEmailFrequency(null, null, ConnectApi.GroupEmailFrequency.WeeklyDigest);
        System.assertEquals('Weekly Digest', test3.getDisplayFrequency());
        
        ChatterSettingsController.GroupEmailFrequency test4 = new ChatterSettingsController.GroupEmailFrequency(null, null, ConnectApi.GroupEmailFrequency.Never);
        System.assertEquals('Never', test4.getDisplayFrequency());
    }
    
    @IsTest(SeeAllData=true) static void actionChangeEmailFrequencyTest_WeeklyDigest() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.id;
        groupMember.MemberId = u.id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
        
        System.runAs(u) {
            ChatterSettingsController controller = new ChatterSettingsController();
            Test.startTest();
            ApexPages.currentPage().getParameters().put('groupId', String.valueOf(newGroup.id));
            ApexPages.currentPage().getParameters().put('emailFrequency', String.valueOf('Weekly Digest'));
            controller.actionChangeEmailFrequency();
            Test.stopTest();
            
            boolean groupFound = false;
            for(ChatterSettingsController.GroupEmailFrequency freq : controller.groupEmailFrequencyList) {
                if(freq.groupId.equals(newGroup.id)) {
                    groupFound = true;
                    System.assertEquals(ConnectApi.GroupEmailFrequency.WeeklyDigest, freq.emailFrequency);
                }
            }
            
            System.assert(groupFound);
        }
    }
    
    @IsTest(SeeAllData=true) static void actionChangeEmailFrequencyTest_DailyDigest() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.id;
        groupMember.MemberId = u.id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
        
        System.runAs(u) {
            ChatterSettingsController controller = new ChatterSettingsController();
            Test.startTest();
            ApexPages.currentPage().getParameters().put('groupId', String.valueOf(newGroup.id));
            ApexPages.currentPage().getParameters().put('emailFrequency', String.valueOf('Daily Digest'));
            controller.actionChangeEmailFrequency();
            Test.stopTest();
            
            boolean groupFound = false;
            for(ChatterSettingsController.GroupEmailFrequency freq : controller.groupEmailFrequencyList) {
                if(freq.groupId.equals(newGroup.id)) {
                    groupFound = true;
                    System.assertEquals(ConnectApi.GroupEmailFrequency.DailyDigest, freq.emailFrequency);
                }
            }
            
            System.assert(groupFound);
        }
    }
    
    @IsTest(SeeAllData=true) static void actionChangeEmailFrequencyTest_EachPost() {
        User u = [SELECT Id, AccountId FROM User WHERE IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = networkId;
        insert newGroup;
        
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.CollaborationGroupId = newGroup.id;
        groupMember.MemberId = u.id;
        groupMember.CollaborationRole = 'Standard';
        groupMember.NotificationFrequency = 'N';
        insert groupMember;
        
        System.runAs(u) {
            ChatterSettingsController controller = new ChatterSettingsController();
            Test.startTest();
            ApexPages.currentPage().getParameters().put('groupId', String.valueOf(newGroup.id));
            ApexPages.currentPage().getParameters().put('emailFrequency', String.valueOf('Each Post'));
            controller.actionChangeEmailFrequency();
            Test.stopTest();
            
            boolean groupFound = false;
            for(ChatterSettingsController.GroupEmailFrequency freq : controller.groupEmailFrequencyList) {
                if(freq.groupId.equals(newGroup.id)) {
                    groupFound = true;
                    System.assertEquals(ConnectApi.GroupEmailFrequency.EachPost, freq.emailFrequency);
                }
            }
            
            System.assert(groupFound);
        }
    }
    
}