global with sharing class MyCourseAssignmentsController {
    
    private List<MentorCourseAssignment__c> myCourses;
    public String[] selectedCourses {get;set;}
            
    public MyCourseAssignmentsController() {}
    
    public MyCourseAssignmentsController(ApexPages.StandardController controller) {
        System.debug('User id is ' + UserInfo.getUserId());
    }

    public List<SelectOption> getMyCourses() {
        String userId = UserInfo.getUserId();
        // First check to see if the user is an employee
        System.debug('Getting Courses for ' + UserInfo.getUserName());
        ID StudentProfileID = [select id from Profile where Name ='Student Profile' LIMIT 1].ID;
        if( [Select count() from User where isEmployee__c = true AND id = :userId
            AND ProfileID != :StudentProfileID] > 0) {
             
            // Check to make sure that there are course (i.e. this is a course mentor)
            this.myCourses = [Select count() from MentorCourseAssignment__c where Mentor__c = :userId] > 0 ?
                [Select CourseNumber__c from MentorCourseAssignment__c where Mentor__c = :userId] :
                new List<MentorCourseAssignment__c>();
                   
        }
        List<SelectOption> options = new List<SelectOption>();
        
        if(myCourses.size() > 0)  {
            for(MentorCourseAssignment__c course : myCourses) {
                options.add(new SelectOption(course.courseNumber__c, course.courseNumber__c));        
            }
        }
        
        return (UserInfo.getProfileID() != StudentProfileID)? options : new List<SelectOption>();
    }
    
    public List<MentorCourseAssignment__c> getMyCoursesByUserId(String userId) {
        // First check to see if the user is an employee
        ID StudentProfileID = [select id from Profile where Name ='Student Profile' LIMIT 1].ID;
        if( [Select count() from User where isEmployee__c = true AND id = :userId 
            AND ProfileID != :StudentProfileID] > 0) {
             
            // Check to make sure that there are course (i.e. this is a course mentor)
            this.myCourses = [Select count() from MentorCourseAssignment__c where Mentor__c = :userId] > 0 ?
                [Select CourseNumber__c from MentorCourseAssignment__c where Mentor__c = :userId] :
                new List<MentorCourseAssignment__c>();
                   
        } 
        return (UserInfo.getProfileID() != StudentProfileID)? this.myCourses: new List<MentorCourseAssignment__c>();
    }    
    
    public String[] getSelectedCourses(){
       return selectedCourses; 
    }
    
    public void setSelectedCourses(String[] courses) {
        this.selectedCourses = courses;
    }
    
    public void loadCourses() {
        User me = new User(id=UserInfo.getUserId());
        String courseList = '';
        for(String s:selectedCourses) {
            courseList += (courseList == '' ? '' : ',') + s.toUpperCase();
        }

        me.CoursesIManage__c = courseList;
        update me;
    }
}