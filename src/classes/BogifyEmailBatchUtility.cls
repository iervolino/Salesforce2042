/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Revised January 22, 2013 @ 1044 hrs - Paul Coleman
 * improved code coverage for prod org by moving prod org test to final update statement in execute method body
 *
 * Created Date January 22, 2013 @ 1044 hrs
 * 
 * Utility class to invalidate all email address fields of a specified object (by soql statement) for sandbox message control
 *
 * DECLARED WITHOUT SHARING TO ENSURE PROPER RECORD SYNCRHONIZATION (class is only used by System Administrator Profiles)
 *
 */
global without sharing class BogifyEmailBatchUtility implements Database.Batchable<sObject> {
 
   global final String queryStr;
   global final Id prodOrgId = '00D30000001GkGUEA0';
   global final boolean inProdOrg;
 
   global BogifyEmailBatchUtility(String queryString) {
      //clause below ensures that bogify does not excessively select prod records that will only be skipped in the execute block
   	  this.inProdOrg = (prodOrgId == [Select Id From Organization LIMIT 1].id);
      this.queryStr = ( inProdOrg? 'select Id,Email,WGUEmail__c from Contact WHERE Email != null AND WGUEmail__c != null LIMIT 1' : queryString );
   }
 
   global Database.QueryLocator start( Database.BatchableContext info ) {
       return Database.getQueryLocator( this.queryStr );
   }
       
   global void execute( Database.BatchableContext info, List<sObject> scope ) {
            
           String[] fields = queryStr.toLowercase().substring(7).substringBefore(' from ').replace(' ','').split(',');
           System.debug('FIELDS: '+ fields );
          
           String sandbox = inProdOrg? 'prod': URL.getSalesforceBaseUrl().toExternalForm().toLowerCase().substringAfter('srm--').split('\\.')[0].split('--c')[0]+'.';
           System.debug(LoggingLevel.DEBUG, 'BOGIFY SANDBOX: '+ sandbox );
          
           Map<Id,SObject> itemsForUpdate = new Map<Id,SObject>();
          
           for( sObject item : scope ) {
              for ( String field: fields ) {
                //skip the "id" field if it were included in the select list
                if (field == 'id') {
                   continue;
                }
               
                //dynamically get the fields existing value
                String emailStr = item.get(field)!=null && ((String)item.get(field)).contains('@')? (String)item.get(field): '';
               
                //split email parts into account/user and domain pair
                String[] emailParts = emailStr.split('@',2);
                if ( emailParts.size() == 2 ) {    //e.g., [account] @ [domain]
                 
                  //if email domain does not already start with sandbox value, modify it
                  if ( !(emailParts[1].startsWith(sandbox)) ) {
                  
                      //dynamically set the email field value to a new value
                      item.put( field, emailParts[0]+'@'+sandbox+emailParts[1] ) ;
                 
                      //ensure each sObject is added to the update list only once
                      if ( itemsForUpdate.containsKey(item.id) ) {
                         sObject me =  itemsForUpdate.get(item.id);
                         me.put( field, item.get(field) ) ;
                      } else {
                        itemsForUpdate.put( item.id, item );
                      }
                  }
                }
              }
           }
           
           //make sure no bogify updates occur in prod
           if ( !itemsForUpdate.isEmpty() && ( !inProdOrg  ) ) {
             update itemsForUpdate.values();
           }
 
   }
       
   global void finish( Database.BatchableContext info ){}
  
   
}