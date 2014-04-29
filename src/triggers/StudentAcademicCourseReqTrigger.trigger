trigger StudentAcademicCourseReqTrigger on StudentAcademicCourseRequirement__c (before insert, before update,after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        StudentAcademicCourseReqUtility.updateContactEmailSent(JSON.serialize(Trigger.new));                    
    }
}