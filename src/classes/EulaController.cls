public with sharing class EulaController {
  public String EulaText {get;set;}
  public Decimal Version {get;set;}
  public EulaController() {}
  public void initialize() {
    List<WGUEula__c> eulas = [select Name,EulaText__c,Version__c
      from WGUEula__c];
    if(eulas.size() > 0) {
      EulaText = eulas.get(0).EulaText__c;
    } else {
      EulaText = 'Eula not found';
    }
  }
}