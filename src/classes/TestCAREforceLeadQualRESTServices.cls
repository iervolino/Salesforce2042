@isTest
public class TestCAREforceLeadQualRESTServices {

   @IsTest
    public static void addTask() {
    
    
    
    List<ExternalLeadContactControl__c> elist = new List<ExternalLeadContactControl__c>();
    
    String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '20';
        
        
        elist.add(wguELCC);
        
        
        ExternalLeadContactControl__c notwguELCC= new ExternalLeadContactControl__c();
        notwguELCC.Name= 'LeadQual';
        notwguELCC.Active__C = true;
        notwguELCC.MonthlyLimit__c = 1000;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '30';
    
        elist.add(notwguELCC);
        
     
   

        insert elist;
        

        
        
        Id recid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;
        Id rec2id = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id; 
        
     
        
        String supper = letters.substring(1,2);
        String slower = supper.toLowerCase();
        Contact contact2 = new Contact(firstName=supper + 'inky', lastName = 'OT' + slower + 'ster', email= supper + 'inkyOTester' + slower + '@yahoo.com',  pidm__C = '1233210'  );
        contact2.recordtypeid = recid;
    

        
        
        
     //   System.debug(myContacts);
        
        insert contact2;
         

         
        List<Account> myAccounts =  [Select id, pidm__C from Account];
         
        List<Opportunity> myCares1 = new List<Opportunity>();

        Opportunity care2 = new Opportunity(AccountId=myAccounts[0].Id, StudentContact__c = contact2.id,  
                                                   Name= contact2.firstName + ' ' + contact2.lastName , 
                                                   CloseDate=date.today(), StageName='Intake', 
                                                  RecordTypeId  = rec2id, ExternalLeadContactControl__c = notwguELCC.id );
        care2.LeadGrade__c = 'B';
               
           insert care2;
          
          
          List<Task> noTasks = [Select id from Task where What.id = :care2.id];
           
          System.assert(noTasks.size() == 0);


          CAREforceLeadQualRESTServices.leadQual((String)care2.id, 'Live Call- AR Live Transfer', '', 'This is my note',
                                               DateTime.now().format(), 'No', 'No'); 
        
          CAREforceLeadQualRESTServices.leadQual((String)care2.id, 'No Follow Up- Not Interested', '', 'This is my note',
                                               DateTime.now().format(), 'Yes', 'Yes');
                                               
          Opportunity care = [Select id, StopPhoneCalls__c, StopEmails__c from Opportunity where id = :care2.id];
          
          List<Task> Tasks = [Select id from Task where What.id = :care2.id];
    
          System.assert(Tasks.size() == 2); 
          
          System.assert(care.StopPhoneCalls__c == true);   
          System.assert(care.StopEmails__c == true);                                 
                                                
    }
}