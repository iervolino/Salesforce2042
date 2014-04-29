@isTest 
public class TestCAREProfileController{

    @isTest
    public static void testCareProfileController() {
    
    createExternalLead();
    
        Runtime__c r = new Runtime__c();
        r.Name = 'UsePersonAccounts';
        r.Value__c = 'false';
        insert r;
        
        Runtime__c e = new Runtime__c();
        e.Name = 'environment';
        e.Value__c = 'test';
        insert e;           
        
        List<CAREProgram__c> cPrograms = new List<CAREProgram__c>();    
        cPrograms.add(new CAREProgram__c(Name='CTEST1', Active__c=true, ProgramLabel__c='CARE Program Test'));
        cPrograms.add(new CAREProgram__c(Name='CTEST2', Active__c=true, ProgramLabel__c='CARE Program Tester'));
        insert cPrograms;
        
        List<WGUDegreeProgram__c> theStart = new List<WGUDegreeProgram__c>();
        theStart.add(new WGUDegreeProgram__c(name='PTEST1', PAMSID__c=1, Active__c=true, CatalogTerm__c='200711', Title__c='PAMS Program Test'));
        theStart.add(new WGUDegreeProgram__c(name='PTEST2', PAMSID__c=2, Active__c=true, CatalogTerm__c='200711', Title__c='myPAMS Program Tester'));
        insert theStart;
        
        List<CareProgramMiddleEarth__c> middleEarth = new List<CareProgramMiddleEarth__c>();
        middleEarth.add(new CareProgramMiddleEarth__c(Name=cPrograms.get(0).ProgramLabel__c, Active__c=true, CAREProgramCode__c=cPrograms.get(0).Id, BannerProgramCode__c=theStart.get(0).Id));
        middleEarth.add(new CareProgramMiddleEarth__c(Name=cPrograms.get(1).ProgramLabel__c, Active__c=true, CAREProgramCode__c=cPrograms.get(1).Id, BannerProgramCode__c=theStart.get(1).Id));
        insert middleEarth;
        
        States__c c = new States__c();
        c.Name = 'UT';
        c.StateFullName__c = 'Utah';
        insert c;
        
        //Contact con = new Contact();
        //con.LastName = 'test';
        //insert con;
        
        
        PageReference pageRef = Page.newprospect;
        Test.setCurrentPage (pageRef);
        
        Test.startTest();
        
        CAREProfileController controller = new CAREProfileController();
        List<SelectOption> programs = controller.getPrograms();
        List<SelectOption> states = controller.getStatesSelectList();
        
        System.assert(programs.size()== 2);
        System.assert(states.get(1).getLabel() == 'Utah' && states.get(1).getValue() == 'UT');
        
        Contact con = controller.getContact();
        StudentAttributes__c stuAtt = controller.getAttributes();
        Opportunity care = controller.getOpportunity();
        
        con.firstName = 'Chase';
        con.lastName = 'Schults';
        con.mailingStreet = '4001 S 700 E';
        con.mailingCity = 'Salt Lake City';
        con.mailingState = 'UT';
        con.mailingPostalCode = '84107';
        con.mailingCountry = 'USA';
        //con.StudentContact__r = con;
        con.Email= 'chase.schults@wgu.edu';
        stuAtt.Affiliation__c = 'WGU';
        care.MarketingProgram__c = middleEarth.get(0).id;
        care.Fieldrep__c = 'Ken Sorber';
        con.phone = '801-428-5967';
        con.OtherPhone= '801-884-6815';
        stuAtt.Nickname__c = 'Chaser';
        
        // Valid insert into Account/Contact/Opportunity
        controller.setContact(con);
        controller.setAttributes(stuAtt);
        controller.setOpportunity(care);
        controller.save();
        
        // Missing information, insert into lead.
        con.Email= null;
        con.phone = '801-428-5969';
        //controller.setEmail('chase.schults@wgu.edu');
        controller.setContact(con);
        controller.setAttributes(stuAtt);
        controller.setOpportunity(care);
        controller.save();
        
        Test.stopTest();
        
        Contact[] contact= [SELECT id, firstName, lastName, Email FROM contact WHERE lastName = 'Schults'];
        System.assertEquals('chase.schults@wgu.edu', contact[0].Email);
        
        Lead[] lead = [SELECT id, firstName, lastName FROM lead WHERE firstName = 'Chase'];
        System.assertEquals('Chase', lead[0].firstName);
        
        Test.setCurrentPage (pageRef);
        
    }
    
          private static void createExternalLead()
        {
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
        

        
   

        insert elist;
    } 
}