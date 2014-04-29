/**
 * Created 2013 12 09 by Tyler Smith
 * Meant to house the utility methods and functions for WGU integrations
 */
public class CAREforceIntegrationUtility{
    
    // Modified from ContactToBannerUtilities.processUpdateBannerReady that is called at the same time 
    public static void sendExternalNotificationOnUpdate(String oldJson, String newJson) {
        // Get Updated records
        List<Opportunity> oldValues = (List<Opportunity>)JSON.deserialize(oldJson, List<Opportunity>.class);
        List<Opportunity> newValues = (List<Opportunity>)JSON.deserialize(newJson, List<Opportunity>.class);
        
        // Circle through list
        Opportunity opportunity = null;
        Opportunity oldOpportunity = null;
        for (Integer i = 0; i < newValues.size(); i++) {
            opportunity = newValues[i];           
            oldOpportunity = oldValues[i];
            
            // Datamark Leads that have applied (have posting score id and are moving from PROS to APIN)
            // Created by Datamark Integration User is another possible filter
            //
            // There is a need for training around this. A valid but stuck lead will need to be edited 
            // to match this criteria to be automated (I'm the only person who does this currently, but 
            // need to be aware of this)
            //
            // Also, this process doesn't take a once Datamark lead (only active datamark leads).
            // That means that a lead that datamark sent over 6 months ago that applies will
            // create a new opportunity and not trigger this criteria
            if (opportunity.PostingScoreId__c != null && 
                oldOpportunity.CAREStatusListView__c == 'PROS' && opportunity.CAREStatusListView__c == 'APIN') {
                
                postDatamarkLeadApplied(newJson);
            }
        }
    }

    /**
     * Modified from postDataToURL in CAREforceUtility
     * Probably need to pass additional information to log/attach errors
     */
    @Future(callout=true)
    public static void postDatamarkLeadApplied(String json_opp) {
        List<Opportunity> opportunities = (List<Opportunity>)JSON.deserialize(json_opp, List<Opportunity>.class);
        if (opportunities.size() < 1) {
            return;
        }
        
        Opportunity opportunity = opportunities[0];
    
        // Setup HTTP Request
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setMethod('POST');
        req.setBody('lead_id=' + opportunity.PostingScoreId__c + '&client_code=WES0007&status_code=APPLY');
        
        // Precaution to ensure we don't send to Datamark on tests
        if (!Test.isRunningTest()) {
            // End point has to be added to Salesforce to make call out to it
            req.setEndpoint('http://ulm.datamark.com/public/clients/addstatus');
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            // Successful XML response should be
            // <add_status><result>success</result></add_status>
            // with a 200 response
            
            String message = parseDatamarkResponse(res);
            
            if (!message.equals('success')) {
                // Probably need to pass additional information to log/attach errors
                logError(opportunity, message);
            }
        }
    }
    
    /**
     * What are the possible errors? Try catching errors to ensure we don't create problems.
     */
    public static String parseDatamarkResponse(HTTPResponse res) {
        String message;
        
        // Parse status out of XML document
        Dom.document doc = res.getBodyDocument();
        Dom.XMLNode addStatus = doc.getRootElement();
        message = addStatus.getChildElement('result', null).getText();
        
        // If success, return that
        if (message.equalsIgnoreCase('success')) {
            return message;
        }
        
        message = '';
        
        // Ensure that we have what we expect
        Dom.XMLNode errors = addStatus.getChildElement('errors', null);
        if (errors != null) {
            for (Dom.XMLNode error : errors.getChildElements()) {
                message += error.getText() + ', ';
            }
            message = message.substringBeforeLast(',');
        }
        
        // Otherwise, return whole response
        return message;
    }
    
    /**
     * Might need to pass additional information along to make attachments
     */
    public static void logError(Opportunity opportunity, String message) {
        opportunity.Lead_Provider_Response_Error__c = message;
        update opportunity;
    }
}