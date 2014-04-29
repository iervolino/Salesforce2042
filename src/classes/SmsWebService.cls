@RestResource(urlMapping='/sms/*')
global with sharing class SmsWebService{

    @HttpPost
    global static void doPost() {
        System.debug(RestContext.request.requestURI);
        if(RestContext.request.requestURI.endsWith('statusCallback')) {
            statusCallback();
        }
        else if(RestContext.request.requestURI.endsWith('inboundSms')) {
            inboundSms();
        }
    }
    
    private static void statusCallback() {
        Map<String, String> params = RestContext.request.params;
        if(!params.containsKey('MessageSid') || !params.containsKey('MessageStatus')) {
            return;
        }
        String sid = params.get('MessageSid');
        String status = params.get('MessageStatus');
        
        /*List<SmsMessage__c> smsMessageList = [SELECT MessageStatus__c, CallbackDatetime__c FROM SmsMessage__c WHERE MessageSid__c = :sid];
        if(smsMessageList.size() != 1) {
            return;
        }
        SmsMessage__c message = smsMessageList.get(0);
        message.MessageStatus__c = status;
        message.CallbackDatetime__c = Datetime.now();
        update message;*/
    }
    
    private static void inboundSms() {
        Map<String, String> params = RestContext.request.params;
        if(!params.containsKey('MessageSid') || !params.containsKey('Body') 
            || !params.containsKey('To') || !params.containsKey('From')) 
        {
            return;
        }
        String sid = params.get('MessageSid');
        String body = params.get('Body') ;
        String toNumber = params.get('To');
        String fromNumber = params.get('From');
        
        /*InboundSmsMessage__c inboundSms = new InboundSmsMessage__c();
        inboundSms.Message__c = body;
        inboundSms.MessageSid__c = sid;
        inboundSms.SenderPhone__c = fromNumber;
        inboundSms.ToPhone__c = toNumber;
        insert inboundSms;*/
    }
    
}