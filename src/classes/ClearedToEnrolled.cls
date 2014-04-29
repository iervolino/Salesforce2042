/*
* Schedulable Class for updating Opportunity records with CAREStatusListView of 'CLRD' 
* and CloseDate occuring in the current calendar month to CAREStatus of 'ENRL – Enrolled and Assigned a Mentor'.
*
* Created 12/11/2013 by Katarina Melki
*/
global class ClearedToEnrolled implements Schedulable
{
    private static String CRON_EXP = '0 0 1 1 * ?';
    
    global static String schedule()
	{
		return System.schedule('CARE Status CLRD->ENRL Update', CRON_EXP, new EnrolltoMatriculated());
	}
    
    global void execute(SchedulableContext sc)
    {
        List<Opportunity> opps=[SELECT Id, CAREStatus__c FROM Opportunity WHERE CAREStatusListView__c='CLRD' AND CloseDate=THIS_MONTH];

        for (Opportunity opp : opps) 
        {
            opp.CAREStatus__c='ENRL – Enrolled and Assigned a Mentor';
        }
        
        update opps;
    }
}