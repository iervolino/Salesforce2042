/*Case Controller Extension Created to manage the quick case functionality
 * Author Mike Slade
 * Western Governors University 
 *
 * Date Feb 20 2013
 * Modified 09/27/2013 - Added Student Task Attempt to the case.
 */
public class QuickCaseController{

    private contact cont {get;set;}
    private string contactId {get;set;}
    private string caseId {get;set;}
    private string objectId {get;set;}
    private string testVal {get;set;}
    private string caseTag {get;set;}
    string recordType;
    public string queueName;
    id ownerId;
    
    public QuickCaseController(ApexPages.StandardController controller)
    {
        this.cont = [select id from contact where id =:ApexPages.CurrentPage().getParameters().get('ContactId')];
        contactID =cont.id;
        objectId = ApexPages.CurrentPage().getParameters().get('ObjectId');
        recordType =ApexPages.CurrentPage().getParameters().get('RecordType');
        queueName =ApexPages.CurrentPage().getParameters().get('QueueName');
        //testVal = 'Initial';
    }
    
    public void createCase()
    {
        ID RtId;
         try
       {
         if (recordType != null)
          RtId = [select id from recordType where sObjectType='Case' and name = :RecordType].id;
           
         if (queueName !=null) //get the queue ID if queue specified, else use the current user for owner
            ownerId=[Select id From QueueSobject where Queue.Name=:queueName].id;
         else
            ownerId=UserInfo.getUserId();
       }
       catch(exception exp)
       {
           testVal = 'Invalid Record Type or Queue Name'; 
           return;
       }
       
      Try
      {
        //check to see if there is already a case for this user and this person in progress for accidental page refreshes or unfinished emails
        list<case> ExistingCase = [select id,refTag__c from case 
                                   where ownerId = :OwnerId 
                                   and contactId=:cont.id 
                                   and QuickCase__c=true 
                                   and Status = 'New'];
          
        if (ExistingCase.size() >0 ) 
        {   
         if (RtID !=ExistingCase[0].recordTypeId )//update the record type if different
         {
             ExistingCase[0].recordTypeId=RtID;
             update existingCase[0];
         }
         caseID=ExistingCase[0].id;
         caseTag=ExistingCase[0].refTag__c;
        }
        else
        {
            Case newCase;
        //if no case exists, create one with the quick case flag set to true
         	list<case> Cases = new list<case>();
            if (recordType != null)
        	   newCase = new Case(contactid =cont.id , Subject='Outgoing Message', recordTypeid=RtId, QuickCase__c=true, ownerId=this.ownerId) ;  
            else
               newCase = new Case(contactid =cont.id , Subject='Outgoing Message', QuickCase__c=true, ownerId=this.ownerId) ; //let the default record type
                
			insert newCase ;  
        	caseId =newCase.id;
            caseTag  = [select refTag__c from case where Id=:caseId limit 1].refTag__c;
        }
        
       caseTag = '<BR/> ' + caseTag ;
        //if linked to an object make that link
		if (objectID != null)
        {
           Case currCase = [SElECT Id, 
                                    FieldExperienceProcess__c,
                                    FieldExperience__c,
                                    TransferEvaluation__c,
                                    FinancialApplication__c,
                                    FinancialAward__c,
                                    TeacherSuccess__c,
                                    StudentProcess__c,
                            		StudentTaskAttempt__c
                             FROM Case 
                             WHERE Id = :caseId 
                             LIMIT 1];
            
            currCase = InboundEmailHandler.attachParentObject(currCase, ObjectID);
            //testVal =currCase.TeacherSuccess__c;
        }
       }
        catch(Exception e)
       {
            String tr=e.getMessage();
            Integer lineNum = e.getLineNumber();
            system.debug(tr);
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Error Occurred in Case Creation ' + lineNum +  ' ' + tr);
            ApexPages.addMessage(errormsg )  ;  
       }
        
    }  
    
    public string getCaseID()   { return this.caseId; }
    public string getCaseTag() {return this.caseTag;}
    public string getObjectId() {return this.objectId;}
    public string getContactId() {return this.contactId;}
    public string getTestVal() {return this.testVal;}
    
  	
}