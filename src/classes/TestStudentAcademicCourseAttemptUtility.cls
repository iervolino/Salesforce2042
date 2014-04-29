/*****************************************************************************************
* Name: TestStudentAcademicCourseAttemptUtility
* Author: Xuebo Zhang
* Purpose: Test StudentAcademicCourseAttemptUtility class and trigger
* Revisions: 
*    - 10/25/2013 Created Class
*
******************************************************************************************/
@isTest
public class TestStudentAcademicCourseAttemptUtility{
    private static testmethod void testUpsertSourceObject()
    {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                                        competencyUnits__c=2,
                                                         compositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         coursecode__c='CRSE',name='test class course',
                                                         status__c='Passed',StudentContact__c=baggins.Id,
                                                         term__c='201310',Type__c='Performance');
        StudentAcademicCourseAttFromBan__c sacfb = new StudentAcademicCourseAttFromBan__c(
                                                         ActionNeeded__c='Upsert',
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CompositeParentKeyIN__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         AttemptedIN__c = date.valueOf('2013-10-01'),
                                                         AssessmentTaskCodeIN__c='CRSE', PassedIN__c=true,
                                                         TypeIN__c='Performance');
        insert sac;
        Test.startTest();
         insert sacfb;
        Test.stopTest();
       
        List<StudentAcademicCourseAttempt__c> sacList = [ select Id,compositeKey__c,AssessmentTaskCode__c,
                                                  Attempted__c,Passed__c,type__c
                                                 from StudentAcademicCourseAttempt__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(1, sacList.size(), 'Excess control records created - expected 1, found ' + sacList.size() ); 
        System.assertEquals(sacfb.AssessmentTaskCodeIN__c, sacList[0].AssessmentTaskCode__c, 'Incorrect asmt-task-code');
        System.assertEquals(sacfb.CompositeKeyIN__c, sacList[0].compositeKey__c, 'Incorrect comp-key');
        System.assertEquals(sacfb.AttemptedIN__c, sacList[0].Attempted__c, 'Incorrect attempt date');
        System.assertEquals(sacfb.PassedIN__c, sacList[0].Passed__c, 'Incorrect passed-status');
        System.assertEquals(sacfb.typeIN__c, sacList[0].type__c, 'Incorrect Type');
    }
    
    private static testmethod void testUpsertSourceObject2(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourseAttFromBan__c sacfb = new StudentAcademicCourseAttFromBan__c(
                                                         ActionNeeded__c='Insert',
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',                                                        
                                                         AttemptedIN__c = date.valueOf('2013-10-01'),
                                                         AssessmentTaskCodeIN__c='CRSE', PassedIN__c=true,
                                                         TypeIN__c='Performance');
         StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                                        competencyUnits__c=2,
                                                         compositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         coursecode__c='CRSE',name='test class course',
                                                         status__c='Passed',StudentContact__c=baggins.Id,
                                                         term__c='201310',Type__c='Performance');
        StudentAcademicCourseAttFromBan__c sacfb2 = new StudentAcademicCourseAttFromBan__c(
                                                         ActionNeeded__c='Upsert',
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CompositeParentKeyIN__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         AssessmentTaskCodeIN__c='CRSE' );
        Test.startTest();
         insert sacfb;
         //insert sacfb2;
        Test.stopTest();
        List<StudentAcademicCourseAttempt__c> sacList = [ select Id,compositeKey__c,AssessmentTaskCode__c,
                                                  Attempted__c,Passed__c,type__c
                                                 from StudentAcademicCourseAttempt__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(sacList.size(), 0, 'Incorrect record size when wrong insertion.');
    }
    
    private static testmethod void testUpsertSourceObject3(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                                        competencyUnits__c=2,
                                                         compositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         coursecode__c='CRSE',name='test class course',
                                                         status__c='Passed',StudentContact__c=baggins.Id,
                                                         term__c='201310',Type__c='Performance');
        StudentAcademicCourseAttFromBan__c sacfb = new StudentAcademicCourseAttFromBan__c(
                                                         ActionNeeded__c='Delete',
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CompositeParentKeyIN__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         AttemptedIN__c = date.valueOf('2013-10-01'),
                                                         AssessmentTaskCodeIN__c='CRSE', PassedIN__c=true,
                                                         TypeIN__c='Performance',StudentAcademicCourseAttempt__c =sac.id);
        insert sac;
        Test.startTest();
           insert sacfb;
        Test.stopTest();
        List<StudentAcademicCourseAttempt__c> sacList = [ select Id,compositeKey__c,AssessmentTaskCode__c,
                                                  Attempted__c,Passed__c,type__c
                                                 from StudentAcademicCourseAttempt__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(sacList.size(), 0, 'Incorrect record size when wrong insertion.');
    }
    
    private static testmethod void testUpsertSourceObject4()
    {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c( competencyUnits__c=2,
                                                         compositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         coursecode__c='CRSE',name='test class course',
                                                         status__c='Passed',StudentContact__c=baggins.Id,
                                                         term__c='201310',Type__c='Performance');
         //StudentAcademicCourseAttempt__c saca = new StudentAcademicCourseAttempt__c(
         //                                                compositeKey__c = sac.CompositeKey__c,AssessmentTaskCode__c=sac.coursecode__c,
         //                                                Attempted__c=date.valueOf('2013-10-01'),Passed__c=true,Type__c='Task');
        StudentAcademicCourseAttFromBan__c sacfb = new StudentAcademicCourseAttFromBan__c(
                                                         ActionNeeded__c='Upsert',
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CompositeParentKeyIN__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         AttemptedIN__c = date.valueOf('2013-10-01'),
                                                         AssessmentTaskCodeIN__c='CRSE', PassedIN__c=true,
                                                         TypeIN__c='Performance');
        insert sac;
        insert sacfb;
        Test.startTest();
         List<StudentAcademicCourseAttempt__c> sacaList = [ select Id,compositeKey__c,AssessmentTaskCode__c,
                                                  Attempted__c,Passed__c,type__c
                                                 from StudentAcademicCourseAttempt__c
                                                 where compositeKey__c = :sac.CompositeKey__c ];
         StudentAcademicCourseAttFromBan__c sacfb2 = new StudentAcademicCourseAttFromBan__c(
                                                         StudentAcademicCourseAttempt__c=sacaList[0].Id,
                                                         ActionNeeded__c='Update',
                                                         CompositeKeyIN__c=sacaList[0].compositeKey__c,
                                                         CompositeParentKeyIN__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         AttemptedIN__c = date.valueOf('2013-10-05'),
                                                         AssessmentTaskCodeIN__c='CRSE', PassedIN__c=true,
                                                         TypeIN__c='Performance');
         //insert sacfb2;
        Test.stopTest();
       
        List<StudentAcademicCourseAttempt__c> sacList = [ select Id,compositeKey__c,AssessmentTaskCode__c,
                                                  Attempted__c,Passed__c,type__c
                                                 from StudentAcademicCourseAttempt__c
                                                 where compositeKey__c = :sacfb.CompositeKeyIN__c ];        
        System.assertEquals(1, sacList.size(), 'Excess control records created - expected 1, found ' + sacList.size() ); 
        System.assertEquals(sacfb.AssessmentTaskCodeIN__c, sacList[0].AssessmentTaskCode__c, 'Incorrect asmt-task-code');
        System.assertEquals(sacfb.CompositeKeyIN__c, sacList[0].compositeKey__c, 'Incorrect comp-key');
        //System.assertEquals(sacfb2.AttemptedIN__c, sacList[0].Attempted__c, 'Incorrect attempt date');
        System.assertEquals(sacfb.PassedIN__c, sacList[0].Passed__c, 'Incorrect passed-status');
        System.assertEquals(sacfb.typeIN__c, sacList[0].type__c, 'Incorrect Type');
    }
   
 /*   
    private static testmethod void testUpdateCourseRequirement(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                                         CompetencyUnits__c=2,
                                                         CompositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CourseCode__c='CRSE',name='test class course',
                                                         Status__c='Passed',StudentContact__c=baggins.Id,
                                                         Term__c='201310', Type__c='Performance');
        insert sac;
        StudentAcademicCourse__c ac = [SELECT Id FROM StudentAcademicCourse__c WHERE CompositeKey__c =: sac.CompositeKey__c];
        StudentAcademicCourseRequirement__c cr = new StudentAcademicCourseRequirement__c(
                                                        StudentAcademicCourse__c = ac.Id,
                                                        uniqueKey__c = sac.CompositeKey__c);                                                        
        insert cr;        
        StudentAcademicCourseAttFromBan__c sacfb = new StudentAcademicCourseAttFromBan__c(
                                                         ActionNeeded__c='Insert',
                                                         CompositeKeyIN__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'20131211',
                                                         CompositeParentKeyIN__c = sac.CompositeKey__c,
                                                         AttemptedIN__c = date.valueOf('2013-10-01'),
                                                         AssessmentTaskCodeIN__c='CRSE',
                                                         PassedIN__c = true,
                                                         TypeIN__c='Performance');
        Test.startTest();
        insert sacfb;
        Test.stopTest();
        List<StudentAcademicCourseRequirement__c> sacrList = [select Id, Status__c, completed__c
                                                          from StudentAcademicCourseRequirement__c
                                                          where UniqueKey__c =: sacfb.CompositeParentKeyIN__c];
        System.assertEquals(1, sacrList.size(), 'Excess control records created - expected 1, found ' + sacrList.size() ); 
        //System.assertEquals('P',sacrList[0].Status__c, 'Incorrect status code');
        //System.assertEquals(true,sacrList[0].completed__c, 'Incorrect completed code');
    }
 */
}