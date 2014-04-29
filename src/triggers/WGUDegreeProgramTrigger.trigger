trigger WGUDegreeProgramTrigger on WGUDegreeProgram__c (after insert) {

    // If New Version of Program added, then create a new CARE Program Code Reference and deactivate the old one.
    if (Trigger.isAfter && Trigger.isInsert){     
        List<String> programCodes = new List<String>();
        
        for (WGUDegreeProgram__c program : Trigger.new) {
            if (program.Active__c)
                programCodes.add(program.Name);
        }

        if ([SELECT count() FROM CAREProgramMiddleEarth__c WHERE Active__c = true AND BannerProgramCode__r.Name in :programCodes AND BannerProgramCode__r.Active__c = true] > 0) {
            CAREforceUtility.addNewProgramVersions(JSON.serialize(Trigger.new));
        }
    }

}