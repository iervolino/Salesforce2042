global class SendSmsBatchJob implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = '';//'SELECT Id FROM SMSObject WHERE Status__c = \'Ready to Send\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> smsMessageList) {
        SmsUtil util = new SmsUtil();
        util.sendMessageList();
    }
    
    global void finish(Database.BatchableContext BC) {
        //TODO: If we want to loop this by scheduling it to run again, do that here
        //if(System.now().hour() < 18) {
        //System.scheduleBatch(new SendSmsBatchJob(), 'Send SMS Batch Job', 5, 10);
        //}
    }
    
}