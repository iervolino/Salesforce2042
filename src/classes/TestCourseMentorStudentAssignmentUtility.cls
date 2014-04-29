/*
 * Author yemeng zhu
 * Western Governors University
 *
 * 3/38/3013
 *
 *
 * Test course mentor assignments.
 * Multiple Assessment version. (modified from old FDP courses)
 */
@isTest
private with sharing class  TestCourseMentorStudentAssignmentUtility
{


    /*
         create manual assignment for course mentor only.
         reject other type mentors
         reject mentor who run out of 'free spots' ( maxstudents == currentstudents )
    */
    static testmethod void testBasicMethods() {
     
    insert new CourseList__c(CourseLong__c='all');
    ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
    ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
    ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
    Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId );
   
    String CourseCode='AAC1';
    Mentor__c mentorCourse=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true); 
    Mentor__c mentorStudent=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Student Mentor',pidm__c='2222',available__c=false);
    Mentor__c mentorBusy=new Mentor__c(maxStudents__c=10,currentStudents__c=10,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true);
    Mentor__c mentorReassign=new Mentor__c(maxStudents__c=10,currentStudents__c=5,mentorRole__c='Course Mentor',pidm__c='4444',available__c=true);
    Mentor__c mentorManual=new Mentor__c(maxStudents__c=10,currentStudents__c=5,mentorRole__c='Course Mentor',pidm__c='5555',available__c=true);
   
        Test.startTest();
            insert student;
            insert mentorCourse;
            insert mentorStudent;
            insert mentorBusy;
            insert mentorReassign;
            insert mentorManual; 
            
            StudentAcademicCourse__c sac=new StudentAcademicCourse__c(studentContact__c=student.id,CourseCode__c=CourseCode,startdate__c=date.today(), Term__c = Datetime.NOW().format('yyyyMM'), status__c = 'Registered');
   
            insert sac;
            system.debug('step1'); 
            System.assert( [SELECT count() FROM User WHERE ContactId = :student.Id] == 0, 'CONTACT ALREADY HAS A USER RECORD, before Contact update, User account already exists' );
             
            system.debug('step2');
            //block if available__c=fales; student mentor should allowed cus we nolonger care about mentorRole field 
            boolean result= CourseMentorStudentAssignmentUtility.createAssignment(mentorStudent, sac,'Manual');
            System.assert(result==false);
            System.assert(mentorStudent.currentStudents__c==0);
            System.assert([select id,student__c from CourseMentorStudentAssignment__c where student__c = :student.id].size()==0);
            
            
            system.debug('step3');
            //busy mentor should be allowed
            result= CourseMentorStudentAssignmentUtility.createAssignment(mentorBusy, sac,'Manual');
            System.assert(result==true);
            System.assert(mentorBusy.currentStudents__c==11);
            System.assert([select id,student__c ,isActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and isActive__c=true].size()==1);
            
           
            
           
         //re-assign
            system.debug('step4');
            CourseMentorStudentAssignment__c ass=[select id,student__c,mentor__c, mentor__r.pidm__c, mentor__r.currentstudents__c,IsActive__c  from CourseMentorStudentAssignment__c where student__c = :student.id].get(0);
            system.assert(CourseMentorStudentAssignmentUtility.reassignMentor(ass,mentorBusy)==false); //same mentor, nothing change
            
            //re-assign another mentor, new assignment created, old assignment deactive
            System.assert([select id,student__c,mentor__c, mentor__r.pidm__c, mentor__r.currentstudents__c  from CourseMentorStudentAssignment__c where student__c = :student.id].get(0).Mentor__r.pidm__c=='3333');
            result=CourseMentorStudentAssignmentUtility.reassignMentor(ass,mentorStudent);
            system.assert(result==false); 
            result=CourseMentorStudentAssignmentUtility.reassignMentor(ass,mentorReassign);
            system.assert(result==true); 
            system.assert([select id,student__c,mentor__c, mentor__r.pidm__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id].size()==2);
            //have 1 active record with mentor 4444
            ass=[select id,student__c,mentor__c, mentor__r.pidm__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c=true ].get(0);  
            System.assert(ass.Mentor__r.pidm__c=='4444'); 
            //have 1 inactive old record with mentor 3333 
            ass=[select id,student__c,mentor__c, mentor__r.pidm__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c=false ].get(0);  
            System.assert(ass.Mentor__r.pidm__c=='3333'); 
            
            System.assert(CourseMentorStudentAssignmentUtility.reassignMentor(null,null)==false); 
             
            system.debug('step5');
            
         //course mentor should pass, assignment should be created.
            result= CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse, sac,'Manual');//1111
            System.assert(result==true);
            System.assert([select id, currentStudents__c from Mentor__c where id=:mentorCourse.id][0].currentStudents__c==1);
            //3 record, 2 old record for 4444, 3333, and 1 new active one for 1111
            System.assert([select id,student__c from CourseMentorStudentAssignment__c where student__c = :student.id].size()==3);
            System.assert([select id,student__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c =true].size()==1);
            System.assert([select id,student__c ,mentor__c, mentor__r.pidm__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c =true][0].mentor__r.pidm__c =='1111');
            system.debug('step6');
        //remove
            system.debug('step7');
            ass=[select id,student__c,mentor__c, mentor__r.pidm__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c=true ].get(0);  
            CourseMentorStudentAssignmentUtility.removeAssignment(ass,'Test'); 
            System.assert([select id,student__c from CourseMentorStudentAssignment__c where student__c = :student.id].size()==3);
            System.assert([select id,student__c ,IsActive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c =true].size()==0);
            System.assert(CourseMentorStudentAssignmentUtility.removeAssignment(null,'Test')==false); 
           
            //manual
            system.debug('step8');
           
        Test.stopTest();
           
        
      }
      
      static testmethod void testManual()
      {
        insert new CourseList__c(CourseLong__c='all');
        ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
        ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
        ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
        Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='DasterdlyTesterson', RecordTypeId=studentContactRecordTypeId );
       
        String CourseCode='AAC1';
        Mentor__c mentorManual=new Mentor__c(maxStudents__c=10,currentStudents__c=5,mentorRole__c='Course Mentor',pidm__c='5555',available__c=true);
        Test.startTest();
            insert student;
            insert mentorManual;
            system.debug('step1'); 
            System.assert( [SELECT count() FROM User WHERE ContactId = :student.Id] == 0, 'CONTACT ALREADY HAS A USER RECORD, before Contact update, User account already exists' );
             
            system.debug('step2');
            //student mentor should fail
            StudentAcademicCourse__c sac=new StudentAcademicCourse__c(studentContact__c=student.id,CourseCode__c=CourseCode,startdate__c=date.today(), Term__c = Datetime.NOW().format('yyyyMM'), status__c = 'Registered');
            insert sac;
            boolean result= CourseMentorStudentAssignmentUtility.createAssignmentManual(mentorManual, sac );
            System.assert(result==true);
            System.debug([select id,CurrentStudents__c from Mentor__c where id=:mentorManual.id][0]);
            System.assert([select id,CurrentStudents__c from Mentor__c where id=:mentorManual.id][0].CurrentStudents__c==6);
            System.assert([select id,student__c from CourseMentorStudentAssignment__c where student__c = :student.id].size()==1);
            System.assert([select id,student__c ,isactive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c =true ].size()==1);
            
            
            system.debug('step3');
            //no duplicate
            result= CourseMentorStudentAssignmentUtility.createAssignmentManual(mentorManual, sac );
            System.assert(result==false);
            System.assert([select id,CurrentStudents__c from Mentor__c where id=:mentorManual.id][0].CurrentStudents__c==6);
            System.assert([select id,student__c from CourseMentorStudentAssignment__c where student__c = :student.id].size()==1);
            System.assert([select id,student__c ,isactive__c from CourseMentorStudentAssignment__c where student__c = :student.id and IsActive__c =true ].size()==1);
           
           
        Test.stopTest();
            
      }
       
      static testmethod void testGetMentorByCourseCode()
      { 
            Test.startTest();
                insert new CourseList__c(CourseLong__c='all');
                Mentor__c mentorCourse1=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true);  
                Mentor__c mentorCourse2=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true);  
                Mentor__c mentorCourse3=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true);  
                Mentor__c mentorCourse4=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='4444',available__c=true);  
                Mentor__c mentorCourse5=new Mentor__c(maxStudents__c=10,currentStudents__c=8,mentorRole__c='Course Mentor',pidm__c='5555',available__c=true);
                Mentor__c mentorCourse6=new Mentor__c(maxStudents__c=10,currentStudents__c=9,mentorRole__c='Course Mentor',pidm__c='6666',available__c=true);  
                Mentor__c mentorCourse7=new Mentor__c(                                       mentorRole__c='Course Mentor',pidm__c='7777',available__c=true);    
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA1',MentorPidm__c='1111');
                MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=2,CourseNumber__c='AAA1',MentorPidm__c='2222');
                MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=3,CourseNumber__c='AAA1',MentorPidm__c='3333');
                MentorCourseAssignment__c mass4= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=4,CourseNumber__c='AAA2',MentorPidm__c='4444');
                MentorCourseAssignment__c mass5= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=5,CourseNumber__c='AAA1',MentorPidm__c='5555');
                MentorCourseAssignment__c mass6= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=6,CourseNumber__c='AAA1',MentorPidm__c='6666');
                MentorCourseAssignment__c mass7= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=7,CourseNumber__c='AAA1',MentorPidm__c='7777');
                insert mentorCourse1;
                insert mentorCourse2;
                insert mentorCourse3;
                insert mentorCourse4;
                insert mentorCourse5;
                insert mentorCourse6;
                insert mentorCourse7;
                insert mass1;
                insert mass2;
                insert mass3;
                insert mass4;
                insert mass5;
                insert mass6;
                insert mass7; 
                System.assert(CourseMentorStudentAssignmentUtility.getMentorsByCourseCode('AAA1').size()==6);
                System.assert(CourseMentorStudentAssignmentUtility.getMentorsByCourseCode('AAA2').size()==1);
                System.assert(CourseMentorStudentAssignmentUtility.getMentorsByCourseCode('AAA3').size()==0);
                //mentor sorted as AvailableSpot__c decrease
                List<Mentor__c> mentors=CourseMentorStudentAssignmentUtility.getMentorsByCourseCode('AAA1');
                System.debug(mentors);
                System.assert(mentors[0].AvailableSpots__c==100);//100 is default value Max-Current
                System.assert(mentors[1].AvailableSpots__c==10);
                System.assert(mentors[2].AvailableSpots__c==10);
                System.assert(mentors[3].AvailableSpots__c==10);
                System.assert(mentors[4].AvailableSpots__c==2);
                System.assert(mentors[5].AvailableSpots__c==1);
        
            Test.stopTest();
        
      }
      
       
      static testmethod void testPlannedStart()
      {
            
          //create students
                insert new CourseList__c(CourseLong__c='all');
                ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
                ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
                ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
                Contact student1 = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
                Contact student2 = new Contact( Status__c='AS', PIDM__c='p002234', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student2', RecordTypeId=studentContactRecordTypeId );
                Contact student3 = new Contact( Status__c='AS', PIDM__c='p002235', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student3', RecordTypeId=studentContactRecordTypeId );
                Contact student4 = new Contact( Status__c='AS', PIDM__c='p002236', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student4', RecordTypeId=studentContactRecordTypeId );
                insert student1;
                insert student2;
                insert student3;
                insert student4;
          //define course code, and use TODAY as date.
                String CourseCode='AAA1';
          //create mentors with or w/o certain free spot
                Mentor__c mentorCourse1=new Mentor__c(maxStudents__c=10,currentStudents__c=1,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true);  
                Mentor__c mentorCourse2=new Mentor__c(maxStudents__c=10,currentStudents__c=1,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true);  
                Mentor__c mentorCourse3=new Mentor__c(maxStudents__c=10,currentStudents__c=7,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true);  
                Mentor__c mentorCourse4=new Mentor__c(maxStudents__c=10,currentStudents__c=5,mentorRole__c='Course Mentor',pidm__c='4444',available__c=true);  
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA1',MentorPidm__c='1111');
                MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=2,CourseNumber__c='AAA1',MentorPidm__c='2222');
                MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=3,CourseNumber__c='AAA1',MentorPidm__c='3333');
                MentorCourseAssignment__c mass4= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=4,CourseNumber__c='AAA1',MentorPidm__c='4444');
                insert mentorCourse1;
                insert mentorCourse2;
                insert mentorCourse3;
                insert mentorCourse4;
                insert mass1;
                insert mass2;
                insert mass3;
                insert mass4;
      
          Test.startTest();
          //create student course registrations , for created students and defined course code and TODAY
                StudentAcademicCourse__c sac1=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c='xx');
                StudentAcademicCourse__c sac2=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student2.id, status__c = 'Registered',startDate__c=date.today(),Term__c='xx');
                StudentAcademicCourse__c sac3=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student3.id, status__c = 'Registered',startDate__c=date.today(),Term__c='xx');
                StudentAcademicCourse__c sac4=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student4.id, status__c = 'Registered',startDate__c=date.today(),Term__c='xx');
                insert sac1;
                insert sac2;
                insert sac3;
                insert sac4;
                
          
          //call assignment method at utility class, given course code and date
                boolean result=CourseMentorStudentAssignmentUtility.createAssignmentsFromPlannedStartDate(courseCode, date.today());
          
          Test.stopTest();
          //check results.
                System.assert(result==true);
                System.debug([select id, Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='1111']);
                System.assert([select id, Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='1111'].CurrentStudents__c==3);
                System.assert([select id, Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='2222'].CurrentStudents__c==3);
                System.assert([select id, Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='3333'].CurrentStudents__c==7);
                System.assert([select id, Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='4444'].CurrentStudents__c==5);
                System.assert([select id,student__c ,isactive__c from CourseMentorStudentAssignment__c where   IsActive__c =true ].size()==4);
           
      }
      
      static testmethod void testEngagement()
      { 
                insert new CourseList__c(CourseLong__c='all');
                ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
                ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
                ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
                Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
                insert student;
                String CourseCode='AAA1';
                
                Mentor__c mentorCourse1=new Mentor__c(maxStudents__c=3,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111');  
                Mentor__c mentorCourse2=new Mentor__c(maxStudents__c=5,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222');  
                Mentor__c mentorCourse3=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333');  
                Mentor__c mentorCourse4=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='4444');  
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA4',MentorPidm__c='1111');
                MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=2,CourseNumber__c='AAA4',MentorPidm__c='2222');
                MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=3,CourseNumber__c='AAA4',MentorPidm__c='3333');
                MentorCourseAssignment__c mass4= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=4,CourseNumber__c='AAA2',MentorPidm__c='4444');
                 
                
                
                StudentAcademicCourse__c sac1=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student.id, status__c = 'Registered',startDate__c=date.today().addDays(22),Term__c=Datetime.NOW().format('yyyyMM'));
                StudentAcademicCourse__c sac2=new StudentAcademicCourse__c(CourseCode__c='AAA2',StudentContact__c=student.id, status__c = 'Registered',startDate__c=date.today().addDays(22),Term__c=Datetime.NOW().format('yyyyMM'));
                StudentAcademicCourse__c sac3=new StudentAcademicCourse__c(CourseCode__c='AAA3',StudentContact__c=student.id, status__c = 'Registered',startDate__c=date.today().addDays(2),Term__c=Datetime.NOW().format('yyyyMM'));
                StudentAcademicCourse__c sac4=new StudentAcademicCourse__c(CourseCode__c='AAA4',StudentContact__c=student.id, status__c = 'Registered',startDate__c=date.today().addDays(4),Term__c=Datetime.NOW().format('yyyyMM'));
                insert sac1;
                insert sac2;
                insert sac3;
                insert sac4;
                
                insert mentorCourse1;
                insert mentorCourse2;
                insert mentorCourse3;
                insert mentorCourse4;
                insert mass1;
                insert mass2;
                insert mass3;
                insert mass4;
                system.assert(sac4.startdate__c > Date.today()); 
            Test.startTest();
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA1',true);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA2',true);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA3',true);
                System.assert([select id from CourseMentorStudentAssignment__c].size()==1);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA4',true);
                System.assert([select id from CourseMentorStudentAssignment__c].size()==2);
                System.assert([select id , MentorPidm__c,CourseCode__c from CourseMentorStudentAssignment__c where CourseCode__c='AAA4' ].MentorPidm__c=='3333'); 
                System.assert([select id,Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='3333'].CurrentStudents__c==1);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA1',false);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA2',false);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA3',false);
                CourseMentorStudentAssignmentUtility.createAssignmentFromEngagement(student.id,'AAA4',false);
                System.assert([select id from CourseMentorStudentAssignment__c].size()==2); 
            Test.stopTest();
                //is cours start after 3 days, disable the assignment is allowed 
                System.assert([select id, isActive__c from CourseMentorStudentAssignment__c where IsActive__c=false].size()==2); 
                System.assert([select id, Pidm__c,CurrentStudents__c from Mentor__c where Pidm__c='3333'].CurrentStudents__c==0);
            
       
      }
      
      
      static testmethod void testMentorLeave()
      { 
            insert new CourseList__c(CourseLong__c='all');
            system.assert(  Limits.getQueries()==0);
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
             
            //we have 3 students
            Contact student1 = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            Contact student2 = new Contact( Status__c='AS', PIDM__c='p002234', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student2', RecordTypeId=studentContactRecordTypeId );
            Contact student3 = new Contact( Status__c='AS', PIDM__c='p002235', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student2', RecordTypeId=studentContactRecordTypeId );
            insert student1;
            insert student2;
            insert student3;
            String CourseCode='AAA1';
             
            //we have 4 mentors
            Mentor__c mentorCourse1=new Mentor__c(maxStudents__c=20,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true);  
            Mentor__c mentorCourse2=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true);  
            Mentor__c mentorCourse3=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true);  
            Mentor__c mentorCourse4=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='4444',available__c=true); 
             
            //mentor A can handle 3 courss 
            MentorCourseAssignment__c mass1a= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA1',MentorPidm__c='1111');
            MentorCourseAssignment__c mass1b= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA2',MentorPidm__c='1111');
            MentorCourseAssignment__c mass1c= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA3',MentorPidm__c='1111');
            //mentor B C D can each handle 1 course
            MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=2,CourseNumber__c='AAA1',MentorPidm__c='2222');
            MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=3,CourseNumber__c='AAA2',MentorPidm__c='3333');
            MentorCourseAssignment__c mass4= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=4,CourseNumber__c='AAA3',MentorPidm__c='4444');
             
                
             
            StudentAcademicCourse__c sac1=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            StudentAcademicCourse__c sac2=new StudentAcademicCourse__c(CourseCode__c='AAA2',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            StudentAcademicCourse__c sac3=new StudentAcademicCourse__c(CourseCode__c='AAA3',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            StudentAcademicCourse__c sac4=new StudentAcademicCourse__c(CourseCode__c='AAA4',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            insert sac1;
            insert sac2;
            insert sac3;
            insert sac4;
            insert mentorCourse1;
            insert mentorCourse2;
            insert mentorCourse3;
            insert mentorCourse4;
            insert mass1a;
            insert mass1b;
            insert mass1c;
            insert mass2;
            insert mass3;
            insert mass4;
            Test.startTest();
            system.assert(  Limits.getQueries()==0);
            //assign all 3 courses of student A to mentor A
            CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse1, sac1, 'Manual');
            CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse1, sac2, 'Manual');
            CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse1, sac3, 'Manual');
             
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==3);
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][1].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][2].mentorpidm__c=='1111');
            
             
            //mentor A leave, we want auto-reassign
            boolean result=CourseMentorStudentAssignmentUtility.reassignmentsWhenMentorLeave('1111');
            
            Test.stopTest(); 
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==6);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=false].size()==3);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true].size()==3);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1' and IsActive__c=true][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA2'and IsActive__c=true][0].mentorpidm__c=='3333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA3'and IsActive__c=true][0].mentorpidm__c=='4444');
            
            //test non-CaseLoadManager user
            User blankUser=new User(FirstName = 'test1111',LastName = 'Test1111',Email = 'test1111@wgu.edu',username='test1111@wgu.edu',LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1',LanguageLocaleKey = 'en_US');
            insert blankUser;
            system.runAs(blankUser)
            {
            	try{
            	CourseMentorStudentAssignmentUtility.reassignmentsWhenMentorLeave('1111');
            	}catch(Exception e)
            	{
            		
            	}
            }
            
      }
      
      
      static testmethod void testMentorDropCourses()
      { 
            insert new CourseList__c(CourseLong__c='all');
            system.assert(  Limits.getQueries()==0);
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
             
            //we have 3 students
            Contact student1 = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            Contact student2 = new Contact( Status__c='AS', PIDM__c='p002234', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student2', RecordTypeId=studentContactRecordTypeId );
            Contact student3 = new Contact( Status__c='AS', PIDM__c='p002235', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student2', RecordTypeId=studentContactRecordTypeId );
            insert student1;
            insert student2;
            insert student3;
            String CourseCode='AAA1';
             
            //we have 4 mentors
            Mentor__c mentorCourse1=new Mentor__c(maxStudents__c=20,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true);  
            Mentor__c mentorCourse2=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true);  
            Mentor__c mentorCourse3=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true);  
            Mentor__c mentorCourse4=new Mentor__c(maxStudents__c=10,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='4444',available__c=true); 
             
            insert mentorCourse1;
            insert mentorCourse2;
            insert mentorCourse3;
            insert mentorCourse4;
            //mentor A can handle 3 courss 
            MentorCourseAssignment__c mass1a= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA1',MentorPidm__c='1111');
            MentorCourseAssignment__c mass1b= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA2',MentorPidm__c='1111');
            MentorCourseAssignment__c mass1c= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='AAA3',MentorPidm__c='1111');
            //mentor B C D can each handle 1 course
            MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=2,CourseNumber__c='AAA1',MentorPidm__c='2222');
            MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=3,CourseNumber__c='AAA2',MentorPidm__c='3333');
            MentorCourseAssignment__c mass4= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=4,CourseNumber__c='AAA3',MentorPidm__c='4444');
             
            
            
            StudentAcademicCourse__c sac1=new StudentAcademicCourse__c(CourseCode__c='AAA1',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            StudentAcademicCourse__c sac2=new StudentAcademicCourse__c(CourseCode__c='AAA2',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            StudentAcademicCourse__c sac3=new StudentAcademicCourse__c(CourseCode__c='AAA3',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            StudentAcademicCourse__c sac4=new StudentAcademicCourse__c(CourseCode__c='AAA4',StudentContact__c=student1.id, status__c = 'Registered',startDate__c=date.today(),Term__c=Datetime.NOW().format('yyyyMM'));
            insert sac1;
            insert sac2;
            insert sac3;
            insert sac4;
            insert mass1a;
            insert mass1b;
            insert mass1c;
            insert mass2;
            insert mass3;
            insert mass4;
            Test.startTest();
            system.assert(  Limits.getQueries()==0);
            //assign all 3 courses of student A to mentor A
            CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse1, sac1, 'Manual');
            CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse1, sac2, 'Manual');
            CourseMentorStudentAssignmentUtility.createAssignment(mentorCourse1, sac3, 'Manual');
             
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==3);
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][1].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][2].mentorpidm__c=='1111');
            
             
            //mentor A leave, we want auto-reassign
            //comment out until mentor team request.
            mass1a.ActiveChk__c='0';
            update mass1a; 
            CourseMentorStudentAssignmentUtility.removeIfMentorCourseAssignmentChange(new List<MentorCourseAssignment__c> {mass1a}, false);
            /*System.assert([select id from  CourseMentorStudentAssignment__c].size()==3);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=false].size()==1);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true].size()==2);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1' and IsActive__c=false][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA2'and IsActive__c=true][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA3'and IsActive__c=true][0].mentorpidm__c=='1111');
            */
            delete mass1b;
            
            CourseMentorStudentAssignmentUtility.removeIfMentorCourseAssignmentChange(new List<MentorCourseAssignment__c> {mass1b}, true);
            /*System.assert([select id from  CourseMentorStudentAssignment__c].size()==3);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=false].size()==2);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true].size()==1);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA2']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1' and IsActive__c=false][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA2'and IsActive__c=false][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c ,isActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA3'and IsActive__c=true][0].mentorpidm__c=='1111');
         */   
            
            Test.stopTest(); 
            
            
             
      }
      ///
      //    test case of governer limit:
     //      mentor who handles 200 studnet will leave, 100 can be assigned to others which 100 course is unique for this mentor only.
      //
      static testmethod void testMentorLeaveGovernerLimit()
      {
            insert new CourseList__c(CourseLong__c='all');
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            Mentor__c mentor1=new Mentor__c(maxStudents__c=600,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true); 
            Mentor__c mentor2=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true); 
            Mentor__c mentor3=new Mentor__c(maxStudents__c=300,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true); 
            insert mentor1;
            insert mentor2;
            insert mentor3;
            
            //mentor A B can all handle 200 courss 
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>();
            List<CourseMentorStudentAssignment__c> asss=new List<CourseMentorStudentAssignment__c>();
            for(integer i=0;i<200;i++)
            {
                //mentor 1 can handle all courses and have plenty free spots
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='1111'); 
                masss.add(mass1);
                if(i<100)//advanced: mentor 2 can only did 50% courses mentor 1 can do
                {   
                    MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='2222');
                    masss.add(mass2);
                }
                
                if(i>=50 &&i <100)
                {
                    MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='3333');
                    masss.add(mass3);
                }
                //create assignment for mentor 1 ( don't use utility class because this will hit governer limit here)
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c();
                ass.Mentor__c=mentor1.id;
                ass.MentorPidm__c='1111';
                ass.Student__c=student.id;
                ass.PIDM__c=student.pidm__c;
                ass.CourseCode__c='A'+i;
                ass.ReasonOfAssignment__c= 'Manual'; 
                mentor1.CurrentStudents__c++;
                asss.add(ass);
            } 
            insert masss; //insert mentor course assignments
            insert asss;//insert  mentor course student assignments
            update mentor1; //now the mentor1 has 200 current load 
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==200);
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][1].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][2].mentorpidm__c=='1111');
            
            
            
            Test.startTest(); 
            system.debug('%%%%%');
            //mentor A leave, we want auto-reassign to mentor2 and mentor 3
            //  here we test it for not hit the governer limit
            CourseMentorStudentAssignmentUtility.reassignmentsWhenMentorLeave('1111');
            //CourseMentorStudentAssignmentUtility.asyncReassignmentsWhenMentorLeave('1111');
            Test.stopTest();
            
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==300);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true ].size()==100);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=false ].size()==200);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1' ]);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c , IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'and IsActive__c=true ][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'and IsActive__c=true ][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'and IsActive__c=true ][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c , IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A50'and IsActive__c=true ][0].mentorpidm__c=='3333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A88'and IsActive__c=true ][0].mentorpidm__c=='3333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A95'and IsActive__c=true ][0].mentorpidm__c=='3333');
            system.debug([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='1111'][0]);
            system.debug([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='2222'][0]);
            system.debug([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='3333'][0]);
            System.assert([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='1111'][0].currentStudents__c==0);
            System.assert([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='2222'][0].currentStudents__c==50);
            System.assert([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='3333'][0].currentStudents__c==50);
            
            
      }
      
      //
      //    test case of governer limit with async(future) , just make sure it works.
      //
      static testmethod void testAsynMentorLeaveGovernerLimit()
      {
            insert new CourseList__c(CourseLong__c='all'); 
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            Mentor__c mentor1=new Mentor__c(maxStudents__c=600,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true); 
            Mentor__c mentor2=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true); 
            Mentor__c mentor3=new Mentor__c(maxStudents__c=300,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true); 
            insert mentor1;
            insert mentor2;
            insert mentor3;
            
            //mentor A B can all handle 200 courss 
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>();
            List<CourseMentorStudentAssignment__c> asss=new List<CourseMentorStudentAssignment__c>();
            for(integer i=0;i<200;i++)
            {
                //mentor 1 can handle all courses and have plenty free spots
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='1111'); 
                masss.add(mass1);
                if(i<100)//advanced: mentor 2 can only did 50% courses mentor 1 can do
                {   
                    MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='2222');
                    masss.add(mass2);
                }
                
                if(i>=50 &&i <100)
                {
                    MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='3333');
                    masss.add(mass3);
                }
                //create assignment for mentor 1 ( don't use utility class because this will hit governer limit here)
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c();
                ass.Mentor__c=mentor1.id;
                ass.MentorPidm__c='1111';
                ass.Student__c=student.id;
                ass.PIDM__c=student.pidm__c;
                ass.CourseCode__c='A'+i;
                ass.ReasonOfAssignment__c= 'Manual'; 
                mentor1.CurrentStudents__c++;
                asss.add(ass);
            } 
            insert masss; //insert mentor course assignments
            insert asss;//insert  mentor course student assignments
            update mentor1; //now the mentor1 has 200 current load 
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==200);
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][1].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][2].mentorpidm__c=='1111');
            
            
            
            Test.startTest(); 
            system.debug('%%%%%');
            //mentor A leave, we want auto-reassign to mentor2 and mentor 3
            //  here we test it for not hit the governer limit
            CourseMentorStudentAssignmentUtility.asyncReassignmentsWhenMentorLeave('1111');
            //CourseMentorStudentAssignmentUtility.asyncReassignmentsWhenMentorLeave('1111');
            Test.stopTest();
            
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==300);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true ].size()==100);
            System.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=false ].size()==200);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'AAA1' ]);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c , IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'and IsActive__c=true ][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'and IsActive__c=true ][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'and IsActive__c=true ][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c , IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A50'and IsActive__c=true ][0].mentorpidm__c=='3333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A88'and IsActive__c=true ][0].mentorpidm__c=='3333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c, IsActive__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A95'and IsActive__c=true ][0].mentorpidm__c=='3333');
            system.debug([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='1111'][0]);
            system.debug([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='2222'][0]);
            system.debug([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='3333'][0]);
            System.assert([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='1111'][0].currentStudents__c==0);
            System.assert([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='2222'][0].currentStudents__c==50);
            System.assert([select id, pidm__c, currentStudents__c from mentor__c where pidm__c='3333'][0].currentStudents__c==50);
            
            
      }
      
      ///
      //    test case of createAssignmentsByStudentCourseRegistration
      //         
      //
      static testmethod void testCreateAssignmentsByStudentAcademicCourse()
      {
            insert new CourseList__c(CourseLong__c='all'); 
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
            for(integer i=0;i<200;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c=''+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                
                if(i>=150)
                {
                    StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Passed');
                    sacs.add(sac);
                }else
                {
                    StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                    sacs.add(sac);
                } 
            }
            insert mentors; 
            insert sacs;    
            
          
            //mentor A B can all handle 200 courss 
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<200;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c=''+i+i+i+i); 
                masss.add(mass1);
                 
            } 
            insert masss; //insert mentor course assignments  
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  StudentAcademicCourse__c].size()==200); 
            
            
            
            Test.startTest(); 
            system.debug('%%%%%');
            CourseMentorStudentAssignmentUtility.createAssignmentsByStudentAcademicCourses(null);//test null for code coverage
            //mentor A leave, we want auto-reassign to mentor2 
            // but likely to hit the governer limit
            CourseMentorStudentAssignmentUtility.createAssignmentsByStudentAcademicCourses([select CourseCode__c, enddate__c, startdate__c, studentContact__c, status__c from StudentAcademicCourse__c]);
            Test.stopTest();
            
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==150);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'][0].mentorpidm__c=='2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'][0].mentorpidm__c=='3333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A50'][0].mentorpidm__c=='50505050');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A88'][0].mentorpidm__c=='88888888');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A95'][0].mentorpidm__c=='95959595');
             
            
            
      }
      
      
      ///
      //    test case of createAssignmentsByStudentCourseRegistration
      //         
      //
      static testmethod void testCreateAssignmentsByStudentAcademicCourseOfOneMentor()
      {
            insert new CourseList__c(CourseLong__c='all'); 
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            List<Mentor__c> mentors=new List<Mentor__c>();
            
            Mentor__c mentor=new Mentor__c(maxStudents__c=300,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c=''+0+0+0+0,available__c=true); 
            mentors.add(mentor);
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
            for(integer i=0;i<200;i++)
            {  
                if(i>=150)
                {
                    StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Passed');
                    sacs.add(sac);
                }else
                {
                    StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                    sacs.add(sac);
                } 
            }
            insert mentors; 
            insert sacs;    
            
            
            //mentor A B can all handle 200 courss 
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<200;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c=''+0+0+0+0); 
                masss.add(mass1);
                 
            } 
            insert masss; //insert mentor course assignments  
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  StudentAcademicCourse__c].size()==200); 
            
            
            
            Test.startTest(); 
            system.debug('%%%%%');
            CourseMentorStudentAssignmentUtility.createAssignmentsByStudentAcademicCourses(null);//test null for code coverage
            //mentor A leave, we want auto-reassign to mentor2 
            // but likely to hit the governer limit
            CourseMentorStudentAssignmentUtility.createAssignmentsByStudentAcademicCourses([select CourseCode__c, enddate__c, startdate__c, studentContact__c, status__c from StudentAcademicCourse__c]);
            Test.stopTest();
            
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==150);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'][0].mentorpidm__c=='0000');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'][0].mentorpidm__c=='0000');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'][0].mentorpidm__c=='0000'); 
            system.assert([select id, CurrentStudents__c from mentor__c limit 1].currentStudents__c==150);
            
            
      }
      //test batch creation . given all registered courses, create assignments.
      static testmethod void testcreateAssignmentsByStudentAcademicCourseBatch()
      {
            insert new CourseList__c(CourseLong__c='all');      
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have   mentors
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
             
            //50 valid scr
            for(integer i=0;i<50;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='A'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                sacs.add(sac);
            } 
            
            //50 pass due scr
            for(integer i=0;i<50;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='B'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='B'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-32), enddate__c=date.today().addMonths(-2),status__c = 'Registered');
                sacs.add(sac);
            }
        
            insert mentors; 
            insert sacs;     
            
            //1 course already exist
            CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c(CourseCode__c='A1',pidm__c='p002233',Mentor__c= mentors[33].id,MentorPidm__c='A33333333',StudentAcademicCourse__c=sacs[1].id);
            insert ass;
            
            //provide 40 mentors handles 40 courses for 3 senario
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<40;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='A'+i+i+i+i); 
                MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='B'+i,MentorPidm__c='B'+i+i+i+i); 
                MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='C'+i,MentorPidm__c='C'+i+i+i+i); 
                masss.add(mass1);
                masss.add(mass2);
                masss.add(mass3);
                 
            } 
            insert masss; //insert mentor course assignments  
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  StudentAcademicCourse__c].size()==100); 
            
            
            
            Test.startTest(); 
            system.debug('%%%%%');
            
            Id batchInstanceId = Database.executeBatch(new CourseMentorStudentAssignmentUtility('DAILYCREATE','Select Type__c, Term__c, StudentContact__c, StudentContact__r.Status__c,StudentContact__r.pidm__c,   Status__c,  StartDate__c,  RequirementsReferred__c,  RequirementsEngaged__c,  RequirementsEngagedPreassessment__c,  RequirementsCompleted__c,  Name,  MentorVerifiedEngagementNotedDate__c,  MentorVerifiedEngagementNotedBy__c,  MentorVerifiedCurrentEngagement__c,  Id,  FullCourseTitle__c,  EndDate__c,  CourseCode__c,  CompositeKey__c,  CompetencyUnits__c,  Attempts__c ,(Select id, CreatedDate, Name, Attempts__c, Completed__c, Engaged__c, EngagedPreassessment__c, FullTitle__c, PreassessmentCode__c, Referred__c, Status__c, StudentAcademicCourse__c, Type__c  From StudentAcademicCourseRequirements__r) '
                            + ' from StudentAcademicCourse__c  where  startdate__c <= NEXT_N_DAYS:2 and enddate__c >= NEXT_N_DAYS:2')); 
             
            Test.stopTest();
            
            System.assert([select id from  CourseMentorStudentAssignment__c where isActive__c =true ].size()==40);
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A0'][0].mentorpidm__c=='A0000');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'][0].mentorpidm__c=='A33333333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'][0].mentorpidm__c=='A2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'][0].mentorpidm__c=='A3333');  
             
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c like 'B%'].size()==0);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c like 'C%'].size()==0);
             
             
            
            for(integer i=10;i<50;i++)
            { 
                sacs[i].Status__c = 'Passed'; 
            }
            update sacs;
            system.debug('#########'+[select id ,IsActive__c from CourseMentorStudentAssignment__c where IsActive__c=true ].size());
            system.debug('#########'+[select id ,IsActive__c from CourseMentorStudentAssignment__c where IsActive__c=false ].size());
        //  CourseMentorStudentAssignmentUtility.removeAssignmentsForPassedCourses([select id from studentcourseversion__c]);
            System.assert([select id ,IsActive__c from CourseMentorStudentAssignment__c where IsActive__c=true ].size()==10);
            System.assert([select id from CourseMentorStudentAssignment__c].size()==40);
            
      }
      
	  // create case loads daily (if not test student)
      static testmethod void testcreateAssignmentDailyBasisForTestStudent()
      {     
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( IsTestData__c = true, Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student; 
            //we have 2 mentor
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
            for(integer i=0;i<200;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c=''+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                
                if(i>=150)
                {
                    StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Passed');
                    sacs.add(sac);
                }else
                {
                    StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                    sacs.add(sac);
                } 
            }
            insert mentors; 
            insert sacs;    
            
          
            //mentor A B can all handle 200 courss 
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<200;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c=''+i+i+i+i); 
                masss.add(mass1);
                 
            } 
            insert masss; //insert mentor course assignments  
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  StudentAcademicCourse__c].size()==200); 
            
            
            Test.startTest(); 


            CourseList__c cl=new CourseList__c(CourseLong__c='all');
            insert cl;
            
            System.assert([select id from CourseList__c ].size()==1);   
            CourseMentorStudentAssignmentSchedulor assignment= new CourseMentorStudentAssignmentSchedulor ();
            
            String seconds = '0'; //Execute at Zero Seconds
            String minutes = '30'; //Execute at every 10th minute of hour
            String hours = '*'; // Execute Every Hour
            String dayOfMonth = '*'; // Execute Every Day of the Month
            String month = '*'; //Execute only in November(11)
            String dayOfWeek = '?'; //Execute on all 7 days of the Week
            String year = '*'; //Execute only for year 2013
            
            //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
            String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek ;//+ ' ' + year;
            //String sch = ’0 10,20,30,40,50 * * 11 ? 2009′;
             
             
      //  List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10]; 
        
       // system.assert(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all')); 
            String jobid1=system.schedule('CourseMentor Batch Assignment1', sch, assignment);
 
            
            Test.stopTest(); 
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==0);  
             
               
            
      }
      
      // if courses's enddate passed, the assignment should be removed regardless the courses are passed or failed.
      //  this method should be scheduled to run at daily basis, but we can't test it here
      static testmethod void testRemoveAssignmentDailyBasis()
      {     
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student; 
            //we have 100 mentors
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>();  
            
            Datetime dt = Datetime.NOW();
            String termCode=dt.format   ('yyyyMM');
            //60 valid scr
            for(integer i=0;i<60;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='A'+i+i+i+i,available__c=true); 
                mentors.add(mentor); 
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                sacs.add(sac);
            } 
            
            //40 pass due scr
            for(integer i=0;i<40;i++)
            { 
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='B'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='B'+i,   Term__c=Datetime.NOW().addMonths(-7).format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-7), enddate__c=date.today().addMonths(-2),status__c = 'Registered');
                sacs.add(sac);
            }
             
            
            insert mentors; 
            insert sacs;     
            
            
            //provide 40 mentors handles 40 courses for 3 senario
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<100;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='A'+i+i+i+i); 
                MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='B'+i,MentorPidm__c='B'+i+i+i+i);  
                masss.add(mass1);
                masss.add(mass2); 
                 
            } 
            insert masss; //insert mentor course assignments 
            
            
            
             //create assignment for 40 past due courses
            List<CourseMentorStudentAssignment__c> assList=new List<CourseMentorStudentAssignment__c>();
            for(integer i=0;i<40;i++)
            {
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c(pidm__c=student.PIDM__c,student__c=student.id, mentor__c=mentors[i].id,mentorpidm__c=mentors[i].PIDM__c, coursecode__c='B'+i, StudentAcademicCourse__c= sacs[i].id,IsActive__c=true, TermCode__c=Datetime.NOW().addMonths(-7).format('yyyyMM'));
                assList.add(ass);
            }
            for(integer i=0;i<60;i++)
            {
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c(pidm__c=student.PIDM__c,student__c=student.id, mentor__c=mentors[i].id,mentorpidm__c=mentors[i].PIDM__c, coursecode__c='A'+i, StudentAcademicCourse__c= sacs[40+i].id,IsActive__c=true,TermCode__c=termCode);
                assList.add(ass);
            }
            insert assList;
            //should be 200 assignments records, all belongs to mentor1 
            //System.assert([select id from  CourseMentorStudentAssignment__c].size()==100); 
            
            Test.startTest(); 


            CourseList__c cl=new CourseList__c(CourseLong__c='all');
            insert cl;
            
            System.assert([select id from CourseList__c ].size()==1);   
            CourseMentorStudentAssignmentSchedulor assignment= new CourseMentorStudentAssignmentSchedulor ();
            
            String seconds = '0'; //Execute at Zero Seconds
            String minutes = '30'; //Execute at every 10th minute of hour
            String hours = '*'; // Execute Every Hour
            String dayOfMonth = '*'; // Execute Every Day of the Month
            String month = '*'; //Execute only in November(11)
            String dayOfWeek = '?'; //Execute on all 7 days of the Week
            String year = '*'; //Execute only for year 2013
            
            //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
            String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek ;//+ ' ' + year;
            //String sch = ’0 10,20,30,40,50 * * 11 ? 2009′;
             
             
      //  List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10]; 
        
       // system.assert(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all')); 
            String jobid1=system.schedule('CourseMentor Batch Assignment1', sch, assignment);
 
            cl.CourseLong__c='\'LET1\',\'BBC1\'';
            update cl;
             
            String jobid2=system.schedule('CourseMentor Batch Assignment2', sch, assignment);
             
            dt = Datetime.NOW().addMonths(-6);
            termCode=dt.format  ('yyyyMM');
            CourseMentorStudentAssignmentUtility.removeAssignmentDaily([select id, StudentAcademicCourse__c,StudentAcademicCourse__r.Term__c, StudentAcademicCourse__r.status__c, mentor__c,mentor__r.CurrentStudents__c, user__c, mentorPidm__c, pidm__c, startdate__c,enddate__c, coursecode__c, student__c, IsActive__c ,TermCode__c from CourseMentorStudentAssignment__c where   ( StudentAcademicCourse__r.Term__c <= :termCode OR StudentAcademicCourse__c = null) and IsActive__c = true  ]);
             
            Test.stopTest(); 
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==100); 
            Integer ct=[select id ,IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true].size();
            
            System.assert(ct==60); 
             
               
            
      }
     // given a list of PASSED course registration, remove assignments.
     static testmethod void testRemoveAssignmentAfterCourseRegistrationsPassed()
     {      
            insert new CourseList__c(CourseLong__c='all');
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
             
            //50 valid scr
            for(integer i=0;i<50;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='A'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                sacs.add(sac);
            } 
            
            //50 future scr
            for(integer i=0;i<50;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='B'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='B'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(2), enddate__c=date.today().addMonths(4),status__c = 'Registered');
                sacs.add(sac);
            }
            
            insert mentors; 
            insert sacs;     
            
            //1 course already exist
            CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c(CourseCode__c='A1',pidm__c='p002233',Mentor__c= mentors[33].id,MentorPidm__c='A33333333',StudentAcademicCourse__c=sacs[1].id);
            insert ass;
            //provide 40 mentors handles 40 courses for 3 senario
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<40;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='A'+i+i+i+i); 
                MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='B'+i,MentorPidm__c='B'+i+i+i+i); 
                MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='C'+i,MentorPidm__c='C'+i+i+i+i); 
                masss.add(mass1);
                masss.add(mass2);
                masss.add(mass3);
                 
            } 
            insert masss; //insert mentor course assignments  
            
            
            
            //should be 100 assignments records, all belongs to mentor1
            System.assert([select id from  StudentAcademicCourse__c].size()==100); 
            
            
            
            Test.startTest(); 
            system.debug('%%%%%');
            //daily creation 
            Id batchInstanceId = Database.executeBatch(new CourseMentorStudentAssignmentUtility('DAILYCREATE','select CourseCode__c, enddate__c, startdate__c, studentContact__c, status__c from StudentAcademicCourse__c')); 
              
            Test.stopTest();
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==40); 
            System.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A0']);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'][0].mentorpidm__c=='A33333333');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'][0].mentorpidm__c=='A2222');
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'][0].mentorpidm__c=='A3333');  
             
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c like 'B%'].size()==0);
            System.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c like 'C%'].size()==0);
             
            for(integer i=25;i<75;i++)
            { 
                sacs[i].Status__c = 'Passed'; 
            }
            update sacs;
            system.debug('#########'+[select id ,IsActive__c from CourseMentorStudentAssignment__c where IsActive__c=true ].size());
            system.debug('#########'+[select id ,IsActive__c from CourseMentorStudentAssignment__c where IsActive__c=false ].size());
        //  CourseMentorStudentAssignmentUtility.removeAssignmentsForPassedCourses([select id from studentcourseversion__c]); 
            System.assert([select id, IsActive__c from CourseMentorStudentAssignment__c where IsActive__c = false].size()==15);
            System.assert([select id, IsActive__c from CourseMentorStudentAssignment__c where IsActive__c = true].size()==25);
            
      }
      
       
      
      //when student 'complete' course prior to planned date, the assignment should be removed prior to planned date too.
      // this test intend to test on hundreds of records without hit govenor limit
      static testmethod void testRemoveAssignmentAfterCourseRegistrationsPassedGovernerLimit()
      {
            insert new CourseList__c(CourseLong__c='all');
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
          
            Integer size=400;
            //we have 2 mentor
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
            //300 valid scr
            
            for(integer i=0;i<size;i++)
            {
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today(), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                sacs.add(sac);
                 
                 
            } 
            insert sacs;
            
            for(integer i=0;i<size/2;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='A'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                 
                 
            }
             
            insert mentors;  
            
        //List<StudentCourseVersion__c> scvs= [select id, Completed__c, Student__c, Student__r.pidm__c,CompletedDate__c from StudentCourseVersion__c];
            //mentor A0000 can handle all courses
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<size/2;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='A0000');  
                masss.add(mass1); 
                 
            } 
            insert masss; //insert mentor course assignments  
            //should be 250 assignments records, all belongs to mentor1
            system.assert([select id from Mentor__c].size()==size/2);
            system.assert([select id from StudentAcademicCourse__c].size()==size);  
            system.assert([select id from  MentorCourseAssignment__c].size()==size/2); 
            
            
            
            Test.startTest();
            CourseMentorStudentAssignmentUtility.createAssignmentsByStudentAcademicCourses([select CourseCode__c, enddate__c, startdate__c, studentContact__c  from StudentAcademicCourse__c]);
            system.assert([select id from  CourseMentorStudentAssignment__c where isActive__c=true].size()==size/2);
            system.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1']);
            system.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'][0].mentorpidm__c=='A0000');
            system.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'][0].mentorpidm__c=='A0000');
            system.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'][0].mentorpidm__c=='A0000');  
        	system.assert([select id, CurrentStudents__c from mentor__c where pidm__c = 'A0000'].currentStudents__c == size/2);
            
            for(Integer i=0;i<sacs.size();i++)
            { 
                sacs[i].Status__c = 'Passed'; 
            }
            
            ///
            //  highly likely to cause trouble this line of code
            //      it failed 20+ times with DML error: 'cannot insert update activity entry' for no reason
            //      but eventurally passed for No reason.
            
            update sacs; 
            
             
            Test.stopTest();
            system.assert([select id, CurrentStudents__c from mentor__c where pidm__c = 'A0000'].currentStudents__c == 0);
            
            system.assert([select id from  CourseMentorStudentAssignment__c where isActive__c =false].size()==size/2);
            system.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true].size()==0); 
              
            
        
             
      }
      
      
      
      
      //when student 'complete' course prior to planned date, the assignment should be removed prior to planned date too.
      // this test intend to test on hundreds of records without hit govenor limit
      static testmethod void testRemoveAssignmentAfterStudentDrop()
      {
            insert new CourseList__c(CourseLong__c='all');
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
          
            Integer size=400;
            //we have 2 mentor
            List<Mentor__c> mentors=new List<Mentor__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>(); 
            //400 valid sac
            
            for(integer i=0;i<size;i++)
            {
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today(), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                sacs.add(sac);
                 
                 
            } 
            insert sacs;
             
            for(integer i=0;i<size/2;i++)
            {
                Mentor__c mentor=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='A'+i+i+i+i,available__c=true); 
                mentors.add(mentor);
                 
                 
            }
             
            insert mentors;  
            
        //List<StudentCourseVersion__c> scvs= [select id, Completed__c, Student__c, Student__r.pidm__c,CompletedDate__c from StudentCourseVersion__c];
            //provide 250 mentors handles 40 courses for 3 senario
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>(); 
            for(integer i=0;i<size/2;i++)
            {
                 
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='A'+i+i+i+i);  
                masss.add(mass1); 
                 
            } 
            insert masss; //insert mentor course assignments  
            //should be 250 assignments records, all belongs to mentor1
            system.assert([select id from Mentor__c].size()==size/2);
            system.assert([select id from StudentAcademicCourse__c].size()==size); 
           // system.assert([select id from StudentCourseVersion__c].size()== size);
            system.assert([select id from  MentorCourseAssignment__c].size()==size/2); 
            
            
            
            CourseMentorStudentAssignmentUtility.createAssignmentsByStudentAcademicCourses([select CourseCode__c, enddate__c, startdate__c, studentContact__c  from StudentAcademicCourse__c]);
            system.assert([select id from  CourseMentorStudentAssignment__c where isActive__c=true].size()==size/2);
            system.debug([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1']);
            system.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A1'][0].mentorpidm__c=='A1111');
            system.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A2'][0].mentorpidm__c=='A2222');
            system.assert([select id, mentor__c, mentorpidm__c,CourseCode__c from  CourseMentorStudentAssignment__c where CourseCode__c = 'A3'][0].mentorpidm__c=='A3333');  
        
            Test.startTest();
            
            
            student.status__c= 'DR';
            update student;
            CourseMentorStudentAssignmentSchedulor assignment= new CourseMentorStudentAssignmentSchedulor ();
            
            String seconds = '0'; //Execute at Zero Seconds
            String minutes = '30'; //Execute at every 10th minute of hour
            String hours = '*'; // Execute Every Hour
            String dayOfMonth = '*'; // Execute Every Day of the Month
            String month = '*'; //Execute only in November(11)
            String dayOfWeek = '?'; //Execute on all 7 days of the Week
            String year = '*'; //Execute only for year 2013
            
            //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
            String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek ;//+ ' ' + year;
            //String sch = ’0 10,20,30,40,50 * * 11 ? 2009′;
             
             
      //  List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10]; 
        
       // system.assert(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all')); 
            String jobid1=system.schedule('CourseMentor Batch Assignment1', sch, assignment); 
            Test.stopTest();
            system.assert([select id from  CourseMentorStudentAssignment__c where isActive__c =false].size()==0);
          /*  system.assert([select id, IsActive__c from  CourseMentorStudentAssignment__c where IsActive__c=true].size()==0); 
              
           */ 
        
             
      }
      
      
      
      //helper function which wipe off all records
      static testmethod void testDeleteAssignments()
      {
            insert new CourseList__c(CourseLong__c='all');
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            Mentor__c mentor1=new Mentor__c(maxStudents__c=600,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true); 
            Mentor__c mentor2=new Mentor__c(maxStudents__c=200,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='2222',available__c=true); 
            Mentor__c mentor3=new Mentor__c(maxStudents__c=300,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='3333',available__c=true); 
            insert mentor1;
            insert mentor2;
            insert mentor3;
            
            //mentor A B can all handle 200 courss 
            List<MentorCourseAssignment__c> masss=new List<MentorCourseAssignment__c>();
            List<CourseMentorStudentAssignment__c> asss=new List<CourseMentorStudentAssignment__c>();
            for(integer i=0;i<200;i++)
            {
                //mentor 1 can handle all courses and have plenty free spots
                MentorCourseAssignment__c mass1= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='1111'); 
                masss.add(mass1);
                if(i<100)//advanced: mentor 2 can only did 50% courses mentor 1 can do
                {   
                    MentorCourseAssignment__c mass2= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='2222');
                    masss.add(mass2);
                }
                
                if(i>=50 &&i <100)
                {
                    MentorCourseAssignment__c mass3= new MentorCourseAssignment__c(ActiveChk__c= '1',AcademicTableKey__c=1,CourseNumber__c='A'+i,MentorPidm__c='3333');
                    masss.add(mass3);
                }
                //create assignment for mentor 1 ( don't use utility class because this will hit governer limit here)
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c();
                ass.Mentor__c=mentor1.id;
                ass.MentorPidm__c='1111';
                ass.Student__c=student.id;
                ass.PIDM__c=student.pidm__c;
                ass.CourseCode__c='A'+i;
                ass.ReasonOfAssignment__c= 'Manual'; 
                mentor1.CurrentStudents__c++;
                asss.add(ass);
            } 
            insert masss; //insert mentor course assignments
            insert asss;//insert  mentor course student assignments
            update mentor1; //now the mentor1 has 200 current load 
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==200);
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][1].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][2].mentorpidm__c=='1111');
            //test recalculation
            mentor1.currentStudents__c = 100;
            update mentor1;
            CourseMentorStudentAssignmentUtility.calculateCurrentCaseLoadForMentors('1');  
            System.assert([select id,CurrentStudents__c from  mentor__c where id =:mentor1.id].CurrentStudents__c==200);
            //test recalculation
            mentor2.currentStudents__c = 100;
            update mentor2; 
            CourseMentorStudentAssignmentUtility.calculateCurrentCaseLoadForMentors(null);
            System.assert([select id,CurrentStudents__c from  mentor__c where id =:mentor2.id].CurrentStudents__c==0);
            System.assert([select id,CurrentStudents__c from  mentor__c where id =:mentor3.id].CurrentStudents__c==0);
            
            Test.startTest(); 
            system.debug('%%%%%'); 
            Id batchInstanceId = Database.executeBatch(new CourseMentorStudentAssignmentUtility('DELETE','select id from CourseMentorStudentAssignment__c')); 
            
            Test.stopTest();
            
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==0);
            System.assert([select id, CurrentStudents__c from  mentor__c  ].size()==3);
            System.assert([select id, CurrentStudents__c from  mentor__c where CurrentStudents__c>0].size()==0);
      }
      
      
      //helper function to map old StudentCouseRegistration__c to new StudentAcademicCourse__c
      static testmethod void testUpgradeAssignments()
      {
            insert new CourseList__c(CourseLong__c='all');
            ID studentContactRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Contact'].id;
            ID studentAccountRecordTypeId = [Select Id from RecordType where DeveloperName = 'StudentRecord' and SObjectType = 'Account'].id;
            ID studentProfileId = [Select id from Profile where Name = 'Student Profile'].id;
            integer size =200;
            //we have 1 students
            Contact student = new Contact( Status__c='AS', PIDM__c='p002233', FirstName='testassignment', Email='notexist@wgu.edu', MailingState='UT', LastName='student1', RecordTypeId=studentContactRecordTypeId );
            insert student;
            String CourseCode='A';
            //we have 2 mentor
            Mentor__c mentor=new Mentor__c(maxStudents__c=600,currentStudents__c=0,mentorRole__c='Course Mentor',pidm__c='1111',available__c=true); 
            insert mentor; 
            
            //mentor A B can all handle 200 courss  
            List<CourseMentorStudentAssignment__c> asss=new List<CourseMentorStudentAssignment__c>();
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>();
            List<StudentCourseRegistration__c> scrs=new List<StudentCourseRegistration__c>();
            for(integer i=0;i<size;i++)
            {
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,   Term__c=Datetime.NOW().format('yyyyMM'),studentContact__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2),status__c = 'Registered');
                sacs.add(sac);
                StudentCourseRegistration__c scr=new StudentCourseRegistration__c(CourseCode__c='A'+i, pidm__c='p002233', TermCode__c=Datetime.NOW().format('yyyyMM'),student__c = student.id, startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(2));
                scrs.add(scr);
            } 
            insert sacs;
            insert scrs;    
             
            for(integer i=0;i<size;i++)
            { 
                 
                //create assignment for mentor 1 ( don't use utility class because this will hit governer limit here)
                CourseMentorStudentAssignment__c ass=new CourseMentorStudentAssignment__c();
                ass.Mentor__c=mentor.id;
                ass.MentorPidm__c='1111';
                ass.Student__c=student.id;
                ass.PIDM__c=student.pidm__c;
                ass.CourseCode__c='A'+i;
                ass.ReasonOfAssignment__c= 'Manual'; 
                ass.TermCode__c =  Datetime.NOW().format('yyyyMM');
                mentor.CurrentStudents__c++;
                if(i<size/2)
                {
                	ass.StudentCourseRegistration__c = scrs[i].id;
                }
                asss.add(ass);
            }  
            insert asss;//insert  mentor course student assignments
            update mentor; //now the mentor1 has 200 current load 
            //should be 200 assignments records, all belongs to mentor1
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==size);
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][0].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][1].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, mentorpidm__c from  CourseMentorStudentAssignment__c][2].mentorpidm__c=='1111');
            System.assert([select id, mentor__c, StudentCourseRegistration__c from  CourseMentorStudentAssignment__c][0].StudentCourseRegistration__c!=null);
            System.assert([select id, mentor__c, StudentAcademicCourse__c from  CourseMentorStudentAssignment__c][0].StudentAcademicCourse__c==null);
            
              
            System.assert([select id,CurrentStudents__c from  mentor__c where id =:mentor.id].CurrentStudents__c==size); 
            
            Test.startTest(); 
            system.debug('%%%%%'); 
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==size); 
            System.assert([select id, mentor__c, StudentCourseRegistration__c from  CourseMentorStudentAssignment__c][0].StudentCourseRegistration__c!=null);
            System.assert([select id, mentor__c, StudentAcademicCourse__c from  CourseMentorStudentAssignment__c][0].StudentAcademicCourse__c==null);
            
            Id batchInstanceId = Database.executeBatch(new CourseMentorStudentAssignmentUtility('UPGRADE','select id from CourseMentorStudentAssignment__c')); 
            
            
            Test.stopTest();
            
            
            System.assert([select id from  CourseMentorStudentAssignment__c].size()==size); 
            System.assert([select id, mentor__c, StudentCourseRegistration__c from  CourseMentorStudentAssignment__c][0].StudentCourseRegistration__c!=null);
            System.assert([select id, mentor__c, StudentAcademicCourse__c from  CourseMentorStudentAssignment__c][0].StudentAcademicCourse__c!=null);
            CourseMentorStudentAssignment__c ass = [select id, mentor__c, StudentCourseRegistration__c,StudentCourseRegistration__r.termcode__c,StudentCourseRegistration__r.student__c, StudentCourseRegistration__r.coursecode__c,
            StudentAcademicCourse__c,StudentAcademicCourse__r.Term__c,StudentAcademicCourse__r.StudentContact__c, StudentAcademicCourse__r.courseCode__c from  CourseMentorStudentAssignment__c][0];
            System.assert(ass.StudentCourseRegistration__r.termcode__c == ass.StudentAcademicCourse__r.term__c) ;
            System.assert(ass.StudentCourseRegistration__r.student__c == ass.StudentAcademicCourse__r.studentContact__c) ;
            System.assert(ass.StudentCourseRegistration__r.coursecode__c == ass.StudentAcademicCourse__r.coursecode__c) ;
            System.assert([select id, CourseMentorStudentAssignment__c from StudentAcademicCourse__c][0].CourseMentorStudentAssignment__c!=null);
           
      }
      
      static testmethod void testStudentAcademicTrigger()
      {
            insert new CourseList__c(CourseLong__c='all');
            List<sObject> contacts=Test.loadData(Contact.sObjectType, 'ContactTestData');
            //we have 1 students 
            Integer size=200;
            //we have 2 mentor
            List<StudentAcademicCourse__c> sacs=new List<StudentAcademicCourse__c>();   
            //300 valid scr
            for(integer i=0;i<size;i++)
            {
                StudentAcademicCourse__c sac=new StudentAcademicCourse__c(CourseCode__c='A'+i,StudentContact__c=contacts[0].Id, Term__c=Datetime.NOW().format('yyyyMM'),      startdate__c= date.today().addMonths(-2), enddate__c=date.today().addMonths(3),status__c = 'Registered');
       
                sacs.add(sac);
                 
            } 
            
             
            insert sacs;    
            //List<StudentCourseVersion__c> scvs=[select Completed__c , student__c, Status__c from StudentCourseVersion__c];
            
            
            
            
            Test.startTest();
        
            
                
            
            for(Integer i=0;i<sacs.size();i++)
            { 
                sacs[i].status__c='Passed';  
            }
            update sacs;
            Test.stopTest();
            
            
            
        
             
      } 
      
      @isTest(SeeAllData=true)
      static void testCaseLoadManagerPermissionSet() {
        //set mark O. with this permission set before this test case
          //List<PermissionSetAssignment> psa=[SELECT PermissionSetId,Assignee.Name, Assigneeid,PermissionSet.Label                                   FROM PermissionSetAssignment 
          //                          WHERE Assignee.Name ='Mark Obremski' and PermissionSet.Label = 'Records for PMs'
          //                          limit 1];
       // System.assert(psa.size()==1);
       // List<User> users=  [select id from User where id=:psa[0].Assigneeid limit 1];  
        //System.assert(users.size() != 0);
       // System.runAs(users[0]) 
        {
            //System.assert(UserInfo.getUserId() == users[0].id);
            System.assert(CourseMentorStudentAssignmentUtility.isCaseLoadManager());
            
        }
        
      
     }
     
     //for Code coverage of schedulor
     static testmethod void testCourseListNull()
     {
            
            Test.startTest(); 
            system.debug('%%%%%');
            
            CourseMentorStudentAssignmentSchedulor assignment= new CourseMentorStudentAssignmentSchedulor ();
            
            String seconds = '0'; //Execute at Zero Seconds
            String minutes = '30'; //Execute at every 10th minute of hour
            String hours = '*'; // Execute Every Hour
            String dayOfMonth = '*'; // Execute Every Day of the Month
            String month = '*'; //Execute only in November(11)
            String dayOfWeek = '?'; //Execute on all 7 days of the Week
            String year = '*'; //Execute only for year 2013
            
            //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
            String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek ;//+ ' ' + year;
            //String sch = ’0 10,20,30,40,50 * * 11 ? 2009′;
             
             
      //  List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10]; 
        
       // system.assert(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all')); 
            String jobid1=system.schedule('CourseMentor Batch Assignment1', sch, assignment);
  
            Test.stopTest();
           
     }
     //for Code coverage of schedulor
     static testmethod void testCourseListAll()
     {
            insert new CourseList__c(CourseLong__c='all');
            Test.startTest(); 
            system.debug('%%%%%');
            
            CourseMentorStudentAssignmentSchedulor assignment= new CourseMentorStudentAssignmentSchedulor ();
            
            String seconds = '0'; //Execute at Zero Seconds
            String minutes = '30'; //Execute at every 10th minute of hour
            String hours = '*'; // Execute Every Hour
            String dayOfMonth = '*'; // Execute Every Day of the Month
            String month = '*'; //Execute only in November(11)
            String dayOfWeek = '?'; //Execute on all 7 days of the Week
            String year = '*'; //Execute only for year 2013
            
            //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
            String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek ;//+ ' ' + year;
            //String sch = ’0 10,20,30,40,50 * * 11 ? 2009′;
             
             
      //  List<CourseList__c> courselist=[select id,CourseLong__c from CourseList__c limit 10]; 
        
       // system.assert(courselist.size()==1&&courselist[0].CourseLong__c.equalsIgnoreCase('all')); 
            String jobid1=system.schedule('CourseMentor Batch Assignment1', sch, assignment);
  
            Test.stopTest();
           
     }
     //for code coverage of bestMentor()
     static testmethod void testBestMentor()
     {
     	Test.startTest(); 
     	CourseMentorStudentAssignmentUtility.bestMentor(new Set<String>(),new  Map<String,Mentor__c> ());
     	Test.stopTest();
      
     }
     
    
}