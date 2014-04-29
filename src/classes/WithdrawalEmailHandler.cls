/*****************************************************************************************
* Name: WithdrawalEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to Withdrawal queue
* Revisions: 
*    - 1/1/13 Created Class
******************************************************************************************/

global class WithdrawalEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'Withdrawal';
        this.queueName = 'Withdrawal';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd);         
        return super.handleInboundEmail(email, envelope);
    }
}