/*
Test class for Code coverage of ScholarshipController
Author- Bhavadeep Raavi
Modified - Bhavedeep Raavi 1-25-2013 For Person Account Conversion
Modified - Mike Slade 1-25-2013 Improved assertions, set seeAllData to False
*/
@isTest(SeeAllData=false)
private class TestScholarshipController{

private static testmethod void ScholarshipCtrl(){
    Test.startTest();
    ScholarshipController sc=new ScholarshipController();
    sc.nameFile='TestAppAtt';
  User testUser = [Select id from User 
                   where Profile.Name = 'Scholarship User' 
                   AND isActive = true 
                   AND UserRole.Name = 'Scholarship User' LIMIT 1];
    System.RunAs( testUser ) 
    {          
        Contact  con1 = new Contact(FirstName = 'TestFname1', LastName = 'TestLname1', PIDM__c='9');
        insert con1;
        System.assertEquals('TestFname1',con1.FirstName);
        Contact  con2 = new Contact(FirstName = 'TestFname2', LastName = 'TestLname2', PIDM__c='10');
        insert con2;
        System.assertEquals('TestFname2',con2.FirstName);
        Contact  con3 = new Contact(FirstName = 'TestFname3', LastName = 'TestLname3', PIDM__c='11');
        insert con3;
        System.assertEquals('TestFname3',con3.FirstName);
        Contact  con4 = new Contact(FirstName = 'TestFname4', LastName = 'TestLname4', PIDM__c='12');
        insert con4;
        System.assertEquals('TestFname4',con4.FirstName);
        id FinAppRT = [SELECT Id FROM RecordType WHERE Name = 'Scholarship' AND SobjectType = 'FinancialApplication__c' LIMIT 1].id;
        id FinReqRT = [SELECT Id FROM RecordType WHERE Name = 'FinRequirement' AND SobjectType = 'KeyValue__c' LIMIT 1].id;
        KeyValue__c TestReq = new KeyValue__c(RecordTypeId=FinReqRT,Name='test', value__c='Testing' );
        insert TestReq;
        RequirementRule__c ReqRule= new RequirementRule__c(FinRequirement__c=TestReq.id,ImportFieldNumber__c=1, ImportFieldSatisfy__c =11 );
        insert ReqRule;
        Opportunity Opp = new Opportunity(Name='Mike Test',StageName='Prospect' ,StudentContact__c=con2.id, CloseDate=Date.today().addDays(10), account =con2.Account );
        insert Opp;
    String str='PIDM,id,Category,Applied On,View,Email,Name,"If you are employed with one of our partners, or your employer is affiliated with one of our partner corporations, please select your employer from the list:","If selected your employer from the list above, please upload proof of employment here:",Are you a member of any of the following?,What is your current military status?,"If you are active duty or spouse of active duty military personnel, please upload proof of military affiliation:",Adjusted Gross Income\n';
    str=str+'9,5742,Submitted,'+Datetime.now().addDays(-2).format('MM/dd/yyyy')+',"<a href=""/admin/opportunities/41/applications/5742"">View</a>",mford8@my.wgu.edu,Mandy Ford,None of the Above,,None of the Above,I am not affiliated with any military service,"<a href="/admin/opportunities/41/applications/5742">View</a>",21410\n';
    str=str+'10,11075,Submitted,'+Datetime.now().addDays(-2).format('MM/dd/yyyy')+',"<a href=""/admin/opportunities/41/applications/11075"">View</a>",wxwax@my.wgu.edu,Kerrin Weatherwax,None of the Above,,Phi Theta Kappa,Spouse of Active Duty Military Personnel,,54599\n';
    str=str+'11,11079,Submitted,'+Datetime.now().addDays(-2).format('MM/dd/yyyy')+',"<a href=""/admin/opportunities/41/applications/11079"">View</a>",dgonz16@my.wgu.edu,Damian Gonzales,None of the Above,,None of the Above,I am not affiliated with any military service,,21410,87260\n';
    //fail to load due to date out of range
    str=str+'12,11082,Submitted,'+Datetime.now().addDays(-10).format('MM/dd/yyyy')+',"<a href=""/admin/opportunities/41/applications/11082"">View</a>",gclarks@my.wgu.edu,Genesis Clark-Singh,Catholic-Healthcare West,"<a href=""/documents/1677"" target=""_blank"">View Document</a>",None of the Above,I am not affiliated with any military service,,152962\n';
    //fail to load no pidm
    str=str+',5742,Submitted,,,mford8@my.wgu.edu,Mandy Ford,None of the Above,,None of the Above,I am not affiliated with any military service,,21410\n';
    //fail to load, no url
    str=str+'9,5742,Submitted,'+Datetime.now().addDays(-2).format('MM/dd/yyyy')+',,mford8@my.wgu.edu,Mandy Ford,None of the Above,,None of the Above,I am not affiliated with any military service,,21410\n';
    
    sc.contentFile=Blob.valueOf(str);
    sc.ReadFile();
    List<FinancialApplication__c> res=sc.getuploadedFinApps();
    //System.debug('Test ==> '+res[0].Name);
    //System.assertEquals('10',res[0].Name);
    
    sc.saveFinApps();
    list<FinancialApplication__c> appLst=  [select id, student__r.pidm__c from financialApplication__c where recordTypeId=:FinAppRT];
    System.assert(appLst.size()==3,'Records Created with Record Type - Size '+ appLst.size());
    
    appLst=[select id, student__r.pidm__c from financialApplication__c where recordTypeId=:FinAppRT and opportunity__c != null];
    System.assert(appLst.size()==1,'Records Created with Opportunity - Size '+ appLst.size());
    
    list<FinancialRequirement__c> reqLst=  [select id from financialRequirement__c];
    System.assert(reqLst.size()==3,'Requirements Created - Size '+ appLst.size());
    
    reqLst=  [select id from financialRequirement__c where SatisfiedIndicator__c='Y'];
    System.assert(reqLst.size()==1,'Requirements Satisfied '+ appLst.size());
    
    //update one of the records to see if it updates
    String str1='PIDM,id,Category,Applied On,View,Email,Name,"If you are employed with one of our partners, or your employer is affiliated with one of our partner corporations, please select your employer from the list:","If selected your employer from the list above, please upload proof of employment here:",Are you a member of any of the following?,What is your current military status?,"If you are active duty or spouse of active duty military personnel, please upload proof of military affiliation:",Adjusted Gross Income\n';
    str1=str1+'11,11079,Submitted,'+Datetime.now().addDays(-2).format('MM/dd/yyyy')+',"<a href=""/admin/opportunities/41/applications/11079"">View</a>",dgonz16@my.wgu.edu,Damian Gonzales,None of the Above,,None of the Above,I am not affiliated with any military service,<a href="/admin/opportunities/41/applications/5742">View</a>,21410,87260\n';
    sc.contentFile=Blob.valueOf(str1);
    sc.ReadFile();
    List<FinancialApplication__c> res1=sc.getuploadedFinApps();
    sc.saveFinApps();
    
    for (financialApplication__c app : appLst)
    {
    	System.debug('Loaded People ' + app.student__r.pidm__c  );
    }
    
    //after the record is updated, field 11 is populated so it should be satisfied.
       reqLst=  [select id from financialRequirement__c where SatisfiedIndicator__c='Y'];
    System.assert(reqLst.size()==2,'Requirements Satisfied after update - Size '+ appLst.size());
  
    Test.stopTest();
       }
}
}