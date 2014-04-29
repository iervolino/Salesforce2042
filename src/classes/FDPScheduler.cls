global class FDPScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        String termcode = generateTermCode(
          Date.Today().addMonths(-6)
        );
        String query = 'select Id '
          + ' from StudentCourseRegistration__c '
          + ' where TermCode__c <= \'' + termcode + '\' ';
        Database.executeBatch(new BatchDelete(query));
    }
     public static String generateTermCode(Date termStart) {
        String code;
        Integer month = termStart.month();

        // Term name is term code 'yyyyMM'.
        if (month < 10)
            code = String.valueOf(termStart.year()) + '0' + String.valueOf(month);
        else
            code = String.valueOf(termStart.year()) + String.valueOf(month);

        return code;
    }
}