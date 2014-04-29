/*****************************************************************************************
*
    Author:  Brad King
    Date:    5/6/2013
    
    This class handles emails coming from TaskStream to ecare@wgu.edu.
    Students (and mentors/staff/faculty) can fill out web forms regarding inqueries about assessments.
    Those forms are then emailed. This class parses through that email, extracting information about the student.
    It then creates a Case object and populates fields with what's needed from the form.
    
* Revisions: 
*    - 6/4/13 Updated mapping of the values subject, studentDRF, and studentTask. Carolyn Coronado
*    - 6/6/13 Updated to manage cases from all email addresses. Carolyn Coronado
*	 - 8/8/13 Update to parse multiple line Description and append time zone behind phone. Test case improved to 94% coverage. Yemeng Zhu 
******************************************************************************************/

global class ECareEmailHandler extends InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        // Set to true to enable debug output
        boolean verbose = true;
        
        if(verbose)
            System.debug('=====>:\tGot ECare email');
        
        // Set flags appropriately
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // All the error checking I put in later in code won't happen with this bit. If this is removed, the error checking ought to hold
       if(email.fromAddress.toLowerCase() != 'notification@taskstream.com')
        /*{ --Modified by Carolyn 6/6, commented below lines out 
            if(verbose)
                System.debug('ECare email was not sent from notification@taskstream.com--exiting');
            result.success = false;
            return result;
        }*/
        
      
   {   
        //  --Modified by Carolyn 6/6, handler for other FROM email addresses
        this.caseRecType = 'ECare';
        this.queueName = 'ECare';
        Messaging.InboundEmail.Header hd = new Messaging.InboundEmail.Header();
        hd.name = 'caseFeedCheck';
        hd.value = 'true';
        email.Headers.add(hd);        
        return super.handleInboundEmail(email, envelope);
 }

else
        // Get email body and try to determine who it's about
        //    Student name:
        //    Student ID:
        //    Phone:
        //    Email:
        //    Program:
        //    DRF Category/Requirement:
        //    Category of request:            Note that there is actually a new line in the email that separates the field name with its value.
        //    * (Value of Category of request)
        //    Description:
        {
        String bodyText = '';
        // If there is no plainTextBody in the email, try to get the HTML body
        if(email.plainTextBody == null || email.plainTextBody == '')
        {
            if(email.htmlBody != null)
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
            bodyText = email.plainTextBody.trim();
        
        // Split up the plainTextBody into an array of Strings. (Hopefully each entry in the email is on its own line...)
        String[] bodyTextLines = bodyText.split('[\n]+', 0);
        
        if(verbose)
            System.debug('=====>:\tNumber of plainTextLines: ' + bodyTextLines.size());
        
        // Prints out plainTextLines. Disabled while I look at my code
        if(verbose && false)
            for(String l : bodyTextLines)
                System.debug('=====>:\t' + l);
        
        // All variables which we need to populate
        String[] studentname;
        String studentID;
        String studentPhone='';
        String studentEmail;
        String studentDRF;
        String studentTask;
        String studentCategoryOfRequest;
        String studentDescription;
        
        // Loop through body and extract information
        //for(String l : bodyTextLines)
        for(Integer i = 0; i < bodyTextLines.size(); i++)
        {
            String l = bodyTextLines[i];
            System.debug('this line==========>'+l); 
            if(l.startsWith('Student name:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                String wholeName = l.subString(beginIndex, endIndex).trim();
                studentName = wholeName.split('[ ]+', 0);    // In case a student has middle name or odd name like "Steve Van De Graff"
                
                if(verbose)
                    System.debug('=====>:\tStudent name: ' + wholeName + '\t' + studentName);
            }
            
            else if(l.startsWith('Student ID:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                studentID = l.subString(beginIndex, endIndex).trim();
                
                if(verbose)
                    System.debug('=====>:\tStudent ID: ' + studentId);
            }
            
            else if(l.startsWith('Phone:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                studentPhone = l.subString(beginIndex, endIndex).trim() + ' '  + studentPhone;
                
                // The Field this data is going into on the Case object has a limit of 40 characters.
                if(studentPhone.length() > 40)
                    studentPhone = studentPhone.subString(0, 39);
                
                if(verbose)
                    System.debug('=====>:\tPhone and time zone: ' + studentPhone);
            }
            // 8/2/2013 add by yemeng to append time zone behind phone field , time zone comes above phone in the inboundemail
            else if(l.startsWith('Time Zone:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                studentPhone = studentPhone + ' '+ l.subString(beginIndex, endIndex).trim();
                
                // The Field this data is going into on the Case object has a limit of 40 characters.
                if(studentPhone.length() > 40)
                    studentPhone = studentPhone.subString(0, 39);
                
                if(verbose)
                    System.debug('=====>time zone: ' + studentPhone);
            }
            else if(l.startsWith('Email:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                studentEmail = l.subString(beginIndex, endIndex).trim();
                
                if(verbose)
                    System.debug('=====>:\tEmail: ' + studentEmail);
            }
            
            else if(l.startsWith('Program:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                studentDRF = l.subString(beginIndex, endIndex).trim();
                
                if(verbose)
                    System.debug('=====>:\tProgram: ' + studentDRF);
            }
            
            else if(l.startsWith('DRF Category/Requirement:'))
            {
                Integer beginIndex = l.indexOf(':');
                Integer endIndex = l.length();
                
                beginIndex = (beginIndex < 0 || beginIndex + 2 > l.length()) ? 0 : beginIndex + 2;
                
                studentTask = l.subString(beginIndex, endIndex).trim();
                
                if(verbose)
                    System.debug('=====>:\tDRF Category/Requirement: ' + studentTask);
            }
            
            else if(l.startsWith('Category of request:'))
            {
                // The 'Category of request' is on its own line, and the next line has the actual data
                // Also, the TaskStream form has multiple check boxes. More than one can be selected.
                // Shanon has asked that if multiple categories are present, just grab the first one.
                // I offered to have any other categories dumped into another text box on the Case and she declined.
                // If the need arises in the future to do so, it should be an easy change in this code.
                Integer j = i;
                List<String> categories = new List<String>();
                while(++j < bodyTextLines.size())
                {
                    if(bodyTextLines[j].startsWith('*'))
                    {
                        String ll = bodyTextLines[j].trim();
                        
                        if(verbose && false)
                            System.debug('=====>:\t' + ll);
                        
                        Integer llBeginIndex = (ll.indexOf('*') + 2 < ll.length()) ? ll.indexOf('*') + 2 : 0;
                        Integer llEndIndex = ll.length();
                        String llSub = ll.subString(llBeginIndex, llEndIndex).trim();
                        
                        // Change the name of the category if it matches this string
                        if(llSub.indexOf('Guidance for accessing resources') != -1)
                        {
                            llEndIndex = 32;
                            llSub = llSub.subString(0, llEndIndex).trim();
                        }
                        if(llSub.length() > 40)
                            llSub = llSub.subString(0, 39).trim();
                        
                        categories.add(llSub);
                    }
                }
                
                studentCategoryOfRequest = 'None';
                if(categories.size() > 0)
                    studentCategoryOfRequest = categories[0];
                
                if(verbose)
                    System.debug('=====>:\tCategory of request: ' + studentCategoryOfRequest);
            }
            
            else if(l.startsWith('Description:'))
            {
                Integer beginIndex = bodyText.indexOf('Description:');
                Integer endIndex = bodyText .length();
                System.debug('=======>indexs:'+ beginIndex+' '+endindex);
                beginIndex = (beginIndex < 0 || beginIndex + 12 > bodyText.length()) ? 0 : beginIndex + 12;
                
                System.debug('=======>indexs:'+ beginIndex+' '+endindex);
                studentDescription = bodyText.subString(beginIndex, endIndex).trim();
                
                if(verbose)
                    System.debug('=====>:\tDescription: ' + studentDescription);
            }
        }
        
        // Supposedly we now have all the information we need to find the SalesForce StudentContact this ECare email is from
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND DeveloperName = 'StudentRecord' LIMIT 1];
        
        if(verbose)
            System.debug('=====>:\tRecordType(s): ' + rts + 'Studentid'+ studentID);
        
        List<Contact> cntcts = [SELECT Id, Name, Email, StudentID__c, Mentor__c FROM Contact WHERE StudentID__c = :studentID AND RecordTypeId IN :rts ORDER BY Id];
        
        if(verbose)
            System.debug('=====>:\tContacts: ' + cntcts);
        
        Contact contact;
        if(cntcts.size() == 0)
        {
            // Found no matching Contacts -- what do?
            if(verbose)
                System.debug('=====>:\tNo Contacts were found. :(');
        }
        else if(cntcts.size() == 1)
        {
            // Found exactly one matching Contact
            contact = cntcts[0];
        }
        else if(cntcts.size() > 1)
        {
            // There were multiple Contacts that matched... wtf. Since they're ordered by Id, just take lowest
            contact = cntcts[0];
            
            if(verbose)
                System.debug('=====>:\tIn ECareEmailHandler. You may want to see what\'s up with Student ID: ' + studentID + ', more than one Contact was returned.');
        }
        
        if(verbose)
            System.debug('=====>:\tContact: ' + contact);
        
        // Create new Case
        Case newCase = new Case();
        newCase.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'ECare' LIMIT 1].Id;
        
        if(contact != null)
        {
            newCase.ContactId = (contact != null) ? contact.Id : null;
        
            newCase.Subject = contact.Name + ' - ' + studentid; // 6/4 Modified by Carolyn to change the subject line from the DRF to the student name and id. Also remove validation of the 255 charac
                                                                   //8/2 2013 moved one line by yemeng to avoid null pointer exception
        }
        newCase.ECareDRF__c = studentDRF; // 6/4 Modified by Carolyn to change the subject line and host the DRF in a new field
        newCase.Task__c = studentTask; // 6/4 Modified by Carolyn to change Task to a new field 
        newCase.SuppliedPhone = studentPhone;            // This is the "Web phone" field on Case. Using this standard field instead of creating a new one
        newCase.StudentComments__c= studentDescription; // 6/4 Modified by Carolyn to change Student Comments to a new field 
        newCase.Reason = studentCategoryOfRequest;
        newCase.Status = 'New';
        newCase.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Case' AND DeveloperName = 'ECare'].Id;
        
        List<QueueSobject> queues = [SELECT QueueId FROM QueueSobject WHERE Queue.Name = 'ECare' LIMIT 1];
        
        if(verbose)
            for(QueueSobject q : queues)
                System.debug('=====>:\t' + q);
        
        if(queues.size() > 0)
            newCase.OwnerId = queues[0].QueueId;
            
        insert newCase;
        
        result.success = true;
        return result;
   }
    }
}