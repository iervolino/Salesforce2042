/****************************************************
* Utility class to automate creation of Mentor Users
*****************************************************/

public with sharing class CreateMentorUser
{
    /********************************************************************************************************************
    * Given a comma delimited string of PIDM's this function will set the User Role, Profile, UserPermissionSupportUser,
    * and Permission Sets appropriately for a mentor user. A Mentor object will be created for each Mentor as well.
    *********************************************************************************************************************/
    public static void createMentors(String pidmString)
    {
        //Create a Set of PIDM's from the input string
        Set<String> mentorPidms = new Set<String>(pidmString.split(','));
        Map<ID, String> pidmMap = new Map<ID, String>();
        
        //Retrieve Permission Sets and create a PermissionSetAssignment list
        List<PermissionSet> mentorPS = [select ID from PermissionSet where Name in ('WGUStudentNote','WGUInternalUser','MentorForce','RecordsForMentors','ServiceDesk_Client','ServiceDeskClientExtra')];
        List<PermissionSetAssignment> psAssignment = new List<PermissionSetAssignment>();        
        
        //Retrieve the Mentor Role and Profile ID's
        Profile mentorProfile = [select ID from Profile where Name='Mentor'];
        UserRole mentorRole = [select ID from UserRole where Name='Mentor'];
        
        //Retrieve the mentor User objects for the provided PIDM's
        List<User> mentorUsers = [select ID, PIDM__c from User where PIDM__c in :mentorPidms];
        
        for (User mentorUser :mentorUsers)
        {
            //Set User values
            mentorUser.ProfileID = mentorProfile.ID;
            mentorUser.UserRoleID = mentorRole.ID;
            mentorUser.UserPermissionsSupportUser = true;
            mentorUser.UserPermissionsInteractionUser = true;
            
            //Add Permission Sets
            for (PermissionSet ps :mentorPS)
            {
                psAssignment.add(new PermissionSetAssignment(AssigneeId = mentorUser.ID, PermissionSetId = ps.ID));
            }
            
            //Populate pidmMap to use for creating Mentor objects
            pidmMap.put(mentorUser.ID, mentorUser.PIDM__c);
        }
        
        //Perform inserts and updates        
        update mentorUsers;
        
        Database.Insert(psAssignment, false);
        
        //Call the insertMentorObject function with the pidmMap
        insertMentorObject(pidmMap);
    }
    
    //Function creates Mentor objects using the provided PIDM/ID map.
    //Runs @future to provide a different run context to avoid mixed DML errors.
    @future
    private static void insertMentorObject(Map<ID, String> mentorPidms)
    {
        //Retrieve the mentor User objects for the provided PIDM's
        Set<ID> mentorIDs = mentorPidms.keySet();
        
        //Create a list of Mentor objects to be inserted
        List<Mentor__c> mentorObjects = new List<Mentor__c>();
        
        //Get Chatter groups and create list for Chatter group assignments
        List<CollaborationGroup> chatterGroups = [select id from collaborationgroup where name in ('MentorForce Discussions','Mentoring')];
        List<CollaborationGroupMember> chatterGroupAssign = new List<CollaborationGroupMember>();
        
        //Get Public Groups and create list for Public Group assignments
        List<Group> publicGroups=[select Id from Group where Name in ('Mentors')];
        List<GroupMember> publicGroupAssign=new List<GroupMember>();
        
        for (ID mentorID :mentorIDs)
        {
            //Create temp Mentor object with required values and add to mentorObjects list
            mentorObjects.add(new Mentor__c(User__c = mentorID, PIDM__c = mentorPidms.get(mentorID)));
            
            //Add mentor to Chatter groups
            for (CollaborationGroup chatterGroup :chatterGroups)
            {
                chatterGroupAssign.add(new CollaborationGroupMember(MemberId=mentorID, CollaborationGroupId=chatterGroup.ID));
            }
            
            //Add mentor to Public Groups
            for (Group publicGroup :publicGroups)
            {
                publicGroupAssign.add(new GroupMember(UserOrGroupId=mentorID, GroupId=publicGroup.Id));
            }
        }
        
        if (Test.isRunningTest())
        {
            System.runAs(new User(Id = Userinfo.getUserId()))
            {
                Database.Insert(mentorObjects, false);
                Database.insert(chatterGroupAssign, false);
                Database.insert(publicGroupAssign, false);
            }
        }
        else
        {
            Database.Insert(mentorObjects, false);
            Database.insert(chatterGroupAssign, false);
            Database.insert(publicGroupAssign, false);
        }
    }
}