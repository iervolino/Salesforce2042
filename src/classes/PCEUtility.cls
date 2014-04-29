/*****************************************************************************************
* Name: PCEUtility
* Author: Will Slade
* Purpose: Called from StudentCompletionTask trigger... when assessments are passed,
           a field on the contact is updated, which sends them an email for PCE/SFAW
* Revisions: 
*    - 8/1/12 Created Class
*    - 3/27/13 Updated to new standards for future methods for code coverage
******************************************************************************************/

public class PCEUtility 
{
    public static void updateContactPCEEmailSent(String compTaskListNewJSON, String compTaskListOldJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch())
        {
            processUpdateContactPCEEmailSent( compTaskListNewJSON, compTaskListOldJSON );
        }
        else
        {
            asyncUpdateContactPCEEmailSent( compTaskListNewJSON, compTaskListOldJSON );
        }
    }      
    
    public static void updateContactSFAWEmailSent(String compTaskListNewJSON, String compTaskListOldJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch())
        {
            processUpdateContactSFAWEmailSent( compTaskListNewJSON, compTaskListOldJSON );
        }
        else
        {
            asyncUpdateContactSFAWEmailSent( compTaskListNewJSON, compTaskListOldJSON );
        }
    }    
    
    @future
    private static void asyncUpdateContactPCEEmailSent(String compTaskListNewJSON, String compTaskListOldJSON)
    {
        processUpdateContactPCEEmailSent(compTaskListNewJSON, compTaskListOldJSON);
    }
    
    @future
    private static void asyncUpdateContactSFAWEmailSent(String compTaskListNewJSON, String compTaskListOldJSON)
    {
        processUpdateContactSFAWEmailSent(compTaskListNewJSON, compTaskListOldJSON);    
    }    
     
    private static void processUpdateContactPCEEmailSent(String compTaskListNewJSON, String compTaskListOldJSON) 
    {   
        List<StudentCompletionTask__c> TriggerNew = (List<StudentCompletionTask__c>)JSON.deserialize( compTaskListNewJSON, List<StudentCompletionTask__c>.class );
        List<StudentCompletionTask__c> TriggerOld = (List<StudentCompletionTask__c>)JSON.deserialize( compTaskListOldJSON, List<StudentCompletionTask__c>.class );
        
        List<StudentCompletionTask__c> assessments = [SELECT Student__c, Name FROM StudentCompletionTask__c WHERE Name IN ('MZC1', 'FHT4', 'EEC1', 'ABP1') AND RequirementComplete__c = true AND Student__r.InitialFEEmailSent__c = false AND Id IN :TriggerNew LIMIT 10000];                
       
        System.debug('=====================> Student ID ' + assessments[0].Student__c);
        
        Map<Id, StudentCompletionTask__c> recordsOfInterest = new Map<Id, StudentCompletionTask__c>();
        
        List<Contact> studentsToEmail = new List<Contact>();
        
        for (StudentCompletionTask__c assessment : assessments)
        {
            if (!recordsOfInterest.containsKey(assessment.student__c))
            {
                recordsOfInterest.put(assessment.student__c, assessment);
                studentsToEmail.add(new Contact(id = assessment.student__c, InitialFEEmailSent__c = true));           
            }   
        }
        
        update studentsToEmail;  
    }
    
    private static void processUpdateContactSFAWEmailSent (String compTaskListNewJSON, String compTaskListOldJSON) 
    {   
        List<StudentCompletionTask__c> TriggerNew = (List<StudentCompletionTask__c>)JSON.deserialize( compTaskListNewJSON, List<StudentCompletionTask__c>.class );
        List<StudentCompletionTask__c> TriggerOld = (List<StudentCompletionTask__c>)JSON.deserialize( compTaskListOldJSON, List<StudentCompletionTask__c>.class );
        
        List<StudentCompletionTask__c> assessments = [SELECT Student__c, Name FROM StudentCompletionTask__c WHERE Name = 'SFAW' AND RequirementComplete__c = true AND Student__r.SFAWEmailSent__c = false AND Id IN :TriggerNew LIMIT 10000];                
        
        System.debug('=====================> Student ID ' + assessments[0].Student__c);
        
        Map<Id, StudentCompletionTask__c> recordsOfInterest = new Map<Id, StudentCompletionTask__c>();
        
        List<Contact> studentsToEmail = new List<Contact>();
        
        for (StudentCompletionTask__c assessment : assessments)
        {
            if (!recordsOfInterest.containsKey(assessment.student__c))
            {
                recordsOfInterest.put(assessment.student__c, assessment);
                studentsToEmail.add(new Contact(id = assessment.student__c, SFAWEmailSent__c = true));                           
            }   
        }        
        update studentsToEmail;  
    }            
}