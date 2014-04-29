global class CourseCommunitiesTermRollScheduledJob implements Schedulable {

    private String testContactId;
    
    global CourseCommunitiesTermRollScheduledJob() {}
    
    global CourseCommunitiesTermRollScheduledJob(String testContactId) {
        this.testContactId = testContactId;
    }
    
    global void execute(SchedulableContext sc) {
        CourseCommunitiesTermRollBatch b;
        if(Test.isRunningTest() && testContactId != null) {
            b = new CourseCommunitiesTermRollBatch(testContactId);            
        }
        else {
            b = new CourseCommunitiesTermRollBatch();
        }
        database.executebatch(b);
    }
    
}