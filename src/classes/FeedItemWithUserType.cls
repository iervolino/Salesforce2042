public class FeedItemWithUserType {
        
    public ConnectApi.FeedItem feedItem { get; set; }
    public String shortenedFeedBody { get; set; }
    public boolean isStudent { get; set; }
    public List<CommentWithUserType> commentList { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public Boolean question { get; set; }
    public boolean questionAnswered { get; set; }
    
    public FeedItemWithUserType (ConnectApi.FeedItem feedItem, boolean isStudent, List<CommentWithUserType> commentList, String shortenedFeedBody,
            String firstName, String lastName, Boolean question, boolean questionAnswered) {
        this.feedItem = feedItem;
        this.isStudent = isStudent;
        this.commentList = commentList;
        this.shortenedFeedBody = shortenedFeedBody;
        this.firstName = firstName;
        this.lastName = lastName;
        this.question = question;
        this.questionAnswered = questionAnswered;
    }
    
    public String getFormattedPostTime() {
        if(feedItem == null) {
         	return null;   
        }
        return feedItem.createdDate.format('MM/dd/yy \'at\' hh:mm a');  
    }
    
    public String getAttachmentType() {
        if(feedItem == null) {
            return null;
        }
        
        if(feedItem.attachment == null) {
            return null;
        }
        
        ConnectApi.FeedItemAttachment attachment = feedItem.attachment;
        if(attachment instanceof ConnectApi.LinkAttachment) {
            return 'link';
        }
        else if(attachment instanceof ConnectApi.ContentAttachment) {
            return 'file';
        }
        return null;
    }
    
    public Boolean getHasPreview() {
        String attachmentType = getAttachmentType();
        if(attachmentType == null || !attachmentType.equals('file')) {
            return false;
        }
           
        ConnectApi.ContentAttachment attachment = (ConnectApi.ContentAttachment)feedItem.attachment;
        return attachment.hasImagePreview || attachment.hasPdfPreview;
    }
    
    public ConnectApi.ContentAttachment getContentAttachment() {
        if(feedItem.attachment instanceof ConnectApi.ContentAttachment) {
            return (ConnectApi.ContentAttachment)feedItem.attachment;
        }
        return null;
    }
    
    public ConnectApi.LinkAttachment getLinkAttachment() {
        if(feedItem.attachment instanceof ConnectApi.LinkAttachment) {
            return (ConnectApi.LinkAttachment)feedItem.attachment;
        }
        return null;
    }
    
    public String getHumanReadableFileSize() {
        Integer size = Integer.valueOf(getContentAttachment().filesize);
        Integer unit = 1024;
        if (size < unit) {
            return size + ' B';
        }
        Integer exp = (Integer)(Math.log(size) / Math.log(unit));
        String pre = ('KMGTPE').substring(exp-1, exp);
        Decimal dec = size / Math.pow(unit, exp);
        dec = dec.setScale(1);
        return String.format('{0}{1}B', new String[] {String.valueOf(dec), pre});
    }
    
}