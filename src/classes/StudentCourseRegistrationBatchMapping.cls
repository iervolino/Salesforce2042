global class StudentCourseRegistrationBatchMapping
  implements Database.Batchable<sObject> {
  global String Query;
  global List<String> emails;
  global StudentCourseRegistrationBatchMapping(List<String> pEmails) {
    if(pEmails != null) {
      emails = pEmails;
    }
    init();
  }
  global StudentCourseRegistrationBatchMapping() {
    emails = new List<String>();
    init();
  }
  private void init() {
    Query = 'select Student__c,PIDM__c ,name'
      + ' from StudentCourseRegistration__c '
      + ' where Student__c = null ';
    emails.add('gchild@solutionstream.com');
  }
  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(Query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<StudentCourseRegistration__c> SCRs = (List<StudentCourseRegistration__c>)scope;
    List<String> pidms = new List<String>();
    for(StudentCourseRegistration__c scr : SCRs) {
      pidms.add(scr.PIDM__c);
    }

    List<Contact> students = [
      select PIDM__c
      from Contact
      where PIDM__c in :pidms
    ];
    Map<String,Id> pidmToId = new Map<String,Id>();
    for(Contact s : students) {
      pidmToId.put(s.PIDM__c,s.Id);
    }
    List<StudentCourseRegistration__c> updateScrs = new List<StudentCourseRegistration__c>();
    for(StudentCourseRegistration__c scr : SCRs) {
      scr.Student__c = pidmToId.get(scr.PIDM__c);
      scr.name=scr.coursecode__C;
      //if(scr.UniqueId__c.split('-',5).size() < 3) {
      //  scr.UniqueId__c = scr.UniqueId__c + '-' + scr.TermCode__c;
     // }
      updateScrs.add(scr);
    }
    update updateScrs;
  }

  global void finish(Database.BatchableContext BC){
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    mail.setToAddresses(emails);
    mail.setReplyTo('gchild@solutionstream.com');
    mail.setSenderDisplayName('Salesforce Batch Processing');
    mail.setSubject('StudentCourseRegistration Mapping Completed');
    mail.setPlainTextBody('Batch Process has completed');

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}