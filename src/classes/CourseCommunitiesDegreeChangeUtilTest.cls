@IsTest
public class CourseCommunitiesDegreeChangeUtilTest {
    
    @IsTest(SeeAllData=true) static void changeDegreeNoCommonCourses() {
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND Contact.WGUDegreeProgram__c != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact c = [SELECT WGUDegreeProgram__c FROM Contact WHERE Id = :u.ContactId];
        
        String newtworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = newtworkId;
        insert newGroup;
        
        WGUCourse__c newCourse = new WGUCourse__c();
        newCourse.name = 'AAAA';
        newCourse.PAMSID__c = -1;
        insert newCourse;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.WGUCourse__c = newCourse.id;
        cac.GroupId__c = newGroup.id;
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE name = 'Group Assignment' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert cac;
        
        WGUDegreeProgram__c newDegree = new WGUDegreeProgram__c();
        newDegree.name = 'B.S. Unit Testing';
        newDegree.PAMSID__c = -3;
        insert newDegree;
        
        WGUCourseInProgram__c newCip = new WGUCourseInProgram__c();
        newCip.Course__c = newCourse.id;
        newCip.Program__c = newDegree.id;
        insert newCip;
        
        CollaborationGroup oldGroup = new CollaborationGroup();
        oldGroup.Name = 'BBBB';
        oldGroup.CollaborationType = 'Public';
        oldGroup.NetworkId = newtworkId;
        insert oldGroup;
        
        WGUCourse__c oldCourse = new WGUCourse__c();
        oldCourse.name = 'BBBB';
        oldCourse.PAMSID__c = -2;
        insert oldCourse;
        
        CommunityAccessControl__c oldCac = new CommunityAccessControl__c();
        oldCac.WGUCourse__c = oldCourse.id;
        oldCac.GroupId__c = oldGroup.id;
        oldCac.CommunityStatus__c = 'Contributor';
        oldCac.StudentUser__c = u.id;
        oldCac.RecordTypeId = [SELECT id FROM RecordType WHERE name = 'Group Access' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert oldCac;
        
        WGUCourseInProgram__c oldCip = new WGUCourseInProgram__c();
        oldCip.Course__c = oldCourse.id;
        oldCip.Program__c = c.WGUDegreeProgram__c;
        insert oldCip;
        
        CollaborationGroupMember oldCgm = new CollaborationGroupMember();
        oldCgm.MemberId = u.id;
        oldCgm.CollaborationGroupId = oldGroup.id;
        oldCgm.NotificationFrequency = 'W';
        oldCgm.CollaborationRole = 'Standard';
        insert oldCgm;

        CommunityAccessControl__c announcement = new CommunityAccessControl__c();
        announcement.GroupId__c = newGroup.id;
        announcement.AdministrationType__c = 'Announcement';
        announcement.DateAnnouncementExpires__c = System.today().addDays(5);
        announcement.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert announcement;
        
        Test.startTest();
        c.WGUDegreeProgram__c = newDegree.id;
        update c;
        Test.stopTest();
        
        List<CollaborationGroupMember> oldCgmList = [SELECT id FROM CollaborationGroupMember WHERE id = :oldCgm.id];
        System.assertEquals(0, oldCgmList.size());
        
        List<CommunityAccessControl__c> oldCacList = [SELECT id, CommunityStatus__c FROM CommunityAccessControl__c WHERE id = :oldCac.id];
        System.assertEquals('Removed', oldCacList.get(0).CommunityStatus__c);
        
        List<CollaborationGroupMember> newCgmList = [SELECT id FROM CollaborationGroupMember WHERE MemberId = :u.id AND CollaborationGroupId = :newGroup.id];
        System.assertEquals(1, newCgmList.size());
        
        List<CommunityAccessControl__c> newCacList = [SELECT id, CommunityStatus__c FROM CommunityAccessControl__c WHERE StudentUser__c = :u.id AND GroupId__c = :newGroup.id];
        System.assertEquals('Viewer', newCacList.get(0).CommunityStatus__c);

        List<CommunityAccessControl__c> studentAnnouncementRecords = [SELECT Id 
                                                                        FROM CommunityAccessControl__c 
                                                                       WHERE StudentUser__c = :u.id 
                                                                         AND RecordType.Name = 'Course Announcement'
                                                                         AND AnnouncementRecord__c = :announcement.id
                                                                         AND ViewedByStudent__c = false];
        System.assertEquals(1, studentAnnouncementRecords.size());
    }
    
    @IsTest(SeeAllData=true) static void changeDegreeCommonCourses() {
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND Contact.WGUDegreeProgram__c != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact c = [SELECT WGUDegreeProgram__c FROM Contact WHERE Id = :u.ContactId];
        
        String newtworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = newtworkId;
        insert newGroup;
        
        WGUCourse__c newCourse = new WGUCourse__c();
        newCourse.name = 'AAAA';
        newCourse.PAMSID__c = -1;
        insert newCourse;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.WGUCourse__c = newCourse.id;
        cac.GroupId__c = newGroup.id;
        cac.RecordTypeId = [SELECT id FROM RecordType WHERE name = 'Group Assignment' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert cac;
        
        WGUDegreeProgram__c newDegree = new WGUDegreeProgram__c();
        newDegree.name = 'B.S. Unit Testing';
        newDegree.PAMSID__c = -3;
        insert newDegree;
        
        WGUCourseInProgram__c newCip = new WGUCourseInProgram__c();
        newCip.Course__c = newCourse.id;
        newCip.Program__c = newDegree.id;
        insert newCip;
        
        CommunityAccessControl__c oldCac = new CommunityAccessControl__c();
        oldCac.WGUCourse__c = newCourse.id;
        oldCac.GroupId__c = newGroup.id;
        oldCac.CommunityStatus__c = 'Contributor';
        oldCac.StudentUser__c = u.id;
        oldCac.RecordTypeId = [SELECT id FROM RecordType WHERE name = 'Group Access' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert oldCac;
        
        WGUCourseInProgram__c oldCip = new WGUCourseInProgram__c();
        oldCip.Course__c = newCourse.id;
        oldCip.Program__c = c.WGUDegreeProgram__c;
        insert oldCip;
        
        CollaborationGroupMember oldCgm = new CollaborationGroupMember();
        oldCgm.MemberId = u.id;
        oldCgm.CollaborationGroupId = newGroup.id;
        oldCgm.NotificationFrequency = 'W';
        oldCgm.CollaborationRole = 'Standard';
        insert oldCgm;
        
        Test.startTest();
        c.WGUDegreeProgram__c = newDegree.id;
        update c;
        Test.stopTest();
        
        List<CollaborationGroupMember> oldCgmList = [SELECT id FROM CollaborationGroupMember WHERE id = :oldCgm.id];
        System.assertEquals(1, oldCgmList.size());
        
        List<CommunityAccessControl__c> oldCacList = [SELECT id, CommunityStatus__c FROM CommunityAccessControl__c WHERE id = :oldCac.id];
        System.assertEquals('Contributor', oldCacList.get(0).CommunityStatus__c);
    }

}