/*****************************************************************************************
* Name: TestStudentAcademicCourseUtility
* Author: Will Slade
* Purpose: Test StudentAcademicCourseUtility class and trigger
* Revisions: 
*    - 10/25/2013 Created Class
*
******************************************************************************************/

@isTest
public class TestStudentAcademicCourseUtility
{
    private static testmethod void testUpsertSourceObject()
    {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourseFromBanner__c sacfb = new StudentAcademicCourseFromBanner__c(
                                                         ActionNeeded__c='UPSERT',CompetencyUnitsIN__c=2,
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CourseCodeIN__c='CRSE',CourseTitleIN__c='test class course',
                                                         EndDateIN__c=date.valueOf('2013-10-25'),
                                                         startDateIN__c=date.valueOf('2013-10-01'),
                                                         StatusIN__c='PA',studentPIDMIN__c=baggins.PIDM__c,
                                                         termIN__c='201310',TypeIN__c='PRFA',StudentAcademicCourse__c=null);
        Test.startTest();
         insert sacfb;
        Test.stopTest();
       
        List<StudentAcademicCourse__c> sacList = [ select Id,name,competencyUnits__c,compositeKey__c,coursecode__c,enddate__c,startdate__c,
                                                  status__c,StudentContact__c,term__c,type__c
                                                 from StudentAcademicCourse__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(sacList.size(), 1, 'Excess control records created - expected 1, found ' + sacList.size() ); 
        System.assertEquals(sacfb.CompetencyUnitsIN__c, sacList[0].competencyUnits__c, 'Incorrect comp-Units');
        System.assertEquals(sacfb.CompositeKeyIN__c, sacList[0].compositeKey__c, 'Incorrect comp-key');
        System.assertEquals(sacfb.CourseCodeIN__c, sacList[0].coursecode__c, 'Incorrect course code');
        System.assertEquals(sacfb.enddateIN__c, sacList[0].enddate__c, 'Incorrect End date');
        System.assertEquals(sacfb.startdateIN__c, sacList[0].startdate__c, 'Incorrect start date');
        System.assertEquals('Passed', sacList[0].status__c, 'Incorrect status');
        System.assertEquals(baggins.id, sacList[0].StudentContact__c, 'Incorrect contact id');
        System.assertEquals(sacfb.termIN__c, sacList[0].term__c, 'Incorrect Term');
        System.assertEquals('Performance', sacList[0].type__c, 'Incorrect Type');
        System.assertEquals(sacfb.CourseTitleIN__c, sacList[0].Name, 'Incorrect SAC name-title');
    }
    
    private static testmethod void testUpsertSourceObject2(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourseFromBanner__c sacfb = new StudentAcademicCourseFromBanner__c(
                                                         ActionNeeded__c='UPSERT',CompetencyUnitsIN__c=2,                                                        
                                                         CourseCodeIN__c='CRSE',CourseTitleIN__c='test class course',
                                                         studentPIDMIN__c=baggins.PIDM__c,
                                                         termIN__c='201310',TypeIN__c='Task');
        Test.startTest();
         insert sacfb;
        Test.stopTest();
        List<StudentAcademicCourse__c> sacList = [ select Id,name,competencyUnits__c,compositeKey__c,coursecode__c,enddate__c,startdate__c,
                                                  status__c,StudentContact__c,term__c,type__c
                                                 from StudentAcademicCourse__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(sacList.size(), 0, 'Incorrect record size when wrong insertion.');
    }
    
    private static testmethod void testUpsertSourceObject3(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourseFromBanner__c sacfb = new StudentAcademicCourseFromBanner__c(
                                                         ActionNeeded__c='UPSERT',CompetencyUnitsIN__c=2,
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CourseCodeIN__c='CRSE',CourseTitleIN__c='test class course',
                                                         EndDateIN__c=date.valueOf('2013-10-25'),
                                                         startDateIN__c=date.valueOf('2013-10-01'),
                                                         StatusIN__c='PA',studentPIDMIN__c=baggins.PIDM__c,
                                                         termIN__c='201310',TypeIN__c='EXTLR',StudentAcademicCourse__c=null);
        insert sacfb;
        sacfb.EndDateIN__c=date.valueOf('2013-10-31');
        sacfb.StatusIN__c = 'NP';
        Test.startTest();
         update sacfb;
         sacfb.StatusIN__c = 'TR';
         update sacfb;
         sacfb.StatusIN__c = 'test';
         update sacfb;
         sacfb.StatusIN__c = 'WV';
         update sacfb;
        Test.stopTest();
        List<StudentAcademicCourse__c> sacList = [ select Id,name,competencyUnits__c,compositeKey__c,coursecode__c,enddate__c,startdate__c,
                                                  status__c,StudentContact__c,term__c,type__c
                                                 from StudentAcademicCourse__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(sacList.size(), 1, 'Excess control records created - expected 1, found ' + sacList.size() ); 
        System.assertEquals(sacfb.CompetencyUnitsIN__c, sacList[0].competencyUnits__c, 'Incorrect comp-Units');
        System.assertEquals(sacfb.CompositeKeyIN__c, sacList[0].compositeKey__c, 'Incorrect comp-key');
        System.assertEquals(sacfb.CourseCodeIN__c, sacList[0].coursecode__c, 'Incorrect course code');
        System.assertEquals(sacfb.enddateIN__c, sacList[0].enddate__c, 'Incorrect End date');
        System.assertEquals(sacfb.startdateIN__c, sacList[0].startdate__c, 'Incorrect start date');
        System.assertEquals('Waived', sacList[0].status__c, 'Incorrect status');
        System.assertEquals(baggins.id, sacList[0].StudentContact__c, 'Incorrect contact id');
        System.assertEquals(sacfb.termIN__c, sacList[0].term__c, 'Incorrect Term');
        System.assertEquals('Not Applicable', sacList[0].type__c, 'Incorrect Type');
        System.assertEquals(sacfb.CourseTitleIN__c, sacList[0].Name, 'Incorrect SAC name-title');
    }
    
    private static testmethod void testUpsertSourceObject4(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourseFromBanner__c sacfb = new StudentAcademicCourseFromBanner__c(
                                                         ActionNeeded__c='UPSERT',CompetencyUnitsIN__c=2,
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CourseCodeIN__c='CRSE',CourseTitleIN__c='test class course',
                                                         EndDateIN__c=date.valueOf('2013-10-25'),
                                                         startDateIN__c=date.valueOf('2013-10-01'),
                                                         StatusIN__c='PA',studentPIDMIN__c=baggins.PIDM__c,
                                                         termIN__c='201310',TypeIN__c='OBJA',StudentAcademicCourse__c=null);
        insert sacfb;
        sacfb.EndDateIN__c=date.valueOf('2013-10-31');
        sacfb.StatusIN__c = 'RM';
        sacfb.ActionNeeded__c = 'DELETE';
        Test.startTest();
         update sacfb;
        Test.stopTest();
        List<StudentAcademicCourse__c> sacList = [ select Id,name,competencyUnits__c,compositeKey__c,coursecode__c,enddate__c,startdate__c,
                                                  status__c,StudentContact__c,term__c,type__c
                                                 from StudentAcademicCourse__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(sacList.size(), 0, 'Incorrect record size after deletion.');
    }
}