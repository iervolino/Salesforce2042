/*
* Test class to test the EnrollToMatriculated and ClearedToEnrolled schedulable classes.
*
* Created 12/11/2013 by Katarina Melki
*/
@istest
public class TestCAREStatusChange
{
    //Tests EnrollToMatriculated schedulable class
	static testmethod void testEnrollToMatriculated()
    {
        Opportunity testOpp=new Opportunity(Name='Test Enrolled', StageName='Intake', CAREStatus__c='ENRL – Enrolled and Assigned a Mentor', CloseDate=Date.today().addMonths(-1));
        insert testOpp;
        
        Test.startTest();
        	String jobId=System.schedule('Test CARE Status ENRL->MATR Update', '0 0 0 3 9 ? 2022', new EnrolltoMatriculated());
        	String jobId2=EnrolltoMatriculated.schedule();
        
        	CronTrigger ct=[select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
        	CronTrigger ct2=[select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId2];
        
        	System.assertEquals('0 0 0 3 9 ? 2022', ct.CronExpression);
        	System.assertEquals('0 0 0 1 * ?', ct2.CronExpression);
        	System.assertEquals(0, ct.TimesTriggered);
        	System.assertEquals(0, ct2.TimesTriggered);
        	System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        	System.assertNotEquals('MATR – Matriculated', [select CAREStatus__c from Opportunity where Id=:testOpp.Id].CAREStatus__c);
        Test.stopTest();
        
        System.assertEquals('MATR – Matriculated', [select CAREStatus__c from Opportunity where Id=:testOpp.Id].CAREStatus__c);
    }
    
    //Tests ClearedToEnrolled schedulable class
    static testmethod void testClearedToEnrolled()
    {
        Opportunity testOpp=new Opportunity(Name='Test Cleared', StageName='Intake', CAREStatus__c='CLRD - Cleared to Start', CloseDate=Date.today());
        insert testOpp;
        
        Test.startTest();
        	String jobId=System.schedule('Test CARE Status CLRD->ENRL Update', '0 0 0 3 9 ? 2022', new ClearedToEnrolled());
        	String jobId2=ClearedToEnrolled.schedule();
        
        	CronTrigger ct=[select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
        	CronTrigger ct2=[select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId2];
        
        	System.assertEquals('0 0 0 3 9 ? 2022', ct.CronExpression);
        	System.assertEquals('0 0 1 1 * ?', ct2.CronExpression);
        	System.assertEquals(0, ct.TimesTriggered);
        	System.assertEquals(0, ct2.TimesTriggered);
        	System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        	System.assertNotEquals('ENRL – Enrolled and Assigned a Mentor', [select CAREStatus__c from Opportunity where Id=:testOpp.Id].CAREStatus__c);
        Test.stopTest();
        
        System.assertEquals('ENRL – Enrolled and Assigned a Mentor', [select CAREStatus__c from Opportunity where Id=:testOpp.Id].CAREStatus__c);
    }
}