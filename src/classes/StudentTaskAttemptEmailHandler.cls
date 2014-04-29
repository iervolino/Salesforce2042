/*****************************************************************************************
* Name: StudentTaskAttemptEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to StudentTaskAttempt queue
* Revisions: 
*    - 4/19/13 Created Class
******************************************************************************************/

global class StudentTaskAttemptEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'StudentTaskAttempt';
        this.queueName = 'StudentTaskAttempt';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd);         
        return super.handleInboundEmail(email, envelope);
    }
}