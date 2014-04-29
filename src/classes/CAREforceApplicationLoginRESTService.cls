// Accesible from ~/services/apexrest/applicationlogin
@RestResource(urlMapping='/applicationlogin')
global class CAREforceApplicationLoginRESTService {

    private static Boolean getValidForReset(String lastName, String postalCode, String email) {
        DateTime timestamp = DateTime.now();
        timestamp = timestamp.addMonths(-18); 
        
        // Match the login query since it will be used to reset pin
        List<Opportunity> opportunities = [SELECT id, CareStatus__c FROM Opportunity 
                                          WHERE StudentContact__r.otherEmail__c = :email
                                              AND StudentContact__r.MailingPostalCode = :postalCode 
                                              AND StudentContact__r.LastName = :lastName
                                              AND createdDate > :timestamp 
                                              AND isDeleted = false
                                              AND (CareStatusListView__c != 'PROS') 
                                              AND Account.isDeleted = false];
        
        // If we have records, make sure the first has a valid status
        // We reset the first record that meets requirements
        if (opportunities.size() > 0) {
            return CAREforceApplicationRESTService.validApplicationStatus(opportunities.get(0).CareStatus__c);
        }
        
        return false;
    }

    /* lastName, zipCode, email engage the pin reset process. If no pin is submitted then a status of 'Valid For PIN Reset' is returned,
     * the values must be resubmitted with the pin to actually change the pin and sign the user in.
     */
    @HttpPost
    global static Response login(String email, String pin, String lastName, String zipCode) {
        boolean resetPin = false;
    
        // Check if pin reset needs to take place, if not then perform regular sign in process.
        if (email != null && lastName != null && zipCode != null) {
            Boolean validForReset = getValidForReset(lastName, zipCode, email);
            
            if (validForReset) {
                if (pin == null) {
                    Response response = new Response(); 
                    response.status = 'Valid For PIN Reset';
                    
                    return response;                    
                } else {
                    resetPin = true;
                }
            } else {
                Response response = new Response(); 
                response.status = 'Not Valid For PIN Reset';
                
                return response;
            }
        }
        
        Response response = new Response();    
        DateTime timestamp = DateTime.now();
        timestamp = timestamp.addMonths(-18);              
        
        Opportunity matchedOpportunity = null;
        
        List<Opportunity> existingOpps = [SELECT id, StudentContact__r.firstName, StudentContact__r.lastName, StudentContact__r.otherEmail__c, 
                                             StudentContact__r.MailingStreet, StudentContact__r.MailingState,
                                             StudentContact__r.MailingPostalCode, StudentContact__r.MailingCountry, StudentContact__r.Phone, 
                                             StudentContact__r.MobilePhone, StudentContact__r.acceptsTexting__c, StudentContact__r.socialSecurityNumber__c,
                                             StudentContact__r.ITINIndividualTaxIdentificationNumber__c, StudentContact__r.gender__c, 
                                             StudentContact__r.dateOfBirth__c, StudentContact__r.middleInitial__c,
                                             StudentContact__r.suffix__c, StudentContact__r.phoneExtension__c, 
                                             StudentContact__r.internationalPhone__c, StudentContact__r.Salutation, StudentContact__r.MailingCity,
                                             applicationPin__c, learnAboutFinancialAid__c, graduatedHighSchool__c, collegeInterest__c,
                                             toefl__c, WGUUsername__c, EmploymentStatus__c, bachelorsdegree__c,
                                             attendedCollegeBeforeWGU__c, nativeLanguageIsEnglish__c, paymentType__c, MarketingProgram__c,
                                             Account.Id, StudentContact__c, CareStatus__c, AffiliateCode__c, DiscountAmount__c, ApplicationFeeAmount__c
                                             FROM Opportunity WHERE StudentContact__r.otherEmail__c = :email
                                                                      AND createdDate > :timestamp 
                                                                      AND isDeleted = false
                                                                      AND (CareStatusListView__c != 'PROS') 
                                                                      AND Account.isDeleted = false
                                                                       ORDER BY createdDate DESC
                                                                             ];
                                                                             
        // Reset pin on newest opportunity if in reset in progress.
        if (resetPin) {
            existingOpps.get(0).applicationPin__c = Decimal.valueOf(pin);
            update existingOpps.get(0);
        }
        
        for (Opportunity opp : existingOpps) {
            if (existingOpps.get(0).applicationPin__c == Decimal.valueOf(pin)) { 
                matchedOpportunity = opp;
                break;
            }
        }
         
        if (matchedOpportunity != null) {            
            // Once application payment has been acknowledged the user should not be allowed to login again.
            
            if ((matchedOpportunity.paymentType__c != null) || 
                    !(
                        (matchedOpportunity.CareStatus__c.startswith('PRAP')) ||
                        (matchedOpportunity.CareStatus__c.startswith('APNN')) ||
                        (matchedOpportunity.CareStatus__c.startswith('APIN')) ||
                        (matchedOpportunity.CareStatus__c.startswith('APCO'))
                     ) 
                )  {
                response.status = 'Application Complete';
                response.reason = 'This application has already been completed.';
                return response;       
            }     
        
            List<StudentAttributes__c> attributes = [SELECT id, nickname__c, affiliation__c, ethnicbackground__c, CommunityType__c,
                                                            ParentsAttendedACollegeOrUniversity__c, MilitaryStatus__c, MaritalStatus__c, 
                                                            CitizenshipStatus__c, parentsGraduated__c, previousNames__c
                                                            FROM StudentAttributes__c WHERE StudentAccount__c = :matchedOpportunity.Account.id ORDER BY createdDate DESC];               
            
            response.loadOpportunity(matchedOpportunity);
            
            if (attributes.size() > 0) {
                response.loadAttributes(attributes.get(0));
                
                List<StudentEmploymentHistory__c> histories = [SELECT id, Employer__c, annualIncome__c, otherEmployer__c
                                                                      FROM StudentEmploymentHistory__c WHERE StudentAttributes__c = :attributes.get(0).id];
                                                                      
                if (histories != null)
                    response.loadEmployments(histories);
            }
                
            List<StudentTranscript__c> transcripts = [SELECT id, institutionName__c, transcriptInstitution__c, transcriptInstitution__r.billingCity,
                                                             transcriptInstitution__r.billingState, transcriptInstitution__r.billingPostalCode,
                                                             transcriptInstitution__r.name,
                                                             institutionCity__c, institutionState__c,
                                                             institutionZip__c, degreeType__c, major__c, minor__c, dateDegreeReceived__c, 
                                                             collegeStartDate__c, collegeEndDate__c
                                                             FROM StudentTranscript__c WHERE StudentAccount__c = :matchedOpportunity.Account.id ORDER BY createdDate];
            if (transcripts != null) 
                response.loadTranscripts(transcripts);


            return response;
        }                 
    
        response.status = 'Invalid Credentials';
        response.reason = 'Pin Did Not Match With Active Opportunity';
        return response;
    }
    
    global class Response {
        public String status = 'success';
        public String reason = '';
        public String id;
        public Map<String, String> fields = new Map<String, String>();
        public List<Map<String, String>> transcripts = new List<Map<String, String>>();
        public List<Map<String, String>> employments = new List<Map<String, String>>();
        
        public void loadEmployments(List<StudentEmploymentHistory__c> histories) {
            for (StudentEmploymentHistory__c record : histories) {
                Map<String, String> current = new Map<String, String>();
                current.put('employerInformation', record.Employer__c);
                current.put('annualIncome', record.annualIncome__c);
                current.put('employerOther', record.otherEmployer__c);

                this.employments.add(current);
            }
        }         
        
        public void loadTranscripts(List<StudentTranscript__c> transcripts) {
            for (StudentTranscript__c record : transcripts) {
                Map<String, String> current = new Map<String, String>();
                if (record.transcriptInstitution__c != null) {
                    current.put('transcriptInstitution', record.transcriptInstitution__c);
                    current.put('institutionName', record.transcriptInstitution__r.name);
                    current.put('city', record.transcriptInstitution__r.billingCity);
                    current.put('state', record.transcriptInstitution__r.billingState);
                    current.put('zip', record.transcriptInstitution__r.billingPostalCode);
                } else {
                    current.put('institutionName', record.institutionName__c);
                    current.put('city', record.institutionCity__c);
                    current.put('state', record.institutionState__c);
                    current.put('zip', record.institutionZip__c);
                }
                current.put('transcriptId', record.id);
                current.put('degree', record.degreeType__c);
                current.put('major', record.major__c);
                current.put('minor', record.minor__c);
                current.put('dateGraduated', String.valueOf(record.dateDegreeReceived__c));
                current.put('attendanceStart', String.valueOf(record.collegeStartDate__c));
                current.put('attendanceEnd', String.valueOf(record.collegeEndDate__c));

                this.transcripts.add(current);
            }
        }
        
        public void loadOpportunity(Opportunity opportunity) {
            id = opportunity.StudentContact__c;
            
            // Name
            fields.put('prefix', opportunity.StudentContact__r.salutation);
            fields.put('firstName', opportunity.StudentContact__r.firstName);
            fields.put('middleInitial', opportunity.StudentContact__r.middleInitial__c);
            fields.put('lastName', opportunity.StudentContact__r.lastName);
            fields.put('suffix', opportunity.StudentContact__r.suffix__c);   
            
            // Email
            fields.put('email', opportunity.StudentContact__r.otherEmail__c);
            
            // Address
            fields.put('street', opportunity.StudentContact__r.MailingStreet);
            fields.put('city', opportunity.StudentContact__r.MailingCity);
            fields.put('state', opportunity.StudentContact__r.MailingState);
            fields.put('zip', opportunity.StudentContact__r.MailingPostalCode);
            fields.put('country', opportunity.StudentContact__r.MailingCountry);
            
            // Phone
            fields.put('phone', opportunity.StudentContact__r.Phone);
            fields.put('ext', opportunity.StudentContact__r.phoneExtension__c);
            fields.put('mobile', opportunity.StudentContact__r.MobilePhone);
            fields.put('acceptsTexting', String.valueOf(opportunity.StudentContact__r.acceptsTexting__c));
            fields.put('internationalPhone', opportunity.StudentContact__r.internationalPhone__c); 
            
            // Contact (other)
            fields.put('ssn', opportunity.StudentContact__r.socialSecurityNumber__c);
            fields.put('itn', opportunity.StudentContact__r.ITINIndividualTaxIdentificationNumber__c);
            fields.put('gender', opportunity.StudentContact__r.gender__c);
            fields.put('dob', opportunity.StudentContact__r.dateOfBirth__c);
            
            // Opportunity
            fields.put('learnMoreFinancialAid', String.valueOf(opportunity.learnAboutFinancialAid__c));
            fields.put('graduateHighSchool', String.valueOf(opportunity.graduatedHighSchool__c));
            fields.put('collegeInterest', opportunity.collegeInterest__c);
            fields.put('majorInterest', opportunity.MarketingProgram__c);
            fields.put('toeflScore', opportunity.toefl__c);
            fields.put('username', opportunity.WGUUsername__c);
            fields.put('employmentStatus', opportunity.EmploymentStatus__c);
            fields.put('earnedBachelors', String.valueOf(opportunity.bachelorsdegree__c));
            fields.put('priorCollege', String.valueOf(opportunity.attendedCollegeBeforeWGU__c));
            fields.put('englishNativeLanguage', String.valueOf(opportunity.nativeLanguageIsEnglish__c));
            
            // Application Payment
            fields.put('affiliateCode', opportunity.AffiliateCode__c);
            fields.put('applicationFeeAmount', String.valueOf(opportunity.ApplicationFeeAmount__c)); 
            fields.put('discountAmount', String.valueOf(opportunity.DiscountAmount__c));
        }

        public void loadAttributes(StudentAttributes__c attributes) {
            fields.put('nickname', attributes.nickname__c);
            fields.put('campus', attributes.affiliation__c);
            fields.put('ethnicBackground', attributes.ethnicbackground__c);
            fields.put('communityType', attributes.CommunityType__c);
            fields.put('parentsAttendCollege', attributes.ParentsAttendedACollegeOrUniversity__c);
            fields.put('citizenshipStatus', attributes.CitizenshipStatus__c);
            fields.put('militaryStatus', attributes.MilitaryStatus__c);
            fields.put('maritalStatus', attributes.MaritalStatus__c);
            fields.put('parentsGraduated', attributes.parentsGraduated__c);
            fields.put('previousNames', attributes.previousNames__c);
        }
    }
}