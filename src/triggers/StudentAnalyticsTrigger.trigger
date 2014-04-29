/**
 * Author Paul R. Stay
 * Western Governors University @ 2014
 * Created Date: March 2014
 *
 * Trigger before insert: for each StudentAnalytics  bonding it to the correct student through the pidm
 * Trigger after insert: update StudentRiskScore__c and StudentAnalyticMessage__c fields in Contact.
 * Version 29.0
 */
trigger StudentAnalyticsTrigger on StudentAnalytics__c (before insert, after insert) {

	// Call the utility class for before insert, this maps the pidm to the student
	if(Trigger.isBefore) {
		System.debug('++++++++++++++++++++++++ Anayltics Trigger ++++++++++++++++++++++');
		StudentAnalyticsUtility.insertStudentAnalytics(Trigger.new);
	}

	if(Trigger.isAfter) {
		System.debug('######################### Analytics After Insert');
		StudentAnalyticsUtility.updateStudentRiskFactor(Trigger.new);
	}
	
}