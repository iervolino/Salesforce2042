// Accesible from ~/services/apexrest/leadqual
@RestResource(urlMapping='/leadqual')
global class CAREforceLeadQualRESTServices {

    @HttpPost
    global static Map<String, String> leadQual(String CAREProfileID, String CallDisposition, String EnrollmentNoteType, String Notes,
                                                String ContactTimestamp, String DoNotCall, String DoNotEmail) 
    {
         system.debug('~~~~~~~~~ CAREProfileID ~~~~~~~~~~~~~~~~~~~ ' + CAREProfileID);                         
        Map<String, String> retVal = new Map<String, String>{};                          
        Opportunity careProf = [Select id, ExternalLeadContactControl__c, StopPhoneCalls__c, StopEmails__c 
                                from Opportunity where id = :CAREProfileID];
   //     System.debug('careProf'); 
   //     System.debug(careProf); 
        if (careProf.ExternalLeadContactControl__c <> null)
        {
            ExternalLeadContactControl__c elcc = [Select id, name  from ExternalLeadContactControl__c where id = :careProf.ExternalLeadContactControl__c]; 
     //       System.debug('elcc' + elcc);
            
            if (elcc.name <> 'LeadQual')
            {
                System.debug('LeadQual Post Error(not a leadqual lead): ' + CAREProfileID);
                retVal.put('Status','Failure');
            }
            else
            {
                Task t = new Task();
                t.WhatId = careProf.id ;
                t.CallDisposition__c = CallDisposition;
                t.Description = Notes;
                t.Subject = 'LeadQual - See Notes ';
                DateTime dt = Datetime.parse(ContactTimestamp);
               // t.ActivityDate = dt;
                t.EnrollmentNoteType__c = EnrollmentNoteType;
                if (DoNotCall == 'Yes')
                {
                    careProf.StopPhoneCalls__c = true;
                }
                if (DoNotEmail == 'Yes')
                {
                    careProf.StopEmails__c = true;
                }
                insert t;
                update careProf;
                retVal.put('Status','Success');
         }
         }
         else
         {
            System.debug('LeadQual Post Error(null lead): ' + CAREProfileID);
            retVal.put('Status','Failure'); 
                                         
         }   
        
        return retVal;
    }
}