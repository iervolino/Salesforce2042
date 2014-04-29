trigger MentorCourseAssignmentTrigger on MentorCourseAssignment__c (before insert, before update, after update, after insert, before delete) 
{
    if (Trigger.isBefore)
    {
        if (Trigger.isInsert || Trigger.isUpdate)
        {
            // assign mentor by pidm
            MentorCourseAssignmentUtility.triggerMentorCourseAssignment(Trigger.new);
            // assign WGUCourse by course number
            MentorCourseAssignmentUtility.findWGUCourseForMentorCourseAssignment(Trigger.new);
        }
        
        if (Trigger.isDelete)
        {
            //Update control records to Delete action and send delete email
            Set<Id> assignIds=new Set<Id>();
            
            for (MentorCourseAssignment__c assign : Trigger.old)
            {
                assignIds.add(assign.Id);
            }
            
            List<MentorCourseAssignToBanner__c> existingControls=[select Id, ActionNeeded__c, MentorCourseAssignment__c from MentorCourseAssignToBanner__c where MentorCourseAssignment__c in :assignIds];
            
            for (MentorCourseAssignToBanner__c control : existingControls)
            {
                control.ActionNeeded__c='Delete';
                control.MentorCourseAssignment__c=null;
            }
            
            update existingControls;
        }
    }
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))// && MentorCourseAssignmentUtility.firstRun)
    {
        //Add/Update Insert/Update Control Record
        MentorCourseAssignmentUtility.addMentorAssignToBanner(JSON.serialize(Trigger.New));
        
        //MentorCourseAssignmentUtility.firstRun=false;
    }
    
    //Remove Case Load records if MentorCourseAssignments:
    //1. turned to inactive
    //2. deleted from salesforce
    //2/26 comment out before mentor's feedback
    if (Trigger.isAfter && Trigger.isUpdate)
    {
        //CourseMentorStudentAssignmentUtility.removeIfMentorCourseAssignmentChange(trigger.new,false);
    }
    else if (Trigger.isBefore&& Trigger.isDelete)
    {
        //CourseMentorStudentAssignmentUtility.removeIfMentorCourseAssignmentChange(trigger.old,true);
    }
    
}