@RestResource(urlMapping='/CreateUserFromContactWebservice')
global with sharing class CreateUserFromContactWebservice{
    
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String pidm = req.headers.get('pidm');
        CreateUserFromContactWebservice w = new CreateUserFromContactWebservice();
        return w.createUserFromContact(pidm);
    }
    
    public String createUserFromContact(String pidm) {
        List<User> u = [Select id, pidm__C from user where pidm__c = :pidm];
        if(u.isEmpty()) {
            List<Contact> c = [SELECT Id, IsDeleted, MasterRecordId, AccountId,
                               LastName, FirstName, Salutation, Name, RecordTypeId, 
                               MailingStreet, MailingCity, MailingState, 
                               MailingPostalCode, MailingCountry,
                               MailingLatitude, MailingLongitude,
                               Phone, Fax, MobilePhone, 
                               HomePhone, OtherPhone, AssistantPhone,
                               Email, Title,   BannerStatus__c,  CurrentTerm__c, 
                               Gender__c,  PIDM__c, Status__c, StudentID__c,
                               OtherEmail__c,  My_WGU_Email__c, DateOfBirth__c,
                               InternationalPhone__c, PhoneExtension__c,  
                               Suffix__c, middleInitial__c,  WGUEmail__c, 
                               Timezone__c,  IsTestData__c,  Username__c FROM Contact 
                               where PIDM__C = :pidm];
            
            
            User ureturn = ContactUtility.createStudentUser(c.get(0), null, null, null);
            insert ureturn;    
            return ureturn.id;
        }
        return 'Exists';
    }

}