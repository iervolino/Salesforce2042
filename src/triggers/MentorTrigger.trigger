/*
* Author Katarina Melki
* 
* Created 01/28/2013
*
* Trigger for Mentor objects
*/

trigger MentorTrigger on Mentor__c (before insert, before update)
{
    //Call MentorUtility.mapUserPidm function to map the Pidm to a specific User
    MentorUtility.mapUserPidm(Trigger.new);
}