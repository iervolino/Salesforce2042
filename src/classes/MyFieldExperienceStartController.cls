/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Revised Oct 30 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 * 
 * Manages display of MyFieldExperienceStartPage
 *
 */
public with sharing class MyFieldExperienceStartController {

   public String getUserProfilePage() {
     String profileName = [SELECT NAME from Profile where ID = :UserInfo.getProfileId()].Name;
     if ( profileName == 'Mentor' || profileName == 'Mentor Manger') {
       return '/apex/FEMentorList';
     } else if ( profileName == 'Field Experiences User' || profileName == 'System Administrator' || profileName == 'Developer'  ) {
       return '/apex/MyFieldExperience';
     } else if (  profileName == 'Student Profile' ) {
       return '';
     } else {
       return '';
     }
   }
}