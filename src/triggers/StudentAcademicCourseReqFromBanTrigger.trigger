/*******************************************************
*
* - StudentAcademicCourseReqFromBanTrigger
* - Author: Will Slade
* - Purpose: Control object for receiving course requirements from Banner
* - Revisions: 1-10-2014 - Created Trigger - WS
*
********************************************************/

trigger StudentAcademicCourseReqFromBanTrigger on StudentAcademicCourseReqFromBanner__c (before insert, before update, after insert, after update) 
{
//////////////////////////////////////// BEGIN LINK SOURCE RECORDS ///////////////////////////////
    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert))
    {
        //Running in trigger rather than future call because this step MUST be complete prior to the "UPSERT SOURCE RECORDS" section
        List<String> ctrlCompKeysList = new List<String>();
        List<String> ctrlCompParentKeysList = new List<String>();
        Map<Id, String> ctrlIdToCompMap = new Map<Id, String>();
        Map<String, Id> srcCompToIdMap = new Map<String, Id>(); 
        Map<String, Id> srcParentCompToIdMap = new Map<String, Id>();
        
        //create list of composite keys and populate map linking them to control IDs
        for (StudentAcademicCourseReqFromBanner__c thisSACRFB : Trigger.new)
        {
            thisSACRFB.SynchronizationError__c = null;
            ctrlCompKeysList.add(thisSACRFB.UniqueKey__c);            
            ctrlIdToCompMap.put(thisSACRFB.Id, thisSACRFB.UniqueKey__c);
            
            //parent information
            ctrlCompParentKeysList.add(thisSACRFB.UniqueParentKey__c);
            srcParentCompToIdMap.put(thisSACRFB.UniqueParentKey__c, null);
        }   
        
        //query existing source objects based on composite keys list
        List<StudentAcademicCourseRequirement__c> sacRList = [SELECT Id, UniqueKey__c 
                                                              FROM StudentAcademicCourseRequirement__c
                                                              WHERE UniqueKey__c IN :ctrlCompKeysList];
        
        //populate source object map with composite keys and IDs                                          
        for (StudentAcademicCourseRequirement__c thisSACR : sacrList)
        {
            srcCompToIdMap.put(thisSACR.UniqueKey__c, thisSACR.Id);
        }
        
        //query existing parent source objects based on parent composite keys list 
        List<StudentAcademicCourse__c> sacList = [SELECT Id, CompositeKey__c 
                                                  FROM StudentAcademicCourse__c
                                                  WHERE CompositeKey__c IN :ctrlCompParentKeysList];
        
        //map where parent records exist                                          
        for (StudentAcademicCourse__c thisSAC : sacList)
        {       
            srcParentCompToIdMap.put(thisSAC.CompositeKey__c, thisSAC.Id);
        }                                                  
                                                                  
        //if a source object already exists for the composite key, populate the lookup record on the control object
        for (StudentAcademicCourseReqFromBanner__c thisSACRFB : Trigger.new)
        {
            if (srcCompToIdMap.get(ctrlIdToCompMap.get(thisSACRFB.Id)) != null)
            {
                thisSACRFB.StudentAcademicCourseRequirement__c = srcCompToIdMap.get(ctrlIdToCompMap.get(thisSACRFB.Id));
            }
                        
            //if there is no existing parent source record that matches the parent composite key populate the error field
            if (srcParentCompToIdMap.get(thisSACRFB.UniqueParentKey__c) == null)
            {
                thisSACRFB.SynchronizationError__c = 'StudentAcademicCourse__c parent record does not exist or parent composite key is malformed.';
            }
            
            //if any key data is missing, populate the error field so the record will not process in the utility method
            else if (((thisSACRFB.RequirementCode__c == null
                    || thisSACRFB.Status__c == null
                    || thisSACRFB.Type__c == null) && thisSACRFB.StudentAcademicCourseRequirement__c == null) 
                    || thisSACRFB.UniqueKey__c == null 
                    || thisSACRFB.UniqueParentKey__c == null)
            {
                thisSACRFB.SynchronizationError__c = 
                 'A required value on this record is missing, source object will not be modified! Required values include: Unique Key, Unique Parent Key, Requirement Code, Status and Type.';
            }            
        }                            
    }
///////////////////////////////////////// END LINK SOURCE RECORDS ////////////////////////////////


/////////////////////////////////////// BEGIN UPSERT SOURCE RECORDS //////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        StudentAcademicCourseReqUtility.upsertRequirements(JSON.serialize(Trigger.new));                
    }   
//////////////////////////////////////// END UPSERT SOURCE RECORDS ///////////////////////////////    
}