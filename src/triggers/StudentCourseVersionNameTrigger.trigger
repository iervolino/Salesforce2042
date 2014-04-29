trigger StudentCourseVersionNameTrigger on StudentCourseVersion__c (before update, after update) 
{
    if (trigger.isBefore)
    {
      Set<String> wguCourseVersionIds = new Set<String>();
      List<StudentCourseVersion__c> updatedCourseVersions = new List<StudentCourseVersion__c>();
      for(StudentCourseVersion__c v: trigger.new){
        if(v.WGUCourseVersion__c != trigger.oldMap.get(v.Id).WGUCourseVersion__c
            || v.StatusDate__c   != trigger.oldMap.get(v.Id).StatusDate__c
            || v.Status__c       != trigger.oldMap.get(v.Id).Status__c
            || v.Student__c      != trigger.oldMap.get(v.Id).Student__c) {
          wguCourseVersionIds.add(v.WGUCourseVersion__c);
          updatedCourseVersions.add(v);
        }
      }
      if(updatedCourseVersions.size() == 0) {
        return;
      }
    
      Map<Id,String> courseVersionToCourse = new Map<Id,String>();
      List<WGUCourseVersion__c> courseVersions = [
        select Id,WGUCourse__c
        from WGUCourseVersion__c
        where Id in :wguCourseVersionIds];
      for(WGUCourseVersion__c cv : courseVersions) {
        courseVersionToCourse.put(cv.Id, cv.WGUCourse__c);
      }
    
      for(StudentCourseVersion__c cv: updatedCourseVersions) {
        if(cv.Status__c == 'Failed') {
          String shortDate = FDPUtilities.formatVeryShortDate(cv.StatusDate__c);
          cv.Name = cv.Student__c
            + '-' + courseVersionToCourse.get(cv.WGUCourseVersion__c)
            + '-' + shortDate;
        } else {
          cv.Name = cv.Student__c + '-' + courseVersionToCourse.get(cv.WGUCourseVersion__c);
        }
      }
    }
    
    if(trigger.isAfter)
    {
    	StudentCourseVersionUtility.removeStudentEngagement(trigger.new, trigger.old);
    }
}