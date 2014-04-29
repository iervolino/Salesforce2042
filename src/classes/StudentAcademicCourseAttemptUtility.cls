/*****************************************************************************************
* Name: StudentAcademicCourseAttemptUtility
* Author: Will Slade
* Purpose: Upserts Student Academic Course Attempt based on control object
* Revisions: 
*    - 10/25/2013 Created Class - WS
*    -  2/26/2014 Added Functionality For Aggregate Attempts Count on Requirement Object - WS
*
******************************************************************************************/

public class StudentAcademicCourseAttemptUtility
{
    public static void upsertAttempts(String sacafbListJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture())
        {
            processUpsertAttempts(sacafbListJSON);
        }
        else
        {
            asyncUpsertAttempts(sacafbListJSON);
        }
    }
    
    @future
    public static void asyncUpsertAttempts(String sacafbListJSON)
    {
        processUpsertAttempts(sacafbListJSON);
    }

    public static void processUpsertAttempts(String sacafbListJSON)
    {
        List<StudentAcademicCourseAttFromBan__c> sacafbList = (List<StudentAcademicCourseAttFromBan__c>) JSON.deserialize(sacafbListJSON, List<StudentAcademicCourseAttFromBan__c>.class);
        List<StudentAcademicCourseAttempt__c> sacaInsertList = new List<StudentAcademicCourseAttempt__c>();
        List<StudentAcademicCourseAttempt__c> sacaUpdateList = new List<StudentAcademicCourseAttempt__c>();
        List<StudentAcademicCourseAttempt__c> sacaDeleteList = new List<StudentAcademicCourseAttempt__c>(); 
        Map<String, Id> srcParentCompToIdMap = new Map<String, Id>();
        Id studentAcademicCourse = null;
               
        //get a keyset of the parent composite keys
        for (StudentAcademicCourseAttFromBan__c thisSACAFB : sacafbList)
        {
            srcParentCompToIdMap.put(thisSACAFB.CompositeParentKeyIN__c, null);
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
        for (StudentAcademicCourseAttFromBan__c thisSACAFB : sacafbList)
        {       
            if (srcParentCompToIdMap.get(thisSACAFB.CompositeParentKeyIN__c) != null)
            {             
                studentAcademicCourse = srcParentCompToIdMap.get(thisSACAFB.CompositeParentKeyIN__c);
            } 
            else
            {
                studentAcademicCourse = null;
            }
        
            if ((thisSACAFB.ActionNeeded__c == 'Insert' || thisSACAFB.ActionNeeded__c == 'Update' || thisSACAFB.ActionNeeded__c == 'Upsert')
                && thisSACAFB.SynchronizationError__c == null && studentAcademicCourse != null)
            {            
                if (thisSACAFB.StudentAcademicCourseAttempt__c == null)
                {                                    
                    sacaInsertList.add(new StudentAcademicCourseAttempt__c(CompositeKey__c = thisSACAFB.CompositeKeyIn__c,
                                                                           AssessmentTaskCode__c = thisSACAFB.AssessmentTaskCodeIN__c,
                                                                           Attempted__c = thisSACAFB.AttemptedIN__c,
                                                                           Passed__c = thisSACAFB.PassedIN__c,
                                                                           StudentAcademicCourse__c = studentAcademicCourse,
                                                                           Type__c = thisSACAFB.TypeIN__c));
                }
                if (thisSACAFB.StudentAcademicCourseAttempt__c != null)
                {                                    
                    sacaUpdateList.add(new StudentAcademicCourseAttempt__c(Id = thisSACAFB.StudentAcademicCourseAttempt__c,
                                                                           CompositeKey__c = thisSACAFB.CompositeKeyIn__c,
                                                                           AssessmentTaskCode__c = thisSACAFB.AssessmentTaskCodeIN__c,
                                                                           Attempted__c = thisSACAFB.AttemptedIN__c,
                                                                           Passed__c = thisSACAFB.PassedIN__c,
                                                                           StudentAcademicCourse__c = studentAcademicCourse,                                                                           
                                                                           Type__c = thisSACAFB.TypeIN__c));
                }                
            }
            else if (thisSACAFB.ActionNeeded__c == 'Delete' && thisSACAFB.StudentAcademicCourseAttempt__c != null)
            {
                sacaDeleteList.add(new StudentAcademicCourseAttempt__c(Id = thisSACAFB.StudentAcademicCourseAttempt__c));
            }                     
            //some key value is missing
            else
            {
                //do not add the record to any update or insert lists as it has an error
            }
        }
        
        update sacaUpdateList;
        insert sacaInsertList;
        delete sacaDeleteList;                                                                                         
    }

    
    public static void updateCourseRequirement(String sacafbListJSON){
        if (Limits.getFutureCalls() > 3 || System.isFuture()){
            processUpdateCourseRequirement(sacafbListJSON);
        }else{
            asyncUpdateCourseRequirement(sacafbListJSON);
        }
    }
    
    @future
    public static void asyncUpdateCourseRequirement(String sacafbListJSON){
        processUpdateCourseRequirement(sacafbListJSON);
    }
    
    public static void processUpdateCourseRequirement(String sacafbListJSON){
        List<StudentAcademicCourseAttFromBan__c> sacafbList = (List<StudentAcademicCourseAttFromBan__c>) JSON.deserialize(sacafbListJSON, List<StudentAcademicCourseAttFromBan__c>.class);
        List<StudentAcademicCourseRequirement__c> sacrUpdateList = new List<StudentAcademicCourseRequirement__c>();
        Set<String> uniKeySet = new Set<String>();
        List<String> comPKList = new List<String>();
        Map<String,String> uniKeyComPK = new MAP<String,String>();
        Map<String,String> gradeMap = new Map<String,String>();
        Map<String,Datetime> completedDateMap = new Map<String,Datetime>();
        for(StudentAcademicCourseAttFromBan__c sacafb : sacafbList){
            if(sacafb.CompositeKeyIN__c == null || sacafb.CompositeParentKeyIN__c == null) continue;
            String compositeKey = sacafb.CompositeKeyIN__c;
            String term = sacafb.CompositeParentKeyIN__c.right(6);
            if(Integer.valueOf(term) <= 0) continue;
            String uniKey = compositeKey.substring(0,compositeKey.lastIndexOf('-')+1) + term;
            uniKeySet.add(uniKey);
            comPKList.add(sacafb.CompositeParentKeyIN__c);
            uniKeyComPK.put(uniKey, sacafb.CompositeParentKeyIN__c);
        }
        //save the latest record in Map from control object
        List<StudentAcademicCourseAttFromBan__c> crseAttFBList = [SELECT CompositeParentKeyIn__c, PassedIN__c, AttemptedIN__c
                                                                  FROM StudentAcademicCourseAttFromBan__c
                                                                  WHERE CompositeParentKeyIN__c IN: comPKList
                                                                  AND AttemptedIN__c != null
                                                                  ORDER BY CompositeParentKeyIN__c, AttemptedIN__c DESC];
        for(StudentAcademicCourseAttFromBan__c cafb : crseAttFBList){
            if(!gradeMap.containsKey(cafb.CompositeParentKeyIn__c)){
                String grade = Boolean.valueOf(cafb.PassedIN__c) ? 'P' : 'NP';
                gradeMap.put(cafb.CompositeParentKeyIn__c, grade);
                completedDateMap.put(cafb.CompositeParentKeyIn__c, cafb.AttemptedIN__c);
            }
        }
        //get corresponding data from Coure Requirement 
        List<StudentAcademicCourseRequirement__c> sacrList = [SELECT Id,UniqueKey__c,Status__c
                                                              FROM StudentAcademicCourseRequirement__c
                                                              WHERE UniqueKey__c IN: uniKeySet];
        for(StudentAcademicCourseRequirement__c sacr : sacrList){
            String comPK = uniKeyComPK.get(sacr.UniqueKey__c);
            String status = gradeMap.get(comPK);
            sacr.Status__c = status;
            if('P'.equals(status)){
                sacr.Completed__c = true;
                sacr.CompletedDate__c = completedDateMap.get(comPK).date();
            }else{
                sacr.Completed__c = false;
                sacr.CompletedDate__c = null;
            }
            sacrUpdateList.add(sacr);
        }
        update sacrUpdateList;
    }
////////////////////////////// Begin Count Attempts for Requirement Record /////////////////////////////    
    public static void countAttempts(String sacafbListJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture())
        {
            processCountAttempts(sacafbListJSON);
        }
        else
        {
            asyncCountAttempts(sacafbListJSON);
        }
    }
    
    @future
    public static void asyncCountAttempts(String sacafbListJSON)
    {
        processCountAttempts(sacafbListJSON);
    }

    public static void processCountAttempts(String sacafbListJSON)
    {
        List<StudentAcademicCourseAttFromBan__c> sacafbList = (List<StudentAcademicCourseAttFromBan__c>) JSON.deserialize(sacafbListJSON, List<StudentAcademicCourseAttFromBan__c>.class);
        List<String> attemptCompKeyList = new List<String>();
        List<String> reqCompKeyList = new List<String>();        
        List<StudentAcademicCourseAttempt__c> sacaList = new List<StudentAcademicCourseAttempt__c>();
        List<StudentAcademicCourseRequirement__c> sacrList = new List<StudentAcademicCourseRequirement__c>();
        Map<String, String> attKeyToParentKeyMap = new Map<String, String>();

        for (StudentAcademicCourseAttFromBan__c sacafb : sacafbList)
        {
            reqCompKeyList.add(sacafb.CompositeParentKeyIN__c);             
        }
        
        sacafbList = [SELECT Id, CompositeKeyIN__c, CompositeParentKeyIN__c
                      FROM StudentAcademicCourseAttFromBan__c
                      WHERE CompositeParentKeyIN__c IN :reqCompKeyList];
                
        //Build lists of the composite keys for queries on source objects
        //Build map to link the attempt with its requirement parent record           
        for (StudentAcademicCourseAttFromBan__c sacafb : sacafbList)
        {
            attemptCompKeyList.add(sacafb.CompositeKeyIN__c);            
            attKeyToParentKeyMap.put(sacafb.CompositeKeyIN__c, sacafb.CompositeParentKeyIN__c);             
        }
        
        //Query lists of source attempt and requirement objects related to trigger contents
        sacaList = [SELECT Id, CompositeKey__c
                    FROM StudentAcademicCourseAttempt__c
                    WHERE CompositeKey__c IN :attemptCompKeyList];                   
                    
        sacrList = [SELECT Id, UniqueKey__c, Attempts__c
                    FROM StudentAcademicCourseRequirement__c
                    WHERE UniqueKey__c IN :reqCompKeyList];
        
        //For each requirement record, loop through the attempt records and get the total         
        for (StudentAcademicCourseRequirement__c sacr : sacrList)
        {         
            integer numAttempts = 0;            
            for (StudentAcademicCourseAttempt__c saca : sacaList)
            {                
                if (attKeyToParentKeyMap.get(saca.CompositeKey__c).equals(sacr.UniqueKey__c))
                {
                    numAttempts += 1;                    
                }
            }
            
            sacr.Attempts__c = numAttempts;            
        }
        
        update sacrList;                                                                                                                                       
    } 
/////////////////////////////// End Count Attempts for Requirement Record //////////////////////////////
}