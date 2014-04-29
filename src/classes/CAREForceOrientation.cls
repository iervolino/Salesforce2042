public class CAREForceOrientation {
//
    public static void createOrientation(Map<Id,Opportunity> optyMap) 
    {    
    for (Opportunity o:optyMap.values())
    {
        Orientation__c orient = new Orientation__c(
          Name=(o.Name+' Orientation'),
          CARE_Profile__c=o.id
        );
       
    try {
      insert orient;  
    } catch (Dmlexception e) {
        System.debug('The following exception occurred: ' + e);
        }
    } //end for-loop      
  } //end class
} //end trigger