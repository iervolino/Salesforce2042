/*
This Controller is for TermBreakRequest VF page used by Students.
Author- Bhavadeep Raavi

Revised: 12/02/2013 Comment out work submitted after term and graduation application submitted questions - Kristin Hasna
3/10/2014: Fixed a bug where the students contact was being looked up with unnecessary criteria such as last name - Austin Poulter
*/

public with sharing class TermBreakRequestController{
    public Boolean disFlag{get;set;}
    public Boolean msgFlag{get;set;}
    public Boolean stdIdFlag{get;set;}
    public string  stdId{get;set;}

    
    public Contact studentInfo{get;set;}
    public List<Contact> studentInfoList{get;set;}
    public StudentProcess__c sp{get{
        if(sp==null){
            sp=new StudentProcess__c();
            return sp;
        }else{
            return sp;
        }
    }set;}
    public List<selectoption> TBRequestedMonths{get;set;}
    public String selReqMonths{get;set;}
    
    public TermBreakRequestController(){
        TBRequestedMonths = new List<selectoption>();
        TBRequestedMonths.add(new selectoption('','--None--'));
        TBRequestedMonths.add(new selectoption('1','1 month'));
        TBRequestedMonths.add(new selectoption('2','2 months'));
        TBRequestedMonths.add(new selectoption('3','3 months'));
        
        User u = [select pidm__c, Profile.Name from User where id=:UserInfo.getUserId()];
        string userPidm = u.pidm__c; 
        String usrProfileName = u.Profile.Name;
        
        if(usrProfileName =='Student Profile'){
            //studentInfoList=[select Id,Name,firstname,Lastname,BalanceDue__c,CumulativeSAP__c,PlannedGraduationDate__c,studentID__c,Mentor__c,MentorName__c,Mentor__r.Email,MailingState,MailingCity,Phone from Contact where firstName=:UserInfo.getFirstName() and lastName=:UserInfo.getLastName()  and PIDM__c =:userPidm  limit 1]; 
            studentInfoList=[select Id,Name,firstname,Lastname,BalanceDue__c,CumulativeSAP__c,PlannedGraduationDate__c,studentID__c,Mentor__c,MentorName__c,Mentor__r.Email,MailingState,MailingCity,Phone from Contact where PIDM__c =:userPidm  limit 1]; 
        }else if(stdId == null || stdId =='' ){
            disflag = true;
            stdIdFlag = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You are not a Student.Please enter the student Id below'));
        }
        if(studentInfoList!=null && studentInfoList.size()>0){
            studentInfo=studentInfoList.get(0);
        }
    }
    public PageReference saveTermBreak(){
         try{    
         
           /*Set<String> monthSet = new Set<String>{'1','2','3'};
           String trMonths = String.valueOf(sp.TBRequestedMonths__c).trim();
           if(trMonths!=null && !monthSet.contains(trMonths)){
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter 1 or 2 or 3'));
               //msgFlag = false;
               return null;
                 
            }*/
            system.debug('raavimonth =========='+selReqMonths);
            if(selReqMonths  == '' || selReqMonths == null){
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter number of months value'));
               return null;
                 
            }
            msgFlag = true;
            if(studentInfo.BalanceDue__c !=null && studentInfo.BalanceDue__c ==true ){ 
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Your student account currently shows a balance.  Please check the payment link on your student portal Resources tab, and with questions, contact the Bursar (877-435-7948 ext. 3105).  When the balance is paid, we can discuss your Term Break request.')); 
              msgFlag = false;
              stdIdFlag = false;
            }
            /*if(studentInfo.CumulativeSAP__c !=null && studentInfo.CumulativeSAP__c <50){
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Request Denied - Academic Eligibility'));
               msgFlag = false;  
            }*/
            /*if(sp.TBGradAppSubmitted__c !=null && sp.TBGradAppSubmitted__c  == 'Yes'){
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Congratulations as you prepare to graduate!  Contact your mentor to discuss final requirements.  A Term Break will only delay your graduation.'));
               msgFlag = false;
               stdIdFlag = false;     
            }*/
            
            sp.student__c=studentInfo.Id;
            sp.Name=studentInfo.lastname+','+studentInfo.firstname+' '+'Term Break';
            sp.recordTypeId =  [Select ID from RecordType where DeveloperName='TermBreak' and sObjectType = 'StudentProcess__c' ].id;
            sp.stage__c = 'New';
            sp.Status__c = 'New'; 
            sp.TBRequestedMonths__c=Integer.ValueOf(selReqMonths);
            insert sp;
            
           
            if(msgFlag == true){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Thank you for completing the Term Break Request form. A counselor will contact you within 24 to 48 hours through your WGU email to setup a scheduled counsel call. Please make sure to check your email and respond back quickly so we can better serve you.'));
                stdIdFlag = false;
            
            }
             disFlag=true;
             
            }catch(exception e){
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You got some Error'));   
            }
    return null;
    }
    public PageReference cancel(){
         PageReference pf = new PageReference('https://my.wgu.edu'); 
         pf.setRedirect(true); 
         return pf;   
    }
    public PageReference getStudentRecord(){
          if(stdId != null){
                system.debug('raavi2 ==========='+stdId);
                
                studentInfoList=[select Id,Name,firstname,Lastname,BalanceDue__c,CumulativeSAP__c,PlannedGraduationDate__c,studentID__c,Mentor__c,MentorName__c,Mentor__r.Email,MailingState,MailingCity,Phone from Contact where StudentID__c =:stdId]; 
            
            if(studentInfoList == null || studentInfoList.size()==0){
                Integer len=stdId.length();               
                for(integer i=0;i<9-len;i++ ){
                   stdId='0'+stdId;                        
                } 
                system.debug('raavi3 ==========='+stdId);
                studentInfoList=[select Id,Name,firstname,Lastname,BalanceDue__c,CumulativeSAP__c,PlannedGraduationDate__c,studentID__c,Mentor__c,MentorName__c,Mentor__r.Email,MailingState,MailingCity,Phone from Contact where StudentID__c =:stdId]; 
            
            }
            }
            if(studentInfoList == null || studentInfoList.isEmpty()== true){
                stdIdFlag = true;
                
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter a valid student Id')); 
                return null;
            }
            if(studentInfoList!=null && studentInfoList.size()>0){
                studentInfo=studentInfoList.get(0);
                disflag = false;
                stdIdFlag = false;
            }
            
         PageReference pf = new PageReference('/apex/TermBreakrequest'); 
         pf.setRedirect(false); 
         return pf;   
    }
    //public void initialize(
    
}