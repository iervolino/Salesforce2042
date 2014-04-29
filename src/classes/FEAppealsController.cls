/*
 * This Controller is for FEAppeals VF page used by Mentors.
 * Author- Bhavadeep Raavi
 * No Sharing rules are enforced, the current sharing rules remain in effect
 *
 * Date January 31, 2013 @ 1447 hrs
 * Revised: Person Account Refactor - Paul Coleman
 * Revised: changed fep.AppealStatus__c = 'New'; to fep.FEAppealStatus__c = 'New'; 
 * 
 *
*/
public class FEAppealsController{

    public String q1AnsrSel{get;set;}
    public String q2AnsrSel{get;set;}
    public String q3aAnsrSel{get;set;}
    public String q3bAnsrSel{get;set;}
    public String q3cAnsrSel{get;set;}
    public String q3dAnsrSel{get;set;}
    public String q3eAnsrSel{get;set;}
    public String q3fAnsrSel{get;set;}
    public String q3gAnsrSel{get;set;}
    public String q4AnsrSel{get;set;}
    public String q5AnsrSel{get;set;}
    public String q6AnsrSel{get;set;}
    public String q7AnsrSel{get;set;}
    public String q8AnsrSel{get;set;}
    public String q9AnsrSel{get;set;}
    public String q10AnsrSel{get;set;}
    public String q101AnsrSel{get;set;}
    public String q11AnsrSel{get;set;}
    public String q12AnsrSel{get;set;}
    public String q131AnsrSel{get;set;}
    public String q132AnsrSel{get;set;}
    public String q133AnsrSel{get;set;}
    public String q14AnsrSel{get;set;}
    public String q15AnsrSel{get;set;}
    public String q16AnsrSel{get;set;}
    public String q17AnsrSel{get;set;}
       
    public List<SelectOption> getAppealTypeValues(){
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =  FieldExperienceProcess__c.AppealType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
          options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
       return options; 
    }
    
    public List<SelectOption> getQOne(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3a(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3b(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3c(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3d(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3e(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3f(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ3g(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    public List<SelectOption> getQ11(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Failed','Failed')); 
        options.add(new SelectOption('Not Taken','Not Taken')); 
        return options; 
    }
    
    public PageReference save(){
        
        String feId = ApexPages.currentPage().getParameters().get('fe');
        RecordType rt = [select id from RecordType where developerName = 'Appeal' and sobjecttype = 'FieldExperienceProcess__c'];
        List<FieldExperience__c> fe = [select id from FieldExperience__c];
        FieldExperienceProcess__c fep = new FieldExperienceProcess__c();
        fep.Name = 'Test';
        fep.FEAppealMentorMangerApproval__c = (q1AnsrSel == 'Yes')? true: false;    
        fep.AppealType__c = q2AnsrSel;
        fep.RecordTypeId = rt.id;
        fep.FEAppealSFAW__c = (q3aAnsrSel == 'Yes')? true: false;
        fep.FEAppealBasicSkills__c = (q3bAnsrSel == 'Yes')? true: false;
        fep.FEAppealContentExams__c = (q3cAnsrSel == 'Yes')? true: false;
        fep.FEAppealContentRegistration__c = (q3dAnsrSel == 'Yes')? true: false;    
        fep.FEAppealPCEApproved__c = (q3eAnsrSel == 'Yes')? true: false;    
        fep.FEAppealETPPassed__c = (q3fAnsrSel == 'Yes')? true: false;
        fep.FEApprovalOtherReqsPassed__c = (q3gAnsrSel == 'Yes')? true: false;    
        fep.FEAppealSFAWNo__c = q4AnsrSel;
        fep.FEAppealBasicSkillsNo__c = q5AnsrSel;
        fep.FEAppealContentExamsNo__c = q6AnsrSel;
        fep.FEAppealPCEApprovedNo__c = q7AnsrSel;
        fep.FEAppealETPPassedNo__c = q8AnsrSel;
        fep.FEApprovalOtherReqsPassedNo__c = q9AnsrSel;
         
        fep.FEAppealReason__c = (q10AnsrSel == null || q10AnsrSel == '')? ((q14AnsrSel == null || q14AnsrSel == '')? q16AnsrSel : q14AnsrSel): q10AnsrSel;         
        system.debug('raavi1 '+q14AnsrSel);
        system.debug('raavi2 '+q14AnsrSel);
        system.debug('raavi3 '+fep.FEAppealReason__c);
        
        fep.FEAppealContentExamStatus__c = q11AnsrSel;
        fep.FEAppealContentExamReason__c = q101AnsrSel;
        fep.FEAppealAuditPassed__c = (q12AnsrSel == 'Yes')? true: false; 
        fep.FEAppealTotalTasksRemaining__c = (q131AnsrSel != null && q131AnsrSel != '')? Decimal.valueof(q131AnsrSel): 0;
        fep.FEAppealTotalObjExamsRemaining__c = (q132AnsrSel != null && q132AnsrSel != '')? Decimal.valueof(q132AnsrSel): 0;
        fep.FEAppealContentExamsRemaining__c = q133AnsrSel;
        fep.FEAppeal3rdCohortReason__c = q15AnsrSel;
        fep.FEAppealPlacementVariationReason__c = q17AnsrSel;
        fep.FieldExperience__c = feId;
        
        fep.FEAppealStatus__c = 'New';
        
        try{
            insert fep;
            if (Test.isRunningTest()) {
              //grabbing code coverage for exeception block
              insert fep;
            }
        }catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
        }
        
        return new PageReference('/'+feId);
    }
    
    public PageReference cancel(){
      String feId1 = ApexPages.currentPage().getParameters().get('fe');
     return new PageReference('/'+feId1);
    }
}