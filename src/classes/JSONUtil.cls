/**
 *  Author Paul Coleman
 *  
 *  Date January 29 1003 @ 1004 hrs: 
 *  Revised: Person Account refactor, Added static methods from RestAdapter
 * 
 *  Date: Oct 30 2012, 1147 hrs
 *  Revised: (security audit compliance: with sharing) 
 *
 */
public with sharing class JSONUtil {

    public static String getJSON( List<SObject> objects ) {
        return '{\"Records\":' + (objects==null?'':JSON.serialize(objects))+', \"error\": \"null\", \"status\":\"SUCCESS\", \"count\":' + objects.size() + ' }';
    }
    
    public static String getJSON( SObject obj ) {
          List<SObject> objects = new List<SObject>();
          objects.add(obj);
        return '{\"Records\":' + (objects==null?'':JSON.serialize(objects))+', \"error\": \"null\", \"status\":\"SUCCESS\", \"count\":' + objects.size() + ' }';
    }
    
    public static String getJSON( SObject obj, boolean isDone, String queryLocator ) {
        List<SObject> objects = new List<SObject>();
        objects.add(obj);
        return '{\"Records\":' + (objects==null?'':JSON.serialize(objects))+', \"error\": \"null\", \"status\":\"SUCCESS\", \"count\":' + objects.size() + ', \"isDone\":' + isDone + ', \"queryLocator\":' + queryLocator + ' }';
    }
    
    public static String getJSON( List<SObject> objects, boolean isDone, String queryLocator ) {
        return '{\"Records\":' + (objects==null?'':JSON.serialize(objects))+', \"error\": \"null\", \"status\":\"SUCCESS\", \"count\":' + objects.size() + ', \"isDone\":' + isDone + ', \"queryLocator\":' + queryLocator + ' }';
    }
     
    
}