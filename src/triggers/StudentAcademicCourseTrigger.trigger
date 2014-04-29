/*
*
* Trigger of StudentAcademicCourse
* Western Governer University
*
* Created by 
*   Edit by 
*   Edit by Yemeng Zhu March, 2014 Passed courses -> release its case load 
* 
*
*/
trigger StudentAcademicCourseTrigger on StudentAcademicCourse__c (after insert, after update, after delete) {
    CourseCommunitiesGroupPermissionUtil util = new CourseCommunitiesGroupPermissionUtil();
    if(Trigger.isInsert) {
        List<StudentAcademicCourse__c> sacList = Trigger.New;
        Map<String, Contact> studentContactMap = util.getStudentContactMap(sacList);
        List<StudentAcademicCourse__c> needToAddList = new List<StudentAcademicCourse__c>();
        List<StudentAcademicCourse__c> needToAddViewerList = new List<StudentAcademicCourse__c>();
        for(StudentAcademicCourse__c academicCourse : sacList) {
            if(academicCourse.StudentContact__c == null 
               || !studentContactMap.containsKey(academicCourse.StudentContact__c)
               || academicCourse.Term__c == null) 
            {
                continue;
            }
            
            if(academicCourse.Term__c.equals(studentContactMap.get(academicCourse.StudentContact__c).CurrentTerm__c)) {
                if(academicCourse.Status__c.equals('Not Passed')
                   || academicCourse.Status__c.equals('Registered')) 
                {
                    needToAddList.add(academicCourse);
                }
                else {
                    needToAddViewerList.add(academicCourse);
                }
            }
            else {
                needToAddViewerList.add(academicCourse);
            }
        }
        util.updateCourseGroupPermissions(needToAddList, 'N', 'Contributor');
        util.updateCourseGroupPermissions(needToAddViewerList, 'N', 'Viewer');
    }
    else if(Trigger.isUpdate) {
        List<StudentAcademicCourse__c> needToAddList = new List<StudentAcademicCourse__c>();
        List<StudentAcademicCourse__c> needToRemoveList = new List<StudentAcademicCourse__c>();
        
        List<StudentAcademicCourse__c> updatedList = Trigger.new;
        Map<String, Contact> studentContactMap = util.getStudentContactMap(updatedList);
        for(Integer i = 0; i < updatedList.size(); i++) {
            StudentAcademicCourse__c studentCourse = updatedList.get(i);
            if(studentCourse.Status__c.equals(Trigger.oldMap.get(studentCourse.id).Status__c)) {
                continue;
            }
            
            if(studentCourse.Status__c.equals('Passed')
               || studentCourse.Status__c.equals('Transferred')
               || studentCourse.Status__c.equals('Requirements Met')
               || studentCourse.Status__c.equals('Unenrolled')
               || studentCourse.Status__c.equals('Planned')) 
            {
                needToRemoveList.add(studentCourse);
                continue;
            }
            
            if(studentCourse.StudentContact__c == null 
               || !studentContactMap.containsKey(studentCourse.StudentContact__c)
               || studentCourse.Term__c == null) 
            {
                continue;
            }
            
            if(studentCourse.Term__c.equals(studentContactMap.get(studentCourse.StudentContact__c).CurrentTerm__c)
               && (studentCourse.Status__c.equals('Not Passed')
                   || studentCourse.Status__c.equals('Registered'))) {
                needToAddList.add(studentCourse);
            }
        }
        
        util.updateCourseGroupPermissions(needToAddList, 'N', 'Contributor');
        util.updateCourseGroupPermissions(needToRemoveList, 'N', 'Viewer');
        
        //Case Load: remove assignment when course passed
        List<StudentAcademicCourse__c> completeList =new List<StudentAcademicCourse__c>();
        for(StudentAcademicCourse__c studentCourse : Trigger.new)
        {
            if(studentCourse.status__c == 'Passed')
            {
                completeList.add(studentCourse);
            } 
        }
        CourseMentorStudentAssignmentUtility.removeAssignmentsForPassedCourses(completeList,'Pass');
        //Case Load : block end
    }
    else if(Trigger.isDelete) {
        util.updateCourseGroupPermissions(Trigger.old, 'N', 'Viewer');
    }
    
    // integration for SFAW course and email update
    if(Trigger.isAfter && Trigger.isInsert){
        List<StudentAcademicCourse__c> sacList = new List<StudentAcademicCourse__c>();
        for(StudentAcademicCourse__c sac : Trigger.new){
            if('SFAW'.equals(sac.CourseCode__c) && 'Passed'.equals(sac.Status__c)){
                sacList.add(sac);
            } 
        }
        if(sacList.size()>0){
            StudentAcademicCourseUtility.insertSFAWcrseReq(JSON.serialize(sacList));
        }
    }
}