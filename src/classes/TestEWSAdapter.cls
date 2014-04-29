/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date Created Aug 15, 2013 @ 1551 hrs
 * 
 * Test class for EWSAdapter class
 *
 */
@isTest
private class TestEWSAdapter {
    
    static testMethod void testSendEmailFrom() {
    	
    	User testUser = [SELECT id,Email FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
       	    OrgWideEmailAddress address = [SELECT Id,DisplayName,Address from OrgWideEmailAddress LIMIT 1];
       	    if ([SELECT count() FROM OrgWideEmailAddress__c WHERE Address__c = :address.Address] == 0) {
       		  insert new OrgWideEmailAddress__c(Name=address.DisplayName,Address__c=address.Address,OrgWideEmailRecordId__c=address.Id);
       	    } 
	    	Test.startTest();
				EWSAdapter.sendEmailFrom(address.Address,address.Address,'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') );
				try {
					EWSAdapter.sendEmailFrom('bogusTeamBox@wgu.edu','bogusTeamBox@wgu.edu','bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom('bogusTeamBox@wgu.NOTedu','bogusTeamBox@NOTwgu.edu','bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom(testUser.Email,testUser.Email,'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', null, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom(testUser.Email,testUser.Email,'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', null, EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom(testUser.Email,testUser.Email,'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), null, 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom(testUser.Email,testUser.Email,null, 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom(testUser.Email,null,'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
				try {
					EWSAdapter.sendEmailFrom(null,null,'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	
	    	Test.stopTest();
    	}   
    	 	
    }

    static testMethod void testSendEmailReplyTo() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
				EWSAdapter.sendEmailReplyTo( 'bogusTeamBox@wgu.edu','bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') );
				try {
					EWSAdapter.sendEmailReplyTo('bogus@NOTwgu.edu','bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
					    	
				try {
					EWSAdapter.sendEmailReplyTo('bogus@NOTwgu.edu','bogus@wgu.edu,no.valid.account&gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
					    	
    	}
    	
    	testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'Student Profile' LIMIT 1];
    	System.runAs(testUser) {
				try {
					EWSAdapter.sendEmailReplyTo( 'bogusTeamBox@wgu.edu','bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') );
				} catch (EWSAdapter.EWSAdapterException e) {}	    	
    	}
	    Test.stopTest();
    }
    
    static testMethod void testSendEmail() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
				EWSAdapter.sendEmail( 'bogus@wgu.edu,no.valid.account@gmail.com'.split(','), 'Test Message Body', 'Test Subject', EWSAdapter.Priority.Normal, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') );
	    	Test.stopTest();
    	}
    }
    static testMethod void testSendEmailSimple() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
				EWSAdapter.sendEmailSimple( 'bogus@wgu.edu,no.valid.account@gmail.com', 'Test Message Body', 'Test Subject');	    	
				EWSAdapter.sendEmailSimpleEncoded( 'bogus@wgu.edu,no.valid.account@gmail.com', EncodingUtil.base64Encode(Blob.valueOf('Test Message Body')), 'Test Subject');	    	
	    	Test.stopTest();
    	}
    }
    static testMethod void testGetTimezones() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
	    	    EWSAdapter.getTimeZones();
	    	Test.stopTest();
    	}
    }
    static testMethod void testQueryFreeBusy() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
				EWSAdapter.queryFreeBusy('bogus1@wgu.edu,bogus2@wgu.edu'.split(','),System.now().addDays(-1), System.now(), 'UTC' );
				try {
					EWSAdapter.queryFreeBusy('bogus1@wgu.edu,bogus2@wgu.edu'.split(','),System.now(), System.now().addDays(-1), null );					
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.queryFreeBusy('bogus1@wgu.edu,bogus2@wgu.edu'.split(','),System.now().addDays(-1), null, 'UTC' );					
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.queryFreeBusy('bogus1@wgu.edu,bogus2@wgu.edu'.split(','),null, System.now(), 'UTC' );					
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.queryFreeBusy(null,System.now().addDays(-1), System.now(), 'UTC' );					
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.queryFreeBusy('bogus1&wgu.edu,bogus2@wgu.edu'.split(','),System.now().addDays(-1), System.now(), 'UTC' );					
				} catch (EWSAdapter.EWSAdapterException e) {}	  
	    	Test.stopTest();
    	}
    }
    static testMethod void testScheduleMeeting() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
				EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),'bogus1@wgu.edu,bogus1@gmail.com'.split(','),'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),'bogus1&wgu.edu,bogus1@gmail.com'.split(','),'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',System.now().addMinutes(60), System.now(), null );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',System.now(), null, 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',null, System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...',null,System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,null,'Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu',null,null,'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@wgu.edu','bogus1&wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1@NOTwgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.scheduleMeeting('bogus1&wgu.edu','bogus1@wgu.edu,bogus1@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' );
				} catch (EWSAdapter.EWSAdapterException e) {}	  
	    	Test.stopTest();
    	}
    }
    static testMethod void testCancelMeeting() {
    	
    	User testUser = [SELECT id FROM User WHERE isActive = true and Profile.Name = 'System Administrator' LIMIT 1];
    	System.runAs(testUser) {
    	
	    	Test.startTest();
				EWSAdapter.cancelMeeting('bogus1@wgu.edu','00000000642B39A783622F409F7F45E03E03B83F070018FFA207BB28524FBB59F2667763E2B500069782C8BC00005C958B78DC3A5B418A58DF9E2FCB1B410000C2F93CFB0000','This meeting has been cancelled');
				try {
					EWSAdapter.cancelMeeting('bogus1@wgu.edu','00000000642B39A783622F409F7F45E03E03B83F070018FFA207BB28524FBB59F2667763E2B500069782C8BC00005C958B78DC3A5B418A58DF9E2FCB1B410000C2F93CFB0000',null);
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.cancelMeeting('bogus1@NOTwgu.edu','00000000642B39A783622F409F7F45E03E03B83F070018FFA207BB28524FBB59F2667763E2B500069782C8BC00005C958B78DC3A5B418A58DF9E2FCB1B410000C2F93CFB0000','Cancelled');
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.cancelMeeting('bogus1&wgu.edu','00000000642B39A783622F409F7F45E03E03B83F070018FFA207BB28524FBB59F2667763E2B500069782C8BC00005C958B78DC3A5B418A58DF9E2FCB1B410000C2F93CFB0000','Cancelled');
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.cancelMeeting('bogus1@wgu.edu',null,'This meeting has been cancelled');
				} catch (EWSAdapter.EWSAdapterException e) {}	  
				try {
					EWSAdapter.cancelMeeting(null,'00000000642B39A783622F409F7F45E03E03B83F070018FFA207BB28524FBB59F2667763E2B500069782C8BC00005C958B78DC3A5B418A58DF9E2FCB1B410000C2F93CFB0000','This meeting has been cancelled');
				} catch (EWSAdapter.EWSAdapterException e) {}	  
	    	Test.stopTest();
    	}
    }
}