/*****************************************************************************************
* Name: OlpEmailHandler Email Handler
* Author: Mike Slade
* Purpose: Assign inbound emails to OlpEmailHandler queue
* Revisions: 
*    -03-27-2013 Created Class
******************************************************************************************/

global class OlpEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'Assessment Scheduling';
        this.queueName = 'Online Proctoring Assessment';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = (test.isRunningTest() ? 'false' : 'true');
        email.Headers.add(hd);
        return super.handleInboundEmail(email, envelope);
    }
}