/*****************************************************************************************
* Name: FETeacherSuccessEmailHandler
* Author: Will Slade
* Purpose: Assign inbound emails to Teacher Success queue
* Revisions: 
*    - 1/01/13 Created Class
*    - 8/15/13 Carolyn Coronado and Alex Zhu. Copy from Student Concern Email handler. This allows the handler to do the following:  
               1.Parse the incomming email
               2.Try to Find out keyword concernid:xxxxx from email body. If StudentDisposition__c exist by given salesforce id xxxxxx, create a task relate to this object.
               3.If nothing found or object id invalid, then call super class to create a case for this email
******************************************************************************************/

global class FETeacherSuccessEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) 
    { 
        this.caseRecType = 'Teacher Success';
        this.queueName = 'FE Teacher Success Queue';
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
            List<StudentDisposition__c> sCons = [select id,TaskOwner__c From StudentDisposition__c where id=:concernid limit 1];
            System.debug(sCons+concernid);
            
            
            //if no student concernd found by given id, then go proceed with normal case creation process.
            if(sCons==null||sCons.size()!=1)
            { 
                return super.handleInboundEmail(email, env);
            }
            StudentDisposition__c sCon=sCons[0];
            
              // Add a new Task to the contact record we just found above.
               newTask.add(new Task(Description =  bodyText,
               Priority = 'Normal',
               Status = 'Inbound Email',
               Subject = email.subject,
               IsReminderSet = true,
               ReminderDateTime = System.now()+1,
               Ownerid=sCon.TaskOwner__c,
               WhatId =  sCon.Id));
         
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
		                attachment.ownerid = sCon.TaskOwner__c;
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
		                attachment.ownerid = sCon.TaskOwner__c;
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