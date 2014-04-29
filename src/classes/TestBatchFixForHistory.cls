@istest
private class TestBatchFixForHistory {

@istest static void testbatchfix(){
        
            String query = 'select id from studentcompletioncourse__C where lastmodifieddate<Yesterday order by student__C limit 100 ';
            Database.executeBatch(new BatchFixForHistory(query));
       
        }
}