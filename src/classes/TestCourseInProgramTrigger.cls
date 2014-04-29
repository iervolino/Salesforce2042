@isTest
public class TestCourseInProgramTrigger {
     public static testMethod void testInsert(){
        WGUDegreeProgram__c program=new WGUDegreeProgram__c();
        program.Active__c=true;
        program.PAMSID__c=1234567;
        program.Name='testprogram';
        insert program;
        WGUCourse__c definition = new WGUCourse__c();
        definition.name = 'testcourse';
        definition.PAMSID__c=999999;
        insert definition;
         WGUCourseInProgram__c tie = new WGUCourseInProgram__c();
       
        tie.PAMSCourseID__c = 999999;
        tie.PAMSProgramID__c=1234567;
       
        insert tie;
       tie=[select course__C,program__C from WGUCourseInProgram__c where PAMSCourseID__c=999999 ];
        system.assertequals(tie.course__C,definition.id);
         system.assertequals(tie.program__C,program.id);
         
         
    
     
     }
      public static testMethod void testupdate(){
        WGUDegreeProgram__c program=new WGUDegreeProgram__c();
        program.Active__c=true;
        program.PAMSID__c=1234567;
        program.Name='testprogram';
        insert program;
        WGUCourse__c definition = new WGUCourse__c();
        definition.name = 'testcourse';
        definition.PAMSID__c=999999;
        insert definition;
     
         WGUCourseInProgram__c tie = new WGUCourseInProgram__c();
       
        tie.PAMSCourseID__c =7654321 ;
        tie.PAMSProgramID__c=7654322;
       
        insert tie;
       tie=[select course__C,program__C from WGUCourseInProgram__c where PAMSCourseID__c=7654321 limit 1];
         system.assertequals(tie.course__C,null);
         system.assertequals(tie.program__C,null);
           tie.PAMSCourseID__c = 999999;
        tie.PAMSProgramID__c=1234567;
        update tie;
        tie=[select course__C,program__C from WGUCourseInProgram__c where PAMSCourseID__c=999999 limit 1];
         system.assertequals(tie.course__C,definition.id);
         system.assertequals(tie.program__C,program.id);
         
         
    
     
     }
      

}