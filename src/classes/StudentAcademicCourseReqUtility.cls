/*****************************************************************************************
* Name: StudentAcademicCourseReqUtility
* Author: Will Slade
* Purpose: Upserts Student Academic Course Requirement based on control object
* Revisions: 
*    - 1/10/2014 Created Class
*
******************************************************************************************/

public class StudentAcademicCourseReqUtility
{
    public static void upsertRequirements(String sacrfbListJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture())
        {
            processUpsertRequirements(sacrfbListJSON);
        }
        else
        {
            asyncUpsertRequirements(sacrfbListJSON);
        }
    }
    
    @future
    public static void asyncUpsertRequirements(String sacrfbListJSON)
    {
        processUpsertRequirements(sacrfbListJSON);
    }

    public static void processUpsertRequirements(String sacrfbListJSON)
    {
        List<StudentAcademicCourseReqFromBanner__c> sacrfbList = (List<StudentAcademicCourseReqFromBanner__c>) JSON.deserialize(sacrfbListJSON, List<StudentAcademicCourseReqFromBanner__c>.class);
        List<StudentAcademicCourseRequirement__c> sacrInsertList = new List<StudentAcademicCourseRequirement__c>();
        List<StudentAcademicCourseRequirement__c> sacrUpdateList = new List<StudentAcademicCourseRequirement__c>();
        List<StudentAcademicCourseRequirement__c> sacrDeleteList = new List<StudentAcademicCourseRequirement__c>(); 
        Map<String, Id> srcParentCompToIdMap = new Map<String, Id>();
        Id studentAcademicCourse = null;
               
        //get a keyset of the parent composite keys
        for (StudentAcademicCourseReqFromBanner__c thisSacrFB : sacrfbList)
        {
            srcParentCompToIdMap.put(thisSacrFB.UniqueParentKey__c, null);
        }
        
        //find all parent records within keyset
        List<StudentAcademicCourse__c> sacList = [SELECT Id, CompositeKey__c 
                                                  FROM StudentAcademicCourse__c
                                                  WHERE CompositeKey__c IN :srcParentCompToIdMap.keyset()];
                                                  
        //populate parent IDs in the map
        for (StudentAcademicCourse__c thisSAC : sacList)
        {
            srcParentCompToIdMap.put(thisSAC.CompositeKey__c, thisSAC.Id);
        }
        
        //loop through map and upsert source records
        for (StudentAcademicCourseReqFromBanner__c thisSacrFB : sacrfbList)
        {
            integer titleLen = 0;
            
            if (thisSacrFB.FullTitle__c != null && thisSacrFB.FullTitle__c != '')
            {
                titleLen = thisSacrFB.FullTitle__c.length() <= 80 ? thisSacrFB.FullTitle__c.length() : 80;
            }
                   
            if (srcParentCompToIdMap.get(thisSacrFB.UniqueParentKey__c) != null)
            {            
                studentAcademicCourse = srcParentCompToIdMap.get(thisSacrFB.UniqueParentKey__c);
            } 
            else
            {
                studentAcademicCourse = null;
            }
        
            if ((thisSacrFB.ActionNeeded__c == 'Insert' || thisSacrFB.ActionNeeded__c == 'Update' || thisSacrFB.ActionNeeded__c == 'Upsert')
                && thisSacrFB.SynchronizationError__c == null && studentAcademicCourse != null)
            {
                String reqType = thisSacrFB.Type__c == 'OBJA' ? 'OBJECTIVE' : thisSacrFB.Type__c;
                reqType = reqType == 'PRFA' ? 'PERFORMANCE' : reqType;               
                String fullTitle = thisSacrFB.FullTitle__c == null ? '' : thisSacrFB.FullTitle__c;
                       
                if (thisSacrFB.StudentAcademicCourseRequirement__c == null)
                {                                    
                    sacrInsertList.add(new StudentAcademicCourseRequirement__c(Name = fullTitle.substring(0, titleLen),
                                                                               FullTitle__c = fullTitle,
                                                                               UniqueKey__c = thisSacrFB.UniqueKey__c,
                                                                               RequirementCode__c = thisSacrFB.RequirementCode__c,
                                                                               EngagedPreassessment__c = thisSacrFB.EngagedPreassessment__c,
                                                                               Status__c = thisSacrFB.Status__c,
                                                                               StudentAcademicCourse__c = studentAcademicCourse,
                                                                               Type__c = reqType));
                }
                if (thisSacrFB.StudentAcademicCourseRequirement__c != null)
                {                                    
                    sacrUpdateList.add(new StudentAcademicCourseRequirement__c(Id = thisSacrFB.StudentAcademicCourseRequirement__c,
                                                                               Name = fullTitle.substring(0, titleLen),
                                                                               FullTitle__c = fullTitle,
                                                                               UniqueKey__c = thisSacrFB.UniqueKey__c,
                                                                               RequirementCode__c = thisSacrFB.RequirementCode__c,
                                                                               EngagedPreassessment__c = thisSacrFB.EngagedPreassessment__c,
                                                                               Status__c = thisSacrFB.Status__c,
                                                                               StudentAcademicCourse__c = studentAcademicCourse,                                                                           
                                                                               Type__c = reqType));
                }                
            }
            else if (thisSacrFB.ActionNeeded__c == 'Delete' && thisSacrFB.StudentAcademicCourseRequirement__c != null)
            {
                sacrDeleteList.add(new StudentAcademicCourseRequirement__c(Id = thisSacrFB.StudentAcademicCourseRequirement__c));
            }                     
            //some key value is missing
            else
            {
                //do not add the record to any update or insert lists as it has an error
            }
        }
        
        update sacrUpdateList;
        insert sacrInsertList;
        delete sacrDeleteList;                                                                                         
    }
    
    public static void updateContactEmailSent(String newJSON){
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch()){
            processUpdateContactEmailSent(newJSON);
        }else{
            asyncUpdateContactEmailSent(newJSON);
        }
    }

    @future
    private static void asyncUpdateContactEmailSent(String newJSON){
        processUpdateContactEmailSent(newJSON);
    }
    
    private static void processUpdateContactEmailSent(String newJSON){   
        List<StudentAcademicCourseRequirement__c> crList = (List<StudentAcademicCourseRequirement__c>)JSON.deserialize( newJSON, List<StudentAcademicCourseRequirement__c>.class );
        List<String> PCEpidmList = new List<String>();
        List<String> SFAWpidmList = new List<String>();
        Set<String> PCECrseSet = new Set<String>();
        PCECrseSet.add('FHT4');
        PCECrseSet.add('EEC1');
        PCECrseSet.add('MZC1');
        PCECrseSet.add('ABP1');
        for(StudentAcademicCourseRequirement__c cr:crList){
            String[] keys = cr.UniqueKey__c.split('-');
            if(keys.size() != 3) continue;
            String pidm = keys[0];
            String crse = keys[1];
            if(PCECrseSet.contains(crse) && cr.Completed__c == TRUE){
                PCEpidmList.add(pidm);
            }else if('SFAW'.equals(crse) && cr.Completed__c == TRUE){
                SFAWpidmList.add(pidm);
            }
        }
        List<Contact> contactPCEList = [SELECT Id,InitialFEEmailSent__c FROM Contact
                                        WHERE InitialFEEmailSent__c = FALSE
                                        AND isDeleted = FALSE
                                        AND PIDM__c IN :PCEpidmList LIMIT 10000];
        for(Contact contact:contactPCEList){
            contact.InitialFEEmailSent__c = TRUE;
        }
        List<Contact> contactSFAWList = [SELECT Id,SFAWEmailSent__c FROM Contact
                                         WHERE SFAWEmailSent__c = FALSE
                                         AND isDeleted = FALSE
                                         AND PIDM__c IN :SFAWpidmList LIMIT 10000];
        for(Contact contact:contactSFAWList){
            contact.SFAWEmailSent__c = TRUE;
        }
        update contactPCEList;
        update contactSFAWList;
    }
}