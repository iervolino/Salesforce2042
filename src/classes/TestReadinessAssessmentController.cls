@IsTest
public class TestReadinessAssessmentController {
    @IsTest
    public static void testControllerSetup() {
        Runtime__c c = new Runtime__c();
        c.Name = 'web3_domain';
        c.Value__c = 'unit.test.wgu.edu';
        insert c;
        
        Test.startTest();
            ReadinessAssessmentExtensionController controller = new ReadinessAssessmentExtensionController(null);
        Test.stopTest();
        
        System.assert(controller.actionURL == 'https://unit.test.wgu.edu/care2/AA_Assesment_Details.asp');
    }
}