public class ContactToBannerUtilities {
    private static Boolean alreadySavingContacts = false;
    
    /**
     * Code to update contact to Banner Ready when the CAREProfile reaches the correct state of APAC.
     */
     
    public static void updateBannerReady(String oldJson, String newJson)
    {       
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled() )
        {
    
            processUpdateBannerReady(oldJson, newJson);
        }
        else
        { 
            try
            {
      
                asyncUpdateBannerReady(oldJson, newJson);
            }
            catch (Exception e)
            {
                processUpdateBannerReady(oldJson, newJson);
            }
        }
    }
    
    @future
    public static void asyncUpdateBannerReady(String oldJson, String newJson)
    {
        processUpdateBannerReady(oldJson, newJson);
    }    
         
    public static void processUpdateBannerReady(String oldJson, String newJson) {
        List<Opportunity> oldValues = (List<Opportunity>)JSON.deserialize(oldJson, List<Opportunity>.class);
        List<Opportunity> newValues = (List<Opportunity>)JSON.deserialize(newJson, List<Opportunity>.class);
        List<Contact> contactsToUpdate = new List<Contact>();
        
        Opportunity opportunity = null;
        Opportunity oldOpportunity = null;
        for (Integer i = 0; i < newValues.size(); i++) {
            opportunity = newValues[i];           
            oldOpportunity = oldValues[i];
            
            if (opportunity.CAREStatus__c != null) {
                if (opportunity.CAREStatus__c.startsWith('APAC') && !oldOpportunity.CAREStatus__c.startsWith('APAC')) {
                    contactsToUpdate.add(new Contact(Id=opportunity.StudentContact__c, BannerReady__c = true));
                }
            }
        }
        
        // Only perform update if any records to update.
        if (contactsToUpdate.size() > 0) {
            update contactsToUpdate;
        }
        
    }
    
    @Future
    public static void updateContacts(String oldJson, String newJson) {
        updateContactsSync(oldJson, newJson);
    } 
    
    /**
     * The Last login date will change often where as the stduent record will not. This function provides a mean to only update
     * the one field that cannot be changed in Salesforce removing the need to check for changes before updating. It is common
     * that only this field will be updated while nothing else is as it will occur each time a student logs into the student portal.
     */
    public static void updateLastLogin(List<ContactToBanner__c> values) {
        List<Contact> contacts = new List<Contact>();
        
        for (ContactToBanner__c value : values) {
            contacts.add(new Contact(Id = value.Contact__c, LastPortalLogin__c = value.LastLoginIN__c));
        }
        
        update contacts;
    }
    
    public static void updateContactsSync(String oldJson, String newJson) {    
        // Prevent this function from triggering itself again.
        if (alreadySavingContacts)
            return;
        
        alreadySavingContacts = true;
        List<ContactToBanner__c> oldValues = (List<ContactToBanner__c>)JSON.deserialize(oldJson, List<ContactToBanner__c>.class);
        List<ContactToBanner__c> newValues = (List<ContactToBanner__c>)JSON.deserialize(newJson, List<ContactToBanner__c>.class);                   
        
        /*Runtime__c*/ String environment = StudentUser.getEnvironment(); //Runtime__c.getValues('environment');
        String sandboxEmailAppend = environment/*.Value__c*/ != 'prod' ? '.' + environment/*.Value__c*/ : '';
        
        Id prospectRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'ContactToBanner__c' AND Name = 'Prospect'].Id;
        Id studentRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'ContactToBanner__c' AND Name = 'Student'].Id;
        Id returningRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'ContactToBanner__c' AND Name = 'Returning'].Id;
        Id contactProspectId = [SELECT Id FROm RecordType WHERE sObjectType = 'Contact' AND Name = 'ProspectRecord'].Id;
        Id contactStudentId = [SELECT Id FROm RecordType WHERE sObjectType = 'Contact' AND Name = 'StudentRecord'].Id;
        
        // Pull the list of campus codes and picklist values from custom settings.
        Map<String, Campus__c> campuses = Campus__c.getAll();
        
        Set<Id> contactIds = new Set<Id>();
        
        for (ContactToBanner__c newValue : newValues) {
            if (newValue.Contact__c != null)
                contactIds.add(newValue.Contact__c);
        }
        
        // Set check for last modified and current Banner status.
        List<Contact> contacts = [SELECT Id, LastModifiedDate FROM Contact WHERE Id = :contactIds];
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        
        for (Contact contact : contacts) {
            contactMap.put(contact.Id, contact);
        }
        
        List<Contact> contactsToModify = new List<Contact>();
        List<ContactToBanner__c> onlyLoginDatesChanged = new List<ContactToBanner__c>();
        
        ContactToBanner__c currentNew;
        ContactToBanner__c currentOld;
        Contact currentContact;
        Boolean forceDataPush;
        String wguEmail;
        Date lastAAVDate;
        SynchronizeToBannerLogUtilities log = new SynchronizeToBannerLogUtilities();
        
        // create new list, SRMBANR-158
        List<ContactToBanner__c> updateContactToBannerList = new List<ContactToBanner__c>();
        
        for (Integer i = 0; i < newValues.size(); i++) {
            forceDataPush = false;
            currentNew = newValues.get(i);
            if (oldValues != null)
                currentOld = oldValues.get(i);
            else
                currentOld = null;
            
            if(currentNew.currentStatus__c == 'Insert' && currentNew.PIDMFromBannerIN__c != null){
                updateContactToBannerList.add(currentNew);
            }    
            
            // If no last synchronized date exists then this record is not ready to merge into Contact.
            if (currentNew.LastSynchronizedFromBanner__c == null)
                continue;
          
            // Comparison checks with old version of record. Do not run if this is first record save.
            if (currentOld != null) {
                // Check if full update occurred or if this is only an update to the last login date.
                if ((currentOld.LastSynchronizedFromBanner__c == currentNew.LastSynchronizedFromBanner__c) 
                     && (currentNew.LastLoginIN__c != null && (currentOld.LastLoginIN__c != currentNew.LastLoginIN__c))) {
                    // move to list that will only process changed login date.     
                    onlyLoginDatesChanged.add(currentNew);
                    // Do not process any further as that only the Last Login Date changed.
                    continue;
                }
            }
            
            // Check if error is already in progress to be resolved. Should not re-push until request re-push is made.
            // Resubmission from Banner counts as re-push request. Power Center will clear the synchornization error field.
            if (currentNew.SynchronizationError__c != null && currentNew.SynchronizationError__c != 'None') {
                if (!currentNew.ResynchronizeToSalesforce__c)
                    continue;
                else {
                    currentNew.ResynchronizeToSalesforce__c = false;
                    currentNew.SynchronizationError__c = null;
                    forceDataPush = true;
                }
            } 
            
            if (currentNew.Contact__c != null) {
                currentContact = contactMap.get(currentNew.Contact__c);
                
                try {
                    if (currentNew.MyWGUEmailIN__c != null) {
                        if (currentNew.MyWGUEmailIN__c.indexOf('my.wgu.edu') > 0)
                            wguEmail = currentNew.MyWGUEmailIN__c.substring(0, currentNew.MyWGUEmailIN__c.indexOf('my.wgu.edu')) + 'wgu.edu' + sandboxEmailAppend;
                        else 
                            wguEmail = currentNew.MyWGUEmailIN__c;
                    } else 
                        wguEmail = null;
                    
                    if (currentNew.LastAAVDateIN__c != null) {
                        lastAAVDate = Date.newInstance(currentNew.LastAAVDateIN__c.year(), currentNew.LastAAVDateIN__c.month(),currentNew.LastAAVDateIN__c.day());
                    } else {
                        lastAAVDate = null;
                    }
                    
                    String contactMentorPidm = null;
                    if (currentNew.MentorPIDMIN__c != null) {
                        contactMentorPidm = String.valueOf(Integer.valueOf(currentNew.MentorPIDMIN__c));
                    }
                        
                    Contact updatedContact = new Contact(
                        Id = currentNew.Contact__c, FirstName = currentNew.FirstNameIN__c, LastName = currentNew.LastNameIN__c,
                        AcademicStanding__c = currentNew.CurrentStandingIN__c, BalanceDue__c = currentNew.BalanceDueIN__c == 'Yes' ? true : false,
                        College__c = currentNew.CollegeIN__c, CurrentTerm__c = currentNew.CurrentTermIN__c, 
                        CurrentTermEnrolledCUs__c = currentNew.CurrentTermEnrolledCUsIN__c, Deceased__c = currentNew.DeceasedIndicatorIN__c,
                        FAADate__c = currentNew.FirstAcademicActivityDateIN__c, FERPAIndicator__c = currentNew.ConfidentialIndicatorIN__c,
                        FinancialAidCheck__c = currentNew.FinancialAidCheckIN__c == 'YES' ? true : false, 
                        FinancialAidStatus__c = currentNew.FinancialAidStatusIN__c, Gender__c = currentNew.GenderIN__c,
                        GradeLevel__c = currentNew.GradeLevelIN__c, HouseholdIncome__c = currentNew.AdjustedGrossIncomeIN__c,
                        LastPortalLogin__c = currentNew.LastLoginIN__c, 
                        LastDateOfAAV__c = lastAAVDate, 
                        MailingCity = currentNew.CityIN__c, MailingPostalCode = currentNew.ZipCodeIN__c, 
                        MailingState = currentNew.StateIN__c, MailingStreet = currentNew.StreetAddressIN__c,
                        MentorPidm__c = contactMentorPidm, MilitaryStatus__c = currentNew.MilitaryStatusIN__c,
                        MobilePhone = currentNew.MobileNumberIN__c, 
                        My_WGU_Email__c = currentNew.MyWGUEmailIN__c == null ? null : currentNew.MyWGUEmailIN__c + sandboxEmailAppend, 
                        Phone = currentNew.HomePhoneIN__c,
                        PlannedGraduationDate__c = currentNew.PlannedGraduationDateIN__c, ProgramCatalogTerm__c = currentNew.ProgramTermIN__c,
                        ProgramCode__c = currentNew.ProgramIN__c, ProgramName__c = currentNew.ProgramNameIN__c, Status__c = currentNew.StatusIN__c,
                        StudentPlannedGraduationDate__c = currentNew.ProjectedDateOfGraduationIN__c, StudentPreferredName__c = currentNew.PreferredFirstNameIN__c,
                        TermBreakCode__c = currentNew.TermBreakCodeIN__c, TermBreakEndDate__c = currentNew.TermBreakEndDateIN__c,
                        TermBreakStartDate__c = currentNew.TermBreakStartDateIN__c, TermEndDate__c = currentNew.TermEndDateIN__c,
                        TermNumber__c = currentNew.TermNumberIN__c, TermStartDate__c = currentNew.TermStartDateIN__c, Timezone__c = currentNew.TimeZoneIN__c,
                        CurrentTermCompletedCUs__c = currentNew.CurrentTermCompletedCUsIN__c,
                        TotalAttemptedCUs__c = (currentNew.HistoricallyAttemptedCUsIN__c != null ? currentNew.HistoricallyAttemptedCUsIN__c : 0)
                                             + (currentNew.CurrentTermEnrolledCUsIN__c != null ? currentNew.CurrentTermEnrolledCUsIN__c : 0), 
                        TotalCompletedCUs__c = (currentNew.HistoricallyCompletedCUsIN__c != null ? currentNew.HistoricallyCompletedCUsIN__c : 0)
                                             + (currentNew.CurrentTermCompletedCUsIN__c != null ? currentNew.CurrentTermCompletedCUsIN__c : 0),
                        HistoricallyAttemptedCUs__c = currentNew.HistoricallyAttemptedCUsIN__c,
                        HistoricallyCompletedCUs__c = currentNew.HistoricallyCompletedCUsIN__c,
                        TransferCreditsTotal__c = currentNew.TransferredCUsIN__c, 
                        WGUEmail__c = wguEmail, OtherEmail__c = currentNew.OtherEmailIN__c,
                        Username__c = currentNew.IDMUsernameIN__c,
                        RequestRefreshFromBanner__c = false
                    );  
                    
                    // Translate campus code if valid.
                    if (currentNew.CampusCodeIN__c != null) {
                        if (campuses.get(currentNew.CampusCodeIN__c) != null) {
                            updatedContact.CampusCode__c = campuses.get(currentNew.CampusCodeIN__c).Contact__c;
                        }
                    }
                    
                    // Check if currently a prospect. Fields that must be different based upon Prospect or Student.
                    if (currentNew.StatusIN__c == 'IN') {
                        updatedContact.Email = currentNew.OtherEmailIN__c == null ? null : currentNew.OtherEmailIN__c + sandboxEmailAppend;
                        currentNew.RecordTypeId = prospectRecordTypeId;
                        updatedContact.RecordTypeId = contactProspectId;
                    } else {
                        updatedContact.Email = currentNew.MyWGUEmailIN__c == null ? null : currentNew.MyWGUEmailIN__c + sandboxEmailAppend;
                        updatedContact.RecordTypeId = contactStudentId;
                        
                        if (currentNew.StatusIN__c == 'AS' || currentNew.StatusIN__c == 'TB' || currentNew.StatusIN__c == 'NS')
                            currentNew.RecordTypeId = studentRecordTypeId;
                        else
                            currentNew.RecordTypeId = returningRecordTypeId;
                    }
                    
                    contactsToModify.add(updatedContact);
                } catch(Exception ex) {
                    currentNew.SynchronizationError__c = ex.getMessage().length()>255 ? ex.getMessage().substring(0,254) : ex.getMessage();  
                    log.add('ContactToBanner__c', currentNew.Id, currentNew.SynchronizationError__c);
                }
            }
        }
        
        updateContactBannerData(updateContactToBannerList);
        
        try{
            if (onlyLoginDatesChanged.size() > 0) {
                // Call function to only update the login dates and no other values.;
                updateLastLogin(onlyLoginDatesChanged);
            }
        } catch(Exception ex) {
            for (ContactToBanner__c c2b : onlyLoginDatesChanged) {
                c2b.SynchronizationError__c = ex.getMessage().length()>255 ? ex.getMessage().substring(0,254) : ex.getMessage();
                log.add('ContactToBanner__c', c2b.Id, c2b.SynchronizationError__c);
            }
        }
        
        try {
            if (contactsToModify.size() > 0)
                update contactsToModify;
        } catch(Exception ex) {
            for (ContactToBanner__c c2b : newValues) {
                for (Contact contact : contactsToModify) {
                    if (contact.Id == c2b.Contact__c) {
                        c2b.SynchronizationError__c = ex.getMessage().length()>255 ? ex.getMessage().substring(0,254) : ex.getMessage();
                        log.add('ContactToBanner__c', c2b.Id, c2b.SynchronizationError__c);
                    }
                }
            }
        }
        
        try {
            update newValues;
        } catch(Exception ex) {
            for (ContactToBanner__c c2b : newValues) {              
                log.add('ContactToBanner__c', c2b.Id, ex.getMessage().length()>255 ? ex.getMessage().substring(0,254) : ex.getMessage());
            }
            
            System.Debug('Critical error updating error log: ' + (ex.getMessage().length()>255 ? ex.getMessage().substring(0,254) : ex.getMessage()));
        }
        
        log.save();
        
        alreadySavingContacts = false;
    }
    
    public static void updateContactBannerData(List<ContactToBanner__c> contactToBannerList )
    {
        List<Contact> contactList = new List<Contact>();
        for(ContactToBanner__c thisContactToBanner : contactToBannerList){
            contactList.add( new Contact(id = thisContactToBanner.Contact__c,
                                        StudentID__c = thisContactToBanner.BannerIDFromBannerIN__c,
                                        Username__c = thisContactToBanner.UsernameFromBannerIN__c,
                                        WGUEmail__c = thisContactToBanner.WGUEmailFromBannerIN__c,
                                        PIDM__c = thisContactToBanner.PIDMFromBannerIN__c) );
        }
        update contactList;

    }
    
//////////////////////// Begin Notification to OpportunityToBanner and StudentAttributesToBanner for a new PIDM ////////////////////    
    
    public static void notifyRelatedObjects(String newJson)
    {       
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled() )
        {
            processNotifyRelatedObjects(newJson);
        }
        else
        { 
            try
            {
                asyncNotifyRelatedObjects(newJson);
            }
            catch (Exception e)
            {
                processNotifyRelatedObjects(newJson);
            }
        }
    }
    
    @future
    public static void asyncNotifyRelatedObjects(String newJson)
    {
        processNotifyRelatedObjects(newJson);
    }    
         
    public static void processNotifyRelatedObjects(String newJson) 
    {
        List<ContactToBanner__c> ctbList = (List<ContactToBanner__c>)JSON.deserialize(newJson, List<ContactToBanner__c>.class);
        List<Id> contactIdList = new List<Id>();
        
        for (ContactToBanner__c ctb : ctbList)
        {
            contactIdList.add(ctb.Contact__c);
        }
        
        List<OpportunityToBanner__c> otbList = [SELECT Id, CurrentStatus__c
                                                FROM OpportunityToBanner__c
                                                WHERE Opportunity__r.StudentContact__c IN :contactIdList];
                                                
        List<StudentAttributesToBanner__c> satbList = [SELECT Id, CurrentStatus__c
                                                       FROM StudentAttributesToBanner__c
                                                       WHERE StudentAttributes__r.StudentContact__c IN :contactIdList];                                                         
    }  
    
///////////////////////// End Notification to OpportunityToBanner and StudentAttributesToBanner for a new PIDM /////////////////////

//////////////////////// Begin Refresh Data from Banner ////////////////////    
    
    public static void resyncToSalesforce(String newJson)
    {       
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled() )
        {
            processResyncToSalesforce(newJson);
        }
        else
        { 
            try
            {
                asyncResyncToSalesforce(newJson);
            }
            catch (Exception e)
            {
                processResyncToSalesforce(newJson);
            }
        }
    }
    
    @future
    public static void asyncResyncToSalesforce(String newJson)
    {
        processResyncToSalesforce(newJson);
    }    
         
    public static void processResyncToSalesforce(String newJson) 
    {
        List<Contact> contactList = (List<Contact>)JSON.deserialize(newJson, List<Contact>.class);    
        List<String> pidmList = new List<String>();
        
        for (Contact thisContact : contactList)
        {
            System.debug('======> pidm ' + thisContact.Pidm__c);
            pidmList.add(thisContact.Pidm__c);
        }
        
        List<ContactToBanner__c> resyncList = [SELECT Id, ResynchronizeToSalesforce__c
                                               FROM ContactToBanner__c
                                               WHERE PidmOUT__c IN :pidmList];
                                               
        for (ContactToBanner__c thisResync : resyncList)
        {
            thisResync.ResynchronizeToSalesforce__c = true;
        }
        
        update resyncList;
    }  
    
///////////////////////// End Refresh Data from Banner /////////////////////
    
    public static void updateOpportunityPidm(String newJson){
         if(Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled()){
             processUpdateOppPidm(newJson);
         }else{
             asyncUpdateOppPidm(newJson);
         }
    }
    @future
    private static void asyncUpdateOppPidm(String newJson){
        processUpdateOppPidm(newJson);
    }
    private static void processUpdateOppPidm(String newJson){
        List<ContactToBanner__c> ctbList = (List<ContactToBanner__c>)JSON.deserialize(newJson, List<ContactToBanner__c>.class);
        List<String> pidmList = new List<String>();
        for(ContactToBanner__c ctb : ctbList){
            if(ctb.PIDMOUT__c != null && !''.equals(ctb.PIDMOUT__c)){
                pidmList.add(ctb.PIDMOUT__c);
            }else if(ctb.PIDMFromBannerIN__c != null && !''.equals(ctb.PIDMFromBannerIN__c)){
                pidmList.add(ctb.PIDMFromBannerIN__c);
            }
        }
        List<Opportunity> opList = [SELECT Id, Pidm__c, StudentContact__r.PIDM__c, CAREStatus__c
                                    FROM Opportunity
                                    WHERE Pidm__c = null AND StudentContact__r.PIDM__c IN :pidmList];
        for(Opportunity op : opList){
            if(op.CAREStatus__c.startsWith('APAC')){
                op.Pidm__c = op.StudentContact__r.PIDM__c;
            }
        }
        update opList;
    }
    
}