trigger CourseInProgramTrigger on WGUCourseInProgram__c (before insert, before update) {
    Map<Decimal, String> programidmap = new Map<decimal,String>();
    Map<Decimal, String> courseidmap = new Map<decimal,String>();
    List<Decimal> programCodes = new List<Decimal>();
    List<Decimal> courseCodes = new List<Decimal>();

    for(WGUCourseInProgram__c mapping : trigger.new) {
        if (mapping.PAMSProgramID__c != null)
            programCodes.add(mapping.PAMSProgramID__c);
        if (mapping.PAMSCourseID__c != null)
            courseCodes.add(mapping.PAMSCourseID__c);
    }
    if (!programCodes.isEmpty()) {
        list<WGUDegreeProgram__c> programs = [select id, PAMSID__c from WGUDegreeProgram__c WHERE PAMSID__c in :programCodes];

        for(WGUDegreeProgram__c program : programs){
            programidmap.put(program.PAMSID__c, program.id);
        }
    }

    if (!courseCodes.isEmpty()) {
        List<WGUCourse__C> courses = [select id, PAMSID__c from wgucourse__C WHERE PAMSID__C in :courseCodes];

        for(WGUCourse__C course : courses){
            courseidmap.put(course.PAMSID__c, course.id);
        }
    }

    for(WGUCourseInProgram__c mapping : trigger.new) {
        if (mapping.PAMSProgramID__c != null)
            mapping.Program__C = programidmap.get((Integer)mapping.PAMSProgramID__c);

        if (mapping.PAMSCourseID__c != null)
            mapping.Course__C = courseidmap.get((Integer)mapping.PAMSCourseID__c);

    }
}