public class SynchronizeToBannerLogUtilities {
    private List<SynchronizeToBannerLog__c> records = new List<SynchronizeToBannerLog__c>();

    public void add(String type, String id, String error) {
        records.add(new SynchronizeToBannerLog__c(ReferenceType__c = type, ReferenceId__c = id, SynchronizationError__c = error));
    }
    
    public void save() {
        insert records;
    }
}