public class SendSmsScheduledJob implements Schedulable {

    public void execute(SchedulableContext sc) {
        CourseCommunitiesTermRollBatch b = new CourseCommunitiesTermRollBatch();
        Database.executeBatch(b, 10);//A batch size of 10 will keep us right at the callout limit
    }
    
}