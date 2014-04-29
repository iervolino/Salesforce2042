public class SmsUtil{
    
    public void sendMessageList() {
        //for(sObject smsMessage : smsMessageList) {
        
    	//}
    }
    
    public void sendMessage(String toNumber, String message) {
        if(String.isEmpty(toNumber) || String.isEmpty(message)) {
            return;
        }
        
        String completeNumber = toNumber.replaceAll('[^\\d.]', '');
        
        if(completeNumber.length() != 10) {
            return;
        }
        
        completeNumber = '+1' + completeNumber;
        
        String fromNumber = '';
        
        /*SmsAccount__c accountSettings = SmsAccount__c.getAll().get('Twilio');
    
        String output = 'StatusCallback=' + EncodingUtil.urlEncode('https://' + accountSettings.SmsCallbackDomain__c + '/services/apexrest/twilioSms/statusCallback', 'UTF-8') +
                        '&To=' + completeNumber + 
                        '&From=' + fromNumber + 
                        '&Body=' + EncodingUtil.urlEncode(message, 'UTF-8');
        
        HttpRequest req = new HttpRequest();
        
        Blob headerValue = Blob.valueOf(accountSettings.AccountSID__c + ':' + accountSettings.AccountToken__c);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        
        req.setMethod('POST');
        req.setEndpoint('https://api.twilio.com/2010-04-01/Accounts/' + accountSettings.AccountSID__c + '/Messages.json');
        req.setBody(output); 

        Http http = new Http();

        HttpResponse res = http.send(req);
        processResponse(res.getBody());*/
    }
    
    public void processResponse(String response) {
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
        String sid = (String)responseMap.get('sid');
        String status = (String)responseMap.get('status');
        
        /*SmsMessage__c smsMessage = new SmsMessage__c();
        smsMessage.MessageSid__c = sid;
        smsMessage.MessageStatus__c = status;
        insert smsMessage;*/
    }
    
}