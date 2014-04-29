@isTest
public class TestCourseArticleUtility {
	public static testMethod void testValidatePublishArticle() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			List<CourseArticle__kav> courseArticleNoLink = TestCourseArticleHelper.createCourseArticle(1);
			//missing type, summary, rich text 
			system.assert(!CourseArticleUtility.validatePublishArticle(courseArticleNoLink[0], 'courseVersionIds', null));
			
			//Testing messages, all errors
			String[] validationMsgs = new String[] {};
			system.assert(!CourseArticleUtility.validatePublishArticle(courseArticleNoLink[0], null, validationMsgs));
			system.assertEquals(4, validationMsgs.size());
			
			CourseArticle__kav courseArticle = TestCourseArticleHelper.createCourseArticleFull('Test Article', 
					Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'Test Course');
					
			//Pass Validation
			courseArticle.articleType__c = 'Unit Test Type';
			courseArticle.Summary = 'Unit Test Summary';
			courseArticle.RichTextArea__c = 'Unit Test Rich Text';
			system.assert(CourseArticleUtility.validatePublishArticle(courseArticle));
		}
	}
	
    public static User init() {
        User testUser;
        Profile systemProfileId = [SELECT Id FROM Profile WHERE Name Like 'System Administrator' LIMIT 1];
        list<User> user1 = [SELECT Id FROM User WHERE ProfileId=:systemProfileId.id AND IsActive=true LIMIT 1]; 
        if (user1.size() > 0){
            System.runAs(user1[0]){ 
    
                // Get Mentor Profile Id
                Profile p = [SELECT Id FROM Profile WHERE Name='Mentor']; 
                // Get Course Mentor Role Id
                UserRole r = [SELECT Id FROM UserRole WHERE Name='Course Mentor'];+
                // Create Test User
                testUser = new User(Alias = 'testUser', Email='testuser@wgu.edu', 
                    EmailEncodingKey='UTF-8', UserRoleId = r.Id, LastName='Testing', LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', ProfileId = p.Id, PIDM__c = 'a1b2c3', IsEmployee__c = true, IsInMentorPilot__c = true,
                    TimeZoneSidKey='America/Denver', UserName='testuser@wgu.edu', IsActive=true,
                    UserPermissionsKnowledgeUser=true, UserPermissionsSFContentUser=true, UserPermissionsMobileUser=true);
                insert testUser;
                // Get Permission Set Id
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'KnowledgeBaseUsers'];
                // Assign Test User to Permission Set
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);
                insert psa;
            }
        }
        return testUser;
    }
    
    //--------------------------------------------------------------------------
    // Helper methods for creating objects
    //--------------------------------------------------------------------------
    public static WGUCourse__c newCourse(String name, Decimal pamsid) {
        return new WGUCourse__c(Name = name, PAMSID__c = pamsid);
    }

    public static WGUCourseVersion__c newCourseVersion(String name, Id courseId, Decimal courseofstudyid, Decimal majorversion, string title) {
        return new WGUCourseVersion__c(Name = name, CourseOfStudyId__c = courseofstudyid, MajorVersion__c = majorversion, Title__c = title);
    }
    public static CourseArticle__kav newCourseArticle(String title, String summary, String articletype, String richtextfield, String urlname) {
        return new CourseArticle__kav(Title = title, Summary = summary, ArticleType__c = articletype, RichTextArea__c = richtextfield, UrlName = urlname);
    }
    public static ArticleCourseVersionLink__c newArticleCVL(Id courseversion, Id articleversionid) {
        return new ArticleCourseVersionLink__c(WGUCourseVersion__c = courseversion, KnowledgeArticleVersionId__c = articleversionid);
    }

}