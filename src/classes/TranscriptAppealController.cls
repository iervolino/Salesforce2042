/*
This Controller is for TranscriptAppeal VF  Student facing page used by Transcripts.
Author- Bhavadeep Raavi
No Sharing rules are enforced, the current sharing rules remain in effect
    -Modified by Will Slade 12/1/12 to make rest adapter calls so student can directly modify a case
        rather than modifying a student case which updates the case via trigger
    -Modified by Will Slade 2/11/13 so the name of the student case is used in the URL rather than the SF ID
    -Modified by Tyler Smith 1/22/2014 to correct bug that was preventing comments in the form from saving to the case.
    -Modified by Tyler Smith 4/7/2014 to improve student interactions with the form

For testing:
- create a test record making sure that it has a studentId on contact and a user record exists for the record (needed to trigger case creation)
- You might need to add the domain to the remote site settings depending on environment
- Login as User
- Page URL is https://srm--devfull--c.cs14.visual.force.com/apex/TranscriptAppeal?Name=A-000003570 (switch Name to match Student Case Name)
*/

public with sharing class TranscriptAppealController{
    private final StudentCase__c stdCase; // requested student case
    private final Case thisCase; // case the student case is attached to
    private final List<Case> cases; // All cases this student case links to (should only every be one)
    
    private StudentCase__c sc; // requested student case selected by Id instead of Name (only used in controller)
    private StudentCase__c contrStdCase { get;set; } // Same as sc but used in VF page
    
    String stdCaseId; // Student Case Id (From query on URL parameter)
    String stdCaseName; // Studnet Case Name (From URL parameter)
    
    // Form management variables
    public Boolean appealflag{get;set;} // Form is an evaluation appeal form (show only these pieces)
    public Boolean exclusionflag{get;set;} // Form is an transcript exclusion form (show only these pieces)
    public Boolean contactUserFlag{get;set;} // Should anything on the forms be displayed?
    public Integer rowFlg{get;set;} // Maximum number of rows to show on appeals form (Could be done with hard number since that is what the code enforces?)
    public Boolean saveFlag{get;set;} // Can the save button be clicked
    
    // Appeal Specific Variables
    public List<StdAdditionalInfo> TranscriptsAppealList{get;set;} // List of appeal rows
    List<Attachment> appealAttachments{
        get
        {
            if (appealAttachments == null)
            {
                appealAttachments = new List<Attachment>();
            }
            return appealAttachments;
        }
        set;} // List of attachments on the appeal form
    
    // Exclusion Specific Variables
    public List<StdExclusionInfo> TranscriptsExclusionList{get;set;} // List of exclusion rows
    List<Attachment> exclusionAttachments{
        get
        {
            if (exclusionAttachments == null)
            {
                exclusionAttachments = new List<Attachment>();
            }
            return exclusionAttachments;
        }
        set;} // list of attachments on the exclusions form
    
    public TranscriptAppealController(ApexPages.StandardController controller) 
    {
        // Get identifying attribute from URL (switched from id to name, see note from Will)
        stdCaseName = Apexpages.currentpage().getParameters().get('Name');
        
        system.debug('Passed Name');
        system.debug(stdCaseName);
        
        // For test grab any record
        if (test.isRunningTest())
        {
            stdCase = [SELECT Id, Contact__r.StudentID__c, Case__c, StudentCaseReason__c, ServiceDescription__c, FinancialAid__c, Contact__r.name, Contact__r.pidm__c, StudentEmail__c, Comments__c 
                       FROM StudentCase__c LIMIT 1];
        }
        // Otherwise get the requested student case
        else
        {
            stdCase = [SELECT Id, Contact__r.StudentID__c, Case__c, StudentCaseReason__c, InstitutionName__c, FinancialAid__c, ServiceDescription__c, Contact__r.name, Contact__r.pidm__c, StudentEmail__c, Comments__c 
                       FROM StudentCase__c WHERE Name = :stdCaseName LIMIT 1];
        }
        
        system.debug('stdCase');
        system.debug(stdCase);
        
        // Get pidm of currently loggedin user
        string userPidm = [select pidm__c from User where id=:UserInfo.getUserId()].pidm__c;
        
        system.debug('UserId Loggedin');
        system.debug(UserInfo.getUserId());
        
        // Save student case id to object
        stdCaseId = stdCase.Id;
        
        // Get Student case again using the Id (why querry it again?)
        List<StudentCase__c> scsList = [SELECT Id, Contact__r.StudentID__c, Case__c, StudentCaseReason__c, InstitutionName__c, ServiceDescription__c, Contact__r.name, Contact__r.pidm__c, StudentEmail__c,
                                               Comments__c, FinancialAid__c
                                        FROM StudentCase__c where id = :stdCaseId 
                                        LIMIT 1];
        
        system.debug('StudentCase List');
        system.debug(scsList);
        
        // Don't proceed if no case exists
        if (scsList.size() > 0)
        {
            // Save case to object (twice?)
            contrStdCase = scsList[0];
            sc = scsList[0];
            
            // Get case that this student case is connected to (through rest adapter if possible otherwise through database query)
            String queryString = 'SELECT Id, Reason, ServiceDescription__c, Status FROM Case WHERE Id = \'' + sc.Case__c + '\'';
            //String queryString = 'SELECT Id FROM Case WHERE Id = \'' + sc.Case__c + '\'';
            system.debug('Get Cases');
            system.debug(queryString);
            //cases = [SELECT Id, Reason, ServiceDescription__c, Status FROM Case WHERE Id = :sc.Case__c];
            
            //RestAdapter ra = new RestAdapter();
            RestAdapter ra = null;
            cases = !test.isRunningTest() && ra != null ? (List<Case>)ra.queryObjects(queryString) : (List<Case>)Database.query(queryString);                                  
            
            system.debug('Returned Cases');
            system.debug(cases);
            
            // Case exists
            if (cases.size() > 0)
            {
                system.debug('Grab case');
                // Save case to object
                thisCase = cases[0];
            
                system.debug('After Case assignment');
                
                // Ensure case is attached to this logged in user and that it is open for them to edit
                /*(if (sc.Contact__c != null && sc.Contact__r.Pidm__c != null &&
                    sc.Contact__r.Pidm__c == userPidm &&
                    thisCase.status == 'Open: Student Response Needed')
                {*/
                    // Appeal page pieces
                    if (thisCase.Reason == 'Appeal')
                    {
                        appealflag = true;
                        exclusionflag = false;
                        contactUserFlag = true;
                        
                        setInitialTranscriptsAppealList(thisCase.ServiceDescription__c);
                    }
                    // Exclusion page pieces
                    else if(thisCase.Reason == 'Exclusion' )
                    {
                        appealflag = false;                    
                        exclusionflag = true;
                        contactUserFlag = true;
                        
                        TranscriptsExclusionList = new List<StdExclusionInfo>();
                        TranscriptsExclusionList.add( new StdExclusionInfo() );
                    }                                        
                /*}
                else
                {
                    system.debug('No Permission');
                
                    appealflag = false;                    
                    exclusionflag = false;
                    contactUserFlag = false;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unfortunately, this application has already been submitted or you don’t have the required permission to access this record.'
                        + ' Please contact your enrollment counselor or the Transcript Evaluation Department at 1-877-435-7948 x 3120.'));                            
                }*/
            }
            // Otherwise, hide everything and give error message
            else
            {
                system.debug('No Case');
            
                appealflag = false;                    
                exclusionflag = false;
                contactUserFlag = false;
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unfortunately, this application has already been submitted or you don’t have the required permission to access this record.'
                //    + ' Please contact your enrollment counselor or the Transcript Evaluation Department at 1-877-435-7948 x 3120.'));                            
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No Cases. Query: ' + queryString));                            
            }
        }
        else {
            system.debug('No Student Case');
            
            appealflag = false;                    
            exclusionflag = false;
            contactUserFlag = false;
            
            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'The form that you are attempting to request does not exist.'
            //        + ' Please contact your enrollment counselor or the Transcript Evaluation Department at 1-877-435-7948 x 3120.'));                            
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'No student case exists with this identifier'));                            
        }
    }
    
    private void setInitialTranscriptsAppealList(String serviceDescription)
    {
        // Don't assume there are any rows to begin
        TranscriptsAppealList = new List<StdAdditionalInfo>();
        rowFlg = 0;
        
        // Is there information already in the service description (student has partially fillout form already)
        if (serviceDescription != null && serviceDescription != '' && serviceDescription != '<br>') {
            
            // GET ATTACHMENTS
            
            List<String> tsaDesc = serviceDescription.split('\\n<br>');
            for (String line : tsaDesc)
            {
                // Split line into fields
                List<String> fields = line.split(', ');
                
                if (fields.size() == 9) {
                    // Create StdAdditionalInfo object
                    StdAdditionalInfo appealRow = new StdAdditionalInfo();
                    
                    // Add fields to object
                    appealRow.inName = fields[0];
                    appealRow.wguCrsCode = fields[1];
                    appealRow.wguCrsTitle = fields[2];
                    appealRow.inCrsCode = fields[3];
                    appealRow.inCrsTitle = fields[4];
                    appealRow.yearAttended = fields[5];
                    appealRow.selGrades = fields[6].trim(); // Invisible white space has to be removed for it to display correctly in form
                    appealRow.selCreditHrs = fields[7].trim(); // Invisible white space has to be removed for it to display correctly in form
                    appealRow.canAddAttachment = false;
                    if (fields[8].equals('(no attachment)')) 
                    {
                        fields[8] = '';
                        appealRow.canAddAttachment = true;
                    }
                    appealRow.attachmentName = fields[8];
                    
                    TranscriptsAppealList.add( appealRow );
                }
                rowFlg++;
            }
        }
        else
        {
            // Create one for the form to load with
            TranscriptsAppealList.add( new StdAdditionalInfo() );      
            rowFlg = 1;
        }
    }
    
    public StudentCase__c getContrStdCase()
    {
        return contrStdCase;
    }
    
    // Add a  new row and remove a row for Appeal
    public PageReference incrementRowFlg()
    {
        // Save current state of rows
        // if there are uploads that need to happen they need to happen now and clear their extra weight
        // in order for the page to load
        // false indicates that this is not a form submission (but a mid process)
        saveRows();
        
        if(rowFlg < 20)
        {
            StdAdditionalInfo sai = new StdAdditionalInfo();
            TranscriptsAppealList.add(sai);
            rowFlg = rowFlg + 1;
        }
        
        return null;
    }
    
    // Remove last line
    public PageReference decrementRowFlg()
    {
        String attachmentName;
        
        system.debug('Row Flag');
        system.debug(rowFlg);
        if(rowFlg > 0)
        {
            rowFlg = rowFlg - 1;
            system.debug('Row Flag 2');
            system.debug(rowFlg);
            attachmentName = TranscriptsAppealList.get(rowFlg).attachmentName;
            TranscriptsAppealList.remove(rowFlg);
            
        }
        
        // They've set the form back to starting condition
        // Add one row for them to proceed.
        if (rowFlg == 0) {
            TranscriptsAppealList.add( new StdAdditionalInfo() );      
            rowFlg = 1;
        }
        
        // Save current state of rows
        // if there are uploads that need to happen they need to happen now and clear their extra weight
        // in order for the page to load (done after to avoid uploading documents that shouldn't be)
        // false indicates that this is not a form submission (but a mid process)
        saveRows();
        
        // Delete attachment associated with deleted row
        if (attachmentName != null && attachmentName != '') 
        {
            // attachments
            List<Attachment> uploadedDocuments = [SELECT Id FROM Attachment WHERE ParentId = :thisCase.Id AND Name = :attachmentName LIMIT 1];
            
            if (uploadedDocuments.size() > 0) 
            {
                Attachment doc = uploadedDocuments[0];
                
                delete doc;
            }
        }
        
        return null;
    }
    
    private void saveRows() 
    {
        String sDesc = '';
        
        if (appealflag) {
            system.debug('Appeal (saveRows)');
            for(StdAdditionalInfo tsa:TranscriptsAppealList)
            {
                sDesc = sDesc + getRowDesc(tsa);
                // Add Attachment to upload queue
                if(tsa.appealAttachment != null )
                {
                    queueAttachmentUpload(tsa.appealAttachment);
                }
            }
        }
        else if (exclusionflag) {
            system.debug('Exclusion (saveRows)');
            for(StdExclusionInfo tsae:TranscriptsExclusionList)
            {
                if(tsae.finAid != null && tsae.finAid)
                {
                    sDesc = sDesc + 'Financial Aid = true' + '\n' + ' , ';    
                }
                else
                {
                    sDesc = sDesc + 'Financial Aid = false' + '\n' + ' , ';
                }
                   
                if(tsae.selDegreeEarned != null && tsae.selDegreeEarned != '')
                {
                    sDesc = sDesc + tsae.selDegreeEarned + '\n' + ' , ';    
                }
                
                if(tsae.selReasonforExclusion != null && tsae.selReasonforExclusion != '')
                {
                    sDesc = sDesc + tsae.selReasonforExclusion + '\r\n' + '<br>';    
                }
                
                // Add Attachment to upload queue
                if(tsae.exclusionAttachment != null)
                {
                    queueAttachmentUpload(tsae.exclusionAttachment);
                }             
            }
        }
        else {
            System.debug( LoggingLevel.ERROR, 'Unable to save.');
        }
        
        thisCase.ServiceDescription__c = sDesc;
        
        //update thisCase;
        //RestAdapter ra = new RestAdapter();
        RestAdapter ra = null;
        if ( !test.isRunningTest() && ra != null ) 
        {            
            //use RestAdapter to bypass license restriction on customer accounts updating cases
            cases[0] = thisCase;
            String responseXML = ra.updateObjects( cases ); 
            if ( responseXML.contains( '<success>false</success>' ) ) 
            {
                System.debug( LoggingLevel.ERROR, 'Transcript Appeal Case Update Failure: ' + EncodingUtil.urlEncode(responseXML,'UTF-8') );
            }
        } 
        else 
        {
            System.debug('TESTING');
            update thisCase;
        }             
        
        // Insert statements have to happen after callouts like the RestAdapter
        uploadAttachments();
    }
    
    private String getRowDesc(StdAdditionalInfo tsa) 
    {
        String sDesc = '';
        
        sDesc = sDesc + tsa.inName + '\n, ';
        sDesc = sDesc + tsa.wguCrsCode + '\n, ';
        sDesc = sDesc + tsa.wguCrsTitle + '\n, ';
        sDesc = sDesc + tsa.inCrsCode + '\n, ';
        sDesc = sDesc + tsa.inCrsTitle + '\n, ';
        sDesc = sDesc + tsa.yearAttended + '\n, ';
        sDesc = sDesc + tsa.selGrades + '\n, ';
        sDesc = sDesc + tsa.selCreditHrs + '\n, ';
        
        // New attachment
        if(tsa.appealAttachment.name != null && tsa.appealAttachment.name != '')
        { 
            sDesc = sDesc + tsa.appealAttachment.name + '\n<br>';                      
        }
        // Existing Attachment
        else if (!tsa.canAddAttachment)
        {
            sDesc = sDesc + tsa.attachmentName + '\n<br>'; 
        }
        else
        {
            sDesc = sDesc + '(no attachment)\n<br>'; 
        }
        
        return sDesc;
    }
    
    private void queueAttachmentUpload(Attachment uploadedFile) 
    {
        system.debug('queueAttachmentUpload');
        
        // Only queue if there is a file to upload
        if (uploadedFile.body != null) 
        {
            system.debug('Have uploaded file (queueAttachmentUpload)');
        
            uploadedFile.parentId = thisCase.Id;
            
            // insert uploadedFile; cannot call insert before external callouts
            //(in theis case the RestAdaptor) so it has to be delayed
            if (appealflag) {
                system.debug('Appeal (queueAttachmentUpload)');
                appealAttachments.add(uploadedFile);
            }
            else if (exclusionflag) {
                system.debug('Exclusion (queueAttachmentUpload)');
                exclusionAttachments.add(uploadedFile);
            }
            else {
                System.debug( LoggingLevel.ERROR, 'Unable to save file for upload.');
            }
        }
    }
    
    // Insert into Salesforce
    private void uploadAttachments()
    {
        system.debug('uploadAttachments');
        
        try
        {
            // Are there Attachments
            if(appealAttachments != null && appealAttachments.size() > 0 && !appealAttachments.isEmpty())
            {
                system.debug('Appeal (uploadAttachments)');
                system.debug(appealAttachments);
                // Upload attachments
                insert appealAttachments;
            }
            
            // Are there Attachments
            if(exclusionAttachments != null && exclusionAttachments.size() > 0 && !exclusionAttachments.isEmpty())
            {
                system.debug('Exclusion (uploadAttachments)');
                system.debug(exclusionAttachments);
                // Upload attachments
                insert exclusionAttachments;
            }
        }
        catch(DMLException e)
        {
            // TODO: Remove surfacing of Salesforce error
            String message = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                message += e.getDmlMessage(i); 
            }
            System.debug( LoggingLevel.ERROR, 'Unable to upload attachment due to permissions.' + message);
        }
        finally {
            if (appealflag) {
                for(StdAdditionalInfo tsa:TranscriptsAppealList)
                {
                    // Remove document contents from form
                    tsa.appealAttachment.body = null;
                }
            }
            else if (exclusionflag) {
                for(StdExclusionInfo te:TranscriptsExclusionList)
                {
                    // Remove document contents from form
                    te.exclusionAttachment.body = null;
                }
            }
            
            // Clear list
            appealAttachments = null;
            exclusionAttachments = null;
            
            system.debug('Cleared attachments on form');
        }
    }
    
    // Send to OnBase
    private void sendAttachmentsToOnBase () 
    {
        // Get attachments
        List<Attachment> uploadedDocuments = [SELECT Name, Body FROM Attachment WHERE ParentId = :thisCase.Id];
        
        // Are there Attachments
        if(uploadedDocuments != null && uploadedDocuments.size() > 0 && !uploadedDocuments.isEmpty())
        {
            // TODO Uncomment sending documents to OnBase
            //OnbaseAttachmentUtility.sendToOnbase(uploadedDocuments, sc.Contact__r.StudentID__c);
        }
        
        uploadedDocuments = null;
    }
    
    // Save on Appeal Block
    public PageReference saveAppeal()
    {
        Boolean errorMsgFlag = false;
        
        if(stdCaseId != null && stdCaseId != '' && thisCase != null)
        {
            // Validate Form
            for(StdAdditionalInfo tsa:TranscriptsAppealList)
            {
                // Institution name is required
                if (tsa.inName == null || tsa.inName == '')
                {
                    errorMsgFlag = true;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Institution Name is required'));     
                }
                
                // WGU Course Title is required
                if(tsa.wguCrsTitle == null || tsa.wguCrsTitle == '')
                {
                    errorMsgFlag = true;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'WGU Course Title is required'));     
                }

                // Institution Course code is required
                if(tsa.inCrsCode == null || tsa.inCrsCode == '')
                {
                    errorMsgFlag = true;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Institution Course Code is required'));     
                }
                
                // Institution Course Title is required
                if(tsa.inCrsTitle == null || tsa.inCrsTitle == '')
                {
                    errorMsgFlag = true;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Institution Course Title is required'));                         
                }
                
                // Year Course addended is required to be a number
                try
                {
                    Integer.valueOf(tsa.yearAttended);
                }
                catch(Exception e)
                {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Year should be number'));     
                    errorMsgFlag = true;
                }
                
                // If errors occured then display messages and don't proceed
                if (errorMsgFlag == true && !test.isRunningTest())
                {
                    return null;
                }
            }
            
            // Add comments to this case
            thisCase.RequestComments__c = contrStdCase.Comments__c;
            
            // ADD FLAG TO LOCK THIS RECORD FROM BEING EDITED BY STUDENT
            thisCase.Status = 'Open: WGU Response Needed / In Progress';
            
            // Save contents (done after other edits so that they go through)
            saveRows();
            
            // Send documents to OnBase
            sendAttachmentsToOnBase();
            
            // Give success message
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Your request was successfully submitted. Please allow 3-5 business days to receive a reply.')); 
            
            // Disable save button
            saveFlag = true;
            
            // Disable loading of sections
            appealflag = false;                    
            exclusionflag = false;
            contactUserFlag = false;
        }
        
        return null;
    }
        
    // Save Exclusion
    public PageReference saveExclusion()
    {
        if(stdCaseId != null && stdCaseId != '')
        {
            // Validate form : nothing to validate (all drop downs require selections)
            
             // Add comments to this case
            thisCase.RequestComments__c = contrStdCase.Comments__c;
            
            // ADD FLAG TO LOCK THIS RECORD FROM BEING EDITED BY STUDENT
            thisCase.Status = 'Open: WGU Response Needed / In Progress';
            
            // Save contents (done after other edits so that they go through)
            saveRows();
            
            // Send documents to OnBase
            sendAttachmentsToOnBase();
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Your request was successfully submitted. Please allow 3-5 business days to receive a reply.'));  
            
            // Disable save button
            saveFlag = true;
            
            // Disable loading of sections
            appealflag = false;                    
            exclusionflag = false;
            contactUserFlag = false;
        }         
        return null;    
    }
        
    public PageReference cancel()
    {
        PageReference pf = new PageReference('https://my.wgu.edu'); 
        pf.setRedirect(true); 
        return pf;
    }
      
    // Single row on appeal form
    public class StdAdditionalInfo
    {
        public String inName{
            get{
                if (inName == null) {inName = '';}
                return inName;
            }set;
        }
        public String wguCrsCode{
            get{
                if (wguCrsCode == null) {wguCrsCode = '';}
                return wguCrsCode;
            }set;
        }
        public String wguCrsTitle{
            get{
                if (wguCrsTitle == null) {wguCrsTitle = '';}
                return wguCrsTitle;
            }set;
        }
        public String inCrsCode{
            get{
                if (inCrsCode == null) {inCrsCode = '';}
                return inCrsCode;
            }set;
        }
        public String inCrsTitle{
            get{
                if (inCrsTitle == null) {inCrsTitle = '';}
                return inCrsTitle;
            }set;
        }
        public String yearAttended{
            get{
                if (yearAttended == null) {yearAttended = '';}
                return yearAttended;
            }set;
        }
        
        public String selGrades{get;set;}
        public String selCreditHrs{get;set;}
        
        public String attachmentName{
            get{
                if ((attachmentName == null || attachmentName == '') && appealAttachment != null) 
                {
                    attachmentName = appealAttachment.name;
                }
                return attachmentName;
            }set;}
        
        public Boolean canAddAttachment{
            get{
                canAddAttachment = false;
                if (attachmentName == null || attachmentName == '') {
                    canAddAttachment = true;
                }
                return canAddAttachment;
            }set;
        }
        
        public List<SelectOption> grade{
            get
            {
                grade = new List<SelectOption>();
                
                grade.add( new SelectOption('','None') );
                grade.add( new SelectOption('A','A') );
                grade.add( new SelectOption('A-','A-') );
                grade.add( new SelectOption('B+','B+') );
                grade.add( new SelectOption('B','B') );
                grade.add( new SelectOption('B-','B-') );
                grade.add( new SelectOption('C+','C+') );
                grade.add( new SelectOption('C','C') );
                grade.add( new SelectOption('C-','C-') );
                grade.add( new SelectOption('Pass','Pass') );
                
                return grade;
            }
            set;
        }
        
        public List<SelectOption> creditHrs{
            get
            {
                creditHrs = new List<SelectOption>();
                
                creditHrs.add( new SelectOption('','None') );
                creditHrs.add( new SelectOption('>3','>3') );
                creditHrs.add( new SelectOption('3','3') );
                creditHrs.add( new SelectOption('2','2') );
                creditHrs.add( new SelectOption('1','1') );
                creditHrs.add( new SelectOption('<1','<1') );
                
                return creditHrs;
            }
            set;
        }
        
        public Attachment appealAttachment
        {
            get 
            {
                if (appealAttachment == null)
                {
                    appealAttachment = new Attachment();
                }
                return appealAttachment;
            }
            set;
        }         
    }
    
    // Single row on exclusion form (only has one row now)
    public class StdExclusionInfo
    {
        public String inName{get;set;}
        public Boolean finAid{get;set;}
        public String selDegreeEarned{get;set;}
        public String selReasonforExclusion{get;set;}
        
        public List<SelectOption> degreeEarned{
            get
            {
                degreeEarned = new List<SelectOption>();
                
                degreeEarned.add( new SelectOption('No Degree Earned','No Degree Earned') );
                degreeEarned.add( new SelectOption('Associate','Associate') );
                degreeEarned.add( new SelectOption('Bachelor','Bachelor') );
                degreeEarned.add( new SelectOption('Master','Master') );
                degreeEarned.add( new SelectOption('Doctorate','Doctorate') );
                degreeEarned.add( new SelectOption('Other','Other') );
                
                return degreeEarned;
            }
            set;
        }
        
        public List<SelectOption> reasonforExclusion{
            get
            {
                reasonforExclusion = new List<SelectOption>();
                
                reasonforExclusion.add( new SelectOption('No valid transfer credits','No valid transfer credits') );
                reasonforExclusion.add( new SelectOption('School Not Accredited','School Not Accredited') );
                reasonforExclusion.add( new SelectOption('No coursework completed','No coursework completed') );
                reasonforExclusion.add( new SelectOption('School cannot locate transcript','School cannot locate transcript') );
                reasonforExclusion.add( new SelectOption('Already met transfer requirements through previously submitted transcript(s)','Already met transfer requirements through previously submitted transcript(s)') );
                reasonforExclusion.add( new SelectOption('High School Diploma/International Baccalaureate (Attachment not required)','High School Diploma/International Baccalaureate (Attachment not required)') );
                reasonforExclusion.add( new SelectOption('AP/CLEP (No Attachment Required)','AP/CLEP (No Attachment Required)') );
                reasonforExclusion.add( new SelectOption('School Name Change','School Name Change') );
                reasonforExclusion.add( new SelectOption('IT coursework older than five years (Information Technology Applicants Only)','IT coursework older than five years (Information Technology Applicants Only)') );
                reasonforExclusion.add( new SelectOption('Other','Other') );
                
                return reasonforExclusion;
            }
            set;
        }
        
        public Attachment exclusionAttachment
        {
            get 
            {
                if (exclusionAttachment == null)
                {
                    exclusionAttachment = new Attachment();
                }                
                return exclusionAttachment;
            }            
            set;
        }        
    }
}