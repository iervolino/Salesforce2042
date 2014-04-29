/**
 * Author Paul Stay
 * Test the MyCourseAssignmentsController and visualforce page
 *
 * Date Jan. 2013
 * 
 */
 @isTest
 private with sharing class TestMyStudentsInACourseController {
 
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
        String selectedCourses = 'TEST,QAT1,FOO1';

        Test.startTest();
                
            System.RunAs(mentorUser) {
            
                PageReference pageRef = new PageReference('/apex/MyStudentsInACourse');
                test.setCurrentPage(pageRef);
                ApexPages.StandardController stdController = new ApexPages.StandardController( new MentorCourseAssignment__c());
                MyStudentsInACourseController controller = new MyStudentsInACourseController(stdController);
                             
                                
                controller.setSelectedCourses(selectedCourses);
                
                String getCourses = controller.getSelectedCourses();
                System.assertEquals(getCourses, 'TEST,QAT1,FOO1');
                
                controller.loadCourses();
                    
                User testUser = [Select id,CoursesIManage__c from User where ID= :mentorUser.Id];
                    
                System.assertEquals(testUser.CoursesIManage__c, 'TEST,QAT1,FOO1');
                   
            }
            
            System.RunAs(mentorUser) {
                MyStudentsInACourseController controller = new MyStudentsInACourseController();
                controller.setSelectedCourses(selectedCourses);
                String getCourses = controller.getSelectedCourses();
                System.assertEquals(getCourses, 'TEST,QAT1,FOO1');
                
                controller.loadCourses();
                    
                User testUser = [Select id,CoursesIManage__c from User where ID= :mentorUser.Id];
                    
                System.assertEquals(testUser.CoursesIManage__c, 'TEST,QAT1,FOO1');
                   
            }
        
        Test.stopTest();
     }
      
 }