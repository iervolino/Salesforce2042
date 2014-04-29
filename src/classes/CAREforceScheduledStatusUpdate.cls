global class CAREforceScheduledStatusUpdate implements Schedulable {
    private static String CRON_EXP = '0 0 5 * * ?'; // Run every day at 5 AM.

    global static void schedule() {
        System.schedule('CARE Status Update', CRON_EXP, new CAREforceScheduledStatusUpdate());
    }


    global void execute(SchedulableContext sc) {
        List<Opportunity> opps = [SELECT Id, CAREStatus__c, Account.StudentContact__r.Status__c, Inactive__c, StopEmails__c, StopAllContact__c, StopPhoneCalls__c 
                                     FROM Opportunity WHERE 
                                        (CAREStatus__c LIKE 'CLRD%' AND CloseDate = THIS_MONTH AND Account.StudentContact__r.Status__c = 'AS') OR 
                                        (CAREStatus__c LIKE 'ENRL%' AND CloseDate = LAST_MONTH AND Account.StudentContact__r.Status__c = 'AS') OR
                                        (CAREStatus__c LIKE 'MATR%' AND Account.StudentContact__r.Status__c IN ('WI', 'DD', 'DR', 'IG'))
                                     LIMIT 10000];
        
        for (Opportunity opp : opps) {
            if (opp.CAREStatus__c.startsWith('CLRD')) {
                opp.CAREStatus__C = 'ENRL – Enrolled and Assigned a Mentor';
                continue;
            }
            
            if (opp.CAREStatus__c.startsWith('ENRL')) {
                opp.CAREStatus__C = 'MATR – Matriculated';
                continue;
            }
            
            if (opp.CAREStatus__c.startsWith('MATR') && opp.Account.StudentContact__r.Status__c == 'IG') {
                opp.CAREStatus__C = 'GRAD – Ready for Graduation';         
                continue;     
            }
            
            if (opp.CAREStatus__c.startsWith('MATR') && 
                (opp.Account.StudentContact__r.Status__c == 'WI' || opp.Account.StudentContact__r.Status__c == 'DD' || opp.Account.StudentContact__r.Status__c == 'DR')) {
                opp.CAREStatus__C = 'DROP – Dropped';  
                opp.Inactive__c = true;
                opp.StopEmails__c = true;
                opp.StopAllContact__c = true;
                opp.StopPhoneCalls__c = true;
                continue;            
            }                      
        }
        
        update opps;        
    }
}