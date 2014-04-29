public class NewStudentMentorController {

    public User acct;
    
    // The extension constructor initializes the private member 
    
    // variable acct by using the getRecord method from the standard 
    
    // controller. 
    
    public NewStudentMentorController(ApexPages.StandardController stdController) {
        this.acct = (User)stdController.getRecord();
    }

public Id uid = System.currentPageReference().getParameters().get('id');

private User currentUser = new User(id = uid);

public Mentor__c studentMentor {
   get {
     if (studentMentor == null)
       studentMentor = new Mentor__c(user__c = currentUser.id,pidm__c = acct.pidm__c);       
     return studentMentor;
   }
   set;
  }
  
//inserts the note  
public PageReference saveStudentMentor() {
  try {
      insert studentMentor;
      }
  catch (DMLException e)
      {
      System.debug('Student Mentor already exists');
      }
  return null;
}



static testMethod void testNewStudentMentorController() {
    Profile prof = [SELECT id from profile where name = 'Lockdown'];
    User user1 = new User(LastName='Mentor',FirstName='Standard',pidm__c='123123',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
    , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=prof.id, LanguageLocaleKey='en_US');
    insert user1;
    ApexPages.StandardController con = new ApexPages.StandardController(user1);
    NewStudentMentorController controller = new NewStudentMentorController(con);
    controller.studentMentor = new Mentor__c(user__c = controller.currentUser.id,pidm__c = controller.acct.pidm__c,studentCapacity__c = 12);
    controller.saveStudentMentor();
    Mentor__c savedMentor = [SELECT id,user__c from Mentor__c where id = :controller.studentMentor.id];
    System.assertEquals(savedMentor.user__c,controller.acct.id);
}

}