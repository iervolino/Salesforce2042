@isTest
public class TestFDPTriggers{
   @IsTest
    public static void testFDPCourseCancelTrigger(){
   FDPCourseCancel__C cal=new FDPCourseCancel__C();
   cal.uniqueid__c='test';
   insert cal;

}
 @IsTest
    public static void testStudentCompletionCourseTrigger(){
     //StudentCompletionCourse__c cal=new  StudentCompletionCourse__c(BannerActivityDate__c =Date.now(),Complete__c='Completed',PIDM__c='11' ,StatusDate__c=Date.now(),Student__c  ='12312', TermCode__c='201206',UniqueId__c='test' , WGUCourseVersion__c='123123' );
    // insert cal;

    }

}