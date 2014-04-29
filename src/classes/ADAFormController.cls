public with sharing class ADAFormController {
    public ADAFile__c studentInfo {get;set;}
    //public String 
    public String confirm {get;set;}
    public Boolean flag {get;set;}
    
    public ADAFormController(ApexPages.StandardController acon){
        studentInfo = new ADAFile__c();
        flag= true;
    }
    public PageReference submit(){
        List<RecordType> rType = [SELECT ID FROM RecordType WHERE SobjectType='ADAFile__c' AND name = 'Referral' LIMIT 1];
        ID rTypeID = rType[0].ID;
        try{
            studentInfo.Status__c = 'Requested';
            studentInfo.RecordTypeId = rTypeID;
            studentInfo.Referrer__c = UserInfo.getUserId();
            studentInfo.Name = studentInfo.LastName__c+ ' , '+studentInfo.FirstName__c;
            insert studentInfo;
            //confirm = 'yes';
            flag= false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Your ADA Referral Form has been submitted.'));      
            
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You got an error.Please contact your Administrator.'));      
        }
    return null;
    }
    public PageReference cancel(){
            PageReference pf = new PageReference('/home/home.jsp'); 
            pf.setRedirect(true); 
            return pf;
    }
    public PageReference homepage(){
            PageReference pf = new PageReference('https://my.wgu.edu'); 
            pf.setRedirect(true); 
            return pf;
    }
    
}