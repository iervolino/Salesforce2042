/**
 * Author Paul R. Stay
 * Western Governors University @ 2014
 * Created Date: March 2014
 *
 * Unit Test the StudentAnalytics class
 * Version 29.0
 */

@isTest
private with sharing class TestStudentAnalytics {
    
    @isTest private static void TestStudentAnalytics() {
        // Get the test user (this should be admin)
        User runAsUser = TestStudentUser.getSAdminUser();

        String environment = TestStudentUser.getEnvironment();
    
        ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;

        // Create a Student Contact record for testing
        List<Contact> testStudents = new List<Contact>();
        testStudents.add( new Contact(lastName='Test',Firstname='Standard Student',PIDM__c='t123456',Email='t123456testing@wgu.edu',recordTypeId=studentContactRecordTypeId) );

        insert testStudents;

        List<Contact> students = [SELECT ID from Contact where PIDM__C='t123456'];

        // System.debug('*********************** Student Analytics ********************' + students.get(0).id);

        System.runAs(runAsUser) {
            Test.startTest();
                List<StudentAnalytics__c> analytics = new List<StudentAnalytics__c>();
                analytics.add(new StudentAnalytics__c(PIDM__C='t123456', RiskFactor__c=1, MentorSuggestion__c = 'abcd'));
                insert analytics;

                StudentAnalytics__c analyticsTestRec = [SELECT id, PIDM__C, Student__c, RiskFactor__c,MentorSuggestion__c from StudentAnalytics__c where PIDM__C = 't123456'];
                Contact testStudent = [SELECT id, StudentRiskScore__c, StudentAnalyticMessage__c from Contact where PIDM__C = 't123456'];
              
                // System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AnalyticsTestRec - >' + analyticsTestRec.id);
                // System.debug('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AnalyticsTestRec - >' + analyticsTestRec.Student__c);

                System.assert(students.get(0).ID == analyticsTestRec.Student__c);
                System.assert(testStudent.StudentRiskScore__c == analyticsTestRec.RiskFactor__c);
                System.assert(testStudent.StudentAnalyticMessage__c == analyticsTestRec.MentorSuggestion__c); //Edit 4-23-14


            Test.stopTest();
        }    
    }

    @isTest static void testStudentAnalyticsBadData() {
        User runAsUser = TestStudentUser.getSAdminUser();

        String environment = TestStudentUser.getEnvironment();
    
        ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;

        // Create a Student Contact record for testing
        List<Contact> testStudents = new List<Contact>();
        testStudents.add( new Contact(lastName='Test',Firstname='Standard Student',PIDM__c='t123456',Email='t123456testing@wgu.edu',recordTypeId=studentContactRecordTypeId) );
        testStudents.add( new Contact(lastName='Test2',Firstname='Standard Student2',PIDM__c='t234567',Email='t23457testing@wgu.edu',recordTypeId=studentContactRecordTypeId) );        

        insert testStudents;

        List<Contact> students = [SELECT ID from Contact where PIDM__C='t123456'];

        // System.debug('*********************** Student Analytics ********************' + students.get(0).id);

        System.runAs(runAsUser) {
            Test.startTest();
                List<StudentAnalytics__c> analytics = new List<StudentAnalytics__c>();
                analytics.add(new StudentAnalytics__c(PIDM__C='t123456', RiskFactor__c=1));
                // Bad pidm  
                analytics.add(new StudentAnalytics__c(PIDM__C='t123458', RiskFactor__c=1));

                try {
                    Database.SaveResult[] srList = Database.insert(analytics,false);
                    for(Database.SaveResult sr : srList){
                        if(!sr.isSuccess()){
                            for(Database.Error err : sr.getErrors()){
                                System.debug('The following error has occurred.');
                                System.debug(err.getStatusCode() + ' : ' + err.getMessage());
                                System.debug('Fields that affected this error: ' + err.getFields());
                            }
                        }
                    }
                    StudentAnalytics__c analyticsTestRec = [SELECT id, PIDM__C, Student__c, RiskFactor__c from StudentAnalytics__c where PIDM__C = 't123456'];                    
                    System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@ Assertion @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                    System.assert(students.get(0).ID == analyticsTestRec.Student__c);                    
                } catch (DmlException e){
                    System.debug('>>>>>>>>>>>>>>>>>>>>>>>> DML getNum '+e.getNumDml());
                    System.debug('>>>>>>>>>>>>>>>>>>>>>>>> DML getNum '+e.getDmlMessage(0));
                    System.assert(false);
                }

            Test.stopTest();
        }    
    }

    @isTest private static void testBulkLoad() {
        User runAsUser = TestStudentUser.getSAdminUser();
        String environment = TestStudentUser.getEnvironment();
    
        ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;

        // Create a Student Contact record for testing
        List<Contact> testStudents = new List<Contact>();
        List<String> pidmList = new List<String>();


        // Create 200 users for bulk testing
        Integer pidm = 123456;
        for(Integer i=0; i < 200; i++) {
            String nPidm = (pidm+i).format().replaceAll('\\,','');
            testStudents.add( new Contact(
                lastName='Test' + i.format(),
                Firstname='Standard Student',
                PIDM__c= 't' + nPidm,
                Email= nPidm + 'testing@wgu.edu',
                recordTypeId=studentContactRecordTypeId) );
         }

         insert testStudents;
         
         List<StudentAnalytics__c> aList = new List<StudentAnalytics__c>();

         Integer risk = 0;

         for(Contact c : testStudents){
            aList.add(new StudentAnalytics__c(
                RiskFactor__c = 4,
                PIDM__C = c.PIDM__c
                ));
            pidmList.add(c.PIDM__c);
         }

         System.runAs(runAsUser) {
            Test.startTest();
                insert aList;

                Integer countAnalytics = [select count() from StudentAnalytics__c where RiskFactor__c = 4];
                System.assert(countAnalytics == 200);


            Test.stopTest();
        }
    }
}