/*
 * Author Paul Stay
 * Western Governors University
 *
 * Date November 12, 2012
 * Revised: (security audit compliance: with sharing) 
 *
 * Utility class for Mentor Course Assignment Object
 *
 * Based on AccountUtility and broken out so we can do testing with a future method.
 *
 */
 
 public with sharing class MentorCourseAssignmentUtility {
     
    public static boolean firstRun = true;
    
    public static void triggerMentorCourseAssignment(List<MentorCourseAssignment__c> mentorAssignments){
        Map<String,ID> mentorMap = new Map<String,ID>();
        Set<String> mentorPidms = new Set<String>();
        
        for(MentorCourseAssignment__c course : mentorAssignments){
            if (course.MentorPidm__c != null) {
              mentorPidms.add(course.MentorPidm__c);           
            }
        }        
        for(User u : [SELECT id, Pidm__c from User where PIDM__C In :mentorPidms] ){
            mentorMap.put(u.PIDM__c, u.Id);           
        }
    
        // Setup the mentor assignment for this course.
        for(MentorCourseAssignment__c course : MentorAssignments){
            course.Mentor__c = course.Mentor__c == null ? mentorMap.get(course.MentorPidm__c) : course.Mentor__c;
        }
    }    
    
    /*
        new methods for mentor group assignment and mentor course assignment    
    */
    // fill up the WGUCourse__c lookup field for MentorCourseAssignment__c before insert/update
    public static void findWGUCourseForMentorCourseAssignment(List<MentorCourseAssignment__c> triggernew){
        Map<String,ID> courseMap = new Map<String,ID>();
        Set<String> codes = new Set<String>(); 
        //get a set of all course codes
        for(MentorCourseAssignment__c assignment : triggernew){
            if (assignment.CourseNumber__c != null) {
              codes.add(assignment.CourseNumber__c);
            }
        }
        //build the map of coursecode->WGUCourse__c
        for(WGUCourse__c wgucourse:[select id, name from WGUCourse__c where name IN :codes])
        {
            courseMap.put(wgucourse.name, wgucourse.id);
        }
        //fill the field of WGUCourse__c  
        for(MentorCourseAssignment__c assignment : triggernew)
        {
            assignment.WGUCourse__c=courseMap.get(assignment.CourseNumber__c);
        }        
    }
    // fill up the WGUCourse__c lookup field for MentorCourseGroup__c before insert/update
    public static void findWGUCourseForMentorCourseGroup(List<MentorCourseGroup__c> triggernew){
        Map<String,ID> courseMap = new Map<String,ID>();
        Set<String> codes = new Set<String>(); 
        //get a set of all course codes
        for(MentorCourseGroup__c mcgroup : triggernew){
            if (mcgroup.CourseNumber__c != null) {
              codes.add(mcgroup.CourseNumber__c);
            }
        }
        //build the map of coursecode->WGUCourse__c
        for(WGUCourse__c wgucourse:[select id,bannercode__c from WGUCourse__c where bannercode__c IN :codes])
        {
            courseMap.put(wgucourse.bannercode__c, wgucourse.id);
        }
        //fill the field of WGUCourse__c     
        for(MentorCourseGroup__c mcgroup : triggernew)
        {
            mcgroup.WGUCourse__c=courseMap.get(mcgroup.CourseNumber__c);
        }        
    }
    
    //Insert/Update Mentor Course Assign control objects
    public static void addMentorAssignToBanner(String assignJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled())
        {
            processAddMentorAssignToBanner(assignJSON);
        }
        else
        {
            asyncAddMentorAssignToBanner(assignJSON);
        }
    }
     
    @future
    public static void asyncAddMentorAssignToBanner(String assignJSON)
    {
        processAddMentorAssignToBanner(assignJSON);
    }
     
    public static void processAddMentorAssignToBanner(String assignJSON)
    {
        List<MentorCourseAssignment__c> assignList=(List<MentorCourseAssignment__c>)JSON.deserialize(assignJSON, List<MentorCourseAssignment__c>.class);
        
        //Build up an Id Map and Set for existing control objects
        Map<Id, Id> existingControlMap=new Map<Id, Id>();
        
        List<MentorCourseAssignToBanner__c> addList=new List<MentorCourseAssignToBanner__c>();
        
        for (MentorCourseAssignment__c Assign :assignList)
        {
            existingControlMap.put(Assign.Id, null);            
        }
        
        Set<Id> assignIds=existingControlMap.keySet();
        
        //Query for existing control objects
        List<MentorCourseAssignToBanner__c> existingControls=[select Id, ActionNeeded__c, MentorCourseAssignment__c, MentorOfficeHours__c,
                                                              MentorCourseAssignment__r.MentorOfficeHours__c
                                                              from MentorCourseAssignToBanner__c where MentorCourseAssignment__c in :assignIds];
        
        //Update existing control objects' ActionNeeded
        for (MentorCourseAssignToBanner__c control : existingControls)
        {
            existingControlMap.put(control.MentorCourseAssignment__c, control.Id);            
            control.ActionNeeded__c=control.ActionNeeded__c=='Insert' ? 'Insert' : 'Update';
            try
            {
                control.MentorOfficeHours__c = DateStringHandler.convertOfficeHoursJSONtoString(control.MentorCourseAssignment__r.MentorOfficeHours__c);
            }
            catch (Exception e)
            {
                control.MentorOfficeHours__c = '';
            }          
        }
        
        //Loop through all objects one last time to create control objects for those lacking one already.
        for (MentorCourseAssignment__c Assign :assignList)
        {
            if (existingControlMap.get(Assign.Id)==null)
            {
                if (Test.isRunningTest())
                {
                    addList.add(new MentorCourseAssignToBanner__c(ActionNeeded__c='Insert'));                                                                               
                }            
                else if (Assign.MentorOfficeHours__c == null)
                {
                    addList.add(new MentorCourseAssignToBanner__c(ActionNeeded__c='Insert', CourseNumber__c=Assign.CourseNumber__c, 
                                                                  MentorCourseAssignment__c=Assign.Id, MentorPIDM__c=Assign.MentorPIDM__c));                                                                                
                }
                else
                {
                    try
                    {                    
                        addList.add(new MentorCourseAssignToBanner__c(ActionNeeded__c='Insert', CourseNumber__c=Assign.CourseNumber__c, 
                                                                      MentorCourseAssignment__c=Assign.Id, MentorPIDM__c=Assign.MentorPIDM__c,
                                                                      MentorOfficeHours__c = DateStringHandler.convertOfficeHoursJSONtoString(Assign.MentorOfficeHours__c)));
                    }
                    catch (Exception e)
                    {
                        addList.add(new MentorCourseAssignToBanner__c(ActionNeeded__c='Insert', CourseNumber__c=Assign.CourseNumber__c, 
                                                                      MentorCourseAssignment__c=Assign.Id, MentorPIDM__c=Assign.MentorPIDM__c));                       
                    }
                }
            }            
        }
        
        insert addList;
        update existingControls;
    }
     
    //Insert/Update Mentor Course Group control objects
    public static void addMentorGroupToBanner(String assignJSON)
    {
        if (Limits.getFutureCalls() > 3 || System.isFuture() || System.isBatch() || System.isScheduled())
        {
            processAddMentorGroupToBanner(assignJSON);
        }
        else
        {
            asyncAddMentorGroupToBanner(assignJSON);
        }
    }
     
    @future
    public static void asyncAddMentorGroupToBanner(String assignJSON)
    {
        processAddMentorGroupToBanner(assignJSON);
    }
     
    public static void processAddMentorGroupToBanner(String assignJSON)
    {
        List<MentorCourseGroup__c> assignList=(List<MentorCourseGroup__c>)JSON.deserialize(assignJSON, List<MentorCourseGroup__c>.class);
        
        //Build up an Id Map and Set for existing control objects
        Map<Id, Id> existingControlMap=new Map<Id, Id>();
        
        List<MentorCourseGroupToBanner__c> addList=new List<MentorCourseGroupToBanner__c>();
        
        for (MentorCourseGroup__c Assign :assignList)
        {
            existingControlMap.put(Assign.Id, null);            
        }
        
        Set<Id> assignIds=existingControlMap.keySet();
        
        //Query for existing control objects
        List<MentorCourseGroupToBanner__c> existingControls=[select Id, ActionNeeded__c, MentorCourseGroup__c from MentorCourseGroupToBanner__c where MentorCourseGroup__c in :assignIds];
        
        //Update existing control objects' ActionNeeded
        for (MentorCourseGroupToBanner__c control : existingControls)
        {
            existingControlMap.put(control.MentorCourseGroup__c, control.Id);            
            control.ActionNeeded__c=control.ActionNeeded__c=='Insert' ? 'Insert' : 'Update';
        }
        
        //Loop through all objects one last time to create control objects for those lacking one already.
        for (MentorCourseGroup__c Assign :assignList)
        {
            if (existingControlMap.get(Assign.Id)==null)
            {
                addList.add(new MentorCourseGroupToBanner__c(ActionNeeded__c='Insert', CourseNumber__c=Assign.CourseNumber__c, MentorCourseGroup__c=Assign.Id));
            }
        }
        
        insert addList;
        update existingControls;
    }
}