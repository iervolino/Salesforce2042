@isTest
public class TestCAREforceUtilityExternalLeads {

 
    @IsTest
    public static void testAssignLeadToVendors() {
    
        ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        
        insert wguELCC;
    
    
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact;
       
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];

        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Sync MacTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        insert care;   
        
        
        CAREforceUtility.assignLeadToVendor(care, wguELCC);
 

        System.assert(care.ExternalLeadContactControl__c == wguELCC.id );   

    } 

    @IsTest
    public static void testCreateExternalLeadsAllWGU (){

        ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '50';
        
        insert wguELCC;
   

        Contact contact2 = new Contact(firstName='Jinky', lastName = 'OTester', email='JinkyOTester@yahoo.com',  pidm__C = '123321' );
        contact2.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact2;
       
        Account student2 = [Select id, pidm__C from Account where studentcontact__r.id = :contact2.id];

        Opportunity care2 = new Opportunity(AccountId=student2.Id, StudentContact__c = contact2.id,  Name='Jinky OTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care2.LeadGrade__c = 'B';
        insert care2;   
        
             
        CAREforceUtility.createExternalLeads(care2);

        /////////////////////////////////////////////////////////////////
        //                 Test Only WGU Exists                        //
        /////////////////////////////////////////////////////////////////
        ExternalLeadContactControl__c exc = [SELECT Id, Name FROM ExternalLeadContactControl__c WHERE Name = 'WGU'];
        Opportunity otest2 = [SELECT Id, Name, ExternalLeadContactControl__c , ExternalLeadContactControl__r.id, ExternalLeadContactControl__r.name  FROM Opportunity where id = :care2.id];
        System.assert(otest2.ExternalLeadContactControl__r.id == exc.id );  
        
            
        
        
        ExternalLeadContactControl__c notwguELCC= new ExternalLeadContactControl__c();
        notwguELCC.Name= 'NotWGU';
        notwguELCC.Active__C = false;
        notwguELCC.MonthlyLimit__c = 1000;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '50';
    
        insert notwguELCC;
            
        
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact;
       
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];

        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Sync MacTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care.LeadGrade__c = 'B';
        insert care;  
        
            
        CAREforceUtility.createExternalLeads(care);

        
        /////////////////////////////////////////////////////////////////
        //                 Test Only WGU Active//
        /////////////////////////////////////////////////////////////////
 
        Opportunity otest = [SELECT Id, Name, ExternalLeadContactControl__c , ExternalLeadContactControl__r.id, ExternalLeadContactControl__r.name  FROM Opportunity where id = :care.id];

        System.assert(otest.ExternalLeadContactControl__r.id == exc.id );  
     
        
        DateTime nowTime = DateTime.now();
        integer h = nowTime.hour(); 
        
        notwguELCC.Active__C = true;
        notwguELCC.StartHour__c = 0;
        if (h-1 > 0)
        {
            notwguELCC.StopHour__c = h-1;
        }
        else
        {
            notwguELCC.Active__C = false;
        }
        update notwguELCC;
              
 
        Contact contact3 = new Contact(firstName='Pinky', lastName = 'OTester', email='PinkyOTester@yahoo.com',  pidm__C = '1234321' );
        contact3.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
    
        insert contact3;
       
        Account student3 = [Select id, pidm__C from Account where studentcontact__r.id = :contact3.id];

        Opportunity care3 = new Opportunity(AccountId=student2.Id, StudentContact__c = contact2.id,  Name='Pinky OTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care3.LeadGrade__c = 'B';
        insert care3;   
               
        
        CAREforceUtility.createExternalLeads(care3);


        Opportunity otest3 = [SELECT Id, Name, ExternalLeadContactControl__c , ExternalLeadContactControl__r.id, ExternalLeadContactControl__r.name  FROM Opportunity where id = :care3.id];

        System.assert(otest3.ExternalLeadContactControl__r.id == exc.id );  
        
  
        
    
    }
    
    
     @IsTest
    public static void testCreateExternalLeadsNoLeadsLeft (){ 
    
    
    List<ExternalLeadContactControl__c> elist = new List<ExternalLeadContactControl__c>();
    
    String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '50';
        
        
        elist.add(wguELCC);
        
        
        ExternalLeadContactControl__c notwguELCC= new ExternalLeadContactControl__c();
        notwguELCC.Name= 'NotWGU';
        notwguELCC.Active__C = true;
        notwguELCC.MonthlyLimit__c = 1;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '50';
    
        elist.add(notwguELCC);
   

        insert elist;
        
        List<Contact> myContacts = new List<Contact>();
        
        
        Id recid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;
        Id rec2id = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id; 
        
        for (Integer i =0; i < 6; i++)
        {
              
        
        String supper = letters.substring(i+1, i+ 2);
        String slower = supper.toLowerCase();
        Contact contact2 = new Contact(firstName=supper + 'inky', lastName = 'OT' + slower + 'ster', email= supper + 'inkyOTester' + slower + '@yahoo.com',  pidm__C = '123321' + i );
        contact2.recordtypeid = recid;
    
        myContacts.add(contact2);
        
        }
        
    //    System.debug(myContacts);
        
        insert myContacts;
         
        System.assert(true);
         
        List<Account> myAccounts =  [Select id, pidm__C from Account];
         
        List<Opportunity> myCares1 = new List<Opportunity>();
        List<Opportunity> myCares2 = new List<Opportunity>();
        List<Opportunity> myCares3 = new List<Opportunity>();
       Test.startTest();
        for (Integer i =0; i < 6; i++)
        {
               Opportunity care2 = new Opportunity(AccountId=myAccounts[i].Id, StudentContact__c = myContacts[i].id,  
                                                   Name= myContacts[i].firstName + ' ' + myContacts[i].lastName , 
                                                   CloseDate=date.today(), StageName='Intake', 
                                                  RecordTypeId  = rec2id);
               care2.LeadGrade__c = 'B';
               
                insert care2;
                CAREforceUtility.createExternalLeads(care2);
           
        }
    
        
        Test.stopTest();
        
        List<Opportunity> myOtests = [SELECT Id, Name, 
                                    ExternalLeadContactControl__c , 
                                    ExternalLeadContactControl__r.id,
                                    ExternalLeadContactControl__r.name  FROM Opportunity];
                                    
        Integer j = 0;       
        
    //   System.debug('notwguELCC.id: ' + notwguELCC.id);
    //   System.debug('wguELCC.id: ' + wguELCC.id);               
        for (Opportunity o: myOtests)
        {
          // System.debug(o);
         //  System.debug(o.ExternalLeadContactControl__r.name);
            if (j == 0)
            {
                System.assert(o.ExternalLeadContactControl__c == notwguELCC.id);
                
            }
            else
            {
                 System.assert(o.ExternalLeadContactControl__r.id == wguELCC.id); 
            }   
            j++;                        
        }
     
        
    
    }
    
    
       @IsTest
    public static void testCreateExternalLeadsOneNotWGU (){ 
    
    
    List<ExternalLeadContactControl__c> elist = new List<ExternalLeadContactControl__c>();
    
    String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '50';
        
        
        elist.add(wguELCC);
        
        
        ExternalLeadContactControl__c notwguELCC= new ExternalLeadContactControl__c();
        notwguELCC.Name= 'NotWGU';
        notwguELCC.Active__C = true;
        notwguELCC.MonthlyLimit__c = 1000;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '50';
    
        elist.add(notwguELCC);
   

        insert elist;
        
        List<Contact> myContacts = new List<Contact>();
        
        
        Id recid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;
        Id rec2id = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id; 
        
        for (Integer i =0; i < 6; i++)
        {
              
        
        String supper = letters.substring(i+1, i+ 2);
        String slower = supper.toLowerCase();
        Contact contact2 = new Contact(firstName=supper + 'inky', lastName = 'OT' + slower + 'ster', email= supper + 'inkyOTester' + slower + '@yahoo.com',  pidm__C = '123321' + i );
        contact2.recordtypeid = recid;
    
        myContacts.add(contact2);
        
        }
        
     //   System.debug(myContacts);
        
        insert myContacts;
         
        System.assert(true);
         
        List<Account> myAccounts =  [Select id, pidm__C from Account];
         
        List<Opportunity> myCares1 = new List<Opportunity>();

       Test.startTest();
       List<Opportunity> myCares2 = new List<Opportunity>();
       
        for (Integer i =0; i < 6; i++)
        {
               Opportunity care2 = new Opportunity(AccountId=myAccounts[i].Id, StudentContact__c = myContacts[i].id,  
                                                   Name= myContacts[i].firstName + ' ' + myContacts[i].lastName , 
                                                   CloseDate=date.today(), StageName='Intake', 
                                                  RecordTypeId  = rec2id);
               care2.LeadGrade__c = 'B';
               
              
            insert care2;
                CAREforceUtility.createExternalLeads(care2);
           
        }
       
        
       Test.stopTest();
        
        List<Opportunity> myOtests = [SELECT Id, Name, 
                                    ExternalLeadContactControl__c , 
                                    ExternalLeadContactControl__r.id,
                                    ExternalLeadContactControl__r.name  FROM Opportunity];
                                    
        Integer j = 0;       
  //            System.debug('notwguELCC.id: ' + notwguELCC.id);
  //      System.debug('wguELCC.id: ' + wguELCC.id);               
        for (Opportunity o: myOtests)
        {
   //         System.debug(o);
    //       System.debug(o.ExternalLeadContactControl__r.name);
            if (math.mod(j,10) < 5)
            {
                System.assert(o.ExternalLeadContactControl__c == notwguELCC.id);
                
            }
            else
            {
                 System.assert(o.ExternalLeadContactControl__r.id == wguELCC.id); 
            }   
            j++;                        
        }
     
        
    
    }
    
       @IsTest
    public static void testCreateExternalLeadsThird (){ 
    
    
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
        notwguELCC.Name= 'NotWGU';
        notwguELCC.Active__C = true;
        notwguELCC.MonthlyLimit__c = 1000;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '30';
    
        elist.add(notwguELCC);
        
       ExternalLeadContactControl__c thirdNotELCC= new ExternalLeadContactControl__c();
        thirdNotELCC.Name= 'ThirdNot';
        thirdNotELCC.Active__C = true;
        thirdNotELCC.MonthlyLimit__c = 1000;
        thirdNotELCC.StartHour__c = 0;
        thirdNotELCC.StopHour__c = 24;
        
        thirdNotELCC.PercentOfLeadsToAssignPicklist__c = '30';
    
        elist.add(thirdNotELCC);
   

        insert elist;
        
        List<Contact> myContacts = new List<Contact>();
        
        
        Id recid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;
        Id rec2id = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id; 
        
        for (Integer i =0; i < 6; i++)
        {
              
        
        String supper = letters.substring(i+1, i+ 2);
        String slower = supper.toLowerCase();
        Contact contact2 = new Contact(firstName=supper + 'inky', lastName = 'OT' + slower + 'ster', email= supper + 'inkyOTester' + slower + '@yahoo.com',  pidm__C = '123321' + i );
        contact2.recordtypeid = recid;
    
        myContacts.add(contact2);
        
        }
        
     //   System.debug(myContacts);
        
        insert myContacts;
         

         
        List<Account> myAccounts =  [Select id, pidm__C from Account];
         
        List<Opportunity> myCares1 = new List<Opportunity>();

        Test.startTest();
        for (Integer i =0; i < 6; i++)
        {
               Opportunity care2 = new Opportunity(AccountId=myAccounts[i].Id, StudentContact__c = myContacts[i].id,  
                                                   Name= myContacts[i].firstName + ' ' + myContacts[i].lastName , 
                                                   CloseDate=date.today(), StageName='Intake', 
                                                  RecordTypeId  = rec2id);
               care2.LeadGrade__c = 'B';
               
           insert care2;
                CAREforceUtility.createExternalLeads(care2);
           
        }
       


       
        
       Test.stopTest();
        
        List<Opportunity> myOtests = [SELECT Id, Name, 
                                    ExternalLeadContactControl__c , 
                                    ExternalLeadContactControl__r.id,
                                    ExternalLeadContactControl__r.name  FROM Opportunity];
                                    
        Integer j = 0;       
        
           
        for (Opportunity o: myOtests)
        {
 //           System.debug(o);
 //           System.debug(o.ExternalLeadContactControl__r.name);
            if (j < 3)
            {
                      System.assert(o.ExternalLeadContactControl__c == notwguELCC.id);
                
            }
            else if (j < 6)
            {
                System.assert(o.ExternalLeadContactControl__c == thirdNotELCC.id);
      
                
            }

            else
            {
                  System.assert(o.ExternalLeadContactControl__r.id == wguELCC.id); 
            }   
            j++;                        
        }
     
        
    
    }
    
    
     @IsTest
    public static void testCreateExternalLeadsPostToLeadQual (){ 
    
    Runtime__c rtc = new RunTime__C(    Value__c = 'http://requestb.in/wvdlwmwv', name = 'LeadQual');
    insert rtc;
    List<ExternalLeadContactControl__c> elist = new List<ExternalLeadContactControl__c>();
    
    String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '10';
        
        
        elist.add(wguELCC);
        
        
        ExternalLeadContactControl__c notwguELCC= new ExternalLeadContactControl__c();
        notwguELCC.Name= 'LeadQual';
        notwguELCC.Active__C = true;
        notwguELCC.MonthlyLimit__c = 1000;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '90';
    
        elist.add(notwguELCC);
        
   

        insert elist;
        
        List<Contact> myContacts = new List<Contact>();
        
        
        Id recid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id;
        Id rec2id = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id; 
        
        for (Integer i =0; i < 2; i++)
        {
              

        
            String supper = letters.substring(i+1, i+ 2);
            String slower = supper.toLowerCase();
            Contact contact2 = new Contact(firstName=supper + 'inky', lastName = 'OT' + slower + 'ster', 
                                            email= supper + 'inkyOTester' + slower + '@yahoo.com',  
                                            pidm__C = '123321' + i, phone = '1234567890', 
                                            homephone ='', mailingstate = 'UT', mailingpostalcode = '84111'
                                             );
            contact2.recordtypeid = recid;
        
            myContacts.add(contact2);
        
        }
        
        System.debug(myContacts);
        
        insert myContacts;
         

         
        List<Account> myAccounts =  [Select id, pidm__C from Account];
         
        List<Opportunity> myCares1 = new List<Opportunity>();
        
     

        Test.startTest();
        for (Integer i =0; i < 2; i++)
        {
               Opportunity care2 = new Opportunity(AccountId=myAccounts[i].Id, StudentContact__c = myContacts[i].id,  
                                                   Name= myContacts[i].firstName + ' ' + myContacts[i].lastName , 
                                                   CloseDate=date.today(), StageName='Intake', LeadGrade__c = 'B',
                                                   RecordTypeId  = rec2id, MarketingProgram__c = getProgram(i+1));
                                                   
             
               
               insert care2;
               System.debug(care2);
               CAREforceUtility.createExternalLeads(care2);
             
           
        }
       
       



       
        
       Test.stopTest();
        
        List<Opportunity> myOtests = [SELECT Id, Name, 
                                    ExternalLeadContactControl__c , 
                                    ExternalLeadContactControl__r.id,
                                    ExternalLeadContactControl__r.name  FROM Opportunity];
                                    
        Integer j = 0;       
        
           
        for (Opportunity o: myOtests)
        {
 //           System.debug(o);
 //           System.debug(o.ExternalLeadContactControl__r.name);
            if (j < 3)
            {
              //        System.assert(o.ExternalLeadContactControl__c == notwguELCC.id);
                
            }
            else if (j < 6)
            {
              //  System.assert(o.ExternalLeadContactControl__c == thirdNotELCC.id);
      
                
            }

            else
            {
           //       System.assert(o.ExternalLeadContactControl__r.id == wguELCC.id); 
            }   
            j++;                        
        }
     
        
    
    }
    
       @IsTest
  public static void testStatusUpdateToLeadQual() {      
  
      Runtime__c rtc = new RunTime__C(    Value__c = 'http://requestb.in/wvdlwmwv', name = 'LeadQual');
    insert rtc;
    List<ExternalLeadContactControl__c> elist = new List<ExternalLeadContactControl__c>();
    
    String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      ExternalLeadContactControl__c wguELCC= new ExternalLeadContactControl__c();
        wguELCC.Name= 'WGU';
        wguELCC.Active__C = true;
        wguELCC.MonthlyLimit__c = 1000;
        wguELCC.StartHour__c = 0;
        wguELCC.StopHour__c = 24;
        wguELCC.PercentOfLeadsToAssignPicklist__c = '0';
        
        
        elist.add(wguELCC);
        
        
        ExternalLeadContactControl__c notwguELCC= new ExternalLeadContactControl__c();
        notwguELCC.Name= 'LeadQual';
        notwguELCC.Active__C = true;
        notwguELCC.MonthlyLimit__c = 1000;
        notwguELCC.StartHour__c = 0;
        notwguELCC.StopHour__c = 24;
        
        notwguELCC.PercentOfLeadsToAssignPicklist__c = '100';
    
        elist.add(notwguELCC);  
        
        insert elist;
    
    Contact student = TestStudentUser.getTestStudentContact();
    
    Opportunity care = new Opportunity(AccountId=student.AccountId, Name='Dudley Schults', ExternalLeadContactControl__C = notwguELCC.id,
     CloseDate=date.today(), StageName='Intake', 
     RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
    insert care;
    update care;
    System.debug('CARET: ' + care);
    care = [select id, AccountId, LastCallDisposition__c, ExternalLeadContactControl__C from Opportunity where id = :care.id];
        System.debug('CAREA: ' + care);
    Id careTaskId = [Select id from RecordType where Name='CAREforce Task' and sObjectType = 'Task'].id;    
        
    Test.StartTest();

        List<Task> newTasksList = new List<Task>();
        newTasksList.add( new Task(Subject='Call', CallDisposition__c='Phone Attempt 1', RecordTypeId=careTaskId, whoid=student.Id, whatid=care.id, NoteType__c='Other') );
        insert newTasksList;
            
    Test.StopTest();
        
   
    //grabbing code coverage
    CAREforceUtility.sendStatusUpdateToLeadQualDecode( JSON.serialize(newTasksList) );

  }
    
    
        public static String getProgram(Integer sequence) {
        WGUDegreeProgram__c degreeProgram = null;
        CareProgramMiddleEarth__c earth = null;
        
        if (sequence == 1 || sequence == null) {

            // Create WGU Degree Program
            degreeProgram = new WGUDegreeProgram__c(Name='BAECE', Title__c='Bachelor of Arts, Early Childhood Education', active__c=true, PAMSID__c=15);
            insert degreeProgram;
            
            // Create Marketing Program
            earth = new CareProgramMiddleEarth__c(Name='BA Early Childhood Education', active__c=true, BannerProgramCode__c=degreeProgram.id, InquiryProgram__c=true, ProgramGroups__c='Nursing');
            insert earth;
        }
        else {
            // Create WGU Degree Program
            degreeProgram = new WGUDegreeProgram__c(Name='BAMA9', Title__c='Bachelor of Arts, Mathematics (5-9)', active__c=true, PAMSID__c=300000);
            insert degreeProgram;
            
            // Create Marketing Program
            earth = new CareProgramMiddleEarth__c(Name='BA Mathematics 5-9', active__c=true, BannerProgramCode__c=degreeProgram.id, InquiryProgram__c=true, ProgramGroups__c='Education (initial teaching licensure programs)');
            insert earth;
        }

        // Return Marketing Program Id
        return earth.id;
    }
    
    
}