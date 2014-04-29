@IsTest
public class TestCreateUserFromContactWebservice{
    
    @IsTest public static void testUserCreation() {    
        String pidm = '0';
        createContactForTest(pidm);
        
      	User testUser = TestStudentUser.getSAdminUser();
    	System.RunAs( testUser ) {   
            Test.startTest();
                
            CreateUserFromContactWebservice cufcw = new CreateUserFromContactWebservice();
            String returnPidm = cufcw.createUserFromContact(pidm);
                            
            Test.stopTest(); 
            
         	List<User> result = [SELECT Id FROM User WHERE PIDM__c = :pidm];
            System.assertEquals(1, result.size());
        }
    }  
    
    @IsTest(SeeAllData=true) public static void userAlreadyExistsTest() {    
        User user = [SELECT id, pidm__c FROM User WHERE IsActive = true AND Profile.name = 'Student Profile' LIMIT 1];
        
      	User testUser = TestStudentUser.getSAdminUser();
    	System.RunAs( testUser ) {   
            Test.startTest();
                
            CreateUserFromContactWebservice cufcw = new CreateUserFromContactWebservice();
            String returnPidm = cufcw.createUserFromContact(user.pidm__c);
                            
            Test.stopTest();
            System.assertEquals('Exists', returnPidm);
        }
    }  
    
    private static void createContactForTest(String pidm) {
        Account acc = new Account();
        acc.name = 'Test Account';
        insert acc;
        
        Contact student = new Contact();
        student.accountId = acc.id;
        student.LastName='test1';
        student.FirstName='test1';
        student.Salutation='test1';
        student.MailingStreet='test1'; 
        student.MailingCity='test1';
        student.MailingState='test1';  
        student.MailingPostalCode='11111';  
        student.MailingCountry = 'UD';
        student.Phone='test1';  
        student.Fax='test1';  
        student.MobilePhone='test1'; 
        student.HomePhone='test1'; 
        student.OtherPhone='test1';  
        student.Email='test1@kf.com'; 
        student.Title='test1'; 
        student.BannerStatus__c='AS';  
        student.CurrentTerm__c='test1';  
        student.Gender__c='test1';
        student.PIDM__c=pidm;  
        student.Status__c='test1'; 
        student.StudentID__c = '21457';
        Student.OtherEmail__c='test1@tesky.com'; 
        student.My_WGU_Email__c='test1@bnleh.com';
        student.DateOfBirth__c ='1111';
        student.InternationalPhone__c='test1'; 
        student.PhoneExtension__c='test1'; 
        student.Suffix__c='test1'; 
        student.middleInitial__c='t'; 
        student.WGUEmail__c='test1@wgu.edu'; 
        student.timezone__c='GMT'; 
        student.Username__c = 'test1';  
        insert student;
    }
    
}