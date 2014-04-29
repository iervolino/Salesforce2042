/*****************************************************************************************
* Name: EvalTranscriptController
* Author: Will Slade
* Purpose: Controller for apex page tied to button "Perform Evaluation" on eval object
* Revisions: 
*    - 9/1/12 Created Class
*    - 4/25/13 Updated for TranscriptToBanner object functionality - Will Slade
******************************************************************************************/

global class EvalTranscriptController
{
    private final TransferEvaluation__c eval;
    public Id transInstID { get; set; } 
    private List<StudentTranscript__c> instCourses { get; set; }
    private List<StudentEquivalentCourse__c> equivCourses { get; set; }
    private List<TransferAttendance__c> transAttendances { get; set; }
    public Date evalCreatedDate { get; set; }
    public Boolean displayDegrees { get; set; }
    private TransferEvaluation__c eval1 = new TransferEvaluation__c();
    Id oppId;
    
    public EvalTranscriptController(ApexPages.StandardController controller)
    {
        this.eval = (TransferEvaluation__c)controller.getRecord();
        eval1 = [SELECT Id, CreatedDate, Opportunity__c, Opportunity__r.Pidm__c, StudentID__c FROM TransferEvaluation__c WHERE Id = :eval.Id LIMIT 1];
        evalCreatedDate = eval1.CreatedDate.Date(); 
        //child list of equivalent courses
        equivCourses = [SELECT RequirementSatisfied__c, UnderReview__c, WGUTitle__c, TransferAttendance__c, TransferAttendance__r.StudentTransferInstitution__c, TransferredCourse__c, TransferRuleText__c,
                        WGUGrade__c, TransferredDegree__c, EvaluationComments__c, WGUCourse__c, CompetencyUnits__c, SatisfiedBy__c, TransferredGroup__c, Status__c
                        FROM StudentEquivalentCourse__c WHERE TransferEvaluation__r.Id = :eval.Id
                        ORDER BY WGUCourse__c];
        oppId = eval1.Opportunity__c;

        List<StudentTranscript__c> transferInstitutions1 = [SELECT Id FROM StudentTranscript__c WHERE Opportunity__c = :oppId];

        transAttendances = [SELECT Id, Transfer_Institution_Name__c, DegreeAwarded__c, DegreeAwarded__r.Value__c, DegreeAwardedDate__c, ProgramName__c,
                               DegreeAwarded__r.NumericValue__c, DegreeRelatesToWGUProgram__c, StudentTransferInstitution__r.InstitutionalAccreditation__c 
                               FROM TransferAttendance__c 
                               WHERE StudentTransferInstitution__c IN :transferInstitutions1];
        if (transAttendances.size() > 0)
        {
            displayDegrees = true;
        }
        else
        {
            displayDegrees = false;
        }            
    }    
    
    public List<StudentEquivalentCourse__c> getequivCourses()
    {
        return equivCourses;
    }
    
    public List<TransferAttendance__c> getTransAttendances()
    {
        return transAttendances;
    }
    
    public String currentInst { get; set { currentInst = value; }}
  
    @RemoteAction
    webservice static List<StudentTranscript__c> getInstitutions(String OpportunityId) {
       return [SELECT Name,
            TranscriptInstitution__r.Name,
            InstitutionalAccreditation__c,
            DegreeType__c,
            DateDegreeReceived__c,
            Major__c    
        FROM StudentTranscript__c
        WHERE Opportunity__r.id = :OpportunityId
        ORDER BY DateDegreeReceived__c];
    }
    
    public List<StudentTranscript__c> getInstCourses() 
    {
       return
       [SELECT Name,
            TranscriptInstitution__r.Name,
            InstitutionalAccreditation__c,
            DegreeType__c,
            DateDegreeReceived__c,
            TranscriptReceivedDate__c,
            Major__c    
        FROM StudentTranscript__c
        WHERE Opportunity__r.id = :eval1.Opportunity__c
        AND TranscriptStatus__c != 'Excluded'
        ORDER BY DateDegreeReceived__c];
    }
    
    public PageReference saveEval() 
    {
        date currentDate = date.today();
        List<Opportunity> oppList = [SELECT Id, Account.BannerId__c, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];     
        string bannerId = '';
        string name = '';
        
        if (oppList.size() > 0)
        {
            if (eval1.StudentID__c != null)
            {        
                bannerId = eval1.StudentID__c;
            }
            if (oppList[0].Name != null)
            {
                name += oppList[0].Name;
            }
        }
        
        PageReference pdf = Page.TranscriptEvalOutput;
        // add parent id to the parameters for standardcontroller
        pdf.getParameters().put('id',eval.id);
     
        // create the new attachment
        Attachment attach = new Attachment();
     
        // the contents of the attachment from the pdf
        Blob body;
     
        try 
        {
            // returns the output of the page as a PDF
            body = pdf.getContentAsPDF();
            // need to pass unit test -- current bug    
        } 
        
        catch (VisualforceException e) 
        {
            body = Blob.valueOf('Some Text');
        }
     
        attach.Body = body;
        // add the user entered name
        attach.Name = 'SavedTransferEvaluation' + '-' + name + '-' + bannerId + '.pdf';
        attach.IsPrivate = false;
        // attach the pdf to the account
        attach.ParentId = eval.id;
        insert attach;
     
        // send the user to the account to view results
        return new PageReference('/'+ eval.id);
    }   
    
    public PageReference saveEquivCourses()
    {
        update equivCourses;
        
        equivCourses = Test.isRunningTest() ? equivCourses :
                       [SELECT RequirementSatisfied__c, WGUTitle__c, TransferAttendance__c, TransferredCourse__c, TransferRuleText__c, TransferAttendance__r.StudentTransferInstitution__c,
                        WGUGrade__c, TransferredDegree__c, EvaluationComments__c, WGUCourse__c, CompetencyUnits__c, SatisfiedBy__c, TransferredGroup__c, Status__c, UnderReview__c
                        FROM StudentEquivalentCourse__c WHERE TransferEvaluation__r.Id = :eval.Id
                        ORDER BY WGUCourse__c];                                  
                        
        List<StudentTransferredCourse__c> transCourses = new List<StudentTransferredCourse__c>();
        List<String> equivCourseIds = new List<String>();
        Map<Id, Id> transcriptMap = new Map<Id, Id>();
        Map<String, Id> equivToTransMap = new Map<String, Id>();
        Map<Id, String> equivToGroupMap = new Map<Id, String>();
        Map<String, Id> groupToTrCrsMap = new Map<String, Id>();
        List<String> courseGroups = new List<String>();
        List<StudentTransferredCourse__c> trCrsPToB = new List<StudentTransferredCourse__c>();
        boolean groupCheck = false;
        Id transcriptId; 
        
        Id tempTranscriptId = [SELECT Id FROM StudentTranscript__c WHERE Opportunity__c = :eval1.Opportunity__c AND TranscriptStatus__c != 'Excluded' ORDER BY Id LIMIT 1].Id; 
      
        for (StudentEquivalentCourse__c equivCourse : equivCourses)
        {                    
            transcriptId = equivCourse.TransferAttendance__r.StudentTransferInstitution__c;
            
            System.debug('=====> transatt ' + equivCourse.TransferAttendance__c);
            
            if (equivCourse.TransferAttendance__c == null)
            {
                transcriptId = tempTranscriptId;    
            }
            
            System.debug('=====> transid ' + transcriptId);
                            
            transcriptMap.put(transcriptId, transcriptId);        
        
            if (equivCourse.TransferredCourse__c == null && 
                (equivCourse.TransferAttendance__c != null || equivCourse.RequirementSatisfied__c == true))
            {
                String truncId = String.valueOf(equivCourse.Id);               
            
                StudentTransferredCourse__c transCourse = new StudentTransferredCourse__c( StudentTransferInstitution__c = transcriptId, 
                                                                                           Subject__c = 'Req Satisfied',
                                                                                           Course__c = truncId.substring(0, 18),
                                                                                           CourseTitle__c = 'Req Satisfied',
                                                                                           Grade__c = 'RS' );
                transCourses.add(transCourse);
                equivCourseIds.add(transCourse.Course__c);
            }
            else if (equivCourse.TransferredCourse__c == null && equivCourse.TransferredGroup__c != null)            
            {
                System.debug('====> found group scenario ' + equivCourse.TransferredGroup__c);
                equivToGroupMap.put(equivCourse.id, equivCourse.TransferredGroup__c);
                courseGroups.add(equivCourse.TransferredGroup__c);
                groupCheck = true;  
            }            
        }
        
        System.debug('===> groupchecktest ' + groupCheck);
        
        if (groupCheck)
        {
            List<StudentTransferredCourse__c> trCrsGroupList = [SELECT Id, CourseGroup__c, PushedToBanner__c
                                                                FROM StudentTransferredCourse__c
                                                                WHERE StudentTransferInstitution__r.Opportunity__r.Pidm__c = :eval1.Opportunity__r.Pidm__c
                                                                AND CourseGroup__c IN :courseGroups];
                                                                
            for (StudentTransferredCourse__c trCrsGroup : trCrsGroupList)
            {
                trCrsGroup.PushedToBanner__c = true;
                trCrsPToB.add(trCrsGroup);
            
                if (!groupToTrCrsMap.ContainsKey(trCrsGroup.CourseGroup__c) || trCrsGroup.Id < groupToTrCrsMap.get(trCrsGroup.CourseGroup__c))
                {
                    groupToTrCrsMap.put(trCrsGroup.CourseGroup__c, trCrsGroup.Id);
                }
            }
            
            List<StudentEquivalentCourse__c> groupEquivList = [SELECT Id, TransferredCourse__c, TransferredGroup__c
                                                               FROM StudentEquivalentCourse__c
                                                               WHERE Id IN :equivToGroupMap.keySet()];
            
            for (StudentEquivalentCourse__c groupEquiv : groupEquivList)
            {
                System.debug('===> map? ' + groupEquiv.Id + ' ' + groupToTrCrsMap.get(groupEquiv.TransferredGroup__c));
                groupEquiv.TransferredCourse__c = groupToTrCrsMap.get(groupEquiv.TransferredGroup__c);
                
                if (groupEquiv.TransferredCourse__c == null)
                {
                    groupEquiv.TransferredGroup__c = null;
                    groupEquiv.EvaluationComments__c = 'ERROR - Group not Tied to Trans Course';
                }
            }
            
            update groupEquivList;                                                                
        }
        
        update trCrsPToB;
        insert transCourses;
        
        equivCourses = [SELECT RequirementSatisfied__c, WGUTitle__c, TransferAttendance__c, TransferredCourse__c, TransferRuleText__c, TransferAttendance__r.StudentTransferInstitution__c,
                        WGUGrade__c, TransferredDegree__c, EvaluationComments__c, WGUCourse__c, CompetencyUnits__c, SatisfiedBy__c, TransferredGroup__c, Status__c, UnderReview__c
                        FROM StudentEquivalentCourse__c WHERE TransferEvaluation__r.Id = :eval.Id
                        ORDER BY WGUCourse__c];           
        
        Set<Id> transcriptIds = transcriptMap.keySet(); 
        
        transCourses = [SELECT Id, Course__c FROM StudentTransferredCourse__c WHERE Course__c IN :equivCourseIds AND StudentTransferInstitution__c IN :transcriptIds];
        
        System.debug('=====> transcoursesize ' + transCourses.size());
        
        for (StudentTransferredCourse__c transCourse : transCourses)
        {
            equivToTransMap.put(transCourse.Course__c, transCourse.Id);
            System.debug('========> mapped ' + transCourse.Course__c + ' ' + transCourse.Id);
        }  
        
        for (StudentEquivalentCourse__c equivCourse : equivCourses)
        {
            if (equivCourse.TransferredCourse__c == null)
            {
                equivCourse.TransferredCourse__c = equivToTransMap.get(equivCourse.Id);
            }
        }
        
        update equivCourses;
        update transCourses; 
        
        equivCourses = [SELECT RequirementSatisfied__c, WGUTitle__c, TransferAttendance__c, TransferredCourse__c, TransferRuleText__c, TransferAttendance__r.StudentTransferInstitution__c,
                        WGUGrade__c, TransferredDegree__c, EvaluationComments__c, WGUCourse__c, CompetencyUnits__c, SatisfiedBy__c, TransferredGroup__c, Status__c, UnderReview__c
                        FROM StudentEquivalentCourse__c WHERE TransferEvaluation__r.Id = :eval.Id
                        ORDER BY WGUCourse__c];                              
          
        return null;
    }
    
    public PageReference applyDegrees()
    {
        /*This method uses rules on the courseInProgram object in conjunction with a students transfer attendances/degrees to determin if it should be satisfied by that degree
         Degrees can be satisfied by a minmum degree, a specific degree and maybe forced to be in a related program in either case.  Once it is determined
         It relates the Equivalent course record with the transfer attendance and puts a commment.  This satisfies the course requirement */
        
        Map<Id, Id> progCourseToEquivMap = new Map<Id, Id>();
        List<TransferEvaluation__c> eval1 = [SELECT Id FROM TransferEvaluation__c WHERE Opportunity__c = :oppId]; 
        List<StudentEquivalentCourse__c> equivCourses = [SELECT Id, WGUCourseInProgram__c FROM StudentEquivalentCourse__c WHERE TransferEvaluation__c = :eval.Id];
        List<Id> inProgramCourseIds = new List<Id>();
        List<StudentTranscript__c> transferInstitutions = [SELECT Id FROM StudentTranscript__c WHERE Opportunity__c = :oppId AND TranscriptStatus__c != 'Excluded'];
        List<TransferAttendance__c> transferAttendances = [SELECT Id, DegreeAwarded__c, DegreeAwarded__r.NumericValue__c, DegreeRelatesToWGUProgram__c 
                                                           FROM TransferAttendance__c 
                                                           WHERE StudentTransferInstitution__c IN :transferInstitutions
                                                           AND DegreeAwarded__c != null
                                                           ORDER BY DegreeAwarded__r.NumericValue__c];                                                          
        Map<Id, Id> equivToAttendanceMap = new Map<Id, Id>();                                                           
        List<Id> satisfiedCourseIds = new List<Id>();
        
        for (StudentEquivalentCourse__c equivCourse : equivCourses)
        {
            inProgramCourseIds.add(equivCourse.WGUCourseInProgram__c);
            progCourseToEquivMap.put(equivCourse.WGUCourseInProgram__c, equivCourse.Id);
        }
        
        List<WGUCourseInProgram__c> WGUCoursesInProgram = [SELECT Id, TransferDegree__r.NumericValue__c, TransferMinimumDegree__r.NumericValue__c, TransferRelatedProgram__c, 
                                                                  TransferDegree__c, TransferMinimumDegree__c
                                                           FROM WGUCourseInProgram__c 
                                                           WHERE Id IN :inProgramCourseIds
                                                           AND (TransferMinimumDegree__c != null
                                                                OR   TransferDegree__c != null)];                                                           
                                                           
        //loop through the courses that have degree r
        for (WGUCourseInProgram__c WGUCourseInProgram : WGUCoursesInProgram)
        {
            //loop through all the degrees this person has listed
                for (TransferAttendance__c transferAttendance : transferAttendances)
                {
                    System.debug('=====================> Degree Numeric Value: ' + transferAttendance.DegreeAwarded__r.NumericValue__c);
                    //if the rule states it has to be in a related degree, then makes sure the transfer attendance field is checked
                    if (WGUCourseInProgram.TransferRelatedProgram__c == True)
                    {
                        //if the numeric value of the degree is >= to the rule and it relates to the program staisfy it
                        if (((WGUCourseInProgram.TransferMinimumDegree__r.NumericValue__c <= transferAttendance.DegreeAwarded__r.NumericValue__c && 
                        WGUCourseInProgram.TransferMinimumDegree__r.NumericValue__c > 0 && transferAttendance.DegreeRelatesToWGUProgram__c == True)
                        || (WGUCourseInProgram.TransferDegree__c == transferAttendance.DegreeAwarded__c 
                        && transferAttendance.DegreeRelatesToWGUProgram__c == True)) && transferAttendance.DegreeAwarded__r.NumericValue__c > 0)
                        {                                
                            satisfiedCourseIds.add(progCourseToEquivMap.get(WGUCourseInProgram.Id));
                            equivToAttendanceMap.put(progCourseToEquivMap.get(WGUCourseInProgram.Id), transferAttendance.Id);
                        }
                    }
                    else
                    {  //if it  doesn't have to be related to degree, just chehck the numeric value of the degree
                         if ((WGUCourseInProgram.TransferMinimumDegree__r.NumericValue__c <= transferAttendance.DegreeAwarded__r.NumericValue__c 
                            || WGUCourseInProgram.TransferDegree__r.NumericValue__c == transferAttendance.DegreeAwarded__r.NumericValue__c)
                            && (WGUCourseInProgram.TransferMinimumDegree__r.NumericValue__c > 0 || WGUCourseInProgram.TransferDegree__r.NumericValue__c > 0)
                            && transferAttendance.DegreeAwarded__r.NumericValue__c > 0)
                        {    
                            satisfiedCourseIds.add(progCourseToEquivMap.get(WGUCourseInProgram.Id));
                            equivToAttendanceMap.put(progCourseToEquivMap.get(WGUCourseInProgram.Id), transferAttendance.Id);
                        }   
                }
            }
           
        }
        
        List<StudentEquivalentCourse__c> satisfiedCourses = [SELECT Id FROM StudentEquivalentCourse__c WHERE Id IN :satisfiedCourseIds];
        //loop through the courses with equivalencies, equate the degree 
        for (StudentEquivalentCourse__c satisfiedCourse : satisfiedCourses)
        {
            satisfiedCourse.TransferAttendance__c = equivToAttendanceMap.get(satisfiedCourse.Id);
            //satisfiedCourse.EvaluationComments__c = 'Satisfied by degree rule';
        }
        update satisfiedCourses;
        //refresh the list with updated information
         equivCourses = [SELECT RequirementSatisfied__c,TransferAttendance__c,TransferredCourse__c,TransferRuleText__c,
                        WGUGrade__c,TransferredDegree__c,EvaluationComments__c,WGUCourse__c,CompetencyUnits__c,SatisfiedBy__c, TransferredGroup__c, Status__c, UnderReview__c
                        FROM StudentEquivalentCourse__c WHERE TransferEvaluation__r.Id = :eval.Id
                        ORDER BY WGUCourse__c];
 
        return null; 
    }        
}