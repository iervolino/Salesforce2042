@IsTest
public class TestCAREforceIntegrationUtility{

    @IsTest
        public static void testDatamarkOpportunityUpdate() {
            // Create Datamark Opportunity (has PostingScoreId__c which is DatamarkId)
            Opportunity opportunity = New Opportunity(name = 'Test', StageName = 'Prospect', CloseDate = date.parse('12/01/2100'), CareStatus__c = 'PROS – Prospect', PostingScoreId__c = '123456');
            insert opportunity;
            
            Test.startTest();
            opportunity.CareStatus__c = 'APIN – Application Incomplete APCO';
            update opportunity;
            Test.stopTest();
            
            // As nothing happens until after the return response and we can't mock that piece,
            // we don't have anything to assert other than it not throwing errors when it runs.
        }

    @IsTest
        public static void testParseGoodResponse() {
            // Test timing out trying to parse the response
        
            HTTPResponse response = New HTTPResponse();
            response.setStatusCode(200);
            response.setStatus('HTTP/1.1 200 OK');
            response.setHeader('Content-Length', '53');
            response.setHeader('Connection', 'close');
            response.setHeader('Content-Type', 'text/xml');
            response.setBody('<add_status><result>success</result></add_status>');
            
            String message = CareforceIntegrationUtility.parseDatamarkResponse(response);
            
            System.assertEquals('success', message, 'Unexpected message');
        }
        
    @IsTest
        public static void testParseFailResponse() {
            // Test timing out trying to parse the response
        
            HTTPResponse response = New HTTPResponse();
            response.setStatusCode(200);
            response.setStatus('HTTP/1.1 200 OK');
            response.setHeader('Content-Length', '139');
            response.setHeader('Connection', 'close');
            response.setHeader('Content-Type', 'text/xml');
            response.setBody('<add_status><result>fail</result><errors><error>Missing client_code</error><error>Invalid lead_id</error></errors></add_status>');
            
            String message = CareforceIntegrationUtility.parseDatamarkResponse(response);
            
            System.assertEquals('Missing client_code, Invalid lead_id', message, 'Unexpected message');
        }
        
    @IsTest
        public static void testLogError() {
            //
            String error_message = 'Error saving';
        
            // Create Datamark Opportunity (has PostingScoreId__c which is DatamarkId)
            Opportunity opportunity = New Opportunity(name = 'Test', StageName = 'Prospect', CloseDate = date.parse('12/01/2100'), CareStatus__c = 'PROS – Prospect', PostingScoreId__c = '123456');
            insert opportunity;
            
            CareforceIntegrationUtility.logError(opportunity, error_message);
            
            List<Opportunity> opportunities = [SELECT Lead_Provider_Response_Error__c FROM Opportunity WHERE name = 'Test' AND PostingScoreId__c = '123456' LIMIT 1];
            
            if (opportunities.size() < 1) {
                System.assert(false, 'No Opportunity to test against');
            } 
            else {
                System.assertEquals(error_message, opportunities[0].Lead_Provider_Response_Error__c, 'Unexpected error message');
            }
        }
}