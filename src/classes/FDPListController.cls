public with sharing class FDPListController {
    public Map<Id,StudentObj> StudentsMap {get;set;}
    public List<StudentObj> StudentsList {get;set;}
    public List<MentorObj> MentorsList {get;set;}
    public Id MentorUserId;

    public with sharing class MentorObj {
      public Id MentorUserId {get;set;}
      public String MentorPIDM {get;set;}
      public String MentorName {get;set;}
      public Boolean IsCurrentUser {get;set;}
    }

    public with sharing class StudentObj {
      public Map<String,TermCode> TermCodesMap {get;set;}
      public List<TermCode> TermCodesList {get;set;}
      public String Name {get;set;}
      public String PIDM {get;set;}
      public String StudentId {get;set;}
      public Id Id {get;set;}
      public Boolean RequiresApproval {get;set;}
      public DateTime LastApprovedDate {get;set;}
      public DateTime LastModifiedDate {get;set;}
      public Integer DueIn {get;set;}
      public Date RollDate {get;set;}
      public String Status {get;set;}
      public Boolean IsRendered {get;set;}
      public StudentObj() {
        TermCodesMap = new Map<String,TermCode>();
        TermCodesList = new List<TermCode>();
        LastApprovedDate = DateTime.newInstance(1901,1,1);
        LastModifiedDate = DateTime.newInstance(1901,1,1);
        RequiresApproval = false;
        IsRendered = false;
      }
    }

    public with sharing class TermCode {
    	public List<StudentTerm__c> terms {get;set;}
    	public String TermCode {get;set;}
    	public DateTime LastApprovedDate {get;set;}
    	public DateTime LastModifiedDate {get;set;}
        public Date StartDate {get;set;}
        public Boolean RequiresApproval {get;set;}
        public Integer UnenrolledCourses {get;set;}
    	public TermCode() {
    		terms = new List<StudentTerm__c>();
    		LastApprovedDate = DateTime.newInstance(1901,1,1);
    		LastModifiedDate = DateTime.newInstance(1901,1,1);
    	}
    	public TermCode(String pTermCode) {
    		this();
    		TermCode = pTermCode;
    	}
    }

	public FDPListController() {}
        public with sharing class FDPListException extends Exception{}

        public PageReference changeMentor() {
          this.MentorUserId = (Id)ApexPages.currentPage().getParameters().get('MentorId');
          loadStudents();
          return null;
        }

        public void loadStudents() {
          StudentsMap = new Map<Id,StudentObj>();
          StudentsList = new List<StudentObj>();
	  List<StudentTerm__c> results = [
	    select Student__r.Id,
	    Student__r.Name,
	    Student__r.PIDM__c,
	    Student__r.StudentId__c,
	    LastModifiedDate,
	    ApprovalDateTime__c,
	    Approved__c,
            StartDate__c,
	    Name,
          (
            select Name,
            Status__c
            from StudentCourses__r
            where Status__c != 'Enrolled'
            and Status__c != 'Submitted'
            and Status__c != 'Completed'
            and Status__c != 'Failed'
          )
		  from StudentTerm__c
          where ((
              StartDate__c <= NEXT_MONTH
              and EndDate__c >= NEXT_MONTH
            ) or (
              StartDate__c <= Today
              and EndDate__c >= Today
            )) and Student__r.Mentor__c = :MentorUserId
		];
		for(StudentTerm__c res:results) {
			StudentObj student;
			if(!StudentsMap.containsKey(res.Student__c)) {
				student = new StudentObj();
				StudentsMap.put(res.Student__c,student);
			} else {
				student = StudentsMap.get(res.Student__c);
			}
			TermCode tc;
			if(!student.TermCodesMap.containsKey(res.Name)) {
				tc = new TermCode(res.Name);
                tc.StartDate = res.StartDate__c;
				student.TermCodesMap.put(res.Name,tc);
				student.TermCodesList.add(tc);
			} else {
				tc = student.TermCodesMap.get(res.Name);
			}
			tc.terms.add(res);
			student.Name = res.Student__r.Name;
			student.Id = res.Student__c;
			student.StudentId = res.Student__r.StudentId__c;
			student.PIDM = res.Student__r.PIDM__c;
		}
		for(Id key: StudentsMap.keySet()) {
			StudentObj student = StudentsMap.get(key);
			for(String code : student.TermCodesMap.keySet()) {
				TermCode tc = student.TermCodesMap.get(code);
				for(StudentTerm__c term : tc.terms) {
					if(term.LastModifiedDate > tc.LastModifiedDate) {
					    tc.LastModifiedDate = term.LastModifiedDate;
					}
                }
                for(StudentTerm__c term : tc.terms) {
                    DateTime approvalDT = null;
                    if(term.ApprovalDateTime__c != null)
                        approvalDT = term.ApprovalDateTime__c.addMinutes(2);
					if(term.Approved__c && approvalDT > tc.LastApprovedDate) {
						tc.LastApprovedDate = approvalDT;
                    }
                    if(tc.UnEnrolledCourses == null || tc.UnenrolledCourses < term.StudentCourses__r.size()) {
                        tc.UnenrolledCourses = term.StudentCourses__r.size();
                    }
				}
				if(tc.LastModifiedDate > tc.LastApprovedDate) {
                    tc.RequiresApproval = true;
					student.RequiresApproval = true;
                    student.IsRendered = true;
                    if(tc.StartDate < student.RollDate || student.RollDate == null) {
                      student.DueIn = Date.Today().daysBetween(tc.StartDate);
                      student.RollDate = tc.StartDate;
                    }
				} else if(tc.UnenrolledCourses > 0) {
                    student.Status = 'Approved';
                    student.IsRendered = true;
                    if(tc.StartDate < student.RollDate || student.RollDate == null) {
                      student.DueIn = Date.Today().daysBetween(tc.StartDate);
                      student.RollDate = tc.StartDate;
                    }
                }
			}
			StudentsList.add(student);
		}

        }

	public void initialize() {
          User u = [select
            ContactId,
            UserType,
            Name,
            PIDM__c
            from User
            where id = :UserInfo.getUserID()];
          if(u.UserType != 'Standard') {
            throw new FDPListException('You do not have access to this page.');
          }
          MentorUserId = u.Id;
          MentorsList = new List<MentorObj>();
          List<AggregateResult> mList = [select
            Mentor__r.Name mname,
            Mentor__r.PIDM__c mpidm,
            Mentor__r.Id mid
            from Contact
            where Mentor__r.Name != null
            and Mentor__c != :u.Id
            group by Mentor__r.Name,
            Mentor__r.PIDM__c,
            Mentor__r.Id];
          MentorObj currentM = new MentorObj();
          currentM.MentorUserId = u.Id;
          currentM.MentorName = 'Current User (' + u.Name + ')';
          currentM.MentorPIDM = u.PIDM__c;
          currentM.IsCurrentUser = true;
          MentorsList.add(currentM);
          for(AggregateResult r : mList) {
            MentorObj mo = new MentorObj();
            mo.MentorUserId = (Id)r.get('mid');
            mo.MentorName = (String)r.get('mname');
            mo.MentorPIDM = (String)r.get('mpidm');
            mo.IsCurrentUser = false;
            MentorsList.add(mo);
          }
          loadStudents();
    }
}