/*
* Author Katarina Melki
* Western Governors University
*
* Created 01/28/2013
*
* Utility class for Mentor objects
*/
public class MentorUtility
{
    /* 
    * We want to auotmatically update the StudentMentor Account with the user from the pidm
    * So get the Account associated with the pidm and insert this into the lookup for the student
    * mentor object.
    */
    public static void mapUserPidm(List<Mentor__c> triggernew)
    {
        Map<String,ID> pidmMap = new Map<String,Id>();
    
        Set<String> mentorPidmList = new Set<String>();
        
        for(Mentor__c sm : triggernew)
        {
            mentorPidmList.add(sm.pidm__c);
        }
        
        if(!mentorPidmList.isEmpty())
        {
            List<User> uList = [SELECT Id, pidm__c from User where pidm__c in :mentorPidmList];
            
            for( User u : uList){
                pidmMap.put(u.pidm__c, u.id);
            }
        }

        for(Mentor__c m : triggernew)
        {
            m.User__c = pidmMap.get(m.pidm__c);
        }
    }
}