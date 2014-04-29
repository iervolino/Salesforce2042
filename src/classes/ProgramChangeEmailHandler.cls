/*****************************************************************************************
* Name: ProgramChangeEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to Program Change queue
* Revisions: 
*    - 1/1/13 Created Class
******************************************************************************************/

global class ProgramChangeEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        this.caseRecType = 'Program Change'; 
        this.queueName = 'Program Change';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd);        
        return super.handleInboundEmail(email, envelope);
    }
}