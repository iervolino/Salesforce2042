/*****************************************************************************************
* Name: FinaidEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to Finaid queue
* Revisions: 
*    - 1/1/13 Created Class
******************************************************************************************/

global class FinaidEmailHandler  extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'Finaid';
        this.queueName = 'Finaid Customer Service';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd); 
        return super.handleInboundEmail(email, envelope);
    }
}