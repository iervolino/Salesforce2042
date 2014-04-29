trigger StudentCourseRegistrationTrigger on StudentCourseRegistration__c (before insert,before update,after insert,after update) {
  if (Trigger.isBefore){
    List<String> pidms = new List<String>();
      Map<String, string> completionMap = new Map<String, string>();
      List<String> completionCodes = new List<String>();
      for(StudentCourseRegistration__c scr : Trigger.New) {
        completioncodes.add(scr.CourseCode__c);
      }
      if(!completionCodes.isEmpty()) {
        List<WGUCourse__c> tasks = [
          select Id, Name,LatestVersion__c
          from WGUCourse__c
          where Name in :completionCodes
        ];
        for(WGUCourse__c task : tasks){
          completionMap.put(task.name, task.id);
        }
      }

      for(StudentCourseRegistration__c scr : Trigger.New) {
        if(scr.Student__c == null) {
          pidms.add(scr.PIDM__c);
        }
      }
      List<Contact> students = [
        select PIDM__c,Name
        from Contact
        where PIDM__c in :pidms
      ];
      Map<String,ID> pidmToId = new Map<String,Id>();
      for(Contact s : students) {
        pidmToId.put(s.PIDM__c,s.Id);
      }
      for(StudentCourseRegistration__c scr : Trigger.New) {
        if(scr.Student__c == null) {
          scr.Student__c = pidmToId.get(scr.PIDM__c);
        }
        if(completionMap.get(scr.CourseCode__c) != null) {
          scr.WGUCourse__c = completionMap.get(scr.CourseCode__c);
        }
      }
  }
  else if (Trigger.isAfter){
      FDPUtilities.updateEnrolledCourses(Trigger.New,Trigger.oldMap);
  }
}