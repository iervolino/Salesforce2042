@IsTest
private with sharing class TestFDPStateAndLicensure {
    
    private static testMethod void testgetStates(){
    
          SetupFDPDevelopmentBox.refreshAllData();
          Contact c = [Select id,
            WGUDegreeProgram__r.Name
            from Contact
            where PIDM__c = '11' LIMIT 1];
      
      //User testUser = [Select id from User where profile.Name = 'Mentor' AND isActive=true];     
      Test.startTest();
      //System.runAs(testUser) {      
            
        FDPStateAndLicensure fsl = new FDPStateAndLicensure(c);
        fsl.getStateLicensureMap().get('UT');
        //System.Assert?
        
      //}
      Test.stopTest();
        
    }

}