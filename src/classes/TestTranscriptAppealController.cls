/*
This Test Class is for TranscriptAppealController.
Author- Bhavadeep Raavi
No Sharing rules are enforced, the current sharing rules remain in effect
*/


@isTest
private class TestTranscriptAppealController {

    static testmethod void testAppeal(){

        Contact con = new Contact();
        con.LastName='testCon';
        insert con;
        system.assertEquals('testCon', con.LastName);    
       
        StudentCase__c sc = new StudentCase__c();
        sc.StudentCaseReason__c='Appeal';
        sc.Contact__c = con.Id;
        insert sc;
	    System.debug('================> ' + sc.Name);
        
        sc = [SELECT Id, Name, StudentCaseReason__c, Contact__c FROM StudentCase__c WHERE Id = :sc.Id LIMIT 1];

        Test.startTest();
	        PageReference pr = Page.TranscriptAppeal;
	        Test.setCurrentPage(pr);    
	        
	        pr.getParameters().put('Id', sc.Id);
	        ApexPages.StandardController stdController = new ApexPages.StandardController(sc);
	        TranscriptAppealController tacc = new TranscriptAppealController(stdController);
	        TranscriptAppealController.StdAdditionalInfo sai=new TranscriptAppealController.StdAdditionalInfo();
	        List<SelectOption> sGrade=sai.grade;
	        List<SelectOption> screditHrs=sai.creditHrs;
	        sai.inName='test in name';
	        sai.wguCrsCode='wgu code';
	        sai.wguCrsTitle='wgu title';
	        sai.inCrsCode='in crs code';
	        sai.yearAttended='2012';
	        sai.selGrades='A';
	        sai.selCreditHrs='2';
	        Attachment at=new Attachment();
	        at.name='atname';
	        at.body=Blob.valueOf('attachment body');
	        sai.appealAttachment=at;
	        List<TranscriptAppealController.StdAdditionalInfo> saiList=new List<TranscriptAppealController.StdAdditionalInfo>();
	        saiList.add(sai);
	        tacc.TranscriptsAppealList=saiList;
	        
	        tacc.incrementRowFlg();
	        tacc.decrementRowFlg();
	         
	        tacc.SaveAppeal();
	        sc.StudentCaseReason__c='Exclusion';
	        update sc;
	        system.assertEquals('Exclusion',sc.StudentCaseReason__c);
	                
        Test.stopTest();

	        TranscriptAppealController  tacc1= new TranscriptAppealController(stdController ); 
	        //tacc.incrementRowFlgEx();
	        //tacc.decrementRowFlgEx(); 
	        tacc.getContrStdCase();
	        TranscriptAppealController.StdExclusionInfo sei=new TranscriptAppealController.StdExclusionInfo();
	        List<SelectOption> sDegreeEarned=sei.degreeEarned;
	        List<SelectOption> sReasonforExclusion=sei.reasonforExclusion;
	        sei.inName='test in name';
	        sei.finAid=true;
	        sei.selDegreeEarned='Associate';
	        sei.selReasonforExclusion='School Not Accredited';
	        
	        Attachment at1=new Attachment();
	        at1.name='atname';
	        at1.body=Blob.valueOf('attachment body');
	        sei.adAttachment2=at1;
	        List<TranscriptAppealController.StdExclusionInfo> seiList=new List<TranscriptAppealController.StdExclusionInfo>();
	        seiList.add(sei);
	        tacc1.TranscriptsExclusionList=seiList;        
	        tacc1.SaveExclusion();
	        
	        tacc.Cancel();  

    } 
    
    static testmethod void testExclusion(){
        Contact con = new Contact();
        con.LastName='testCon';
        insert con;
        system.assertEquals('testCon', con.LastName);    
       
        StudentCase__c sc = new StudentCase__c();
        sc.StudentCaseReason__c='Exclusion';
        sc.Contact__c = con.Id;
        insert sc;
        
        sc = [SELECT Id, Name, StudentCaseReason__c, Contact__c FROM StudentCase__c WHERE Id = :sc.Id LIMIT 1];
        
        system.assertEquals('Exclusion',sc.StudentCaseReason__c);
        
        System.debug('================> ' + sc.Name);
        
        Test.startTest();
	        PageReference pr = Page.TranscriptAppeal;
	        Test.setCurrentPage(pr);
	        pr.getParameters().put('Id', sc.Id);
	        ApexPages.StandardController stdController = new ApexPages.StandardController(sc);
	        TranscriptAppealController tacc = new TranscriptAppealController(stdController);
	        TranscriptAppealController.StdAdditionalInfo sai=new TranscriptAppealController.StdAdditionalInfo();
	        List<SelectOption> sGrade=sai.grade;
	        List<SelectOption> screditHrs=sai.creditHrs;
	        sai.inName='test in name';
	        sai.wguCrsCode='wgu code';
	        sai.wguCrsTitle='wgu title';
	        sai.inCrsCode='in crs code';
	        sai.yearAttended='2012';
	        sai.selGrades='A';
	        sai.selCreditHrs='2';
	        Attachment at=new Attachment();
	        at.name='atname';
	        at.body=Blob.valueOf('attachment body');
	        sai.appealAttachment=at;
	        List<TranscriptAppealController.StdAdditionalInfo> saiList=new List<TranscriptAppealController.StdAdditionalInfo>();
	        saiList.add(sai);
	        tacc.TranscriptsAppealList=saiList;
	        
	        tacc.incrementRowFlg();
	        tacc.decrementRowFlg();
	         
	        tacc.SaveAppeal();
	        sc.StudentCaseReason__c='Exclusion';
	        update sc;
	        system.assertEquals('Exclusion',sc.StudentCaseReason__c);
	        
        Test.stopTest();

	        TranscriptAppealController  tacc1= new TranscriptAppealController(stdController ); 
	        //tacc.incrementRowFlgEx();
	        //tacc.decrementRowFlgEx(); 
	        TranscriptAppealController.StdExclusionInfo sei=new TranscriptAppealController.StdExclusionInfo();
	        List<SelectOption> sDegreeEarned=sei.degreeEarned;
	        List<SelectOption> sReasonforExclusion=sei.reasonforExclusion;
	        sei.inName='test in name';
	        sei.finAid=true;
	        sei.selDegreeEarned='Associate';
	        sei.selReasonforExclusion='School Not Accredited';
	        
	        Attachment at1=new Attachment();
	        at1.name='atname';
	        at1.body=Blob.valueOf('attachment body');
	        sei.adAttachment2=at1;
	        List<TranscriptAppealController.StdExclusionInfo> seiList=new List<TranscriptAppealController.StdExclusionInfo>();
	        seiList.add(sei);
	        tacc1.TranscriptsExclusionList=seiList;
	        tacc1.SaveExclusion();
	        
	        tacc.Cancel();  
    }
}