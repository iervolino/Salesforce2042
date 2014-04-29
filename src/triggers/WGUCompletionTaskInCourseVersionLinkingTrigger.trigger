trigger WGUCompletionTaskInCourseVersionLinkingTrigger on WGUCompletionTaskInCourseVersion__c (before insert, before update) {
    Map<Decimal, String> aMap = new Map<Decimal, String>();
    Map<Decimal, String> courseversionMap = new Map<Decimal, String>();
    List<Decimal> courseVersionIds = new List<Decimal>();
    List<Decimal> aIds = new List<Decimal>();
    
    for (WGUCompletionTaskInCourseVersion__c task : Trigger.new) {    
        if (task.PAMSCourseVersionId__c != null) {
            courseVersionIds.add(task.PAMSCourseVersionId__c);
        }      
         if (task.PAMSAssessmentId__c != null) {
            aIds.add(task.PAMSAssessmentId__c);
        }        
    }
    
    if(!courseVersionIds.isEmpty()){
       List<WGUCourseCompletionTask__c> courses = [SELECT count() from WGUCourseCompletionTask__c where PAMSPK__c in :aIds]>0? [SELECT Id, PAMSPK__c from WGUCourseCompletionTask__c where PAMSPK__c in :aIds]: new List<WGUCourseCompletionTask__c>();
        
       for(WGUCourseCompletionTask__c course : courses ){
          aMap.put(course.PAMSPK__c, course.id);
        }
         List<WGUCourseversion__c> courseversions = [SELECT count() from WGUCourseversion__c where PAMSVersionID__c in :courseVersionIds]>0? [SELECT Id, PAMSVersionID__c from WGUCourseversion__c where PAMSVersionID__c in :courseVersionIds]: new List<WGUCourseversion__c>();
        
        for(WGUCourseversion__c course : courseversions){
            courseversionMap.put(course.PAMSVersionID__c, course.id);
        }
    }   
    
    for(WGUCompletionTaskInCourseVersion__c task : Trigger.new){ 
        if(task.pamscourseVersionId__c != null){
             task.wguCourseCompletionTask__c = aMap.get((Integer)task.PAMSAssessmentId__c);
             task.wguCourseversion__c = courseversionMap.get((Integer)task.pamscourseVersionId__c);
        }
        
    } 
}