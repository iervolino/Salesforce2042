trigger MentorCourseGroupTrigger on MentorCourseGroup__c(before insert, before update, before delete, after insert, after update) 
{
    if (Trigger.isBefore) 
    { 
        if (Trigger.isInsert || Trigger.isUpdate)
        {
            //assign WGUCourse by courseNumber
            MentorCourseAssignmentUtility.findWGUCourseForMentorCourseGroup(Trigger.new);
        }
        
        if (Trigger.isDelete)
        {
            //Update control records to Delete action
            Set<Id> assignIds=new Set<Id>();
            
            for (MentorCourseGroup__c assign : Trigger.old)
            {
                assignIds.add(assign.Id);
            }
            
            List<MentorCourseGroupToBanner__c> existingControls=[select Id, ActionNeeded__c, MentorCourseGroup__c from MentorCourseGroupToBanner__c where MentorCourseGroup__c in :assignIds];
            
            for (MentorCourseGroupToBanner__c control : existingControls)
            {
                control.ActionNeeded__c='Delete';
                control.MentorCourseGroup__c=null;
            }
            
            update existingControls;
        }
    }
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) && MentorCourseAssignmentUtility.firstRun)
    {
        //Add/Update Insert/Update Control Record
        MentorCourseAssignmentUtility.addMentorGroupToBanner(JSON.serialize(Trigger.New));
        
        MentorCourseAssignmentUtility.firstRun=false;
    }
}