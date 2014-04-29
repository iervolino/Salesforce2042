/*
This Controller is for Readmission VF page used by Students.
Author- Bhavadeep Raavi
*/

public with sharing class ReadmissionController{
    public Integer rowFlg{get;set;}
    public Boolean removeFlag{get;set;} 
    public StudentProcess__c stdProcess{get;set;}
    private String stdProcessAutoNum;
    public Boolean disFlag{get;set;} 
    public Boolean waiveFeeFlag{get;set;}
    public List<StdAdditionalInfo> studentProcessList{get;set;}
    public ReadmissionController(ApexPages.StandardController controller) {
            waiveFeeFlag=false;
            stdProcessAutoNum=Apexpages.currentpage().getParameters().get('StudentProcessAutoNumber__c');
            System.debug('stdProcessAutoNum '+stdProcessAutoNum);
            string userPidm = [select pidm__c from User where id=:UserInfo.getUserId()].pidm__c; 
            stdProcess=test.isRunningTest()?[select Id,FirstName__c,LastName__c,ApplicationInstitution__c,StudentID__c,Student__r.pidm__c, MailingStreet__c,MailingCity__c,MailingZip__c,MailingCountry__c,State__c,ProgramCode__c,WaiveFee__c ,ApplicationEmailAddress__c,ApplicationPhoneNumber__c,ApplicationStreetAddress1__c,ApplicationStreetAddress2__c,ApplicationCity__c,ApplicationState__c,ApplicationZipCode__c,College__c,ProgramName__c,ReadmissionDesiredDate__c,FinancePaymentType__c,ReadmissionAppeal__c,Agree__c,DoNotAgree__c from StudentProcess__c LIMIT 1]:[select Id,FirstName__c,LastName__c,ApplicationInstitution__c,StudentID__c,Student__r.pidm__c, MailingStreet__c,MailingCity__c,MailingZip__c,MailingCountry__c,State__c,ProgramCode__c,WaiveFee__c ,ApplicationEmailAddress__c,ApplicationPhoneNumber__c,ApplicationStreetAddress1__c,ApplicationStreetAddress2__c,ApplicationCity__c,ApplicationState__c,ApplicationZipCode__c,College__c,ProgramName__c,ReadmissionDesiredDate__c,FinancePaymentType__c,ReadmissionAppeal__c,Agree__c,DoNotAgree__c from StudentProcess__c where StudentProcessAutoNumber__c=:stdProcessAutoNum LIMIT 1];
            /*if (test.isRunningTest())
            {     
            stdProcess=[select Id,FirstName__c,LastName__c,ApplicationInstitution__c,StudentID__c,Student__r.pidm__c, MailingStreet__c,MailingCity__c,MailingZip__c,MailingCountry__c,State__c,ProgramCode__c,WaiveFee__c ,ApplicationEmailAddress__c,ApplicationPhoneNumber__c,ApplicationStreetAddress1__c,ApplicationStreetAddress2__c,ApplicationCity__c,ApplicationState__c,ApplicationZipCode__c,College__c,ProgramName__c,ReadmissionDesiredDate__c,FinancePaymentType__c,ReadmissionAppeal__c from StudentProcess__c LIMIT 1];
            }else{
            stdProcess=[select Id,FirstName__c,LastName__c,ApplicationInstitution__c,StudentID__c,Student__r.pidm__c, MailingStreet__c,MailingCity__c,MailingZip__c,MailingCountry__c,State__c,ProgramCode__c,WaiveFee__c ,ApplicationEmailAddress__c,ApplicationPhoneNumber__c,ApplicationStreetAddress1__c,ApplicationStreetAddress2__c,ApplicationCity__c,ApplicationState__c,ApplicationZipCode__c,College__c,ProgramName__c,ReadmissionDesiredDate__c,FinancePaymentType__c,ReadmissionAppeal__c from StudentProcess__c where StudentProcessAutoNumber__c=:stdProcessAutoNum LIMIT 1];
            }*/
            
            studentProcessList=new List<StdAdditionalInfo>();
            StdAdditionalInfo sai=new StdAdditionalInfo();
            studentProcessList.add(sai);
            rowFlg=1;
            if(stdProcess.Student__r!=null &&  stdProcess.Student__r.pidm__c!=userPidm){
                 disFlag=true;
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You do not have the required permission to access this record.   If you believe this message is in error, please contact the Student Records Department at 877-435-7948 x 3146 or by email at readmission@wgu.edu.'));  
            }
            if(stdProcess!=null && stdProcess.ReadmissionDesiredDate__c!=null){
                 disFlag=true;
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Your appeal for readmission has already been submitted and is currently being reviewed. If you have questions concerning your readmission request please contact Student Records at 877-435-7948 x 3146 or by email at readmission@wgu.edu.'));  
            }
            
            
    }
    public PageReference saveReadmission(){
        String sDesc='';
        Boolean flag=false;
        
        for(StdAdditionalInfo tsa:studentProcessList){
            if(tsa.inName!=null && tsa.inName!=''){
                sDesc=sDesc+tsa.inName+'\n '+' , ';    
            }              
            if(tsa.doa!=null && tsa.doa!=''){
                sDesc=sDesc+tsa.doa+'\n'+' , ';    
            }        
        }
         try{
        if(stdProcess.Agree__c==False && stdProcess.DoNotAgree__c==False){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please check Agree or Do Not Agree under the Terms and Conditions.'));                   
            flag=true;
        }
        if(stdProcess.Agree__c==True && stdProcess.DoNotAgree__c==True){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please check either Agree or Do Not Agree under the Terms and Conditions.  You cannot select both.'));                   
            flag=true;
        }
        if(stdProcess.College__c==null || stdProcess.College__c==''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please enter the Desired College'));                   
            flag=true;
        }
        if(stdProcess.ProgramName__c==null || stdProcess.ProgramName__c==''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please enter the Desired Program Name'));                   
            flag=true;
        }
        if(stdProcess.ReadmissionDesiredDate__c==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please enter the Desired Readmission Date'));                   
            flag=true;
        }else{
            Date reAdmDesireDate=stdProcess.ReadmissionDesiredDate__c;
            Date dateAfter4weeks=Date.today().adddays(28);
            if(reAdmDesireDate<=dateAfter4weeks){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Desired Readmission Date must be at least 4 weeks out.'));                   
                flag=true;
            }
        }
        if(stdProcess.FinancePaymentType__c==null || stdProcess.FinancePaymentType__c==''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please enter the Payment type'));                   
            flag=true;
        }
        
        if(stdProcess.ReadmissionAppeal__c==null || stdProcess.ReadmissionAppeal__c==''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please enter the Re-Admission Appeal'));                   
            flag=true;
        }
        if(flag==true){
        return null;
        }
        
       
            stdProcess.ApplicationInstitution__c=sDesc;
            update stdProcess;
            disFlag = true;
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: There is problem in updating'));                   
            return null;
        }
        String submitMsg='';
        waiveFeeFlag=stdProcess.WaiveFee__c?false:true;
        submitMsg=stdProcess.WaiveFee__c?'Thank you for submitting your formal appeal requesting readmission to WGU. We will begin your re-entry evaluation and notify you of our decision once your request has been reviewed.  If you need further assistance please feel free to contact Student Records at (877) 435-7948 x 3146 or readmission@wgu.edu.':'Thank you for submitting your formal appeal requesting readmission to WGU.  We will begin your re-entry evaluation as soon as your readmission fee has been paid. We will notify you of our decision once your request has been reviewed.   If you need further assistance please feel free to contact us. Student Records, Phone: 877-435-7948 x 3146, Email: readmission@wgu.edu. Bursar Phone: 877-435-7948 x 310 Email: bursar@wgu.edu';
       /* if(stdProcess.WaiveFee__c==true){
            waiveFeeFlag=false;
            submitMsg=;    
        }else{
            waiveFeeFlag=true;
            submitMsg=
        }*/
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,submitMsg));
         return null;
    }
    public PageReference cancel(){
            PageReference pf = new PageReference('https://my.wgu.edu'); 
            pf.setRedirect(true); 
            return pf;
    }
    public PageReference incrementRowFlg(){
        system.debug('rowFlag ==> '+rowFlg);
            if(rowFlg<5){
                StdAdditionalInfo sai=new StdAdditionalInfo();
                studentProcessList.add(sai);
                rowFlg=rowFlg+1;
                removeFlag=false;
            }
            return null;
    }
    public PageReference decrementRowFlg(){
        system.debug('rowFlag ==> '+rowFlg);
            if(rowFlg>1){
                rowFlg=rowFlg-1;
                studentProcessList.remove(rowFlg);
            }
            return null;
    }
    public class StdAdditionalInfo{
            public String inName{get;set;}
            public String doa{get;set;}
    }
}