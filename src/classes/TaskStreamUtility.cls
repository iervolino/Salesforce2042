/*
    this is the utility to update 2 look up fields(student__c, TaskStreamAssessment__c), by given pidm__c and course code 

*/

public class TaskStreamUtility
{
    
    //look up contacts and courses and set them into look up fields
    public static void processLookUpFieldsOfTask(List<Taskstreamtask__c> triggernew)
    {  
        /*
            fill up the lookup field to specific student
        */
        system.debug('%%%%%%%%%%% Taskstreamutility utility task start:%%%%%%%%%'+triggernew);
        Map<String,id> pidmMap=new Map<String,id>();   //map from pidm to student
        Set<String> pidms=new Set<String>();           //set of all pidms
        Map<Double,id> keyMap=new Map<Double,id>();   //map from code to courses
        Set<Double> keys=new Set<Double>();           //set of all course code
        //build 2 sets
        for(TaskStreamTask__c tst :  Triggernew)
        {
            pidms.add(tst.pidm__c); 
            keys.add(tst.AssessmentIDKey__c); 
        }  
        //build 2 maps
        if(!pidms.isEmpty())
        {
            List<contact> contacts=[select id,pidm__c from contact where pidm__c in :pidms];
            for(contact c:contacts)
            {
                pidmMap.put(c.pidm__c,c.id);
            } 
        } 
        if(!keys.isEmpty())
        {
            //( pidm + assessment code) pair up as a key -> taskstreamassessment
            List<TaskStreamAssessment__c> courses=[select id, AssessmentIDKey__c  from TaskStreamAssessment__c where AssessmentIDKey__c in :keys ];
            for(TaskStreamAssessment__c c:courses)
            {
                keyMap.put(c.AssessmentIDKey__c,c.id);
            }  
        }
        // fill up student and course by given pidm and course code.
        for(TaskStreamTask__c ts:TriggerNew)
        {
            ts.Student__c=pidmMap.get(ts.pidm__c);
            ts.TaskStreamAssessment__c=keyMap.get(ts.AssessmentIDKey__c);
        }
        // tracking errors
        for(TaskStreamTask__c ts:TriggerNew)
        {    
            if (ts.TaskStreamAssessment__c==null )
            { 
               ts.TaskStreamAssessment__c.addError('====error: cannot find corresponding TaskStreamAssessment for given assessmentIDKey : '+ts.AssessmentIDKey__c + ' Assessment dictionary filled:' + keyMap.size()+'/' +keys.size());
               System.debug('====error: cannot find corresponding TaskStreamAssessment for given assessmentIDKey  : '+ts.AssessmentIDKey__c + ' Assessment dictionary filled:' + keyMap.size()+'/' +keys.size()); 
             //  reporterror('====error: cannot find corresponding TaskStreamAssessment for given course code : '+ts.AssessmentIDKey__c);
            }
            if ( ts.Student__c==null)
            { 
               ts.Student__c.addError('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c);
               System.debug('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c);  
             //  reporterror('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c); 
            }
             
        }  
        system.debug('%%%%%%%%%%%taskstream utility task end:%%%%%%%%%%%%%%% '+triggernew);
    }
      
    //look up contacts and courses and set them into look up fields
    public static void processLookUpFieldsOfAssessment(List<TaskstreamAssessment__c> triggernew)
    {  
        /*
            fill up the lookup field to specific student
        */
        system.debug('%%%%%%%%%%% Taskstreamutility utility assessment start:%%%%%%%%%'+triggernew);
        Map<String,id> pidmMap=new Map<String,id>();   //map from pidm to student
        Set<String> pidms=new Set<String>();           //set of all pidms 
        //build 1 sets
        for(TaskStreamAssessment__c tst :  Triggernew)
        {
            pidms.add(tst.pidm__c);  
        }  
        //build 1 maps
        if(!pidms.isEmpty())
        {
            List<contact> contacts=[select id,pidm__c from contact where pidm__c in :pidms];
            for(contact c:contacts)
            {
                pidmMap.put(c.pidm__c,c.id);
            } 
        } 
      
        // fill up student by given pidm 
        for(TaskStreamAssessment__c ts:TriggerNew)
        {
            ts.Student__c=pidmMap.get(ts.pidm__c);
        }
        // tracking errors
        for(TaskStreamAssessment__c ts:TriggerNew)
        {     
            if ( ts.Student__c==null)
            { 
               ts.Student__c.addError('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c);
               System.debug('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c); 
               
            }
             
        }  
        system.debug('%%%%%%%%%%%taskstream utility assessment end:%%%%%%%%%%%%%%% '+triggernew);
    }
    
    /************************************************************************************************************
    * Maps the Student and Task Stream Assessment Master-Detail fields for the Task Stream Task Failures objects.
    *************************************************************************************************************/
    public static void processLookUpFieldsOfTaskFailures(List<TaskStreamTaskFailure__c> triggernew)
    {  
        //fill up the lookup field to specific student
        system.debug('%%%%%%%%%%% Taskstreamutility utility task failure start:%%%%%%%%%'+triggernew);
        Map<String,id> pidmMap=new Map<String,id>();   //map from pidm to student
        Set<String> pidms=new Set<String>();           //set of all pidms
        Map<Double,id> keyMap=new Map<Double,id>();   //map from code to courses
        Set<Double> keys=new Set<Double>();           //set of all course code
        
        //build 2 sets
        for(TaskStreamTaskFailure__c tst :  Triggernew)
        {
            pidms.add(tst.pidm__c); 
            keys.add(tst.AssessmentIDKey__c); 
        }
        
        //build 2 maps
        if(!pidms.isEmpty())
        {
            List<contact> contacts=[select id,pidm__c from contact where pidm__c in :pidms];
            for(contact c:contacts)
            {
                pidmMap.put(c.pidm__c,c.id);
            } 
        }
        
        if(!keys.isEmpty())
        {
            //( pidm + assessment code) pair up as a key -> taskstreamassessment
            List<TaskStreamAssessment__c> courses=[select id, AssessmentIDKey__c  from TaskStreamAssessment__c where AssessmentIDKey__c in :keys ];
            for(TaskStreamAssessment__c c:courses)
            {
                keyMap.put(c.AssessmentIDKey__c,c.id);
            }  
        }
        
        // fill up student and course by given pidm and course code.
        for(TaskStreamTaskFailure__c ts:TriggerNew)
        {
            ts.Student__c=pidmMap.get(ts.pidm__c);
            ts.TaskStreamAssessment__c=keyMap.get(ts.AssessmentIDKey__c);
        }
        
        // tracking errors
        for(TaskStreamTaskFailure__c ts:TriggerNew)
        {    
            if (ts.TaskStreamAssessment__c==null )
            { 
               ts.TaskStreamAssessment__c.addError('====error: cannot find corresponding TaskStreamAssessment for given assessmentIDKey : '+ts.AssessmentIDKey__c + ' Assessment dictionary filled:' + keyMap.size()+'/' +keys.size());
               System.debug('====error: cannot find corresponding TaskStreamAssessment for given assessmentIDKey  : '+ts.AssessmentIDKey__c + ' Assessment dictionary filled:' + keyMap.size()+'/' +keys.size()); 
             //  reporterror('====error: cannot find corresponding TaskStreamAssessment for given course code : '+ts.AssessmentIDKey__c);
            }
            if ( ts.Student__c==null)
            { 
               ts.Student__c.addError('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c);
               System.debug('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c);  
             //  reporterror('====error: cannot find corresponding student for given pidm of this record :'+ts.pidm__c); 
            }
             
        }
        
        system.debug('%%%%%%%%%%%taskstream utility task failure end:%%%%%%%%%%%%%%% '+triggernew);
    }
    
    /*@future
    static void reporterror(String message)
    {
        Errormessage__c err=new errormessage__c();
        err.detail__c=message;
        insert err;
    }*/
    
    /***************************************************************************************************************************************
    * Deletes all Task Stream Assessments and Tasks with an Activity Date before a given cut-off date.
    * The cut-off is determined by taking the current date and subtracting the number of months (numMonths) to retain from it.
    * numMonths is a positive Integer that defines how many months of Assessments going back from the current date that will not be deleted.
    * This is currently untested and should remain commented out for now.
    ****************************************************************************************************************************************/
    /*@future
    public static void deleteOldTaskStreamAssessments(Integer numMonths)
    {
        date curDate = date.today();
        date cutOff = curDate.addMonths(numMonths * -1);
    
        list<TaskStreamAssessment__c> DeleteList = [select ID from TaskStreamAssessment__c where ActivityDate__c < :cutOff]; 

        delete DeleteList;
    }*/
}