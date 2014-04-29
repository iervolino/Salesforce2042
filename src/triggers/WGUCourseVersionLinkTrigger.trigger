trigger WGUCourseVersionLinkTrigger on WGUCourseVersion__c (before insert,before update,after insert,after update) {
  if(Trigger.isBefore){
    Set<Integer> courseids=new Set<Integer>();
    for(WGUCourseVersion__c v:Trigger.new){
      courseids.add(Integer.valueOf(v.PAMSCOURSEID__c));
    }
    List<WGUCourse__c> courses=[select Id,
      PAMSId__c
      from WGUCourse__c
      where PAMSId__c in :courseids];
    Map<Integer,id> idmap = new Map<Integer,id>();
    for(WGUCourse__c c : Courses) {
      idmap.put(Integer.valueOf(c.PAMSId__c),c.id);
    }
    for(WGUCourseVersion__c v:Trigger.new) {
      v.WGUCourse__c = idmap.get(Integer.valueOf(v.PAMSCOURSEID__c));
    }
  } else if(Trigger.isAfter) {
    FDPUtilities.updateCourseLatestVersion(trigger.new);
  }
}