/**
 * Author Paul R. Stay
 * Western Governors University @ 2014
 * Created Date: March 2014
 *
 * update - April 22 - Yemeng   : Add StudentAnalyticMessage into contact, update this field at the same time with StudentRiskScore__c
 
 * Utility Class for Student Analytics
 * Version 29.0
 */

public class StudentAnalyticsUtility {

	// we create a new record for each new piece of Analytics Data
	public static void insertStudentAnalytics(List<StudentAnalytics__c> triggernew){
		Map<String, ID> pidmToStudent = new Map<String,ID>();
		Set<String> pidmList = new Set<String>();
		List<Contact> studentList;

		for(StudentAnalytics__c s : triggernew){
			pidmList.add(s.PIDM__c);
		}

		// System.debug('***************************** PIDM LIST ************ -> ' + pidmList.size());
		// System.debug('***************************** PIDM LIST ************ -> ' + pidmList);

		if(!pidmList.isEmpty()){
			 studentList = [SELECT ID, PIDM__C  from Contact where PIDM__C in :pidmList];

			 // System.debug('^^^^^^^^^^^^^^^^^^^^^^^^ Student list is ' + studentList);

			 for(Contact c : studentList){
			 	pidmToStudent.put(c.PIDM__c, c.Id);
			 }
		}

		for(StudentAnalytics__c sa : triggernew){
			// System.debug('############################## Setting PIDM__C to : ' + sa.PIDM__C);
			// System.debug('############################## Setting Student__c to : ' + pidmToStudent.get(sa.PIDM__c));
			if(pidmToStudent.get(sa.PIDM__c) != null) {
				sa.Student__c = pidmToStudent.get(sa.PIDM__c);
				} else {
					sa.addError('Student__c relation not found');
				}
		}

	}

	public static void updateStudentRiskFactor(List<StudentAnalytics__c> triggerlist) {
		List<Contact> students = new List<Contact>();

		for( StudentAnalytics__c sa : triggerList){
			if(sa.Student__c != null){
				Contact myStudent = new Contact(id=sa.student__C);
				myStudent.StudentRiskScore__c = sa.RiskFactor__c;
				myStudent.StudentAnalyticMessage__c = sa.MentorSuggestion__c;
				students.add(myStudent);
			}
		}
		update students;
	}

}