public class OppTranscriptController
{
    private final Opportunity opp;
    public Id TransInstID { get; set; }  
    public Id CurrentInstID {get; set;}
    public string testout {get; set;}
    public string NewSubject {get; set;}
    public string NewTitle {get; set;}
    public string NewCrseName {get; set;}
    public decimal NewCredits{get; set;}
    public string NewGrade {get; set;}
    public string NewCourseGroup {get; set;}
    public string NewTerm {get; set;}
    private List<StudentTranscript__c> InstCourses { get; set; }                                                  
    public List<StudentTransferredCourse__c> courses { get; set; }       
    
    public OppTranscriptController(ApexPages.StandardController controller)
    {
        this.opp = (Opportunity)controller.getRecord();
        testout ='initial';
    }    
    
    public String currentInst { get; set { currentInst = value; }}

    public  PageReference save()
    {
        courses= InstCourses[0].TransferCourses__r;
            testout = courses[0].name + courses[0].id;
            update courses;
            return null;
    }
    
    public PageReference add()
    {         
         if (NewSubject != '' && NewCrseName != '')
         {
             StudentTransferredCourse__c newCourse = new StudentTransferredCourse__c(
                                                                                        StudentTransferInstitution__c = CurrentInstID, 
                                                                                        subject__c = NewSubject,
                                                                                        Course__c = NewCrseName,
                                                                                        CourseTitle__c = NewTitle,
                                                                                        CourseGroup__c = NewCourseGroup,
                                                                                        Credits__c = NewCredits,
                                                                                        Grade__c = NewGrade,
                                                                                        Term__c = NewTerm
                                                                                    );
            
            //StudentTranscript__c transcript = new StudentTranscript__c();
            
            //transcript.Opportunity__c = ApexPages.currentPage().getParameters().get('id');
            //transcript.TranscriptInstitution__c =currentInst ;
            
            insert newCourse;
        
            //PageReference secondPage = new PageReference('http://espn.com');
            //secondPage.setRedirect(true);
            //return secondPage; 
            NewSubject = null;
            NewSubject =null;
            NewTitle =null;
            NewCourseGroup =null;
            NewCredits=null;
            NewGrade=null;
            NewTerm=Null;
        }
        return null;
    }
  
    public List<StudentTranscript__c> getInstCourses() 
    {
        /*Id oppId = ApexPages.currentPage().getParameters().get('id');
        if (oppId == null)
        {
            oppId = [SELECT Id FROM Opportunity WHERE Name = 'testEvalCourseTriggerOpp'].Id;
        }*/            
           
         InstCourses =
        [   select Name, 
            TranscriptInstitution__r.Name,
            TranscriptReceivedDate__c, 
            TranscriptStatus__c,
        (select Name,Subject__c, CourseGroup__c, CourseTitle__c ,Credits__c,Grade__c, Term__c, Course__c
        from TransferCourses__r 
        where Subject__c != 'Req Satisfied'
        order by Term__c, Subject__c, Name) ,
        (select TransferAttendance__c.Name,DegreeAwarded__c, StartDate__c, EndDate__c, GPA__c,DegreeRelatesToWGUProgram__c  from  TransferAttendances__r)    
        from StudentTranscript__c
        where opportunity__r.id = :opp.Id
        and TranscriptStatus__c != 'Excluded'
        order by TranscriptInstitution__r.Name];
        
        //courses = InstCourses[0].TransferCourses__r;
        return InstCourses;
    }     
}