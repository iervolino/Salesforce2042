/*
 * Author Paul Coleman
 * Western Governors University 
 *
 * Created Aug 1 2013 @ 1320 hrs

 * StudentAttributes__c object's Trigger class
 *
 */
trigger StudentAttributesTrigger on StudentAttributes__c (after insert, after update) 
{
    
    //Create StudentAttributesToBanner__c records
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) )  
    {  
        List<StudentAttributes__c> saList = [SELECT Id FROM StudentAttributes__c WHERE Id IN :Trigger.new AND StudentContact__r.PIDM__c != null AND StudentContact__r.PIDM__c != ''];
        if(StudentAttributesUtility.firstRun == true && saList.size() > 0)
        {
            StudentAttributesUtility.createStudentAttributesToBanner ( JSON.serialize(saList) );
            StudentAttributesUtility.firstRun = false;
        }
    }       
}