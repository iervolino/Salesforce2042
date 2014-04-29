/*
 * Author: Jordan Paul
 * Slalom Consulting
 *
 * Date Mar 19 2013 @ 14:00 hrs 
 *
 * Quality Assurance object Utility class
 *
 */

global class QualityAssuranceUtility{
    
    //Search method for "Link Student Process" button
	WebService static void SearchForSP (id associateID, Date auditMonth, id auditId) {
        
        List<StudentProcess__c> selectedSP = new List<StudentProcess__c>();
       	List<StudentProcess__c> finalSP = new List<StudentProcess__c>();
        Set<StudentProcess__c> toUpdate = new Set<StudentProcess__c>();
        
        Integer[] listSelection = new List<Integer>();
        
        Integer month = auditMonth.month();
        Integer year = auditMonth.year();
        
        selectedSP = [SELECT ID, QualityAssurance__c, CreatedDate FROM StudentProcess__c WHERE (OwnerID=:associateID OR ProcessedBy__c=:associateID) and CALENDAR_YEAR(CreatedDate) =:year and CALENDAR_MONTH(CreatedDate) =:month];
        
        if(selectedSP.size()==0) {
        } else {
            /*
        if(selectedSP.size()<10) {
            Integer rnd1 = Math.round(Math.random()*selectedSP.size());
            if(rnd1==0){
                finalSP.add(selectedSP[rnd1]);
            } else{
            finalSP.add(selectedSP[rnd1-1]);
            listSelection.add(rnd1-1);
            }
        } else{
                do {
                    Integer rnd = Math.round(Math.random()*selectedSP.size());
                                if(rnd==0){
                                    finalSP.add(selectedSP[rnd]);
                                } else {
                                finalSP.add(selectedSP[rnd-1]);
                                listSelection.add(rnd-1);
                                }
            } while(listSelection.size() <= selectedSP.size());
        }*/
            for (StudentProcess__c sp: selectedSP) {
                finalSP.add(sp);
            }
        }
        
        for(StudentProcess__c c: finalSP) {
            c.QualityAssurance__c=auditId;
        }
        
        toUpdate.addAll(finalSP);
        finalSP.clear();
        finalSP.addAll(toUpdate);
        
        update finalSP;
        
    }
    
    
    //Search method for "Link Transfer Evaluations" button
    WebService static void SearchForTR (id associateID, Date auditMonth, id auditId) {
        
        List<TransferEvaluation__c> selectedTR = new List<TransferEvaluation__c>();
       List<TransferEvaluation__c> finalTR = new List<TransferEvaluation__c>();
        Set<TransferEvaluation__c> toUpdate = new Set<TransferEvaluation__c>();
        
        Integer[] listSelection = new List<Integer>();
        
        Integer month = auditMonth.month();
        Integer year = auditMonth.year();
        
        selectedTR = [SELECT ID, QualityAssurance__c, CreatedDate FROM TransferEvaluation__c WHERE AssignedTo__c=:associateID and CALENDAR_YEAR(CreatedDate) =:year and CALENDAR_MONTH(CreatedDate) =:month];
        
        if(selectedTR.size()==0) {
        } else {
        /*
		if(selectedTR.size()<10) {
            Integer rnd1 = Math.round(Math.random()*selectedTR.size());
            if(rnd1==0){
                finalTR.add(selectedTR[rnd1]);
            } else{
            finalTR.add(selectedTR[rnd1-1]);
            listSelection.add(rnd1-1);
            }
        } else{
                do {
                    Integer rnd = Math.round(Math.random()*selectedTR.size());
                                if(rnd==0){
                                    finalTR.add(selectedTR[rnd]);
                                } else {
                                finalTR.add(selectedTR[rnd-1]);
                                listSelection.add(rnd-1);
                                }
            } while(listSelection.size() <= (selectedTR.size()));
        }*/
            for (TransferEvaluation__c ca: selectedTR) {
                finalTR.add(ca);
            }
        }
        
        for(TransferEvaluation__c c: finalTR) {
            c.QualityAssurance__c=auditId;
        }
        
        toUpdate.addAll(finalTR);
        finalTR.clear();
        finalTR.addAll(toUpdate);
        
        update finalTR;
        
    }
    
    //Search method for "Link Cases" button
    WebService static void SearchForCase (id associateID, Date auditMonth, id auditId) {
        
        List<Case> userCase = new List<Case>();
        List<Case> selectedCases = new List<Case>();
       List<Case> finalCases = new List<Case>();
        Set<Case> toUpdate = new Set<Case>();
        
        Integer[] listSelection = new List<Integer>();
        
        Integer month = auditMonth.month();
        Integer year = auditMonth.year();
        
        userCase = [SELECT ID, QualityAssurance__c, CreatedDate, ClosedDate, RecordTypeId FROM Case WHERE OwnerID=:associateID and CALENDAR_YEAR(CreatedDate) =:year and CALENDAR_MONTH(CreatedDate) =:month];
        RecordType rtypeid1 = [select Id from RecordType where Name = 'Academic Services' and SobjectType = 'Case'];
        RecordType rtypeid2 = [select Id from RecordType where Name = 'Graduation' and SobjectType = 'Case'];
        RecordType rtypeid3 = [select Id from RecordType where Name = 'Program Change' and SobjectType = 'Case'];
        RecordType rtypeid4 = [select Id from RecordType where Name = 'Records' and SobjectType = 'Case'];
        RecordType rtypeid5 = [select Id from RecordType where Name = 'Scores' and SobjectType = 'Case'];
        RecordType rtypeid6 = [select Id from RecordType where Name = 'Term Break' and SobjectType = 'Case'];
        RecordType rtypeid7 = [select Id from RecordType where Name = 'Transcripts' and SobjectType = 'Case'];
        RecordType rtypeid8 = [select Id from RecordType where Name = 'Withdrawal' and SobjectType = 'Case'];
        for(Case ca: userCase) {
            if(ca.RecordTypeId==rtypeid8.id || ca.RecordTypeId==rtypeid7.id || ca.RecordTypeId==rtypeid6.id || ca.RecordTypeId==rtypeid5.id || ca.RecordTypeId==rtypeid4.id || ca.RecordTypeId==rtypeid3.id || ca.RecordTypeId==rtypeid2.id || ca.RecordTypeId==rtypeid1.id) {
                if(ca.ClosedDate==null) {
                    selectedCases.add(ca);
                } else {
                    if((ca.CreatedDate.getTime()-ca.ClosedDate.getTime())>0.0139d) {
                        selectedCases.add(ca);
                    }
                }
            }
        }
        if(selectedCases.size()==0) {
        } else {
        
            /*
			if(selectedCases.size()<10) {
            Integer rnd1 = Math.round(Math.random()*selectedCases.size());
            if(rnd1==0){
                finalCases.add(selectedCases[rnd1]);
            } else{
            finalCases.add(selectedCases[rnd1-1]);
            listSelection.add(rnd1-1);
            }
        } else{
                do {
                    Integer rnd = Math.round(Math.random()*selectedCases.size());
                                if(rnd==0){
                                    finalCases.add(selectedCases[rnd]);
                                } else {
                                finalCases.add(selectedCases[rnd-1]);
                                listSelection.add(rnd-1);
                                }
            } while(listSelection.size() <= (selectedCases.size()));
        }*/
            for (Case i : selectedCases) {
                finalCases.add(i);
            }
        }
        
        for(Case c: finalCases) {
            c.QualityAssurance__c=auditId;
        }
        
        toUpdate.addAll(finalCases);
        finalCases.clear();
        finalCases.addAll(toUpdate);
        
        update finalCases;
        
    }
}