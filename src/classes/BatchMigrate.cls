global class BatchMigrate implements Database.Batchable<sObject> {
   global final String query;

   global BatchMigrate() {
     query = 'select id,Name,processed__c from FDPMigrationStudent__C where processed__c = false';
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      List<String> pidms = new List<String>();
    for(sObject ms :scope){
    FDPMigrationStudent__C mstudent=(FDPMigrationStudent__C)ms;
        pidms.add(mstudent.Name);
        mstudent.processed__c = true;
    }

    list<StudentDegreeplans__C> plans = [select id,old_id__C from studentdegreeplans__C where isapproved__C=true and student__r.pidm__C IN :pidms];
    for(StudentDegreeplans__C plan: plans) {
        plan.old_id__C='N';
    }

    update plans;
    update scope;

      
   }

   global void finish(Database.BatchableContext BC){}

}