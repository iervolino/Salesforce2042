/*
*Author John Chan
*Slalom
*Test helper class for unit tests
*/
@isTest
public with sharing class TestCourseArticleHelper {
    public static final String kbUserPermissionSetName = 'KnowledgeBaseUsers';
    public static final String studentRecordTypeName = 'StudentRecord';
    public static final String mentorPublicGroupName = 'Mentors';
    
    public static List<KnowledgeBaseReporting__c> createKnowledgeBaseReporting(integer count) {
        List<KnowledgeBaseReporting__c> kbReportList = new List<KnowledgeBaseReporting__c>();
        for (integer i = 1; i <= count; i++) {
            KnowledgeBaseReporting__c kbReport = new KnowledgeBaseReporting__c();
            kbReport.Title__c = 'Unit Test KB Report ' + i;
            kbReport.KnowledgeArticleId__c = string.valueOf(i);
            kbReport.KnowledgeArticleVersionId__c = string.valueOf(i);
            kbReportList.add(kbReport);
        }
        insert kbReportList;
        return kbReportList;
    }
    
    public static List<CourseArticle__kav> createCourseArticleLink(List<KnowledgeBaseReporting__c> kbReporting) {
        List<CourseArticle__kav> courseArticles = createCourseArticle(kbReporting.size());
        for (integer i = 0; i < courseArticles.size(); i++) {
            kbReporting[i].KnowledgeArticleVersionId__c = courseArticles[i].Id;
        }
        update kbReporting;
        return courseArticles;
    }
    
    public static CourseArticle__kav createCourseArticleFull(String name, String articleType, string fileUploadType, String courseCode) {
        CourseArticle__kav courseArticle = new CourseArticle__kav();
        courseArticle.Title = 'Unit Test Course Article ' + name;
        courseArticle.ArticleType__c = articleType;
        courseArticle.InternalTagging__c = 'Unit Test Course Article Internal Tagging ' + name;
        courseArticle.RichTextArea__c = 'Unit Test Course Article Rich Text Area ' + name;
        courseArticle.Summary = 'Unit Test Course Article Summary ' + name;
        courseArticle.FileUpload__Name__s = 'Unit Test File Name ' + name;
        courseArticle.FileUpload__ContentType__s = fileUploadType;
        courseArticle.FileUpload__Body__s = Blob.valueOf('Unit Test Course Article Body ' + name);
        courseArticle.UrlName = courseArticle.Title.replace(' ', '-');
        insert courseArticle;
        KnowledgeBaseReporting__c kbReport = KnowledgeBaseReportingUtility.createKbReportByArticle(CourseArticleDAO.getForKnowledgeBaseUpsert(courseArticle.Id));
        insert kbReport;
        
        WGUCourse__c course = createCourse(courseCode, 2, Integer.valueOf(1000 * Math.random()));
        Set<String> courseVersionIds = new Set<String>();
        List<KnowledgeBaseWguCourseVersionLink__c> kbCourseVersionLink = new List<KnowledgeBaseWguCourseVersionLink__c>();
        for (WGUCourseVersion__c courseVersion : [SELECT Id FROM WGUCourseVersion__c WHERE WGUCourse__r.Name = :courseCode]) {
            courseVersionIds.add(courseVersion.Id);
        }
        KnowledgeBaseReportingDAO.updateCourseVersionLink(null, courseArticle.Id, kbReport.Id, courseVersionIds);
        
        return courseArticle;
    }
    
    public static List<CourseArticle__kav> createCourseArticle(integer loopCount) {
        List<CourseArticle__kav> courseArticles = new List<CourseArticle__kav>();
        for (integer i = 1; i <= loopCount; i++) {
            CourseArticle__kav courseArticle = new CourseArticle__kav();
            courseArticle.Title = 'Unit Test Course Article ' + i;
            courseArticle.UrlName = courseArticle.Title.replace(' ', '-');
            courseArticles.add(courseArticle);
        }
        insert courseArticles;
        return courseArticles;
    }
    
    public static Mentor__c createMentorKbCourseManagement(User mentorUser, WGUCourse__c course) {
        final String PIDM = '1234';
        mentorUser.PIDM__c = PIDM;
        update mentorUser;
        
        Mentor__c mentor = new Mentor__c(Name = mentorUser.Name, User__c = mentorUser.Id, PIDM__c = mentorUser.PIDM__c, StudentCapacity__c = 100);
        insert mentor;
        KBCourseManagement__c courseManagement = new KBCourseManagement__c(Mentor__c = mentor.Id, Course__c = course.Id);
        insert courseManagement;
        
        return mentor;
    }
    
    public static String[] getCourseArticleLanguageList() {
        String[] languages = new String[] { };
        for (Schema.PicklistEntry language : Schema.SObjectType.CourseArticle__kav.fields.Language.getPickListValues()) {
            languages.add(language.getValue());
        }
        
        return languages;
    }
    
    public static void publishCourseArticle(List<CourseArticle__kav> courseArticles) {
        courseArticles = [SELECT Id, KnowledgeArticleId FROM CourseArticle__kav WHERE Id IN :courseArticles];
        for (CourseArticle__kav courseArticle : courseArticles) {
            KbManagement.PublishingService.publishArticle(courseArticle.KnowledgeArticleId, true);
        }
    }
    
    public static void publishCourseArticle(Id[] courseArticleVersionIds) {
        List<CourseArticle__kav> courseArticles = [SELECT Id, KnowledgeArticleId FROM CourseArticle__kav WHERE Id IN :courseArticleVersionIds];
        for (CourseArticle__kav courseArticle : courseArticles) {
            KbManagement.PublishingService.publishArticle(courseArticle.KnowledgeArticleId, true);
        }
    }
    
    public static void archiveCourseArticle(List<Id> courseArticleVersionIds) {
        List<CourseArticle__kav> courseArticles = [SELECT Id, KnowledgeArticleId, PublishStatus FROM CourseArticle__kav WHERE Id IN :courseArticleVersionIds];
        for (CourseArticle__kav courseArticle : courseArticles) {
            if (courseArticle.PublishStatus == KbArticleConstants.PublicationStatus.Draft.name()) {
                KbManagement.PublishingService.publishArticle(courseArticle.KnowledgeArticleId, true);  
            }
            KbManagement.PublishingService.archiveOnlineArticle(courseArticle.KnowledgeArticleId, null);
        }
    }
    
    public static CourseArticle__kav getCourseArticleById(Id id) {
        return [SELECT Summary FROM CourseArticle__kav WHERE Id = :id];
    }
    
    public static KnowledgeBaseReporting__c getKbReportByCourseArticleVersionId(String courseArticleVersionId) {
        return [SELECT Summary__c FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c = :courseArticleVersionId];
    }
    
    public static User getTestUser(String userName, String profileName, boolean kbUser) {
        Profile profile = [select Id from Profile where Name = :profileName limit 1];
        User user = new User(UserName=(userName + '@wgu.edu'), Alias=userName.substring(0,7), Email=(userName + '@wgu.edu'), EmailEncodingKey='UTF-8', LastName='User', FirstName = 'Test', 
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='America/Los_Angeles', ProfileId=profile.Id, PIDM__c=userName, UserPermissionsKnowledgeUser = kbUser);
        insert user;
        
        if (kbUser) {
            PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :kbUserPermissionSetName];
            PermissionSetAssignment permissionAssignment = new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSet.Id);
            insert permissionAssignment;
            
            Group mentorGroup = [SELECT Id FROM GROUP WHERE Name = :mentorPublicGroupName];
            GroupMember groupAssignment = new GroupMember(GroupId = mentorGroup.Id, UserOrGroupId = user.Id);
            insert groupAssignment;
        }
        
        return user;
    }
    
    public static User getTestStudent(String userName, String firstName, String lastName) {
    	RecordType contactRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact' AND Name = :studentRecordTypeName LIMIT 1];
    	Contact studentContact = new Contact(FirstName = firstName, LastName = lastName, RecordType = contactRecordType, Email=userName + '@wgu.edu', Phone = '1112224444', MobilePhone = '3335557777', StudentId__c = 'UNIT TEST');
    	insert studentContact;
    	RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = :studentRecordTypeName LIMIT 1];
    	Account studentAccount = new Account(Name = firstName + ' ' + lastName, RecordType = accountRecordType, StudentContact__c = studentContact.Id);
    	insert studentAccount;
    	
    	Profile profile = [SELECT Id FROM Profile WHERE Name = :'Student Profile' LIMIT 1];
    	User user = new User(UserName=(userName + '@wgu.edu'), Alias=userName.substring(0,7), Email=(userName + '@wgu.edu'), EmailEncodingKey='UTF-8', LastName = lastName, FirstName = firstName, 
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='America/Los_Angeles', ProfileId=profile.Id, PIDM__c=userName, UserPermissionsKnowledgeUser = false, ContactId = studentContact.Id);
        insert user;
        return user;
    }
    
    public static void assignPermissionSet(User user, String permssionSetName) {
        PermissionSetAssignment permissionAssignment = new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = 
                [SELECT Id FROM PermissionSet WHERE Name = :permssionSetName].Id);
        insert permissionAssignment;
    }
    
    //TODO: Move this to a CourseVersion Helper class instead of here
    public static List<WGUCourseVersion__c> createCourseVersions(integer count, String courseCode, Id courseId, integer PAMSID) {
        List<WGUCourseVersion__c> courseVersions = new List<WGUCourseVersion__c>();
        for (integer i = 1; i <= count; i++) {
            WGUCourseVersion__c courseVersion = new WGUCourseVersion__c(title__c = 'Unit test Course ' + courseCode + i, NEW_Id__c = courseCode + i, PAMSCOURSEID__c = PAMSID, CourseOfStudyId__c = i, MajorVersion__c = i, WGUCourse__c = courseId);
            courseVersions.add(courseVersion);
        }
        insert courseVersions;
        return courseVersions;
    }
    
    public static List<WGUCourseVersion__c> createCourseVersions(integer count, String courseCode) {
        return createCourseVersions(count, courseCode, null, null);
    }
    
    public static WGUCourse__c createCourse(String courseCode, integer courseVersionCount, integer PAMSID) {
        WGUCourse__c course = new WGUCourse__c(Name = courseCode, PAMSId__c = PAMSID);
        insert course;
        
        if (courseVersionCount > 0) {
            createCourseVersions(courseVersionCount, courseCode, course.Id, PAMSID);
        }
        return course;
    }
    
    public static CourseArticleMentorContact__c createMentorContact(String courseCode, String email, String name) {
    	CourseArticleMentorContact__c mentorContact = new CourseArticleMentorContact__c(CourseCode__c = courseCode, MentorEmail__c = email, MentorName__c = name);
    	insert mentorContact;
    	
    	return mentorContact;
    }
    
    public static void setGlobalSettingKbBatchEmail() {
        Runtime__c runtime = new Runtime__c(Name = KnowledgeBaseReportingBatchUtility.reportBatchContactEmailsName, Value__c = 'unit_test_email@wgu.edu');
        insert runtime;
    }
}