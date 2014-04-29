trigger StudentDispositionTrigger on StudentDisposition__c (before Insert,after Insert){
    
     if ( Trigger.isBefore &&  Trigger.isInsert ) {

    Map<String,contact> contMap=new Map<String,contact>();
    Map<String,TaskStreamAssessment__c> tsaMap=new Map<String,TaskStreamAssessment__c>();
    Map<String,TaskStreamTaskFailure__c> tstfMap=new Map<String,TaskStreamTaskFailure__c>();
    Set<String> contactIds=new Set<String>();
    Set<String> studentIdSet=new Set<String>();
    Set<String> AssessmentNameSet=new Set<String>();
    Set<String> TaskFailedNameSet=new Set<String>();
    for(StudentDisposition__c sd:Trigger.new){
        Integer len=sd.StudentID__c.length();           
        if(sd.StudentID__c !=null && sd.StudentID__c!='' && len==9){
            studentIdSet.add(sd.StudentID__c);        
        }else if(sd.StudentID__c !=null && sd.StudentID__c!='' && len<9){
            for(integer i=0;i<9-len;i++ ){
                sd.StudentID__c='0'+sd.StudentID__c;
            } 
            studentIdSet.add(sd.StudentID__c);  
        }
        AssessmentNameSet.add(sd.AssessmentName__c);
        TaskFailedNameSet.add(sd.TaskName__c);
    }
    for(Contact cont:[select id,StudentID__c from contact where StudentID__c in:studentIdSet]){
        contMap.put(cont.StudentID__c,cont);
        contactIds.add(cont.Id);
    }
     System.debug('raavi1 =========='+contactIds);
     System.debug('raavi2 =========='+AssessmentNameSet);
     System.debug('raavi3 =========='+TaskFailedNameSet);
    for(TaskStreamAssessment__c tsa:[Select Id,Student__c,Name from TaskStreamAssessment__c where Student__c in:contactIds and Name in:AssessmentNameSet]){
        tsaMap.put(tsa.Student__c,tsa);
    }
    for(TaskStreamTaskFailure__c tstf:[select Id, Student__c,Name,TaskStreamAssessment__c from TaskStreamTaskFailure__c where Student__c in:contactIds and Name in:TaskFailedNameSet]){
        tstfMap.put(tstf.Student__c,tstf);
    }
    for(StudentDisposition__c sd:Trigger.New){
        if(contMap!=null && contMap.get(sd.studentID__c)!=null){
            sd.student__c=contMap.get(sd.studentID__c).Id;
         }
        if(tsaMap!=null && tsaMap.get(sd.student__c)!=null){
            sd.Assessment__c = tsaMap.get(sd.Student__c).Id;
         }
         if(tstfMap!=null && tstfMap.get(sd.student__c)!=null){
            sd.TaskFailure__c = tstfMap.get(sd.Student__c).Id;
        }
    }
}
}