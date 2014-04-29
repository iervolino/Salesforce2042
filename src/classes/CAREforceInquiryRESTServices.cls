// Accesible from ~/services/apexrest/inquiryform
@RestResource(urlMapping='/inquiryform')
global class CAREforceInquiryRESTServices {

    @HttpPost
    global static Map<String, String> inquiry(String id, Map<String, String> fields, Map<String, String> requiredQuestions, Map<String, String> optionalQuestions, Boolean grade) {
        // Operating Variables
        Account account = null;
        Contact contact = null;
        
        // Submitted without an id
        if (id == null || id =='') {
            // Check system for matching record
            contact = checkForExistingInquiry(fields);
            
            // New person
            if (contact == null) {
                return processNew(fields, requiredQuestions, optionalQuestions, grade);
            } 
            // Already in system
            else {
                account = New Account(id = contact.accountId);
                contact = New Contact(id = contact.Id);
            }
        }
        else {
            Map<String, String> accountAndContact = getAccountAndContactIds(id);
            
            // Status is an error message, pass to caller
            if (accountAndContact.get('status') != null) {
                return accountAndContact;
            }
            
            account = New Account(id = accountAndContact.get('accountId'));
            contact = New Contact(id = accountAndContact.get('contactId'));
        }
        
        // Continue with update
        return processUpdate(account, contact, fields, requiredQuestions, optionalQuestions, grade);
    }
    
    /**
     * Determine if new record should be crated as a Lead or Complete Record
     * Complete Record = Account, Contact, Opportunity, and Student Attributes
     */
    private static Map<String, String> processNew(Map<String, String> fields, Map<String, String> requiredQuestions, Map<String, String> optionalQuestions, Boolean grade) {
        // Assume we have enough information to create a complete record
        Boolean sufficientInformation = true;
        
        // Create New Everything
        Contact contact = new Contact();
        StudentAttributes__c attributes = new StudentAttributes__c();
        Opportunity opportunity = new Opportunity();
        
        // Map passed fields to objects
        setFields(fields, contact, opportunity, attributes);
        
        // Check that enough information has been provided for a complete record
        try {
            sufficientInformation = checkRecordIsSufficient(contact);
        } catch(Exception ex) {
            // Do nothing, we want to capture it but any error in the data should be dumped into the Lead object.
            sufficientInformation = false;
        }
        
        // New records that are not suffiently complete create leads
        if (!sufficientInformation) {
            // Create Lead, Return Response
            return createLead(contact, opportunity);
        }
 
        // Create New Record
        Map<String, String> r = createNewRecord(contact, opportunity, attributes, requiredQuestions, optionalQuestions, grade);
        //LeadQual
        CAREforceUtility.createExternalLeads(opportunity);
        //Return Response
        return r;
    }
    
    /**
     * Create Lead
     *
     * Returned keys: id, status, newopportunity, graded
     */
    private static Map<String, String> createLead(Contact contact, Opportunity opportunity) {
        Map<String, String> response = New Map<String, String>();
        
        insert new Lead(
            FirstName = contact.firstName,
            LastName = contact.lastName,
            Phone = contact.phone, 
            Email = contact.otherEmail__c,
            MobilePhone = contact.mobilePhone,
            FieldRep__c = opportunity.fieldrep__c, 
            MarketingProgram__c = opportunity.MarketingProgram__c,
            Street = contact.MailingStreet,
            City = contact.MailingCity,
            State = contact.MailingState,
            PostalCode = contact.MailingPostalCode,
            PostingSource__c = opportunity.PostingSource__c,
            PostingScoreId__c = opportunity.PostingScoreId__c,
            LeadSource = opportunity.LeadSource,
            ReferId__c = opportunity.ReferId__c,
            country = contact.MailingCountry
        );          
        
        response.put('id', null);
        response.put('status', 'incomplete');
        response.put('newopportunity', 'false');
        response.put('graded', 'false');
        
        return response;
    }
    
    /**
     * Manage creation of (Account), Contact, Opportunity, and Student Attributes
     *
     * Returned keys: id, status, newopportunity, grade, updatedConverted
     */
    private static Map<String, String> createNewRecord(Contact contact, Opportunity opportunity, StudentAttributes__c attributes, Map<String, String> requiredQuestions, Map<String, String> optionalQuestions, Boolean grade) {
        Map<String, String> response = New Map<String, String>();
        
        // Save contact record (contact trigger will create account)
        saveContact(contact);
        
        Map<String, String> accountAndContact = getAccountAndContactIds(contact.id);
            
        // Status is an error message, pass to caller
        if (accountAndContact.get('status') != null) {
            return accountAndContact;
        }
        
        String accountId = accountAndContact.get('accountId');
        
        // Add Account Id to response
        response.put('id', String.valueOf(contact.id));
        
        // Add Status - new records created (account & contact)
        response.put('status', 'inserted');
        
        // New opportunity created
        response.put('newopportunity', 'true');
        
        // Set Lead Grade to Not Scored, Prep to send back to caller
        // Set here as this is specific only to newly created opportunities
        // If grade == true then these will be overwritten in the processing of questions
        opportunity.leadGrade__c = 'NS';
      
     //TODO:  9/17/2013   
     //This code will be used to pregrade an careprofile so that it can be round robined by grade.  
     //   String leadGrade = CAREforceUtility.getScoreFromQuestions(requiredQuestions,optionalQuestions, opportunity.ReferID__c);
     //  if (leadGrade != null)
    //   {
    //
    //    opportunity.LeadGrade__c = leadGrade ;
    //   }
        response.put('grade', opportunity.leadGrade__c); 
        
        // Save Attributes and Opportunity
        saveAttributes(attributes, accountId, contact.id);
        saveOpportunity(opportunity, accountId, contact.id, attributes.id);
        
        response.putAll(precessQuestions(opportunity, requiredQuestions, optionalQuestions, grade));
        
        // Sign-up for Eloqua
        // Has to happen after opportunity has been saved
        // Tested in TestCAREforceUtilities, does not need to be repeated.
        if (!Test.isRunningTest()) {
            Opportunity generatedValues = [SELECT Owner.Name, EmailCampusFull__c, EmailCampusShort__c, MarketingProgram__r.Name, CareStatus__c FROM Opportunity WHERE Id = :opportunity.Id];
            
            CAREforceUtility.sendBasicInfoToEloqua(contact.Email, contact.FirstName, generatedValues.MarketingProgram__r.Name, 
                                                   generatedValues.EmailCampusFull__c, generatedValues.EmailCampusShort__c, generatedValues.Owner.Name, 
                                                   CAREforceUtility.trimCAREStatusValue(opportunity.careStatus__c));
        }
        
        // Not exactly sure what this is about
        // TODO: Figure out if this is needed for anything
        response.put('updatedConverted', String.valueOf(opportunity == null ? true : false)); 
        
        return response;
    }
    
    /**
     * Manage Update Process
     *
     * Returned keys: id, status, newopportunity
     */
    private static Map<String, String> processUpdate(Account account, Contact contact, Map<string, String> fields, Map<String, String> requiredQuestions, Map<String, String> optionalQuestions, Boolean grade) {
        Map<String, String> response = New Map<String, String>();
        
        // Add Account Id to response
        response.put('id', String.valueOf(contact.id));
        response.put('status', 'updated');
        
        // Get Student Attributes 
        // Looks for existing, if not it builds a new one
        StudentAttributes__c attributes = getAttributes(contact.id);
        
        // Get Opportunity
        // Looks for existing, if not it builds a new one
        Opportunity opportunity = getOpportunity(contact.id);
        
        // New opportunity created? communicate to calling service
        if (opportunity.id == null) {
            response.put('newopportunity', 'true');
        }
        else {
            response.put('newopportunity', 'false');
        }
        
        // Map passed fields to objects
        setFields(fields, contact, opportunity, attributes);
        
        // Create/Update objects
        saveContact(contact);
        saveAttributes(attributes, account.id, contact.id);
        saveOpportunity(opportunity, account.id, contact.id, attributes.id);
        
        response.putAll(precessQuestions(opportunity, requiredQuestions, optionalQuestions, grade));
        
        return response;
    }
    
    /**
     * Update if we have an id, otherwise create prospect contact record
     * and mark as using person account for compatability's sake
     */
    private static void saveContact(Contact contact) {
        // Update changes
        if (contact.id != null) {
            update contact;
            return;
        }
        
        // Get record type id
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;   
        
        // Some other systems still rely on this flag
        // Set it even though it is not technically true any more
        contact.isPersonAccount__c = true;
        
        // Create Contact
        insert contact;
    }
    
    /**
     * Attache Attributes to Account and Contact.
     * Update if we have an id, otherwise insert
     */
    private static void saveAttributes(StudentAttributes__c attributes, String accountId, String contactId) {
        // Set Object Relationships
        attributes.StudentAccount__c = accountId;
        attributes.StudentContact__c = contactId;
        
        if (attributes.id != null) {
            update attributes;
            return;
        }
        
        insert attributes;
    }
    
    /**
     * Attache Opportunity to Account, Contact, and Attributes.
     * Update if we have an id, otherwise insert
     * If inserting, add default fields
     */
    private static void saveOpportunity(Opportunity opportunity, String accountId, String contactId, String attributesId) {
        // Set Object Relationships
        opportunity.accountId = accountId;
        opportunity.StudentContact__c = contactId;
        opportunity.StudentAttributes__c = attributesId;
        
        // Only for new opportunities
        if (opportunity.id != null) {
            update opportunity;
            return;
        }
            
        opportunity.CloseDate = date.parse('12/01/2100');
        opportunity.careStatus__c = 'PROS – Prospect';
        opportunity.stageName = 'Prospect';
        opportunity.originallyInquiry__c = true;
        
        // Eloqua Unique ID
        opportunity.EmailId__c = CAREforceUtility.randomUUID();
        
        setEnrollmentCounselor(opportunity);
        
        insert opportunity;
        
         /* Call to method to create a PURL
            Method added October 2013 by Dave Perry

            This method is used to create a unique personal url for the personal pages using Site.com
        */
        PersonalPages.generateIdentifier(opportunity.id, contactId);
    }
    
    /**
     * Get account id and contact id using the contact as the base record
     */
    private static Map<String, String> getAccountAndContactIds(String passedId) {
        Map<String, String> response = New Map<String, String>();
        List<Contact> contacts = null;
        
        // Determine what the Id we have is (account or contact)
        String passedIdType = getObjectNameFromId(passedId);
        
        if (passedIdType == 'account') {
            // Use contact as the base, instead of account
            contacts = [SELECT Id, AccountId FROM Contact WHERE accountId = :passedId];
        }
        else {
            contacts = [SELECT Id, AccountId FROM Contact WHERE id = :passedId];
        }
        
        // Account with ID was not found; ID is invalid.
        if (contacts.isEmpty()) {
            // Communicate error
            response.put('status', 'Invalid ID');
            
            // End processing; return response
            return response;
        }
        
        response.put('accountId', contacts.get(0).accountId);
        response.put('contactId', contacts.get(0).id);
        
        return response;
    }
    
    /**
     * Get object type based on its id
     * Only does account and contact
     */
    private static String getObjectNameFromId(String id) {
        if (id.left(3) == '001') {
            return 'account';
        }
        
        return 'contact';
    }

    
    /**
     * Get id of existing Student Attributes object
     * Lean on contact as the base record
     */
    private static StudentAttributes__c getAttributes(String contactid) {
        // Get student attributes
        List<StudentAttributes__c> existingAttributes = [SELECT id FROM StudentAttributes__c WHERE StudentContact__c = :contactid];
        
        // If one doesn't exist, return null
        if (existingAttributes.size() < 1) {
            return New StudentAttributes__c();
        } 
        
        return existingAttributes.get(0);
    }
    
    /**
     * Get id of current Opportunity object
     * Lean on contact as the base record
     */
    private static Opportunity getOpportunity(String contactId) {
        // Get most recent "current" opportunity
        // Current = inquiry in the the last 6 months or application in the past 18
        DateTime timestamp = DateTime.now();
        timestamp = timestamp.addMonths(-6);
        DateTime applicantTimestamp = DateTime.now();
        applicantTimestamp = applicantTimestamp.addMonths(-18);                
        List<Opportunity> existingOpportunities = [SELECT id, careStatus__c FROM Opportunity WHERE StudentContact__c = :contactId AND ((CareStatus__c like 'PROS%' AND createdDate > :timestamp) OR createdDate > :applicantTimestamp) ORDER BY createdDate DESC];
        
        // Does a current, active opportunity exist
        if (existingOpportunities.size() < 1) {
            return New Opportunity();
        }
        
        return existingOpportunities.get(0);
    }
    
    /**
     * Search for possible existing record for this person
     */
    private static Contact checkForExistingInquiry(Map<String, String> fields) {
        // Operating Variables
        String firstName, lastName, email, phone;
        
        // Pull out needed information to check for existing record
        for (String key : fields.keySet()) {
            if (key.toLowerCase() == 'firstname') firstName = fields.get(key);
            if (key.toLowerCase() == 'lastname') lastName = fields.get(key);
            if (key.toLowerCase() == 'email') email = fields.get(key);
            if (key.toLowerCase() == 'phone') phone = fields.get(key);
        }
        
        return CAREforceUtility.checkProspectForExistingContact(firstName, lastName, email, phone, null, null);
    }
    
    /**
     * Test if record has complete information
     * Incomplete information will cause the creation on Leads instead of full records
     */
    private static Boolean checkRecordIsSufficient(Contact contact) { 
        // Requires email, name, address (street, city, and country), and phone 
        return contact.Email != null && contact.Email != '' 
                && contact.FirstName != null && contact.FirstName != '' && contact.LastName != null && contact.LastName != ''
                && contact.MailingStreet != null && contact.MailingStreet != ''
                && contact.MailingCity != null && contact.MailingCity != ''
                && contact.MailingCountry != null && contact.MailingCountry != ''
                && contact.Phone != null && contact.Phone != '';
    }   
    
    /**
     * Get an enrollment counselor for the opportunity
     * TODO: Should have a default instead of the user calling the service
     */
    private static void setEnrollmentCounselor(Opportunity opportunity) {
        if (opportunity.MarketingProgram__c != null) {
            List<CareProgramMiddleEarth__c> programs = [SELECT name FROM CareProgramMiddleEarth__c WHERE id = :opportunity.MarketingProgram__c]; 
            if (!programs.isEmpty()){
                Id ec = CAREforceUtility.nextEnrollmentCounselor(programs.get(0).name); 
                //Id ec =CAREforceUtility.nextEnrollmentCounselorByGrade(programs.get(0).name,  opportunity.leadGrade__c);
                if (ec != null) {
                    opportunity.ownerid = ec;
                }
            }
        }    
    }
    
    /**
     * Add questions and deal with grading
     */
    private static Map<String, String> precessQuestions(Opportunity opportunity, Map<String, String> requiredQuestions, Map<String, String> optionalQuestions, Boolean grade) {
        // Create Response
        Map<String, String> response = new Map<String, String>();
        
        // If told to grade without any additional responses, done't
        // Communicate that back to calling function
        if (requiredQuestions == null && optionalQuestions == null && grade) {
            response.put('graded', String.valueOf(false));
            
            return response;
        }
        
        // Add Responses to Enrollment Questions
        addQuestionResponses(requiredQuestions, opportunity.Id);
        addQuestionResponses(optionalQuestions, opportunity.Id);
        
        if (grade != null && grade && opportunity.careStatus__c.startsWith('PROS')) {
            // Only required questions are scored, optional questions which appear on page two of the inquiry
            // form on the marketing website are not included. This becomes scored on first page insert unless
            // the data was incomplete and it was placed into a Lead object.
            CAREforceUtility.ScoreResult result = CAREforceUtility.scoreLead(opportunity);
            //System.assertEquals(opportunity.leadGrade__c, result.grade);
            opportunity.leadGrade__c = result.grade;
            opportunity.leadScore__c = result.score;
            
            update opportunity;
            
            response.put('grade', opportunity.leadGrade__c);                
        }
        
        response.put('graded', String.valueOf(grade != null ? grade : false));
            
        return response;        
    }
    
    /**
     * Attach enrollment responses to opportunity
     * Update any questions that have been previously answered
     */
    private static void addQuestionResponses(Map<String, String> responses, String opportunityId) {
        if (responses == null) {
            return;
        }
        
        List<EnrollmentResponses__c> existingResponses = [SELECT id, AnswerQuestion__c, QuestionNumber__c FROM EnrollmentResponses__c WHERE CAREProfile__c= :opportunityId];
        List<EnrollmentResponses__c> updates = new List<EnrollmentResponses__c>();
        List<EnrollmentResponses__c> inserts = new List<EnrollmentResponses__c>();
    
        EnrollmentResponses__c existing = null;
    
        for (String key : responses.keySet()) {
            existing = null;
        
            for (EnrollmentResponses__c existingResponse : existingResponses) {
                if (existingResponse.QuestionNumber__c == key) existing = existingResponse;
            }
            
            if (existing == null) {
                inserts.add(new EnrollmentResponses__c(QuestionNumber__c=key, AnswerQuestion__c=responses.get(key), CAREProfile__c=opportunityId, DateAnswered__c=date.today()));                
            } else {
                existing.AnswerQuestion__c = responses.get(key);
                updates.add(existing);
            }
        }
        
        if (updates.size() > 0) update updates;
        if (inserts.size() > 0) insert inserts;
    }
    
    /**
     * Set Field values also some administrative fields
     */
    private static void setFields(Map<String, String> fields, Contact contact, Opportunity opportunity, StudentAttributes__c attributes) {
        // Map passed fields to objects
        for (String key : fields.keySet()) {
            setField(key, fields.get(key), contact, attributes, opportunity);
        }
        
        if (String.isNotBlank(contact.FirstName) && String.isNotBlank(contact.LastName)) {
            attributes.name = contact.FirstName + ' ' + contact.LastName;
            opportunity.name = contact.FirstName + ' ' + contact.LastName;
        }
        
        // For old records (set to not sync), have them start syncing to Eloqua
        // Does no damage to set it on all records running through this process
        contact.ExcludeFromEloqua__c = false;
    }
    
    /**
     * Manager of mapings
     */
    private static void setField(String key, String value, Contact contact, StudentAttributes__c attributes, Opportunity opportunity) {    
        // Name
        if (key.toLowerCase() == 'firstname') contact.FirstName = value;
        if (key.toLowerCase() == 'lastname') contact.LastName = value;
        
        // Address
        if (key.toLowerCase() == 'street' && value != null && value != '') contact.MailingStreet = value;
        if (key.toLowerCase() == 'city' && value != null && value != '') contact.MailingCity = value;
        if (key.toLowerCase() == 'state' && value != null && value != '') contact.MailingState = value;
        if (key.toLowerCase() == 'postalcode' && value != null && value != '') contact.MailingPostalCode = value;
        if (key.toLowerCase() == 'country') {
            if (value == 'USA') value = 'US';
                
            contact.MailingCountry = value;
        } 
        
        // Email can never be set to null after it has been set once.
        if (key.toLowerCase() == 'email' && value != null && value != '') {
            contact.otherEmail__c = value.toLowerCase().trim();
            contact.Email = value.toLowerCase().trim();
        }
        
        // Phone
        if (key.toLowerCase() == 'phone' && value != null && value != '') {
            // Attempt to standardize phone formatting
            String cleanPhone = null;
            
            cleanPhone = value.replaceAll('[^0-9]','');
            if (cleanPhone.length() == 10) {
                value = '(' + cleanPhone.substring(0, 3) + ') ' + cleanPhone.substring(3, 6) + '-' + cleanPhone.substring(6, 10);
            }
            
            contact.Phone = value;
            contact.HomePhone = value;
        }
        if (key.toLowerCase() == 'phoneextension') contact.phoneExtension__c = value;
        if (key.toLowerCase() == 'mobile') {
            // Attempt to standardize phone formatting
            String cleanPhone = null;
            
            cleanPhone = value.replaceAll('[^0-9]','');
            if (cleanPhone.length() == 10) {
                value = '(' + cleanPhone.substring(0, 3) + ') ' + cleanPhone.substring(3, 6) + '-' + cleanPhone.substring(6, 10);
            }
            
            contact.MobilePhone = value;
            // Student job is overwritting MobilePhone so save to OtherPhone too
            contact.OtherPhone = value;
        }
        if (key.toLowerCase() == 'acceptstexting') contact.acceptsTexting__c = Boolean.valueOf(value);
        
        // Care Profile
        // TODO: These should be more protected. Many can cause problems in reports or 
        // data integrity switch just because a newer value has been sent.
        if (key.toLowerCase() == 'program') opportunity.MarketingProgram__c = value;
        // An existing record will already have a referid. Don't overwrite.
        if (key.toLowerCase() == 'referid' && opportunity.Id == null) {
            opportunity.referid__c = value;
            
            List<MarketingSourceCode__c> sources = [SELECT id FROM MarketingSourceCode__c WHERE Name = :value];
            if (sources.size() > 0) {
                opportunity.MarketingSource__c = sources.get(0).Id;
            }
        }
        if (key.toLowerCase() == 'fieldrep' && value != null && value != '') opportunity.fieldrep__c = value;
        if (key.toLowerCase() == 'postingsource') opportunity.PostingSource__c = value;
        if (key.toLowerCase() == 'postingscoreid') opportunity.PostingScoreId__c = value;
        if (key.toLowerCase() == 'source') opportunity.LeadSource = value;
        if (key.toLowerCase() == 'startdate' && value != null) opportunity.CloseDate = Date.parse(value);
             
        // Student Attributes
        if (key.toLowerCase() == 'nickname' && value != null && value != '') attributes.nickName__c = value;
        if (key.toLowerCase() == 'campus' && value != null && value != '') attributes.Affiliation__c = value;
    }
}