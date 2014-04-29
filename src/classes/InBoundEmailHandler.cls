/*****************************************************************************************
*
* Name: InBoundEmailHandler
* Author: Will Slade
* Purpose: All queue-specific email handler classes call this class as super to process 
*          inbound mail
* Revisions: 
*    - 6/1/12 Created Class
*    - 2/21/12 Seperated attachParentObject function for reuse in QuickCaseController
*
******************************************************************************************/

global virtual class InBoundEmailHandler implements Messaging.InboundEmailHandler 
{
    protected String queueName;
    protected String caseRecType;  
    private Boolean caseFeedCheck = false; 
    protected Boolean isValidId = false;   
    
    global virtual Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {  
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        Id businessContactId = [Select Id from RecordType where DeveloperName = 'BusinessContact' AND SObjectType='Contact'].Id;
        String parentObjectId = '';
        String caseParentId = '';        
        Boolean contactFound = false;
        Boolean taskOwnerFound = false;
        Boolean queueFound = false;
        Boolean caseThread = false;
        Boolean isValidCaseParentId = false;
        Boolean accountFound = false;
        Boolean verbose = true;
        Account accountToBeAssigned = null;
        String modFromAddress = '';
        String origFromAddress = '';
        Task newTask = new Task();
        String taskOwnerId = '';
        Case currCase = new Case(); 
        User taskOwner = [SELECT Id FROM User WHERE Name = 'System Admin']; 
        List<QueueSobject> queueList = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = :queueName LIMIT 1];
        List<RecordType> caseRecTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = :caseRecType LIMIT 1];
        QueueSobject queue = new QueueSobject();
        Contact fromContact = null;
        String emailBody = '';
        List<Case> caseCheck = new List<Case>();        
             
        EmailMessage newEmailMessage = new EmailMessage();
               
               
        
        /*if (test.isRunningTest())
        {
            if (email.fromAddress.indexOf('casefeed') != -1)
            {
                caseFeedCheck = true;
            }
        }*/                
        //else
        //{        
            for (Messaging.InboundEmail.Header hd : email.headers)
            {
                if (hd.name == 'caseFeedCheck' && hd.value == 'true')
                {
                    caseFeedCheck = true;
                }
            }                        
        //}
        
        System.debug('===============> Plain ' + email.plainTextBody);
        System.debug('===============> HTML ' + email.htmlbody);               
        
        if (email.plainTextBody != NULL)
        {
            emailBody = email.plainTextBody;
        }
        
        else if (email.htmlBody != NULL)  
        {
            string html = email.htmlBody;
            //first replace all <BR> tags with \n to support new lines
            string result1 = html.replaceAll('<br/>', '\n');
            result1 = result1.replaceAll('<br />', '\n');
            result1 = result1.replaceAll('<br>', '\n');
            result1 = result1.replaceAll('&nbsp;', ' ');
            
            //regular expression to match all HTML/XML tags
            string HTML_TAG_PATTERN = '<.*?>';
            
            // compile the pattern     
            pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
            
            // get your matcher instance
            matcher myMatcher = myPattern.matcher(result1);
            
            //remove the tags     
            result1 = myMatcher.replaceAll('');        
            emailBody = result1;
        }
        
        
        
        // split email body to multiple lines         
        List<String> emailSplitBody = emailBody.split('\n', 0);
        
        if (queueList.size() == 1)
        {
            queue = queueList[0];
            queueFound = true;               
        }
        
        try  
        {
            if (email.subject.indexOf('@!$') != -1)
            {
                taskOwnerId = email.subject.substring((email.subject.indexOf('@!$') + 3), (email.subject.indexOf('@!$') + 18));    
            }
            
            else
            {
                for (String emailLine : emailSplitBody)
                {
                    if (emailLine.indexOf('@!$') != -1)
                    {
                        taskOwnerId = emailLine.substring((emailLine.indexOf('@!$') + 3), (emailLine.indexOf('@!$') + 18));
                        break;
                    }
                }               
            }
            
            taskOwner = [SELECT Id FROM User WHERE Id = :taskOwnerId];
        }      
        
        catch(Exception e)
        {
            System.debug('=========> task owner error ' + e);
        }               
        
        
        //determine Contact by fromAddress
        if (email.fromAddress != null)
        {
            modFromAddress = email.fromAddress;
            List<List<SObject>> searchForEmail = [FIND :modFromAddress IN EMAIL FIELDS RETURNING Account(Id, Name, RecordTypeId, StudentContact__c), Contact(Id, Name, accountId)];
            
            List<Account> fromAccounts = searchForEmail[0];          
            List<Contact> fromContacts = searchForEmail[1];
            /*List<Id> fromContactIds = new List<Id>();
            
            for (Contact thisContact : fromContacts)
            {
                fromContactIds.add(thisContact.Id);
           }
            
            fromContacts = [SELECT Id, Name, AccountId FROM Contact WHERE Id IN :fromContactIds];*/
            System.debug('=================> size ' + fromAccounts.size() + ' ' + fromContacts.size() + ' On Email ' + modFromAddress);         
            //can not find any contact or account associate with from address, insert my after @ and search again
            if ((fromContacts.size() == 0 && fromAccounts.size() == 0 && (modFromAddress.indexOf('@wgu.edu') != -1)) || test.isRunningTest())
            {
                origFromAddress = modFromAddress;
                modFromAddress = modFromAddress.substring(0, modFromAddress.indexOf('@') + 1) + 'my.' + modFromAddress.substring(modFromAddress.indexOf('@') + 1);
                searchForEmail = [FIND :modFromAddress IN EMAIL FIELDS RETURNING Account(Id, Name, RecordTypeId, StudentContact__c), Contact(Id, Name, AccountId)];
                fromAccounts = searchForEmail[0];
                fromContacts = searchForEmail[1];
            }
            // still cant find any account and contact relate to this email, go search EmailAddress__c object.
            if (fromAccounts.size() == 0 && fromContacts.size() == 0)
            {
                List<EmailAddress__c> emailAddresses = [SELECT Id, Contact__c FROM EmailAddress__c WHERE Email__c = :origFromAddress OR Email__c = :modFromAddress];
                fromContacts = emailAddresses.size() > 0 ? [SELECT Id, Name, accountId FROM Contact WHERE Id = :emailAddresses[0].Contact__c ORDER BY Id] : fromContacts;
            }  
            
            
            if (fromAccounts.size() >= 1 && fromContacts.size() == 0)
            {
                //////////////////////////////BRAD//////////////////////////////
                if(verbose)
                    System.debug('=========> fromAccounts.size() >= 1 && fromContacts.size() == 0');
                
                RecordType lrvRT = [SELECT Id, Name FROM RecordType WHERE sObjectType='Account' AND DeveloperName='LearningResourcesVendor' LIMIT 1];
                //RecordType studentRT = [SELECT Id, Name FROM RecordType WHERE sObjectType='Contact' AND DeveloperName = 'StudentRecord' LIMIT 1];
                
                // Get a list of Contacts of type StudentRecord whose email address is in the delivery field
                if(verbose)
                    System.debug('======> ' + email.toAddresses);
                //find the contacts (of student)this email sent to.   
                List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE RecordType.DeveloperName IN ('StudentRecord', 'AlumniRecord', 'ProspectRecord') AND  (Email IN :email.toAddresses OR My_WGU_Email__c IN :email.toAddresses OR OtherEmail__c IN :email.toAddresses OR WGUEmail__c IN :email.toAddresses)  ORDER BY Id] ;
             
                if(verbose)
                    System.debug('=========> contacts.size():\t' + contacts.size());
                
                for(Account acct : fromAccounts)
                    if(acct.RecordTypeId == lrvRT.Id)
                    {
                        if(accountToBeAssigned == null)
                        {
                            accountToBeAssigned = acct;
                            accountFound = true;
                        }
                        for(Contact c : contacts)
                            if(c.Email.toLowerCase().indexOf('wgu.edu') != -1)   //if contact.Email field contains wgu.edu, then put this to address to fromContacts list.
                                fromContacts.add(c);
                    }
                
                if(verbose)
                    System.debug('=========> fromContacts.size():\t' + fromContacts.size());
                
                // If no Contact(s) have been added (Which means there was no applicable Contact(s), or there were no Accounts of RecordType LearningResourcesVendor)
                if(fromContacts.size() == 0)
                {                    
                    // Find the right Account to associate. Loooking for Account, RecordType=LearningResourcesVendor, sorted by Id
                    for(Account acct : fromAccounts)
                        if(acct.RecordTypeId == lrvRT.Id)
                        {
                            if(accountToBeAssigned == null)
                            {
                                accountToBeAssigned = acct;
                                accountFound = true;
                            }
                            accountToBeAssigned = accountToBeAssigned.Id < acct.Id ? accountToBeAssigned : acct;
                        }
                }
                
                if(verbose)
                {
                    if(accountFound)
                        System.debug('=========> Account Found:\t' + accountToBeAssigned);
                    else
                        System.debug('=========> No Account Found');
                }
                
                //////////////////////////////BRAD//////////////////////////////
               
                fromContact = fromAccounts[0].StudentContact__c != NULL ? [SELECT Id, Name, AccountId FROM Contact WHERE Id = :fromAccounts[0].StudentContact__r.Id] : fromContact;
                contactFound = fromAccounts[0].StudentContact__c != NULL ? true : contactFound;
                
                if(verbose)
                {
                    if(contactFound)
                        System.debug('=========> Contact Found:\t' + fromContact);
                    else
                        System.debug('=========> Contact not found');
                }
            }                      
            
            //remove else
            if(fromContacts.size() == 1)
            {
                if(verbose)
                       System.debug('=========> fromContacts.size() == 1\tfromContact:\t' + fromContact + '\tStomping over old fromContact');
                
                fromContact = fromContacts[0];
                contactFound = true;
                
                if(verbose)
                    System.debug('=========> fromContact is now:\t' + fromContact);
            }
            
            
            //remove else
            if(fromContacts.size() > 1)
            {
                System.debug('====> Multiple Contacts Found for Email Given ' + fromContacts.size()); 
                
                List<Contact> contactsWithAccounts = new List<Contact>();
                
                for (Contact thisContact : fromContacts)
                {
                    if (thisContact.accountId != null)
                    {
                        contactsWithAccounts.add(thisContact);
                    }
                }
                
                fromContact = contactsWithAccounts.size() == 1 ? contactsWithAccounts[0] : fromContact;                
                
                if (contactsWithAccounts.size() > 1)
                {
                    fromContact = contactsWithAccounts[0];
                    
                    for (Contact thisContact : contactsWithAccounts)
                    {
                        fromContact = thisContact.Id < fromContact.Id ? thisContact : fromContact;
                    }
                }
                
                else if (contactsWithAccounts.size() == 0)
                {
                    fromContact = fromContacts[0];
                    
                    for (Contact thisContact : fromContacts)
                    {
                        fromContact = thisContact.Id < fromContact.Id ? thisContact : fromContact;
                    }
                }                                
                
                contactFound = true;
                
                /*Case dupeContactCase = new case();
                dupeContactCase.ContactId = fromContact.Id;
                dupeContactCase.Subject = 'Duplicate email addresses in system for contact ' + fromContact.Name;
                dupeContactCase.Description = 'Email address ' + email.fromAddress + ' exists for multiple contacts.  Please run de-duping process';
                dupeContactCase.Status = 'New';
                dupeContactCase.Origin = 'Email';
                dupeContactCase.SuppliedEmail = email.fromAddress;
                
                if (queueFound == true)
                {                
                    dupeContactCase.OwnerId = queue.QueueId;   
                }
                
                insert dupeContactCase;*/                          
            }
           
            //change else to if(fromContacts.size() == 0 && fromAccounts.size() == 0)
            //if no contact or account found , then create a contact by given name.
            if(!contactFound && !accountFound)
            {
                if(verbose)
                    System.debug('=========> No Contact and no Account found. Creating new Contact...');
                Contact newContact = new Contact(RecordTypeId=businessContactId);
                
                String fromName = email.fromName == null ? '' : email.fromName;
                fromName = fromName.replaceAll('\\s+', ' ');
                fromName = fromName.trim();
                
                if(fromName == '')
                {
                    newContact.FirstName = 'Unknown';
                    newContact.LastName = 'Unknown';
                }
                else
                {
                    if(fromName.indexOf(' ') != -1)
                    {
                        newContact.FirstName = fromName.substring(0, fromName.indexOf(' '));
                        newContact.LastName = fromName.substringAfter(' ');
                    }
                    else
                    {
                        newContact.FirstName = fromName.trim();
                        newContact.LastName = 'Unknown';
                    }
                }
                
                if (email.fromAddress != null)
                {
                   newContact.Email = email.fromAddress;
                }
                
                System.debug('=============> added contact email ' + newContact.Email);
                
                if(verbose)    
                    System.debug('====> findme11 newContact.FirstName: \"' + newContact.FirstName + '\"\tnewContact.LastName: \"' + newContact.LastName + '\"');
                
                insert newContact;
                fromContact = newContact;
                
                if(verbose)
                    System.debug('=========> fromContact:\t' + fromContact);
            }
        }
         
            
            
        try
        {       
            if (email.subject.indexOf(':ref') != -1)
            {
                // Formula for generating the case thread ID
                parentObjectId = email.subject.substring(email.subject.indexOf(':ref') - 10, email.subject.indexOf(':ref') -6) + '000000'
                               + email.subject.substring(email.subject.indexOf(':ref') - 5, email.subject.indexOf(':ref'));
                // Indicator that this is a case feed email
                caseThread = true;
                System.debug('=================> ParentObjectId Threading ' + parentObjectId);                             
            }
                               
            /* We are not putting IDs in the subject line
            if (email.subject.indexOf('@!$') != -1)
            {
                if (!caseThread)
                {
                    parentObjectId = email.subject.substring((email.subject.indexOf('$!@') + 3), (email.subject.indexOf('$!@') + 18));  
                }
                else
                {
                    caseParentId = email.subject.substring((email.subject.indexOf('$!@') + 3), (email.subject.indexOf('$!@') + 18));
                }
            }*/
                       
            if (parentObjectId.equals('') || (caseThread && caseParentId.equals('')))
            {
                for (String emailLine : emailSplitBody)
                {
                    if (emailLine.indexOf(':ref') != -1 && !caseThread)
                    {
                        if ((emailLine.substring(emailLine.indexOf(':ref') - 10, emailLine.indexOf(':ref') -9).equals('_')))
                        {
                            parentObjectId = emailLine.substring(emailLine.indexOf(':ref') - 9, emailLine.indexOf(':ref') -5) + '000000'
                                           + emailLine.substring(emailLine.indexOf(':ref') - 5, emailLine.indexOf(':ref'));                        
                        }
                        else
                        {
                            parentObjectId = emailLine.substring(emailLine.indexOf(':ref') - 10, emailLine.indexOf(':ref') -6) + '000000'
                                           + emailLine.substring(emailLine.indexOf(':ref') - 5, emailLine.indexOf(':ref'));
                        }
                        // Indicator that this is a case feed email
                        caseThread = true;
                        System.debug('=================> ParentObjectId Body Threading ' + parentObjectId);               
                    }
                                        
                    if (emailLine.indexOf('$!@') != -1)
                    {
                        System.debug('======> pulled in object id ' + emailLine.substring((emailLine.indexOf('$!@') + 3), (emailLine.indexOf('$!@') + 18)));
                        if (caseThread || caseFeedCheck)
                        {
                            caseParentId = emailLine.substring((emailLine.indexOf('$!@') + 3), (emailLine.indexOf('$!@') + 18));
                        }
                        else
                        {
                            parentObjectId = emailLine.substring((emailLine.indexOf('$!@') + 3), (emailLine.indexOf('$!@') + 18));  
                        }
                    }
                }               
            }            

            // Assign the task to the correct parent object            
            caseCheck = [SELECT Id, Contact.StudentID__c, RecordTypeId, Reason FROM Case WHERE Id = :parentObjectId LIMIT 1];
            
            /*if (!caseFeedCheck)
            {
                fepCheck = [SELECT Id FROM FieldExperienceProcess__c WHERE Id = :parentObjectId];
                feCheck = [SELECT Id FROM FieldExperience__c WHERE Id = :parentObjectId];
                evalCheck = [SELECT Id FROM TransferEvaluation__c WHERE Id = :parentObjectId];
            }*/
            
            System.debug('==================> CaseCheckSize ' + caseCheck.size());
            
            if (caseCheck.size() > 0)// || fepCheck.size() > 0 || feCheck.size() > 0 || evalCheck.size() > 0)
            {
                //newTask.WhatId = parentObjectId;
                isValidId = true;                              
            }
        }
        
        catch(Exception e)
        {
            System.debug('Hidden SFID exception ' + e);
        }
        
        if(!isValidId)
        {
            System.debug('===============> Creating New Case !isValidId');
            // Create case on contact from email
            Case emailCase = new case();
            
            //TODO - check to see that fromContact is not null before doing the next line
            
            //System.debug('============> case checkers ' + fromContact + ' ' + accountFound + ' ' + accountToBeAssigned.Id);
            if(fromContact != null)
            {
                System.debug('=====> ' + 'Assigned contact to case, contactFound: ' + contactFound + '\taccountFound: ' + accountFound);
                
                // If a Contact was found, not created, and there is an Account of RecordType LearningResourcesVendor, then associate the Account with the Case's Vendor
                if(contactFound && accountFound)
                {
                    System.debug('==========> ' + 'Account to be assigned as the Case\'s Vendor:\t' + accountToBeAssigned);
                    emailCase.Vendor__c = accountToBeAssigned.Id;
                }
                emailCase.ContactId = fromContact.Id;
            }
            else if(fromContact == null)
            {
                //TODO - if fromContact is null, email.Case.AccountId = the LRV account we determined needed to be associated
                if(accountFound)
                {
                    System.debug('=====> ' + 'Assigned account to case');
                    emailCase.AccountId= accountToBeAssigned.Id;
                }
            }

            
            emailCase.Subject = email.subject;            
            emailCase.Description = ' ';
            emailCase.Status = 'New';
            emailCase.Origin = 'Email';
            
            if (caseRecTypes.size() > 0)
            {
                emailCase.RecordTypeId = caseRecTypes[0].Id;
            }
            
            if (queueFound == true)
            {
                emailCase.OwnerId = queue.QueueId;   
            }
            
            try 
            {          
                insert emailCase;
            }
            catch (Exception e)
            {
                insert emailCase;
            }
            
            // Assign the task to the newly-created case                  
            parentObjectId = emailCase.Id;
            newTask.WhatId = parentObjectId;                                  
        }                
        
        // If this is a case feed object and a parent Id is found, create the relationship
        if (caseFeedCheck)
        {
                    currCase = [SELECT Id, 
                                    FieldExperienceProcess__c,
                                    FieldExperience__c,
                                    //StudentTranscript__c,
                                    TransferEvaluation__c,
                                    FinancialApplication__c,
                                    FinancialAward__c,
                                    TeacherSuccess__c,
                                    StudentProcess__c,
                                    StudentTaskAttempt__c
                             FROM Case 
                             WHERE Id = :parentObjectId 
                             LIMIT 1];
            System.debug('==========> Attempting to attach email to parent case via Mikes new code');
            if (currCase != null)
            {
                isValidId = true;
            }                             
              currCase = attachParentObject(currCase, caseParentID);
        }                            
        
        newTask.Subject = email.subject;
        newTask.Status = 'Not Started';
        newTask.Priority = 'Normal';
        if (email.ccAddresses != null && !caseFeedCheck)
        {
            newTask.Description = 'From: ' + email.fromAddress + '\n' + 'To: ' + email.toAddresses + '\n' +
                                  'CC: ' + email.ccAddresses + '\n' + 'Body: ' + emailBody;
        }        
        else if (!caseFeedCheck)
        {
            newTask.Description = 'From: ' + email.fromAddress + '\n' + 'To: ' + email.toAddresses + '\n' +
                                  'Body: ' + emailBody;        
        }         
        else
        {       
            String fullURL = URL.getSalesforceBaseUrl().toExternalForm() +
            '/' + parentObjectId;        
            newTask.Description = 'You have received a new email message here ' + fullURL;
        }
        
        if (contactFound == true)
        {
            newTask.WhoId = fromContact.Id;  
        }

        newTask.OwnerId = taskOwner.Id;
        if (!caseFeedCheck) // Decided to not create task if using case feed, but leaving code above for now, it just won't insert the object that was constructed
        {
            insert newTask;
        }
        
        if (currCase != null && caseFeedCheck)
        {
            System.debug('==============> Creating new email message for currCase that is NOT NULL');
            newEmailMessage.activityId = newTask.Id;
            newEmailMessage.ccAddress = JSON.serialize(email.ccAddresses).replace('"', '').replace('[', '').replace(']', '');
            if (newEmailMessage.ccAddress == null || newEmailMessage.ccAddress.equals('null'))
            {
                newEmailMessage.ccAddress = '';
            }
            newEmailMessage.fromAddress = email.fromAddress;
            newEmailMessage.toAddress = JSON.serialize(email.toAddresses).replace('"', '').replace('[', '').replace(']', '');
            newEmailMessage.fromName = email.fromName;
            newEmailMessage.htmlBody = email.htmlBody;
            newEmailMessage.textBody = email.plainTextBody;
            newEmailMessage.incoming = true;
            newEmailMessage.parentId = parentObjectId;
            newEmailMessage.status = '0';
            newEmailMessage.subject = email.subject;
            
            insert newEmailMessage;            
        }         

        if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) 
        {
            String bannerId = '';
            List<Attachment> attachments = new List<Attachment>();    
        
            for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) 
            {
                Attachment attachment = new Attachment();
                // Attach to the passed or created salesforce object
                if (!caseFeedCheck)
                {
                    attachment.ParentId = parentObjectId;
                }
                else
                {
                    attachment.ParentId = newEmailMessage.Id;
                }
                
                attachment.Name = email.binaryAttachments[i].filename;
                attachment.Body = email.binaryAttachments[i].body;
                attachments.add(attachment);            
            }
        
            insert attachments;
            
            if (caseCheck.size() > 0 || test.isRunningTest())
            {
                RecordType transRT = [SELECT Id FROM RecordType WHERE Name = 'Transcripts' AND SobjectType = 'Case' LIMIT 1];
                
                if (test.isRunningTest())
                {
                    Case newCase = [SELECT Id, RecordTypeId FROM Case LIMIT 1];
                    caseCheck.add(newCase);
                }
            
                if (caseCheck[0].RecordTypeId == transRT.Id && (caseCheck[0].Reason == 'Appeal' || caseCheck[0].Reason == 'Exclusion'))
                {
                    bannerId = caseCheck[0].Contact.StudentID__c;
                    OnbaseAttachmentUtility.sendToOnbase(attachments, bannerId);
                }
            }
        }
        
        return result; 
    }
    
    public static case attachParentObject(case currCase, string caseParentID)
    {
          
            List<FieldExperienceProcess__c>  fepCheck = [SELECT Id FROM FieldExperienceProcess__c WHERE Id = :caseParentId];
            List<FieldExperience__c> feCheck = [SELECT Id FROM FieldExperience__c WHERE Id = :caseParentId];
            List<TransferEvaluation__c> evalCheck = [SELECT Id FROM TransferEvaluation__c WHERE Id = :caseParentId];
            List<FinancialApplication__c> finAppCheck = [SELECT Id FROM FinancialApplication__c WHERE Id = :caseParentId];
            List<FinancialAward__c> finAwardCheck = [SELECT Id FROM FinancialAward__c WHERE Id = :caseParentId];
            List<TeacherSuccess__c> tchSuccessCheck = [SELECT Id FROM TeacherSuccess__c WHERE Id = :caseParentId];
            List<StudentProcess__c> stdnProcessCheck = [SELECT Id FROM StudentProcess__c WHERE Id = :caseParentId];
            List<StudentTaskAttempt__c> stdnTaskAttempt = [SELECT Id FROM StudentTaskAttempt__c WHERE Id = :caseParentId];
            
            if (currCase.FieldExperienceProcess__c != null || currCase.FieldExperience__c != null || currCase.TransferEvaluation__c != null ||
                currCase.FinancialApplication__c != null || currCase.FinancialAward__c != null || currCase.TeacherSuccess__c != null ||
                currCase.StudentProcess__c != null || currCase.StudentTaskAttempt__c != null) 
            {
                // Do nothing as the case already has a parent object
            }                
            else if (fepCheck.size() > 0)
            {
                currCase.FieldExperienceProcess__c = (Id)caseParentId;
                update currCase;
            }  
            else if (feCheck.size() > 0)
            {
                currCase.FieldExperience__c = (Id)caseParentId;
                update currCase;
            }
            else if (evalCheck.size() > 0)
            {
                currCase.TransferEvaluation__c = (Id)caseParentId;
                update currCase;
            }
            else if (finAppCheck.size() > 0)
            {
                currCase.FinancialApplication__c = (Id)caseParentId;
                update currCase;
            }
            else if (finAwardCheck.size() > 0)
            {
                currCase.FinancialAward__c = (Id)caseParentId;
                update currCase;
            }
            else if (tchSuccessCheck.size() > 0)
            {
                currCase.TeacherSuccess__c = (Id)caseParentId;
                update currCase;
            }
            else if (stdnProcessCheck.size() > 0)
            {
                currCase.StudentProcess__c = (Id)caseParentId;
                update currCase;
            }       
            else if (stdnTaskAttempt.size() > 0)
            {
                currCase.StudentTaskAttempt__c = (Id)caseParentId;
                update currCase;
            }
        System.debug('============> Current Case is ' + currCase.Id);
            return currCase;
    }
}