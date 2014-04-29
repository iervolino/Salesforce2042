/**
 * Author Paul Stay
 * Test the MyCourseAssignmentsController and visualforce page
 *
 * Date Jan. 2013
 * 
 */
 @isTest
 private with sharing class TestMyCourseAssignmentsController {
 
     private static testMethod void testController() {
        
        // Add create user and mentor course assignments for testing.
        ID mentorProfileId = [SELECT id from Profile where name = 'Mentor'].ID;
        User mentorUser = new User(LastName='Mentor',FirstName='Standard',pidm__c='m198765',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', 
            LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId , LanguageLocaleKey='en_US');
        mentorUser.CoursesIManage__c = 'TEST';
       
        insert mentorUser ;

        MentorCourseAssignment__c course = new MentorCourseAssignment__c( AcademictableKey__c=1.0,
            ActiveChk__c='Y', CourseNumber__c='QAT1', MentorPidm__c='m198765'     );
    
        insert course;
        
        // Used to simulate selecting courses
        String[] selectedCourses = new String[3];
        selectedCourses[0] = 'TEST';
        selectedCourses[1] = 'QAT1';
        selectedCourses[2] = 'FOO1';

        Test.startTest();
                
        System.RunAs(mentorUser) {
        
            PageReference pageRef = new PageReference('/apex/MyCourseAssignments');
            test.setCurrentPage(pageRef);
            ApexPages.StandardController stdController = new ApexPages.StandardController( new MentorCourseAssignment__c());
            MyCourseAssignmentsController controller = new MyCourseAssignmentsController(stdController);
          

                List<System.SelectOption> courseList = controller.getMyCourses();
                System.assertEquals(courseList.get(0).getLabel(), 'QAT1');
                 
                List<MentorCourseAssignment__c> userCourseList = controller.getMyCoursesByUserId('m1998765');
                System.assertEquals(userCourseList.get(0).CourseNumber__c, 'QAT1');
                
                controller.setSelectedCourses(selectedCourses);
                controller.loadCourses();
                
                User testUser = [Select id,CoursesIManage__c from User where ID= :mentorUser.Id];
                
                System.assertEquals(testUser.CoursesIManage__c, 'TEST,QAT1,FOO1');
               
        }
        
        Test.stopTest();
     }
      
 }