@isTest
private with sharing class TestCourseKbContactMentorController {
	private static User studentUser;
	private static User mentorUser;

	public static testMethod void testInitAndPhoneSelection() {
		studentUser = TestCourseArticleHelper.getTestStudent('teststudent', 'Test', 'Student');
		System.runAs(studentUser) {
			Contact studentContact = [SELECT Email, Phone, MobilePhone, Name, StudentID__c FROM Contact WHERE Id IN (SELECT ContactID FROM User WHERE Id = :UserInfo.getUserId()) LIMIT 1];
			Test.startTest();
			CourseKbContactMentorController controller = new CourseKbContactMentorController();
			System.assert(String.isNotEmpty(controller.userTimeZone));
			System.assertEquals(studentContact.Email, controller.contactEmail);
			
			List<SelectOption> phoneOptions = controller.getPhoneSelections();
			System.assertEquals(3, phoneOptions.size());
			
			List<SelectOption> meridiemOptions = controller.getTimeZoneSelections();
			System.assertEquals(6, meridiemOptions.size());
			Test.stopTest();
		}
	}
	
	public static testMethod void testInitNonStudent() {
		mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			Test.startTest();
			CourseKbContactMentorController controller = new CourseKbContactMentorController();
			System.assert(String.isNotEmpty(controller.userTimeZone));
			System.assertEquals(UserInfo.getUserEmail(), controller.contactEmail);
			
			List<SelectOption> options = controller.getPhoneSelections();
			System.assertEquals(1, options.size());
			
			List<SelectOption> meridiemOptions = controller.getTimeZoneSelections();
			System.assertEquals(6, meridiemOptions.size());
			Test.stopTest();
		}
	}
	
	public static testMethod void testHideComponent() {
		studentUser = TestCourseArticleHelper.getTestStudent('teststudent', 'Test', 'Student');
		System.runAs(studentUser) {
			CourseKbContactMentorController controller = new CourseKbContactMentorController();
			System.assert(controller.cmComponentAttributes == null);
			CourseKbContactMentorAttributes componentAttributes = new CourseKbContactMentorAttributes();
			componentAttributes.isVisible = true;
			componentAttributes.displayMessages = true;
			controller.cmComponentAttributes = componentAttributes;
			System.assert(controller.cmComponentAttributes.isVisible);
			System.assert(controller.cmComponentAttributes.displayMessages);
			
			Test.startTest();
			controller.hideComponent();
			Test.stopTest();
			
			System.assert(!controller.cmComponentAttributes.isVisible);
			System.assert(!controller.cmComponentAttributes.displayMessages);
		}
	}
	
	public static testMethod void testValidation() {
		studentUser = TestCourseArticleHelper.getTestStudent('teststudent', 'Test', 'Student');
		System.runAs(studentUser) {
			CourseKbContactMentorController controller = new CourseKbContactMentorController();
			System.assert(controller.cmComponentAttributes == null);
			CourseKbContactMentorAttributes componentAttributes = new CourseKbContactMentorAttributes();
			controller.cmComponentAttributes = componentAttributes;
			controller.contactPhone = 'Other';
			System.assert(!controller.cmComponentAttributes.displayMessages); 
			Test.startTest();
			controller.submitContactMyMentorRequest();
			System.assertEquals(3, ApexPages.getMessages().size());
			System.assert(controller.cmComponentAttributes.displayMessages);
			
			controller.contactViaEmail = true;
			controller.contactEmail = null;
			controller.contactViaPhone = true;
			controller.submitContactMyMentorRequest();
			System.assertEquals(5, ApexPages.getMessages().size());
			Test.stopTest();
		}
	}
	
	public static testMethod void testSubmitContactMyMentorRequest() {	
		studentUser = TestCourseArticleHelper.getTestStudent('teststudent', 'Test', 'Student');
		System.runAs(studentUser) {
			CourseKbContactMentorController controller = new CourseKbContactMentorController();
			controller.cmComponentAttributes = new CourseKbContactMentorAttributes();
			controller.mentorContactEmail = 'unittest@unittest.com';
			controller.mentorContactName = 'Unit Test';
			controller.comments = 'Some comment';
			controller.bestTimeToContact = '1';
			controller.contactViaEmail = true;
			controller.studentCourseCode = 'UT1';
			controller.contactPhone = '1112224444';
			controller.bestTimeToContactMeridiem = 'PM';
			Integer emailbefore = Limits.getEmailInvocations();
			Test.startTest();
			controller.submitContactMyMentorRequest();
		   // System.assertEquals(emailbefore + 1, Limits.getEmailInvocations());
			Test.stopTest();
		}
	}
	
	public static testMethod void testSubmitContactMyMentorRequestException() {	
		studentUser = TestCourseArticleHelper.getTestStudent('teststudent', 'Test', 'Student');
		System.runAs(studentUser) {
			CourseKbContactMentorController controller = new CourseKbContactMentorController();
			controller.cmComponentAttributes = new CourseKbContactMentorAttributes();
			controller.mentorContactEmail = 'unittest@unittest.com';
			controller.mentorContactName = 'Unit Test';
			controller.comments = 'Some comment';
			controller.bestTimeToContact = '1';
			controller.contactViaEmail = true;
			Integer emailbefore = Limits.getEmailInvocations();
			System.assertEquals(0, ApexPages.getMessages().size());
			Test.startTest();
			controller.submitContactMyMentorRequest();
			Test.stopTest();
			System.assertEquals(emailbefore, Limits.getEmailInvocations());
			System.assertEquals(1, ApexPages.getMessages().size());
		}
	}
}