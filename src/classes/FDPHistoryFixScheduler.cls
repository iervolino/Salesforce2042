global class FDPHistoryFixScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        LIST<AggregateResult> count=[select count(id) cnt from studentcompletioncourse__C where lastmodifieddate>Yesterday];
        if( (integer)count[0].get('cnt')>200000){
        String query = 'select id from studentcompletioncourse__C where lastmodifieddate<Yesterday order by student__C ';
        Database.executeBatch(new BatchFixForHistory(query),20);
        }
    }
   
}