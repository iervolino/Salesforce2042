/** 
 *  RestAdapter Apex Class
 *  @author Dr. Paul Coleman, WGU Software Architect
 *  @exception RestException
 *  @version 1.0
 *
 *  Date June 01 2013 @ 2240 hrs
 *  Revised: Added queryAll() SOAP Wrapper Method, with QueryAllResult inner class, and related methods: sendSOAPQueryAll(), getResultFromSOAPXML() and queryAllObjects() 
 * 
 *  Date January 29 2013 @ 1521 hrs
 *  Revised: Person Account refactor, Removed static JSON serialization methods and moved them to JSONUtil
 * 
 *  Revision History
 *  Date            By                    Description
 *  2013-03-08      Paul Coleman          commented out QueueSObject restriction to allow students to assign queues to cases, etc.
 *  2012-03-16      Paul Coleman          Added reset() method to allow static resources to be reset via anonymous apex execution.
 *  2012-03-18      Paul Coleman          Added isAccessViolation() method to restrict access to certain sObject types, like ApexClass.
 *  
 *  
 *  Description
 *  This class was created to facilite student access to restricted objects in the WGU data model on force.com. Because student
 *  accounts are granted under the customer portal licensing cost structures, student accounts are always constrained as to
 *  their access to certain records and object types, particularly the core objects: Account, Contact, Task Activities, Event 
 *  Activities, & User. To enable developers to write code capable of manipulating all objects necessary to ensure a 
 *  student's productivity, this class skirts the licensing security model by granting controlled access to the complete
 *  object model via the force.com REST API (json enabled). 
 *  
 *  The class constructor creates a security context for the object's usage, ensuring that only authenticated users with 
 *  active session ids can instantiate the class and invoke its methods. Profile access is also limited to students, developers,
 *  and system administrators. The class simply runs in 'system mode' as any 'not with sharing' apex class would, accept that
 *  licensing constraints are also averted.
 *  
 *  IMPORTANT: Developers must ensure that specific usage of the class within code implementations does not grant students 
 *  access to records they ought not to see or manipulate. The organizational security policy for WGU's force.com cloud is public 
 *  read/write, which means record sharing across users and profiles is lenient by default. But this class interacts with the
 *  entire sandbox with system administrator privileges, lacking only the rights to manage users or deploy code.
 *  
 *  SECURITY CONSTRAINT: This class should never be used directly in visualforce pages (javascript) via the apex.js library.
 *  All usage of this class should be encapsulated within another class, such as a utility class or visualforce controller.  
 *  The reason for this constraint is to prevent the browser from gaining direct access to any user's session id by profiling
 *  client-side java script, as well as preventing the class interface from ever appearing in code that students could use
 *  to gain access to data they are not entitled to see or manipulate. 
 *  
 *  The 'Student Profile' should never have API Access and without api access the ability to highjack a live session id, using
 *  this class directly should not be possible. Put another way, in order to be able to use this class in unauthorized ways,
 *  a hacker would have to gain access to a live session id in a browser, know that the class exists and its interface methods,
 *  and be able to inject javascript into their browser (say, via GreaseMonkey or Chrome user plugin) that leverages the apex.js
 *  and connection.js libraries for direct class access. The easiest way for a hacker to get a live session id in a browser is
 *  for a visualforce programmer to include the tag {!$Api.Session_ID} somewhere in the page--which must never be done in 
 *  student-facing pages.
 *  
 *  If AJAX use of the class is required, the correct use case for implementation is to annotate a page controller method with
 *  @RemoteAction and within the encapsulated body of the controller's method, use this class for unfettered object manipulation.
 *  The javascript would then call the controller's wrapper method. NOTE: Use of this class in any use case should never 
 *  include unchecked or unescaped pass-thru REST query or search strings--to protect against soql/sosl injection hacks. Also,
 *  every effort should be made to verify, using force.com recordId association, that the context student is entitled to see the 
 *  data being accessed through the methods of this class.
 *  
 *  EXAMPLE CONTROLLER USAGE: 
 *   @RemoteAction
 *   public static String getJSON() {
 *      RestAdapter adapter = new RestAdapter(UserInfo.getSessionId());
 *      return adapter.describe(new Account());
 *   }
 *  
 *  force.com AJAX Toolkit Links
 *  @see https://na1.salesforce.com/soap/ajax/24.0/connection.js
 *  @see https://na1.salesforce.com/soap/ajax/24.0/apex.js
 *  @see http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_and_ajax.htm
 *  
 *  force.com Service Console Integration API Links
 *  @see http://www.salesforce.com/us/developer/docs/api_console/Content/sforce_api_console_sample_vf.htm
 *  @see https://na1.salesforce.com/support/console/24.0/integration.js
 *  
 *  force.com REST API Docs
 *  @see http://www.salesforce.com/us/developer/docs/api_rest/index.htm
 *  
 *  forcetk.js Javascript library for force.com REST API (DO NOT USE in Student-facing visualforce pages)
 *  @see https://github.com/developerforce/Force.com-JavaScript-REST-Toolkit
 *  
 */
global class RestAdapter {
        
    public enum HTTPMethod { GET, POST, HEAD, DELETEOBJ } //DELETE is a reserved word
    
    private Map<ID,Profile> profileIDs = new Map<ID,Profile>();
    private Map<ID,String> illegalAccessIDs = new Map<ID,String>();
    private transient Map<String,String> loginResultMap = new Map<String,String>();
    private transient Map<String,RestAdapterCredentials__c> APICredentials = new Map<String,RestAdapterCredentials__c>();
    private  String si_username;
    private  String si_password;
    private  String si_password_key;
    private  String si_rest_url;
    private  String si_login_url;
    
    //PRIVATE URL contexts for REST API
    private static final String API_VERSION = 'v24.0';
    private static final String BASE_REST_URL_PREFIX = '/services/data/'+API_VERSION;
    private static final String SOBJECTS_URL = BASE_REST_URL_PREFIX +'/sobjects';
    private static final String SEARCH_URL = BASE_REST_URL_PREFIX +'/search'; 
    private static final String QUERY_URL = BASE_REST_URL_PREFIX +'/query'; 
    private static final String CHATTER_URL = '/services/data/v25.0/chatter'; 
    
    private static final String RECENT_URL = BASE_REST_URL_PREFIX +'/recent';
    
    
    public RestAdapter() {
      if ( UserInfo.getUserType() != 'Guest' ) { //ensure Guest User access does not successfully instantiate a sessionid (also checked by Profile id lower down)
        
        profileIDs = new Map<ID,Profile>([SELECT Id, Name from Profile where NAME in ('Student Profile','Developer','System Administrator') LIMIT 3]);
        illegalAccessIDs = new Map<ID,String>();
        loginResultMap = new Map<String,String>();
        APICredentials = new Map<String,RestAdapterCredentials__c>();

        if ( Test.isRunningTest() ) {
            if ( [select count() from RestAdapterCredentials__c] == 0 ) {
                    String restCredsJson = '[{"attributes": {"type": "RestAdapterCredentials__c"},"Name": "restapi.login.url","Value__c": "https://test.salesforce.com","Seed__c": null},{"attributes": {"type": "RestAdapterCredentials__c"},"Name": "restapi.password","Value__c": "KOfmD8kWOtma2zQLTMeFQNGDb8NmXYilaiFmYraMU214f00ap9bwVdFkjr+JW2nf9l3Nj8gbo2HVykeYcHsNDw==","Seed__c": "eOo42XlGW3iqFNGOWVWtsUvsgvl8w8+TVKSUbbehRPU="},{"attributes": {"type": "RestAdapterCredentials__c"},"Name": "restapi.url","Value__c": "https://cs1.salesforce.com","Seed__c": null},{"attributes": {"type": "RestAdapterCredentials__c"},"Name": "restapi.username","Value__c": "studentintegration@wgu.edu.devfull","Seed__c": null},{"attributes": {"type": "RestAdapterCredentials__c"},"Name": "uv.username","Value__c": "uservalidation@wgu.edu.devfull","Seed__c": null},{"attributes": {"type": "RestAdapterCredentials__c"},"Name": "uv.password","Value__c": "ZoNFT1ltYJJIyQyNXsuTSDql6pFbPku//0lVTyKhF9iBB0ukrmNCxvW0XCQEB9rMZYw0Lo0bNK5cUGl9DLo9Ew==","Seed__c": "eOo42XlGW3iqFNGOWVWtsUvsgvl8w8+TVKSUbbehRPU="}]';
                    List<RestAdapterCredentials__c> creds = (List<RestAdapterCredentials__c>)JSON.deserialize(restCredsJson, List<RestAdapterCredentials__c>.class);
                    insert creds;
            }
            
        }
          
        for ( RestAdapterCredentials__c cred : [SELECT Name, Value__c, Seed__c from RestAdapterCredentials__c] ) {
           APICredentials.put( cred.Name, cred );
        }
        si_username = APICredentials.get('restapi.username').Value__c;
        si_password = APICredentials.get('restapi.password').Value__c;
        si_password_key = APICredentials.get('restapi.password').Seed__c;
        si_rest_url = APICredentials.get('restapi.url').Value__c; //URL.getSalesforceBaseUrl().toExternalForm()
        si_login_url = APICredentials.get('restapi.login.url').Value__c;

        for ( ID profile: profileIDs.keySet() ) {
            illegalAccessIDs.put( profileIDs.get(profile).Id, profileIDs.get(profile).Name );
        } 
        
        if ( profileIDs.containsKey( UserInfo.getProfileID() ) ) {
          if ( Test.isRunningTest() ) {
            //grabbing code coverage for HTTP callout
            send( HTTPMethod.POST, QUERY_URL +'?q='+ encodeUrl('SELECT Id FROM User LIMIT 1'), 'body', loginResultMap.get('sessionId') );
          }
          getNewSessionId();
        } else {
            //block all non-SA, non-Developer, and non-Student user access to the RestAdapter's functionality. Normal user account object access
            //is managed by profiles, roles, and permission sets. 
            throw new RestException('NOT AUTHORIZED');
        }
     }
   }
        
    //SET Student's Profile Photo
    public String setProfilePhoto( ID studentUserID, String photoFileID ) {
        String result = '';
          if ( studentUserID != null && photoFileID != null && [select count() from User where id = :studentUserId and profile.Name in ('Student Profile','System Administrator') LIMIT 1] > 0  ) {
              String postStr = '{"fileId":"'+(photoFileID.length()==18?photoFileID.substring(0, 15):photoFileID)+'"}';
              System.debug( LoggingLevel.DEBUG, 'JSON POST for Chatter Photo: ' + postStr );
              result = ( !Test.isRunningTest() )? send( HTTPMethod.POST, CHATTER_URL + '/users/' + studentUserID +'/photo', postStr, loginResultMap.get('sessionId') ): '{  "largePhotoUrl" : "https://srm--DevFull--c.cs1.content.force.com/profilephoto/729S00000008Qrb/F",  "photoVersionId" : "729S00000008QrbIAE",  "smallPhotoUrl" : "https://srm--DevFull--c.cs1.content.force.com/profilephoto/729S00000008Qrb/T" }';
          }     
       return result;  
    }
    
    //DELETE
    public String deleteObject( SObject sObjectType ) {
      if ( sObjectType == null || sObjectType.Id == null ) {
        throw new RestException('NULL Value Exception: sObjectType parameter to deleteObj() method cannot be null and must have a valid id');
      } else if ( isAccessViolation( sObjectType ) || sObjectType instanceof Account || 
           sObjectType instanceof Profile || 
           sObjectType instanceof Contact || 
           sObjectType instanceof User || 
           sObjectType instanceof Case || 
           illegalAccessIDs.containsKey(sObjectType.Id) ) {
        //DO NOT ALLOW Account, Contact, User, Case, or KeyValue__c records to be deleted through the RestAdapter
        throw new RestException('NOT AUTHORIZED');
      } else {
        return (!Test.isRunningTest())? send( HTTPMethod.DELETEOBJ, SOBJECTS_URL + '/' + String.ValueOf(sObjectType.getSObjectType())+'/'+sObjectType.Id, null, loginResultMap.get('sessionId') ): '[ ]';
      }
    }

    //CREATE or INSERT
    public String updateObjects( List<SObject> sObjectList ) {
       String result = '';
       if ( sObjectList == null || sObjectList.size() == 0 ) {
         throw new RestException('NULL Value Exception: sObjectType List parameter to updateObjects() method cannot be null or empty');
       } else if ( isAccessViolation( sObjectList[0] ) || sObjectList[0] instanceof Account || 
           sObjectList[0] instanceof Profile || 
           sObjectList[0] instanceof Contact || 
           sObjectList[0] instanceof User ) {
        //DO NOT ALLOW Account, Contact, or User records to be updated through the RestAdapter
        throw new RestException('NOT AUTHORIZED');
       } else {
           String sObjectType = String.ValueOf( sObjectList[0].getSObjectType() );
           //create SOAP Request
           XmlStreamWriter sObjectXML = new XmlStreamWriter();
           sObjectXML.writeStartElement( null, 'urn:update', null );
           JSONParser parser = JSON.createParser( '{\"Records\":' +JSON.serialize( sObjectList )+'}' );
           boolean firstTime = true;
           while ( parser.nextToken() != null ) {
               if ( parser.getCurrentToken() == JSONToken.START_ARRAY ) {
                   System.debug( 'START_ARRAY: ' + parser.getText() );
                   while ( parser.nextToken() != null ) {
                       if ( parser.getCurrentToken() == JSONToken.START_OBJECT ) {
                           sObjectXML.writeStartElement( null, 'urn:sObjects', null );
                           sObjectXML.writeAttribute( null, null, 'xsi:type', 'urn1:'+sObjectType );
                           sObjectXML.writeAttribute( null, null, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance' );
                           while ( parser.nextToken() != null ) {
                               if ( parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() != null && parser.getText() != '' ) {
                                   String fieldname = parser.getText();
                                   if ( fieldname != 'attributes' && fieldname != 'type' && fieldname != 'url' ) {
                                     parser.nextValue();
                                     sObjectXML.writeStartElement( null, 'urn1:'+fieldname, null );
                                     sObjectXML.writeCharacters( parser.getText() );
                                     sObjectXML.writeEndElement(); //fieldname
                                   } else if ( fieldname == 'attributes' ) {
                                       if (firstTime) {
                                         firstTime = false;  
                                       } else {
                                           sObjectXML.writeEndElement(); //sObjects 
                                           sObjectXML.writeStartElement( null, 'urn:sObjects', null );
                                           sObjectXML.writeAttribute( null, null, 'xsi:type', 'urn1:'+sObjectType );
                                           sObjectXML.writeAttribute( null, null, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance' );
                                       }     
                                   }
                               } else if ( parser.getCurrentToken() == JSONToken.END_ARRAY ) {
                                 sObjectXML.writeEndElement(); //sObjects 
                               }
                           } 
                       } 
                   }
               } 
           }
           sObjectXML.writeEndElement(); //update
           String xmlOutput = sObjectXML.getXmlString();
           sObjectXML.close();
           result = sendSOAP( xmlOutput, loginResultMap.get('sessionId') ); 
       }
       return result;
    }
    
    
    //UPDATE
    public String updateObject( SObject sObjectType ) {
      if ( sObjectType == null || sObjectType.Id == null ) {
        throw new RestException('NULL Value Exception: sObjectType parameter to updateObj() method cannot be null and must have a valid id');
      } else if ( isAccessViolation( sObjectType ) ||  
           sObjectType instanceof Profile || 
           illegalAccessIDs.containsKey(sObjectType.Id) ) {
        //DO NOT ALLOW KeyValue__c records to be updated through the RestAdapter
        throw new RestException('NOT AUTHORIZED');
      } else {   
        if ( sObjectType instanceof User && sObjectType.Id != UserInfo.getUserId() ) {
          throw new RestException('NOT AUTHORIZED');
        } else if ( sObjectType instanceof Contact && sObjectType.Id != [SELECT ContactId from User where ID = :UserInfo.getUserId()].ContactId ) {
          throw new RestException('NOT AUTHORIZED');
        } else if ( sObjectType instanceof Account && sObjectType.Id != [SELECT AccountId from User where ID = :UserInfo.getUserId()].AccountId ) {
          throw new RestException('NOT AUTHORIZED');
        }
        String bodyJSON = JSON.serialize(sObjectType); 
        bodyJSON = bodyJSON.replaceAll(',"Id":"'+sObjectType.Id+'"', ''); //JSON update must not include id field, the id is sent in REST URL
        //NOTE: the APEX HTTPRequest class did not support the PATCH method as of v24, the work around being the ?_HttpMethod=PATCH query string 
        return (!Test.isRunningTest())? send( HTTPMethod.POST, SOBJECTS_URL + '/' + String.ValueOf(sObjectType.getSObjectType())+'/'+sObjectType.Id+'?_HttpMethod=PATCH', bodyJSON, loginResultMap.get('sessionId') ): '[ ]';
      }
    }

    public static List<SObject> getListFromJSON( String jsonString ) {
        List<SObject> deserializedObjects;
        String result = jsonString;
        if ( result.contains('"records" : [ {' ) ) {
           Integer startIndex = result.indexOf('"records" : [') + '"records" : '.length();
           Integer endIndex = result.lastIndexOf('} ]') + '} ]'.length();
           String jsonArray = result.substring(startIndex, endIndex);
           deserializedObjects = (List<SObject>)JSON.deserialize(jsonArray, List<SObject>.class);
        }
        return deserializedObjects;
    }

	public class QueryAllResult {
     	Boolean done;
     	List<SObject> records;
     	String queryLocator;
     	Integer size;
     	
     	public QueryAllResult() {
     		this.done = true;
     		this.records = new List<SObject>();
     		this.queryLocator = '';
     		this.size = 0;
     	}
   	}
   
    public static QueryAllResult getResultFromSOAPXML( String soapXMLString ) {
        QueryAllResult result = new QueryAllResult();
        XmlStreamReader reader = new XmlStreamReader( soapXMLString );
        reader.setNamespaceAware(true);
        reader.setCoalescing(true);
        String jsonList = '[';
        String chars = '';
        String sobjectType = '';
        Integer size = 0;
        Boolean inRecord = false;
        Boolean firstRecord = true;
        while(reader.hasNext()) {
	         if ( reader.getEventType() == XmlTag.START_ELEMENT ) {
	          	chars = ''; //reset chars buffer
	         	String localName = reader.getLocalName().contains(':')? reader.getLocalName().split(':')[1]: reader.getLocalName();
	            if ( localName.equals('records') ) {
	            	inRecord = true;
	            	if ( sobjectType.equals('') ) {
	            	  sobjectType = reader.getAttributeValueAt(0);
	            	  sobjectType = (sobjectType.contains(':'))? sobjectType.split(':')[1]: sobjectType;
	            	}
	            	jsonList += (firstRecord?'{':',{') + '"attributes":{"type":"'+sobjectType+'"}';
	            	firstRecord = firstRecord==true? false: firstRecord;
	            }
	         } else if (reader.getEventType() == XmlTag.END_ELEMENT) {
	         	String localName = reader.getLocalName().contains(':')? reader.getLocalName().split(':')[1]: reader.getLocalName();
	         	if ( localName.equals('done') ) {
	         		result.done = (chars == 'true');
	         	} else if ( localName.equals('queryLocator') && !chars.equals('') ) {
	            	result.queryLocator = chars;
	            } else if (localName.equals('records') ) {
	            	inRecord = false;
	            	jsonList += '}';
	            } else if (localName.equals('size') ) {
	            	size = Integer.valueOf(chars);
	            } else if ( inRecord ) {
	            	jsonList += ',"'+localName+'":"'+chars+'"';
	            }
	         } else if (reader.getEventType() == XmlTag.CHARACTERS) {
	         	if (!reader.isWhiteSpace()) { 
	         	 	chars = reader.getText(); 
	         	}
	         } 
	        reader.next();
	    }
        jsonList += ']';
        System.debug( LoggingLevel.FINE, 'JSON RESULT: ' + jsonList);
        result.records = size==0? result.records:(List<SObject>)JSON.deserialize(jsonList, List<SObject>.class);
        result.size = size;
        System.debug( LoggingLevel.DEBUG, result);
        return result;
    }

    //CREATE or INSERT
    public String createObjects( List<SObject> sObjectList ) {
       String result = '';
       if ( sObjectList == null || sObjectList.size() == 0 ) {
         throw new RestException('NULL Value Exception: sObjectType List parameter to createObjects() method cannot be null or empty');
       } else if ( isAccessViolation( sObjectList[0] ) || sObjectList[0] instanceof Account || 
           sObjectList[0] instanceof Profile || 
           sObjectList[0] instanceof Contact || 
           sObjectList[0] instanceof User ) {
        //DO NOT ALLOW Account, Contact, or User records to be created through the RestAdapter
        throw new RestException('NOT AUTHORIZED');
       } else {
           String sObjectType = String.ValueOf( sObjectList[0].getSObjectType() );
           //create SOAP Request
           XmlStreamWriter sObjectXML = new XmlStreamWriter();
           sObjectXML.writeStartElement( null, 'urn:create', null );
           JSONParser parser = JSON.createParser( '{\"Records\":' +JSON.serialize( sObjectList )+'}' );
           boolean firstTime = true;
           while ( parser.nextToken() != null ) {
               if ( parser.getCurrentToken() == JSONToken.START_ARRAY ) {
                   System.debug( 'START_ARRAY: ' + parser.getText() );
                   while ( parser.nextToken() != null ) {
                       if ( parser.getCurrentToken() == JSONToken.START_OBJECT ) {
                           sObjectXML.writeStartElement( null, 'urn:sObjects', null );
                           sObjectXML.writeAttribute( null, null, 'xsi:type', 'urn1:'+sObjectType );
                           sObjectXML.writeAttribute( null, null, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance' );
                           while ( parser.nextToken() != null ) {
                               if ( parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() != null && parser.getText() != '' ) {
                                   String fieldname = parser.getText();
                                   if ( fieldname != 'attributes' && fieldname != 'type' && fieldname != 'url' ) {
                                     parser.nextValue();
                                     sObjectXML.writeStartElement( null, 'urn1:'+fieldname, null );
                                     sObjectXML.writeCharacters( parser.getText() );
                                     sObjectXML.writeEndElement(); //fieldname
                                   } else if ( fieldname == 'attributes' ) {
                                       if (firstTime) {
                                         firstTime = false;  
                                       } else {
                                           sObjectXML.writeEndElement(); //sObjects 
                                           sObjectXML.writeStartElement( null, 'urn:sObjects', null );
                                           sObjectXML.writeAttribute( null, null, 'xsi:type', 'urn1:'+sObjectType );
                                           sObjectXML.writeAttribute( null, null, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance' );
                                       }     
                                   }
                               } else if ( parser.getCurrentToken() == JSONToken.END_ARRAY ) {
                                 sObjectXML.writeEndElement(); //sObjects 
                               }
                           } 
                       } 
                   }
               } 
           }
           sObjectXML.writeEndElement(); //create
           String xmlOutput = sObjectXML.getXmlString();
           sObjectXML.close();
           result = sendSOAP( xmlOutput, loginResultMap.get('sessionId') );  
       }
       return result;
    }
    
    public String createObject( SObject sObjectType ) {
       return createObject( sObjectType, loginResultMap.get('sessionId') );
    }
    
    public String createObject( SObject sObjectType, String sessionId ) {
      if ( sObjectType == null ) {
        throw new RestException('NULL Value Exception: sObjectType parameter to createObject() method cannot be null');
      } else if ( isAccessViolation( sObjectType ) || sObjectType instanceof Account || 
           sObjectType instanceof Profile || 
           sObjectType instanceof Contact || 
           sObjectType instanceof User ) {
        //DO NOT ALLOW Account, Contact, or User records to be created through the RestAdapter
        throw new RestException('NOT AUTHORIZED');
      } else {   
        if ( sObjectType.id != null ) {
              throw new RestException('CANNOT CREATE AN OBJECT THAT ALREADY HAS AN ID');
        }
        String bodyJSON = JSON.serialize(sObjectType);  
        return (!Test.isRunningTest())? send( HTTPMethod.POST, SOBJECTS_URL + '/' + String.ValueOf(sObjectType.getSObjectType()), bodyJSON, sessionId ): '{  "id" : "a08Q0000004B27GIAS",  "errors" : [ ],  "success" : true}';
      }
    }
    
    //SELECT SObject 
    public String getSObject( SObject sobjectType ) {
      if ( sObjectType == null ) {
        throw new RestException('NULL Value Exception: sObjectType parameter to getSObject() method cannot be null');
      } else if ( isAccessViolation( sobjectType ) ) {
           throw new RestException('NOT AUTHORIZED');
      } else {   
          if (sObjectType.Id == null) {
            return (!Test.isRunningTest())? send( HTTPMethod.GET, SOBJECTS_URL + '/' + String.ValueOf(sObjectType.getSObjectType()), null, loginResultMap.get('sessionId') ): '{  "recentItems" : [ {    "attributes" : {      "type" : "FieldExperience__c",      "url" : "/services/data/v24.0/sobjects/FieldExperience__c/a0Ta000000B0NhuEAF"    },    "Id" : "a0Ta000000B0NhuEAF",    "Name" : "Poindexter, Matthew,   FE Application"  } ],  "objectDescribe" : {    "name" : "FieldExperience__c",    "label" : "Field Experience",    "keyPrefix" : "a0T",    "labelPlural" : "Field Experiences",    "custom" : true,    "layoutable" : true,    "activateable" : false,    "urls" : {      "sobject" : "/services/data/v24.0/sobjects/FieldExperience__c",      "describe" : "/services/data/v24.0/sobjects/FieldExperience__c/describe",      "rowTemplate" : "/services/data/v24.0/sobjects/FieldExperience__c/{ID}"    },    "searchable" : true,    "updateable" : true,    "createable" : true,    "deprecatedAndHidden" : false,    "customSetting" : false,    "deletable" : true,    "feedEnabled" : false,    "mergeable" : false,    "queryable" : true,    "replicateable" : true,    "retrieveable" : true,    "undeletable" : true,    "triggerable" : true  }}';
          } else {
            if ( illegalAccessIDs.containsKey(sObjectType.Id) ) {
               throw new RestException('NOT AUTHORIZED');
            }
            return (!Test.isRunningTest())? send( HTTPMethod.GET, SOBJECTS_URL + '/' + String.ValueOf(sObjectType.getSObjectType())+'/'+sObjectType.Id, null, loginResultMap.get('sessionId') ): '{  "attributes" : {    "type" : "StudentAttributes__c",    "url" : "/services/data/v24.0/sobjects/StudentAttributes__c/a08Q0000004B27GIAS"  },  "Id" : "a08Q0000004B27GIAS",  "OwnerId" : "005Q0000000jiABIAY",  "IsDeleted" : false,  "Name" : "Paul Coleman",  "RecordTypeId" : "01230000000buB1AAI",  "CreatedDate" : "2012-03-20T02:48:14.000+0000",  "CreatedById" : "005Q0000000jiABIAY",  "LastModifiedDate" : "2012-03-20T02:48:14.000+0000",  "LastModifiedById" : "005Q0000000jiABIAY",  "SystemModstamp" : "2012-03-20T02:48:14.000+0000",  "LastActivityDate" : null,  "AboutMeStatement__c" : null,  "AffiliateFullname__c" : "Western Governors University",  "AffiliatePortalURL__c" : "my.wgu.edu",  "Affiliate_URL__c" : "https://my.wgu.edu",  "Affiliation__c" : "WGU",  "FacebookProfile__c" : null,  "LinkedInProfile__c" : null,  "Nickname__c" : "Johnny Be Good",  "PersonalInterests__c" : null,  "PersonalMissionStatement__c" : null,  "StudentContact__c" : null,  "StudentDegreePlan__c" : null,  "StudentStatus__c" : null,  "TwitterProfile__c" : null}';
          }
      }
    }

    //describe SObject, possible use case: dynamically generating javascript UI based on sobject meta constraints
    public String describe( SObject sobjectType ) {
      if ( sObjectType == null ) {
         throw new RestException('NULL Value Exception: sObjectType parameter to describe() method cannot be null');
      } else if ( isAccessViolation( sobjectType ) ) {   
         throw new RestException('NOT AUTHORIZED');
      } else {   
         return  (!Test.isRunningTest())? send( HTTPMethod.GET, SOBJECTS_URL + '/' + String.ValueOf(sObjectType.getSObjectType())+'/describe', null, loginResultMap.get('sessionId') ): '{  "name" : "StudentAttributes__c",  "fields" : [ {    "length" : 18,    "name" : "Id",    "type" : "id" } ],  "replicateable" : true,  "retrieveable" : true,  "searchLayoutable" : null,  "undeletable" : true,  "triggerable" : true}';
      }
    }
    
    //SELECT via SOQL, return List
    public List<SObject> queryObjects( String soql ) {
      return getListFromJSON( this.query(soql) );
    }
    
    //SELECT via SOQL, return JSON
    public String query( String soql ) {
      if ( soql == null || soql.length() == 0 ) {
           throw new RestException('NULL Value Exception: Must supply a valid query string.');
      }
      for ( ID illegalID : illegalAccessIDs.keySet() ) {
        if ( soql.contains( illegalID ) ) {
           throw new RestException('NOT AUTHORIZED');
        }
      }
      String result = (!Test.isRunningTest()) ? send( HTTPMethod.GET, QUERY_URL +'?q='+ (soql==null?'':encodeUrl(soql)), null, loginResultMap.get('sessionId') ): '{  "totalSize" : 1,  "done" : true,  "records" : [ {    "attributes" : {      "type" : "KeyValue__c",      "url" : "/services/data/v24.0/sobjects/KeyValue__c/a06Q0000005FXaIIAW"    },    "Id" : "a06Q0000005FXaIIAW"  } ]}';
        
        //check for accessViolation in object return type
        if ( result.contains('"records" : [ {' ) ) {
           List<SObject> deserializedObjects = getListFromJSON( result );
           if ( !deserializedObjects.isEmpty()  &&  isAccessViolation( deserializedObjects.get(0) ) )  {
             throw new RestException('NOT AUTHORIZED');
           }
        }
      return result;
    }
  
  
    //SOAP queryAll, return List
    public List<SObject> queryAllObjects( String soql ) {
      //NOTE: does not support nested child queries or parent references
      return getResultFromSOAPXML( this.queryAll(soql) ).records;
    }
    
  
    //SOAP queryAll, returns raw SOAP XML response
    public String queryAll( String soql ) {
       String result = '';
      if ( soql == null || soql.length() == 0 ) {
           throw new RestException('NULL Value Exception: Must supply a valid query string.');
      }
      for ( ID illegalID : illegalAccessIDs.keySet() ) {
        if ( soql.contains( illegalID ) ) {
           throw new RestException('NOT AUTHORIZED');
        }
      }

       result = sendSOAPQueryAll(soql, loginResultMap.get('sessionId') ); 
       
       return result;
    }
    
  
    
    //FIND
    public String search( String sosl ) {
      if ( sosl == null || sosl.length() == 0 ) {
           throw new RestException('NULL Value Exception: Must supply a valid search string.');
      }
      for ( ID illegalID : illegalAccessIDs.keySet() ) {
        if ( sosl.contains( illegalID ) ) {
           throw new RestException('NOT AUTHORIZED');
        }
      }
      return (!Test.isRunningTest())? send( HTTPMethod.GET, SEARCH_URL + '?q=' + (sosl==null?'':encodeUrl(sosl)), null, loginResultMap.get('sessionId') ): '[ {  "attributes" : {    "type" : "StudentAttributes__c",    "url" : "/services/data/v24.0/sobjects/StudentAttributes__c/a08Q0000004B253IAC"  },  "Id" : "a08Q0000004B253IAC"} ]';
    }
    
    //GET RECENT ITEMS LIST
    public String recent() {    
      return (!Test.isRunningTest())? send( HTTPMethod.GET, RECENT_URL, null, loginResultMap.get('sessionId') ) : '[ {  "attributes" : {    "type" : "FieldExperience__c",    "url" : "/services/data/v24.0/sobjects/FieldExperience__c/a0Ta000000B0NhuEAF"  },  "Id" : "a0Ta000000B0NhuEAF",  "Name" : "Poindexter, Matthew,   FE Application"} ]';
    }
    
    public String convertAttachmentToChatterFile( ID AttachmentID ) {
       String anonymousApex = 'ID result = AttachmentUtility.convertAttachmentToChatterFile( \''+AttachmentID+'\' );';
       String result = executeAnonymous( anonymousApex, true);
       System.debug( LoggingLevel.DEBUG, result );
       return result;
    }

    //After placing the plaintext value in the RestAdapterCredentials__c record for Name = uv.password, run this method in execute anonymous
    public static void encryptUVPassword() {
        String base64Result;
        RestAdapterCredentials__c creds = [SELECT Name, Value__c, Seed__c from RestAdapterCredentials__c where Name = 'uv.password' LIMIT 1];
        String uv_password = creds.Value__c;
        String uv_password_key = creds.Seed__c;
        Blob vector = Blob.valueOf('2045688900114650');            
        Blob cipherData = Crypto.encrypt( 'AES256', EncodingUtil.base64Decode(uv_password_key), vector, Blob.ValueOf(uv_password) );
        base64Result = EncodingUtil.base64Encode( cipherData );
        creds.Value__c = base64Result;
        update creds;
        System.debug( base64Result );
    }
    
    public String getUserValidationSessionId() {
        //Use the SOAP API to get a session id for the user validation integration account
        String uv_username = APICredentials.get('uv.username').Value__c;
        String uv_password = APICredentials.get('uv.password').Value__c;
        String uv_password_key = APICredentials.get('uv.password').Seed__c;
        Blob vector = Blob.valueOf('2045688900114650');            
        Blob decryptedData = Crypto.decrypt('AES256', EncodingUtil.base64Decode(uv_password_key), vector, EncodingUtil.base64Decode(uv_password));
        String uv_decrypted = decryptedData.toString();
        
        HttpResponse res = getNewSessionId( uv_username, uv_decrypted );
        String sessionId;
        if ( res.getStatusCode() == 500 ) {
            throw new RestException('USER VALIDATION AUTHENTICATION FAILURE');
        }
        System.debug( 'HTTP RESPONSE: ' + res.toString()+ ' '+  res.getBody() );       
        
        XmlStreamReader reader = res.getXmlStreamReader();
        boolean captureChars = false;
        boolean keepGoing = true;
        String chars;
        while(reader.hasNext() && keepGoing ) {
          //skip the container elements and gather the name/value pairs
          if ( reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'sessionId' ) {
             keepGoing = false;
             captureChars = false;
             sessionId = chars;
          } else if ( reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'sessionId' ) {
            captureChars = true;
          } else if ( reader.getEventType() == XmlTag.CHARACTERS && captureChars ) {
             chars = reader.getText(); //capture the PCDATA between the start and end tags
          }
          reader.next();
        }
        if (Test.isRunningTest()) {
          sessionId = UserInfo.getSessionId();
        }
        return sessionId;
    }
 
    //After placing the plaintext value in the RestAdapterCredentials__c record for Name = restapi.password, run this method in execute anonymous
    public static void encryptRestAdapterPassword() {
        String base64Result;
        RestAdapterCredentials__c creds = [SELECT Name, Value__c, Seed__c from RestAdapterCredentials__c where Name = 'restapi.password' LIMIT 1];
        String ra_password = creds.Value__c;
        String ra_password_key = creds.Seed__c;
        Blob vector = Blob.valueOf('1934577899003549');            
        Blob cipherData = Crypto.encrypt( 'AES256', EncodingUtil.base64Decode(ra_password_key), vector, Blob.ValueOf(ra_password) );
        base64Result = EncodingUtil.base64Encode( cipherData );
        creds.Value__c = base64Result;
        update creds;         
    }
        
       
    //*********************
    //BEGIN PRIVATE METHODS
    //*********************
    private Boolean isAccessViolation( SObject sobjectType ) {
          String sObjectTypeString = String.ValueOf(sobjectType.getSObjectType());
        if ( sObjectTypeString.contains('Apex') || 
           sObjectTypeString.startsWith('Contract') || 
           sObjectTypeString.startsWith('Dashboard') || 
           sObjectTypeString.startsWith('ProcessInstance') || 
           sObjectTypeString.startsWith('Product2') || 
           sObjectTypeString.endsWith('Share') || 
           sObjectTypeString.endsWith('Activity') || 
           sObjectTypeString.endsWith('Feed') || 
           sObjectTypeString.endsWith('History') || 
           sObjectTypeString.contains('Permission') || 
           sObjectType instanceof Question || 
           sObjectType instanceof Reply ||
           // Changed March 8 2013 - Paul Coleman 
           // Allowed access to QueueSobject for students to be able to create cases and assign them to queues (license restriction)
           // sObjectType instanceof QueueSobject || 
           sObjectType instanceof Name || 
           sObjectType instanceof Organization || 
           sObjectType instanceof Partner || 
           sObjectType instanceof PartnerRole || 
           // No need to test for Period
           // as the customer license prohibits
           // access to it
           //sObjectType instanceof Period || 
           sObjectType instanceof PriceBook2 || 
           sObjectType instanceof PriceBookEntry || 
           sObjectType instanceof Note || 
           sObjectType instanceof NoteAndAttachment || 
           sObjectType instanceof CronTrigger || 
           sObjectType instanceof OrgWideEmailAddress ||
           sObjectType instanceof PushTopic || 
           sObjectType instanceof Report || 
           sObjectType instanceof Site || 
           sObjectType instanceof SiteFeed || 
           sObjectType instanceof SiteHistory || 
           sObjectType instanceof StaticResource || 
           sObjectType instanceof UserLicense || 
           sObjectType instanceof UserRecordAccess || 
           sObjectType instanceof StudentDisposition__c ||
           sObjectType instanceof RestAdapterCredentials__c ||
           sObjectType instanceof WGUStudentNote__c 
          ) {
            return true;
          }  else {
            return false;
          }
    }
                                        
    private String encodeUrl( String url ) {
        return url.trim().replaceAll(' ', '+');
    }


    
    //Process Student Integration Login and get a valid session Id for subsequent REST calls
    private void getNewSessionId() {
        //Use the SOAP API to get a session id for the student integration account
        loginResultMap.clear();
        Blob vector = Blob.valueOf('1934577899003549');            
        Blob decryptedData = Crypto.decrypt('AES256', EncodingUtil.base64Decode(si_password_key), vector, EncodingUtil.base64Decode(si_password));
        String decrypted = decryptedData.toString();
        System.debug(  decrypted  );
        
        HttpResponse res = getNewSessionId( si_username, decrypted );
        
        if ( res.getStatusCode() == 500 ) {
            throw new RestException('AUTHENTICATION FAILURE');
        }
        System.debug( LoggingLevel.DEBUG, 'HTTP RESPONSE: ' + res.toString()+ ' '+  res.getBody() );       
        
        XmlStreamReader reader = res.getXmlStreamReader();
        boolean captureChars = false;
        String chars;
        while(reader.hasNext()) {
          //skip the container elements and gather the name/value pairs
          if ( reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() != 'Envelope' && reader.getLocalName() != 'Body' && reader.getLocalName() != 'loginResponse' && reader.getLocalName() != 'result' && reader.getLocalName() != 'userInfo' ) {
             loginResultMap.put( reader.getLocalName(), chars );
          } else if ( reader.getEventType() == XmlTag.CHARACTERS ) {
             chars = reader.getText(); //capture the PCDATA between the start and end tags
          }
          reader.next();
        }
        
        if (Test.isRunningTest()) {
          loginResultMap.put( 'sessionId', UserInfo.getSessionId() );
          loginResultMap.put( 'serverUrl', String.ValueOf(URL.getSalesforceBaseUrl()).split('=')[1] + '/services/Soap/u/24.0/00DQ0000000Dxvs' );
        }
        System.debug(LoggingLevel.DEBUG, loginResultMap.keySet());
    }
                    
    private HttpResponse getNewSessionId(String username, String password) {
        System.debug( LoggingLevel.DEBUG, username );
        System.debug( LoggingLevel.DEBUG, password );
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint( si_login_url + '/services/Soap/u/24.0' );
        req.setHeader( 'User-Agent', 'Salesforce Web Service Connector For Java/1.0' ); 
        req.setHeader( 'SOAPAction', '""' );
        req.setHeader( 'Accept', 'text/xml' );
        req.setHeader( 'Content-Type', 'text/xml; charset=UTF-8' );                
        req.setBody( '<?xml version="1.0" encoding="UTF-8"?><env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><env:Body><m:login xmlns:m="urn:partner.soap.sforce.com" xmlns:sobj="urn:sobject.partner.soap.sforce.com"><m:username>'+username+'</m:username><m:password>'+password+'</m:password></m:login></env:Body></env:Envelope>' );
        req.setMethod( 'POST' );
        HttpResponse response = send(req);
        if (Test.isRunningTest()) {
            response.setBody('<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><loginResponse><result><metadataServerUrl>https://cs3-api.salesforce.com/services/Soap/m/24.0/00DQ0000000Dxvs</metadataServerUrl><passwordExpired>false</passwordExpired><sandbox>true</sandbox><serverUrl>https://cs3-api.salesforce.com/services/Soap/u/24.0/00DQ0000000Dxvs</serverUrl><sessionId>00DQ0000000Dxvs!ARMAQGMkVKHduc98NmkJujQMCtqA2LFa9lqmNJGr7INI_uA0poIMNyAZFgKyzS_vQThSCqD6d3P2BCXsmrX1hQQrdK39fCW8</sessionId><userId>005300000050zVTAAY</userId><userInfo><accessibilityMode>false</accessibilityMode><currencySymbol>$</currencySymbol><orgAttachmentFileSizeLimit>5242880</orgAttachmentFileSizeLimit><orgDefaultCurrencyIsoCode>USD</orgDefaultCurrencyIsoCode><orgDisallowHtmlAttachments>false</orgDisallowHtmlAttachments><orgHasPersonAccounts>true</orgHasPersonAccounts><organizationId>00DQ0000000DxvsMAC</organizationId><organizationMultiCurrency>false</organizationMultiCurrency><organizationName>Western Governors University</organizationName><profileId>00e30000001k9gxAAA</profileId><roleId>00E300000016U2dEAE</roleId><sessionSecondsValid>7200</sessionSecondsValid><userDefaultCurrencyIsoCode xsi:nil="true"/><userEmail>pcoleman@wgu.edu</userEmail><userFullName>Paul Coleman</userFullName><userId>005300000050zVTAAY</userId><userLanguage>en_US</userLanguage><userLocale>en_US</userLocale><userName>pcoleman@wgu.edu.devbox</userName><userTimeZone>America/Denver</userTimeZone><userType>Standard</userType><userUiSkin>Theme3</userUiSkin></userInfo></result></loginResponse></soapenv:Body></soapenv:Envelope>');
        } 
        return response;
    }

    private String executeAnonymous(String apexString, Boolean enableDebug) {
      String result = '';
        if ( apexString != null && apexString.length() > 0 ) {
                 
            Boolean debugEnabled = enableDebug==null?false:enableDebug;
            HttpRequest req = new HttpRequest(); 
            req.setEndpoint( loginResultMap.get('serverUrl').replace('/u/','/s/') );
            req.setHeader( 'User-Agent', 'Salesforce Web Service Connector For Java/1.0' ); 
            req.setHeader( 'SOAPAction', '""' );
            req.setHeader( 'Accept', 'text/xml, application/soap+xml' );
            req.setHeader( 'Content-Type', 'text/xml; charset=UTF-8' ); 
            String soapXML = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://soap.sforce.com/2006/08/apex"><soapenv:Header><SessionHeader>'+
                             '<sessionId>'+loginResultMap.get('sessionId')+'</sessionId>'+
                             (debugEnabled?'</SessionHeader><DebuggingHeader xmlns="http://soap.sforce.com/2006/08/apex"><categories><category>Apex_code</category><level>Finest</level></categories><debugLevel>Debugonly</debugLevel></DebuggingHeader>':'</SessionHeader>')+
                             '</soapenv:Header><soapenv:Body><executeAnonymous><String>'+apexString+'</String></executeAnonymous></soapenv:Body></soapenv:Envelope>';
            System.debug( LoggingLevel.WARN, 'SOAP XML: ' +  EncodingUtil.urlEncode( soapXML, 'UTF-8' ) );
            req.setBody(soapXML);
            req.setMethod( 'POST' );
            HttpResponse res = send(req); 
            result = res.getBody();
            System.debug( LoggingLevel.DEBUG, 'HTTP RESPONSE: ' + res.toString()+ ' '+  res.getBody() );       
            if ( res.getStatusCode() == 500 ) {
                System.debug( LoggingLevel.ERROR, 'HTTP SOAP ERROR: '+res.getBody()==null?'': res.getBody());
                throw new RestException('EXECUTE ANONYMOUS FAILURE');
            }
            if (Test.isRunningTest()) {
                //canned result for test cases
                result = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="http://soap.sforce.com/2006/08/apex" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Header><DebuggingInfo><debugLog>24.0 APEX_CODE,FINEST\nExecute Anonymous: System.debug( JSON.serialize( Runtime__c.getValues(&apos;environment&apos;) ) );\n14:29:39.047 (47906000)|EXECUTION_STARTED\n14:29:39.122 (122115000)|USER_DEBUG|[1]|DEBUG|{&quot;attributes&quot;:{&quot;type&quot;:&quot;Runtime__c&quot;,&quot;url&quot;:&quot;/services/data/v25.0/sobjects/Runtime__c/a0P30000009q4RYEAY&quot;},&quot;Name&quot;:&quot;environment&quot;,&quot;SetupOwnerId&quot;:&quot;00DS0000000FzTuMAK&quot;,&quot;LastModifiedById&quot;:&quot;005300000050zVTAAY&quot;,&quot;SystemModstamp&quot;:&quot;2012-05-15T15:25:50.000+0000&quot;,&quot;CreatedById&quot;:&quot;005300000050zVTAAY&quot;,&quot;CreatedDate&quot;:&quot;2012-03-22T03:45:44.000+0000&quot;,&quot;IsDeleted&quot;:false,&quot;LastModifiedDate&quot;:&quot;2012-05-15T15:25:50.000+0000&quot;,&quot;Id&quot;:&quot;a0P30000009q4RYEAY&quot;,&quot;Value__c&quot;:&quot;devfull&quot;}\n14:29:39.122 (122173000)|EXECUTION_FINISHED</debugLog></DebuggingInfo></soapenv:Header><soapenv:Body><executeAnonymousResponse><result><column>-1</column><compileProblem xsi:nil="true"/><compiled>true</compiled><exceptionMessage xsi:nil="true"/><exceptionStackTrace xsi:nil="true"/><line>-1</line><success>true</success></result></executeAnonymousResponse></soapenv:Body></soapenv:Envelope>';
            }
        }
      return result;
    }

    private String sendSOAP( String sObjectXML, String sessionId ) {
        //The REST api does not support creating, deleting, updating more than one SFID at a time
        //the SOAP api supports processing up to 200 records at a time, hence its inclusion here
        String result = '';
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint( loginResultMap.get('serverUrl').replace('/u/','/c/') );
        req.setHeader( 'User-Agent', 'Salesforce Web Service Connector For Java/1.0' ); 
        req.setHeader( 'SOAPAction', '""' );
        req.setHeader( 'Accept', 'text/xml, application/soap+xml' );
        req.setHeader( 'Content-Type', 'text/xml; charset=UTF-8' ); 
        String soapXML = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:enterprise.soap.sforce.com" xmlns:urn1="urn:sobject.enterprise.soap.sforce.com">'+
                         '<soapenv:Header><urn:SessionHeader><urn:sessionId>'+sessionId+'</urn:sessionId></urn:SessionHeader></soapenv:Header><soapenv:Body>'+ sObjectXML +'</soapenv:Body></soapenv:Envelope>';
        System.debug( LoggingLevel.FINE, 'SOAP XML: ' +  EncodingUtil.urlEncode( soapXML, 'UTF-8' ) );
        req.setBody(soapXML);
        req.setMethod( 'POST' );
        HttpResponse res = send(req); 
        result = res.getBody();
        if ( res.getStatusCode() == 500 ) {
            System.debug( LoggingLevel.ERROR, 'HTTP SOAP ERROR: '+ res.getBody()!=null?res.getBody():'' );
            throw new RestException('AUTHENTICATION FAILURE');
        }
        System.debug( 'HTTP RESPONSE: ' + res.toString()+ ' '+  res.getBody() );       
        if (Test.isRunningTest()) {
            result = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><createResponse xmlns="urn:enterprise.soap.sforce.com"><result><errors xsi:nil="true"/><id>00130000002K9TnAAK</id><success>true</success></result></createResponse></soapenv:Body></soapenv:Envelope>';
        }
        return result;
    }
        
    private String sendSOAPQueryAll( String soql, String sessionId ) {
        //As of this writing, 2013-06-01, the REST api does not support the queryAll feature for retrieving deleted or archived records
        //this method wraps the SOAP queryAll method and was added primarily for RestAdapter to be able to retrieve archived Task records as part of FieldExperience queries 
        //batchSize is non-configurable and set to a maximum of 2000 records and no attempt is made to support queryMore functionality
        //See also: the SOQL "ALL ROWS" clause
        String result = '';
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint( loginResultMap.get('serverUrl').replace('/u/','/c/') );
        req.setHeader( 'User-Agent', 'Salesforce Web Service Connector For Java/1.0' ); 
        req.setHeader( 'SOAPAction', '""' );
        req.setHeader( 'Accept', 'text/xml, application/soap+xml' );
        req.setHeader( 'Content-Type', 'text/xml; charset=UTF-8' ); 
        String soapXML = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:enterprise.soap.sforce.com" xmlns:urn1="urn:sobject.enterprise.soap.sforce.com">'+
                         '<soapenv:Header><urn:SessionHeader><urn:sessionId>'+sessionId+'</urn:sessionId></urn:SessionHeader><urn:QueryOptions><urn:batchSize>2000</urn:batchSize></urn:QueryOptions></soapenv:Header><soapenv:Body><urn:queryAll><urn:queryString>'+ soql +'</urn:queryString></urn:queryAll></soapenv:Body></soapenv:Envelope>';
        System.debug( LoggingLevel.FINE, 'SOAP XML: ' +  EncodingUtil.urlEncode( soapXML, 'UTF-8' ) );
        req.setBody(soapXML);
        req.setMethod( 'POST' );
        HttpResponse res = send(req); 
        result = res.getBody();
        if ( res.getStatusCode() == 500 ) {
            System.debug( LoggingLevel.ERROR, 'HTTP SOAP ERROR: '+ res.getBody()!=null?res.getBody():'' );
            throw new RestException('AUTHENTICATION FAILURE');
        }
        System.debug( 'HTTP RESPONSE: ' + res.toString()+ ' '+  res.getBody() );       
        if (Test.isRunningTest()) {
            result = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:enterprise.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sf="urn:sobject.enterprise.soap.sforce.com"><soapenv:Body><queryAllResponse><result><done>true</done><queryLocator xsi:nil="true"/><records xsi:type="sf:Task"><sf:Id>00Ta000002cAk2xEAC</sf:Id><sf:CardIndex__c>1.0</sf:CardIndex__c><sf:IsClosed>false</sf:IsClosed><sf:SortOrder__c>10.0</sf:SortOrder__c><sf:Status>Not Started</sf:Status><sf:Subject>Field Experience Requirements Overview</sf:Subject><sf:TemplateId__c>a0X30000006quBYEAY</sf:TemplateId__c><sf:WhatId>a0T30000005x27vEAA</sf:WhatId></records><records xsi:type="sf:Task"><sf:Id>00T3000001vy9h1EAA</sf:Id><sf:CardIndex__c>1.0</sf:CardIndex__c><sf:IsClosed>true</sf:IsClosed><sf:SortOrder__c>10.0</sf:SortOrder__c><sf:Status>Completed</sf:Status><sf:Subject>Field Experience Requirements Overview</sf:Subject><sf:TemplateId__c>a0X30000006quBYEAY</sf:TemplateId__c><sf:WhatId>a0T30000005x27vEAA</sf:WhatId></records><records xsi:type="sf:Task"><sf:Id>00Ta000002E2EqJEAV</sf:Id><sf:CardIndex__c>19.0</sf:CardIndex__c><sf:IsClosed>false</sf:IsClosed><sf:SortOrder__c>200.0</sf:SortOrder__c><sf:Status>Not Started</sf:Status><sf:Subject>PCE: Signed Task Summary Upload</sf:Subject><sf:TemplateId__c>a0X30000006quBhEAI</sf:TemplateId__c><sf:WhatId>a0T30000005x27vEAA</sf:WhatId></records><size>3</size></result></queryAllResponse></soapenv:Body></soapenv:Envelope>';
        }
        return result;
    }
        
    
    //Process HTTP request, returning the HTTPResponse as a JSON string
    // @see http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_methods_system_json_overview.htm for 
    //      JSON serialization/deserialization in Apex
    private String send( HTTPMethod method, String url, String body, String sessionId ) { 
        HTTPResponse response;  
            
            //use the REST api, JSON enabled
            HttpRequest request = new HttpRequest(); 
            request.setEndpoint( si_rest_url + url );
            request.setHeader( 'Authorization', 'OAuth ' + sessionId ); 
            request.setHeader( 'X-PrettyPrint', 'false' ); 
            
            if ( method == HTTPMethod.POST ) {
                request.setHeader('Content-Type', 'application/json');
                request.setBody(body);
            } 
            
            request.setMethod( method==HTTPMethod.DELETEOBJ?'DELETE':String.ValueOf(method) );
            System.debug(Logginglevel.INFO, request);
            response = (!Test.IsRunningTest())? send(request) : new HTTPResponse();
            if ( Test.isRunningTest() ) {
              response.setStatusCode(200);
              response.setBody('');
            }
            System.debug(Logginglevel.INFO, response);
            System.debug(Logginglevel.INFO, response.getBody()==null? '' : response.getBody().replace('\n', ''));
            if ( response.getStatusCode() == 401 ) {
              throw new RestException( 'NOT AUTHORIZED' );
            } else if ( response.getStatusCode() == 404 ) {
              //let not found condition fall thru
            } else if ( response.getStatusCode() > 204 ) {
              throw new RestException('RestAdapter Returned Status Code ' + String.valueOf( response.getStatusCode() ) + ' with status text of ' + response.getStatus() + '. Request endpoint = ' + request.getEndPoint() );
            } 
       
        return response.getBody()==null?'':response.getBody().replace('\n', '');
    }
    
    private HttpResponse send( HttpRequest request ) {
        HttpResponse response = (!Test.isRunningTest())? new Http().send(request): new HttpResponse();
        if ( Test.isRunningTest() ) {
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('[ {  "attributes" : {    "type" : "StudentAttributes__c",    "url" : "/services/data/v24.0/sobjects/StudentAttributes__c/a08Q0000004B27GIAS"  },  "Id" : "a08Q0000004B27GIAS",  "Name" : "Paul Coleman"} ]');
        }
        return response;
        
    }   
}