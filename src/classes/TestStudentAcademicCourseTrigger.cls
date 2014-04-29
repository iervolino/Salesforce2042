@IsTest
public class TestStudentAcademicCourseTrigger {
	
	@IsTest(SeeAllData=true) static void testCourseCommunitiesAddUserToGroupOnInsert() {//Requires SeeAllData because ContactId on User is not writable
		String currentTerm = DateTime.now().format('yyyyMM');
        
        User u = [SELECT Id, ContactId FROM User WHERE ContactId != null AND IsActive = true AND Profile.Name = 'Student Profile' LIMIT 1];
        Contact c = [SELECT CurrentTerm__c FROM Contact WHERE Id = :u.ContactId];
        c.CurrentTerm__c = currentTerm;
        update c;
        
        CollaborationGroup newGroup = new CollaborationGroup();
        newGroup.Name = 'AAAA';
        newGroup.CollaborationType = 'Public';
        newGroup.NetworkId = [SELECT Id FROM Network WHERE Name = 'WGU Commons'].id;
        insert newGroup;
        
        WGUCourse__c course = new WGUCourse__c();
        course.Title__c = 'Introduction to Underwater Basket Weaving';
        course.Name = 'AAAA';
        course.PAMSID__c = 0;
        insert course;
        
        CommunityAccessControl__c cac = new CommunityAccessControl__c();
        cac.GroupId__c = newGroup.id;
        cac.WGUCourse__c = course.id;
        cac.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Assignment'].id;
        insert cac;
        
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c();
        sac.CourseCode__c = 'AAAA';
        sac.Term__c = currentTerm;
        sac.Status__c = 'Registered';
        sac.StudentContact__c = u.ContactId;

        CommunityAccessControl__c announcement = new CommunityAccessControl__c();
        announcement.GroupId__c = newGroup.id;
        announcement.AdministrationType__c = 'Announcement';
        announcement.DateAnnouncementExpires__c = System.today().addDays(5);
        announcement.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Community Administration' AND sObjectType = 'CommunityAccessControl__c'].id;
        insert announcement;
        
        Test.startTest();
        insert sac;
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :u.id 
                                                      AND GroupId__c = :newGroup.id
                                                      AND RecordType.Name = 'Group Access'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Contributor', cacList.get(0).CommunityStatus__c);

        List<CollaborationGroupMember> cgmList = [SELECT Id,
                                                         NotificationFrequency 
                                                    FROM CollaborationGroupMember 
                                                   WHERE MemberId = :u.id 
                                                     AND CollaborationGroupId = :newGroup.id];
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

}