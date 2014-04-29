public class EmailAddressToBannerUtilities {
    
    private static Boolean alreadyAssigning = false;
    private static Boolean alreadyUpdating = false;
    
    private static String convertActiveIndicator(String bannerCode) {
        return bannerCode == 'A' ? 'Active' : 'Inactive';
    }

    private static Boolean validateEmail(String emailAddress) {
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern MyPattern = Pattern.compile(emailRegex);
        
        // Then instantiate a new Matcher object "MyMatcher"
        Matcher MyMatcher = MyPattern.matcher(emailAddress);
        
        // Check for underscores after @ symbol.
        
        return MyMatcher.matches();  
    }
  
    // Needs to be run as before set the EmailAddress__c.id value that is either looked up or created. 
    // Records cannot be saved without this value.
    public static void matchIdOrCreateSync(String jsonNew) {
        if (alreadyAssigning)
            return;
        
        alreadyAssigning = true;
        
        List<EmailAddressToBanner__c> newValues = (List<EmailAddressToBanner__c>)JSON.deserialize(jsonNew, List<EmailAddressToBanner__c>.class);
        List<EmailAddressToBanner__c> records = new List<EmailAddressToBanner__c>();
        Map<String, EmailAddressToBanner__c> recordsToProcess = new Map<String, EmailAddressToBanner__c>();
        Set<String> emailsAddresses = new Set<String>();
        List<EmailAddressToBanner__c> badEmails = new List<EmailAddressToBanner__c>();
        Set<Integer> badEmailIndexes = new Set<Integer>();
        
        // Remove invalid Emails from the list to be run through.
        for (Integer i = 0; i < newValues.size(); i++) {
            EmailAddressToBanner__c record = newValues.get(i);
            // Check email address is valid for salesforce, if not no reason to bother looking for it.
            if (!validateEmail(record.EmailAddressIN__c)) {
                record.SynchronizationError__c = 'Email address format not valid for Salesforce.';
                badEmails.add(record);
                badEmailIndexes.add(i);
            } else {
                records.add(record);
            }
        }
        
        if (badEmails.size() > 0)
            update badEmails;
        
        // Create a list of records that need to have the EmailAddress__c.Id filled in. Already assigned values
        // can be ignored. Ignore invalid email addresses.
        for (EmailAddressToBanner__c record : records) {
            if (record.EmailAddress__c == null) {
                emailsAddresses.add(record.EmailAddressIN__c);
                recordsToProcess.put(record.PIDMIN__c + '-' + record.EmailAddressIN__c, record);                    
            }
        }
        
        List<EmailAddress__c> emails;
        String currentId;
        
        try {
            String statusIndicator;    
            EmailAddressToBanner__c current; 
            
            // Match up existing Email records to new sync records and update original record with changes from sync.
            emails = [SELECT Id, PIDM__c, Email__c, EmailCode__c, PrimaryEmail__c, StatusIndicator__c FROM EmailAddress__c WHERE Email__c = :emailsAddresses];
            
            for (EmailAddress__c email : emails) {
                currentId = email.Id;
                
                if (recordsToProcess.containsKey(email.PIDM__c + '-' + email.Email__c)) {
                    current = recordsToProcess.get(email.PIDM__c + '-' + email.Email__c);
                    
                    current.EmailAddress__c = email.Id;
                }
            }
        
            emails = new List<EmailAddress__c>();
            
            // Scan for records that are still not matched, create if doesn't exist then link.
            for (EmailAddressToBanner__c record : recordsToProcess.values()) {
                currentId = record.Id;
                
                if (record.EmailAddress__c == null) {
                    statusIndicator = convertActiveIndicator(record.StatusIndicatorIN__c);
                    emails.add(new EmailAddress__c(Contact__c = record.ContactIdIN__c, Email__c = record.EmailAddressIN__c, 
                                                   EmailCode__c = record.EmailCodeIN__c, PIDM__c = record.PIDMIN__c,
                                                   PrimaryEmail__c = record.PrimaryEmailIN__c, StatusIndicator__c = statusIndicator ));
                }
            }
        
        
            insert emails;
            
            // Link emails to sync records.
            for (EmailAddress__c email : emails) {
                currentId = email.Id;
                
                if (recordsToProcess.containsKey(email.PIDM__c + '-' + email.Email__c)) {
                    recordsToProcess.get(email.PIDM__c + '-' + email.Email__c).EmailAddress__c = email.Id;
                }
            }            
        } catch (Exception ex) {
            String message = ex.getMessage().substring(0, ex.getMessage().length() > 200 ? 200 : ex.getMessage().length());
            SynchronizeToBannerLogUtilities log = new SynchronizeToBannerLogUtilities();
            
            for (EmailAddressToBanner__c sync : recordsToProcess.values()) {
                sync.SynchronizationError__c = message + ' on record ' + currentId;
                log.add('EmailAddressToBanner__c', sync.Id, message + ' on record ' + currentId);
            }
            
            log.save();
        }
        
        update recordsToProcess.values();
    }
    
    @Future
    public static void processUpdate(String jsonNew) {
        processUpdateSync(jsonNew);
    }        
        
    public static void processUpdateSync(String jsonNew) {
        if (alreadyUpdating)
            return;
        
        alreadyUpdating = true;        
        
        List<EmailAddressToBanner__c> newValues = (List<EmailAddressToBanner__c>)JSON.deserialize(jsonNew, List<EmailAddressToBanner__c>.class);
        List<EmailAddressToBanner__c> records = new List<EmailAddressToBanner__c>();
        Set<Id> emailIds = new Set<Id>();
        Map<Id, EmailAddressToBanner__c> syncMap = new Map<Id, EmailAddressToBanner__c>();
        List<EmailAddressToBanner__c> badEmails = new List<EmailAddressToBanner__c>();
        Set<Integer> badEmailIndexes = new Set<Integer>();
        
        // Remove invalid Emails from the list to be run through.
        for (Integer i = 0; i < newValues.size(); i++) {
            EmailAddressToBanner__c record = newValues.get(i);
            // Check email address is valid for salesforce, if not no reason to bother looking for it.
            if (!validateEmail(record.EmailAddressIN__c)) {
                record.SynchronizationError__c = 'Email address format not valid for Salesforce.';
                badEmails.add(record);
                badEmailIndexes.add(i);
            } else {
                records.add(record);
            }
        }
        
        if (badEmails.size() > 0)
            update badEmails;
        
        for (EmailAddressToBanner__c newValue : records) {
            emailIds.add(newValue.EmailAddress__c);
            syncMap.put(newValue.EmailAddress__c, newValue);
        }
        
        String currentId;
        
        try {        
            List<EmailAddress__c> emails = [SELECT Id, PIDM__c, Email__c, EmailCode__c, PrimaryEmail__c, StatusIndicator__c FROM EmailAddress__c WHERE Id = :emailIds];
        
            EmailAddressToBanner__c current;
            String statusIndicator;
            
            for (EmailAddress__c email : emails) {
                currentId = email.Id;
                
                if (syncMap.containsKey(email.Id)) {
                    current = syncMap.get(email.Id);        
                    currentId = current.Id;
                    statusIndicator = convertActiveIndicator(current.StatusIndicatorIN__c);
                    
                    email.EmailCode__c = current.EmailCodeIN__c;
                    email.PrimaryEmail__c = current.PrimaryEmailIN__c;
                    email.StatusIndicator__c = statusIndicator;
                }
            }   
             
            update emails;
        } catch (Exception ex) {
            String message = ex.getMessage().substring(0, ex.getMessage().length() > 200 ? 200 : ex.getMessage().length());
            SynchronizeToBannerLogUtilities log = new SynchronizeToBannerLogUtilities();
            
            for (EmailAddressToBanner__c sync : newValues) {
                sync.SynchronizationError__c = message + ' on record ' + currentId;
                log.add('EmailAddressToBanner__c', sync.Id, message + ' on record ' + currentId);
            }
            
            update records;
            log.save();
        }        
    }
}