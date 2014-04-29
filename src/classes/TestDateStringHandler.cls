/*
* Test class for DateStringHandler
* Katarina Melki 11/20/2013
*/
@IsTest
public class TestDateStringHandler
{
    //Test all 12 hour to 24 hour format conversion scenarios
	static testmethod void testConvert12to24()
    {
        Test.startTest();
        Test.stopTest();
        
        system.assert(DateStringHandler.convert12to24('01', 'PM')=='13');
        system.assert(DateStringHandler.convert12to24('12', 'AM')=='00');
        system.assert(DateStringHandler.convert12to24('12', 'PM')=='12');
        system.assert(DateStringHandler.convert12to24('1', 'AM')=='01');
    }
    
    //Test all 24 hour to 12 hour format conversion scenarios
    static testmethod void testConvert24to12()
    {
        String[] am01;
        String[] am12;
        String[] pm01;
        String[] pm12;
        
        Test.startTest();
        am01=DateStringHandler.convert24to12('01');
        am12=DateStringHandler.convert24to12('00');
        pm01=DateStringHandler.convert24to12('13');
        pm12=DateStringHandler.convert24to12('12');
        Test.stopTest();
        
        system.assert(am01[0]=='01');
        system.assert(am01[1]=='AM');
        system.assert(am12[0]=='12');
        system.assert(am12[1]=='AM');
        system.assert(pm01[0]=='01');
        system.assert(pm01[1]=='PM');
        system.assert(pm12[0]=='12');
        system.assert(pm12[1]=='pm');
    }
    
    //Test conversion of shift hours JSON to human readable format for both good and bad input
    static testmethod void testConvertOfficeHoursJSONtoString()
    {
        String testBad='Bad input';
        String testGood='{"Shift":[{"Start":{"Day":"MON","Time":"0900"},"End":{"Day":"MON","Time":"1700"},"Offset":"-7"},{"Start":{"Day":"TUE","Time":"0900"},"End":{"Day":"TUE","Time":"1700"},"Offset":"-5"},{"Start":{"Day":"WED","Time":"0915"},"End":{"Day":"WED","Time":"1730"},"Offset":"-6"},{"Start":{"Day":"THU","Time":"0915"},"End":{"Day":"THU","Time":"2245"},"Offset":"-8"},{"Start":{"Day":"FRI","Time":"0000"},"End":{"Day":"FRI","Time":"1200"},"Offset":"-7"},{"Start":{"Day":"SAT","Time":"0200"},"End":{"Day":"SUN","Time":"1100"},"Offset":"-7"}]}';
        String goodResult='MON 09:00 AM - MON 05:00 PM MST\nTUE 09:00 AM - TUE 05:00 PM EST\nWED 09:15 AM - WED 05:30 PM CST\nTHU 09:15 AM - THU 10:45 PM PST\nFRI 12:00 AM - FRI 12:00 PM MST\nSAT 02:00 AM - SUN 11:00 AM MST\n';
        
        Test.startTest();
        Test.stopTest();
        
        system.debug(DateStringHandler.convertOfficeHoursJSONtoString(testGood));
        system.assert(DateStringHandler.convertOfficeHoursJSONtoString(testBad)==testBad);
        system.assert(DateStringHandler.convertOfficeHoursJSONtoString(testGood)==goodResult);
    }
}