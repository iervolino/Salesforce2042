@IsTest
public class TestPersonalPages{
    
 /*   class JsonOutput
    {
        String firstName;
        String lastName;
        String ecName;
        String programName;
        List<Personal_Pages_Link__c> personalPagesLinks;
        String identifier;
        String errorMessage;
        
    }
*/    
    
    
    @IsTest
        public static void helloWorld(){
            
            System.assert(true);
            
        }
    
    //Tests simple name no special characters, valid
    @IsTest
        public static void testGenerateIdentifier(){
            
            Test.startTest();
            Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
            contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
            
            insert contact;
            
            Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
            
            Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Sync MacTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
            insert care;
            
            
            Test.stopTest();
            
            Contact testContact = [Select id, lastName, FirstName from Contact where id = :contact.id];
            Opportunity testOpportunity = [select PersonalPageIdentifier__c from Opportunity where id = :care.id];
            
            System.assert(testOpportunity.PersonalPageIdentifier__c == null);
            
            PersonalPages.generateIdentifier(care.id, testContact.id);
            
            testOpportunity = [select PersonalPageIdentifier__c from Opportunity where id = :care.id];
            
            String contactId = (String) contact.id;
            String lastFour = contactId.substring(contactId.length()- 7, contactId.length() - 3);
            String idenf = 'syncmactester' + lastFour;
            System.debug('idenf ' + idenf);
            System.debug('testOpportunity ' + testOpportunity.PersonalPageIdentifier__c);
            
            System.assert(idenf.equals(testOpportunity.PersonalPageIdentifier__c));
            
            
        }
    
    //Tests simple name with special characters/numbers, valid
   @IsTest
        public static void testGenerateIdentifierspecialCharacters(){
            
            Test.startTest();
            Contact contact = new Contact(firstName='Sync568', lastName = 'Mac&%$Tester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
            contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
            
            insert contact;
            
            Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
            
            Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  Name='Sync MacTester', CloseDate=date.today(), StageName='Intake', RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
            insert care;
            
            
            Test.stopTest();
            
            Contact testContact = [Select id, lastName, FirstName from Contact where id = :contact.id];
            Opportunity testOpportunity = [select PersonalPageIdentifier__c from Opportunity where id = :care.id];
            
            System.assert(testOpportunity.PersonalPageIdentifier__c == null);
            
            PersonalPages.generateIdentifier(care.id, testContact.id);
            
            testOpportunity = [select PersonalPageIdentifier__c from Opportunity where id = :care.id];
            
            String contactId = (String) contact.id;
            String lastFour = contactId.substring(contactId.length()- 7, contactId.length() - 3);
            String idenf = 'syncmactester' + lastFour;
            System.assert(idenf.equals(testOpportunity.PersonalPageIdentifier__c));
            
            
        }
    
    /*
    @IsTest
        public static void incorrectStudent()
    {
        
        Test.startTest();
        
        
        
        
        String jsn = PersonalPages.identifierDataGather('not a real possible url');
        System.debug(jsn);
        
        JsonOutput j = (JsonOutput) JSON.deserialize(jsn ,jsonOutput.class);
        
        
        
        Test.stopTest();
        
        System.assert(j.errorMessage.equals('Student Not Found')); 
        

        
        
        
        
    }
    
    @IsTest
        public static void nullUrl()
    {
        
        
        String json = PersonalPages.identifierDataGather(null);
        System.debug(json);
        System.Assert(json == null );
        
        
        
    }
    
 @IsTest
        public static void goodPathSinglePageLink()
    {
        
        
        CAREProgram__c cProgram = new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test');
        insert cProgram;
        
        WGUDegreeProgram__c original = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test');
        insert original;
        
        CareProgramMiddleEarth__c middleEarth = new CareProgramMiddleEarth__c(Name=cProgram.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram.Id, BannerProgramCode__c=original.Id);
        insert middleEarth;
        
        
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
        
        
        insert contact;
        
           StudentAttributes__c studentAttr = new StudentAttributes__c(Affiliation__c = 'WGU');

        insert studentAttr; 
        
        
        
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
        
        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  
                                           Name='Sync MacTester', CloseDate=date.today(), 
                                           StageName='Intake', StudentAttributes__c = studentAttr.id, 
                                           RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care.MarketingProgram__c = middleEarth.id;
        insert care;
        
        PersonalPages.generateIdentifier(care.id, contact.id);

        
        Personal_Pages_Link__c pplink = new Personal_Pages_Link__c(active__c = true,
                                                                   affiliation__c = 'WGU',
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page1.html',
                                                                   Program__c = 'CARE Program Test',
                                                                   sort_order__c = 0);
        insert pplink;
        
        Test.startTest();
        
        String contactid = contact.id;
        String lastFour = contactid.substring(contactid.length()- 7, contactid.length() - 3);
  
        List<Personal_Pages_Link__c> testppl  = [Select id, affiliation__c, active__c,
                                             sort_order__c, image__c, link__c,
                                             Program__c
                                             from Personal_Pages_Link__c
                                             where active__C = true
                                             and affiliation__c = 'WGU'
                                             order by sort_order__c];
    //    System.debug('HERE2' + testppl);
  
        String jsn = PersonalPages.identifierDataGather('http://url.does.not.matter/' + 'syncmactester' + lastFour );
   //     System.debug(jsn);
        
        JsonOutput j = (JsonOutput) JSON.deserialize(jsn ,jsonOutput.class);
        
        Test.stopTest();
    //    system.debug(j);
        
      //  system.debug('JPPL: ' + j.personalPagesLinks);
     //   system.debug('JPPLS: ' + j.personalPagesLinks.size());
        System.assert(j.personalPagesLinks.siZe() == 1);
        System.assert(j.personalPagesLinks.get(0).link__c.equals('http://link.to.me/page1.html'));
        System.assert(j.personalPagesLinks.get(0).affiliation__c.equals('WGU'));
        
        
        
        
    }
    
     @IsTest
    public static void goodPathMultipleLinksOnlyOneForProgram()
    {
        
        
        CAREProgram__c cProgram = new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test');
        insert cProgram;
        
        WGUDegreeProgram__c original = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test');
        insert original;
        
        CareProgramMiddleEarth__c middleEarth = new CareProgramMiddleEarth__c(Name=cProgram.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram.Id, BannerProgramCode__c=original.Id);
        insert middleEarth;
        
                CAREProgram__c cProgram2 = new CAREProgram__c(Name='CTEST2', Active__c=true, ProgramLabel__c='CARE2 Program Test2');
        insert cProgram2;
        
        WGUDegreeProgram__c original2 = new WGUDegreeProgram__c(name='PTEST2', PAMSID__c=2, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS2 Program Test2');
        insert original2;
        
        CareProgramMiddleEarth__c middleEarth2 = new CareProgramMiddleEarth__c(Name=cProgram2.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram2.Id, BannerProgramCode__c=original2.Id);
        insert middleEarth2;
        
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
        
        
        insert contact;
        
           StudentAttributes__c studentAttr = new StudentAttributes__c(Affiliation__c = 'WGU');

        insert studentAttr; 
        
        
        
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
        
        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  
                                           Name='Sync MacTester', CloseDate=date.today(), 
                                           StageName='Intake', StudentAttributes__c = studentAttr.id, 
                                           RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care.MarketingProgram__c = middleEarth.id;
        insert care;
        
        PersonalPages.generateIdentifier(care.id, contact.id);

        
        Personal_Pages_Link__c pplink2 = new Personal_Pages_Link__c(active__c = true,
                                                                   affiliation__c = 'WGU',
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page1.html',
                                                                   Program__c = 'CARE Program Test',
                                                                   sort_order__c = 0);
        insert pplink2;
        
        
             Personal_Pages_Link__c pplink = new Personal_Pages_Link__c(active__c = true,
                                                                   affiliation__c = 'WGU',
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://notlink.to.me/page1.html',
                                                                   Program__c = 'Not CARE Program Test',
                                                                   sort_order__c = 0);
                                                                   
        insert pplink;
        
        Test.startTest();
        
        String contactid = contact.id;
        String lastFour = contactid.substring(contactid.length()- 7, contactid.length() - 3);
  
        List<Personal_Pages_Link__c> testppl  = [Select id, affiliation__c, active__c,
                                             sort_order__c, image__c, link__c,
                                             Program__c
                                             from Personal_Pages_Link__c
                                             where active__C = true
                                             and affiliation__c = 'WGU'
                                             order by sort_order__c];
 
  
        String jsn = PersonalPages.identifierDataGather('http://url.does.not.matter/' + 'syncmactester' + lastFour );

        
        JsonOutput j = (JsonOutput) JSON.deserialize(jsn ,jsonOutput.class);
        
        Test.stopTest();

     
        
        System.assert(j.personalPagesLinks.siZe() == 1);
        System.assert(j.personalPagesLinks.get(0).link__c.equals('http://link.to.me/page1.html'));
        System.assert(j.personalPagesLinks.get(0).affiliation__c.equals('WGU'));
        
        
        
        
    }
    
    
    
   

        

                                                                   
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                
                                                                   
    @IsTest
    public static void goodPathOneLinkWithMoreThenOneProgram()
    {
        
        
        CAREProgram__c cProgram = new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test');
        insert cProgram;
        
        WGUDegreeProgram__c original = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test');
        insert original;
        
        CareProgramMiddleEarth__c middleEarth = new CareProgramMiddleEarth__c(Name=cProgram.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram.Id, BannerProgramCode__c=original.Id);
        insert middleEarth;
        
                CAREProgram__c cProgram2 = new CAREProgram__c(Name='CTEST2', Active__c=true, ProgramLabel__c='CARE2 Program Test2');
        insert cProgram2;
        
        WGUDegreeProgram__c original2 = new WGUDegreeProgram__c(name='PTEST2', PAMSID__c=2, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS2 Program Test2');
        insert original2;
        
        CareProgramMiddleEarth__c middleEarth2 = new CareProgramMiddleEarth__c(Name=cProgram2.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram2.Id, BannerProgramCode__c=original2.Id);
        insert middleEarth2;
        
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
        
        
        insert contact;
        
           StudentAttributes__c studentAttr = new StudentAttributes__c(Affiliation__c = 'WGU');

        insert studentAttr; 
        
        
        
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
        
        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  
                                           Name='Sync MacTester', CloseDate=date.today(), 
                                           StageName='Intake', StudentAttributes__c = studentAttr.id, 
                                           RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care.MarketingProgram__c = middleEarth.id;
        insert care;
        
        PersonalPages.generateIdentifier(care.id, contact.id);
    
            Personal_Pages_Link__c pplink2 = new Personal_Pages_Link__c(active__c = true,
                                                                   affiliation__c = 'WGU',
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page1.html',
                                                                   Program__c = 'CARE Program Test; Not CARE Program Test',
                                                                   sort_order__c = 0);
        insert pplink2;
        
        

        
        
 
        
        Test.startTest();
        
        String contactid = contact.id;
        String lastFour = contactid.substring(contactid.length()- 7, contactid.length() - 3);
  
        List<Personal_Pages_Link__c> testppl  = [Select id, affiliation__c, active__c,
                                             sort_order__c, image__c, link__c,
                                             Program__c
                                             from Personal_Pages_Link__c
                                             where active__C = true
                                             and affiliation__c = 'WGU'
                                             order by sort_order__c];
 
  
        String jsn = PersonalPages.identifierDataGather('http://url.does.not.matter/' + 'syncmactester' + lastFour );
        System.debug(jsn);
        
        JsonOutput j = (JsonOutput) JSON.deserialize(jsn ,jsonOutput.class);
        
        Test.stopTest();
       

     
        
        System.assert(j.personalPagesLinks.siZe() == 1);
        System.assert(j.personalPagesLinks.get(0).link__c.equals('http://link.to.me/page1.html'));
        System.assert(j.personalPagesLinks.get(0).affiliation__c.equals('WGU'));
        
        
        
        
    }
    
     public static void goodPathMutipleLinskWithMoreThenOneProgram()
    {
        
        
        CAREProgram__c cProgram = new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test');
        insert cProgram;
        
        WGUDegreeProgram__c original = new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test');
        insert original;
        
        CareProgramMiddleEarth__c middleEarth = new CareProgramMiddleEarth__c(Name=cProgram.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram.Id, BannerProgramCode__c=original.Id);
        insert middleEarth;
        
        CAREProgram__c cProgram2 = new CAREProgram__c(Name='CTEST2', Active__c=true, ProgramLabel__c='CARE2 Program Test2');
        insert cProgram2;
        
        WGUDegreeProgram__c original2 = new WGUDegreeProgram__c(name='PTEST2', PAMSID__c=2, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS2 Program Test2');
        insert original2;
        
        CareProgramMiddleEarth__c middleEarth2 = new CareProgramMiddleEarth__c(Name=cProgram2.ProgramLabel__c, Active__c=true, CAREProgramCode__c=cProgram2.Id, BannerProgramCode__c=original2.Id);
        insert middleEarth2;
        
        Contact contact = new Contact(firstName='Sync', lastName = 'MacTester', email='MACTESTER@Msn.com',  pidm__C = '12356321' );
        contact.recordtypeid = [select id from recordtype where name = 'ProspectRecord' and sobjecttype = 'Contact' limit 1].id; 
        
        
        insert contact;
        
           StudentAttributes__c studentAttr = new StudentAttributes__c(Affiliation__c = 'WGU');

        insert studentAttr; 
        
        
        
        Account student = [Select id, pidm__C from Account where studentcontact__r.id = :contact.id];
        
        Opportunity care = new Opportunity(AccountId=student.Id, StudentContact__c = contact.id,  
                                           Name='Sync MacTester', CloseDate=date.today(), 
                                           StageName='Intake', StudentAttributes__c = studentAttr.id, 
                                           RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        care.MarketingProgram__c = middleEarth.id;
        insert care;
        
        PersonalPages.generateIdentifier(care.id, contact.id);
       
       
               Personal_Pages_Link__c pplink2 = new Personal_Pages_Link__c(active__c = true,
                                                                   affiliation__c = 'WGU',
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page1.html',
                                                                   Program__c = 'CARE Program Test',
                                                                   sort_order__c = 0);
        insert pplink2;
        
        
             Personal_Pages_Link__c pplink = new Personal_Pages_Link__c(active__c = true,
                                                                   affiliation__c = 'WGU',
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://notlink.to.me/page1.html',
                                                                   Program__c = 'CARE Program Test;Not CARE Program Test',
                                                                   sort_order__c = 0);
                                                                   
        insert pplink;
        
        
        
 
        
        Test.startTest();
        
        String contactid = contact.id;
        String lastFour = contactid.substring(contactid.length()- 7, contactid.length() - 3);
  
        List<Personal_Pages_Link__c> testppl  = [Select id, affiliation__c, active__c,
                                             sort_order__c, image__c, link__c,
                                             Program__c
                                             from Personal_Pages_Link__c
                                             where active__C = true
                                             and affiliation__c = 'WGU'
                                             order by sort_order__c];

  
        String jsn = PersonalPages.identifierDataGather('http://url.does.not.matter/' + 'syncmactester' + lastFour );
        System.debug(jsn);
        
        JsonOutput j = (JsonOutput) JSON.deserialize(jsn ,jsonOutput.class);
        
        Test.stopTest();

     
        
        System.assert(j.personalPagesLinks.siZe() == 2);
        System.assert(j.personalPagesLinks.get(0).link__c.equals('http://link.to.me/page1.html'));
        System.assert(j.personalPagesLinks.get(1).link__c.equals('http://notlink.to.me/page1.html'));
        System.assert(j.personalPagesLinks.get(0).affiliation__c.equals('WGU'));
        
        
        
        
        
    }
    
*/
    
    
}