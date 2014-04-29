@IsTest
public class CourseCommunitiesTermRollScheduledTest {

    @IsTest(SeeAllData=true) static void testJob() {
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
        
        CollaborationGroupMember cgm = new CollaborationGroupMember();
        cgm.MemberId = u.id;
        cgm.CollaborationGroupId = newGroup.id;
        cgm.NotificationFrequency = 'W';
        cgm.CollaborationRole = 'Standard';
        insert cgm;
        
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
        
        CommunityAccessControl__c cac2 = new CommunityAccessControl__c();
        cac2.GroupId__c = newGroup.id;
        cac2.StudentUser__c = u.id;
        cac2.CommunityStatus__c = 'Viewer';
        cac2.WGUCourse__c = course.id;
        cac2.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Group Access'].id;
        insert cac2;
        
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c();
        sac.CourseCode__c = 'AAAA';
        sac.Term__c = currentTerm;
        sac.Status__c = 'Registered';
        sac.StudentContact__c = u.ContactId;
        insert sac;
        
        Test.startTest();
        System.schedule('Test Course Communities Term Roll Scheduled Job', '0 0 0 3 9 ? 2022', new CourseCommunitiesTermRollScheduledJob(c.id));
        Test.stopTest();
        
        List<CommunityAccessControl__c> cacList = [SELECT CommunityStatus__c 
                                                     FROM CommunityAccessControl__c 
                                                    WHERE StudentUser__c = :u.id 
                                                      AND GroupId__c = :newGroup.id
                                                      AND RecordType.Name = 'Group Access'];
        System.assertEquals(1, cacList.size());
        System.assertEquals('Contributor', cacList.get(0).CommunityStatus__c);
    }
    
}