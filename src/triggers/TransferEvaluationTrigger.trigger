/***************************************************************************************************************
*
* Purpose: Create TranscriptToBanner records via call to TransferEvaluationUtility class
* Author: Will Slade
* Revisions:
*     4-16-2013 - Created Trigger
*
****************************************************************************************************************/

trigger TransferEvaluationTrigger on TransferEvaluation__c (After Insert, After Update) 
{
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {
        List<TransferEvaluation__c> trEvalList = new List<TransferEvaluation__c>();
        
        //Find evaluations that are Sent or Complete           
        for (TransferEvaluation__c trEval : [SELECT Id FROM TransferEvaluation__c WHERE EvaluationStatus__c IN ('Sent') AND Id IN :Trigger.new])
        {
            if (!(Trigger.oldMap.get(trEval.Id).EvaluationStatus__c.equals('Sent')) && !(Trigger.oldMap.get(trEval.Id).EvaluationStatus__c.equals('Complete')))
            {
                trEvalList.add(trEval);
            }
        }
        
        //Make call to utility class
        if (trEvalList.size() > 0)
        { 
            TransferEvaluationUtility.createTranscriptsToBanner(JSON.serialize(trEvalList));
        }       
    }
}