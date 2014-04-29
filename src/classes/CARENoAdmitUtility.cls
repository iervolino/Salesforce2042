public with sharing class CARENoAdmitUtility
{
    public static void cancelTransferEvals(String evalsToCancelJSON)
    {
        cancelTransferEvals(evalsToCancelJSON, !Test.isRunningTest());
    }    

    public static void cancelTransferEvals(String evalsToCancelJSON, boolean runFuture)
    {
        if (Test.isRunningTest() && runFuture == false)
        {
            processCancelTransferEvals(evalsToCancelJSON);
        }
        else
        {
            try
            {
                asyncCancelTransferEvals(evalsToCancelJSON);
            }
            catch (System.AsyncException e)
            {
                if (e.getMessage().contains('Future method cannot be called from a future'))
                {
                    processCancelTransferEvals(evalsToCancelJSON);
                }
                else
                {
                    throw e;
                }
            }
        }
    }        
    
    @future
    private static void asyncCancelTransferEvals(String evalsToCancelJSON)
    {
        processCancelTransferEvals(evalsToCancelJSON);
    }   
     
    private static void processCancelTransferEvals(String evalsToCancelJSON) 
    {   
        List<TransferEvaluation__c> evalsToCancel = (List<TransferEvaluation__c>)JSON.deserialize( evalsToCancelJSON, List<TransferEvaluation__c>.class );                       
        
        for (TransferEvaluation__c eval : evalsToCancel)
        {
            eval.EvaluationStatus__c = 'Canceled';  
        }
        
        update evalsToCancel;  
    }               
}