@isTest(SeeAllData=false)
global class TestQuickCaseController
{
	static testMethod void TestQuickCase()
    {
        case newCase = new case();
             
        //test with no record Type
        //test with record Type
        //test with no queue
        //test with queue
        //test with all different objects attached
        //test with an open case
         Contact  con1 = TestStudentUser.getTestStudentContact();
        
        FinancialApplication__c finapp1 = new financialapplication__c(Student__c = con1.id);
        insert finapp1;
        
        StudentProcess__c sp= new StudentProcess__c(student__c = con1.id);
    User testUser = [Select id from User where Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
    System.RunAs( testUser ) 
    {   
         // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('ObjectId', sp.id);
        ApexPages.currentPage().getParameters().put('ContactId', con1.id);
  
        ApexPages.StandardController stdCont = new ApexPages.standardController(newCase);
        QuickCaseController testController = new QuickCaseController(stdCont);
       
        test.startTest();
     
      	  	testController.createCase(); //create a positive test of a finaid case record type	
   			testController.createCase(); //if we call it again and we haven't closed the case it shouldn't create a second one.
        
      	  	system.debug('Case ID:' + testController.getCaseId());
      	  	system.debug('Contact Id:' + testController.getContactId());
            system.debug('Object Id:'+ testController.getObjectId());
            system.debug('Case Tag:' + testController.getCaseTag() );

			list<case> casesCreated = [select id from case where  QuickCase__c=True and StudentProcess__c = :sp.id ];
        	System.assert(casesCreated.size()==1,'Check One case was created and linked to object '+ casesCreated.size());
         
            //create email message to activate workflow and close the case
         	emailMessage emal = new emailMessage(ParentId  = testController.getCaseId(),FromAddress='none@none.com', Subject ='test',HtmlBody ='hello');
       	 	insert emal;

        	casesCreated = [select id from case where  QuickCase__c=True and isClosed=true and subject = 'test'];
        	System.assert(casesCreated.size()==1,'Case Closed when email message was created '+ casesCreated.size());
        	
        	case delCase = new case(id=testController.getcaseId());
        	delete delCase;
        
           //test invalid record type
        	ApexPages.currentPage().getParameters().put('RecordType', 'abc123');//this should error out with invalid record type and not create an additional case
        	ApexPages.StandardController stdCont2 = new ApexPages.standardController(newCase);
        	QuickCaseController testController2 = new QuickCaseController(stdCont2);
      	    testController2.createCase(); 
        	System.assert( testController2.getTestVal() == 'Invalid Record Type or Queue Name','Check invalid Record Type or Queue Name Error ' + testController.getTestVal() );
        	 
        	  //test blank record type
        	   // Add parameters to page URL
            ApexPages.currentPage().getParameters().put('ObjectId', '');
            ApexPages.currentPage().getParameters().put('ContactId', con1.id);
        	ApexPages.currentPage().getParameters().put('RecordType', 'Finaid'); //this should error out with invalid record type and not create an additional case
        	ApexPages.StandardController stdCont4 = new ApexPages.standardController(newCase);
        	QuickCaseController testController4 = new QuickCaseController(stdCont4);
      	    testController4.createCase(); 
        
        
        	ApexPages.currentPage().getParameters().put('ObjectId', '');
            ApexPages.currentPage().getParameters().put('ContactId', con1.id);
        	ApexPages.currentPage().getParameters().put('RecordType', 'Bursar'); //this should error out with invalid record type and not create an additional case
        	ApexPages.StandardController stdCont5 = new ApexPages.standardController(newCase);
        	QuickCaseController testController5 = new QuickCaseController(stdCont5);
      	    testController5.createCase(); 

      	    delCase = new case(id=testController4.getcaseId());
        	delete delCase;
        	//System.assert( ); 
        	 
        	 
        	//test a valid queue
        	ApexPages.currentPage().getParameters().put('RecordType', 'Finaid');
        	ApexPages.currentPage().getParameters().put('QueueName', 'Bursar'); //this sould error out for invalid queue
        	ApexPages.StandardController stdCont3 = new ApexPages.standardController(newCase);
        	QuickCaseController testController3 = new QuickCaseController(stdCont3);
      	    testController3.createCase(); 
            system.debug('Queue Name:' +  testController3.queueName);
                      
     
       //     casesCreated = [select id from case where QuickCase__c=True];
        //	System.assert(casesCreated.size()==0,'Check Error Cases Did not load '+ casesCreated.size());
        	

        test.stopTest();
      }
    }
    
 
    
}