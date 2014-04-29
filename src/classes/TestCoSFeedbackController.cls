/*****************************************************************************************
* Name: TestCoSFeedbackController
* Author: Will Slade
* Purpose: Test class CoSFeedbackController
* Revisions: 
*    - 2/7/13 Created Class
******************************************************************************************/

@isTest
global class TestCoSFeedbackController
{
    static testMethod void TestCoSFeedbackControllerAsStaff()
    {
        Profile adminProf = [select id from profile where name='System Administrator']; 
        User au = new User(alias = 'admin723', email='adminuser@testorg.com.wgu.edu', 
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
        localesidkey='en_US', profileid = adminProf.Id, 
        timezonesidkey='America/Los_Angeles', username='adminuser834@testorg.com');                
        
        Test.startTest();
        
        System.runAs(au)
        {
            ProgramFeedback__c testPF = new ProgramFeedback__c();        
            
            ApexPages.StandardController stdCont = new ApexPages.standardController(testPF);
                   
            CoSFeedbackController testController = new CoSFeedbackController(stdCont);
            
            Blob attachBody = Blob.valueOf('attachment body');
            Attachment attach = new Attachment(Name = 'testfeedbackattach.pdf', Body = attachBody);            
            
            testController.FbAttachment = attach;
            testController.getFbAttachment();        
            testController.getColleges();
            testController.getUserFullName();
            testController.getUserRole();
            testController.saveWithAttachment();                                    
        }
        Test.stopTest();
        
        List<ProgramFeedback__c> pfList = [SELECT Id, SubmitterRole__c FROM ProgramFeedback__c WHERE OriginalFeedbackSubmitter__c = :au.Id];
        
        System.assert(pfList.size() == 1, 'Found newly created Program Feedback record');
        System.assertEquals(pfList[0].SubmitterRole__c, 'Staff/Other', 'Correct Submitter Role assigned to Program Feedback record');
    }
    
    static testMethod void TestCoSFeedbackControllerAsMentor()
    {
        Profile mentorProf = [select id from profile where name='Mentor']; 
        User mu = new User(alias = 'ment723', email='mentoruser@testorg.com.wgu.edu', 
        emailencodingkey='UTF-8', lastname='Testing2', languagelocalekey='en_US', 
        localesidkey='en_US', profileid = mentorProf.Id, 
        timezonesidkey='America/Los_Angeles', username='mentoruser834@testorg.com');                
        
        Test.startTest();
        
        System.runAs(mu)
        {
            ProgramFeedback__c testPF = new ProgramFeedback__c();        
            
            ApexPages.StandardController stdCont = new ApexPages.standardController(testPF);
                   
            CoSFeedbackController testController = new CoSFeedbackController(stdCont);
            
            Blob attachBody = Blob.valueOf('attachment body');
            Attachment attach = new Attachment(Name = 'testfeedbackattach.pdf', Body = attachBody);            
            
            testController.FbAttachment = attach;
            testController.getFbAttachment();        
            testController.getColleges();
            testController.getUserFullName();
            testController.getUserRole();
            testController.saveWithAttachment();                                    
        }
        Test.stopTest();
        
        List<ProgramFeedback__c> pfList = [SELECT Id, SubmitterRole__c FROM ProgramFeedback__c WHERE OriginalFeedbackSubmitter__c = :mu.Id];
        
        System.assert(pfList.size() == 1, 'Found newly created Program Feedback record');
        System.assertEquals(pfList[0].SubmitterRole__c, 'Mentor/Mentor Manager', 'Correct Submitter Role assigned to Program Feedback record');
    }        
}