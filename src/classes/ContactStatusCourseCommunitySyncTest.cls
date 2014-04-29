@IsTest
public class ContactStatusCourseCommunitySyncTest {

    @IsTest(SeeAllData=true) static void changeToASTest() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        CollaborationGroup newGroup = setupGroup(networkId);
        
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND Contact.Status__c != 'AS' AND Contact.WGUDegreeProgram__c != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact con = [SELECT Id, Status__c, WGUDegreeProgram__c FROM Contact WHERE id = :u.contactId];
        
        WGUCourse__c c = new WGUCourse__c();
        c.Title__c = 'Introduction to Underwater Basket Weaving';
        c.Name = 'AAAA';
        c.PAMSID__c = 0;
        insert c;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = newGroup.id;
        cac.WGUCourse__c = c.id;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Assignment'].id;
        insert cac;
        
        WGUCourseInProgram__c cip = new WGUCourseInProgram__c();
        cip.Course__c = c.id;
        cip.Program__c = con.WGUDegreeProgram__c;
        insert cip;

        CommunityAccessControl__c announcement = new CommunityAccessControl__c();
        announcement.GroupId__c = newGroup.id;
        announcement.AdministrationType__c = 'Announcement';
        announcement.DateAnnouncementExpires__c = System.today().addDays(5);
        announcement.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert announcement;
        
        Test.startTest();
        con.Status__c = 'AS';
        update con;
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT GroupId__c, CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :u.id 
                                                      AND GroupId__c = :newGroup.id
                                                      AND RecordTypeId IN (SELECT Id FROM RecordType WHERE Name = 'Group Access')];

        System.assertEquals(1, cacList.size());
        System.assertEquals('Viewer', cacList.get(0).CommunityStatus__c);
        
        List<CollaborationGroupMember> cgmList = [SELECT NotificationFrequency FROM CollaborationGroupMember WHERE MemberId = :u.id AND CollaborationGroupId = :newGroup.id];
        System.assertEquals(1, cgmList.size());
        System.assertEquals('N', cgmList.get(0).NotificationFrequency);

        List<CommunityAccessControl__c> studentAnnouncementRecords = [SELECT Id 
                                                                        FROM CommunityAccessControl__c 
                                                                       WHERE StudentUser__c = :u.id 
                                                                         AND RecordType.Name = 'Course Announcement'
                                                                         AND AnnouncementRecord__c = :announcement.id
                                                                         AND ViewedByStudent__c = false];
        System.assertEquals(1, studentAnnouncementRecords.size());
    }
    
    @IsTest(SeeAllData=true) static void removeTest() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        CollaborationGroup newGroup = setupGroup(networkId);
        
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND Contact.Status__c != 'DR' AND Contact.WGUDegreeProgram__c != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact con = [SELECT Id, Status__c, WGUDegreeProgram__c FROM Contact WHERE id = :u.contactId];
        
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

        Test.startTest();
        con.Status__c = 'DR';
        update con;
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT GroupId__c, CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :u.id 
                                                      AND GroupId__c = :newGroup.id
                                                      AND RecordTypeId IN (SELECT Id FROM RecordType WHERE Name = 'Group Access')];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Removed', cacList.get(0).CommunityStatus__c);
        
        List<CollaborationGroupMember> cgmList = [SELECT NotificationFrequency FROM CollaborationGroupMember WHERE MemberId = :u.id AND CollaborationGroupId = :newGroup.id];
        System.assertEquals(0, cgmList.size());
    }
    
    @IsTest(SeeAllData=true) static void changeToAS_CGMAlreadyExistsNoUpdateTest() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        CollaborationGroup newGroup = setupGroup(networkId);
        
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND Contact.Status__c != 'AS' AND Contact.WGUDegreeProgram__c != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact con = [SELECT Id, Status__c, WGUDegreeProgram__c FROM Contact WHERE id = :u.contactId];
        
        WGUCourse__c c = new WGUCourse__c();
        c.Title__c = 'Introduction to Underwater Basket Weaving';
        c.Name = 'AAAA';
        c.PAMSID__c = 0;
        insert c;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = newGroup.id;
        cac.WGUCourse__c = c.id;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Assignment'].id;
        insert cac;
        
        WGUDegreeProgram__c dp = new WGUDegreeProgram__c();
        dp.Title__c = 'Bachelor of Science, Science!';
        dp.PAMSID__c = -1;
        insert dp;
        
        WGUCourseInProgram__c cip = new WGUCourseInProgram__c();
        cip.Course__c = c.id;
        cip.Program__c = con.WGUDegreeProgram__c;
        insert cip;
        
        CollaborationGroupMember cgm = new CollaborationGroupMember();
        cgm.CollaborationGroupId = newGroup.id;
        cgm.MemberId = u.id;
        cgm.CollaborationRole = 'Standard';
        cgm.NotificationFrequency = 'N';
        insert cgm;
        
        CommunityAccessControl__c permissionCac = new CommunityAccessControl__c();
        permissionCac.CommunityStatus__c = 'Viewer';
        permissionCac.StudentUser__c = u.id;
        permissionCac.GroupId__c = newGroup.id;
        permissionCac.CommunityId__c = networkId;
        permissionCac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access'].id;
        permissionCac.WGUCourse__c = c.id;
        insert permissionCac;
        
        Test.startTest();
        con.Status__c = 'AS';
        update con;
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT GroupId__c, CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :u.id 
                                                      AND GroupId__c = :newGroup.id
                                                      AND RecordTypeId IN (SELECT Id FROM RecordType WHERE Name = 'Group Access')];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Viewer', cacList.get(0).CommunityStatus__c);
        
        List<CollaborationGroupMember> cgmList = [SELECT NotificationFrequency FROM CollaborationGroupMember WHERE MemberId = :u.id AND CollaborationGroupId = :newGroup.id];
        System.assertEquals(1, cgmList.size());
        System.assertEquals('N', cgmList.get(0).NotificationFrequency);
    }
    
    @IsTest(SeeAllData=true) static void changeToAS_CGMAlreadyExistsUpdateTest() {
        String networkId = ([SELECT Id FROM Network WHERE Name = 'WGU Commons']).id;
        CollaborationGroup newGroup = setupGroup(networkId);
        
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND Contact.Status__c != 'AS' AND Contact.WGUDegreeProgram__c != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact con = [SELECT Id, Status__c, WGUDegreeProgram__c FROM Contact WHERE id = :u.contactId];
        
        WGUCourse__c c = new WGUCourse__c();
        c.Title__c = 'Introduction to Underwater Basket Weaving';
        c.Name = 'AAAA';
        c.PAMSID__c = 0;
        insert c;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = newGroup.id;
        cac.WGUCourse__c = c.id;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Assignment'].id;
        insert cac;
        
        WGUDegreeProgram__c dp = new WGUDegreeProgram__c();
        dp.Title__c = 'Bachelor of Science, Science!';
        dp.PAMSID__c = -1;
        insert dp;
        
        WGUCourseInProgram__c cip = new WGUCourseInProgram__c();
        cip.Course__c = c.id;
        cip.Program__c = con.WGUDegreeProgram__c;
        insert cip;
        
        CollaborationGroupMember cgm = new CollaborationGroupMember();
        cgm.CollaborationGroupId = newGroup.id;
        cgm.MemberId = u.id;
        cgm.CollaborationRole = 'Standard';
        cgm.NotificationFrequency = 'W';
        insert cgm;
        
        CommunityAccessControl__c permissionCac = new CommunityAccessControl__c();
        permissionCac.CommunityStatus__c = 'Removed';
        permissionCac.StudentUser__c = u.id;
        permissionCac.GroupId__c = newGroup.id;
        permissionCac.CommunityId__c = networkId;
        permissionCac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access'].id;
        permissionCac.WGUCourse__c = c.id;
        insert permissionCac;
        
        Test.startTest();
        con.Status__c = 'AS';
        update con;
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT GroupId__c, CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :u.id 
                                                      AND GroupId__c = :newGroup.id
                                                      AND RecordTypeId IN (SELECT Id FROM RecordType WHERE Name = 'Group Access')];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Viewer', cacList.get(0).CommunityStatus__c);
        
        List<CollaborationGroupMember> cgmList = [SELECT NotificationFrequency FROM CollaborationGroupMember WHERE MemberId = :u.id AND CollaborationGroupId = :newGroup.id];
        System.assertEquals(1, cgmList.size());
        System.assertEquals('N', cgmList.get(0).NotificationFrequency);
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