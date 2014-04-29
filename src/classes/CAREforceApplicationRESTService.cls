// Accesible from ~/services/apexrest/applicationform
@RestResource(urlMapping='/applicationform')
global class CAREforceApplicationRESTService {
    
    @HttpPost
    global static Map<String, String> apply(String id, Map<String, String> fields, List<Map<String, String>> transcripts, List<Map<String, String>> employments, List<String> deleteTranscripts, Boolean noTranscripts) {
        // Operating Variables
        Account account = null;
        Contact contact = null;
        
        // Submitted without an id
        if (id == null || id =='') {
            // Check system for matching record
            contact = checkForExistingInquiry(fields); 
            
            // New person
            if (contact == null) {
                return processNew(fields, transcripts, employments);
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
        return processUpdate(account, contact, fields, transcripts, employments, deleteTranscripts, noTranscripts);
    }
    
    /**
     * Manage the creation of a new record
     */
    private static Map<String, String> processNew(Map<String, String> fields, List<Map<String, String>> transcripts, List<Map<String, String>> employments) {
        Map<String, String> response = new Map<String, String>();
        
        // Create New Everything
        Contact contact = new Contact();
        StudentAttributes__c attributes = new StudentAttributes__c();
        Opportunity opportunity = new Opportunity(careStatus__c = 'APNN – Application Incomplete PRAP');
        
        // Map passed fields to objects
        setFields(fields, contact, opportunity, attributes);
        
        // Save contact record (contact trigger will create account)
        saveContact(contact);
        
        // Get Account Id
        Map<String, String> accountAndContact = getAccountAndContactIds(contact.id);
        String accountId = accountAndContact.get('accountId');
        
        // Add Account Id to response
        response.put('id', String.valueOf(contact.id));
        
        response.put('account', 'created');
        response.put('attributes', 'created');
        response.put('opportunity', 'created');
        
        // Save everything
        saveAttributes(attributes, accountId, contact.id);
        saveEmployments(employments, attributes, opportunity);
        saveOpportunity(opportunity, accountId, contact.id, attributes.id);
        response.putAll(saveTranscripts(transcripts, accountId, opportunity.id));
        
        // Get and save admissions record (will create if one doesn't exist)
        Admission__c admissions = getAdmissions(opportunity.id);
        saveAdmissions(admissions);
        
        // Send information to Eloqua
        updateEloqua(opportunity.id);
        
        response.put('status', 'success');
        
        CAREforceUtility.createExternalLeads(opportunity);
        
        return response;
    }
    
    /**
     * Manage the updating of an existing record
     */
    private static map<String, String> processUpdate(Account account, Contact contact, Map<String, String> fields, List<Map<String, String>> transcripts, List<Map<String, String>> employments, List<String> deleteTranscripts, Boolean noTranscripts) {
        Map<String, String> response = new Map<String, String>();
        
        // Add Account Id to response
        response.put('id', String.valueOf(contact.id));
        
        StudentAttributes__c attributes = getAttributes(contact.id);
        Opportunity opportunity = new Opportunity();
        
        // Pull out needed information to check for existing record
        String opportunityType = null;
        for (String key : fields.keySet()) {
            if (key.toLowerCase() == 'type') opportunityType = fields.get(key);
        }
        
        // Only get opportunities of the type that we are creating
        opportunity = getOpportunity(contact.id, opportunityType);
        
        // Validation: we have an unpaid application
        // TODO: Update message
        // Really it is just that we have a completed application or record further in the process
        if (!validApplicationStatus(opportunity.careStatus__c)) {
            response.put('attributes', 'exists');
            response.put('status', 'Email used by active application.');
            
            return response;
        }
        
        // Map passed fields to objects
        setFields(fields, contact, opportunity, attributes);
        
        // Set response defaults
        response.put('account', 'updated');
        response.put('attributes', 'created');
        response.put('opportunity', 'created');
        
        // Update response accordingly
        if (attributes.id != null) {
            response.put('attributes', 'updated');
        }
        
        if (attributes.id != null) {
            response.put('opportunity', 'updated');
        }
        
        // Save everything
        saveContact(contact);
        saveAttributes(attributes, account.id, contact.id);
        saveEmployments(employments, attributes, opportunity);
        saveOpportunity(opportunity, account.id, contact.id, attributes.id);
        response.putAll(saveTranscripts(transcripts, account.id, opportunity.id));
        
        // Get and save admissions record (will create if one doesn't exist)
        Admission__c admissions = getAdmissions(opportunity.id);
        saveAdmissions(admissions);
        
        // Delete Indicated Transcripts
        deleteTranscripts(deleteTranscripts);
        
        // All transcripts should be deleted if the User selects that they have none
        if (noTranscripts != null && noTranscripts) {
            clearTranscripts(account.id, opportunity.id);
        }
        
        // Send information to Eloqua
        updateEloqua(opportunity.id);
        
        response.put('status', 'success');
          
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
     * Attach Attributes to Account and Contact.
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
     * Attach Opportunity to Account, Contact, and Attributes.
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
            
        // Continuing Grads set their Start Date
        // Everyone else gets this date
        if (opportunity.CloseDate == null) {
          opportunity.CloseDate = date.parse('12/01/2100');
        }
        opportunity.stageName = 'Applicant';
        opportunity.LeadGrade__c = 'A+';
        
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
     * Create an admissions object and attache it to opportunity
     */
    private static void saveAdmissions(Admission__c admissions) {
        // If one exists, ignore
        if (admissions.id != null) {
            return;
        }
        
        insert admissions;
    }
    
    /**
     * Manage the saving of multiple employments
     */
    private static void saveEmployments(List<Map<String, String>> employments, StudentAttributes__c attributes, Opportunity opportunity) {
        // Store Employment Information
        if (employments != null) {
            for (Map<String, String> employment : employments) {
                saveEmployment(employment, attributes, opportunity);
            }
        }
    }
    
    /**
     * Save a single employment record (or update existing)
     * TODO: we really shouldn't overwrite the most recent employment blindly
     */
    private static void saveEmployment(Map<String, String> employment, StudentAttributes__c attributes, Opportunity opportunity) { 
        StudentEmploymentHistory__c history = null;
        
        List<StudentEmploymentHistory__c> histories = [SELECT id FROM StudentEmploymentHistory__c WHERE StudentAttributes__c = :attributes.id AND isDeleted = false ORDER BY createdDate DESC];
        
        if (histories.size() > 0)
            history = histories.get(0);
        else {
            history = new StudentEmploymenthistory__c();
            history.StudentAttributes__c = attributes.id;
        }
        
        for (String key : employment.keySet()) {
            String value = employment.get(key);
        
            if (key.toLowerCase() == 'employerinformation') history.Employer__c = value;
            if (key.toLowerCase() == 'annualincome') history.annualIncome__c = value;
            if (key.toLowerCase() == 'employerother') history.OtherEmployer__c = value;
        }
        
        if (history.id != null) {
            update history;
        }
        else {
            insert history;
        }
        
        opportunity.StudentEmploymentHistory__c = history.id;
    }
    
    /**
     * Manage that saving of multiple transcripts
     */
    private static Map<String, String> saveTranscripts(List<Map<String, String>> transcripts, String accountId, String opportunityId) {
        // Create Response
        Map<String, String> response = new Map<String, String>();
        
        // Store Transcripts
        if (transcripts != null && !transcripts.isEmpty()) {
            // Delete any NONE transcripts if they exist 
            // It should only exist if there are no other transcripts
            List<StudentTranscript__c > results = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__c = :accountId AND degreeType__c = 'NONE'];
            delete results;
            
            String transcriptIds = '';
            
            for (Map<String, String> transcript : transcripts) {
                transcriptIds += saveTranscript(transcript, accountId, opportunityId) + ';';
            }
            
            response.put('transcriptIds', transcriptIds);
        }
        
        return response;
    }
    
    /**
     * Save a single transcript
     * TODO: This might need so help to avoid some issue that we get with transcripts
     */
    private static ID saveTranscript(Map<String, String> transcript, String accountId, String opportunityId) {
        StudentTranscript__c record = null;
        String institutionname = null;
        String degree = null;
        
        // Attempt to match to an existing transcript with institution and degree to update other details.
        // Will not match if a different college or degree are specified.
        for (String key : transcript.keySet()) {
            String value = transcript.get(key);
            if (key.toLowerCase() == 'institutionname') institutionname = value;
            if (key.toLowerCase() == 'degree') degree = value;
        }        
        
        List<StudentTranscript__c> records = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__c = :accountId 
                                                AND transcriptInstitution__c = :institutionname
                                                AND degreeType__c = :degree];
        
        if (records.size() > 0) {
            record = records.get(0);
        } else {
            record = new StudentTranscript__c();
            record.studentAccount__c = accountId;
            record.opportunity__c = opportunityId;
        }
        
        for (String key : transcript.keySet()) {
            String value = transcript.get(key);
            if (key.toLowerCase() == 'institutionname') record.InstitutionName__c = value;
            if (key.toLowerCase() == 'transcriptinstitution') record.transcriptInstitution__c = value;
            if (key.toLowerCase() == 'city') record.institutionCity__c = value;
            if (key.toLowerCase() == 'state') record.institutionState__c = value;
            if (key.toLowerCase() == 'zip') record.institutionZip__c = value;
            if (key.toLowerCase() == 'degree') record.degreeType__c = value;
            if (key.toLowerCase() == 'major') record.major__c = value;
            if (key.toLowerCase() == 'minor') record.minor__c = value;
            if (value != null && value != '') {
                if (key.toLowerCase() == 'dategraduated') record.dateDegreeReceived__c = Date.valueOf(value);
                if (key.toLowerCase() == 'attendancestart') record.collegeStartDate__c = Date.valueOf(value);
                if (key.toLowerCase() == 'attendanceend') record.collegeEndDate__c = Date.valueOf(value);
            }
        }
        
        if (record.id == null)
            insert record;
        else
            update record;
            
        return record.id;
    }
    
    /**
     * Delete Transcripts
     */
    private static void deleteTranscripts(List<String> deleteTranscripts) {
        // Delete Transcripts
        if (deleteTranscripts != null && !deleteTranscripts.isEmpty()) {
            List<StudentTranscript__c > results = [SELECT id FROM StudentTranscript__c WHERE id = :deleteTranscripts];
            delete results;
        }
    }
    
    /**
     * Delete all transcript, add a NONE
     * This is used by the application form to say that they will not be sending transcripts
     * TODO: remove the NONE transcript and store this piece of information in another way
     */
    private static void clearTranscripts(String accountId, String opportunityId) {
        List<StudentTranscript__c > results = [SELECT id FROM StudentTranscript__c WHERE StudentAccount__c = :accountId];
        delete results;
        
        // Add NONE record
        StudentTranscript__c record = new StudentTranscript__c();
        record.studentAccount__c = accountId;
        record.opportunity__c = opportunityId;
        
        record.degreeType__c = 'NONE';
        
        insert record;
    }
    
    /**
     * Verify that the Status of the opportunity is associated with an incomplete application
     */
    public static Boolean validApplicationStatus(String status) {
        if (status == 'APNN – Application Incomplete PRAP' ||
            status == 'APIN – Application Incomplete APCO' ||
            status == 'PRAP – Prospect Applied Online' ||
            status == 'APCO – Application Complete, Unpaid') {
            return true;
        }
        
        return false;
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
            response.put('status', 'Invalid Account ID');
            
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
    private static Opportunity getOpportunity(String contactId, String recordType) {
        // Get most recent "current" opportunity
        List<Opportunity> existingOpportunities = new List<Opportunity>();
        
        // If  a record filter provided, use it
        if (recordType != null) {
            DateTime applicantTimestamp = DateTime.now();
            applicantTimestamp = applicantTimestamp.addMonths(-12);
            
            // Only merge with existing apps of this type in the last 12 months
            existingOpportunities = [SELECT id, OriginallyInquiry__c, StudentAttributes__c, MarketingProgram__c, careStatus__c FROM Opportunity WHERE StudentContact__c = :contactId AND type = :recordType AND createdDate > :applicantTimestamp ORDER BY createdDate DESC];               
        }
        else {
            // Current = inquiry in the the last 6 months or application in the past 18
            DateTime timestamp = DateTime.now();
            timestamp = timestamp.addMonths(-6);
            DateTime applicantTimestamp = DateTime.now();
            applicantTimestamp = applicantTimestamp.addMonths(-18);
            
            // Wouldn't it catch an Inquiry in the last 18 months?
            existingOpportunities = [SELECT id, OriginallyInquiry__c, StudentAttributes__c, MarketingProgram__c, careStatus__c FROM Opportunity WHERE StudentContact__c = :contactId AND ((CareStatus__c like 'PROS%' AND createdDate > :timestamp) OR createdDate > :applicantTimestamp) ORDER BY createdDate DESC];               
        }
        
        // Does a current, active opportunity exist
        if (existingOpportunities.size() < 1) {
            // Create start of a PRAP record (no inquiry)
            return New Opportunity(careStatus__c = 'APNN – Application Incomplete PRAP');
        }
        
        Opportunity opportunity = existingOpportunities.get(0);
        
        if (opportunity.careStatus__c.startsWith('PROS')) {
            // Create start of APCO record (has inquiry)
            opportunity.careStatus__c = 'APIN – Application Incomplete APCO';
        }
        
        return opportunity;
    }
    
    /**
     * Search for admissions objects associated with record
     */
    private static Admission__c getAdmissions(String opportunityId) {
        // Does an admissions object exist
        List<Admission__c> existingAdmissions = [SELECT id FROM Admission__c WHERE AdmissionReview__c = :opportunityId ORDER BY createdDate DESC];               
       
        // If not, create one
        if (existingAdmissions.size() < 1) {
            return New Admission__c(AdmissionReview__c = opportunityId);
        }
        
        // Otherwise, return it
        return existingAdmissions.get(0);
    }
    
    /**
     * Search for possible existing record for this person
     */
    private static Contact checkForExistingInquiry(Map<String, String> fields) {
        // Operating Variables
        String firstName, lastName, email, phone, socialSecurityNumber, dob;
        
        // Pull out needed information to check for existing record
        for (String key : fields.keySet()) {
            if (key.toLowerCase() == 'firstname') firstName = fields.get(key);
            if (key.toLowerCase() == 'lastname') lastName = fields.get(key);
            if (key.toLowerCase() == 'email') email = fields.get(key);
            if (key.toLowerCase() == 'phone') phone = fields.get(key);
            if (key.toLowerCase() == 'ssn') socialSecurityNumber = fields.get(key);
            if (key.toLowerCase() == 'dob') dob = fields.get(key);
        }
        
        Contact contact = CAREforceUtility.checkProspectForExistingContact(firstName, lastName, email, phone, socialSecurityNumber, dob);
        
        return contact;
    }
    
    /**
     * Set Field values also some administrative fields
     */
    private static void setFields(Map<String, String> fields, Contact contact, Opportunity opportunity, StudentAttributes__c attributes) {
        // Check that Marketing Program is maintained
        String currentProgram = opportunity.MarketingProgram__c;
        
        for (String key : fields.keySet()) {
            setField(key, fields.get(key), contact, opportunity, attributes);
        }
        
        // Update Attributes and Opportunity names
        if (String.isNotBlank(contact.FirstName) && String.isNotBlank(contact.LastName)) {
            attributes.name = contact.FirstName + ' ' + contact.LastName;
            opportunity.name = contact.FirstName + ' ' + contact.LastName;
        }
        
        // Error: because of the way that updated programs are dealt with the program
        // could be an updated version of the same program and force a new EC assignment
        // Quick fix is to only assign EC on creation of opportunity and leave it to ECs
        // to reassign if program changes.
        // If they have changed programs, we need to change ECs to someone in the new program
        //if (opportunity.MarketingProgram__c != currentProgram) {
        //    setEnrollmentCounselor(opportunity);
        //}
        
        // For old records (set to not sync), have them start syncing to Eloqua
        // Does no damage to set it on all records running through this process
        contact.ExcludeFromEloqua__c = false;
    }
    
    /**
     * Manager of field mapings
     */
    private static void setField(String key, String value, Contact contact, Opportunity opportunity, StudentAttributes__c attributes) {
        // Name
        if (key.toLowerCase() == 'prefix')        contact.salutation = value;
        if (key.toLowerCase() == 'firstname')     contact.firstName = value;
        if (key.toLowerCase() == 'middleinitial') contact.middleInitial__c = value;
        if (key.toLowerCase() == 'lastname')      contact.lastName = value;
        if (key.toLowerCase() == 'suffix')        contact.suffix__c = value;
        
        // Email
        if (key.toLowerCase() == 'email')     contact.otherEmail__c = value.toLowerCase().trim();
        if (key.toLowerCase() == 'email')     contact.email = value.toLowerCase().trim();
        
        // Address
        if (key.toLowerCase() == 'street')    contact.mailingStreet = value;
        if (key.toLowerCase() == 'city')      contact.mailingCity = value;
        if (key.toLowerCase() == 'state')     contact.mailingState = value;
        if (key.toLowerCase() == 'zip')       contact.mailingPostalCode = value;
        if (key.toLowerCase() == 'country')   contact.mailingCountry = value;
        
        // Phone
        if (key.toLowerCase() == 'phone') {
            // Attempt to standardize phone formatting
            String cleanPhone = null;
            
            cleanPhone = value.replaceAll('[^0-9]','');
            if (cleanPhone.length() == 10) {
                value = '(' + cleanPhone.substring(0, 3) + ') ' + cleanPhone.substring(3, 6) + '-' + cleanPhone.substring(6, 10);
            }
            
            contact.Phone = value;
            contact.HomePhone = value;
        }
        if (key.toLowerCase() == 'ext')                 contact.phoneExtension__c = value;
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
        if (key.toLowerCase() == 'internationalphone')  contact.internationalPhone__c = value;
        
        // Contact (other)
        if (key.toLowerCase() == 'ssn')                     contact.socialSecurityNumber__c = value;
        if (key.toLowerCase() == 'itn')                     contact.ITINIndividualTaxIdentificationNumber__c = value;
        if (key.toLowerCase() == 'gender')                  contact.gender__c = value;
        if (key.toLowerCase() == 'dob')                     contact.dateOfBirth__c = value;
        
        // Opportunity
        if (key.toLowerCase() == 'type' && value == 'Continuing Grad') {
            opportunity.type = value;
            opportunity.recordtypeid = [select id from recordtype where name = 'ContinuingGrad' and sobjecttype = 'Opportunity' limit 1].id;
        
            // Returning Grads don't have Readiness Assessments
            // Check off to get to REDI status
            opportunity.ReadinessAssessmentCompleted__c = true;
        }
        if (key.toLowerCase() == 'startdate')               opportunity.CloseDate = Date.parse(value);
        if (key.toLowerCase() == 'learnmorefinancialaid')   opportunity.learnAboutFinancialAid__c = value.toLowerCase() == 'true';
        if (key.toLowerCase() == 'password')                opportunity.applicationPin__c = Decimal.valueOf(value);
        if (key.toLowerCase() == 'graduatehighschool')      opportunity.graduatedHighSchool__c = value.toLowerCase() == 'true';
        if (key.toLowerCase() == 'collegeinterest') {         
                                                            opportunity.collegeInterest__c = value;
            // All colleges other than Business have PreReqs
            if (value.toLowerCase() != 'business') {
                opportunity.NeedPreReqs__c = true;
            }
            else {
                opportunity.NeedPreReqs__c = false;
            }
        }
        if (key.toLowerCase() == 'majorinterest')           opportunity.MarketingProgram__c = value;
        if (key.toLowerCase() == 'toeflscore')              opportunity.toefl__c = value;
        if (key.toLowerCase() == 'username')                opportunity.WGUUsername__c = value;
        if (key.toLowerCase() == 'employmentstatus')        opportunity.EmploymentStatus__c = value;
        if (key.toLowerCase() == 'pin')                     opportunity.applicationPin__c = Decimal.valueOf(value);
        if (key.toLowerCase() == 'referid' && opportunity.Id == null) {
            opportunity.referid__c = value;
            
            List<MarketingSourceCode__c> sources = [SELECT id FROM MarketingSourceCode__c WHERE Name = :value];
            if (sources.size() > 0) {
                opportunity.MarketingSource__c = sources.get(0).Id;
            }
        }
        if (key.toLowerCase() == 'earnedbachelors')         opportunity.bachelorsdegree__c = Boolean.valueOf(value);
        if (key.toLowerCase() == 'priorcollege')            opportunity.attendedCollegeBeforeWGU__c = Boolean.valueOf(value);
        if (key.toLowerCase() == 'englishnativelanguage')   opportunity.nativeLanguageIsEnglish__c = Boolean.valueOf(value);
        
        // Student Attributes
        if (key.toLowerCase() == 'nickname')                attributes.nickname__c = value;
        if (key.toLowerCase() == 'campus')                  attributes.affiliation__c = value;
        //if (key.toLowerCase() == 'campus')                  attributes.EnrollmentDynamicEmails__c = value;
        if (key.toLowerCase() == 'ethnicbackground')        attributes.ethnicbackground__c = value;
        if (key.toLowerCase() == 'communitytype')           attributes.CommunityType__c = value;
        if (key.toLowerCase() == 'parentsattendcollege')    attributes.ParentsAttendedACollegeOrUniversity__c = value;
        if (key.toLowerCase() == 'citizenshipstatus')       attributes.CitizenshipStatus__c = value;
        if (key.toLowerCase() == 'militarystatus')          attributes.MilitaryStatus__c = value;
        if (key.toLowerCase() == 'maritalStatus')           attributes.MaritalStatus__c = value;
        if (key.toLowerCase() == 'parentsgraduated')        attributes.parentsGraduated__c = value;
        if (key.toLowerCase() == 'previousnames')           attributes.previousNames__c = value;
        
        // Application Complete
        if (key.toLowerCase() == 'applicationcomplete') {
            if (opportunity.OriginallyInquiry__c != null && opportunity.OriginallyInquiry__c)
                opportunity.CareStatus__c = 'APCO – Application Complete, Unpaid';
            else
                opportunity.CareStatus__c = 'PRAP – Prospect Applied Online';            
        }
        
        // Application Payment Complete
        if (key.toLowerCase() == 'paymenttype') {
            opportunity.paymentType__c = value;
            opportunity.CareStatus__c = 'APAC – Application Complete, Paid';
            opportunity.ApplicationComplete__c = true;
            opportunity.ApplicationFeePaid__c = true;
        }
        if (key.toLowerCase() == 'confirmationnumber')    opportunity.applicationFeeConfirmation__c = value;   
        if (key.toLowerCase() == 'affiliatecode')         opportunity.affiliateCode__c = value;   
        if (key.toLowerCase() == 'applicationfeeamount')  opportunity.applicationFeeAmount__c = Decimal.valueOf(value);
        if (key.toLowerCase() == 'discountamount')        opportunity.discountAmount__c = Decimal.valueOf(value);   
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
                if (ec != null)
                    opportunity.ownerid = ec;
            }
        }    
    }
    
    /**
     * Update Eloqua with record's most current information:
     * - EC Name
     * - Email
     * - Prospect's First Name
     * - Program Name
     * - Campus Name (full and short)
     * - Care Status
     */
    private static void updateEloqua(String OpportunityId) {
        Opportunity generatedValues = [SELECT Owner.Name, EmailCampusFull__c, EmailCampusShort__c, MarketingProgram__r.Name, careStatus__c, StudentContact__c, StudentContact__r.name, StudentContact__r.FirstName, StudentContact__r.email FROM Opportunity WHERE Id = :OpportunityId];
        if (!Test.isRunningTest()) {
            CAREforceUtility.sendBasicInfoToEloqua(generatedValues.StudentContact__r.email, generatedValues.StudentContact__r.FirstName, generatedValues.MarketingProgram__r.Name, generatedValues.EmailCampusFull__c, generatedValues.EmailCampusShort__c, generatedValues.Owner.Name, CAREforceUtility.trimCAREStatusValue(generatedValues.careStatus__c));
        }
    }   
}