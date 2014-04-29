public class UnhandledExceptionLogger {
  public String Application;
  public Integer LineNumber;
  public String Message;
  public String StackTrace;
  public String TypeName;
  public String ErrorCode;
  public String AdditionalInfo;
  private UnhandledException__c dbLog;

  public UnhandledExceptionLogger(Exception ex,String app,String additionalInfo) {
    this.Application = app;
    this.LineNumber = ex.getLineNumber();
    this.Message = ex.getMessage();
    this.StackTrace = ex.getStackTraceString();
    this.TypeName = ex.getTypeName();
    this.AdditionalInfo = additionalInfo;
    dbLog = new UnhandledException__c(
        Application__c = this.Application,
        LineNumber__c = this.LineNumber,
        Message__c = this.Message,
        StackTrace__c = this.StackTrace,
        TypeName__c = this.TypeName,
        AdditionalInfo__c = this.AdditionalInfo
    );
  }

  public void save() {
    insert dbLog;
    UnhandledException__c e = [select Id,Name from UnhandledException__c where Id = :dbLog.Id];
    this.ErrorCode = e.Name;
  }

  public static String logError(Exception ex,String app) {
    return logError(ex,app,'');
  }

  public static String logError(Exception ex,String app,String additionalInfo) {
    UnhandledExceptionLogger ue = new UnhandledExceptionLogger(ex,app,additionalInfo);
    ue.save();
    return ue.ErrorCode;
  }
}