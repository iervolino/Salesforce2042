/*
* Class for handling various date string conversions
*
* Katarina Melki 11/19/2013
*/

global with sharing class DateStringHandler
{
    //Takes the JSON representation of office shifts and converts to a human readable multi-line string
    @RemoteAction
    global static String convertOfficeHoursJSONtoString(String hoursJSON)
    {
        String officeHours='';
        
        //Verify the JSON string, return the original string if it is not valid
        if (hoursJSON.startsWith('{"Shift":[') && hoursJSON.contains('"Start"') && hoursJSON.contains('"End"') && hoursJSON.contains('"Day"') && hoursJSON.contains('"Time"') && hoursJSON.contains('"Offset"'))
        {
            for (String shift : hoursJSON.split('Start'))
            {
                if (shift.contains('Day'))
                {
                    system.debug('Shift: '+shift);
                    String[] shiftParts=shift.split(',');
                    
                    officeHours=officeHours+shiftParts[0].split(':')[2].replace('"', '').replace('}','').replace(']','')+' '+
                                convert24to12(shiftParts[1].split(':')[1].replace('"', '').replace('}','').replace(']','').substring(0, 2))[0]+':'+shiftParts[1].split(':')[1].replace('"', '').replace('}','').replace(']','').substring(2)+' '+
                                convert24to12(shiftParts[1].split(':')[1].replace('"', '').replace('}','').replace(']','').substring(0, 2))[1]+' - '+
                                shiftParts[2].split(':')[2].replace('"', '').replace('}','').replace(']','')+' '+
                                convert24to12(shiftParts[3].split(':')[1].replace('"', '').replace('}','').replace(']','').substring(0, 2))[0]+':'+shiftParts[3].split(':')[1].replace('"', '').replace('}','').replace(']','').substring(2)+' '+
                                convert24to12(shiftParts[3].split(':')[1].replace('"', '').replace('}','').replace(']','').substring(0, 2))[1]+' ';
                    
                    if (shiftParts[4].split(':')[1].replace('"', '').replace('}','').replace(']','')=='-5')
                    {
                        officeHours=officeHours+'EST\n';
                    }
                    else if (shiftParts[4].split(':')[1].replace('"', '').replace('}','').replace(']','')=='-6')
                    {
                        officeHours=officeHours+'CST\n';
                    }
                    else if (shiftParts[4].split(':')[1].replace('"', '').replace('}','').replace(']','')=='-7')
                    {
                        officeHours=officeHours+'MST\n';
                    }
                    else if (shiftParts[4].split(':')[1].replace('"', '').replace('}','').replace(']','')=='-8')
                    {
                        officeHours=officeHours+'PST\n';
                    }
                }
            }
        }
        else
        {
            return hoursJSON;
        }
        
        return officeHours;
    }
    
    //Converts 12 hour time format to 24 hour time format
    @RemoteAction
    global static String convert12to24(String hour, String half)
    {
        if (half=='PM' && hour!='12')
        {
            return String.valueOf(Integer.valueOf(hour)+12);
        }
        else if (half=='AM' && hour=='12')
        {
            return '00';
        }
        else
        {
            if (hour.length()==1)
            {
                return '0'+hour;
            }
            else
            {
                return hour;
            }
        }
    }
    
    //Converts a 24 hour format to an array with a 12 hour format hour and accompanying AM/PM
    @RemoteAction
    global static String[] convert24to12(String hour)
    {
        String[] hourM=new String[]{hour, 'AM'};
        
        if (Integer.valueOf(hour)>=12)
        {
            if (Integer.valueOf(hour)>12)
            {
                hourM[0]=String.valueOf(Integer.valueOf(hour)-12);
                if (hourM[0].length()==1)
                {
                    hourM[0]='0'+hourM[0];
                }
            }
            hourM[1]='PM';
        }
        else if (hour=='00')
        {
            hourM[0]='12';              
        }
        
        return hourM;
    }
}