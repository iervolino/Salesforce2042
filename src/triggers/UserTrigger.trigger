/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Revised Feb 20 2013 @ 1038 hrs
 * Revised: Added ProfileName__c synch code on BEFORE INSERT | UPDATE, for User queries that need Profile.Name but lack the View Setup & Configuration system permission
 * Revised: Added Username change notification block BEFORE UPDATE and AFTER UPDATE
 *
 * Revised Oct 30 2012 @ 1126 hrs
 * Revised: Restructured all For loop code with booleans instead of calling into Utility classes before the break (security audit compliance: executing SOQL within For Loops) 
 *
 * Revised Dec 17 2012 @ 1709 hrs
 * Revised: added After Insert logic for creating UserAttributes__c object for enrollment process users 
 * 
 * User object's Trigger class
 *
 */
 trigger UserTrigger on User (before insert, before update, after insert, after update) {
   
   
   if ( Trigger.isBefore && Trigger.isInsert ) {
      
      //set Employee user's default TimeZone
      //Do not use before or after Update for this utility call, because the User needs to be able to override the timezone setting based on current location (for scheduling)
      ID studentProfile = [SELECT id FROM Profile WHERE Name = 'Student Profile' LIMIT 1].id;
      //Do not process records if all of them are Student User accounts
      boolean isTargetRecord = false;
      for (User thisUser: Trigger.new) {
        if ( thisUser.profileId <> studentProfile ) {
          isTargetRecord = true;
          break;
        }
      } 
      if (isTargetRecord) {
        UserUtility.UserTimeZoneSetTrigger( Trigger.new );
      }    
   }
   
   
//=================================START USER BEFORE UPDATE==============================================   
   if ( Trigger.isBefore && Trigger.isUpdate ) {
       ID SAProfileId = [SELECT id FROM profile WHERE Name = 'System Administrator' LIMIT 1].Id;
       ID SAUserId = [SELECT id FROM User WHERE Username LIKE 'sadmin@wgu.edu%' LIMIT 1].Id;
       String oldProdOrgId = '00D30000001GkGUEA0'; //old person account org
       String newProdOrgId = '00Dd0000000hVl6EAE'; //new non person account org
       String thisOrgId = [Select Id From Organization].id; 
       boolean inProdOrg = ( thisOrgId.equals(oldProdOrgId) || thisOrgId.equals(newProdOrgId) );
               
      for ( User thisUser: Trigger.new ) {
      	
        String oldEmail = Trigger.OldMap.get(thisUser.Id).email;
        String oldFirstName = Trigger.OldMap.get(thisUser.Id).FirstName;
        String oldLastName = Trigger.OldMap.get(thisUser.Id).LastName;
        String oldUsername = Trigger.OldMap.get(thisUser.Id).Username;
        
        //prevent updates to employee email address unless current user is SA profile user
        thisUser.email = ( thisUser.isEmployee__c && !thisUser.Email.equals(oldEmail) ) && ( !UserInfo.getProfileId().equals(SAProfileId) )? oldEmail: thisUser.email;
        
        if ( !thisUser.Username.equals(oldUsername) && thisUser.NewUserName__c == null ) {
	    	  //bogify the User's Email address so a notification is not sent due to Username change
	        thisUser.Email = ('notify_bogify.' + thisUser.Email);
	        thisUser.NewUserName__c = thisUser.Username;
	        thisUser.Username = oldUsername; 
        } else if  ( !thisUser.Username.equals(oldUsername) && thisUser.NewUserName__c != null ) {
          thisUser.NewUserName__c = null;          
        }
	      
        if ( !inProdOrg && !thisUser.Email.endsWith('wgu.edu') && !thisUser.IsPortalEnabled ) {
        	//If in a Sandbox, make sure email address ends with 'wgu.edu', else, the record will not save due to domain verification
        	String[] emailParts = thisUser.Email.split('@');
					String[] domainParts = emailParts[1].split('wgu\\.edu');
					String domain = '';
					for ( String s: domainParts ) {
					  if ( !s.contains('wgu.edu') ) {
					     domain += s;
					  }
					}
					domain = (domain.startsWith('.')? domain.substring(1): domain);
					String emailStr = emailParts[0]+'@'+ (domain.equals('')?'':domain+'.') +'wgu.edu'; 
					thisUser.Email = emailStr;
        }
        
        if ( thisUser.isEmployee__c && ( !thisUser.FirstName.equals(oldFirstName)  || !thisUser.LastName.equals(oldLastName) ) ) {
          //prevent updates to employee Name fields by sadmin@wgu.edu user (Informatica Jobs) 
          if ( UserInfo.getUserId().equals( SAUserId )  ) {
            thisUser.FirstName = oldFirstName;
            thisUser.LastName = oldLastName;
          }
        }
        
        thisUser.isActive = ( thisUser.isEmployee__c && thisUser.isActive && thisUser.EmployeeStatusType__c != null && thisUser.EmployeeStatusType__c.equals('TERMINATED') )? false: thisUser.isActive;
      }        
   }
//=================================END USER BEFORE UPDATE==============================================   


//=================================START USER AFTER UPDATE (when manually configuring a new employee user)==============================================   
   if ( Trigger.isAfter && Trigger.isUpdate ) {
     Map<Id,UserRole> EnrollmentRolesMap = new Map<Id,UserRole>([SELECT id,Name FROM UserRole WHERE DeveloperName in ('BusinessGraduate','BusinessUndergrad','EnrollmentIT','HealthProfessions','HPPrelicensure','TeachersCollegeElEdSoSci','TeachersCollegeMathScience','TeachersCollegeMEd')]); 
     if ( [SELECT count() FROM User WHERE id in :Trigger.new AND UserRoleId in :EnrollmentRolesMap.keySet() AND isEmployee__c = true] > 0 ) {
          UserUtility.createEnrollmentAttributes( JSON.serialize(Trigger.new), JSON.serialize(EnrollmentRolesMap) );
     }     
     if ( [SELECT count() FROM User WHERE id in :Trigger.new AND Email LIKE 'notify_bogify.%' AND NewUserName__c != null] > 0 ) {
          UserUtility.recoverFromUsernameChange( JSON.serialize(Trigger.new) ); 
     }
     
   }
//=================================END USER AFTER INSERT==============================================   



//=================================START USER BEFORE UPDATE/INSERT ProfileName__c sync========================
   if ( Trigger.isBefore && ( Trigger.isUpdate || Trigger.IsInsert ) ) {
      Map<Id,String> profileNamesMap = new Map<Id,String>();
      for ( Profile profile: [SELECT Id,Name FROM Profile] ) {
        profileNamesMap.put( profile.Id, profile.Name );
      }
      for ( User thisUser: Trigger.New ) {
        thisUser.ProfileName__c = profileNamesMap.get(thisUser.ProfileId);
      }
   }
//=================================END USER AFTER UPDATE/INSERT ==============================================   

	//Flag a record for IDM update
	if(Trigger.isBefore && Trigger.isUpdate) {
        for(User u : Trigger.new) {
            if(u.isEmployee__c == true) {
                continue;
            }
            
            User oldUser = Trigger.oldMap.get(u.id);
            if(u.Alias != oldUser.Alias
              || u.City != oldUser.City
              || u.CommunityNickname != oldUser.CommunityNickname
              || u.CompanyName != oldUser.CompanyName
              || u.CallCenterId != oldUser.CallCenterId
              || u.Country != oldUser.Country
              || u.Department != oldUser.Department
              || u.Email != oldUser.Email
              || u.Division != oldUser.Division
              || u.EmployeeNumber != oldUser.EmployeeNumber
              || u.Extension != oldUser.Extension
              || u.Street != oldUser.Street
              || u.Fax != oldUser.Fax
              || u.IsActive != oldUser.IsActive
              || u.Username != oldUser.Username
              || u.FirstName != oldUser.FirstName
              || u.LastName != oldUser.LastName
              || u.Name != oldUser.Name
              || u.Phone != oldUser.Phone
              || u.ReceivesAdminInfoEmails != oldUser.ReceivesAdminInfoEmails
              || u.UserRoleId != oldUser.UserRoleId
              || u.UserType != oldUser.UserType
              || u.State != oldUser.State
              || u.Title != oldUser.Title
              || u.ReceivesInfoEmails != oldUser.ReceivesInfoEmails
              || u.EmployeeStatusType__c != oldUser.EmployeeStatusType__c
              || u.HireDate__c != oldUser.HireDate__c
              || u.IsEmployee__c != oldUser.IsEmployee__c) 
            {
                u.IDMRequiresUpdate__c = true;
            }
    	}
    }

}