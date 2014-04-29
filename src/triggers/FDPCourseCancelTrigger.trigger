trigger FDPCourseCancelTrigger on   FDPCourseCancel__c (after insert) {
  FDPUtilities.doCourseCancelation(trigger.new);

}