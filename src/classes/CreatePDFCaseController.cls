/*
This Controller is used for CreatePDFCase ,PDFCasePage & PDFCasePageInv VF Pages.
Author - Bhavadeep Raavi
*/

public with sharing class CreatePDFCaseController{
    public List<SelectOption> emailTempsList{get;set;}
    public String selET{get;set;}
    public String content{get;set;}
    public case cs{get;set;}
    public Id csId{get;set;}
    public EmailTemplate emailTemp{get;set;}

    public CreatePDFCaseController(ApexPages.StandardController controller) {
        emailTempsList=new List<SelectOption>();
        String Id = [Select Id from Folder where DeveloperName='RecordsEmailTemplates' and AccessType ='Shared' LIMIT 1].Id;
        List<EmailTemplate> listEmailTemps=[select Id,name,body,HtmlValue  from EmailTemplate where FolderId =:Id and name like 'RECPDFCASE%' order By Name];
        for(EmailTemplate et:listEmailTemps){
            emailTempsList.add(new SelectOption(et.Id,et.Name));           
        }
        csId=controller.getRecord().Id;
        system.debug('raavi==========='+csId);
        cs=[select Contact.Email,NewMentorName__c,Description,Contact.CatalogYear__c,Contact.College__c,Contact.CumulativeSAP__c,Contact.CurrentTermCompletedCUs__c,Contact.CurrentTermEnrolledCUs__c,Contact.CurrentTerm__c,Contact.DateOfBirth__c,Contact.FAADate__c,Contact.FirstName,Contact.GradeLevel__c, 
            Contact.LastDateOfAAV__c,Contact.LastName,Contact.MailingCity,Contact.MailingCountry,Contact.MailingPostalCode,Contact.MailingState,Contact.MailingStreet,Contact.MentorName__c,Contact.Name,Contact.PlannedGraduationDate__c,Contact.ProgramCatalogTerm__c,Contact.ProgramCode__c,Contact.ProgramName__c,Contact.ProgramStartDate__c,Contact.ProgramSummary__c, 
            Contact.Salutation,Contact.SocialSecurityNumber__c,Contact.StatusDate__c,Contact.Status__c,Contact.StudentID__c,Contact.StudentMentor__c,Contact.StudentPreferredName__c,Contact.Suffix__c,Contact.TermCode__c,Contact.TermCompletedCUs__c,Contact.TermCUsandSAP__c,Contact.TermEndDate__c,Contact.TermEnrolledCUs__c,
            Contact.TermSap__c,Contact.TermStartDate__c,Contact.TotalAttemptedCUs__c,Contact.TotalCompletedCUs__c,Contact.TotalCUsandSAP__c,Contact.TransferCreditsTotal__c,Contact.WGUDegreeProgram__c from Case where id =:csId];
    }
    public PageReference emailContent(){
        String Id1 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates' and AccessType ='Shared'].Id;
        for(EmailTemplate et:[select id,name,body,HtmlValue from EmailTemplate where FolderId =:Id1 and Id=:selET]){
           content=et.HtmlValue;    
        }
        
        String Today='{!Today()}';
        
        String Description='{!Case.Description}';
        String NMentorName='{!Case.NewMentorName__c}';
        String AcaStanding='{!Contact.AcademicStanding__c}';
        String catalogyr='{!Contact.CatalogYear__c}';
        String college='{!Contact.College__c}';
        String cumSAP='{!Contact.CumulativeSAP__c}';
        String CurrTCCus='{!Contact.CurrentTermCompletedCUs__c}';
        String CurrTECus='{!Contact.CurrentTermEnrolledCUs__c}';
        String CurrTerm='{!Contact.CurrentTerm__c}';
        String DOB='{!Contact.DateOfBirth__c}';
        String FaaDate='{!Contact.FAADate__c}';
        String FName='{!Contact.FirstName}';
        String GLevel='{!Contact.GradeLevel__c}';
        String LDaav='{!Contact.LastDateOfAAV__c}';
        String LName='{!Contact.LastName}';
        String MCity='{!Contact.MailingCity}';
        String MCountry='{!Contact.MailingCountry}';
        String MPCode='{!Contact.MailingPostalCode}';
        String MState='{!Contact.MailingState}';
        String MStreet='{!Contact.MailingStreet}';
        String MName='{!Contact.MentorName__c}';
        String Name='{!Contact.Name}';
        String PGDate='{!Contact.PlannedGraduationDate__c}';
        String PCTerm='{!Contact.ProgramCatalogTerm__c}';
        String PCode='{!Contact.ProgramCode__c}';
        String PName='{!Contact.ProgramName__c}';
        String PSDate='{!Contact.ProgramStartDate__c}';
        String PSummary='{!Contact.ProgramSummary__c}';
        String Salutation='{!Contact.Salutation}';
        String Ssn='{!Contact.SocialSecurityNumber__c}';
        String SDate='{!Contact.StatusDate__c}';
        String Status='{!Contact.Status__c}';
        String StdId='{!Contact.StudentID__c}';
        String SMentor='{!Contact.StudentMentor__c}';
        String SPGDate='{!Contact.StudentPlannedGraduationDate__c}';
        String SPName='{!Contact.StudentPreferredName__c}';
        String Suffix='{!Contact.Suffix__c}';
        String TCode='{!Contact.TermCode__c}';
        String TCCus='{!Contact.TermCompletedCUs__c}';
        String TCSap='{!Contact.TermCUsandSAP__c}';
        String TEDate='{!Contact.TermEndDate__c}';
        String TECus='{!Contact.TermEnrolledCUs__c}';
        String TSap='{!Contact.TermSap__c}';
        String TSDate='{!Contact.TermStartDate__c}';
        String TACus='{!Contact.TotalAttemptedCUs__c}';
        String TotalCCus='{!Contact.TotalCompletedCUs__c}';
        String TotalCSap='{!Contact.TotalCUsandSAP__c}';
        String TCT='{!Contact.TransferCreditsTotal__c}';
        String WGUDP='{!Contact.WGUDegreeProgram__c}';

        String Symbol=']]>';
        
       /* Boolean todayFlag =content.contains(Today);        
        if(todayFlag){
            content=content.replace(Today,Date.Today().format());
        }*/
        content = content.contains(Today)?content.replace(Today,Date.Today().format()):content;
        
        content =  content.contains(Description)?  ( (cs.Description!=null)? content.replace(Description,cs.Description): content.replace(Description,'null') ) : content;
        content =  content.contains(NMentorName)?  ( (cs.NewMentorName__c!=null)? content.replace(NMentorName,cs.NewMentorName__c): content.replace(NMentorName,'null') ) : content;
        content =  content.contains(AcaStanding)?  ( (cs.Contact.AcademicStanding__c!=null)? content.replace(AcaStanding,cs.Contact.AcademicStanding__c): content.replace(AcaStanding,'null') ) : content;
        content =  content.contains(catalogyr)?  ( (cs.Contact.CatalogYear__c!=null)? content.replace(catalogyr,cs.Contact.CatalogYear__c): content.replace(catalogyr,'null') ) : content;
        content =  content.contains(college)?  ( (cs.Contact.College__c!=null)? content.replace(college,cs.Contact.College__c): content.replace(college,'null') ) : content;
        content =  content.contains(cumSAP)?  ( (cs.Contact.CumulativeSAP__c!=null)? content.replace(cumSAP,cs.Contact.CumulativeSAP__c.format()): content.replace(cumSAP,'null') ) : content;
        content =  content.contains(CurrTCCus)?  ( (cs.Contact.CurrentTermCompletedCUs__c!=null)? content.replace(CurrTCCus,cs.Contact.CurrentTermCompletedCUs__c.format()): content.replace(CurrTCCus,'null') ) : content;
        content =  content.contains(CurrTECus)?  ( (cs.Contact.CurrentTermEnrolledCUs__c!=null)? content.replace(CurrTECus,cs.Contact.CurrentTermEnrolledCUs__c.format()): content.replace(CurrTECus,'null') ) : content;
        content =  content.contains(CurrTerm)?  ( (cs.Contact.CurrentTerm__c!=null)? content.replace(CurrTerm,cs.Contact.CurrentTerm__c): content.replace(CurrTerm,'null') ) : content;
        content =  content.contains(DOB)?  ( (cs.Contact.DateOfBirth__c!=null)? content.replace(DOB,cs.Contact.DateOfBirth__c): content.replace(DOB,'null') ) : content;
        content =  content.contains(FaaDate)?  ( (cs.Contact.FAADate__c!=null)? content.replace(FaaDate,cs.Contact.FAADate__c.format()+''): content.replace(FaaDate,'null') ) : content;
        content =  content.contains(FName)?  ( (cs.Contact.FirstName!=null)? content.replace(FName,cs.Contact.FirstName): content.replace(FName,'null') ) : content;
        content =  content.contains(GLevel)?  ( (cs.Contact.GradeLevel__c!=null)? content.replace(GLevel,cs.Contact.GradeLevel__c): content.replace(GLevel,'null') ) : content;
        content =  content.contains(LDaav)?  ( (cs.Contact.LastDateOfAAV__c!=null)? content.replace(LDaav,cs.Contact.LastDateOfAAV__c.format()+''): content.replace(LDaav,'null') ) : content;
        content =  content.contains(LName)?  ( (cs.Contact.LastName!=null)? content.replace(LName,cs.Contact.LastName): content.replace(LName,'null') ) : content;
        content =  content.contains(MCity)?  ( (cs.Contact.MailingCity!=null)? content.replace(MCity,cs.Contact.MailingCity): content.replace(MCity,'null') ) : content;
        content =  content.contains(MCountry)?  ( (cs.Contact.MailingCountry!=null)? content.replace(MCountry,cs.Contact.MailingCountry): content.replace(MCountry,'null') ) : content;
        content =  content.contains(MPCode)?  ( (cs.Contact.MailingPostalCode!=null)? content.replace(MPCode,cs.Contact.MailingPostalCode): content.replace(MPCode,'null') ) : content;
        content =  content.contains(MState)?  ( (cs.Contact.MailingState!=null)? content.replace(MState,cs.Contact.MailingState): content.replace(MState,'null') ) : content;
        content =  content.contains(MStreet)?  ( (cs.Contact.MailingStreet!=null)? content.replace(MStreet,cs.Contact.MailingStreet): content.replace(MStreet,'null') ) : content;
        content =  content.contains(MName)?  ( (cs.Contact.MentorName__c!=null)? content.replace(MName,cs.Contact.MentorName__c): content.replace(MName,'null') ) : content;
        content =  content.contains(Name)?  ( (cs.Contact.Name!=null)? content.replace(Name,cs.Contact.Name): content.replace(Name,'null') ) : content;
        content =  content.contains(PGDate)?  ( (cs.Contact.PlannedGraduationDate__c!=null)? content.replace(PGDate,cs.Contact.PlannedGraduationDate__c.format()+''): content.replace(PGDate,'null') ) : content;
        content =  content.contains(PCTerm)?  ( (cs.Contact.ProgramCatalogTerm__c!=null)? content.replace(PCTerm,cs.Contact.ProgramCatalogTerm__c): content.replace(PCTerm,'null') ) : content;
        content =  content.contains(PCode)?  ( (cs.Contact.ProgramCode__c!=null)? content.replace(PCode,cs.Contact.ProgramCode__c): content.replace(PCode,'null') ) : content;
        content =  content.contains(PName)?  ( (cs.Contact.ProgramName__c!=null)? content.replace(PName,cs.Contact.ProgramName__c): content.replace(PName,'null') ) : content;
        content =  content.contains(PSDate)?  ( (cs.Contact.ProgramStartDate__c!=null)? content.replace(PSDate,cs.Contact.ProgramStartDate__c.format()+''): content.replace(PSDate,'null') ) : content;
        content =  content.contains(PSummary)?  ( (cs.Contact.ProgramSummary__c!=null)? content.replace(PSummary,cs.Contact.ProgramSummary__c): content.replace(PSummary,'null') ) : content;
        content =  content.contains(Salutation)?  ( (cs.Contact.Salutation!=null)? content.replace(Salutation,cs.Contact.Salutation): content.replace(Salutation,'null') ) : content;
        content =  content.contains(Ssn)?  ( (cs.Contact.SocialSecurityNumber__c!=null)? content.replace(Ssn,cs.Contact.SocialSecurityNumber__c): content.replace(Ssn,'null') ) : content;
        content =  content.contains(SDate)?  ( (cs.Contact.StatusDate__c!=null)? content.replace(SDate,cs.Contact.StatusDate__c.format()+''): content.replace(SDate,'null') ) : content;
        content =  content.contains(Status)?  ( (cs.Contact.Status__c!=null)? content.replace(Status,cs.Contact.Status__c): content.replace(Status,'null') ) : content;
        content =  content.contains(StdId)?  ( (cs.Contact.StudentID__c!=null)? content.replace(StdId,cs.Contact.StudentID__c): content.replace(StdId,'null') ) : content;
        content =  content.contains(SMentor)?  ( (cs.Contact.StudentMentor__c!=null)? content.replace(SMentor,cs.Contact.StudentMentor__c): content.replace(SMentor,'null') ) : content;
        content =  content.contains(SPGDate)?  ( (cs.Contact.StudentPlannedGraduationDate__c!=null)? content.replace(SPGDate,cs.Contact.StudentPlannedGraduationDate__c): content.replace(SPGDate,'null') ) : content;
        content =  content.contains(SPName)?  ( (cs.Contact.StudentPreferredName__c!=null)? content.replace(SPName,cs.Contact.StudentPreferredName__c): content.replace(SPName,'null') ) : content;
        content =  content.contains(Suffix)?  ( (cs.Contact.Suffix__c!=null)? content.replace(Suffix,cs.Contact.Suffix__c): content.replace(Suffix,'null') ) : content;
        content =  content.contains(TCode)?  ( (cs.Contact.TermCode__c!=null)? content.replace(TCode,cs.Contact.TermCode__c): content.replace(TCode,'null') ) : content;
        content =  content.contains(TCCus)?  ( (cs.Contact.TermCompletedCUs__c!=null)? content.replace(TCCus,cs.Contact.TermCompletedCUs__c.format()): content.replace(TCCus,'null') ) : content;
        content =  content.contains(TCSap)?  ( (cs.Contact.TermCUsandSAP__c!=null)? content.replace(TCSap,cs.Contact.TermCUsandSAP__c): content.replace(TCSap,'null') ) : content;
        content =  content.contains(TEDate)?  ( (cs.Contact.TermEndDate__c!=null)? content.replace(TEDate,cs.Contact.TermEndDate__c.format()+''): content.replace(TEDate,'null') ) : content;
        content =  content.contains(TECus)?  ( (cs.Contact.TermEnrolledCUs__c!=null)? content.replace(TECus,cs.Contact.TermEnrolledCUs__c.format()): content.replace(TECus,'null') ) : content;
        content =  content.contains(TSap)?  ( (cs.Contact.TermSap__c!=null)? content.replace(TSap,cs.Contact.TermSap__c.format()): content.replace(TSap,'null') ) : content;
        content =  content.contains(TSDate)?  ( (cs.Contact.TermStartDate__c!=null)? content.replace(TSDate,cs.Contact.TermStartDate__c.format()+''): content.replace(TSDate,'null') ) : content;
        content =  content.contains(TACus)?  ( (cs.Contact.TotalAttemptedCUs__c!=null)? content.replace(TACus,cs.Contact.TotalAttemptedCUs__c.format()): content.replace(TACus,'null') ) : content;
        content =  content.contains(TotalCCus)?  ( (cs.Contact.TotalCompletedCUs__c!=null)? content.replace(TotalCCus,cs.Contact.TotalCompletedCUs__c.format()): content.replace(TotalCCus,'null') ) : content;
        content =  content.contains(TotalCSap)?  ( (cs.Contact.TotalCUsandSAP__c!=null)? content.replace(TotalCSap,cs.Contact.TotalCUsandSAP__c): content.replace(TotalCSap,'null') ) : content;
        content =  content.contains(TCT)?  ( (cs.Contact.TransferCreditsTotal__c!=null)? content.replace(TCT,cs.Contact.TransferCreditsTotal__c.format()): content.replace(TCT,'null') ) : content;
        content =  content.contains(WGUDP)?  ( (cs.Contact.WGUDegreeProgram__c!=null)? content.replace(WGUDP,cs.Contact.WGUDegreeProgram__c): content.replace(WGUDP,'null') ) : content;
        
        Boolean SymFlag =content.contains(Symbol);        
        if(SymFlag){
            content=content.replace(Symbol,'');
        }
        
       return null;
    }
    public PageReference viewPDF(){
         PageReference pdf=new PageReference('/apex/PDFCasePage'); 
        return pdf;
    }
     public PageReference savePDF(){
        PageReference pdf = Page.PDFCasePageInv;
        Attachment attach = new Attachment();
        attach.ParentId = csId;
        attach.name = 'PDFPage.pdf';
        attach.body =(!Test.isRunningTest())?pdf.getContentAsPDF():Blob.valueOf('Test');
        insert attach;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Attachment Successfully Saved'));
        return null;
    }
    public PageReference sendEmail(){
       String Id2 = [Select Id from Folder where DeveloperName='RecordsEmailTemplates'].Id;
       for(EmailTemplate et:[select id,name,body,HtmlValue,subject from EmailTemplate where FolderId =:Id2 and Id=:selET]){
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            PageReference pdf =  Page.PDFCasePageInv;
            attach.setContentType('application/pdf');
            attach.setFileName('Attachment.pdf');
            attach.setInline(false);
            attach.body =(!Test.isRunningTest())?pdf.getContentAsPDF():Blob.valueOf('Test');
            String owa = [select id, Address from OrgWideEmailAddress where Address='records@wgu.edu'].id;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setUseSignature(false);
            mail.setToAddresses(new String[] { cs.Contact.Email});
            mail.setSubject(et.subject);
            String body='<html><body>'
                        +'<table>'
                        +'<tr>'
                        +'<td>Dear '+cs.Contact.Name+'</td><td></td><td></td><td></td>'
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
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
       }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Email Sent Successfully'));
        return null;
    }
    
    public PageReference cancel(){
        return new PageReference('/'+csId);
    }
    public PageReference cancel1(){
        PageReference pf=new PageReference('/apex/createpdfcase?id='+csId);
        pf.setRedirect(true);
        return pf;
    }

}