/*
This Controller is used for CreatePDF & PDFPage VF Pages.
Author - Bhavadeep Raavi
No Sharing rules, the current sharing rules remain in effect
*/

public class CreatePDFController {
    public List<SelectOption> emailTempsList{get;set;}
    public String selET{get;set;}
    public String content{get;set;}
    public StudentProcess__c sp{get;set;}
    public Id spId{get;set;}
    public EmailTemplate emailTemp{get;set;}

    public CreatePDFController(ApexPages.StandardController controller) {
        emailTempsList=new List<SelectOption>();
        String Id = [Select Id from Folder where DeveloperName='RecordsEmailTemplates' and AccessType ='Shared' LIMIT 1].Id;
        List<EmailTemplate> listEmailTemps=[select Id,name,body,HtmlValue  from EmailTemplate where FolderId =:Id and name like 'RECPDF%' order By Name];
        for(EmailTemplate et:listEmailTemps){
            emailTempsList.add(new SelectOption(et.Id,et.Name));           
        }
        spId=controller.getRecord().Id;
        sp=[select id,name,Student__r.Name,Student__r.Id,Student__r.Email,Student__r.FirstName,StudentId__c,FirstName__c,LastName__c,LastActivityDate,GraduationDate__c,DateOfDetermination__c,ProgramFullName__c,RequirementsCompletedOn__c, 
               MailingStreet__c,MailingCity__c,State__c,MailingZip__c,Owner.Name,Student__r.FAADate__c,Student__r.TermStartDate__c,Student__r.ProgramStartDate__c,Student__r.PlannedGraduationDate__c from StudentProcess__c where id=:spId];
    }
    public PageReference emailContent(){
        String Id1 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates' and AccessType ='Shared'].Id;
        for(EmailTemplate et:[select id,name,body,HtmlValue from EmailTemplate where FolderId =:Id1 and Id=:selET]){
           content=et.HtmlValue;    
        }
        String Today='{!Today()}';
        String studentId='{!StudentProcess__c.StudentId__c}';
        String FName='{!StudentProcess__c.FirstName__c}';
        String LName='{!StudentProcess__c.LastName__c}';
        String LADate='{!StudentProcess__c.LastActivityDate}';
        String GDate='{!StudentProcess__c.GraduationDate__c}';
        String DOD='{!StudentProcess__c.DateOfDetermination__c}';
        String PFName='{!StudentProcess__c.ProgramFullName__c}';
        String RCon='{!StudentProcess__c.RequirementsCompletedOn__c}';
        String MStreet='{!StudentProcess__c.MailingStreet__c}';
        String MCity='{!StudentProcess__c.MailingCity__c}';
        String Sta='{!StudentProcess__c.State__c}';
        String MZip='{!StudentProcess__c.MailingZip__c}';
        String OFName='{!StudentProcess__c.OwnerFullName}';
        String TSDate='{!Contact.TermStartDate__c}';
        String FDate='{!Contact.FAADate__c}';
        String PSDate='{!Contact.ProgramStartDate__c}';
        String PGDate='{!Contact.PlannedGraduationDate__c}';
        String Symbol=']]>';
        
         /**checking whether {!Contact.name} is present in the template**/
        Boolean todayFlag =content.contains(Today);        
        if(todayFlag){
            content=content.replace(Today,Date.Today().format());
        }
         
       content =  content.contains(studentId)?  ( (sp.StudentId__c!=null)? content.replace(studentId,sp.StudentId__c): content.replace(studentId,'null') ) : content;
       content =  content.contains(FName)?  ( (sp.FirstName__c!=null)? content.replace(FName,sp.FirstName__c): content.replace(FName,'null') ) : content;
       content =  content.contains(LName)?  ( (sp.LastName__c!=null)? content.replace(LName,sp.LastName__c): content.replace(LName,'null') ) : content;
       content =  content.contains(LADate)?  ( (sp.LastActivityDate!=null)? content.replace(LADate,sp.LastActivityDate.format()+''): content.replace(LADate,'null') ) : content;
       content =  content.contains(GDate)?  ( (sp.GraduationDate__c!=null)? content.replace(GDate,sp.GraduationDate__c.format()+''): content.replace(GDate,'null') ) : content;
       content =  content.contains(DOD)?  ( (sp.DateOfDetermination__c!=null)? content.replace(DOD,sp.DateOfDetermination__c.format()+''): content.replace(DOD,'null') ) : content;
       content =  content.contains(PFName)?  ( (sp.ProgramFullName__c!=null)? content.replace(PFName,sp.ProgramFullName__c): content.replace(PFName,'null') ) : content;
       content =  content.contains(RCon)?  ( (sp.RequirementsCompletedOn__c!=null)? content.replace(RCon,sp.RequirementsCompletedOn__c.format()+''): content.replace(RCon,'null') ) : content;
       content =  content.contains(MStreet)?  ( (sp.MailingStreet__c!=null)? content.replace(MStreet,sp.MailingStreet__c): content.replace(MStreet,'null') ) : content;
       content =  content.contains(MCity)?  ( (sp.MailingCity__c!=null)? content.replace(MCity,sp.MailingCity__c): content.replace(MCity,'null') ) : content;
       content =  content.contains(Sta)?  ( (sp.State__c!=null)? content.replace(Sta,sp.State__c): content.replace(Sta,'null') ) : content;
       content =  content.contains(MZip)?  ( (sp.MailingZip__c!=null)? content.replace(MZip,sp.MailingZip__c): content.replace(MZip,'null') ) : content;
       content =  content.contains(OFName)?  ( (sp.Owner.Name!=null)? content.replace(OFName,sp.Owner.Name): content.replace(OFName,'null') ) : content;
       content =  content.contains(TSDate)?  ( (sp.Student__r.TermStartDate__c!=null)? content.replace(TSDate,sp.Student__r.TermStartDate__c.format()+''): content.replace(TSDate,'null') ) : content;
       content =  content.contains(FDate)?  ( (sp.Student__r.FAADate__c!=null)? content.replace(FDate,sp.Student__r.FAADate__c.format()+''): content.replace(FDate,'null') ) : content;
       content =  content.contains(PSDate)?  ( (sp.Student__r.ProgramStartDate__c!=null)? content.replace(PSDate,sp.Student__r.ProgramStartDate__c.format()+''): content.replace(PSDate,'null') ) : content;
       content =  content.contains(PGDate)?  ( (sp.Student__r.PlannedGraduationDate__c!=null)? content.replace(PGDate,sp.Student__r.PlannedGraduationDate__c.format()+''): content.replace(PGDate,'null') ) : content;
        
        Boolean SymFlag =content.contains(Symbol);        
        if(SymFlag){
            content=content.replace(Symbol,'');
        }
       return null;
    }
    public PageReference viewPDF(){
        PageReference pdf=new PageReference('/apex/PDFPage'); 
        return pdf;
    }
     public PageReference savePDF(){
        //shButton = true;
        PageReference pdf = Page.PDFPageInv;
        Attachment attach = new Attachment();
        attach.ParentId = spId;
        attach.name = 'PDFPage.pdf';
        attach.body =(!Test.isRunningTest())?pdf.getContentAsPDF():Blob.valueOf('Test');
         /*if(!Test.isRunningTest()){
            attach.body = pdf.getContentAsPDF();
        }else{
            attach.body=Blob.valueOf('Test');
        }*/
        //attach.body = pdf.getContentAsPDF();
        insert attach;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Attachment Successfully Saved'));
        return null;
    }
    public PageReference sendEmail(){
       //shButton = true;
       String Id2 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates'].Id;
       for(EmailTemplate et:[select id,name,body,HtmlValue,subject from EmailTemplate where FolderId =:Id2 and Id=:selET]){
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            PageReference pdf =  Page.PDFPageInv;
            attach.setContentType('application/pdf');
            attach.setFileName('Attachment.pdf');
            attach.setInline(false);
            attach.body =(!Test.isRunningTest())?pdf.getContentAsPDF():Blob.valueOf('Test');
            /*if(!Test.isRunningTest()){
                attach.body = pdf.getContentAsPDF();
            }else{
                attach.body=Blob.valueOf('Test');
             }*/
            //attach.Body = pdf.getContentAsPDF();
            String owa = [select id, Address from OrgWideEmailAddress where Address='records@wgu.edu'].id;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setUseSignature(false);
            mail.setToAddresses(new String[] { sp.Student__r.Email});
            mail.setSubject(et.subject);
            String body='<html><body>'
                        +'<table>'
                        +'<tr>'
                        +'<td>Dear '+sp.Student__r.FirstName+'</td><td></td><td></td><td></td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">&nbsp;</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">Please find attached the letter you requested from the Office of the Registrar</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">&nbsp;</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">If we can assist you in any further way please do not hesitate to contact us.</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">&nbsp;</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">Sincerely,</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">&nbsp;</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">Student Records</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">Office of the Registrar</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">Western Governors University</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">4001 South 700 East, Suite 700</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">Salt Lake City, UT 84107</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">877-435-7948 x 3146</td>'
                        +'</tr>'
                        +'<tr>'
                        +'<td colspan="4">records@wgu.edu</td>'
                        +'</tr>'
                        +'</body></html>';
            
            mail.setHtmlBody(body);
            mail.setOrgWideEmailAddressId(owa);
            //mail.setTargetObjectId(sp.Student__r.Id);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
       }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Email Sent Successfully'));
        return null;
    }
    
    public PageReference cancel(){
        return new PageReference('/'+spId);
    }
    public PageReference cancel1(){
        PageReference pf=new PageReference('/apex/createpdf?id='+spId);
        pf.setRedirect(true);
        return pf;
    }

}