public class RelatedListFEP {

private List<FieldExperienceProcess__c> FEPs;
private FieldExperience__c FE;
public RelatedListFEP(ApexPages.standardController controller) {
    this.FE= (FieldExperience__c)controller.getRecord();
    }
public List<FieldExperienceProcess__c> getFEPs()
    {
        FEPs = [Select Id, Name, Student__c, CheckReadyForEval__c, CheckStatus__c, CheckWorkComplete__c, HostTeacher__c, ClinicalSupervisor__c, CheckTotalAmount__c, CheckFinalObservationOverride__c, ObservationStatus__c, ObservationType__c, ObservationOutcome__c from FieldExperienceProcess__c where RecordType.Name in ('Placement Attempt','Observation','CS Request') and FieldExperience__r.Id = :FE.Id];
        return FEPs;
    }
}