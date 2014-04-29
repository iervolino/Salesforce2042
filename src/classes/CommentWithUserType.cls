public class CommentWithUserType {
        
    public ConnectApi.Comment comment { get; set; }
    public boolean isStudent { get; set; }
    public boolean question { get; set; }
    public boolean questionAnswered { get; set; }
    
    public CommentWithUserType(ConnectApi.Comment comment, boolean isStudent, boolean question, boolean questionAnswered) {
        this.comment = comment;
        this.isStudent = isStudent;
        this.question = question;
        this.questionAnswered = questionAnswered;
    }
    
    public String getFormattedPostTime() {
        if(comment == null) {
         	return null;   
        }
        return comment.createdDate.format('MM/dd/yy \'at\' hh:mm a');  
    }
    
    public ConnectApi.ContentAttachment getContentAttachment() {
        if(comment.attachment == null) {
            return null;
        }
        return (ConnectApi.ContentAttachment)comment.attachment;
    }
    
    public Boolean getHasPreview() {
        ConnectApi.ContentAttachment attachment = getContentAttachment();
        if(attachment == null) {
            return null;
        }
        return attachment.hasImagePreview || attachment.hasPdfPreview;
    }
    
    public String getHumanReadableFileSize() {
        ConnectApi.ContentAttachment attachment = (ConnectApi.ContentAttachment)comment.attachment;
        Integer size = Integer.valueOf(attachment.filesize);
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