@isTest
private with sharing class TestQualityAssuranceUtility{
    
    //Test SearchForSP method
    //Created by Kristin Hasna 2013.12.10
    //Updated by Dave Manwaring 2014.04.15 to fix Kristin's test user.  Changed from "Kristin Hasna" to Profile.Name='System Administrator'
    private static testmethod void testSearchForSP () {
        
        ID spRecordID = [Select Id From RecordType Where SobjectType = 'StudentProcess__c' and Name = 'Withdrawal'].Id;
        ID rTypeId = [Select Id From RecordType Where SobjectType = 'Contact' and Name = 'StudentRecord'].Id;
        
        Contact a = new Contact(LastName='TestName');
        a.RecordTypeId = rTypeId;
        insert a;
        
        System.assert(a.AccountId == null, 'Account creation trigger not working.');
        
        Opportunity o = new Opportunity();
        o.Name = 'Run1';
        o.AccountID = a.Account.id;
        o.StageName = 'Prospect';
        o.CloseDate = Date.today();
        insert o;
        
        Date d = Date.today();
        Integer i;
        List<StudentProcess__c> spinsert = new List<StudentProcess__c>();
        User u = [SELECT ID FROM User WHERE Profile.name='System Administrator' and IsActive=TRUE LIMIT 1];
        for (i = 0; i < 5; i++) {
            StudentProcess__c sp = new StudentProcess__c();
            sp.Account__c=a.AccountId;
            sp.Name='TestMe'+i;
            sp.OwnerId=u.id;
            spinsert.add(sp);
        }
        
        insert spinsert;
        spinsert.clear();
        
        
        QualityAssurance__c qa = new QualityAssurance__c(Employee__c=u.id,DateOfAudit__c=d);
        insert qa;
        
        List<StudentProcess__c> updatedSP = new List<StudentProcess__c>();
        
        System.RunAs(u){
               Test.startTest(); 
        QualityAssuranceUtility.SearchForSP(qa.Employee__c,qa.DateOfAudit__c,qa.id);
        
        updatedSP=[SELECT ID, QualityAssurance__c FROM StudentProcess__c WHERE QualityAssurance__c=:qa.id];
        for(StudentProcess__c sp1: updatedSP) {
            System.assert(sp1.QualityAssurance__c != null, 'Null value found');
        }
        updatedSP.clear();
            
        }
        
        
        for (i = 0; i < 25; i++) {
            StudentProcess__c sp = new StudentProcess__c();
            sp.Account__c=a.AccountId;
            sp.Name='TestAgain'+i;
            sp.OwnerId=u.id;
            spinsert.add(sp);
        }
        
        insert spinsert;
        
        System.RunAs(u) {
        
        QualityAssuranceUtility.SearchForSP(qa.Employee__c,qa.DateOfAudit__c,qa.id);
        
        updatedSP=[SELECT ID, QualityAssurance__c FROM StudentProcess__c WHERE QualityAssurance__c=:qa.id];
        for(StudentProcess__c sp1: updatedSP) {
            System.assert(sp1.QualityAssurance__c != null, 'Null value found');
        }
            Test.stopTest();
        }
    }
    
    //Test SearchForTR method
    private static testmethod void testSearchForTR () {
        
        ID rTypeId = [Select Id From RecordType Where SobjectType = 'Contact' and Name = 'StudentRecord'].Id;
        
        Contact a = new Contact(LastName='TestName');
        a.RecordTypeId = rTypeId;
        insert a;
        
        System.assert(a.AccountId == null, 'Account creation trigger not working.');
        
        Opportunity o = new Opportunity(Name='Run1', AccountID=a.AccountId, StageName='Prospect',CloseDate=Date.today());
        insert o;
        
        Date d = Date.today();
        Integer i;
        List<TransferEvaluation__c> trinsert = new List<TransferEvaluation__c>();
        User u = [SELECT ID FROM User WHERE Profile.name='System Administrator' AND IsActive=TRUE LIMIT 1];
        for (i = 0; i < 5; i++) {
            TransferEvaluation__c tr = new TransferEvaluation__c();
            tr.Opportunity__c=o.id;
            tr.EvaluationType__c='Transfer Evaluation';
            tr.EvaluationStatus__c='Ready for Evaluation';
            tr.Name='TestMe'+i;
            tr.AssignedTo__c=u.id;
            trinsert.add(tr);
        }
        
        insert trinsert;
        trinsert.clear();
        
        
        QualityAssurance__c qa = new QualityAssurance__c(Employee__c=u.id,DateOfAudit__c=d);
        insert qa;
        List<TransferEvaluation__c> updatedTR = new List<TransferEvaluation__c>();
        
        System.RunAs(u) {
            Test.startTest();
        QualityAssuranceUtility.SearchForTR(qa.Employee__c,qa.DateOfAudit__c,qa.id);
        
        updatedTR=[SELECT ID, QualityAssurance__c FROM TransferEvaluation__c WHERE QualityAssurance__c=:qa.id];
        for(TransferEvaluation__c tr1: updatedTR) {
            System.assert(tr1.QualityAssurance__c != null, 'Null value found');
        }
        
            updatedTR.clear();
            
        }
        
        for (i = 0; i < 25; i++) {
            TransferEvaluation__c tr = new TransferEvaluation__c();
            tr.Opportunity__c=o.id;
            tr.EvaluationType__c='Transfer Evaluation';
            tr.EvaluationStatus__c='Ready for Evaluation';
            tr.Name='TestMe'+i;
            tr.AssignedTo__c=u.id;
            trinsert.add(tr);
        }
        
        insert trinsert;
        
        System.RunAs(u) {
            
        QualityAssuranceUtility.SearchForTR(qa.Employee__c,qa.DateOfAudit__c,qa.id);
        
        updatedTR=[SELECT ID, QualityAssurance__c FROM TransferEvaluation__c WHERE QualityAssurance__c=:qa.id];
        for(TransferEvaluation__c tr1: updatedTR) {
            System.assert(tr1.QualityAssurance__c != null, 'Null value found');
        }
            Test.stopTest();
        }
    }
    
    //Test for SearchForCase method
    private static testmethod void testSearchForCase () {
        
        ID CRecordID = [Select Id From RecordType Where SobjectType = 'Case' and Name = 'Withdrawal'].Id;
        ID rTypeId = [Select Id From RecordType Where SobjectType = 'Contact' and Name = 'StudentRecord'].Id;
        
        Contact a = new Contact(LastName='TestName');
        a.RecordTypeId = rTypeId;
        insert a;
        
        System.assert(a.AccountId == null, 'Account creation trigger not working.');
        
        Opportunity o = new Opportunity(Name='Run1', AccountID=a.AccountId, StageName='Prospect',CloseDate=Date.today());
        insert o;
        
        Date d = Date.today();
        Integer i;
        List<Case> cainsert = new List<Case>();
        User u = [SELECT ID FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        for (i = 0; i < 3; i++) {
            Case ca = new Case();
            ca.RecordTypeId=CRecordID;
            ca.Status='New';
            ca.Subject='TestMe'+i;
            ca.OwnerId=u.id;
            cainsert.add(ca);
        }
        for (i = 0; i < 5; i++) {
            Case ca = new Case();
            ca.RecordTypeId=CRecordID;
            ca.Status='Resolved';
            ca.Subject='TestMe'+i;
            ca.OwnerId=u.id;
            cainsert.add(ca);
        }
        
        insert cainsert;
        cainsert.clear();
        
        
        QualityAssurance__c qa = new QualityAssurance__c(Employee__c=u.id,DateOfAudit__c=d);
        insert qa;
        List<Case> updatedCA = new List<Case>();
        
        System.RunAs(u){
            Test.startTest();        
            
        QualityAssuranceUtility.SearchForCase(qa.Employee__c,qa.DateOfAudit__c,qa.id);
        
        updatedCA=[SELECT ID, QualityAssurance__c FROM Case WHERE QualityAssurance__c=:qa.id];
        for(Case ca1: updatedCA) {
            System.assert(ca1.QualityAssurance__c != null, 'Null value found');
        }
        updatedCA.clear();
            
        }
        
        for (i = 0; i < 25; i++) {
            Case ca = new Case();
            ca.RecordTypeId=CRecordID;
            ca.Status='New';
            ca.Subject='TestMe1'+i;
            ca.OwnerId=u.id;
            cainsert.add(ca);
        }
        
        insert cainsert;
        
        System.RunAs(u) {
            
        
        QualityAssuranceUtility.SearchForCase(qa.Employee__c,qa.DateOfAudit__c,qa.id);
        
        updatedCA=[SELECT ID, QualityAssurance__c FROM Case WHERE QualityAssurance__c=:qa.id];
        for(Case ca1: updatedCA) {
            System.assert(ca1.QualityAssurance__c != null, 'Null value found');
        }
            Test.stopTest();
    }
    }
}