/*
This Controller is for Career Services Appointment Request VF page used by Students.
Author- Bhavadeep Raavi
*/
public with sharing class CareerServicesApptRequestController{
    public Contact studentInfo{get;set;}
    public Boolean disFlag{get;set;}
    public string fileName{get;set;} 
    public Blob fileBody{get;set;}  

    public Attachment attachment {
      get {
      if (attachment == null)
        attachment = new Attachment();
      return attachment;
    }
      set;
    }
    public CareerServices__c cs{get{
        if(cs==null){
            cs=new CareerServices__c();
            return cs;
        }else{
            return cs;
        }
    }set;}
    public CareerServicesApptRequestController(){
        try{
            
            string userPidm = [select pidm__c from User where id=:UserInfo.getUserId()].pidm__c; 
            studentInfo=[select Id,Name,firstname,Lastname,studentID__c,Status__c,WGUDegreeProgram__r.Name,College__c,Phone,Email from Contact where firstName=:UserInfo.getFirstName() and lastName=:UserInfo.getLastName() and PIDM__c =:userPidm  limit 1];    
            
        }catch(Exception e){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You will need to log in to the WGU Portal to access this form. If you have forgotten your username or password for the WGU portal, please contact Student Services at 1-866-903-0110 or studentservices@wgu.edu. They are available 6am-Midnight (MT) Mon-Fri and 10am-7pm (MT) Sat-Sun'));      
        }
    }
    public PageReference submit(){
         try{
            cs.student__c= studentInfo.Id;
            cs.FirstName__c = studentInfo.FirstName;
            cs.LastName__c = studentInfo.LastName;
            cs.Email__c = studentInfo.Email;
            cs.Phone__c = studentInfo.Phone;
            insert cs;
            
            disFlag=true;     
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Thank you for your request.')); 
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You got an error.Please contact your Administrator.'));      
        }
        try{
          //Attachment myAttachment  = new Attachment();  
          attachment.ParentId = cs.Id;
          insert attachment;  
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error in attaching your file.'));      
        }
    return null;
    }
    public PageReference cancel(){
            PageReference pf = new PageReference('https://my.wgu.edu'); 
            pf.setRedirect(true); 
            return pf;
    }
    
}