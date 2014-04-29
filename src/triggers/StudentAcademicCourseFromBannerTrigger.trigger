/*******************************************************
*
* - StudentAcademicCourseFromBannerTrigger
* - Author: Will Slade
* - Purpose: Control object for receiving course attempts from Banner
* - Revisions: 10-21-2013 - Created Trigger - WS
*
********************************************************/

trigger StudentAcademicCourseFromBannerTrigger on StudentAcademicCourseFromBanner__c (before insert, before update, after insert, after update) 
{
//////////////////////////////////////// BEGIN LINK SOURCE RECORDS ///////////////////////////////
    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert))
    {
        //Running in trigger rather than future call because this step MUST be complete prior to the "UPSERT SOURCE RECORDS" section
        List<String> ctrlCompKeysList = new List<String>();
        Map<Id, String> ctrlIdToCompMap = new Map<Id, String>();
        Map<String, Id> srcCompToIdMap = new Map<String, Id>();       
        
        //create list of composite keys and populate map linking them to control IDs
        for (StudentAcademicCourseFromBanner__c thisSACFB : Trigger.new)
        {
            thisSACFB.SynchronizationError__c = null;
            ctrlCompKeysList.add(thisSACFB.CompositeKeyIN__c);
            ctrlIdToCompMap.put(thisSACFB.Id, thisSACFB.CompositeKeyIN__c);
        }
        
        //query existing source objects based on composite keys list
        List<StudentAcademicCourse__c> sacList = [SELECT Id, CompositeKey__c 
                                                  FROM StudentAcademicCourse__c
                                                  WHERE CompositeKey__c IN :ctrlCompKeysList];
        
        //populate source object map with composite keys and IDs                                          
        for (StudentAcademicCourse__c thisSAC : sacList)
        {
            srcCompToIdMap.put(thisSAC.CompositeKey__c, thisSAC.Id);
        }
        
        //if a source object already exists for the composite key, populate the lookup record on the control object
        for (StudentAcademicCourseFromBanner__c thisSACFB : Trigger.new)
        {
            if (srcCompToIdMap.get(ctrlIdToCompMap.get(thisSACFB.Id)) != null)
            {
                thisSACFB.StudentAcademicCourse__c = srcCompToIdMap.get(ctrlIdToCompMap.get(thisSACFB.Id));
            }

            //if any key data is missing, populate the error field so the record will not process in the utility method
            if (((thisSACFB.CourseCodeIN__c == null
                || thisSACFB.CourseTitleIN__c == null
                || thisSACFB.StatusIN__c == null
                || thisSACFB.StudentPIDMIN__c == null
                || thisSACFB.TermIn__c == null) && thisSACFB.StudentAcademicCourse__c == null) 
                || thisSACFB.CompositeKeyIN__c == null)
            {
                thisSACFB.SynchronizationError__c = 
                 'A required value on this record is missing, source object will not be modified! Required values include: Composite Key, Course Code, Course Title, Status, PIDM, Term, and Type.';
            }
            // adjust type value 
            if('PRFA'.equals(thisSACFB.TypeIn__c)){
                thisSACFB.TypeIn__c = 'Performance';
            }else if('OBJA'.equals(thisSACFB.TypeIn__c)){
                thisSACFB.TypeIn__c = 'Objective';
            }else{
                thisSACFB.TypeIn__c = 'Not Applicable';
            }
        }                                                                                        
    }
///////////////////////////////////////// END LINK SOURCE RECORDS ////////////////////////////////


/////////////////////////////////////// BEGIN UPSERT GRADE RECORDS //////////////////////////////
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        //pass all records in trigger to utility method
        StudentAcademicCourseUtility.upsertCourses(JSON.serialize(Trigger.new));                
    }   
//////////////////////////////////////// END UPSERT GRADE RECORDS ///////////////////////////////    
}