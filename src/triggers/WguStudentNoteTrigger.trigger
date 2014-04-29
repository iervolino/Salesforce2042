/*
 * Author Paul Stay
 * Date 11 October 2012
 * Western Governors University @2012
 * 
 * This should really only be needed on bulk loads.
 */

trigger WguStudentNoteTrigger on WGUStudentNote__c (before insert, after update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate ) ) {
      if (true) { //missing count clause
         WguStudentNoteUtility.triggerWguStudentNote( Trigger.new);
      }   
    }
}