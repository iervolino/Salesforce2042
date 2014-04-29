public with sharing class OnbaseAttachmentUtility
{
    public static void sendToOnbase(List<Attachment> attachments, String bannerId) //, Id orgWideId)
    {
        Messaging.reserveSingleEmailCapacity(2);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        String[] toAddresses = new String[] {'tedocs@wgu.edu'};               

        mail.setToAddresses(toAddresses);
        mail.setReplyTo('transcriptinfo@wgu.edu'); 
        mail.setSubject(bannerId);
        mail.setUseSignature(false);
        mail.setHTMLBody('Attachment Sent');
        
        /*if (orgWideId != null)
        {
            //mail.setOrgWideEmailAddressId(orgWideId);
        }*/             
        
        List<Messaging.EmailFileAttachment> efaList = new List<Messaging.EmailFileAttachment>();
        
        for (Attachment attach : attachments)
        {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attach.Name);
            efa.setBody(attach.Body);
            efaList.add(efa);
        }
        
        mail.setFileAttachments(efaList);
        
        Messaging.sendEmail(new Messaging.SingleEmailMEssage[] { mail });
    }        
}