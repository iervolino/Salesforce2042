/*
* Schedulable Class for updating Opportunity records with CAREStatusListView of 'ENRL' 
* and CloseDate occuring in the previous calendar month to CAREStatus of 'MATR – Matriculated'.
*
* Created 12/11/2013 by Katarina Melki
*/
global class EnrollToMatriculated implements Schedulable
{
    private static String CRON_EXP = '0 0 0 1 * ?';
    
    global static String schedule()
	{
		return System.schedule('CARE Status ENRL->MATR Update', CRON_EXP, new EnrolltoMatriculated());
	}
    
    global void execute(SchedulableContext sc)
    {
        List<Opportunity> opps=[SELECT Id, CAREStatus__c FROM Opportunity WHERE CAREStatusListView__c='ENRL' AND CloseDate=LAST_MONTH];

        for (Opportunity opp : opps) 
        {
            opp.CAREStatus__c='MATR – Matriculated';
        }
        
        update opps;
    }
}