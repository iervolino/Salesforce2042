@IsTest
public class CopyNotesAndAttachmentsUtilTest {

    @IsTest static void copyNotesAndAttachmentsTest_NullTo() {
        CopyNotesAndAttachmentsUtil.copyNotesAndAttachments('1', null);
    }
    
    @IsTest static void copyNotesAndAttachmentsTest_NullFrom() {
        CopyNotesAndAttachmentsUtil.copyNotesAndAttachments(null, '1');
    }
    
    @IsTest static void copyNotesTest_NullTo() {
        CopyNotesAndAttachmentsUtil.copyNotes('1', null);
    }
    
    @IsTest static void copyNotesTest_NullFrom() {
        CopyNotesAndAttachmentsUtil.copyNotes(null, '1');
    }
    
    @IsTest static void copyAttachmentsTest_NullTo() {
        CopyNotesAndAttachmentsUtil.copyAttachments('1', null);
    }
    
    @IsTest static void copyAttachmentsTest_NullFrom() {
        CopyNotesAndAttachmentsUtil.copyAttachments(null, '1');
    }

    @IsTest static void copyNotesAndAttachmentsTest() {
        StudentDisposition__c sd = new StudentDisposition__c();
        sd.studentId__c = '1';
        insert sd;
    
        Note n1 = new Note();
        n1.body = 'Note about something';
        n1.title = 'Note title';
        n1.parentId = sd.id;
        insert n1;
        
        Attachment a1 = new Attachment();
        a1.name = 'Attachment Name';
        a1.body = Blob.toPdf('Test');
        a1.parentId = sd.id;
        insert a1;
        
        CodeOfConductReferral__c cocr = new CodeOfConductReferral__c();
        cocr.StudentConcern__c = sd.id;
        insert cocr;
        
        Test.startTest();
        CopyNotesAndAttachmentsUtil.copyNotesAndAttachments(String.valueOf(sd.id), String.valueOf(cocr.id));
        Test.stopTest();
        
        List<Note> noteList = [SELECT Body, ParentId FROM Note WHERE parentId = :cocr.id];
        System.assertEquals(1,noteList.size());
        Note responseNote = noteList.get(0);
        System.assertEquals('Note about something', responseNote.body);
        System.assert(responseNote.id != n1.id, 'Note was not cloned correctly');
        
        List<Attachment> attachmentList = [SELECT Id, ParentId FROM Attachment WHERE ParentId = :cocr.id];
        System.assertEquals(1,attachmentList.size());
        Attachment responseAttachment = attachmentList.get(0);
        System.assert(responseAttachment.id != a1.id, 'Attachment was not cloned correctly');
    }
    
    @IsTest static void copyNotesTest() {
        StudentDisposition__c sd = new StudentDisposition__c();
        sd.studentId__c = '1';
        insert sd;
    
        Note n1 = new Note();
        n1.body = 'Note about something';
        n1.title = 'Note title';
        n1.parentId = sd.id;
        insert n1;
        
        Attachment a1 = new Attachment();
        a1.name = 'Attachment Name';
        a1.body = Blob.toPdf('Test');
        a1.parentId = sd.id;
        insert a1;
        
        CodeOfConductReferral__c cocr = new CodeOfConductReferral__c();
        cocr.StudentConcern__c = sd.id;
        insert cocr;
        
        Test.startTest();
        CopyNotesAndAttachmentsUtil.copyNotes(String.valueOf(sd.id), String.valueOf(cocr.id));
        Test.stopTest();
        
        List<Note> noteList = [SELECT Body, ParentId FROM Note WHERE parentId = :cocr.id];
        System.assertEquals(1,noteList.size());
        Note responseNote = noteList.get(0);
        System.assertEquals('Note about something', responseNote.body);
        System.assert(responseNote.id != n1.id, 'Note was not cloned correctly');
        
        List<Attachment> attachmentList = [SELECT Id, ParentId FROM Attachment WHERE ParentId = :cocr.id];
        System.assertEquals(0,attachmentList.size());
    }
    
    @IsTest static void copyAttachmentsTest() {
        StudentDisposition__c sd = new StudentDisposition__c();
        sd.studentId__c = '1';
        insert sd;
    
        Note n1 = new Note();
        n1.body = 'Note about something';
        n1.title = 'Note title';
        n1.parentId = sd.id;
        insert n1;
        
        Attachment a1 = new Attachment();
        a1.name = 'Attachment Name';
        a1.body = Blob.toPdf('Test');
        a1.parentId = sd.id;
        insert a1;
        
        CodeOfConductReferral__c cocr = new CodeOfConductReferral__c();
        cocr.StudentConcern__c = sd.id;
        insert cocr;
        
        Test.startTest();
        CopyNotesAndAttachmentsUtil.copyAttachments(String.valueOf(sd.id), String.valueOf(cocr.id));
        Test.stopTest();
        
        List<Note> noteList = [SELECT Body, ParentId FROM Note WHERE parentId = :cocr.id];
        System.assertEquals(0,noteList.size());
        
        List<Attachment> attachmentList = [SELECT Id, ParentId FROM Attachment WHERE ParentId = :cocr.id];
        System.assertEquals(1,attachmentList.size());
        Attachment responseAttachment = attachmentList.get(0);
        System.assert(responseAttachment.id != a1.id, 'Attachment was not cloned correctly');
    }
    
}