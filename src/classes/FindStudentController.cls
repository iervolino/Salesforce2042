/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date February 13, 2013 @ 1420hrs
 * Revised: Person Account Refactor - Paul Coleman 
 * 
 * Date October 30, 2012 @ 1130 hrs
 * Revised: (security audit compliance: with sharing) 
 * 
 */
public with sharing class FindStudentController {

    @RemoteAction
    public static String searchSSN( String ssn, Boolean isLast4 ) {
    
        List<StudentSearchHash__c> students = new List<StudentSearchHash__c>();
        if ( isLast4 ) {
          students = [SELECT count() FROM StudentSearchHash__c WHERE SSNLastFour__c = :Integer.ValueOf(ssn)]>0? [SELECT Id, Name, Student__c, Student__r.Name, Student__r.FirstName,Student__r.LastName, Student__r.ProgramCode__c, Student__r.ProgramName__c, Student__r.MailingCity, Student__r.MailingState,Student__r.RecordType.Name FROM StudentSearchHash__c WHERE SSNLastFour__c = :Integer.ValueOf(ssn)  LIMIT 200]: new List<StudentSearchHash__c>();
        } else { 
          String ssnHash = EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( ssn ) ) );
          students = [SELECT count() FROM StudentSearchHash__c WHERE SSNHash__c = :ssnHash]>0? [SELECT Id, Name, Student__c, Student__r.Name,Student__r.FirstName,Student__r.LastName, Student__r.ProgramCode__c, Student__r.ProgramName__c, Student__r.MailingCity, Student__r.MailingState,Student__r.RecordType.Name FROM StudentSearchHash__c WHERE SSNHash__c = :ssnHash  LIMIT 200]: new List<StudentSearchHash__c>();
        }
        for( StudentSearchHash__c hash: students ){
            hash.Name = hash.Student__r.LastName + ', ' +hash.Student__r.FirstName; 
        }
        return  JSONUtil.getJSON(students);
    }
    
    @RemoteAction
    public static String searchBirthDate( String birthdate ) {
        
        List<StudentSearchHash__c> students = new List<StudentSearchHash__c>();
        Date bDate = Date.parse(birthdate);
        String bdateHash = EncodingUtil.base64Encode( Crypto.generateDigest( 'SHA1', Blob.valueOf( bDate.format() ) ) );
        students = [SELECT count() FROM StudentSearchHash__c WHERE BirthDateHash__c = :bdateHash ]>0? [SELECT Id, Name, Student__c, Student__r.Name, Student__r.FirstName, Student__r.LastName, Student__r.ProgramCode__c, Student__r.ProgramName__c, Student__r.MailingCity, Student__r.MailingState,Student__r.RecordType.Name FROM StudentSearchHash__c WHERE BirthDateHash__c = :bdateHash  LIMIT 500]: new List<StudentSearchHash__c>();
        for( StudentSearchHash__c hash: students ){
          hash.Name = hash.Student__r.LastName + ', ' +hash.Student__r.FirstName; 
        }
        
        return JSONUtil.getJSON(students);
    }
    
}