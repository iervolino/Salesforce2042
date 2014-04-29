/*
This Controller is for Withdrawal VF page used by Students.
Author- Bhavadeep Raavi
*/
public with sharing class WithdrawalController{
    public Contact studentInfo{get;set;}
    public Boolean disFlag{get;set;}
    public StudentProcess__c sp{get{
        if(sp==null){
            sp=new StudentProcess__c();
            return sp;
        }else{
            return sp;
        }
    }set;}
    public WithdrawalController(){
        try{
            string userPidm = [select pidm__c from User where id=:UserInfo.getUserId()].pidm__c; 
            studentInfo=[select Id,Name,firstname,Lastname,studentID__c,Mentor__r.Name,TermEndDate__c from Contact where firstName=:UserInfo.getFirstName() and lastName=:UserInfo.getLastName() and PIDM__c =:userPidm  limit 1];    
            List<StudentProcess__c> spLst=[select id,ApplicationReceived__c from StudentProcess__c where ApplicationReceived__c!=null and Student__c=:studentInfo.Id order by ApplicationReceived__c desc];
            system.debug('raaviList '+spLst);
            system.debug('raaviDate '+spLst[0].ApplicationReceived__c);
            if(spLst!=null && spLst.size()>0 && spLst.get(0)!=null && spLst.get(0).ApplicationReceived__c.date().daysBetween(Date.today())<=30){
                system.debug('raaviDate1 '+spLst[0].ApplicationReceived__c);
                System.debug('spLst.get(0).ApplicationReceived__c.date() : '+Date.today().daysBetween(spLst.get(0).ApplicationReceived__c.date()));
                disFlag=true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Your withdrawal request has already been submitted.  If you have questions concerning your withdrawal please contact Student Services at (866) 903-0110.'));          
            }
        }catch(Exception e){
             disFlag=true;
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Your record cannot be found.Please contact WGU'));      
        }
    }
    public PageReference submit(){
        try{
            sp.student__c=studentInfo.Id;
            sp.Name=studentInfo.lastname+','+studentInfo.firstname+' '+'Withdraw Request';
            sp.recordTypeId =  [Select ID from RecordType where DeveloperName='Withdrawal' and sObjectType = 'StudentProcess__c' ].id; 
            sp.ApplicationReceived__c=System.now();
            system.debug('multi '+sp.reason__c);
            if(sp.reason__c.split(';').size()>5){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select a maximum of 5 values.'));  
                return null;    
            }
            insert sp;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Thank you for your request.  A withdrawal counselor will be in touch with you soon.  In the meantime, if you have any questions, please contact Student Services at (866) 903-0110.')); 
            disFlag=true;     
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You got an error.Please contact your Administrator.'));      
        }
    return null;
    }
    public PageReference cancel(){
            PageReference pf = new PageReference('https://my.wgu.edu'); 
            pf.setRedirect(true); 
            return pf;
    }
    
}