@IsTest
private class TestCreateMentorUser
{
    //Tests the Mentor User creation
    static testmethod void testMentorCreate()
    {
        //Create and add test users
        Profile prof = [SELECT id from profile where name = 'Lockdown'];
        Profile mentorProfile = [select ID from Profile where Name='Mentor'];
        UserRole mentorRole = [select ID from UserRole where Name='Mentor'];
        
        List<User> testUsers = new List<User>();
        testUsers.add(new User(LastName='Mentor', FirstName='Standard', pidm__c='123123', Username='a@wgu.edu', Email='a@wgu.edu', Alias='a', CommunityNickname='a', TimeZoneSidKey='GMT'
            , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', ProfileId=prof.ID, LanguageLocaleKey='en_US'));
        testUsers.add(new User(LastName='Mentor', FirstName='Test', pidm__c='123456', Username='b@wgu.edu', Email='b@wgu.edu', Alias='b', CommunityNickname='b', TimeZoneSidKey='GMT'
            , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', ProfileId=prof.ID, LanguageLocaleKey='en_US'));
        insert testUsers;
        
        Test.startTest();
        try
        {
            CreateMentorUser.createMentors('123123,123456');
        }
        catch (Exception e)
        {
            System.debug(e);
        }
        Test.stopTest();
        
        User userTest1 = [select ID, PIDM__c, ProfileID, UserRoleID, UserPermissionsSupportUser, UserPermissionsInteractionUser from User where PIDM__c='123123'];
        
        system.assert(userTest1.PIDM__c=='123123');
        system.assert(userTest1.ProfileID==mentorProfile.ID);
        //system.assert(userTest1.ProfileID==prof.ID);
        system.assert(userTest1.UserRoleID==mentorRole.ID);
        system.assert(userTest1.UserPermissionsSupportUser==true);
        system.assert(userTest1.UserPermissionsInteractionUser==true);
        
        system.assert([select PIDM__c from Mentor__c where PIDM__c='123456'][0].PIDM__c=='123456');
        system.assert([select ID from PermissionSetAssignment where AssigneeId=:userTest1.ID].size()!=0);
    }
}