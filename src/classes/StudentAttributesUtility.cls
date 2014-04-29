/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Created Date Aug 4, 2013 @ 1352 hrs
 *
 * Trigger Utility for StudentAttributes Trigger processing
 *
 */ 
public with sharing class StudentAttributesUtility {
      
    public static boolean firstRun = true;
    
//////////////////////////// START SECTION: Push some fields of Student Attributes into StudentAttributesToBanner ///////////////////////////////////////

    public static void createStudentAttributesToBanner (String listNewJSON){
        if(Limits.getFutureCalls()>8 || System.isFuture() || System.isBatch() || System.isScheduled() ){
            processCreateStudentAttributesToBanner (listNewJSON);
        }else{
            try{
                asyncCreateStudentAttributesToBanner (listNewJSON);
            }catch(Exception e){
                processCreateStudentAttributesToBanner (listNewJSON);
            }
        }
    }

@future
    private static void asyncCreateStudentAttributesToBanner (String listNewJSON){
        processCreateStudentAttributesToBanner (listNewJSON);
    }

    private static void processCreateStudentAttributesToBanner (String listNewJSON){
        List<StudentAttributes__c> attributeList = (List<StudentAttributes__c>)JSON.deserialize(listNewJSON,List<StudentAttributes__c>.class);
        List<StudentAttributesToBanner__c> insertList = new List<StudentAttributesToBanner__c>();
        List<StudentAttributesToBanner__c> updateList = new List<StudentAttributesToBanner__c>();
       
        for(StudentAttributes__c stuAttr: [select id, (select id from StudentsAttributesToBanner__r) from StudentAttributes__c WHERE id IN :attributeList]){      
            if( stuAttr.StudentsAttributesToBanner__r.isEmpty() ){
                insertList.add( new StudentAttributesToBanner__c(StudentAttributes__c = stuAttr.Id) );   
            }else{
                updateList.add( new StudentAttributesToBanner__c(Id=stuAttr.StudentsAttributesToBanner__r[0].Id, StudentAttributes__c=stuAttr.Id) );
            }
        }  
        
        if (!updateList.isEmpty() ) {      
          update updateList;
        }
        if ( !insertList.isEmpty() ) {
          insert insertList;
        }
    }

//////////////////////////// END SECTION: Push some fields of Student Attributes into StudentAttributesToBanner  ///////////////////////////////////////  


}