/*
* Utility class for the StudentCourseVersionNameTrigger
* Created by Katarina Melki 4/10/2013 
*   Edit by Will Slade 2/18/14 for program change course version updates
*	Edit by Yemeng Zhu Mar 2014 "Pass" no longer change the CaseLoad of this course after we switch to StudentAcademicCourse.
*/
public class StudentCourseVersionUtility
{
    //Clears Student Course Engagement information from StudentCourseRegistration__c when Completed__c is set to true.
    public static void removeStudentEngagement(List<StudentCourseVersion__c> triggernew, List<StudentCourseVersion__c> triggerold)
    {
        List<StudentCourseRegistration__c> CourseRegistrations=new List<StudentCourseRegistration__c>();
        Map<Id, boolean> mapOldCompleted=new Map<Id, boolean>();
      //  List<StudentCourseVersion__c> completes=new List<StudentCourseVersion__c>();
        
        for(StudentCourseVersion__c oldCourseVersion: triggerold)
        {
            mapOldCompleted.put(oldCourseVersion.Id, oldCourseVersion.Completed__c);
        }
        
        for(StudentCourseVersion__c CourseVersion: triggernew)
        {
            if (CourseVersion.Completed__c && CourseVersion.CompletedDate__c>date.today().addDays(-1) && !mapOldCompleted.get(CourseVersion.Id) && CourseVersion.StudentCourseRegistration__c!=null)
            {
                CourseRegistrations.add(new StudentCourseRegistration__c(Id=CourseVersion.StudentCourseRegistration__c, IsEngaged__c=false, EngagementNotedBy__c=null, EngagementNotedDate__c=null));
                system.debug(CourseVersion);
            }
         /*   if(CourseVersion.Completed__c||CourseVersion.Status__c =='Completed')
            {
                completes.add(CourseVersion);
            }*/
        }
        
        update CourseRegistrations;
      //  CourseMentorStudentAssignmentUtility.removeAssignmentsForPassedCourses(completes,'Pass');
    }

///////////////////////////// Begin Program Change Course Section ///////////////////////////////////

    public static void checkValidCourses(String degreeUpdatedListJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture())
        {
            processCheckValidCourses(degreeUpdatedListJSON);
        }
        else
        {
            asyncCheckValidCourses(degreeUpdatedListJSON);
        }
    }
    
    @future
    public static void asyncCheckValidCourses(String degreeUpdatedListJSON)
    {
        processCheckValidCourses(degreeUpdatedListJSON);
    }

    public static void processCheckValidCourses(String degreeUpdatedListJSON)
    {
        List<Contact> degreeUpdatedList = (List<Contact>) JSON.deserialize(degreeUpdatedListJSON, List<Contact>.class);
        List<Id> wguDegreePrograms = new List<Id>(); 
        List<Id> contactIds = new List<Id>();       
        List<WGUCourseInProgram__c> wguCourseInPrograms = new List<WGUCourseInProgram__c>();
        List<StudentCourseVersion__c> fullSCVList = new List<StudentCourseVersion__c>();
        Set<StudentCourseVersion__c> deleteSet = new Set<StudentCourseVersion__c>();
        List<StudentCourseVersion__c> deleteList = new List<StudentCourseVersion__c>();        
        Set<Id> scvSet = new Set<Id>();
        Map<Id, Id> studentToDPMap = new Map<Id, Id>();        
        Map<Id, Id> cipToDPMap = new Map<Id, Id>();
        Map<Id, Id> cipToCourseMap = new Map<Id, Id>();
        Map<Id, Id> wcvToWcMap = new Map<Id, Id>();
        Map<Id, Id> scvToStudentMap = new Map<Id, Id>();
        Map<Id, Id> scvToCourseMap = new Map<Id, Id>();
        Map<Id, Set<Id>> studentToCourseListMap = new Map<Id, Set<Id>>();
        
        //Build map linking students to their new degree plans
        //Build lists of degree programs and contact ids
        for (Contact degreeUpdated : degreeUpdatedList)
        {                
            wguDegreePrograms.add(degreeUpdated.WGUDegreeProgram__c);
            studentToDPMap.put(degreeUpdated.Id, degreeUpdated.WGUDegreeProgram__c);
            contactIds.add(degreeUpdated.Id);
        }
        
        //Build list of all student course version records for contacts in trigger
        fullSCVList = [SELECT Id, Student__c, WGUCourseVersion__r.WGUCourse__c
                       FROM StudentCourseVersion__c
                       WHERE Student__c IN :contactIds];                       
        
        //Build list of all WGU Courses in Program for degree programs in list                      
        wguCourseInPrograms = [SELECT Id, Program__c, Course__c
                               FROM WGUCourseInProgram__c
                               WHERE Program__c IN :wguDegreePrograms];
        
        //Build map for course in program to degree program
        //Build map for course in program to WGU course                       
        for (WGUCourseInProgram__c wcip : wguCourseInPrograms)
        {             
            cipToDPMap.put(wcip.Id, wcip.Program__c);
            cipToCourseMap.put(wcip.Id, wcip.Course__c);
        }
        
        //Build map for student course version to contact
        //Build map for student course version to WGU course
        for (StudentCourseVersion__c scv : fullSCVList)
        {              
            scvToStudentMap.put(scv.Id, scv.Student__c);
            scvToCourseMap.put(scv.Id, scv.WGUCourseVersion__r.WGUCourse__c);
        }
        
        scvSet = scvToStudentMap.keySet();
        
        //For each contact, build a list of WGU courses in their current program and add it to a map
        for (Contact degreeUpdated : degreeUpdatedList)
        {      
            Set<Id> thisCourseSet = new Set<Id>();
            
            for (Id cipId : cipToDPMap.keySet())
            {             
                if (cipToDPMap.get(cipId) == studentToDPMap.get(degreeUpdated.Id))
                {               
                    thisCourseSet.add(cipToCourseMap.get(cipId));
                }
            }
            
            studentToCourseListMap.put(degreeUpdated.Id, thisCourseSet);
        }
        
        //For each student course version, verify the corresponding WGU course exists in the list of the map for the student
        for (StudentCourseVersion__c scv : fullSCVList)
        {      
            Set<Id> thisCourseSet = studentToCourseListMap.get(scvToStudentMap.get(scv.Id));
            
            for (Id thisCourse : thisCourseSet)
            {          
                if (!thisCourseSet.contains(scvToCourseMap.get(scv.Id)) && !deleteSet.contains(scv))
                {
                    deleteSet.add(scv);               
                    deleteList.add(scv);
                }
            }          
        }
        
        delete deleteList;                          
    }
}

////////////////////////////// End Program Change Course Section ////////////////////////////////////