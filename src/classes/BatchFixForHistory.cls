global class BatchFixForHistory implements Database.Batchable<sObject> {
   global final String query;

   global BatchFixForHistory (String q) {
     query = q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      List<Studentcompletioncourse__C>stccs=scope;
  List<studentcourseversion__C> stvs=[select id ,student__C from studentcourseversion__C where studentcompletioncourse__C in :stccs];
  List<studentcourse__C>oldcourses=[select id from studentcourse__C where studentcourseversion__C in :stvs];
  Set<String> ss=new Set<String>();
  for(studentcourseversion__C sc: stvs){
  ss.add(sc.student__C);
  }
  List<Contact> students=[select id,wgudegreeprogram__C from contact where id in :ss];
  delete stvs;
  delete oldcourses;
  
  List<studentcourseversion__C> cvs=new  List<studentcourseversion__C>();
  List<studentcourse__C> cs=new  List<studentcourse__C>();
  for(Contact student:students){
  List<studentcourseversion__C> rr=    [select wgucourseversion__r.wgucourse__C from studentcourseversion__C where student__C=:student.id ];
  set<String> cours=new set<String>();
      for (studentcourseversion__C c:rr){
      cours.add(c.wgucourseversion__r.wgucourse__C);
      }
      List<wguCourseinProgram__C> missings= [select id,course__r.latestversion__C,course__r.name from wgucourseinprogram__C where  program__C = :student.WGUDegreeProgram__C and course__C not in :cours];
   List<studentdegreeplans__C> dps= [select id,student__c, (select id,name,student__c from studentterms__r where startdate__C> TODAY  or (startdate__C<TODAY and enddate__C > TODAY)  order by startdate__C asc limit 2) from studentdegreeplans__C  where student__C =:student.id]; 
      
         for (studentdegreeplans__C plan:dps){
           if (plan.studentterms__r.size()>0){
            studentterm__C term=plan.studentterms__r[0];
            if (plan.studentterms__r.size()>1)
              term=plan.studentterms__r[1];
            
             for (wguCourseinProgram__C c:missings){
                StudentCourseversion__C cv=new StudentCourseversion__C();
                cv.status__C='Planned';
                cv.name=c.course__r.name;
                cv.student__C=plan.student__C;
                cv.wgucourseversion__C=c.course__r.latestversion__C;
                cvs.add(cv);
                StudentCourse__c sc=new Studentcourse__c();
                sc.name=c.course__r.name;
                sc.student__C=plan.student__C;
                sc.studentterm__c=term.id;
                sc.studentcourseversion__r=cv;
                sc.status__c='Planned';
                cs.add(sc);
             }
           }
         }
         }
        
          if (cvs.size()>0)
         insert cvs;
         if (cs.size()>0){
        for(Studentcourse__C c:cs){
          c.studentcourseversion__c=c.studentcourseversion__r.id;
        }
        insert cs;
      
        }
  
   }

   global void finish(Database.BatchableContext BC){}
}