/*******************************************************
*
* - StudentAcademicCourseAttFromBanTrigger
* - Author: Will Slade
* - Purpose: Control object for receiving course attempts from Banner
* - Revisions: 10-21-2013 - Created Trigger - WS
* -             2-26-2014 - Added functionality to add aggregate sum of attempts for requirement object - WS
*
********************************************************/

trigger StudentAcademicCourseAttFromBanTrigger on StudentAcademicCourseAttFromBan__c (before insert, before update, after insert, after update) 
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
        for (StudentAcademicCourseAttFromBan__c thisSACAFB : Trigger.new)
        {
            thisSACAFB.SynchronizationError__c = null;
            ctrlCompKeysList.add(thisSACAFB.CompositeKeyIN__c);            
            ctrlIdToCompMap.put(thisSACAFB.Id, thisSACAFB.CompositeKeyIN__c);
            
            //parent information
            ctrlCompParentKeysList.add(thisSACAFB.CompositeParentKeyIN__c);
            srcParentCompToIdMap.put(thisSACAFB.CompositeParentKeyIN__c, null);
        }   
        
        //query existing source objects based on composite keys list
        List<StudentAcademicCourseAttempt__c> sacaList = [SELECT Id, CompositeKey__c 
                                                          FROM StudentAcademicCourseAttempt__c
                                                          WHERE CompositeKey__c IN :ctrlCompKeysList];
        
        //populate source object map with composite keys and IDs                                          
        for (StudentAcademicCourseAttempt__c thisSACA : sacaList)
        {
            srcCompToIdMap.put(thisSACA.CompositeKey__c, thisSACA.Id);
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
        for (StudentAcademicCourseAttFromBan__c thisSACAFB : Trigger.new)
        {
            if (srcCompToIdMap.get(ctrlIdToCompMap.get(thisSACAFB.Id)) != null)
            {
                thisSACAFB.StudentAcademicCourseAttempt__c = srcCompToIdMap.get(ctrlIdToCompMap.get(thisSACAFB.Id));
            }
                        
            //if there is no existing parent source record that matches the parent composite key populate the error field
            if (srcParentCompToIdMap.get(thisSACAFB.compositeParentKeyIN__c) == null)
            {
                thisSACAFB.SynchronizationError__c = 'StudentAcademicCourse__c parent record does not exist or parent composite key is malformed.';
            }
            
            //if any key data is missing, populate the error field so the record will not process in the utility method
            else if (((thisSACAFB.AssessmentTaskCodeIN__c == null
                    || thisSACAFB.AttemptedIN__c == null
                    || thisSACAFB.PassedIN__c == null
                    || thisSACAFB.TypeIN__c == null) && thisSACAFB.StudentAcademicCourseAttempt__c == null) 
                    || thisSACAFB.CompositeKeyIN__c == null 
                    || thisSACAFB.CompositeParentKeyIN__c == null)
            {
                thisSACAFB.SynchronizationError__c = 
                 'A required value on this record is missing, source object will not be modified! Required values include: Composite (&parent) Key, Assessment Code, Attempted (Test Date/Time), Passed, and Type.';
            }
            // adjust type value 
            if('PRFA'.equals(thisSACAFB.TypeIN__c)){
                thisSACAFB.TypeIN__c = 'Performance';
            }else if('OBJA'.equals(thisSACAFB.TypeIn__c)){
                thisSACAFB.TypeIN__c = 'Objective';
            }            
        }                            
    }
///////////////////////////////////////// END LINK SOURCE RECORDS ////////////////////////////////

/////////////////////////////////////// BEGIN UPSERT SOURCE RECORDS //////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        StudentAcademicCourseAttemptUtility.upsertAttempts(JSON.serialize(Trigger.new));                
    }   
//////////////////////////////////////// END UPSERT SOURCE RECORDS ///////////////////////////////

/////////////////////////////////////// BEGIN Update Academic Course Requirement //////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)){
        StudentAcademicCourseAttemptUtility.updateCourseRequirement(JSON.serialize(Trigger.new));                
    }   
/////////////////////////////////////// END Update Academic Course Requirement  //////////////////

////////////////////////////////////////// BEGIN COUNT ATTEMPTS //////////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        StudentAcademicCourseAttemptUtility.countAttempts(JSON.serialize(Trigger.new));                
    }   
/////////////////////////////////////////// END COUNT ATTEMPTS ///////////////////////////////////
}