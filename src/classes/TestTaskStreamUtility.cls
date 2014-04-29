/*
Author Yemeng Zhu , Katarina Melki 
Western Governer University
 11/8/2012

Tester of Taskstream Utility and Trigger function. 
*/
 
@IsTest
private class TestTaskStreamUtility
{
    /*  assessment insertion */
    static testmethod void testLookUpOfAssessment()
    {  
    
        system.debug('### Test zero ###');
        List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');
        
        List<sObject> assessments=Test.loadData(TaskStreamAssessment__c.sObjectType, 'TaskStreamAssessmentTestData');
        
        TaskStreamAssessment__c course2=new TaskStreamAssessment__c(AssessmentCode__c='LAT1', 
                                                                             ActivityDate__c=date.newInstance(2008, 12, 1),
                                                                             pidm__c='000000',
                                                                             overallstatus__c='IP',
                                                                             AssessmentIDKey__c=4444);            
        Test.startTest();
        try{ 
            insert course2;
         }catch(Exception e){
        }
        Test.stopTest(); 
        system.assert([select id,student__c, student__r.pidm__c from taskstreamassessment__c where pidm__c='1111'].size()==2  );  
        system.assert([select id,student__c, student__r.pidm__c from taskstreamassessment__c where pidm__c='000000'].size()==0  );
    }
    
    /*  given taskstream object with pidm, insert, then the trigger should be able to associate correct contact with same pidm    */
    static testmethod void testLookUpOfStudentsP()
    {  
    
        system.debug('### Test one ###');
        List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');
        
        List<sObject> assessments=Test.loadData(TaskStreamAssessment__c.sObjectType, 'TaskStreamAssessmentTestData');        
        
        Test.startTest();
        List<sObject> tasks=Test.loadData(TaskStreamTask__c.sObjectType, 'TaskStreamTaskTestData');
        Test.stopTest();
        String pidm=[select id,student__c, student__r.pidm__c from taskstreamtask__c where pidm__c='1111'][0].student__r.pidm__c; 
        system.assert( pidm=='1111' );    
        
        String code=[select id, TaskStreamAssessment__c,TaskStreamAssessment__r.AssessmentCode__c from taskstreamtask__c where pidm__c='1111'][0].TaskStreamAssessment__r.AssessmentCode__c; 
        system.assert( code=='LAT1' );
    }
    
    //Tests Master-Detail fields set by the utility for the Task Stream Task Failure object.
    static testmethod void testLookUpOfTaskFailures()
    {
        system.debug('### Test one ###');
        List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');
        
        List<sObject> assessments=Test.loadData(TaskStreamAssessment__c.sObjectType, 'TaskStreamAssessmentTestData');
        
        TaskstreamTaskFailure__c tc=new TaskstreamtaskFailure__c(PIDM__c ='1111',
                                                   LastFailedAttempt__c=datetime.newInstance(2008, 12, 1),
                                                   Name='LAT1',
                                                   NumberFailedAttempts__c=4,
                                                   TaskTitle__c='testing',
                                                   AssessmentIDKey__c=4444,
                                                   TaskFailureKey__c=10000);
        
       
        Test.startTest(); 
        insert tc;
        Test.stopTest();
        String pidm=[select id,student__c, student__r.pidm__c from taskstreamtaskfailure__c where pidm__c='1111'][0].student__r.pidm__c; 
        system.assert( pidm=='1111' );    
        
        String code=[select id, TaskStreamAssessment__c,TaskStreamAssessment__r.AssessmentCode__c from taskstreamtaskfailure__c where pidm__c='1111'][0].TaskStreamAssessment__r.AssessmentCode__c; 
        system.assert( code=='LAT1' );
    }
    
    /*  test 4 success and 2 fail */
    static testmethod void testFailTheInvalidTaskstreamRecord()
    {
        system.debug('### Test two ###');
    
        List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');        
        
        List<sObject> assessments=Test.loadData(TaskStreamAssessment__c.sObjectType, 'TaskStreamAssessmentTestData');                                                                                             
                                                                           
        List<sObject> tasks=Test.loadData(TaskStreamTask__c.sObjectType, 'TaskStreamTaskTestData');
        
        //These two tasks are custom created to fail insert.
        List<TaskstreamTask__c> tc=new List<Taskstreamtask__c>();
        tc.add(new Taskstreamtask__c        (PIDM__c ='4444',
                                                   ActivityDate__c=datetime.newInstance(2012, 2, 1),
                                                   AssessmentCode__c='EET4',
                                                   Status__c='0',
                                                   TaskTitle__c='testing',
                                                   AssessmentIDKey__c=666,
                                                   TaskIDKey__c=1003));                                           
        tc.add(new Taskstreamtask__c        (PIDM__c ='6666',
                                                   ActivityDate__c=datetime.newInstance(2012, 2, 1),
                                                   AssessmentCode__c='EET5',
                                                   Status__c='0',
                                                   TaskTitle__c='testing',
                                                   AssessmentIDKey__c=555,
                                                   TaskIDKey__c=1004));
        
        Contact studentContact=[select ID from Contact where pidm__c='1111'];
        
        Test.startTest();  
        try{
            database.insert( tc,false);
          // insert tc;
        }catch(Exception e){
        }        
         
        Test.stopTest();       
        //should be only 3 taskstreams inserted 
        Set<String> pidms = new Set<String>{'1111','2222', '3333','4444','6666'};
        integer count=[select id,student__c, student__r.pidm__c from taskstreamtask__c where pidm__c in :pidms].size();
        system.debug('#### count '+count);
        system.assert(count==4);
        //test master-detail relationships
        delete studentContact;
        system.assert([select id from taskstreamtask__c ].size() ==2);      
        system.assert([select id from taskstreamassessment__c ].size() ==4);     
      /*  system.debug([select id,detail__c from errormessage__c]);     
        system.assert(  [select id,detail__c from errormessage__c].size()==3);    */            
    }
    
    /*  test decimal number of keymap */
    static testmethod void testDecimalNumberField()
    {    
       	system.debug('### Test three ###');
    
       	List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');        
        
        List<sObject> assessments=Test.loadData(TaskStreamAssessment__c.sObjectType, 'TaskStreamAssessmentTestData');
                                                                           
        //create taskstreams, intend to fail at 4 and 5 for student__c and course
        List<TaskstreamTask__c> tc=new List<Taskstreamtask__c>();
        tc.add(new Taskstreamtask__c        (PIDM__c ='1111',
                                                   ActivityDate__c=datetime.newInstance(2012, 2, 1),
                                                   AssessmentCode__c='EET1',
                                                   Status__c='0',
                                                   TaskTitle__c='testing',
                                                   AssessmentIDKey__c=111.0, // decimal 111.0
                                                   TaskIDKey__c=1000));
        
        Contact studentContact=[select ID from Contact where pidm__c='1111'];
                                       
        Test.startTest();   
        database.insert( tc,false);  
        Test.stopTest();         
        // should be able to math 111 to 111.0 in trigger
        integer count=[select id,student__c, student__r.pidm__c from taskstreamtask__c].size();
        system.debug('#### count '+count); 
        system.assert(count==1 );    
        //test master-detail relationships
        delete studentContact;
        system.assert([select id from taskstreamtask__c where pidm__c='1111'].size() ==0);      
        system.assert([select id from taskstreamassessment__c where pidm__c='1111'].size() ==0); 
    }
    
    /*  test before update of assessment by linking new tasks*/
    static testmethod void testBeforeUpdateAssessment()
    {
       	system.debug('### Test three ###');
    
        List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');        
        
        List<sObject> assessments=Test.loadData(TaskStreamAssessment__c.sObjectType, 'TaskStreamAssessmentTestData');
                                                                           
        //create taskstreams, intend to fail at 4 and 5 for student__c and course
        List<TaskstreamTask__c> tc=new List<Taskstreamtask__c>();
        tc.add(new Taskstreamtask__c        (PIDM__c ='1111',
                                                   ActivityDate__c=datetime.newInstance(2012, 2, 1),
                                                   AssessmentCode__c='EET1',
                                                   Status__c='0',
                                                   TaskTitle__c='testing',
                                                   AssessmentIDKey__c=111.0, // decimal 111.0
                                                   TaskIDKey__c=1000)); 
        tc.add(new Taskstreamtask__c        (PIDM__c ='1111',
                                                   ActivityDate__c=datetime.newInstance(2012, 2, 1),
                                                   AssessmentCode__c='EET1',
                                                   Status__c='2',
                                                   TaskTitle__c='testing1',
                                                   AssessmentIDKey__c=111.0, // decimal 111.0
                                                   TaskIDKey__c=1001));
        
        Contact studentContact=[select ID from Contact where pidm__c='1111'];
                                       
        Test.startTest();   
        database.insert( tc,false);  
        Test.stopTest();         
        // should be able to math 111 to 111.0 in trigger
        integer count=[select id,student__c, student__r.pidm__c from taskstreamtask__c].size();
        system.debug('#### count '+count); 
        system.assert(count==2 );    
        //test master-detail relationships
        delete studentContact;
        system.assert([select id from taskstreamtask__c where pidm__c='1111'].size() ==0);      
        system.assert([select id from taskstreamassessment__c where pidm__c='1111'].size() ==0); 
    }
    
    //Test deleting assessments
    //The delete function is currently unimplemented.
    /*static testmethod void testDeleteOldTaskStreamAssessments()
    {
        system.debug('### Test four ###');
        
        List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');
        
        date curDate = date.today();
        date cutOff = curDate.addMonths(-8);
        
        List<TaskStreamAssessment__c> course=new List<TaskStreamAssessment__c>();
        course.add(new TaskStreamAssessment__c  (AssessmentCode__c='EET1',
                                                                             ActivityDate__c=curDate,
                                                                             pidm__c='1111',
                                                                             overallstatus__c='IP' ,AssessmentIDKey__c=111));
        course.add(new TaskStreamAssessment__c  (AssessmentCode__c='EET2',                                                                             
                                                                             ActivityDate__c=cutOff,
                                                                             pidm__c='1111',
                                                                             overallstatus__c='IP' ,AssessmentIDKey__c=222));
        insert course;
        
        //At this point we should see two assessments
        system.assert([select id from taskstreamassessment__c ].size() == 2);
        
        Test.startTest();  
        try
        {
            TaskStreamUtility.deleteOldTaskStreamAssessments(6);
        }
        catch(Exception e)
        {
        }
        Test.stopTest();
        
        //Now we should only see one assessment
        system.assert([select id from taskstreamassessment__c ].size() == 1); 
    }*/
}