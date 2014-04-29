/*
*Author John Chan
*Slalom
*Contact my mentor modal currently only used in search but can eventually be added to the articles or other locations.
*/
public with sharing class CourseKbContactMentorController {
    private Contact currentUserContact;
    private String currentContactMobilePhone;
    private String currentContactPhone;
    
    public String userTimeZone { get; set; }
    public boolean contactViaEmail { get; set; }
    public String contactEmail { get; set; }
    public boolean contactViaPhone { get; set; }
    public String contactPhone { get; set; }
    public String otherContactPhone { get; set; }
    public String bestTimeToContact { get; set; }
    public String bestTimeToContactMeridiem { get; set; }
    public String comments { get; set; }
    public CourseKbContactMentorAttributes cmComponentAttributes { get; set; }
    public String studentCourseCode { get; set; }
    public String mentorContactEmail { get; set; }
    public String mentorContactName { get; set; }
    
    //TODO: Need to move to a more standard timezone method... as Phoenix can potentially be wrong as it does not follow daylight savings time
    private final List<String> TIME_ZONE_NAME = new List<String> { 'Eastern Time', 'Central Time', 'Mountain Time', 'Pacific Time', 'Alaska Time', 'Hawaii-Aleutian Time' };
    private final Map<String, String> TIME_ZONE_DISPLAY = new Map<String, String> { 'America/New_York' => TIME_ZONE_NAME.get(0), 'America/Indianapolis' => TIME_ZONE_NAME.get(0), 
            'America/Chicago' => TIME_ZONE_NAME.get(1), 'America/Denver' => TIME_ZONE_NAME.get(2), 'America/Phoenix' => TIME_ZONE_NAME.get(2), 'America/Los_Angeles' => TIME_ZONE_NAME.get(3), 
            'America/Anchorage' => TIME_ZONE_NAME.get(4), 'Pacific/Honolulu' => TIME_ZONE_NAME.get(5) };
    private final String OTHER_PHONE_SELECT = 'Other';
    private final List<String> CONTACT_MENTOR_EMAIL_TEMPLATES = new List<String> { 'StudentRequestHelp_Student', 'StudentRequestHelp_Mentor' };
    
    public CourseKbContactMentorController() {
        contactViaEmail = false;
        contactViaPhone = false;
        contactPhone = OTHER_PHONE_SELECT;
        TimeZone tz = UserInfo.getTimeZone();
        userTimeZone = TIME_ZONE_DISPLAY.get(tz.getID());
        
        List<Contact> contact = [SELECT Email, Phone, MobilePhone, Name, StudentID__c FROM Contact WHERE Id IN (SELECT ContactID FROM User WHERE Id = :UserInfo.getUserId()) LIMIT 1];
        if (contact.size() > 0) { //TODO: Should set the phone info here instead of passing currentUserContact around or move to an abstract contact that both Contact and User be set to
            currentUserContact = contact.get(0);
            contactEmail = currentUserContact.Email;
            currentContactMobilePhone = currentUserContact.MobilePhone;
            currentContactPhone = currentUserContact.Phone;
        } else {
            contactEmail = UserInfo.getUserEmail();
            User currentUser = [SELECT Phone, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
            currentContactMobilePhone = currentUser.MobilePhone;
            currentContactPhone = currentUser.Phone;
        }
        
        if (String.isNotEmpty(currentContactMobilePhone)) {
            contactPhone = currentContactMobilePhone;
        } else if (String.isNotEmpty(currentContactPhone)) {
            contactPhone = currentContactPhone;
        }
    }
    
    public PageReference submitContactMyMentorRequest() {
        if (validInput()) {
            try {
                Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
                for (EmailTemplate template : [SELECT Subject, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :CONTACT_MENTOR_EMAIL_TEMPLATES]) {
                    emailTemplateMap.put(template.DeveloperName, template);
                }
                Messaging.reserveSingleEmailCapacity(2);
                Messaging.SingleEmailMessage studentEmail = getStudentEmail(emailTemplateMap.get(CONTACT_MENTOR_EMAIL_TEMPLATES.get(0)));
                Messaging.SingleEmailMessage mentorEmail = getMentorEmail(emailTemplateMap.get(CONTACT_MENTOR_EMAIL_TEMPLATES.get(1)));
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { studentEmail, mentorEmail });
                hideComponent();
            } catch (Exception ex) {
                system.debug('Exception in CourseKbContactMentorController.submitContactMyMentorRequest. Failed to send emails out: ' + ex + ex.getStackTraceString());
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to sumbit request please contact technical support.'));
            }
        }   
        return null;
    }

    private boolean validInput() {
        if (String.isEmpty(comments)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please enter your comments.'));
        }
        if (String.isEmpty(bestTimeToContact)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please enter the best time to contact you'));
        }
        if ((!contactViaEmail) && (!contactViaPhone)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please select at least one way to contact you.'));
        }
        if (contactViaEmail && String.isEmpty(contactEmail)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please enter an email address.'));
        }
        if (contactViaPhone && contactPhone == OTHER_PHONE_SELECT && String.isEmpty(otherContactPhone)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please enter a phone number.'));
        }
        boolean validInput = (ApexPages.getMessages().size() == 0);
        cmComponentAttributes.displayMessages = !validInput;
        return validInput;
    }
    
    private Messaging.SingleEmailMessage getMentorEmail(EmailTemplate template) {
            String subject = template.Subject;
            subject = subject.replaceAll('\\{!Case.Contact\\}', (currentUserContact != null ? currentUserContact.Name : UserInfo.getName()));
            subject = subject.replaceAll('\\{!Case.WGUCourseCode__c\\}', studentCourseCode);
            String body = template.Body;
            body = body.replaceAll('\\{!Case.WGUCourseCode__c\\}', studentCourseCode);
            body = body.replaceAll('\\{!Case.Contact\\}', (currentUserContact != null ? currentUserContact.Name : UserInfo.getName()));
            body = body.replaceAll('\\{!Case.StudentID__c\\}', (currentUserContact != null ? currentUserContact.StudentID__c:''));
            String replaceContactEmail = String.isEmpty(contactEmail) ? '' : contactEmail;
            body = body.replaceAll('\\{!Case.WGUContactEmail__c\\}', replaceContactEmail);
            String replaceContactPhone = '';
            if (contactPhone == OTHER_PHONE_SELECT && String.isNotEmpty(otherContactPhone)) {
                replaceContactPhone = otherContactPhone;
            } else if (contactPhone != OTHER_PHONE_SELECT && String.isNotEmpty(contactPhone)) {
                replaceContactPhone = contactPhone;
            }
            body = body.replaceAll('\\{!Case.WGUContactPhone__c\\}', replaceContactPhone);
            body = body.replaceAll('\\{!Case.ContactViaEmail__c\\}', (contactViaEmail ? contactEmail : ''));
            body = body.replaceAll('\\{!Case.ContactViaPhone__c\\}', (contactViaPhone ? replaceContactPhone : ''));
            body = body.replaceAll('\\{!Case.WGUContactBestTime__c\\}', bestTimeToContact);
            body = body.replaceAll('\\{!Case.WGUContactBestTimeAmPm__c\\}', bestTimeToContactMeridiem);
            body = body.replaceAll('\\{!Case.WGUContactTimezone__c\\}', userTimeZone);
            body = body.replaceAll('\\{!Case.Description\\}', comments);            
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setReplyTo(contactEmail);
            email.setSenderDisplayName((currentUserContact != null ? currentUserContact.Name : UserInfo.getName()));
            email.setToAddresses(new List<String> { mentorContactEmail }); //TODO: Fix this
            email.setPlainTextBody(body);
            email.setSubject(subject);
            email.setSaveAsActivity(false);
            return email;
    }
    
    private Messaging.SingleEmailMessage getStudentEmail(EmailTemplate template) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setReplyTo(mentorContactEmail);
            if (String.isNotEmpty(mentorContactName)) {
                email.setSenderDisplayName(mentorContactName);
            }
            email.setToAddresses(new List<String> { contactEmail });
            email.setPlainTextBody(template.Body);
            email.setSubject(template.Subject);
            email.setSaveAsActivity(false);
            return email;
    }
    
    public void hideComponent() {
        cmComponentAttributes.displayMessages = false;
        cmComponentAttributes.isVisible = false;
    }
    
    public List<SelectOption> getTimeZoneSelections() {
        List<SelectOption> selections = new list<SelectOption>();
        for (String tzName : TIME_ZONE_NAME) {
            selections.add(new SelectOption(tzName, tzName));
        }
        return selections;
    }
    
    public List<SelectOption> getPhoneSelections() {
        List<SelectOption> selections = new list<SelectOption>();
        
        if (String.isNotEmpty(currentContactMobilePhone)) {
            selections.add(new SelectOption(currentContactMobilePhone, currentContactMobilePhone));
        }
        if (String.isNotEmpty(currentContactPhone)) {
            selections.add(new SelectOption(currentContactPhone, currentContactPhone));
        }
        selections.add(new SelectOption(OTHER_PHONE_SELECT, OTHER_PHONE_SELECT));
        return selections;
    }
}