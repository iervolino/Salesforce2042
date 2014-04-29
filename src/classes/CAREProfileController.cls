public class CAREProfileController {
    
    Contact contact;
    Opportunity careprofile;
    public String marketingProgram {get; set;}
    public String fieldRep {get; set;}
    StudentAttributes__c attributes;
    // public String firstname {get; set;}
    public CAREProfileController(){
    }
    public List<SelectOption> getPrograms(){
        List<CareProgramMiddleEarth__c> programs = [SELECT Id,Name FROM CareProgramMiddleEarth__c WHERE Active__c = True ORDER BY ProgramGroups__c, Name];
        List<SelectOption> options = new List<SelectOption>();
        if (!programs.isEmpty()){
            for (CareProgramMiddleEarth__c program : programs){
                options.add(new SelectOption(program.Id, program.Name));
            }    
        }
        return options; 
    }
    
    public List<SelectOption> getStatesSelectList(){
        List<SelectOption> states = new List<SelectOption>();
        states.add(new SelectOption('', '--Select a State--'));
        Map<String, States__c> stateNames = States__c.getAll(); // new Map<ID, States__c>( [select id, name, value__c from States__c order by name ASC] ); 
        List <String> statesShortName = new List<String>();
        statesShortName.addAll(stateNames.keySet());
        statesShortName.sort();
        for (String stateShortName : statesShortName) {
            States__c state = stateNames.get(stateShortName);
            states.add(new SelectOption(stateShortName, state.StateFullName__c));
        }
        return states;
    }
    
    public void setContact(Contact contact){
        this.contact = contact;
    }
    public void setOpportunity(Opportunity careprofile){
        this.careprofile = careprofile;
    }
    public void setAttributes(StudentAttributes__c attributes){
        this.attributes = attributes;
    }
    
    public Contact getContact(){
        if(contact == null) contact= new Contact(); 
        return contact;
    } 
    
    public Opportunity getOpportunity() {
        if(careprofile == null) careprofile = new Opportunity();
        return careprofile;
    }
    
    public StudentAttributes__c getAttributes(){
        if(attributes == null) attributes = new StudentAttributes__c();
        return attributes;
    }
    
    public void save() {
        Map<String, String> fields = new Map<String, String>();
        fields.put('firstname', contact.firstName);
        fields.put('lastname', contact.lastName);
        fields.put('street', contact.mailingStreet);
        fields.put('city', contact.mailingCity);
        fields.put('state', contact.mailingState);
        fields.put('postalcode', contact.mailingPostalCode);
        fields.put('country', 'US');
        fields.put('email', contact.Email);
        fields.put('campus', attributes.Affiliation__c);
        fields.put('fieldrep', fieldRep);
        fields.put('nickname', attributes.Nickname__c);
        fields.put('phone', contact.phone);
        fields.put('alternatephone', contact.OtherPhone);
        fields.put('program', marketingProgram);
        fields.put('referid', '1721');
        
        CAREforceInquiryRESTServices.inquiry(null, fields, null, null, false);
        
        contact = null;
        careprofile = null;
        attributes = null; 
    
    }
    
}