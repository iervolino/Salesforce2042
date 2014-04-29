/*
 * Author Paul Stay
 * Western Governors University @ 2013
 * 
 * This allows a user (student mentor) to select one or more courses and then using a extended list view
 * display the students in the course that are assigned to that student mentor.
 */


public with sharing class MyStudentsInACourseController {
    
    public String selectedCourses;
    
    public MyStudentsInACourseController() {}
    
    public MyStudentsInACourseController(ApexPages.StandardController controller) {
        System.debug('User id is ' + UserInfo.getUserId());
    }
    
    public void setSelectedCourses(String courses) {
        selectedCourses = courses;
    }
    
    public String getSelectedCourses() {
        return selectedCourses;
    }
    
    public void loadCourses(){
        User me = new User(id=UserInfo.getUserId());
        String courseList = selectedCourses;

        me.CoursesIManage__c = courseList.toUpperCase();
        update me;
    }
}