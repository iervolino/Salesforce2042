/*****************************************************************************************
* Name: EvalCreateEquivalentsTrigger
* Author: Will Slade
* Initial Purpose: Creates equivalent courses for student based on evaluation criteria entered
* Revisions: 
*    - 9/1/12 Created Trigger
*    - 2/6/13 Updated to find the most current version of the WGU Program - Will Slade
******************************************************************************************/

trigger EvalCreateEquivalentsTrigger on TransferEvaluation__c (after insert) 
{
    List<TransferEvaluation__c> evals = [SELECT Id, WGUDegreeProgram__c, Opportunity__r.MarketingProgram__c, Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name
                                         FROM TransferEvaluation__c 
                                         WHERE Id IN :Trigger.new
                                         LIMIT 1000];
    Map<Id, Id> evalToProgramCrosswalk = new Map<Id, Id>();
    Map<Id, Id> marketingToWGUProgram = new Map<Id, Id>();
    Map<Id, Id> evalToWGUProgram = new Map<Id, Id>();  
    List<String> bannerProgramTitles = new List<String>();
    Map<Id, String> wguProgIdToVersion = new Map<Id, String>();
    Map<Id, String> wguProgIdToTitle = new Map<Id, String>();
    Map<String, Id> wguProgTitleToId = new Map<String, Id>();
    
    // Get titles of all WGUDegreePrograms tied to these records
    for (TransferEvaluation__c eval : evals)
    {
        bannerProgramTitles.add(eval.Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name);
    }
    
    // Get all WGU Degree Programs with titles matching those in the trigger records in order to find the most current version
    List<WGUDegreeProgram__c> allPossibleWGUProgs = [SELECT Name, Id, Title__c, CatalogTerm__c FROM WGUDegreeProgram__c WHERE Active__c = true AND Name IN :bannerProgramTitles LIMIT 1000];
    
    // Populate intermediate maps to refine data to latest versions        
    for (WGUDegreeProgram__c wguProg : allPossibleWGUProgs)
    {
        wguProgIdToVersion.put(wguProg.Id, wguProg.CatalogTerm__c);
        wguProgIdToTitle.put(wguProg.Id, wguProg.Name);
    }
    
    // Build map tied to latest versions
    for (WGUDegreeProgram__c wguProg : allPossibleWGUProgs)
    {
        if(!wguProgTitleToId.containsKey(wguProg.Name))
        {
            wguProgTitleToId.put(wguProg.Name, wguProg.Id);
        }
        else if(wguProgIdToVersion.get(wguProgTitleToId.get(wguProg.Name)) < wguProg.CatalogTerm__c)
        {
            wguProgTitleToId.remove(wguProg.Name);
            wguProgTitleToId.put(wguProg.Name, wguProg.Id);
        }
    }
    
    // Map each Transfer Evaluation to its corresponding Marketing Program - most current version
    for (TransferEvaluation__c eval : evals)
    {
        evalToProgramCrosswalk.put(eval.Id, wguProgTitleToId.get(eval.Opportunity__r.MarketingProgram__r.BannerProgramCode__r.Name));
    }
    /*
    // Get a list of all Marketing Program IDs from the map
    List<Id> marketingPrograms = evalToProgramCrosswalk.values();        
    
    // Get a list of all the Crosswalk Programs that are tied to the list of Marketing Programs
    List<CareProgramMiddleEarth__c> crosswalkPrograms = [SELECT Id, CAREProgramCode__c, BannerProgramCode__c FROM CareProgramMiddleEarth__c WHERE Id IN :marketingPrograms LIMIT 1000];
    
    // Map the Marketing Programs to their corresponding WGU Programs
    for (CareProgramMiddleEarth__c crosswalkProgram : crosswalkPrograms)
    {
        if (!marketingToWGUProgram.ContainsKey(crosswalkProgram.Id))
        {
            marketingToWGUProgram.put(crosswalkProgram.Id, crosswalkProgram.BannerProgramCode__c);
        }
    }*/
    
    // Link the WGU Program to the Transfer Evaluation
    for (TransferEvaluation__c eval1 : evals)
    {
        if (eval1.WGUDegreeProgram__c == null)
        {
            eval1.WGUDegreeProgram__c = evalToProgramCrosswalk.get(eval1.Id); //marketingToWGUProgram.get(eval1.Opportunity__r.MarketingProgram__c);           
        }        

        evalToWGUProgram.put(eval1.Id, eval1.WGUDegreeProgram__c);
    }  

    List<WGUCourseInProgram__c> testCIP = [SELECT Id, Name, Program__c FROM WGUCourseInProgram__c];  
    
    // Find transferrable courses for programs
    List<WGUCourseInProgram__c> coursesInProgram = 
            [SELECT Id, Course__c, Program__c, Course__r.CompetencyUnits__c, TransferRule__c, Program__r.Name  
             FROM WGUCourseInProgram__c 
             WHERE Program__c IN :evalToProgramCrosswalk.values()
             AND Transferable__c = True
             LIMIT 10000];
    
    List<StudentEquivalentCourse__c> courses = new List<StudentEquivalentCourse__c>();
    
    // Create and insert new student equivalent courses         
    for (WGUCourseInProgram__c courseInProgram : coursesInProgram)
    {   
        for (TransferEvaluation__c eval2 : evals)
        {        
            if (courseInProgram.Program__c == evalToProgramCrosswalk.get(eval2.Id))
            {            
                StudentEquivalentCourse__c newCourse = new StudentEquivalentCourse__c(TransferEvaluation__c = eval2.Id, WGUCourseInProgram__c = courseInProgram.Id);
                courses.add(newCourse);              
            }    
        }   
    }    
    insert courses; 
    update evals;                                       
}