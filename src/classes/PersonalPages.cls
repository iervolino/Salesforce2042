public class PersonalPages{
 
public static void generateIdentifier(Id profileId, String contactId) {

    //SOQL for contact name
    Contact contact = [SELECT FirstName, LastName FROM Contact WHERE Id =:contactId];
    
    String name = contact.FirstName + '' + contact.LastName; 
    name = name.toLowerCase();
    name = name.replaceAll('[^a-z]+', '');
    
    System.debug(contactId);
    System.debug(contactId.length());
    String lastFour = (contactId.length() >= 7)? contactId.substring(contactId.length() - 7, contactId.length()-3): contactId ;
    String identifier = name + lastFour ;
    
    
     //Replaced by above as we have chosen a diffrent unique id string. 
    /*  // Get current Date
    Date currentDate = date.today();
    
    
    
    // Check contact for null
    
    String identifier = generateIdentifierWithDate(profileId, contact.FirstName, contact.LastName, currentDate);
    
    */
    
    
    
    // Set Identifier for the Opportunity
    Opportunity profile = New Opportunity(id = profileId, PersonalPageIdentifier__c = identifier);
    
    // Save change
    update profile;
}


/*  Replaced by above as we have chosen a diffrent unique id string.  

private static String generateIdentifierWithDate(String profileId, String firstName, String lastName, Datetime createdDate) {
List<String> dateParts = String.valueOf(createdDate).split('-', 0);

String identifierStub = firstName.toLowerCase() + lastName.toLowerCase() + '-' + dateParts[1] + dateParts[0].right(2) + '-'; 
String queryLikeStub = identifierStub + '%';

// Get list of records
List<Opportunity> records = [SELECT PersonalPageIdentifier__c 
                 FROM Opportunity 
                 WHERE PersonalPageIdentifier__c LIKE :queryLikeStub];

// Get the next sequence number (default to 1)
Integer sequenceNumber = 1;

// Search for correct sequence number
for (Opportunity record : records) {
// Determine sequence number of record
Integer recordSequenceNumber = Integer.valueOf(record.PersonalPageIdentifier__c.substring(record.PersonalPageIdentifier__c.lastIndexOf('-') + 1));

// Does this record have a sequence number larger or equal to 
// the one we are trying to apply to the new record 
if (recordSequenceNumber >= sequenceNumber) {
// Set sequence number to be next number in sequence
sequenceNumber = recordSequenceNumber + 1;
}
}

return identifierStub + String.valueOf(sequenceNumber);
}
*/
/*

    @RemoteAction
    public static String identifierDataGather(String identifierURL)
    {
        
        if (identifierURL == null)
        {
            return null;
        }
        String errorMessage = 'none';
        Map<String,Object>  returnMap  = new Map<String,Object>();
        
        String identifier = identifierURL.substringAfterLast('/');
        if (identifier  == null || identifier.length() < 1)
        {
            return null;
        }
        
        List<Opportunity> profiles = [Select id, NameAndPhone__c,
                               ContactLastName__c,
                               MarketingProgram__r.Name,
                               Owner.name, StudentAttributes__r.Affiliation__c
                               from Opportunity 
                               where PersonalPageIdentifier__c = :identifier];
                               
        if (profiles.size() < 1)
        {
            errorMessage = 'Student Not Found';
            returnMap.put('errorMessage',errorMessage);   
            return  Json.serialize(returnMap);                 
        }
        
        
        Opportunity profile = profiles.get(0);
        
        System.debug('Profile: ' + profile);
        System.debug('Afil: ' + profile.StudentAttributes__r.Affiliation__c);
        String ecName = profile.Owner.name;
        String programName = profile.MarketingProgram__r.name;
        String affiliation = profile.StudentAttributes__r.Affiliation__c;
        
        List<Personal_Pages_Link__c> pplc = [Select id, affiliation__c, active__c,
                                             sort_order__c, image__c, link__c,
                                             Program__c
                                             from Personal_Pages_Link__c
                                             where active__C = true
                                             and affiliation__c = :affiliation
                                             order by sort_order__c];                                       
        System.debug('HERE0' + pplc);
        
   
        
        List<Personal_Pages_Link__c> personalPagesLinks = new List<Personal_Pages_Link__c>();
            
            
        
        for (Personal_Pages_Link__c pagelink : pplc )
        {
            System.debug('HERE1' + pagelink );
            if (pagelink.Program__c != null)
            {
                 List<String> programsLinks = pagelink.Program__c.split(';'); 
                 
                 for (String program : programsLinks )
                 {
                     if (program.equalsIgnoreCase(programName))
                     {
                        personalPagesLinks.add(pagelink);
                        break;
                     } 
                 }
            }

                  
       }
       

        
        returnMap.put('firstName', profile.NameAndPhone__c);
        returnMap.put('lastName', profile.ContactLastName__c);
        returnMap.put('ecName', ecName);
        returnMap.put('programName', programName);
        returnMap.put('personalPagesLinks', personalPagesLinks);
        returnMap.put('identifier', identifier);
        returnMap.put('errorMessage',errorMessage);
        
       // System.debug(returnMap);
        
        String jsonReturnMap = Json.serialize(returnMap);
        
      //  System.debug(jsonReturnMap);
        return jsonReturnMap;
        
        
    }

*/
    
}