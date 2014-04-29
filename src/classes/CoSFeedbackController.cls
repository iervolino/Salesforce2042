public with sharing class CoSFeedbackController
{
    public Attachment fbAttachment { get;set; }
    public ProgramFeedback__c fb { get;set; }
    public string collegeOption { get;set; }
    public string userFullName { get;set; }
    public string userRole { get;set; }

    public CoSFeedbackController(ApexPages.StandardController controller) 
    {
        fbAttachment = new Attachment();
        fb = (ProgramFeedback__c)controller.getRecord();
        userFullName = this.getUserFullName();
        userRole = this.getUserRole();
    }
    
    public Attachment getFbAttachment()
    {
        return fbAttachment;
    }       
    
    public List<SelectOption> getColleges()
    {
        List<SelectOption> colleges = new List<SelectOption>();
        colleges.add(new SelectOption('Business', 'Business'));
        colleges.add(new SelectOption('Health Professions', 'Health Professions'));
        colleges.add(new SelectOption('Information Technology', 'Information Technology'));
        colleges.add(new SelectOption('Teachers College', 'Teachers College'));
        colleges.add(new SelectOption('General Education', 'General Education'));
        return colleges;
    }
    
    public String getUserFullName()
    {
        userFullName = UserInfo.getName();
        return userFullName;
    }
    
    public String getUserRole()
    {
        String thisProfileName = 'Staff/Other';

        if (UserInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'Student Profile' LIMIT 1].Id)
        {
            thisProfileName = 'Student';
        }
        else if (UserInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'Mentor' LIMIT 1].Id ||
                 UserInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'Mentor Manager' LIMIT 1].Id)
        {
            thisProfileName = 'Mentor/Mentor Manager';
        }
        return thisProfileName;
    }
    
    public PageReference saveWithAttachment()
    {        
        String queryString = 'SELECT QueueId FROM QueueSObject WHERE Queue.Name = \'Program Feedback Triage\' LIMIT 1';

        List<QueueSobject> queueList;                
        
        if (!Test.isRunningTest() && userRole.equals('Student')) 
        {
            RestAdapter ra = new RestAdapter();
            
            if (ra != null)
            {
                queueList = (List<QueueSObject>)ra.queryObjects(queryString); 
            }
            else
            {
                queueList = (List<QueueSObject>)Database.query(queryString);
            }
        } 
        else 
        { 
            queueList = (List<QueueSObject>)Database.query(queryString); 
        }
        
        fb.ownerId = UserInfo.getUserId();            
        fb.OriginalFeedbackSubmitter__c = UserInfo.getUserId();
        fb.college__c = collegeOption;
        fb.status__c = 'Open';
        fb.SubmitterRole__c = userRole;
        
        //Insert Program Feedback record with owner temporarily set as submitter
        insert fb;
        
        //Insert attachment while submitter is still the owner
        if (fbAttachment.body != null)
        {
            fbAttachment.parentId = fb.id;
            insert fbAttachment;
        }                
            
        //Fire the workflow to change the owner to the queue
        if (queueList.size() > 0)
        {                
            fb.changeOwner__c = true;
            update fb;
        }                                              
        
        PageReference pr = new PageReference('/apex/FeedbackReceived');
        pr.setRedirect(true);
        return pr;        
    }     
}