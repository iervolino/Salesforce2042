@IsTest
public class TestFDPUtilities {

    @IsTest
    static void formatDateLongMonthYearTest() {
        Date myDate = Date.newInstance(2010, 5, 1);
        String output = FDPUtilities.formatDateLongMonthYear(myDate);
        System.assertEquals('May 2010',output);
    }

    @isTest
    static void testFormatDateLong() {
      Date myDate = Date.newInstance(2010,5,1);
      String output = FDPUtilities.formatDateLong(myDate);
      System.assertEquals('May 1, 2010',output);
    }

    @isTest
    static void getidfromcoursepamsid(){
        FDPUtilities.PAMSMappings mapping=new FDPUtilities.PAMSMappings();
        mapping.getidfromcoursepamsid(1232);
        mapping.getidfromprogrampamsid(1232);

    }

    @isTest
    static void testBatchdelete(){
        FDPUtilities.batchdelete();

    }

    @isTest
    static void testFormatCurrency() {
        System.assertEquals(FDPUtilities.formatCurrency(5000.00,0),'$5,000');
        System.assertEquals(FDPUtilities.formatCurrency(100.0,0),'$100');
        System.assertEquals(FDPUtilities.formatCurrency(1000000.0,0),'$1,000,000');
        System.assertEquals(FDPUtilities.formatCurrency(10000000.0,0),'$10,000,000');
    }

    @isTest
    static void testGetTermEndDateByCode() {
        Date one=FDPUtilities.getTermEndDateByCode('201205');
        System.assertEquals(31,one.day());
    }

    //@isTest
     static void testGetPlanStartDate() {
         FDPTestingUtilities utility = new FDPTestingUtilities();
        Date one=FDPUtilities.getPlanStartDate(utility.plan.id);
        System.assertEquals(utility.terms[0].startDate__C,one);

    }

    //@IsTest
     static void testMappingCompletedCourses(){
            FDPTestingUtilities utility = new FDPTestingUtilities();
            WGUCourseCompletionTask__c task1=utility.generateWGUCourseCompletionTask(utility.definitions[0]);
             WGUCourseCompletionTask__c task2=utility.generateWGUCourseCompletionTask(utility.definitions[0]);
             WGUCourseCompletionTask__c task3=utility.generateWGUCourseCompletionTask(utility.definitions[1]);
            StudentCompletionTask__c one=new StudentCompletionTask__c();
            one.WGUCourseCompletionTask__c=task1.id;
            one.StatusDate__c=Date.today();
            one.Student__c=utility.contact.id;
            one.TermCode__c='201004';
            one.AssessmentStatus__c = 'Passed';
            insert one;
               StudentCompletionTask__c three=new StudentCompletionTask__c();
            three.WGUCourseCompletionTask__c=task3.id;
            three.Student__c=utility.contact.id;
              three.StatusDate__c=Date.today();
               three.TermCode__c='201004';
               three.AssessmentStatus__c = 'Passed';
            insert three;
           System.assertequals('Planned',utility.courses[0].Status__c);
             System.assertequals('Planned',utility.courses[1].Status__c);
            String course0Id = utility.courses[0].Id;
            String course1Id = utility.courses[1].Id;
            System.debug('course0Id: ' + course0Id);
            System.debug('course1Id: ' + course1Id);

            StudentCourse__c course1= [select Status__c from StudentCourse__c where id= :course0Id];
            System.assertequals('Planned',course1.Status__c);
             List<StudentCourse__c> emptyCourseList= [select Status__c from StudentCourse__c where id= :course1Id];
            System.assertEquals(1,emptyCourseList.size());
            List<StudentCourse__c> completedCourses = [select Status__c from StudentCourse__c where id = :utility.currentPlanCourses[1].Id];
            System.assertequals('Completed',completedCourses[0].Status__c);

            StudentCompletionTask__c two=new StudentCompletionTask__c();
            two.WGUCourseCompletionTask__c=task2.id;
             two.Student__c=utility.contact.id;
              two.StatusDate__c=Date.today();
               two.TermCode__c='201004';
               two.AssessmentStatus__c = 'Passed';
            insert two;
              
              emptyCourseList= [select status__C from StudentCourse__C where id= :utility.courses[0].id];
              System.assertEquals(1,emptyCourseList.size());
            completedCourses = [select Status__c from StudentCourse__c where id = :utility.currentPlanCourses[0].Id];
            System.assertequals('Completed',completedCourses[0].Status__c);
    }

    //@IsTest
      static void testMappingCompletedCoursesWithNonmappedCourse(){
            FDPTestingUtilities utility = new FDPTestingUtilities();
            WGUCourseCompletionTask__c task1=utility.generateWGUCourseCompletionTask(utility.definitions[0]);
             WGUCourseCompletionTask__c task2=utility.generateWGUCourseCompletionTask(utility.definitions[0]);
             WGUCourseCompletionTask__c task3=utility.generateWGUCourseCompletionTask(utility.definitions[1]);
            StudentCompletionTask__c one=new StudentCompletionTask__c();
            one.WGUCourseCompletionTask__c=task1.id;
            one.StatusDate__c=Date.today();
            one.Student__c=utility.contact.id;
            one.AssessmentStatus__c = 'Passed';
            insert one;
               StudentCompletionTask__c three=new StudentCompletionTask__c();
            three.WGUCourseCompletionTask__c=task3.id;
            three.Student__c=utility.contact.id;
              three.StatusDate__c=Date.today();
              three.AssessmentStatus__c = 'Passed';
            insert three;
            
            StudentCompletionTask__c two=new StudentCompletionTask__c();
            two.WGUCourseCompletionTask__c=task2.id;
             two.Student__c=utility.contact.id;
              two.StatusDate__c=Date.today();
              two.AssessmentStatus__c = 'Passed';
            insert two;
            WGUCourse__c definition = new WGUCourse__c();
            definition.name = 'test course that not mapped';
            definition.competencyunits__c = 5;
            definition.PAMSID__c = Math.random();
            insert definition;
            WGUCourseCompletionTask__c tie = new WGUCourseCompletionTask__c();
            tie.WGUCourse__c = definition.id;
            insert tie;
           
            StudentCompletionTask__c four=new StudentCompletionTask__c();
            four.WGUCourseCompletionTask__c=tie.id;
            four.Student__c=utility.contact.id;
            four.StatusDate__c=Date.today();
            four.TermCode__c='199812';
            four.AssessmentStatus__c = 'Passed';
            insert four;
          
            List<StudentCourse__c> created= [select StudentTerm__c,Status__c from StudentCourse__C where name='test course that not mapped'];
            System.assertEquals(1,created.size());
            System.assertequals('Completed',created[0].Status__c);
            List<StudentTerm__c> termcreated= [select name,StudentDegreePlan__c from Studentterm__C where id=:created[0].StudentTerm__c];
                System.assertequals('199812',termcreated[0].name);
                StudentDegreePlans__c plan=[select id from StudentDegreePlans__c where CurrentPlan__c = true];
                System.assertequals(plan.id,termcreated[0].StudentDegreePlan__c);
            List<StudentCourse__c>  emptyCourseList= [select status__C from StudentCourse__C where id= :utility.courses[0].id];
            System.assertEquals(1,emptyCourseList.size());
            List<StudentCourse__c> completedCourses = [select Status__c from StudentCourse__c where id = :utility.currentPlanCourses[0].Id];
            System.assertequals('Completed',completedCourses[0].Status__c);
    }

    //@isTest
    //TODO remove all references to FDPTestingUtilities and delete the class
     static void testClonePlan(){
      FDPTestingUtilities util = new FDPTestingUtilities();
      StudentDegreePlans__C plan=FDPUtilities.cloneStudentDegreePlan(util.plan.id,  'test');
      System.debug(plan);
      System.assert(plan.name=='test');
      System.assert(plan.id!=null);
     }
}