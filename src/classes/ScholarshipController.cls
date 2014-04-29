/*
This Controller is used for ScholarshipUpload Page.It handles the CSV file and load the records.
Author - Bhavadeep Raavi
Modified - Mike Slade - Added Record Types and fixed small defects
Modified - Bhavedeep Raavi 1-25-2003 For Person Account Conversion
No Sharing rules, the current sharing rules remain in effect
*/

public class ScholarshipController{

    public string nameFile{get;set;}
    public string nameFile1{get;set;}
    public string testval {get;set;}
    public Blob contentFile{get;set;}
    public List<ScholarshipBean> lstScrship{get;set;}
    String[] filelines = new String[]{};
    List<FinancialApplication__c> finAppstoupload;   
    List<FinancialRequirement__c> lstFR=new List<FinancialRequirement__c>();
    List<FinancialRequirement__c> lstUPDFR=new List<FinancialRequirement__c>();
    Map<String,ScholarshipBean> mapScrship=new Map<String,ScholarshipBean>();
    Map<String,FinancialApplication__c> mapFinApp=new Map<String,FinancialApplication__c>();
    Map<String,FinancialApplication__c> mapFinAppIds=new Map<String,FinancialApplication__c>();
    Map<String,FinancialApplication__c> exstFinAppMap=new Map<String,FinancialApplication__c>();
    private Map<String,FinancialRequirement__c> urlReqMap = new map <String,FinancialRequirement__c>();
    private List<FinancialRequirement__c> reqList = new List<FinancialRequirement__c>();
    private Map<String,Contact> conMap=new Map<String,Contact>();
    
    
    
    
    //Method to read the Uploaded CSV document
    public Pagereference ReadFile()
    {
        try {
                parsefile();
            }
        catch(Exception e){
            String tr=e.getMessage();
            Integer lineNum = e.getLineNumber();
            system.debug(tr);
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in the upload. Please check the template or try again later: ' + lineNum +  ' ' + tr);
            ApexPages.addMessage(errormsg )  ;                 
                }
        return null;
    }
    
    public void parsefile()   
    {
        lstScrship=new List<ScholarshipBean>();
        string pidm;
         string url;
        nameFile1=contentFile.toString();
        filelines = nameFile1.split('\n');
        system.debug('raavi1  '+filelines);
        finAppstoupload = new List<FinancialApplication__c>();
        Set<String> pidmSet=new Set<String>();
        Set<String> appURLSet=new Set<String>();
       
        // Map<String,Account> accIdMap=new Map<String,Account>();
        Map<String,Opportunity> oppMap = new Map<String, Opportunity>();
        
        //get the requirement rules
               list <RequirementRule__c> ReqRules = [select FinRequirement__c,
                                                             ImportFieldNumber__c, 
                                                             ImportFieldBlankValue__c,
                                                             ImportFieldSatisfy__c,
                                                             AllNeedReq__c
                                                      from   RequirementRule__c where recordtype.Name ='Scholarship Import'];
        
        
        for (Integer i=1;i<filelines.size();i++){
            
              system.debug('File Line ' + i +' ' +filelines[i]);        
            Date todayDate=Date.today();
            Date past7Date=todayDate.addDays(-7);
            if (i>0){
            ScholarshipBean ssb=new ScholarshipBean();
            String[] inputvalues = new String[]{};
            inputvalues = filelines[i].split(',(?=([^\"]*\"[^\"]*\")*[^\"]*$)');//Spliting the records to get the  Coloumn values
            
            inputvalues[0] = inputvalues[0].replace('"','');
            pidm = inputvalues[0];
            pidmSet.add(inputvalues[0]);
            ssb.Name = inputvalues[6];
            
             //Assign the PIDM value
                if(inputvalues[0]!=null && inputvalues[0]!=''){
                    ssb.pidm = inputvalues[0];
                }else{
                    ssb.pidm ='';
                    continue;
                }
            
            //Getting the last 7 days records.
            if(inputvalues!=null && inputvalues.size()>4 && inputvalues[3]!=null && inputvalues[3]!=' ' && todayDate>=Date.parse(inputvalues[3]) &&  past7Date<=Date.parse(inputvalues[3])){
                 
             System.debug('Student Has Valid Info ==> '+ssb.pidm);          
               
                ssb.lastUpdatedDate =inputvalues[3];
              
                
                //Assigning the URL of the student's application
                String[] arrView2;
                if(inputvalues[4]!=null && inputvalues[4]!=''){
                    String[] arrView1=inputvalues[4].split('""');
                    if(arrView1!=null && arrView1.size()>=2){ 
                        arrView2=arrView1[1].split('""'); 
                    }
                 }    
                if(arrView2!=null && arrView2[0]!=null && arrView2[0]!=''){  
                    url = 'https://wgu.academicworks.com'+arrView2[0]+'#general_application';
                    ssb.view = url ;  //added +'#general_application' Mike Slade 
                    appURLSet.add(url);
                }else{
                    ssb.view = '';
                    System.debug('No Url ==> '+ssb.pidm); 
                    continue; 
                }
                
                //loop through the requirement rules to create requiremetns
                String reqURL  ;
                String satisfyValue;
                for (RequirementRule__c reqRule : reqrules)
                {
                   
                     String importValue = inputvalues[(integer)reqRule.ImportFieldNumber__c];  //get the import value for the specified field
                    String reqStatus = 'Required'; //default status to requiremed
                   if (reqRule.ImportFieldSatisfy__c != null)
                    {   
                         reqURL = null;
                
                          satisfyValue = null;   
                          satisfyValue = inputValues[(integer)reqRule.ImportFieldSatisfy__c];
                          //    testval += reqRule.FinRequirement__c + inputValues[(integer)reqRule.ImportFieldSatisfy__c];
                        system.debug('Satisfy Value ' + satisfyValue);
                             if ( satisfyValue.startsWith('"<a href')  )
                        {
                            String[] arrView7;
                            String[] arrView8;
                            arrView7=inputvalues[(integer)reqRule.ImportFieldSatisfy__c].split('""'); 
                            if(arrView7!=null && arrView7.size()>=2)
                            {
                                system.debug('url portion' + arrView7[1]);
                                arrView8=arrView7[1].split('""');
                            }
                           
                            
                            if(arrView8!=null && arrView8[0]!=null && arrView8[0]!='')
                              reqURL = 'https://wgu.academicworks.com'+arrView8[0];
                            else
                              reqURL = null;
                        }
                    }
                    else
                    {
                        satisfyValue = null;
                        reqURL = null;
                    }
                    
                 
                    
                  
                    if ( (importValue!=null && importValue!='' && importValue!=reqRule.ImportFieldBlankValue__c) ||reqRule.AllNeedReq__c )
                    {
                        if  (reqRule.ImportFieldSatisfy__c != null )  //check to see if it's auto satisfied
                        {
                                
                                if (satisfyValue != null && satisfyValue !='' && satisfyValue!= '[,,]')
                                {
                                  reqStatus  = 'Satisfied';
                                   //if (pidm == '123456')  
                                       //testval += pidm +' '+ satisfyValue;
                                }
                        }
                         
                        
                        
                       FinancialRequirement__c finReq = new FinancialRequirement__c(Requirement__c =reqRule.FinRequirement__c, 
                                                                                      RequirementsStatus__c = reqStatus,
                                                                                     TempID__c = url,
                                                                                     RequirementURL__c =reqURL );
                        reqList.add(finReq);
                        //testval += pidm + ' ' + reqRule.FinRequirement__c;
                    }
                }
              
                mapScrship.put(inputvalues[0],ssb);
                lstScrship.add(ssb);
                 System.debug('Student Looded into Bean ==> '+ssb.pidm); 
             }
            }
        }
        Set<id> conSet=new Set<id>();
        List<Contact> lstCon=[select id,PIDM__c from Contact where PIDM__c in :pidmSet];
        
        List<FinancialApplication__c> lstExistingFinApps=[select id,ApplicationURL__c 
                                                          from FinancialApplication__c 
                                                          where ApplicationURL__c in :appURLSet];
        for(Contact con: lstCon){
            conMap.put(con.PIDM__c,con);
              conSet.add(con.id);
            //accIdMap.put(ac.id, ac);
        }   
        
       try
            {
                 
        //get the opportunity if it's active
        List<Opportunity> lstOpp=[select id,StudentContact__r.Id
                                  from Opportunity 
                                  where  StudentContact__r.Id in :conSet
                                  and CloseDate > Today ];
                
        for (Opportunity opp:lstOpp)
        {
            oppMap.put(opp.StudentContact__r.Id,opp);          
        }
                }
           catch (Exception er1){
            String tr1=er1.getMessage();
            system.debug(tr1);
            integer lineNum1 = er1.getLineNumber();
            ApexPages.Message errormsg1 = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured Mapping Opportunity. Please check the template or try again later ' + lineNum1 + tr1);
            ApexPages.addMessage(errormsg1 );
        } 
            
        
        for(FinancialApplication__c fapp: lstExistingFinApps){
            exstFinAppMap.put(fapp.ApplicationURL__c,fapp);
        }
        
        //Creating Financial Applications list from CSV Document
        for (ScholarshipBean sb:lstScrship){     
            Id faId;
            String faName;
            String faStdContact;
            String faAppURL;
            String faDate;   
            string fastdOpportunity;
            FinancialApplication__c fa = new FinancialApplication__c();
            
           RecordType FinAppRT = [SELECT Id FROM RecordType WHERE Name = 'Scholarship' AND SobjectType = 'FinancialApplication__c' LIMIT 1];
            
        
                
            
            //Upsert the Financial Applications
            if(exstFinAppMap!=null && exstFinAppMap.get(sb.view)!=null){
                faId=exstFinAppMap.get(sb.view).id;  //check the map to see it exists already
            }else{
                faId=null;
            }
            if(sb.pidm.length() > 80){
                faName=sb.pidm.substring (1,80) ;
            }else{
                faName=sb.pidm;
            }
            if(conMap.get(sb.pidm)!=null){
                faStdContact=conMap.get(sb.pidm).id;
                
            } 
            //get the opportunity from the map
            if (oppMap.get(faStdContact) != null)
            {
                faStdOpportunity = oppMap.get(faStdContact).id ;
              
            }

            if(sb.view!=''){
                faAppURL=sb.view;
            }
            if(sb.lastUpdatedDate !=''){
                faDate=sb.lastUpdatedDate;
            }
           if (faStdContact != null) 
           { 
               
                FinancialApplication__c faupsrt = new FinancialApplication__c(RecordTypeId = FinAppRT.Id, id=faId,Name=faName,
                                                                          Student__c=faStdContact, ApplicationURL__c=faAppURL,
                                                                          Opportunity__c = faStdOpportunity,
                                                                          ApplicationCSVFileLastUpdated__c=Date.parse(faDate));
                System.debug('Finapp created ==> '+sb.pidm); 
               finAppstoupload.add(faupsrt); } //upsert the application
           }
       
    }

   
    // Displaying the Page block table on VF page
    public List<FinancialApplication__c> getuploadedFinApps(){
        if (finAppstoupload!= NULL){
            if (finAppstoupload.size() > 0)
                return finAppstoupload;
            else
                return null;         
        }else{
            return null;
            }

    }
    //Creating the Financial Applications ans Financial Requirements
    public PageReference saveFinApps(){
         try{
           upsert finAppstoupload;
        }catch (Exception e){
            String tr=e.getMessage();
            Integer lineNum = e.getLineNumber();
            system.debug(tr);
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured in the app creation. Please check the template or try again later: ' + lineNum +  ' ' + tr);
            ApexPages.addMessage(errormsg );
            
        }
            //createRequirements(finAppstoupload);
            createRequirements(finAppstoupload);
        
         //Saving the document in Scholarship folder of Document Object
        Document document = new Document();
        document.AuthorId = UserInfo.getUserId();
        document.FolderId = [Select Id from Folder where DeveloperName ='Scholarship' and Type = 'Document'  LIMIT 1].Id;
        document.body=contentFile;
        document.Name=nameFile;
        document.Type='csv';
        insert document;
        integer count=finAppstoupload.size();
        lstScrship=null;
        finAppstoupload=null;
        lstFR=null;
        ApexPages.Message succemsg = new ApexPages.Message(ApexPages.severity.INFO,count+'  '+'Applications Successfully Submitted');
        ApexPages.addMessage(succemsg);
        //PageReference pf=new PageReference('/apex/Scholorship?cnt='+count);
        //pf.setredirect(false);
        //return pf;
        
            return null;
    }    
    
    public void createRequirements(list <FinancialApplication__c> finAppstoupload)
    {
        
        Set<Id> appIDSet=new Set<Id>();
        Id ReqID;
        map<String, ID> urlReqIdMap = new map<String, ID>();
        List<FinancialRequirement__c> reqListFinal = new List<FinancialRequirement__c>();
    //map the apps to upload    
        for(FinancialApplication__c fApp:finAppstoupload){
            system.debug('raavi0=========='+fApp.ApplicationURL__c);
            mapFinApp.put(fApp.ApplicationURL__c,fApp);
            appIDSet.add(fApp.Id); 
        }
        
         list<FinancialRequirement__c> exstReqs = [select FinancialApplication__c, ID ,
                                                   FinancialRequirement__c.TempID__c,
                                                   Requirement__c
                                                      from FinancialRequirement__c 
                                                      where FinancialApplication__c in :appIDSet ];
        for (FinancialRequirement__c exstReq : exstReqs  )
        {
            urlReqIdMap.put (exstReq.TempId__c + exstReq.Requirement__c, exstReq.id);
        }
        
        //loop  through and add the app ID and Record id if it exists
        for (FinancialRequirement__c req : reqList)
        {
               
               if (urlReqIdMap.get(req.TempId__c + req.Requirement__c) != null) //if the requirement already exists just update the status
               {
                   reqId = urlReqIdMap.get(req.TempId__c + req.Requirement__c);
                   FinancialRequirement__c exstReq = new FinancialRequirement__c(id=reqID, 
                                                                                RequirementsStatus__c = req.RequirementsStatus__c,
                                                                                RequirementURL__c =req.RequirementURL__c);
                   reqListFinal.add(exstReq);
               }
               else
               {
                   system.debug('raavi============='+mapFinApp);
                   system.debug('raavi1============='+Req.TempId__c);
                   system.debug('raavi2============='+mapFinApp.get(Req.TempId__c));
                   if(mapFinApp!= null && Req.TempId__c!= null && mapFinApp.get(Req.TempId__c)!=null){
                   req.FinancialApplication__c =mapFinApp.get(Req.TempId__c).id; //get the tempid/url 
                   reqlistFinal.add(req); //if not create the entire record from the original record
                  }
               }
        }
        
        upsert reqlistFinal;
        reqList = new List<FinancialRequirement__c>(); //clear list
        
    }
 
    
 // Wrapper class to display page block on VF Page
    public class ScholarshipBean{
        public String pidm{get;set;}
        public String lastUpdatedDate{get;set;}
        public String view{get;set;}
        public String employmentNoAFlag{get;set;}
        public String document{get;set;}
        public String resume{get;set;}
        public String agi{get;set;}
        public String name{get;set;}
        public String membership{get;set;}
        public String military{get;set;}
        public String militaryDoc{get;set;}
        public String lor{get;set;}
    }           
}