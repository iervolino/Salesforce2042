public with sharing class FDPStateAndLicensure {
  Map<String,Set<WGUStateLicensure__c>> statemaps;
  Contact student;
  public FDPStateAndLicensure(Contact s) {
    student = s;
  }
  Public Map<String,Set<WGUStateLicensure__c>> getStateLicensureMap(){
    if(this.statemaps==null){
      Set<String> states=new Set<String>();
      this.statemaps = new Map<String,Set<WGUStateLicensure__c>>();
      List <WGULicenseRequirement__c> lis = [select Id,
        WGUStateLicensure__r.Name,
        WGUStateLicensure__r.State__c,
        WGUStateLicensure__r.Id,
        Program__c
        from WGULicenseRequirement__c
        where Program__c = :student.WGUDegreeProgram__r.Name];
      for (WGULicenseRequirement__c li:lis){
        states.add(li.WGUStateLicensure__r.State__c);
        Set<WGUStateLicensure__c> licensures=statemaps.get(li.WGUStateLicensure__r.State__c);
        if(licensures==null) {
          licensures=new Set<WGUStateLicensure__c>();
          this.statemaps.put(li.WGUStateLicensure__r.State__c,licensures);
        }
        licensures.add(li.WGUStateLicensure__r);
      }
    }
    return statemaps;
  }
  public boolean needLicensure() {
    List<StudentLicenseHistory__c> lis = [select Id
      from StudentLicenseHistory__c
      where Student__c = :student.Id];
    if(lis.size() > 0)
      return false;
    return this.getStateLicensureMap().keyset().size() > 0;
  }
}