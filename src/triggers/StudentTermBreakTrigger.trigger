trigger StudentTermBreakTrigger on StudentTermBreak__c (before insert,before update) {
  List<String> pidms = new List<String>();
  for(StudentTermBreak__c scr : Trigger.New) {
    if(scr.Student__c == null) {
      pidms.add(scr.PIDM__c);
    }
  }
  if(pidms.size() > 0) {
    List<Contact> students = [
      select PIDM__c,Name
      from Contact
      where PIDM__c in :pidms
    ];
    Map<String,ID> pidmToId = new Map<String,Id>();
    for(Contact s : students) {
      pidmToId.put(s.PIDM__c,s.Id);
    }
    for(StudentTermBreak__c scr : Trigger.New) {
      if(scr.Student__c == null) {
        scr.Student__c = pidmToId.get(scr.PIDM__c);
      }
    }
  }
}