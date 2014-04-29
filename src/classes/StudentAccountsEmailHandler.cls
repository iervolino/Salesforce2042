global class StudentAccountsEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler {
    
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) { 
        this.caseRecType = 'Student Accounts';
        this.queueName = 'Student Accounts';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = (test.isRunningTest() ? 'false' : 'true');
        email.Headers.add(hd);
        return super.handleInboundEmail(email, envelope);
    }
    
}