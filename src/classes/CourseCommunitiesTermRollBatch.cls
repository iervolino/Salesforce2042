global class CourseCommunitiesTermRollBatch implements Database.Batchable<sObject> {

    private String testContactId;
        
    global CourseCommunitiesTermRollBatch() {}
    
    global CourseCommunitiesTermRollBatch(String testContactId) {
        this.testContactId = testContactId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String currentTerm = DateTime.now().format('yyyyMM');
        String query = 'SELECT Id FROM Contact WHERE CurrentTerm__c = \'' + currentTerm + '\'';
        if(Test.isRunningTest() && testContactId != null) {
            query += ' AND Id = \'' + testContactId + '\'';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> contactList) {
        String currentTerm = DateTime.now().format('yyyyMM');
        List<StudentAcademicCourse__c> sacList = [SELECT Id, StudentContact__c, CourseCode__c
                                                    FROM StudentAcademicCourse__c 
                                                   WHERE StudentContact__c IN :contactList 
                                                     AND Term__c = :currentTerm
                                                     AND Status__c IN ('Registered', 'Not Passed')];
        
        if(sacList.isEmpty()) {
            return;
        }
        
        CourseCommunitiesGroupPermissionUtil util = new CourseCommunitiesGroupPermissionUtil();
        util.updateCourseGroupPermissions(sacList, 'N', 'Contributor');
    }

    global void finish(Database.BatchableContext BC) {
        
    }
    
}