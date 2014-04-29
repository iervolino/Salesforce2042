global class StudentConcernEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler {
 /*

 	This emailhandler and test class created at Aug 2013. by:  Carolyn Coronado, Yemeng zhu 
 	1.Parse the incomming email
 	2.Try to Find out keyword concernid:xxxxx from email body
 		2.1 if StudentDisposition__c or CodeofConductReferral__c exist by given salesforce id xxxxxx, create a task relate to this object.
 	3.If nothing found or object id invalid, then call super class to create a case for this email

 */
  global override Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env)
  {
        this.caseRecType = 'Student Concern';
        this.queueName = 'Concern-General';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = (test.isRunningTest() ? 'false' : 'true');
        email.Headers.add(hd); 

 
        // Create an InboundEmailResult object for returning the result of the 
        // Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
  
        String bodyText = '';
        // If there is no plainTextBody in the email, try to get the HTML body
        if(email.plainTextBody == null || email.plainTextBody == '')
        {
            if(email.htmlBody != null&& email.htmlBody.length()>0)
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
            
                bodyText = result1;
            }
        }
        else
        {
            bodyText = email.plainTextBody.trim();
        }
        
        //if no student concernd id include in email body, then proceed as normal case creation.
        if(bodyText.toLowerCase().indexOf('concernid:')==-1)
        { 
            return super.handleInboundEmail(email, env);
        }
        
        // Split up the plainTextBody into an array of Strings. (Hopefully each entry in the email is on its own line...)
        String[] bodyTextLines = bodyText.split('[\n]+', 0);
        String concernId = '';
        for(Integer i = 0; i < bodyTextLines.size(); i++)
        {
            String l = bodyTextLines[i];
            System.debug('this line==========>'+l); 
            if(l.toLowerCase().indexOf('concernid:')!=-1)
            {
                Integer beginIndex = l.toLowerCase().indexOf('concernid:')+9;
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                concernid = l.subString(beginIndex, endIndex).trim(); 
                system.debug('concernid:'+concernid+':');
            }
        }
        
        
         
        // New Task object to be created
        Task[] newTask = new Task[0];
         
          
        try 
        {
          /*  StudentDisposition__c sCon = [SELECT Id 
            FROM StudentDisposition__c
            WHERE id = :email.subject
            LIMIT 1];
            */
            List<StudentDisposition__c> sCons = [select id,TaskOwner__c From StudentDisposition__c where id=:concernid limit 1];
            List<CodeofConductReferral__c> sCocs = [select id,ownerid From CodeofConductReferral__c where id=:concernid limit 1];
            System.debug('student concern:'+ sCons+concernid);
            System.debug('code of concuct referral'+sCocs+concernid);
            id ownerid=null;
            id whatid=null;
            //see if this concernid relate to a record of StudentDisposition__c or CodeofConductReferral__c
            if(sCons!=null&&sCons.size()==1)
            {
            	ownerid=sCons[0].TaskOwner__c;
            	whatid=sCons[0].id;
            }else if(sCocs!=null&&sCocs.size()==1)
            {
            	ownerid=sCocs[0].ownerid;
            	whatid=sCocs[0].id;
            }
            //if no student concernd found by given id, then go proceed with normal case creation process.
            if(ownerid==null)
            { 
                return super.handleInboundEmail(email, env);
            } 
            
              // Add a new Task to the contact record we just found above.
               newTask.add(new Task(Description =  bodyText,
               Priority = 'Normal',
               Status = 'Inbound Email',
               Subject = email.subject,
               IsReminderSet = true, 
               ReminderDateTime = System.now()+1,
               Ownerid= ownerid,
               WhatId =  whatid)); 
         
             // Insert the new Task 
             insert newTask;    
             //process attachment
             
             
              if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) 
		      {
		            String bannerId = '';
		            List<Attachment> attachments = new List<Attachment>();    
		        
		            for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) 
		            {
		                Attachment attachment = new Attachment();
		                // Attach to the passed or created salesforce object
		                attachment.ParentId = newTask[0].id;
		                attachment.ownerid = ownerid;
		                attachment.Name = email.binaryAttachments[i].filename;
		                attachment.Body = email.binaryAttachments[i].body;
		                attachments.add(attachment);            
		            }
		        
		            insert attachments;
		            
		        }
                else if (email.textAttachments != null && email.textAttachments.size() > 0) 
		        {
		            String bannerId = '';
		            List<Attachment> attachments = new List<Attachment>();    
		        
		            for (integer i = 0 ; i < email.textAttachments.size() ; i++) 
		            {
		                Attachment attachment = new Attachment();
		                // Attach to the passed or created salesforce object
		                attachment.ParentId = newTask[0].id;
		                attachment.ownerid = ownerid;
		                attachment.Name = email.textAttachments[i].filename;
		                attachment.Body = Blob.valueof(email.textAttachments[i].body);
		                attachments.add(attachment);            
		            }
		        
		            insert attachments;
		            
		        }
         
             System.debug('New Task Object: ' + newTask );  
             
              
        }
        // If an exception occurs when the query accesses 
        // the contact record, a QueryException is called.
        // The exception is written to the Apex debug log.
       catch (QueryException e) {
           System.debug('Query Issue: ' + e);
       }
       
       // Set the result to true. No need to send an email back to the user 
       // with an error message
       result.success = true;
       
       // Return the result for the Apex Email Service
       return result;
      }
}