/*****************************************************************************************
* Name: VendorAssessment Email Handler
* Author: Mike Slade
* Purpose: Assign inbound emails to Vendor Assessment queue
* Revisions: 
*    -03-27-2013 Created Class
******************************************************************************************/

global class VendorAssessmentEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    { 
        this.caseRecType = 'Assessment Scheduling';
        this.queueName = 'Vendor Assessments';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = (test.isRunningTest() ? 'false' : 'true');
        email.Headers.add(hd);
        return super.handleInboundEmail(email, envelope);
    }
}