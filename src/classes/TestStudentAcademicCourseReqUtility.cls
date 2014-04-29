/*****************************************************************************************
* Name: TestStudentAcademicCourseReqUtility
* Author: Will Slade
* Purpose: Test StudentAcademicCourseReqUtility class and trigger
* Revisions: 
*    - 1/13/2014 Created Class
*
******************************************************************************************/
@isTest
public class TestStudentAcademicCourseReqUtility{
    private static testmethod void testUpsertSourceObject()
    {
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                                         CompetencyUnits__c=2,
                                                         CompositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         CourseCode__c='CRSE',name='test class course',
                                                         Status__c='Passed',StudentContact__c=baggins.Id,
                                                         Term__c='201310', Type__c='Task');
        StudentAcademicCourseReqFromBanner__c sacrfb = new StudentAcademicCourseReqFromBanner__c(
                                                         ActionNeeded__c='Upsert',
                                                         UniqueKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         UniqueParentKey__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         //EngagedPreassessment__c = date.valueOf('2013-10-01'),
                                                         RequirementCode__c='CRSE', Status__c = 'PA',
                                                         Type__c='Task');
        insert sac;
        Test.startTest();
         insert sacrfb;
        Test.stopTest();
       
        List<StudentAcademicCourseRequirement__c> sacList = [SELECT Id, UniqueKey__c, RequirementCode__c, EngagedPreassessment__c, Status__c, Type__c
                                                             FROM StudentAcademicCourseRequirement__c
                                                             WHERE UniqueKey__c = :sacrfb.UniqueKey__c ];        
        System.assertEquals(1, sacList.size(), 'Excess control records created - expected 1, found ' + sacList.size() ); 
        System.assertEquals(sacrfb.RequirementCode__c, sacList[0].RequirementCode__c, 'Incorrect asmt-task-code');
        System.assertEquals(sacrfb.UniqueKey__c, sacList[0].UniqueKey__c, 'Incorrect comp-key');
        System.assertEquals(sacrfb.Type__c, sacList[0].Type__c, 'Incorrect Type');
    }
    
    private static testmethod void testUpsertSourceObject2(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourseReqFromBanner__c sacrfb = new StudentAcademicCourseReqFromBanner__c(
                                                         ActionNeeded__c='Insert',
                                                         UniqueKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         RequirementCode__c='CRSE', Status__c='PA',
                                                         Type__c='Task');
         StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                                         competencyUnits__c=2,
                                                         compositeKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         coursecode__c='CRSE',name='test class course',
                                                         status__c='Passed',StudentContact__c=baggins.Id,
                                                         term__c='201310',Type__c='Task');
        StudentAcademicCourseReqFromBanner__c sacrfb2 = new StudentAcademicCourseReqFromBanner__c(
                                                         ActionNeeded__c='Upsert',
                                                         UniqueKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         UniqueParentKey__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         RequirementCode__c='CRSE' );
        Test.startTest();
         insert sacrfb;
         insert sacrfb2;
        Test.stopTest();
        List<StudentAcademicCourseRequirement__c> sacList = [ select Id,UniqueKey__c,RequirementCode__c,
                                                  Status__c, Type__c
                                                 from StudentAcademicCourseRequirement__c
                                                 where UniqueKey__c = :sacrfb.UniqueKey__c ];        
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
                                                         term__c='201310',Type__c='Task');
        StudentAcademicCourseReqFromBanner__c sacrfb = new StudentAcademicCourseReqFromBanner__c(
                                                         ActionNeeded__c='Delete',
                                                         UniqueKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         UniqueParentKey__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         RequirementCode__c='CRSE', Status__c='PA',
                                                         Type__c='Task',StudentAcademicCourseRequirement__c =sac.id);
        insert sac;
        Test.startTest();
           insert sacrfb;
        Test.stopTest();
        List<StudentAcademicCourseRequirement__c> sacList = [SELECT Id, UniqueKey__c, RequirementCode__c,
                                                             Status__c, Type__c
                                                             FROM StudentAcademicCourseRequirement__c
                                                             WHERE UniqueKey__c = :sacrfb.UniqueKey__c ];        
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
                                                         term__c='201310',Type__c='Task');
        StudentAcademicCourseReqFromBanner__c sacrfb = new StudentAcademicCourseReqFromBanner__c(
                                                         ActionNeeded__c='Upsert',
                                                         UniqueKey__c=baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         UniqueParentKey__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                         RequirementCode__c='CRSE', Status__c = 'PA',
                                                         Type__c='Task');
        insert sac;
        insert sacrfb;
        Test.startTest();
         List<StudentAcademicCourseRequirement__c> sacrList = [SELECT Id, UniqueKey__c, RequirementCode__c,
                                                               Status__c, Type__c
                                                               FROM StudentAcademicCourseRequirement__c
                                                               WHERE UniqueKey__c = :sac.CompositeKey__c ];
         StudentAcademicCourseReqFromBanner__c sacrfb2 = new StudentAcademicCourseReqFromBanner__c(
                                                          StudentAcademicCourseRequirement__c=sacrList[0].Id,
                                                          ActionNeeded__c = 'Update',
                                                          UniqueKey__c = sacrList[0].UniqueKey__c,
                                                          UniqueParentKey__c = baggins.PIDM__c+'-'+'CRSE'+'-'+'201310',
                                                          RequirementCode__c='CRSE', Status__c = 'PA',
                                                          Type__c='Task');
         insert sacrfb2;
        Test.stopTest();
       
        List<StudentAcademicCourseRequirement__c> sacList = [SELECT Id, UniqueKey__c, RequirementCode__c,
                                                             Status__c, Type__c
                                                             FROM StudentAcademicCourseRequirement__c
                                                             WHERE UniqueKey__c = :sacrfb.UniqueKey__c];        
        System.assertEquals(1, sacList.size(), 'Excess control records created - expected 1, found ' + sacList.size() ); 
        System.assertEquals(sacrfb.RequirementCode__c, sacList[0].RequirementCode__c, 'Incorrect asmt-task-code');
        System.assertEquals(sacrfb.UniqueKey__c, sacList[0].UniqueKey__c, 'Incorrect comp-key');
        System.assertEquals(sacrfb.Status__c, sacList[0].Status__c, 'Incorrect passed-status');
        System.assertEquals(sacrfb.Type__c, sacList[0].Type__c, 'Incorrect Type');
    }
    
    private static testmethod void testUpdateContactEmailSent(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        Contact baggins = [SELECT Id, PIDM__c FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        StudentAcademicCourse__c sac = new StudentAcademicCourse__c(
                                           StudentContact__c = baggins.Id,
                                           CompositeKey__c = baggins.PIDM__c+'-'+'ABP1'+'-'+'201403',
                                           CourseCode__c='ABP1', Status__c='Passed',
                                           term__c='201403',Type__c='Performance');
        insert sac;
        StudentAcademicCourse__c sacNew = [Select Id,CompositeKey__c FROM StudentAcademicCourse__c
                                           where CompositeKey__c =: sac.CompositeKey__c];
        StudentAcademicCourseRequirement__c cr = new StudentAcademicCourseRequirement__c(
                                                     StudentAcademicCourse__c = sacNew.Id,
                                                     UniqueKey__c = sacNew.CompositeKey__c,
                                                     Completed__c = True);
        Test.startTest();
          insert cr;
          cr.UniqueKey__c = baggins.PIDM__c+'-'+'SFAW'+'-'+'201403';
          update cr;
        Test.stopTest();
        Contact bagginsNew = [SELECT Id,InitialFEEmailSent__c,SFAWEmailSent__c  FROM Contact WHERE Id =: baggins.Id];
        System.assertEquals(True, bagginsNew.InitialFEEmailSent__c, 'PCE email error');
        System.assertEquals(True, bagginsNew.SFAWEmailSent__c, 'SFAW email error');
    }
 
}