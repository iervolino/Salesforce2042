/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Date Feb 15 2013 @ 1348 hrs
 * Revised: Person Account Refactor, modified syncOpportunityTaskToCallDisposition to follow future trigger pattern - Paul Coleman 
 * 
 * Refactored Oct 4 2013 by Tyler Smith
 * Complete Refactor Oct 15 2013 by Tyler Smith
 */
public class CAREforceUtility {

    public static Boolean updatePushToBannerInProgress = false;
    public static Boolean updateCreateSyncToBannerInProgress = false;
    private static String kHexChars = '0123456789abcdefABCDEF';
    
    
    //--------------------------------------
    // Random Pieces
    //--------------------------------------
    
    /**
     * Generate UUID
     *
     * ?!?!?!?
     * I don't know what this is used for or if it should be part of this class
     */
    public static String randomUUID(){
        String returnValue = '';
        Integer nextByte = 0;
        for(Integer i = 0; i < 16; i++){
            if (i==4 || i==6 || i==8 || i==10) {
                returnValue += '-';
            }
            //generate a "byte"; i.e., number in range [-2^7,2^7-1]
            nextByte = (Math.round(Math.random() * 255)-128) & 255;

            if (i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }
            if (i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }
            
            returnValue += charAt(kHexChars,nextByte >> 4);
            returnValue += charAt(kHexChars,nextByte & 15);
        }
        return returnValue;
    }
    
    /**
     * Helper function for randomUUID
     */
    private static String charAt(String str, Integer index) {
        return str.substring(index, index+1);
    }
    
    /**
     * Get Short CARE status from Long Version
     */
    public static String trimCAREStatusValue(String status) {
        if (status == null)
            return '';
        return status.substring(0, status.indexOf(' '));
    }
    
    /**
     * Checks configuration to detect if Person Accounts are in use.
     *
     * ?!?!?!?
     * Is this still used by anything? Does it matter any more?
     */
    public static Boolean usePersonAccounts() {
        RunTime__c usePersonAccounts = Runtime__c.getInstance('UsePersonAccounts');
        
        if (usePersonAccounts == null) {
            return true;
        }
        else { 
            return Boolean.valueOf(usePersonAccounts.Value__c);
        }
    }
    
    /**
     * General function to post data to vendors
     * We use this a lot, do others need similar functionality?
     * Should this be in a more general place?
     */
    @Future(callout=true)
    public static void postDataToURL(String endPoint, String body) {
        // Setup HTTP Request
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setMethod('POST');
        req.setBody (body);
        
        // Just another precaution to ensure we don't send on tests
        if (Test.isRunningTest()) {
            req.setEndpoint('https://goingnowhere.fake');
        }
        else {
            // If endpoint is not set, don't continue
            if (endPoint == null) {
                return;
            }
            
            req.setEndpoint(endPoint);
        }
        
        // Setup HTTP to send request (if not running a test)
        // ?!?!?!?
        // Why set two different precautions for the test sending?
        if (!Test.isRunningTest()) {
            Http http = new Http();
            HTTPResponse res = http.send(req);
        }
    }
 
    //--------------------------------------
    // Call Disposition
    //--------------------------------------
 
    /**
     * MODIFIED Feb 15, 2012 1444 hrs by Paul Coleman
     * MODIFIED Oct 15, 2013 1324 hrs by Tyler Smith
     * Called by Trigger AFTER INSERT on TASK, 
     * Copy the call disposition of the Task to the corresponding Opportunity
     * If safe, call future method, otherwise do it now.
     */
    public static void syncOpportunityTaskToCallDisposition(String taskListNewJSON) {
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled()) {
            processSyncOpportunityTaskToCallDisposition( taskListNewJSON );
        } 
        else {
            futureSyncOpportunityTaskToCallDisposition( taskListNewJSON );
        }
    }
   
    /**
     * Future version of syncOpportunityTaskToCallDisposition
     */
    @future
    private static void futureSyncOpportunityTaskToCallDisposition(String taskListNewJSON) {
        processSyncOpportunityTaskToCallDisposition(taskListNewJSON);
    }
 
    /**
     * Now version of syncOpportunityTaskToCallDisposition
     */
    private static void processSyncOpportunityTaskToCallDisposition(String taskListNewJSON) {
        // Move information passed from trigger into objects (instead of JSON string)
        List<Task> TriggerNew = (List<Task>)JSON.deserialize(taskListNewJSON, List<Task>.class);

        // Get record type if for CAREforceTasks
        Id careTaskId = [SELECT id 
                         FROM RecordType 
                         WHERE developerName = 'CAREforceTask' 
                         AND sObjectType = 'Task'].id;
        
        // Get Opportunity Prefix
        String careKeyPrefix = Schema.SObjectType.Opportunity.getKeyPrefix(); 
        
        // Get all passed tasks that have a call disposition, are not deleted, and are of the right type
        List<Task> tasks = [SELECT Id, LastModifiedDate, CallDisposition__c, Whatid, WhoId, RecordTypeId 
                            FROM Task 
                            WHERE ID IN :TriggerNew 
                            AND CallDisposition__c != null 
                            AND isDeleted = false 
                            AND RecordTypeId = :careTaskId 
                            ORDER BY LastModifiedDate DESC];
        
        // Gather list of Opportunities that need to be updated
        Map<Id,Opportunity> careProfilesMap = new Map<Id,Opportunity>();
        for(Task thisTask: tasks) { 
            // Only look at tasks attached to opportunities, 
            // and only add them if they aren't already in the list (don't update opportunity twice)
            if (thisTask.WhatId != null && ((String)thisTask.WhatId).startsWith(careKeyPrefix) && !careProfilesMap.containsKey(thisTask.WhatId)) {
                careProfilesMap.put(thisTask.WhatId, new Opportunity(id=thisTask.WhatId, LastCallDisposition__c=thisTask.CallDisposition__c));
            }
        }
        
        // Only update if there is something to update
        if (!careProfilesMap.isEmpty()) {
            update careProfilesMap.values();
        }
    }
   
    //--------------------------------------
    // Inquiry Pieces
    //--------------------------------------
    
    // When moving these things around, this piece should move to the inquiry form
    
    /**
     * Class to store the results to be returned from the scoreLead function.
     */
    // Reviewed 5/18/2012
    public class ScoreResult {
        public Double score;
        public String grade;
       
        public ScoreResult(Double score, String grade) {
            this.score = score;
            this.grade = grade;
        }
    }
   
    /**
     * Calculate grade (numeric and letter
     *
     * @return - ScoreResult object with score (numeric grade) and grade (letter grade)
     */
    // Reviewed 5/18/2012
    public static ScoreResult scoreLead(Opportunity pros) {
        Long currentYear = Date.today().year();
    
        Double leadScoreResult = 0.0;
        List<EnrollmentResponses__c> results = [SELECT e.QuestionNumber__r.QuestionText__c, 
                                                       e.QuestionNumber__r.GradingType__c, 
                                                       e.CAREProfile__r.ReferID__c,
                                                       e.CAREProfile__r.Name, 
                                                       e.IsDeleted,  
                                                       e.AnswerQuestion__r.Value__c, 
                                                       e.AnswerQuestion__r.PointValue__c, 
                                                       e.AnswerQuestion__r.Name, 
                                                       e.AnswerQuestion__r.Multiplier__c,
                                                       e.AnswerQuestion__r.MultiplierValue__c, 
                                                       e.AnswerQuestion__r.IsDeleted, 
                                                       e.AnswerQuestion__r.AnswerText__c,
                                                       e.AnswerQuestion__r.AnswerStatus__c 
                                                FROM EnrollmentResponses__c e
                                                WHERE e.CAREProfile__c= :pros.Id];
        
        for (EnrollmentResponses__c e : results){
            // Skip records that cannot be processed because they 
            // are just questions without responses (early Datamark issue)
            if (e.AnswerQuestion__r == null) {
                continue;
            }
            // Graduation Date Grading
            else if (e.QuestionNumber__r.GradingType__c == 'Grad Date') {
                // Get rough estimate of age
                Long gradYear = Long.valueOf(e.AnswerQuestion__r.AnswerText__c);
                Long expectedAge = (currentYear - gradYear) + 18;
                
                // Possitive grade if between 25 and 40
                if (expectedAge >= 25 && expectedAge <= 40){
                    leadScoreResult += 0.206504671635885;
                } 
                // Otherwise, no change
                else {
                    leadScoreResult += 0.0;
                }
            } 
            // Standard grading
            // Using multipliers and values on answer object
            else {
                leadScoreResult += (e.AnswerQuestion__r.Multiplier__c *e.AnswerQuestion__r.MultiplierValue__c);                
            }
            
            // Bonus for specific sources
            // ?!?!?!?
            // Some of these are very old and some have new counterparts
            // Will need to change with move to MarketingSourceCode Object
            if ((e.CAREProfile__r.ReferID__c  ==   '0') // 00083 - Website More Info
                || (e.CAREProfile__r.ReferID__c  ==   '205') // 00496 - Live chat
                || (e.CAREProfile__r.ReferID__c  ==   '134') // 00090 - Troops to Teachers
                || (e.CAREProfile__r.ReferID__c  ==   '389') // 00681 - Refer A Friend (Online Form)
                || (e.CAREProfile__r.ReferID__c  ==   '425') // 00718 - Refer a Friend (Postcard) 
                || (e.CAREProfile__r.ReferID__c  ==   '203') // 00494 - Texas Refer a Friend
                || (e.CAREProfile__r.ReferID__c  ==   '204')) { // 00495 - Nevada Refer a Friend 
                leadScoreResult +=  0.293585899165594;
            }
        }

        // Funny math (just following old methodology)
        leadScoreResult += -5.56783865284557;
        Double finalResult = Math.exp(leadScoreResult)/ (1 + Math.exp(leadScoreResult));
        
        // Return as ScoreResult Object
        return new ScoreResult(finalResult, decodeGrade(finalResult));
    }

    /**
     * Translate from numeric value to letter grades
     */
    // Reviewed 5/18/2012
    public static String decodeGrade(Double score){
        if ((score > 0.31347633847592) && (score <= 1)) {return 'A';}
        else if (score > 0.164256113365196) {return 'B+';}
        else if (score > 0.0799564581610787) {return 'B';}
        else if (score > 0.0317842215602586) {return 'C';}
        else if (score > 0.0260082343351823) {return 'D';}
        else if (score > 0.0) {return 'F';}
        else {return 'NS';}
    } 

    /*
    public static String getScoreFromQuestions(Map<String, String> requiredQuestions,
                                               Map<String, String> optionalQuestions,
                                              String referID)
        
    {   System.debug('requiredQuestions');
        System.debug(requiredQuestions);
        System.debug('optionalQuestions');
        System.debug(optionalQuestions);
        if(requiredQuestions==null || requiredQuestions.isEmpty())
        {
            return null;
        }
        Long currentYear = Date.today().year();
        Double leadScoreResult = 0.0;
        if(optionalQuestions!=null)
        {
            requiredQuestions.putAll(optionalQuestions);
        }
        for ( String key : requiredQuestions.keyset())
        {   
            EnrollmentResponses__c e =  new EnrollmentResponses__c(QuestionNumber__c=key, AnswerQuestion__c=requiredQuestions.get(key),
                                   CAREProfile__c=null, DateAnswered__c=date.today());
        
        
         if (e.AnswerQuestion__r == null) {
                // Skip records that cannot be processed because they are just questions without responses
                continue;
            }
            else if (e.QuestionNumber__r.GradingType__c == 'Grad Date') {
   
                Long gradYear = Long.valueOf(e.AnswerQuestion__r.AnswerText__c);
                Long expectedAge = (currentYear - gradYear) + 18;
                
                if (expectedAge >= 25 && expectedAge <= 40){
                    leadScoreResult += 0.206504671635885;
                } else {
                    leadScoreResult += 0.0;
                }
            } else {
                leadScoreResult += (e.AnswerQuestion__r.Multiplier__c *e.AnswerQuestion__r.MultiplierValue__c);                
            }
            
            if ((referId  ==   '0') // 00083 - Website More Info
                || (referId ==   '205') // 00496 - Live chat
                || (referId ==   '134') // 00090 - Troops to Teachers
                || (referId  ==   '389') // 00681 - Refer A Friend (Online Form)
                || (referId  ==   '425') // 00718 - Refer a Friend (Postcard) 
                || (referId  ==   '203') // 00494 - Texas Refer a Friend
                || (referId ==   '204')) { // 00495 - Nevada Refer a Friend 
                leadScoreResult +=  0.293585899165594;
            }
        }

        leadScoreResult += -5.56783865284557;
        Double finalResult = Math.exp(leadScoreResult)/ (1 + Math.exp(leadScoreResult));
        System.debug('New Final RESULT: ' + finalResult);
        String finalGrade = decodeGrade(finalResult);
        return finalGrade;
    }  
    */
    
    //--------------------------------------
    // EC Assignment Pieces
    //--------------------------------------
    
    /**
     * Finds the next Enrollment Councilor in line to have a CARE profile assigned.
     */
    public static Id nextEnrollmentCounselor(String programGroup) {
        List<Id> ids = nextEnrollmentCounselor(programGroup, 1);
        
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        else {   
            return ids[0];
        }
    }
    
    /**
     * Get list of ECs to assign Leads to, based on program
     * Leads can be weighted on a per EC basis
     */
    public static List<Id> nextEnrollmentCounselor(String programGroup, Integer howManyToPull) {
        // Without a Program, don't proceed
        if (programGroup == null) {
            return null;    
        }
    
        // Get Enrollment Team Record Type Id
        Id ecRecordType = [SELECT Id 
                           FROM RecordType 
                           WHERE sObjectType = 'UserAttributes__c' 
                           AND Name = 'Enrollment Team'][0].Id;
        
        // Get Enrollment Counselors assigned to the specified program
        // ECs are Users with Enrollment Team Record Type
        List<UserAttributes__c> enrollmentCounselors = [SELECT id, AssignmentMultiplier__c, User__r.Id, User__r.IsActive 
                                                        FROM UserAttributes__c 
                                                        WHERE User__r.IsActive = true 
                                                        AND UserAttributes__c.IsDeleted = false
                                                        AND RecordTypeId = :ecRecordType 
                                                        AND AssignedPrograms__c INCLUDES (:programGroup)];
        
        // If there aren't ECs assigned to this program stop trying to assign
        // ?!?!?!?
        // This is wehre a default would be helpful instead of leaving it
        // assigned to whoever created the record
        if (enrollmentCounselors.isEmpty()) {
            return null;
        }
        
        // Create a list of ECs with multipliers (throttle for ECs)
        // While in there, create list of Ids
        Map<Id, Decimal> multipliers = new Map<Id, Decimal>();
        List<Id> memberIds = new List<Id>();
        for (UserAttributes__c  user : enrollmentCounselors) {
            if (user.AssignmentMultiplier__c == null) {
                user.AssignmentMultiplier__c = 1;
            }
            
            multipliers.put(user.User__r.Id, user.AssignmentMultiplier__c);
            memberIds.add(user.User__r.Id);
        }
        
        // Get raw count of prospects (from today) that each EC has recieved
        List<AggregateResult> existingProfiles = [SELECT ownerid, count(name) counselorCount 
                                                  FROM Opportunity 
                                                  WHERE CreatedDate > YESTERDAY 
                                                  AND BadLeadReason__c = null 
                                                  AND ownerId in :memberIds 
                                                  GROUP BY ownerId];
        
        // Get modified count of EC loads (raw * multiplier)
        Map<Id, Decimal> counts = new Map<Id, Decimal>();
        for (Integer i = 0; i < existingProfiles.size(); i++) {
            counts.put((Id)existingProfiles[i].get('ownerid'), (Decimal)existingProfiles[i].get('counselorCount') * multipliers.get((Id)existingProfiles[i].get('ownerid')));
        }        
        
        List<Id> counselors = new List<Id>();
        for(Integer i = 0; i < howManyToPull; i++) {
            boolean nextIteration = false;
        
            // Check if any councilors don't have any leads, assign them leads first.
            // ?!?!?!?
            // Doesn't seem like nesting a for loop in a for loop is a good option here
            // Why not just run the none assigned and then follow it with the normal assignment?
            if (existingProfiles == null || existingProfiles.size() < memberIds.size()) {
                // Loop through all ECS, looking for ones without Leads
                for (Id memberId : memberIds) {    
                    // Does this EC exist in the list with Leads
                    if (!counts.containsKey(memberId)) {
                        // Add this EC as the first to recieve a lead
                        counselors.add(memberId);
                        
                        // Update their count
                        Decimal multiplierValue = multipliers.get(memberId);
                        counts.put(memberId, 1 * multiplierValue); 
                        
                        // Count this as one EC
                        nextIteration = true;
                        break;                     
                    }
                }
                
                // Skip to next iteration 
                // Stop execution if only looking for 1
                if (nextIteration) {
                    continue;
                }
            }
            
            // Find lowest count
            // Done by comparing each EC with its neighor and keeping the lowest until
            // you run out of ECs to compare against
            Id nextInLine = null;
            Decimal compare = 0;
            for (String key : counts.keySet()) {
                // Fist EC always selected as starting point (default)
                if (nextInLine == null) {    
                    nextInLine = key;
                    continue;
                }
                
                // If this EC has less than current nextInLine, it becomes nextInLine
                if (counts.get(key) < counts.get(nextInLine)) {
                    nextInLine = key;
                }
            }
            
            // Add EC with fewest leads as next to receieve lead
            counselors.add(nextInLine);
            
            // Update their count
            counts.put(nextInLine, counts.get(nextInLine) + (1 * multipliers.get(nextInLine)));
        }
        
        // Return list of ECs to receive leads
        return counselors;
    }

    /*
    // 7/9/2013 yemeng
    // Finds the next Enrollment Councilor in line to have a CARE profile assigned.
    public static Id nextEnrollmentCounselorByGrade(String programGroup,String leadGrade) {
        List<Id> ids = nextEnrollmentCounselorByGrade(programGroup, leadGrade, 1);
        
        if (ids == null || ids.isEmpty())
            return null;
        else    
            return ids[0];
    }
    
    // 7/9/2013 yemeng
    // Finds  next Enrollment Counsellors by given program , leadgrade
    public static List<Id> nextEnrollmentCounselorByGrade(String programGroup, String leadGrade,Integer howManyToPull) {
       // System.debug('################## enter Next EC by grade p:' + programGroup + ' Grade:'+ leadGrade+ ' howManyToPull:'+howManyToPull);
        if (programGroup == null)
            return null;    
    
        List<Id> counselors = new List<Id>();
        Id ecRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'UserAttributes__c' AND Name = 'Enrollment Team'][0].Id;
        //List of User Attributes for all Enrollment Counselor of given program.
        List<UserAttributes__c> enrollmentCounselors = [SELECT id, AssignmentMultiplier__c, User__r.Id, User__r.IsActive FROM UserAttributes__c 
        WHERE User__r.IsActive = true AND
        UserAttributes__c.IsDeleted = false  AND
        RecordTypeId = :ecRecordType AND
        AssignedPrograms__c INCLUDES (:programGroup)];
        
   //     System.debug('################## UserAttributes'+enrollmentCounselors);
        if (enrollmentCounselors.isEmpty()) 
            return null;
        //User of Enrollment Counselors 
        List<Id> memberIds = new List<Id>();
        
        for (UserAttributes__c member : enrollmentCounselors) {
            memberIds.add(member.User__r.Id);
        }
   //     System.debug('################## menberids '+memberIds);
        List<AggregateResult> existingProfiles = [SELECT ownerid, count(name) counselorCount FROM Opportunity WHERE leadGrade__c = :leadGrade and CreatedDate > YESTERDAY AND BadLeadReason__c = null AND ownerId in :memberIds group by ownerId];
   //     System.debug('################## Exist Opportunity'+existingProfiles);
        //  User -> multiplier 
        Map<Id, Decimal> multipliers = new Map<Id, Decimal>();
        
        for (UserAttributes__c  user : enrollmentCounselors) {
            if (user.AssignmentMultiplier__c == null)
                user.AssignmentMultiplier__c = 1;
            
            multipliers.put(user.User__r.Id, user.AssignmentMultiplier__c);
        }
        // User -> priorityScore ( opps * multiplier)
        Map<Id, Decimal> counts = new Map<Id, Decimal>();
        
        for (Integer i = 0; i < existingProfiles.size(); i++) {
            counts.put((Id)existingProfiles[i].get('ownerid'), (Decimal)existingProfiles[i].get('counselorCount') * multipliers.get((Id)existingProfiles[i].get('ownerid')));
        }        
//        System.debug('################## counts'+counts);
        for(Integer i = 0; i < howManyToPull; i++) {
            boolean nextIteration = false;
        
            // Check if any councilors are not in the aggregate results, this means they have no assignments and need to be assigned first.
            if (existingProfiles == null || existingProfiles.size() < memberIds.size()) {
                
                for (Id memberId : memberIds) {    
             //   System.debug('################## ---memid---'+memberId );
                    if (!counts.containsKey(memberId)) {
                        counselors.add(memberId);
                        // Set first Key/count for enrollment counselor that did not have a key prior to this function run.
                        Decimal multiplierValue = multipliers.get(memberId);
                            
                        counts.put(memberId, 1 * multiplierValue); 
                        nextIteration = true;
                        break;                     
                    }
                }
                
                if (nextIteration)
                    continue;
            }
            
            // Find lowest count.
            Id nextInLine = null;
            Decimal compare = 0;
       //     System.debug('##################  count again'+counts);
            for (String key : counts.keySet()) {
                if (nextInLine == null) {    
                    nextInLine = key;
                    continue;
                }
                
                if (counts.get(key) < counts.get(nextInLine)) {
                    nextInLine = key;
                }
            }
            
            if (nextInLine == null)
                counselors.add(null);
            //update counts for next EC     
            counts.put(nextInLine, counts.get(nextInLine) + (1 * multipliers.get(nextInLine)));
            //current EC put in
            counselors.add(nextInLine);
        }
    //    System.debug('################## counselors'+counselors);
        
        return counselors;
    }
    */
   
    //--------------------------------------
    // Record Merging
    //--------------------------------------
    
    /**
     * Meant to allow us to merge two accounts mid stream if we determine that
     * records that are separate actually are for the same individual.
     *
     * @return - Id of account to which all information is to be attached.
     */
    public static Id matchSSNAndDobAndMerge(Id incomingAccount, String ssn, Date dob) {
        // If no date of birth or SSN, then don't proceed.
        // This matches records that banner would choke on
        if (dob == null || ssn == null) {
            return null;
        }
  
        // Search for matching record
        // Is there a record to merge with?
        Id existingAccount = matchSsnAndDOB(ssn, dob);
        
        // If no match, return account id.
        if (existingAccount == null) {
            return incomingAccount;
        }
        
        // Merge current record with previous record
        // Delete old record
        mergeAccounts(incomingAccount, existingAccount, true);
        
        // Return id of account to which everything was merged
        return existingAccount;
    }
    
    /**
     * Standardize method for merging two accounts
     */
    public static void mergeAccounts(Id fromAccountId, Id toAccountId, Boolean deleteOld) {
        // Gather all objects attached to from record
        // This is done in preparation to moving them to the
        // existing record.
        Account fromAccount = [SELECT Id, StudentContact__c,
                              (SELECT Id, WhoId, WhatId FROM Tasks),
                              (SELECT Id, WhoId, WhatId FROM Events)
                               FROM Account 
                               WHERE Id = :fromAccountId];
        
        // Gather original (previous) record that information will be moved onto
        Account toAccount = [SELECT Id, StudentContact__c
                              FROM Account 
                              WHERE Id = :toAccountId];
        
        // Move Tasks to existing Account
        moveTasks(fromAccount.Tasks, toAccount.StudentContact__c, toAccount.id);
        
        // Move Events to existing Account
        moveEvents(fromAccount.Events, toAccount.StudentContact__c, toAccount.id);
        
        // Merge contacts
        // Don't delete, deleting the account will do that if set
        mergeContacts(fromAccount.StudentContact__c, toAccount.StudentContact__c, false);
        
        // Move opportunities to new account
        moveOpportunities(fromAccount.Id, toAccount.Id, toAccount.StudentContact__c);
        
        // Clean up flag set (delete after move)
        if (deleteOld) {
            // Get hash (Hash is not moved)
            // It should already exist on existing record as that is how it was found
            List<StudentSearchHash__c> hash = [SELECT Id 
                                               FROM StudentSearchHash__c 
                                               WHERE StudentAccount__c = :fromAccountId];
            
            // Delete hash and account
            // Hash first because account cannot be deleted if hash still exists
            delete hash;
            delete fromAccount;
        }
    }
    
    /**
     * Standardize method for merging two contacts
     */
    public static void mergeContacts(Id fromContactId, Id toContactId, Boolean deleteOld) {
        // Gather Merge/Copy information from both Contact records
        Contact fromContact = [SELECT Id, DateOfBirth__c, SocialSecurityNumber__c, OtherEmail__c, HomePhone, Email,
                                      MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, RecordTypeId, Status__c,
                           	  (SELECT Id, WhoId, WhatId FROM Tasks),
                              (SELECT Id, WhoId, WhatId FROM Events)
                               FROM Contact 
                               WHERE Id = :fromContactId];
        Contact toContact = [SELECT Id, DateOfBirth__c, SocialSecurityNumber__c, OtherEmail__c, HomePhone, Email,
                              MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, RecordTypeId, Status__c
                              FROM Contact 
                              WHERE Id = :toContactId];
        
        // Move Tasks to merged Contact
        moveTasks(fromContact.Tasks, toContact.Id, null);
        
        // Move Events to merged Contact
        moveEvents(fromContact.Events, toContact.Id, null);
        
        // Contact value updates
        // Don't replace with null values
        if (fromContact.OtherEmail__c != null) toContact.OtherEmail__c = fromContact.OtherEmail__c;
        if (fromContact.HomePhone != null) toContact.HomePhone = fromContact.HomePhone;
        if (fromContact.MailingStreet != null) toContact.MailingStreet = fromContact.MailingStreet;
        if (fromContact.MailingCity != null) toContact.MailingCity = fromContact.MailingCity;
        if (fromContact.MailingState != null) toContact.MailingState = fromContact.MailingState;
        if (fromContact.MailingPostalCode != null) toContact.MailingPostalCode = fromContact.MailingPostalCode;
        if (fromContact.MailingCountry != null) toContact.MailingCountry = fromContact.MailingCountry;
        
        // Only update email if new email is not blank
        // existing is empty or doesn't end with wgu.edu (assumes from record has newer information)
        if ((toContact.Email == null || !toContact.Email.endsWith('wgu.edu')) && fromContact.Email != null) {
            toContact.Email = fromContact.Email;
        }
        
        // Only pull over SSN and date of birth if they are blank on the toContact
        if (toContact.DateOfBirth__c == null) {toContact.DateOfBirth__c = fromContact.DateOfBirth__c;}
        if (toContact.SocialSecurityNumber__c == null) {toContact.SocialSecurityNumber__c = fromContact.SocialSecurityNumber__c;}    
        
        // ?!?!?!?
        // If toContact record is an IN (Inquiry/Prospect) set Record type to ProspectRecord
        // Shouldn't this already be true? Why here?
        if (toContact.Status__c == 'IN') {
            toContact.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Contact' AND Name = 'ProspectRecord'].Id;
        }
        
        // Update existing (proper) contact
        update toContact;
        
        if (deleteOld) {
            delete fromContact;
        }
    }
    
    /**
     * Standardized method to move opportunities from one record to another
     */
    public static void moveOpportunities(Id fromAccount, Id toAccount, Id toContact) {
        // Get list of opportunities associated with Account
        List<Opportunity> Opportunities = [SELECT Id, Name, AccountId, Account.StudentContact__c, StudentContact__c, StudentAttributes__r.Id, 
                                                      StudentAttributes__r.StudentContact__c, StudentAttributes__r.StudentAccount__c,
                                              (SELECT Id, WhoId, WhatId FROM Tasks),
                                              (SELECT Id, WhoId, WhatId FROM Events)
                                               FROM Opportunity 
                                               WHERE AccountId = :fromAccount];
        
        // Process Opportunity Moving
        // Keep list of all opportunities and update them all at once
        List<Opportunity> listOfOpportunitiesForUpdate = new List<Opportunity>();
        
        // Modify each Opportunity.
        for (Opportunity opp : Opportunities) {
            // Switch Account and Contact connection to exiting ones
            opp.AccountId = toAccount;
            opp.StudentContact__c = toContact;
            
            // ?!?!?!?
            // Update Student Attributes attached to this Opportunity
            // Is this really the proper relationship to rely on for this?
            opp.StudentAttributes__r.StudentContact__c = toContact;
            opp.StudentAttributes__r.StudentAccount__c = toAccount;
            
            // Reassign whoId on Opportunity Tasks
            moveTasks(opp.Tasks, toContact, NULL);
            
            // Reassign whoId on Opportunity Events
            moveEvents(opp.Events, toContact, NULL);
            
            // Add to list to be updated
            listOfOpportunitiesForUpdate.add(opp);
        }
        
        // Update Opportunities as a group
        update listOfOpportunitiesForUpdate;
    }
    
    /**
     * Standardized method to move a group of events to a new object
     */
    public static void moveEvents(List<Event> events, Id whoId, Id whatId) {
        List<Event> eventsToUpdate = New List<Event>();
        
        for (Event event : events) {
            // Only overwrite if previously specified and not unspecifying
            // Does not allow disconnecting or further specifying connections
            // Only allows for reassigning existing connection points
            if (event.whoId != null && whoId != null) {event.whoId = whoId;}
            if (event.whatId != null && whatId != null) {event.whatId = whatId;}
            
            // Just a protection against being passed a list of events without ids
            if (event.Id != null) {
                eventsToUpdate.add(event);
            }
        }
        
        update eventsToUpdate;
    }
    
    /**
     * Standardized method to move a group of tasks to a new object
     */
    public static void moveTasks(List<Task> tasks, Id whoId, Id whatId) {
       List<Task> tasksToUpdate = New List<Task>();
        
        for (Task task : tasks) {
            // Only overwrite if previously specified and not unspecifying
            // Does not allow disconnecting or further specifying connections
            // Only allows for reassigning existing connection points
            if (task.whoId != null && whoId != null) {task.whoId = whoId;}
            if (task.whatId != null && whatId != null) {task.whatId = whatId;}
            
            // Just a protection against being passed a list of tasks without ids
            if (task.Id != null) {
                tasksToUpdate.add(task);
            }
        }
        
        update tasksToUpdate;
    }
    
    //--------------------------------------
    // Record Matching
    //--------------------------------------
    
    /**
     * Look for matching record.
     *
     * @return - Contact with Id, AccountId, FirstName, LastName, & Email
     */
    public static Contact checkProspectForExistingContact(String firstName, String lastName, String email, String phone, String socialSecurityNumber, String dob) {
        // Look for SSN match.
        // If found, stop continued execution.
        Contact match = findSSNMatch(socialSecurityNumber, dob, email, lastName);
        if (match != null) {
            return match;
        }
      
        // Look for Contact Information match.
        // If found, stop continued execution.
        match = findContactInfoMatch(firstName, lastName, email, phone);
        if (match != null) {
            return match;
        }
        
        // Fall back to null (no match)
        return null;
    }
    
    /*
     * Matching criteria:
     * social security number (matches exactly)
     *   -- AND --
     *   (
     *     date of birth (matches exactly)
     *     -- OR -- 
     *     email (matches Email or OtherEmail exactly)
     *     -- OR -- 
     *     Last Name (matches exactly)
     *   )
     *
     * @return - getContactInfo created Contact
     */
    public static Contact findSSNMatch(String socialSecurityNumber, String dob, String email, String lastName) {
        // If no SSN, don't proceed
        if (socialSecurityNumber == null && socialSecurityNumber == '') {
            return null;
        }
        
        // Social Security Number Matching Options
        // SSN & (DOB, an Email, or Last Name)
        Id matchedAccount = null;
        
        // Give presidence to Date of Birth and SSN match
        // This is the match that Banner does internally
        if (dob != null && dob != '') {
            // Get account with matching SSN and Date of Birth
            matchedAccount = MatchSsnAndDOB(socialSecurityNumber, Date.parse(dob));
            
            // If matched, return required contact information
            // Otherwise, continue to other methods.
            if (matchedAccount != null) {
                return getContactInfo(matchedAccount);
            }
        }
        
        // Fall back to just matching by SSN
        matchedAccount = MatchSsn(socialSecurityNumber);
        
        // If no match, don't proceed
        if (matchedAccount != null) {
            // Get contact associated with account
            Contact SSNContact = getContactInfo(matchedAccount);
            
            // This logic might crash if account is connected to contact 
            // but contact isn't attached to account. Only proceed if no
            // problems encountered
            if (SSNContact != null) {
                // Only return match if some other datapoint also matches
                // Possible options are: email, or last name
                // Don't match on empty or null values
                if (email != '' && email != null && (email == SSNContact.OtherEmail__c || email == SSNContact.Email)) {
                    return SSNContact;
                }
                else if (lastName != '' && lastName != null && lastName == SSNContact.LastName) {
                    return SSNContact;
                }
            }
        }
        
        // Fall back to returning null (no match)
        return null;
    }
    
     /*
     * Matching criteria:
     * Last Name matches exactly and first three letters for First Name match
     *   -- AND --
     *   (
     *     email matches exactly (main emails)
     *     -- OR -- 
     *     phone matches exactly (any phone number)
     *   )
     *
     * @return - getContactInfo created Contact
     */
    public static Contact findContactInfoMatch(String firstName, String lastName, String email, String phone) {
        // No point to proceed if either first or last name is blank or null.
        if (firstName == '' || firstName == null || lastName == '' || lastName == null) {
            return null;
        }
    
        // Default first name to complete, then cut to just three letters (if it is longer)
        String firstNameSubSet = firstName;
        if (firstNameSubSet.length() > 3) {
            firstNameSubSet = firstNameSubSet.substring(0, 3) + '%';
        }
        
        // Transform phone number to common Salesforce format
        // Expecting just numbers, if sent something else then use format that was submitted.
        String phoneToCheck = null;
        if (phone != null) {
            phoneToCheck = phone.replaceAll('[^0-9]','');
            if (phoneToCheck.length() == 10) {
                phoneToCheck = '(' + phoneToCheck.substring(0, 3) + ') ' + phoneToCheck.substring(3, 6) + '-' + phoneToCheck.substring(6, 10);
            } else {
                phoneToCheck = phone;
            }
        }
        
        // First 3 letters of first name, last name & (an email or a phone number)
        List<Contact> contacts = [SELECT Id, AccountId, FirstName, LastName, Email 
                                  FROM Contact 
                                  WHERE (FirstName LIKE :firstNameSubSet AND 
                                         LastName = :lastName) 
                                  AND   (Email = :email OR
                                         OtherEmail__c = :email OR
                                         Phone = :phoneToCheck OR 
                                         HomePhone = :phoneToCheck OR
                                         MobilePhone = :phoneToCheck OR
                                         OtherPhone = :phoneToCheck) 
                                  AND IsDeleted = false]; 
        
        // Check for matches
        if (contacts.size() > 0) {
            // Return first match
            return contacts.get(0);
        }
        
        return null;
    }
    
    /**
     * Find a contact record based on an account id
     *
     * This is broken out to allow for an abstraction of what should be returned instead
     * of managing it in multiple locations.
     *
     * @return - Contact (with expected fields for record match) or NULL
     */
    public static Contact getContactInfo(Id accountId) {
        // Don't search if no account id is provided
        if (accountId == null) {
            return null;
        }
        
        // Get expected data points from contact using the account id
        List<Contact> SSNmatches = [SELECT Id, AccountId, FirstName, LastName, Email, OtherEmail__c 
                                    FROM Contact 
                                    WHERE (AccountID = :accountId) 
                                    AND IsDeleted = false 
                                    LIMIT 1];
        
        // Return match is made, otherwise null
        if (SSNmatches.size() > 0) {
            return SSNmatches.get(0);
        }
        
        return null;
    }
    
    /**
     * Find a record with a matching SSN and Date of Birth
     * @return - Account Id or NULL
     */
    public static Id MatchSsnAndDOB(String ssn, Date dob) {
        // Don't bother if either value is null
        if (ssn == null || dob == null) {
            return null;
        }
        
        // Get encrypted versions of values
        String ssnHash = EncryptSsn(ssn);  
        String birthDateHash =  EncryptDob(dob);
        
        List<StudentSearchHash__c> existingHashes = [Select Id, Student__c, StudentAccount__c 
                                                     FROM StudentSearchHash__c 
                                                     WHERE SSNHash__c = :ssnHash 
                                                     AND BirthDateHash__c = :birthDateHash
                                                     LIMIT 1]; 
        
        // Return match or NULL if nothing returned by query
        if (existingHashes.isEmpty()) {
            return null;
        }
        else {
            return existingHashes[0].StudentAccount__c;
        }  
    }
    
    /**
     * Search for an account based on SSN. 
     * @return - Account Id or NULL
     */
    public static Id MatchSsn(String ssn) {
        // Do not search if no SSN passed
        if (ssn == null) {
            return null;
        }
        
        // Get encrypted SSN
        String  ssnHash = EncryptSsn(ssn);  
        
        
        List<StudentSearchHash__c> existingHashes = [SELECT Id, Student__c, StudentAccount__c 
                                                     FROM StudentSearchHash__c 
                                                     WHERE SSNHash__c = :ssnHash]; 
        
        // Return match or NULL if nothing returned by query
        if (existingHashes.isEmpty()) {
            return null;
        }
        else {
            return existingHashes[0].StudentAccount__c;
        }  
    } 
    
    /**
     * Return an encrypted SSN
     */
    private static String EncryptSsn(String ssn) {
        // Don't encrypt if value is null
        if (ssn == null) {
            return null;
        }
        
        // Return standard encryption
        return EncryptValue(ssn);  
    }
    
    /**
     * Return an encrypted Date of Birth from Date
     */
    private static String EncryptDob(Date dob) {
        // Don't encrypt if value is null
        if (dob == null) {
            return null;
        }
        
        // Return standard encryption
        return EncryptValue(dob.format());
    }
    
    /**
     * Return an encrypted field following our standard encryption
     * Calling this function directly should be done with caution
     * If ecypting a SSN or Date of Birth, use their functions (in case
     * things change at a later time).
     */
    private static String EncryptValue(String value) {
        // Don't encrypt if value is null
        if (value == null) {
            return null;
        }
        
        // Follow standard encryption patten that we use
        return EncodingUtil.base64Encode(Crypto.generateDigest('SHA1', Blob.valueOf(value)));
    }
    
    //--------------------------------------
    // Eloqua Pieces
    //--------------------------------------
    
    public static void sendBasicInfoToEloqua(String email, String firstName, String marketingProgram, String campusLong, 
                                             String campusShort, String ecName, String careStatus) {
        String body = 'elqSiteID=' + EncodingUtil.urlEncode('46982626', 'UTF-8') +
            '&elqFormName=' + EncodingUtil.urlEncode('smartStartSFdcPushTest-1349889849844', 'UTF-8') +
            '&elqCampaignId=' + 
            '&emailAddress=' + EncodingUtil.urlEncode(email, 'UTF-8') +
            '&firstName=' + EncodingUtil.urlEncode(firstName, 'UTF-8') +
            '&salesperson=' + EncodingUtil.urlEncode(ecName, 'UTF-8') +
            '&MarketingProgram=' + EncodingUtil.urlEncode(marketingProgram, 'UTF-8') +
            '&campusLongName=' + EncodingUtil.urlEncode(campusLong, 'UTF-8') +
            '&campusShortName=' + EncodingUtil.urlEncode(campusShort, 'UTF-8') + 
            '&careStatus=' + EncodingUtil.urlEncode(careStatus, 'UTF-8');
        
        postDataToURL(String.valueOf(Runtime__c.getValues('eloquaNewContactURL')), body);
    }
    
    //--------------------------------------
    // LeadQual of External Vendor Pieces
    //--------------------------------------
    
    /**
     * Set Contact Controller On opportunity
     * Kick off any processes specific to the assigned vendor
     */
    public static void assignLeadToVendor(Opportunity o, ExternalLeadContactControl__c c) {
        // Get Information from Contact Controller
        ExternalLeadContactControl__c outsideOrg = [SELECT Id, Name, IsDeleted, Active__c 
                                                    FROM ExternalLeadContactControl__c  
                                                    WHERE isDeleted = false
                                                    AND Active__c = true 
                                                    AND id = :c.id];
        // LeadQual Processing
        if (outsideOrg.name == 'LeadQual') {
            // Get Opportunity details
            o = [SELECT id, studentContact__r.firstName, studentContact__r.lastName,
                        studentContact__r.phone, studentContact__r.homephone, 
                        MarketingProgram__r.name,  MarketingProgram__r.CAREProgramCode__r.name,
                        MarketingProgram__r.ProgramGroups__c, studentContact__r.mailingstate, 
                        studentContact__r.mailingpostalcode, Owner.name, LeadGrade__c   
                 FROM Opportunity  
                 WHERE Opportunity.id = :o.id];
            
            sendInfoToLeadQual(o.id, o.studentContact__r.firstName, o.studentContact__r.lastName,
                               o.studentContact__r.phone,o.studentContact__r.homephone,  o.MarketingProgram__r.name, 
                               o.MarketingProgram__r.CAREProgramCode__r.name, o.MarketingProgram__r.ProgramGroups__c, o.studentContact__r.mailingstate,
                               o.studentContact__r.mailingpostalcode, o.Owner.name, o.LeadGrade__c );
        }                                             
        
        // Assign opportunity to organization and save change
        o.ExternalLeadContactControl__c = c.id;
        update o;
    }
    
    /**
     * Figure out who will be contact this opportunity
     * Default is to assign it to WGU.
     * 
     * In order to be assigned, an organization must be open (according to their bussiness hours),
     * not have met their monthly max for lead assignment, and not have more than their percentage
     * of leads by grade.
     */
    public static void createExternalLeads(Opportunity o) {
        // Filter by operating hours (don't assign when peope aren't there to contact the Lead)
        
        // Gather LeadContact Controllers
        // ?!?!?!?
        // There is nothing that forces them to be external
        List<ExternalLeadContactControl__c> externLeadOrg = [SELECT Id, IsDeleted, Name, CreatedDate, CreatedById,
                                                                    Active__c, CurrentMonthlyCount__c, MonthlyLimit__c, 
                                                                    PercentOfLeadsToAssignPicklist__c, StartHour__c, StopHour__c 
                                                             FROM ExternalLeadContactControl__c 
                                                             WHERE isDeleted = false
                                                             AND Active__c = true];
        
        ExternalLeadContactControl__c WGULead;    
        DateTime nowTime = DateTime.now();
        integer h = nowTime.hour();     
        List<ExternalLeadContactControl__c> activeExternalOrgs = new List<ExternalLeadContactControl__c>();
        
        // Loop through LeadContactControllers
        // Ones that are actively making calls are added to activeList
        // Also get the WGU controller and assign it to variable
        for (ExternalLeadContactControl__c el : externLeadOrg) {
            if (el.name == 'WGU' ) {
                WGULead = el;
            }
            
            if (el.StartHour__c <= h && el.StopHour__c > h ) {
                activeExternalOrgs.add(el);
            }
        }                                              
        
        // If only WGU controller, assign opportunity to WGU
        // ?!?!?!?
        // There is an assumption here that it will always find WGU
        if (externLeadOrg.size() <= 1) {
            assignLeadToVendor(o, WGULead);     
            return;                                 
        }                                              
        
        // If there are no active Organizations, assign opportunity to WGU
        // ?!?!?!?
        // There is an assumption here that it will always find WGU
        if (activeExternalOrgs.size() <= 1) {
            assignLeadToVendor(o, WGULead);     
            return;                                 
        }                                              
        
               
        // Filter by limits (don't assign more than we are under contract for or want to assign them)
        
        // Ensure that Organizations haven't reached their max and shouldn't recieve more Leads
        // Get number of opportunities assigned to Organizations, broken into groups by Grade
        List<AggregateResult> activeThisMonth =  [SELECT count(id) c, LeadGrade__c,     
                                                         ExternalLeadContactControl__r.name nm,
                                                         max(ExternalLeadContactControl__r.MonthlyLimit__c) ml, 
                                                         max(ExternalLeadContactControl__r.StartHour__c) start, 
                                                         max(ExternalLeadContactControl__r.StopHour__c) stop, 
                                                         ExternalLeadContactControl__c 
                                                  FROM Opportunity 
                                                  WHERE Opportunity.createdDate = THIS_MONTH 
                                                  AND (ExternalLeadContactControl__r.Active__c = true 
                                                       OR ExternalLeadContactControl__c = null)
                                                  GROUP BY LeadGrade__c, ExternalLeadContactControl__c,ExternalLeadContactControl__r.name];
        
        Integer totalLeads = 0;
        Map<String, Integer> mapByExternalVendor = new Map<String, Integer> ();
        Map<String, Integer> mapByGrade =  new Map<String, Integer> ();
        Map<String, Integer> mapPercentByExternalVendor =  new Map<String, Integer> ();
        
        Boolean externalLeadHours = false;
        List<AggregateResult> validVendors = new List<AggregateResult>();
        
        // Data gathering
        for (AggregateResult ao: activeThisMonth) {
            // Pull out Organization name, Opportunities' Grade, 
            // and Number of Opportunities in this groups
            String t = String.valueof(ao.get('nm'));
            String g = String.valueof(ao.get('LeadGrade__c'));
            totalLeads = totalLeads + integer.valueof(ao.get('c'));
            
            // If no ContactController assigned, default is WGU
            if (t == null) {
                t = 'WGU';
            }
            
            // If this organization is already in the vendor map
            // update count value
            // ?!?!?!?
            // Why remove and put instead of just MAP.set()
            if (mapByExternalVendor.containsKey(t)) {
                Integer i = mapByExternalVendor.get(t) + Integer.valueof(ao.get('c'));
                mapByExternalVendor.remove(t);
                mapByExternalVendor.put(t, i);
            }
            // Otherwise, just add it
            else {
                mapByExternalVendor.put(String.valueof(t), Integer.valueof(ao.get('c')));
            }
            
            // If this grade is already in the Grade map
            // Update count value
            // ?!?!?!?
            // Why remove and put instead of just MAP.set()
            // ?!?!?!?
            // There doesn't seem to be a Org filter on the grade piece, is that intentional?
            if (mapByGrade.containsKey(g)) {
                Integer i = mapByGrade.get(g) + Integer.valueof(ao.get('c'));
                mapByGrade.remove(g);
                mapByGrade.put(g, i);
            }
            // Otherwise, just add it
            else {
                mapByGrade.put(g, Integer.valueof(ao.get('c')));
            }
        }
        
        // Collect Organizations that have not met their monthly limit
        List<ExternalLeadContactControl__c> availableLeadsOrgs = new List<ExternalLeadContactControl__c>();
        for (ExternalLeadContactControl__c el : activeExternalOrgs) {
            if (el.name != 'WGU') {
                // Number of leads already assigned to vendor
                integer i = mapByExternalVendor.get(el.name);
                
                // Default to zero
                if (i == null) {
                    i = 0;
                }
                
                // This one won't push them over their limit
                // Add them to the list
                if ((i + 1) <= el.MonthlyLimit__c) {
                    availableLeadsOrgs.add(el); 
                }
            }
        }
        
        // If everyone is at their limit, assign to WGU
        if (availableLeadsOrgs.size() < 1){
            assignLeadToVendor(o, WGULead);  
            return;   
        }
        
        
        // Filter by % limits on number of leads (for any grade)
        
        // Get opportunity's grade, and number of people with that grade this month
        String grade = o.LeadGrade__C;
        Integer gradeCount = mapByGrade.get(grade);
        Integer precentCount = 0;
        
        // Loop through Orgs looking for one to assign this opportunity to
        // Crazy logic. Basically if first organization is set to receive 30%
        // and they haven't reached that yet they will get this lead. If they have,
        // their percentage is added to the next org (lets say 20% to make 50%). If that
        // limit hasn't been passed the second org will get the lead. And so on.
        // ?!?!?!?
        // This method favors the first Organization in the list (assuming query always return same order)
        // If total percentage passes 100% then the organization that pushes it over will get 
        // all leads for the rest of the month (as mod(x, 10) could never return 10+)
        // Any organizations after the one that pushes it past 100% won't get any
        for (ExternalLeadContactControl__c el : availableLeadsOrgs) {
            // Update percent count (shortcut using 10 as the picklist options are all sets of 10) 
            // ?!?!?!?
            // If turning PercentOfLeadsToAssignPicklist__c into percentage shouldn't it be divided by 100
            // The values are 10, 20, 30, etc to 100
            precentCount  = precentCount  + Integer.valueOf(el.PercentOfLeadsToAssignPicklist__c)/10;
            
            // Total count of opportunity with this grade
            // divided by 10, return the remainder
            // ?!?!?!?
            // Why?
            Integer remainder = math.mod(gradeCount, 10);
            
            //
            if (remainder <= precentCount) {
                assignLeadToVendor(o,el); 
                return;
            }
        }
        
        // Fall back to assigning Lead to WGU
        assignLeadToVendor(o, WGULead);
    }  

    /**
     * Send initial information to LeadQual
     */
    public static void sendInfoToLeadQual(Id CAREProfileID, String firstName, String lastName,
                                          String phone, string altPhone,  String programName, 
                                          String programCode, String college, String state,
                                          String zip, String ecName, String leadGrade ) {
        // ?!?!?!?
        // I'm not sure why these are included over others
        if (altPhone == null) {
            altPhone = '';
        }       
        if (programCode == null) {
            programCode = '';
        }
                                             
        // Data Formating For LeadQual
        // ?!?!?!?
        // I'm not sure this even matters, the colleges shouldn't get these values.
        // At least, not from the application form
        // Does it come over in this form on the inquiry form?
        if (college == 'Nursing') {
            college = 'Health Professions';
        }                                
        else if (college.contains('Education')) {
            college = 'Teacher\'s College';                                     
        }   
                                              
        // Setup post body
        String body = 'SalesForceID=' + EncodingUtil.urlEncode((String) CAREProfileID, 'UTF-8') +
            '&FirstName=' + EncodingUtil.urlEncode(firstName, 'UTF-8') +
            '&LastName=' + EncodingUtil.urlEncode(lastName, 'UTF-8') +
            '&PrimaryPhone=' + EncodingUtil.urlEncode(phone, 'UTF-8') +
            '&FirstName=' + EncodingUtil.urlEncode(firstName, 'UTF-8') +
            '&FirstName=' + EncodingUtil.urlEncode(firstName, 'UTF-8') +
            '&PrimaryPhone=' + EncodingUtil.urlEncode(phone, 'UTF-8') +
            '&SecondaryPhone=' + EncodingUtil.urlEncode(altPhone, 'UTF-8') +
            '&ProgramOfInterest=' + EncodingUtil.urlEncode(programName, 'UTF-8') +
            '&ProgramCode=' + EncodingUtil.urlEncode(programCode, 'UTF-8') +
            '&College=' + EncodingUtil.urlEncode(college, 'UTF-8') + 
            '&State=' + EncodingUtil.urlEncode(state, 'UTF-8') + 
            '&ZipCode=' + EncodingUtil.urlEncode(zip, 'UTF-8') + 
            '&CareProfileOwner=' + EncodingUtil.urlEncode(ecName, 'UTF-8') + 
            '&LeadGrade=' + EncodingUtil.urlEncode(leadGrade, 'UTF-8');
        
        postDataToURL(String.valueOf(Runtime__c.getValues('LeadQual')), body);
    }
    
    /**
     * Parse JSON on added tasks, send updates to LeadQual on appropriate ones
     *
     * What sends the JSON?
     *
     * ?!?!?!?
     * Seems like some of the logic could be handled in a more specific querry
     * That querry might get a little ugly though. Just seems silly to querry
     * two things and then run through a loop to attach the data together.
     */
    public static void sendStatusUpdateToLeadQualDecode(String taskListNewJSON) {
        // Transform JSON string into list of Tasks
        List<Task> jsonTasks = (List<Task>)JSON.deserialize(taskListNewJSON, List<Task>.class);
        
        // Get recordtype id for CAREforce Tasks
        Id careTaskId = [SELECT id 
                         FROM RecordType 
                         WHERE developerName = 'CAREforceTask' 
                         AND sObjectType = 'Task'].id;
        
        // Gather new tasks (as identified in JSON)
        List<Task> newTasks = [SELECT Id, LastModifiedDate, CallDisposition__c, EnrollmentNoteType__c,
                                        Whatid, WhoId, RecordTypeId 
                                 FROM Task
                                 WHERE id IN :jsonTasks 
                                 AND isDeleted = false 
                                 AND RecordTypeId = :careTaskId 
                                 ORDER BY LastModifiedDate DESC];
        
        // Filter task list to just ones attached to Opportunities
        // Add filtered values to various lists
        String opportunityPrefix = Schema.SObjectType.Opportunity.getKeyPrefix(); 
        List<Task> filteredTasks = new List<Task>();
        List<Id> opportunitiesWithNewTasks = new List<Id>();
        Map<Id,Id> taskToOpportunityIdMap = new Map<Id,Id>();
        for (Task task : newTasks) {
            // Only add to list if task is connected to Opportunty
            if (task.WhatId != null && ((String)task.WhatId).startsWith(opportunityPrefix)) {
                filteredTasks.add(task);
                opportunitiesWithNewTasks.add(task.whatId);
                taskToOpportunityIdMap.put(task.id, task.whatId);
            }
        }
        
        // Get ExternalLeadContactControl objects for opportunities in filtered list
        // ?!?!?!?
        // Seems like it would be easier to read if this querry was reversed
        // and it got ExternalLeadContactControl objects and the Opportunity they are attached to
        List<Opportunity> opportunityWithContactControl = [SELECT id, ExternalLeadContactControl__c, ExternalLeadContactControl__r.name
                                                           FROM Opportunity 
                                                           WHERE id in :opportunitiesWithNewTasks];
        
        // Loop through filtered tasks
        for(Task task: filteredTasks) {
            // Get opportunity attached to task
            Id opportunityId = taskToOpportunityIdMap.get(task.id);
            Opportunity activeOpportunity = null;
            
            // Find ExternalLeadContactControl attached to this opportunity using opportunity id
            for (Opportunity o: opportunityWithContactControl) {
                if (o.id == opportunityId) {
                    activeOpportunity = o;
                }
            }
            
            // If no matching opportunity, stop execution
            // ?!?!?!? 
            // Stop all execution? That seems extreme (if it is passing a bunch of these)
            if (activeOpportunity == null) {
                return;
            }
            
            // Opportunity is managed by LeadQual
            if (activeOpportunity.ExternalLeadContactControl__r.name == 'LeadQual') {
                // Send LeadQual a status update
                sendStatusUpdateToLeadQual(task.Whatid, task.CallDisposition__c, task.EnrollmentNoteType__c);
                
                // Should LeadQual continue to be updated?
                boolean b = leadQualContinueSendingStatus(task.CallDisposition__c);
                
                // If not, disconnect the lead from them
                if (!b) {
                    // Get LeadQualComplete Contact Control
                    // ?!?!?!?
                    // Why not just assign it back to WGU?
                    ExternalLeadContactControl__c leadQualComplete = [SELECT id 
                                                                      FROM ExternalLeadContactControl__c 
                                                                      WHERE name = 'LeadQualComplete'];
                    
                    // If it exists, assign opportunity to it
                    if (leadQualComplete != null) { 
                        activeOpportunity.ExternalLeadContactControl__c = leadQualComplete.id;
                        update activeOpportunity;
                    }
                }
            }
        }
    }
    
    /**
     * Standard determination of whether status messages should continue to be sent to leadQual
     * Broken out into a separate function do to the likelihood of later changes.
     */
    public static boolean leadQualContinueSendingStatus(String callDisposition) {
        if (callDisposition == 'Phone Attempt 1' || callDisposition == 'Phone Attempt 2' ||
            callDisposition == 'Phone Attempt 3' || callDisposition == 'Phone Attempt 4' ||
            callDisposition == 'Phone Attempt 5') {
            return true;
        }
        else {
            return false;
        }
    }  
     
    /**
     * Standardized method for sending status updates to LeadQual
     */
    public static void sendStatusUpdateToLeadQual(Id CAREProfileID, String callDisposition, String enrollmentNoteType) {
        // Make sure String values are strings (no null values)
        if (callDisposition == null) {
            callDisposition = '';
        }
        if (enrollmentNoteType == null) {
            enrollmentNoteType = '';
        }
        
        // Setup post body
        String body = 'SalesForceID=' + EncodingUtil.urlEncode((String) CAREProfileID, 'UTF-8') +
            '&CallDisposition=' + EncodingUtil.urlEncode(callDisposition, 'UTF-8') +
            '&EnrollmentNoteType=' + EncodingUtil.urlEncode(enrollmentNoteType, 'UTF-8');
        
        postDataToURL(String.valueOf(Runtime__c.getValues('LeadQual')), body);
    }
    
    //--------------------------------------
    // PAMs Integration
    //--------------------------------------
    
    /**
     * Handler to avoid preventable errors 
     *
     * Modified Oct 15 2013 1525 hrs by Tyler Smith
     */
    public static void addNewProgramVersions(String programsNewJSON) {
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled() || Test.isRunningTest()) {
            processAddNewProgramVersions(programsNewJSON);
        }
        else {
            asyncAddNewProgramVersions(programsNewJSON);
        }
    }
 
    /**
     * Future version of addNewProgramVersions
     */
    @Future
    public static void asyncAddNewProgramVersions(String programsNewJSON) {
        processAddNewProgramVersions(programsNewJSON);
    }
    
    /**
     * Now version of addNewProgramVersions
     *
     * ?!?!?!?
     * What trigger calls this?
     */
    private static void processAddNewProgramVersions(String programsNewJSON) {    
        // Get program list from Trigger
        List<WGUDegreeProgram__c> news = (List<WGUDegreeProgram__c>)JSON.deserialize(programsNewJSON, List<WGUDegreeProgram__c>.class);
        
        // Create list of programs in list that are active
        List<String> programCodes = new List<String>();
        for (WGUDegreeProgram__c program : news) {
            if (program.Active__c) {
                programCodes.add(program.Name);
            }
        }
        
        // Get MiddleEarth programs from pass programs that are active
        List<CAREProgramMiddleEarth__c> earths = [SELECT id, active__c, ApplicationTitle__c, BannerProgramCode__c,
                                                         InquiryProgram__c, ProgramGroups__c, CAREProgramCode__c, BannerProgramCode__r.Id, 
                                                         BannerProgramCode__r.Name, BannerProgramCode__r.CatalogTerm__c, Name
                                                  FROM CAREProgramMiddleEarth__c 
                                                  WHERE Active__c = true 
                                                  AND BannerProgramCode__r.Name in :programCodes 
                                                  AND BannerProgramCode__r.Active__c = true];
        
        // Create list of program versions being deactivated and inserted in their place
        List<CareProgramMiddleEarth__c> newRecords = new List<CareProgramMiddleEarth__c>();
        List<CareProgramMiddleEarth__c> existingRecords = new List<CareProgramMiddleEarth__c>();
        for (WGUDegreeProgram__c program : news) {
            // If program isn't active don't bother
            if (program.Active__c == null || !program.Active__c) {
                continue;
            }
        
            // Search through existing programs
            for (CareProgramMiddleEarth__c middleEarth : earths) {
                // Name matches and it is a newer version of the Program
                if (middleEarth.BannerProgramCode__r.Name == program.Name && program.CatalogTerm__c > middleEarth.BannerProgramCode__r.CatalogTerm__c) {
                    // Duplicate any program that is getting updated
                    CareProgramMiddleEarth__c replacement = middleEarth.clone();
                    
                    // Connect new Middle earth to new Banner program
                    replacement.BannerProgramCode__c = program.Id;
                    newRecords.add(replacement);
                    
                    // Deactivate old Middle earth program (linked to old Banner program)
                    middleEarth.active__c = false;
                    existingRecords.add(middleEarth);
                }
            }
        }
        
        // Save all changes
        update existingRecords;
        insert newRecords;
    }
    
    //--------------------------------------
    // Banner Sync Pieces
    //--------------------------------------
    
    // The integration team is working on an update to this system which should remove 
    // the need for this code. Anything that remains will need to move into their classes.
    
    //Move the values produced by push to Banner back into the Contact Object.
    @Future
    public static void updateValuesFromPushToBanner(String taskListNewJSON, String taskListOldJSON) {
        // Only run once in a an execution thread to prevent recursion.
              System.debug('updateValuesFromPushToBanner' + Limits.getFutureCalls());
        If (CAREforceUtility.updatePushToBannerInProgress)
            return;
    
        CAREforceUtility.updatePushToBannerInProgress = true;
        List<SynchronizeToBanner__c> triggerNews = (List<SynchronizeToBanner__c>)JSON.deserialize(taskListNewJSON, List<SynchronizeToBanner__c>.class);
        List<SynchronizeToBanner__c> triggerOlds = (List<SynchronizeToBanner__c>)JSON.deserialize(taskListOldJSON, List<SynchronizeToBanner__c>.class);
        
        List<String> opportunityIds = new List<String>();
        List<String> syncIds = new List<String>();
        
        
        for (Integer i = 0; i < triggerNews.size(); i++) {
            // If PIDM is being set then the values have been returned from the push to banner process.
            if (triggerNews[i].PidmIn__c != triggerOlds[i].PidmIn__c || triggerNews[i].ReSynchronizeInSalesforce__c == true) {
                opportunityIds.add(triggerNews[i].ActiveOpportunity__c);
                syncIds.add(triggerNews[i].Id);
            }
        }
        
        List<Opportunity> opportunities = [SELECT id, Account.Id, Account.PIDM__c, StudentContact__r.PIDM__C, StudentContact__r.WGUEmail__c, 
                                                  StudentContact__r.StudentId__c, StudentContact__r.My_WGU_Email__c, PIDM__c
                                              FROM Opportunity WHERE Id = :opportunityIds LIMIT 10000];

        List<Contact> contactToUpdates = new List<Contact>();
        List<Account> accountToUpdates = new List<Account>();
        List<SynchronizeToBanner__c> syncsToUpdate = [SELECT id, LastSynchronizedIn__c, SynchronizationError__c, ReSynchronizeInSalesforce__c FROM SynchronizeToBanner__c WHERE id = :syncIds];
        
        Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
        
        for (Opportunity opp : opportunities) {
            opportunityMap.put(opp.Id, opp);
        }
        
        Map<String, SynchronizeToBanner__c> syncsMap = new Map<String, SynchronizeToBanner__c>();
        
        for (SynchronizeToBanner__c sync : syncsToUpdate) {
            syncsMap.put(sync.Id, sync);
        }
        
        for (SynchronizeToBanner__c triggerNew : triggerNews) {
            Opportunity opp = opportunityMap.get(triggerNew.ActiveOpportunity__c);
            
            if (opp != null) {
                opp.StudentContact__r.PIDM__c = triggerNew.PIDMIn__c;
                opp.StudentContact__r.StudentId__c = triggerNew.BannerIdIn__c;
                opp.StudentContact__r.WGUEmail__c = triggerNew.WGUEmailIn__c.replace('my.wgu.edu', 'wgu.edu');
                opp.StudentContact__r.My_WGU_Email__c = triggerNew.WGUEmailIn__c;
                opp.StudentContact__r.Status__c = 'IN';
                contactToUpdates.add(opp.StudentContact__r);
                
                opp.Account.PIDM__c = triggerNew.PIDMIn__c;
                accountToUpdates.add(opp.Account);
                opp.PIDM__c = triggerNew.PIDMIn__c;
                
                syncsMap.get(triggerNew.Id).SynchronizationError__c = null;
                syncsMap.get(triggerNew.Id).ReSynchronizeInSalesforce__c = false;
            }
        }
        
        try {
            update contactToUpdates;
        } catch(Exception ex) {
            for (SynchronizeToBanner__c sync : syncsToUpdate) {
                sync.SynchronizationError__c = ex.getMessage();
            }
        }
        
        try {
            update accountToUpdates;
        } catch(Exception ex) {
            for (SynchronizeToBanner__c sync : syncsToUpdate) {
                sync.SynchronizationError__c = ex.getMessage();
            }
        }        
        
        update opportunities;
        
        // Last Synchronized must be after Contact Last modified to accurately set current status.
        for (SynchronizeToBanner__c sync : syncsToUpdate) {
            sync.LastSynchronizedIn__c = Datetime.now();
        }
        
        update syncsToUpdate;
    }    
    
    public static void processCAREProfilesForSynchronization(String taskListNewJSON) {    
        List<Opportunity> opportunities = (List<Opportunity>)JSON.deserialize(taskListNewJSON, List<Opportunity>.class);
    
        Set<String> ids = new Set<String>();
        Map<String, String> names = new Map<String, String>();
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();
        
        for (Opportunity opp : opportunities) {
            ids.add(opp.Id);
            names.put(opp.Id, opp.Name);
            oppsMap.put(opp.Id, opp);
        }
    
        List<SynchronizeToBanner__c> syncs = [SELECT ID, ActiveOpportunity__c FROM SynchronizeToBanner__c WHERE ActiveOpportunity__c = :ids];
        
        for (SynchronizeToBanner__c sync : syncs) {
            ids.remove(sync.ActiveOpportunity__c);
        }
        
        List<SynchronizeToBanner__c> newSyncs = new List<SynchronizeToBanner__c>();
        
        for (String id : ids) {    
            SynchronizeToBanner__c sync = new SynchronizeToBanner__c(Name=names.get(id), ActiveOpportunity__c=id);
            
            Opportunity opp = oppsMap.get(id);
            
            if (opp.CAREStatus__c != null && opp.CAREStatus__c.contains('NEVR')) {
                sync.ProcessedEWBRoll__c = DateTime.now();
            }   
                        
            newSyncs.add(sync);
        }
        
        insert newSyncs;
    }
    
    /**
     * The purpose of this funtion is to trigger the formula field to update status on change of source objects. Now updates are performed
     * and this function should only result in one query being executed on any of the triggers involved.
     */
    public static void updateSynchronizeToBanner(String type, Set<String> recordId) {
        if (Limits.getFutureCalls() > 5 || System.isFuture() || System.isBatch() || System.isScheduled() ) {
            updateSynchronizeToBannerSync(type, recordid);
        }
        else {
            updateSynchronizeToBannerAsync(type, recordId);
        }
    }
     
    @Future
    public static void updateSynchronizeToBannerAsync(String type, Set<String> recordId) {
        System.debug('updateSynchronizeToBanner' + Limits.getFutureCalls());
        updateSynchronizeToBannerSync(type, recordid);
    }
      
    public static void updateSynchronizeToBannerSync(String type, Set<String> recordId) {
        List<SynchronizeToBanner__c> syncs = null;
        
        if (type == 'Contact') {
            syncs = [SELECT Id, CurrentStatus__c FROM SynchronizeToBanner__c WHERE ActiveOpportunity__r.StudentContact__c = :recordId];
        }        
    
        if (type == 'Opportunity') {
            syncs = [SELECT Id, CurrentStatus__c FROM SynchronizeToBanner__c WHERE ActiveOpportunity__c = :recordId];
        }
        
        if (type == 'StudentAttributes') {
            syncs = [SELECT Id, CurrentStatus__c FROM SynchronizeToBanner__c WHERE ActiveOpportunity__r.StudentAttributes__c = :recordId];
        }
        
        if (type == 'SynchronizeToBanner') {
            syncs = [SELECT Id, CurrentStatus__c FROM SynchronizeToBanner__c WHERE Id = :recordId];
        }        
    }
    
    //--------------------------------------
    // Careforce Case Creation
    //--------------------------------------
    
    // These cases are slated for deletion, because of that they have not been altered
    // I do need to figure out if the trigger for them is still running.
    
    public static void createCAREforceCase (List <String> opportunityIds, List <String> feedBodies, List <String> feedItemIds){
    
        if(Test.isRunningTest()){
            createCAREforceCaseProcess(opportunityIds, feedBodies, feedItemIds);
        }else{
            try {
                createCAREforceCaseAsync(opportunityIds, feedBodies, feedItemIds);
            } catch (System.AsyncException e) {
                //Future methods cannot be called from within future methods
                //if this method has been invoked from another Trigger's future method,
                //it must process the triggered records synchronously
                if ( e.getMessage().contains( 'Future method cannot be called from a future' ) ) {
                  createCAREforceCaseProcess(opportunityIds, feedBodies, feedItemIds);
                } else {
                  throw e;
                }
            }
        }
    
    }
    
    @Future 
    public static void createCAREforceCaseAsync(List <String> opportunityIds, List <String> feedBodies, List <String> feedItemIds){
        createCAREforceCaseProcess(opportunityIds, feedBodies, feedItemIds);
    }
    
    public static void createCAREforceCaseProcess(List <String> opportunityIds, List <String> feedBodies, List <String> feedItemIds){
        String oppKeyPrefix = Opportunity.sObjectType.getDescribe().getKeyPrefix();
        List<Case> cases = new List<Case>();
        List<FeedComment> comments = new List<FeedComment>();
        
        for (integer i = 0; i<opportunityIds.size(); i++) {
            String parentId = opportunityIds[i];
            if ((parentId.startsWith (oppKeyPrefix)) && (feedBodies[i].contains('#CAREforceHelp')))
            {
                Case newCase = new Case ( 
                    Subject = 'CAREforce Help Team',
                    Status = 'Open',
                    Priority = 'Medium',
                    Origin = 'Web',
                    CAREProfile__c = opportunityIds[i],
                    EnrollmentCounselor__c = [SELECT Owner.Id FROM Opportunity WHERE Id = :parentId].Owner.Id,
                    Description = feedBodies[i],
                    ContactId = [SELECT StudentContact__r.Id FROM Opportunity WHERE Id = :parentId].StudentContact__r.Id,
                    RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'CAREforce Team'].Id,
                    OwnerId = [SELECT QueueId  FROM QueueSobject WHERE sobjecttype ='Case' AND Queue.Name = 'CAREforce Team'].QueueId 
                );
                
                cases.add(NewCase);
                    
                FeedComment fcomment = new FeedComment(
                    FeedItemId = feedItemIds[i],
                    CommentBody = 'The CAREforce Team has received your request and are working hard for you; once this issue is resolved or if the CAREforce Team has further questions you will be notified!'
                );
                
                comments.add(fcomment);
            }
        
        }
        
        insert cases;
        insert comments;
    }
}