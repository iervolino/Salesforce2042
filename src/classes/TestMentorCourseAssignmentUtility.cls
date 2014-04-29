/**
 * Author Paul Stay
 * Western Governors University
 *
 * Date November 12, 2012 
 * Revised: (security audit compliance: with sharing)
 * 
 */

@isTest
private with sharing class TestMentorCourseAssignmentUtility 
{
    static testMethod void testMentorCourseAssignmentInsert()
    {
        // Setup the test mentor
        ID mentorProfileID = [SELECT id from Profile where name = 'Mentor'].id;
        ID newUserId;
        User thisUser;
        
        thisUser = (thisUser == null) ? new User(LastName='Mentor1', FirstName='Standard1', pidm__c='m19421', Username='a1@wgu.edu', email='a1@wgu.edu', Alias='a1', CommunityNickname='a1', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileID, LanguageLocaleKey='en_US', isEmployee__c=true): thisUser;
        insert thisUser;
        
        // Set up the test Mentor Assignment 
        WGUCourseCompletionTask__c task=new WGUCourseCompletionTask__c(BannerCode__c='LET1', Type__c='Performance');
        insert task;
        
        MentorCourseAssignment__c course = new MentorCourseAssignment__c(AcademicTableKey__c=1234, ActiveChk__c='True', CourseNumber__c='LET1', MentorPidm__c='m19421',MentorOfficeHours__c='9-10'  );
        
        Test.startTest();
            insert course;            
        Test.stopTest();
        
        MentorCourseAssignment__c newCourse = [select Mentor__c, ID, CourseNumber__c from MentorCourseAssignment__c where AcademicTableKey__c=1234];
        
        System.assert(newCourse.Mentor__c != null);
        System.debug('Mentor found ' + newCOurse.Mentor__c);
        
        newCourse.MentorOfficeHours__c='Test Value';
        update newCourse;
        
        delete newCourse;
        
        System.assert([select ID from MentorCourseAssignment__c where AcademicTableKey__c=1234].size()==0);
        System.assert([select ID from MentorCourseAssignToBanner__c].size()==1);
    }
    
    static testMethod void testMentorCourseAssignmentLookUpWGUCourse()
    {
        // Setup the test mentor
        ID mentorProfileID = [SELECT  id from Profile where name = 'Mentor'].id;
        ID newUserId;
        User thisUser=  new User(LastName='Mentor', FirstName='Standard', pidm__c='m1942', Username='a@wgu.edu', email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=mentorProfileId, LanguageLocaleKey='en_US', isEmployee__c=true) ;
        insert thisUser;
        WGUCourse__c thisCourse= new WGUCourse__c(Name='LET1',PAMSID__c=92);
        insert thisCourse;
        // Set up the test Mentor Assignment 

        MentorCourseAssignment__c course1 = new MentorCourseAssignment__c(AcademicTableKey__c=1234, ActiveChk__c='TRUE', CourseNumber__c='LET1', MentorPidm__c='m1942',MentorOfficeHours__c='9-10'  );
        MentorCourseAssignment__c course2 = new MentorCourseAssignment__c(AcademicTableKey__c=1235, ActiveChk__c='TRUE', CourseNumber__c='LET2', MentorPidm__c='m1942',MentorOfficeHours__c='9-10'  );
        Test.startTest();
            insert course1;
            insert course2;
        Test.stopTest();
        MentorCourseAssignment__c newCourse1 = [select Mentor__c, ID, CourseNumber__c,WGUCourse__c from MentorCourseAssignment__c where AcademicTableKey__c=1234];
        MentorCourseAssignment__c newCourse2 = [select Mentor__c, ID, CourseNumber__c,WGUCourse__c from MentorCourseAssignment__c where AcademicTableKey__c=1235];
        System.assert(newCourse1.WGUCourse__c==thisCourse.id); 
        System.assert(newCourse2.WGUCourse__c==null);
    }
    
    static testMethod void testMentorCourseGroupLookUpWGUCourse()
    {  
        WGUCourse__c thisCourse= new WGUCourse__c(Name='LET1',PAMSID__c=92);
        insert thisCourse;
        // Set up the test Mentor Group 

        MentorCourseGroup__c course1 = new MentorCourseGroup__c(  CourseNumber__c='LET2',TableKey__c=11311  );
        MentorCourseGroup__c course2 = new MentorCourseGroup__c(  CourseNumber__c='LET1',TableKey__c=11312  );
        Test.startTest();
            insert course2;
            insert course1;            
        Test.stopTest();
        MentorCourseGroup__c newCourse1 = [select id, WGUCourse__c,TableKey__c from MentorCourseGroup__c where TableKey__c=11311];
        MentorCourseGroup__c newCourse2 = [select id, WGUCourse__c,TableKey__c from MentorCourseGroup__c where TableKey__c=11312];
        System.assert(newCourse1.WGUCourse__c==null); 
        System.assert(newCourse2.WGUCourse__c==thisCourse.id);
        
        delete newCourse2;
        
        System.assert([select ID from MentorCourseGroupToBanner__c where CourseNumber__c='LET1'].size()==1);
    }
}