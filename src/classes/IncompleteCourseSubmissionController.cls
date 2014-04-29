public with sharing class IncompleteCourseSubmissionController {
    public Flow.Interview.ICLREOTRequestFlow Test1{ get; set; }
    public IncompleteCourseSubmissionController(ApexPages.StandardController controller) {

    }
    public String getStdID() {
        String sId=Test1==null?'':Test1.StudentProcessId;
        /*if (Test1==null) return '';
    else return Test1.StudentProcessId;*/
    return sId;
    }

    public PageReference getNextPage(){
        system.debug('raavi============ '+getStdID());
        PageReference p = new PageReference('/'+getStdID());
        p.setRedirect(true);
    return p;
}

}