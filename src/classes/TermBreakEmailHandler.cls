/*****************************************************************************************
* Name: TermBreakEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to Term Break queue
* Revisions: 
*    - 1/1/13 Created Class
******************************************************************************************/

global class TermBreakEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'Term Break';
        this.queueName = 'Term Break';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd);         
        return super.handleInboundEmail(email, envelope);
    }
}