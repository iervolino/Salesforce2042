@isTest
public with sharing class TestOpportunityToBannerUtility{

    @isTest
    private static void testCreateOppToBanner(){
        AccountTestingUtility util = new AccountTestingUtility('test');
        util.save();
        
        Contact baggins = [SELECT Id, PIDM__c, FirstName, LastName FROM Contact WHERE LastName = 'Baggins' LIMIT 1];
        
        StudentAttributes__c testSA = new StudentAttributes__c(StudentContact__c = baggins.Id,Affiliation__c = 'WGU-TX');
        insert testSA;
        
        CAREProgram__c cProgram = new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test');
        insert cProgram;
        
        WGUDegreeProgram__c original = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test');
        insert original;
        
        CareProgramMiddleEarth__c middleEarth = new CareProgramMiddleEarth__c(Name=cProgram.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram.Id, BannerProgramCode__c=original.Id);
        insert middleEarth;

       Opportunity testOpp = new Opportunity(StudentContact__c = baggins.Id,
                                              name='Frodo Baggins',
                                              DiscountAmount__c = 100.00, LearnAboutFinancialAid__c = true,
                                              IntakeBy__c = 'test in take',
                                              ApplicationFeeAmount__c = 10.00, PaymentType__c = 'Check',
                                              stageName='Prospect', closeDate=Date.today(),
                                              PIDM__c = baggins.PIDM__c,CAREStatus__c='PROS – Prospect' );
        
        Test.startTest();
            insert testOpp;
        Test.stopTest();
        
        List<OpportunityToBanner__c> testOppTBList = [SELECT Opportunity__c,CampusCodeOut__c,DiscountAmountOUT__c,FinAidOUT__c,
                                                          intakeInterviewUserPIDMOUT__c, MajorOfInterestOUT__c,
                                                          PaymentAmountOUT__c, PaymentTypeOUT__c,
                                                          PIDMOUT__c, ProfileStatusOUT__c
                                                      FROM OpportunityToBanner__c
                                                      WHERE Opportunity__c =: testOpp.Id LIMIT 5];

        System.assertEquals(testOppTBList.size(), 1, 'Excess control records created - expected 1, found ' + testOppTBList.size() );
        System.assertEquals(testOppTBList[0].Opportunity__c,testOpp.Id, 'Control record linked to incorrect Opportunity record');
        System.assertEquals(testOppTBList[0].CampusCodeOUT__c,testOpp.StudentAttributes__r.Affiliation__c, 'Incorrect campus code control record' );
        System.assertEquals(testOppTBList[0].DiscountAmountOUT__c,testOpp.DiscountAmount__c, 'Incorrect discount amount control record' );
        String boolstr = testOpp.LearnAboutFinancialAid__c ? 'Y' : 'N';
        System.assertEquals(testOppTBList[0].FinAidOUT__c,boolstr, 'Incorrect Fin Aid control record-YN' );
        System.assertEquals(testOppTBList[0].intakeInterviewUserPIDMOUT__c,testOpp.IntakeBy__c, 'Incorrect intake by control record' );
        System.assertEquals(testOppTBList[0].MajorOfInterestOUT__c,testOpp.MarketingProgram__r.BannerProgramCode__r.Name, 'Incorrect major of interest control record' );
        System.assertEquals(testOppTBList[0].PaymentAmountOUT__c,testOpp.ApplicationFeeAmount__c, 'Incorrect payment amount control record' );
        System.assertEquals(testOppTBList[0].PaymentTypeOUT__c,testOpp.PaymentType__c, 'Incorrect payment type control record' );
        System.assertEquals(testOppTBList[0].PIDMOUT__c,testOpp.PIDM__c, 'Incorrect PIDM control record' );
        System.assertEquals(testOppTBList[0].ProfileStatusOUT__c,'PROS', 'Incorrect profile status(CARE) control record' );
    }
}