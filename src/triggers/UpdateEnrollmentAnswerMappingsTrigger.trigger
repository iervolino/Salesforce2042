// Reviewed 5/18/2012
trigger UpdateEnrollmentAnswerMappingsTrigger on EnrollmentAnswers__c (before insert) {
    List<EnrollmentQuestions__c> questions = [SELECT id, name FROM EnrollmentQuestions__c];

    for (EnrollmentAnswers__c answer : trigger.new) {
        if (answer.EnrollmentQuestion__c != null && (answer.QuestionKey__c == null)) {
            for (EnrollmentQuestions__c question : questions) {
                if (answer.EnrollmentQuestion__c == question.id) {
                    answer.QuestionKey__c = Decimal.valueOf(question.name);
                }
            }
        }
        
        if (answer.EnrollmentQuestion__c == null && answer.QuestionKey__c != null) {
            for (EnrollmentQuestions__c question : questions) {
                if (answer.QuestionKey__c == Decimal.valueOf(question.name)) {
                    answer.EnrollmentQuestion__c = question.id;
                }
            }        
        }
    }
}