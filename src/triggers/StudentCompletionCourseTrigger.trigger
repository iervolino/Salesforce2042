trigger StudentCompletionCourseTrigger on StudentCompletionCourse__c (before insert, before update,after insert,after update) {
   if (Trigger.isBefore && (Trigger.isUpdate ||Trigger.isInsert)) {
      FDPUtilities.linkCompletionCourse(Trigger.new);
   } else if (Trigger.isAfter && (Trigger.isUpdate ||Trigger.isInsert)) {
      FDPUtilities.updateCompletedCourses(Trigger.new,Trigger.oldMap);
      //FDPUtilities.checkForCompletionStatusChange(Trigger.new,Trigger.oldMap);
   }
}