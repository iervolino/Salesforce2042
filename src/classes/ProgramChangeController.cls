/*
This Controller is for ProgramChange VF page used by Students.
Author- Bhavadeep Raavi
*/

public with sharing class ProgramChangeController{
    public StudentProcess__c stdProcess{get;set;}
    public String q1{get;set;}
    public String q2{get;set;}
    public String q3{get;set;}
    public String q4{get;set;}
    public String q5{get;set;}
    private String stdProcessAutoNum;
    public String Fname;
    public String Lname;
    public Boolean disFlag{get;set;} 
    public Boolean pceandnonpce{get;set;} 
    public ProgramChangeController(ApexPages.StandardController controller) {
            stdProcessAutoNum=Apexpages.currentpage().getParameters().get('StudentProcessAutoNumber__c');
            System.debug('stdProcessAutoNum '+stdProcessAutoNum); 
            string userPidm = [select pidm__c from User where id=:UserInfo.getUserId()].pidm__c; 
            
            stdProcess=test.isRunningTest()?[select Id,FirstName__c,LastName__c,Stage__c,ApplicationVerification__c,CatalogYear__c,NewCatalogTerm__c,NewProgramCode__c,NewDegreeProgram__r.Name,Type__c,Student__r.pidm__c, Student__r.MentorName__c,MentorEmail__c,StudentID__c,ProgramCode__c from StudentProcess__c LIMIT 1]:[select Id,FirstName__c,LastName__c,Stage__c,ApplicationVerification__c,CatalogYear__c,NewCatalogTerm__c,NewProgramCode__c,NewDegreeProgram__r.Name,Type__c,Student__r.pidm__c, Student__r.MentorName__c,MentorEmail__c,StudentID__c,ProgramCode__c from StudentProcess__c where StudentProcessAutoNumber__c=:stdProcessAutoNum LIMIT 1];
            /*if (test.isRunningTest())
            {          
            stdProcess=[select Id,FirstName__c,LastName__c,Stage__c,ApplicationVerification__c,CatalogYear__c,NewCatalogTerm__c,NewProgramCode__c,Type__c,Student__r.pidm__c, Student__r.MentorName__c,MentorEmail__c,StudentID__c,ProgramCode__c from StudentProcess__c LIMIT 1];
            }else{
            stdProcess=[select Id,FirstName__c,LastName__c,Stage__c,ApplicationVerification__c,CatalogYear__c,NewCatalogTerm__c,NewProgramCode__c,Type__c,Student__r.pidm__c, Student__r.MentorName__c,MentorEmail__c,StudentID__c,ProgramCode__c from StudentProcess__c where StudentProcessAutoNumber__c=:stdProcessAutoNum LIMIT 1];
            }*/
            
            Fname = stdProcess.FirstName__c;
            Lname = stdProcess.LastName__c;
            if(stdProcess.Student__r!=null &&  stdProcess.Student__r.pidm__c!=userPidm){
                 disFlag=true;
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You do not have the required permission to access this record.   If you believe this message is in error, please contact the Student Records Department at 877-435-7948 x 3146 or by email at records@wgu.edu .'));  
            }
            if(stdProcess!=null && stdProcess.Stage__c!=null && stdProcess.Stage__c=='MOU Accepted by Student'){
                 disFlag=true;
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Your Memorandum of Understanding for your requested program change has already been submitted and is currently being reviewed.  If you have questions concerning your program change request please contact Student Records at 877-435-7948 x 3146 or by email at records@wgu.edu .'));  
            }
            
            
    }
    public PageReference approveNonPCE(){
        String sDesc='';
        Boolean flag=false;
               
        if(q1==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please answer all the questions below'));                   
            flag=true;
        }
        if(q2==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please answer all the questions below'));                   
            flag=true;
        }
        if(q3==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please answer all the questions below'));                   
            flag=true;
        }
        if(q4==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please answer all the questions below'));                   
            flag=true;
        }
        if(q5==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: Please answer all the questions below'));                   
            flag=true;
        }
        
        if(flag==true){
            return null;
        }
        String strNonPCE='';
        if(q1=='No' || q2=='No' || q3=='No' || q4=='No' || q5=='No'){
            strNonPCE='Your Memorandum of Understanding has been submitted to your Mentor. You answered no to one or more questions indicating that you do not fully understand the ramifications of your requested program change.   Your mentor will review your MOU and communicate directly with you to discuss your program change request further. Thank you!';            
        }else{
           strNonPCE='Your Memorandum of Understanding has been submitted to your Mentor. Once your mentor has reviewed your MOU, a Program Change Request will be submitted on your behalf.If any additional information is required, your Mentor will communicate that need directly to you. Thank you! ';             
        }
        try{
        stdProcess.ApplicationVerification__c='Q1- '+q1+','+'Q2- '+q2+','+'Q3- '+q3+','+'Q4- '+q4+','+'Q5- '+q5+' '+Fname+' '+Lname+' '+'Approved on'+'  '+datetime.now();
        stdProcess.Stage__c='MOU Accepted by Student';
        update stdProcess;
        disFlag = true;
        }catch(Exception e){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: There is problem in updating'));
        return null;
        }
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,strNonPCE));
         return null;
    }
    public PageReference approvePCE(){
        
         
        try{
            stdProcess.ApplicationVerification__c='Verified'+' '+datetime.now();
            stdProcess.Stage__c='MOU Accepted by Student';
            update stdProcess;
            disFlag = true;
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'ERROR: There is problem in updating'));                   
            return null;
        }
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Thank you for completing the Memorandum of Understanding for your requested program change. Your mentor has been notified and will be in contact with you if any further information is needed.'));
         return null;
    }
    public PageReference cancel(){
            PageReference pf = new PageReference('https://my.wgu.edu'); 
            pf.setRedirect(true); 
            return pf;
    }
}