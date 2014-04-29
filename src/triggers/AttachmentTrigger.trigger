trigger AttachmentTrigger on Attachment (after delete) 
{
    if (Trigger.isDelete && Trigger.isAfter)
    {
        List<Attachment> recordsOfInterest = new List<Attachment>();
        for (Attachment a : Trigger.old)
        {
            if (String.valueOf(a.ParentId).startsWith('a0U') || (a.name.IndexOf('SavedTransferEvaluation') != -1 && a.name.IndexOf('.pdf') != -1))
            {
                recordsOfInterest.add(a);
            }
        }
        if (recordsOfInterest.size() > 0)
        {
            // Get the current user's profile name
            List<Profile> prof = [select Name from Profile where Id = :UserInfo.getProfileId() LIMIT 1];
            
            // If current user is not a System Administrator, do not allow Attachments to be deleted
            if (prof.size() > 0)
            {
                if (!'System Administrator'.equalsIgnoreCase(prof[0].Name)) 
                {
                    for (Attachment a : recordsOfInterest) 
                    {
                        a.addError('You do not have permission to delete attachments.');
                    }   
                }
            }
            else
            for (Attachment a : recordsOfInterest) 
            {
                a.addError('You do not have permission to delete attachments.');
            } 
        }
    }
}