global class CopyNotesAndAttachmentsUtil {

    webservice static void copyNotesAndAttachments(String fromId, String toId) {
        if(String.isEmpty(fromId) || String.isEmpty(toId)) {
            return;
        }
        
        cloneNotes(fromId, toId);
        cloneAttachments(fromId, toId);      
    }
    
    webservice static void copyNotes(String fromId, String toId) {
        if(String.isEmpty(fromId) || String.isEmpty(toId)) {
            return;
        }
        
        cloneNotes(fromId, toId);  
    }
    
    webservice static void copyAttachments(String fromId, String toId) {
        if(String.isEmpty(fromId) || String.isEmpty(toId)) {
            return;
        }
        
        cloneAttachments(fromId, toId);      
    }
    
    private static void cloneNotes(String fromId, String toId) {
        List<Note> noteList = [SELECT Body,
                                      CreatedById,
                                      CreatedDate,
                                      IsDeleted,
                                      IsPrivate,
                                      LastModifiedById,
                                      LastModifiedDate,
                                      OwnerId,
                                      SystemModstamp,
                                      Title
                                 FROM Note
                                WHERE ParentId = :fromId];
                                
        List<Note> clonedNotes = new List<Note>();
        for(Note n : noteList) {
            Note clone = n.clone(false, true, true, true);
            clone.parentId = toId;
            clonedNotes.add(clone);
        }
        insert clonedNotes;
    }
    
    private static void cloneAttachments(String fromId, String toId) {
        List<Attachment> attachmentList = [SELECT Body,
                                                  BodyLength,
                                                  ConnectionReceivedId,
                                                  ConnectionSentId,
                                                  ContentType,
                                                  CreatedById,
                                                  CreatedDate,
                                                  Description,
                                                  IsDeleted,
                                                  IsPartnerShared,
                                                  IsPrivate,
                                                  LastModifiedById,
                                                  LastModifiedDate,
                                                  Name,
                                                  OwnerId,
                                                  SystemModstamp
                                             FROM Attachment
                                            WHERE parentId = :fromId];
                                            
        List<Attachment> clonedAttachments = new List<Attachment>();
        for(Attachment a : attachmentList) {
            Attachment clone = a.clone(false, true, true, true);
            clone.parentId = toId;
            clonedAttachments.add(clone);
        }
        insert clonedAttachments;
    }

}