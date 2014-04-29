/*****************************************************************************************
* Name: AcademicServicesEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to Academic Services queue
* Revisions: 
*    - 1/1/13 Created Class
******************************************************************************************/

global class AcademicServicesEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'Academic Services';
        this.queueName = 'AcademicServices';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = (test.isRunningTest() ? 'false' : 'true');
        email.Headers.add(hd);
        return super.handleInboundEmail(email, envelope);
    }
}