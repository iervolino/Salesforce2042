/*****************************************************************************************
* Name: AcademicServicesEmailHandler
* Author: Brad King
* Purpose: Assign inbound emails to IT Help Desk queue
* Revisions: 
*    - 4/19/13 Created Class
******************************************************************************************/

global class ITHelpDeskEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        this.caseRecType = 'ITHelpDesk'; 
        this.queueName = 'ITHelpDesk';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd);         
        return super.handleInboundEmail(email, envelope);
    }
}