@isTest
private class TestCustomMentorLookupController{

static testMethod void CustomMentorLookUpTest(){   
    Profile prof = [SELECT id from Profile where name = 'LockDown'];
    List<User> users = new List<user>();
    User user1 = new User(LastName='Mentor',FirstName='Standard',pidm__c='123123',Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
    , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=prof.id, LanguageLocaleKey='en_US');
    users.add(user1);
    User user2 = new User(LastName='Mentor',FirstName='State',pidm__c='123124',Username='b@wgu.edu', Email='b@wgu.edu', Alias='b', CommunityNickname='b', TimeZoneSidKey='GMT'
    , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=prof.id, LanguageLocaleKey='en_US');
    users.add(user2);
    User user3 = new User(LastName='Mentor',FirstName='Starter',pidm__c='123125',Username='c@wgu.edu', Email='c@wgu.edu', Alias='c', CommunityNickname='c', TimeZoneSidKey='GMT'
    , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=prof.id, LanguageLocaleKey='en_US');
    users.add(user3);
    User user4 = new User(LastName='Mentor',FirstName='Concentrated',pidm__c='123126',Username='d@wgu.edu', Email='d@wgu.edu', Alias='d', CommunityNickname='d', TimeZoneSidKey='GMT'
    , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=prof.id, LanguageLocaleKey='en_US',state='IN');
    users.add(user4);
    insert users;
    List<Mentor__c> mentors = new List<Mentor__c>();
    Mentor__c mentor1 = new Mentor__c(mentorRole__c='Student Mentor',pidm__c=user1.pidm__c,studentcapacity__c=80,monthlyprojection__c=1,priority1programcodes__c='BSITNW;BSIT',programcodes__c='BSITND;BSITSF');
    Mentor__c mentor2 = new Mentor__c(mentorRole__c='Student Mentor (Concentrated)',pidm__c=user2.pidm__c,studentcapacity__c=80,monthlyprojection__c=0,priority1programcodes__c='BSAC',programcodes__c='BSITND;BSITSF');
    Mentor__c mentor3 = new Mentor__c(mentorRole__c='Student Mentor (Starter)',pidm__c=user3.pidm__c,studentcapacity__c=80,monthlyprojection__c=0,priority1programcodes__c='BSPRN',programcodes__c='BSITND;BSITSF');
    Mentor__c mentor4 = new Mentor__c(mentorRole__c='Student Mentor',pidm__c=user4.pidm__c,studentcapacity__c=80,monthlyprojection__c=0,priority1programcodes__c='BSIT',programcodes__c='BAECE;BSITSF');
    mentors.add(mentor1);
    mentors.add(mentor2);
    mentors.add(mentor3);
    mentors.add(mentor4);
    insert mentors;
    CustomMentorLookUpController controller = new CustomMentorLookUpController();
    PageReference pageRef = new PageReference('/apex/CustomMentorLookup?txt=j_id0%3AmyForm%3Aj_id46%3Aj_id47%3A0%3AMentor__c1&frm=j_id0%3AmyForm&lksearch=&lksrch=');
    test.setCurrentPage(pageRef);
    controller.searchString = 'BSITNW';
    controller.search();
    System.assert(controller.results != null);
    controller.getFormTag();
    System.assertEquals(controller.getFormTag(),pageRef.getParameters().get('frm'));
    controller.getTextBox();
    System.assertEquals(controller.getTextBox(),pageRef.getParameters().get('txt'));
}
}