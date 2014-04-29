@isTest
private class TestAttachmentTrigger
{
    /**
    * Verify that Standard User profiles are unable to delete attachments
    */
    static testMethod void testStandardUser() 
    {
        
        // Create a new user with the Standard User profile
        Profile standardProf = [select id from profile where name='Standard User']; 
        User su = new User(alias = 'stand85', email='standarduser4568@testorg.com.wgu.edu', 
            emailencodingkey='UTF-8', lastname='Tes25ting846', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = standardProf.Id, 
            timezonesidkey='America/Los_Angeles', username='standarduser7844@testorg.com');
            
        // Switch current user to Standard User
        System.runAs(su) 
        {      
        
            // Create test data (a new Account with an Attachment)
            Account acct = new Account(Name = 'Test Account758',Type='Prospect', Phone = '504 555-1212',
            BillingStreet = '123 any st', BillingCity = 'Cinn', BillingState = 'NJ',
            BillingPostalCode = '08077');
            insert acct;
            Blob attachBody = Blob.valueOf('attachment body');
            Attachment attach = new Attachment(Name = 'SavedTransferEvaluation.pdf', ParentId = acct.Id, Body = attachBody);
            insert attach;
        
            // Verify the "Unable to delete attachments" error is thrown when attachment is deleted
            Boolean errorThrown = false; 
            try 
            {
                delete attach;
            } 
            catch (Exception e) 
            {
                System.debug(e);
                if (e.getMessage().contains('You do not have permission to delete attachments.')) 
                {
                    errorThrown = true;
                }
            }
            System.assert(errorThrown);
        }
    }
    
    static testMethod void testAdminUser() 
    {
        
        // Next make sure that a System Admin *can* delete an attachment
        Profile adminProf = [select id from profile where name='System Administrator']; 
        User au = new User(alias = 'admin723', email='adminuser@testorg.com.wgu.edu', 
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = adminProf.Id, 
            timezonesidkey='America/Los_Angeles', username='adminuser834@testorg.com');
        
        // Switch current user to System Admin user
        System.runAs(au) 
        {            
            // Create test data (a new Account with an Attachment)
            Account acct = new Account(Name = 'Test Accoun8614',Type='Prospect', Phone='1234567899',
                                 BillingStreet = '123 any st', BillingCity = 'Cinn', BillingState = 'NJ', BillingPostalCode = '08077');
            insert acct;
            Blob attachBody = Blob.valueOf('attachment body');
            Attachment attach = new Attachment(Name = 'SavedTransferEvaluation.pdf', ParentId = acct.Id, Body = attachBody);
            insert attach;
            
            // Verify that no error is thrown when the attachment is deleted
            Boolean errorThrown = false;
            try 
            {
                delete attach;
            } 
            catch (Exception e) 
            {
                System.debug(e);
                errorThrown = true;
            }
            System.assert(!errorThrown);
        }
    }
}