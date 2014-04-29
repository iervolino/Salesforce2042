/*
 * Author Paul Coleman
 * Western Governors University
 *
 * Date Created Aug 15, 2013 @ 1551 hrs
 * 
 * Class for Exchange Web Service Integration
 *
 * Examples of API usage:

//System.debug( EWSAdapter.sendEmailFrom('bursar@wgu.edu','bursar@wgu.edu','pcoleman@wgu.edu,paul.coleman.dba@gmail.com'.split(','), 'Hello from DEVFULL, check attachments, check Sent Items', 'testing Heroku w/Attachments', EWSAdapter.Priority.High, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') ) );
//System.debug( EWSAdapter.sendEmailReplyTo('bursar@wgu.edu','pcoleman@wgu.edu,paul.coleman.dba@gmail.com'.split(','), 'Hello from DEVFULL, check attachments, check Sent Items', 'testing Heroku w/Attachments', EWSAdapter.Priority.High, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') ) );
//System.debug( EWSAdapter.sendEmail('pcoleman@wgu.edu,paul.coleman.dba@gmail.com'.split(','), 'Hello from DEVFULL, check attachments, check Sent Items', 'testing Heroku w/Attachments', EWSAdapter.Priority.High, '00Pe0000000ka7o,00Pe0000000kaAT'.split(',') ) );
//System.debug( EWSAdapter.sendEmail('pcoleman@wgu.edu,paul.coleman.dba@gmail.com'.split(','), 'Hello from DEVFULL, check Sent Items', 'testing Heroku', EWSAdapter.Priority.Low, null ) );
//System.debug( EWSAdapter.sendEmailSimple('paul.coleman.dba@gmail.com', 'Hello from DEVFULL, check Sent Items', 'testing Heroku Simple' ) );
//System.debug( EWSAdapter.getTimezones() );
//System.debug( EWSAdapter.queryFreeBusy('pcoleman@wgu.edu,toliver@wgu.edu'.split(','),System.now().addDays(-1), System.now(), 'UTC' ) );
//System.debug( EWSAdapter.scheduleMeeting('paul.coleman@wgu.edu','pcoleman@wgu.edu,paul.coleman.dba@gmail.com'.split(','),null,'This meeting will be for...','Test Meeting Subject',System.now(), System.now().addMinutes(60), 'UTC' ) );
//System.debug( EWSAdapter.cancelMeeting('paul.coleman@wgu.edu','00000000642B39A783622F409F7F45E03E03B83F070018FFA207BB28524FBB59F2667763E2B500069782C8BC00005C958B78DC3A5B418A58DF9E2FCB1B410000C2F93CFB0000','This meeting has been cancelled') );

 */
global class EWSAdapter {

    global enum HTTPMethod { GET, POST }
    global enum Priority { Low, Normal, High }
    
    global class EWSAdapterException extends Exception{}
 
    private static final String STUDENT_PROXY = 'salesforce-email@wgu.edu';
    private static final String REST_ENDPOINT = 'https://wgu-exchange.herokuapp.com';
    private static final String API_VERSION = 'v1.0';
    private static final String APEX_API_VERSION = '27.0';
    private static final String APEX_CONTEXT = '/services/Soap/s/'+APEX_API_VERSION;
    private static final String BASE_REST_URL_PREFIX = REST_ENDPOINT + '/services/' + API_VERSION;
    private static final String FREEBUSY = BASE_REST_URL_PREFIX +'/freebusy';
    private static final String SCHEDULE_MTG = BASE_REST_URL_PREFIX +'/schedulemeeting'; 
    private static final String SEND_EMAIL = BASE_REST_URL_PREFIX +'/sendmail'; 
    private static final String CANCEL_MTG = BASE_REST_URL_PREFIX +'/cancelmeeting'; 
    private static final String TIMEZONES = BASE_REST_URL_PREFIX +'/timezones';   
	private static final String emailRegex = '[a-zA-Z0-9\\.\\!\\#\\$\\%\\&\\*\\/\\=\\?\\^\\_\\+\\-\\`\\{\\|\\}\\~\'._%+-]+@[a-zA-Z0-9\\-.-]+\\.[a-zA-Z]+';
	private static final String wguEmailRegex = '[a-zA-Z0-9\\.\\!\\#\\$\\%\\&\\*\\/\\=\\?\\^\\_\\+\\-\\`\\{\\|\\}\\~\'._%+-]+@wgu+\\.edu+';
        
    public EWSAdapter() {}
   
    @RemoteAction
    webservice static String getTimeZones() {
        //scheduleMeeting and queryFreeBusy API calls require a valid MS Exchange TimeZone id parameter
        //this method returns the complete set of timezone ids so a valid id value can be sent
        //this method can also be used to quickly test for service status/functionality
        return send(EWSAdapter.HTTPMethod.GET, TIMEZONES, null);
    }
    
    @RemoteAction
    webservice static String scheduleMeeting(String meetingHost,String[] requiredAttendees,String[] optionalAttendees,String htmlBody,String subject,DateTime startTime,DateTime stopTime,String timezone) {
        EWSAdapter.ScheduleMeetingParms parms = new EWSAdapter.ScheduleMeetingParms();
		if ( Pattern.matches(wguEmailRegex, meetingHost) ) {
        	parms.meetingOrganizer = meetingHost; //the person who owns the calendar event in Outlook, must be primary SMTP address in Exchange
		} else {
			throw new EWSAdapterException('Meeting Host must be a valie WGU mailbox');
		}
		if ( requiredAttendees == null || requiredAttendees.isEmpty() ) {
			throw new EWSAdapterException('At least one valid email address must be specified for requiredAttendees');
		}   	
        for ( String mailbox: requiredAttendees ) {
			if ( !Pattern.matches(emailRegex, mailbox) ) {
    			throw new EWSAdapterException('Invalid requiredAttendees mailbox address: ' + mailbox);
			}   	
        }
        parms.requiredAttendees = requiredAttendees;  //array of email addresses, e.g., Course Mentor's email address and Student's email address

        if ( optionalAttendees != null && !optionalAttendees.isEmpty() ) {	
	        for ( String mailbox: optionalAttendees ) {
				if ( mailbox != '' && !Pattern.matches(emailRegex, mailbox) ) {
	    			throw new EWSAdapterException('Invalid optionalAttendees mailbox address: ' + mailbox);
				}   	
	        }
        }
        parms.optionalAttendees = optionalAttendees;  //array of email addresses, e.g., Student Mentor's email address
		if ( htmlBody != null && !htmlBody.equals('') ) {
	        parms.message = htmlBody; //informational html message [i.e., the body of calendar item] to be sent to attendee's (required) 
		} else {
			throw new EWSAdapterException('HtmlBody (meeting message) parameter must be a non-null and non-empty string value');
		}
		if ( subject != null && !subject.equals('') ) {
	        parms.subject = subject; //plain text or base64-encoded html
		} else {
			throw new EWSAdapterException('Meeting Subject parameter must be a non-null and non-empty string value');
		}
		if ( startTime == null ) {
			throw new EWSAdapterException('Meeting StartTime parameter must be a non-null');
		}
        parms.startTime = startTime;
		if ( stopTime == null ) {
			throw new EWSAdapterException('Meeting StopTime parameter must be a non-null');
		}
        parms.stopTime = stopTime;
        parms.timezone = timezone==null || timezone==''? 'UTC': timezone;
        return send(EWSAdapter.HTTPMethod.POST, SCHEDULE_MTG, parms.encode() );
    }
    
    @RemoteAction
    webservice static String cancelMeeting(String meetingHost,String meetingEntryId,String htmlBody) {
        EWSAdapter.CancelMeetingParms parms = new EWSAdapter.CancelMeetingParms();
		if ( meetingHost != null && Pattern.matches(wguEmailRegex, meetingHost) ) {
	        parms.meetingOrganizer = meetingHost; //the person who owns the calendar event in Outlook, must be primary SMTP address in Exchange
		} else {
			throw new EWSAdapterException('Meeting Host must be a valid WGU mailbox');
		}
		if ( meetingEntryId != null && !meetingEntryId.equals('') ) {
	        parms.meetingEntryId = meetingEntryId; //exchange meeting item id, as returned in a queryFreeBusy result for a person's own calendar (querying user [meetingOrganizer/meetingHost] must own the meeting to cancel it)
		} else {
			throw new EWSAdapterException('MeetingEntryId parameter must be a non-null and non-empty string value');
		}
		if ( htmlBody != null && !htmlBody.equals('') ) {
	        parms.message = htmlBody; //informational html message to be sent to attendee's (required), becomes the new body of calendar item
		} else {
			throw new EWSAdapterException('HtmlBody (cancellation message) parameter must be a non-null and non-empty string value');
		}
        return send(EWSAdapter.HTTPMethod.POST, CANCEL_MTG, parms.encode() );
    }
    
    @RemoteAction
    webservice static String queryFreeBusy(String[] mailboxes,DateTime startTime,DateTime stopTime,String timezone) {
        EWSAdapter.FreeBusyParms parms = new EWSAdapter.FreeBusyParms();
		if ( mailboxes != null && !mailboxes.isEmpty() ) {
	        parms.mailboxes = mailboxes; //email addresses of calendars to query
	        for ( String mailbox: mailboxes ) {
				if ( !Pattern.matches(wguEmailRegex, mailbox) ) {
	    			throw new EWSAdapterException('Invalid WGU mailbox address (@wgu.edu required): ' + mailbox); 
				}   	
	        }
		} else {
			throw new EWSAdapterException('mailboxes parameter must be a non-null and non-empty array of WGU mailbox (email) addresses');
		}
		if ( startTime == null ) {
			throw new EWSAdapterException('Meeting StartTime parameter must be a non-null');
		}
        parms.startTime = startTime;

		if ( stopTime == null ) {
			throw new EWSAdapterException('Meeting StopTime parameter must be a non-null');
		}
        parms.stopTime = stopTime;
        parms.timezone = timezone == null || timezone==''? 'UTC': timezone;
        return send(EWSAdapter.HTTPMethod.POST, FREEBUSY, parms.encode() );
    }
    
    //send to comma-seperated list of addresses, Normal priority, no attachments
	@RemoteAction
    webservice static String sendEmailSimpleEncoded(String mailboxes,String htmlBody,String subject) {
    	return sendEmail(mailboxes.split(','), EncodingUtil.base64Decode(htmlBody).toString(), subject, EWSAdapter.Priority.Normal, null);
	}   
	
    //send to comma-seperated list of addresses, Normal priority, no attachments
	@RemoteAction
    webservice static String sendEmailSimple(String mailboxes,String htmlBody,String subject) {
    	return sendEmail(mailboxes.split(','), htmlBody, subject, EWSAdapter.Priority.Normal, null);
	}   
	
	//use a different replyTo address than current user's from address
	@RemoteAction
    webservice static String sendEmailReplyTo(String replyToAddress, String[] mailboxes,String htmlBody,String subject,EWSAdapter.Priority importance,String[] attachments) {
         return sendEmailFrom(Userinfo.getUserEmail(), replyToAddress, mailboxes, htmlBody, subject, importance, attachments);
    }

	@RemoteAction
    webservice static String sendEmail(String[] mailboxes,String htmlBody,String subject,EWSAdapter.Priority importance,String[] attachments) {
         return sendEmailReplyTo(Userinfo.getUserEmail(), mailboxes, htmlBody, subject, importance, attachments);
    }
    
    
	// complete sendmail options, send mail from an OrgWideEmailAddress__c.Address__c record
	@RemoteAction
    webservice static String sendEmailFrom(String fromAddress, String replyToAddress, String[] mailboxes,String htmlBody,String subject,EWSAdapter.Priority importance,String[] attachments) {
        EWSAdapter.SendEmailParms parms = new EWSAdapter.SendEmailParms();  
		if ( mailboxes == null || mailboxes.isEmpty() ) {
			throw new EWSAdapterException('At least one valid email address must be specified');
		}   	
        for ( String mailbox: mailboxes ) {
			if ( !Pattern.matches(emailRegex, mailbox) ) {
    			throw new EWSAdapterException('Invalid mailbox address: ' + mailbox);
			}   	
        }
        parms.mailboxes = mailboxes; //array of email addresses
		if ( htmlBody != null && !htmlBody.equals('') ) {
	        parms.message = htmlBody;
		} else {
			throw new EWSAdapterException('HtmlBody (message) parameter must be a non-null and non-empty string value');
		}
		
		if ( subject != null && !subject.equals('') ) {
	        parms.subject = subject; //plain text or base64-encoded html
		} else {
			throw new EWSAdapterException('Email Subject parameter must be a non-null and non-empty string value');
		}
        parms.priority = importance==null? String.valueOf(EWSAdapter.Priority.Normal): String.valueOf(importance);
        parms.attachments = attachments; //array of attachment record ids
		
		if ( fromAddress == null || !Pattern.matches(wguEmailRegex, fromAddress) ) {
			throw new EWSAdapterException('Invalid WGU from address (@wgu.edu required): ' + fromAddress);
		} else {
			//Validate that current user is allowed to send from this address, based on private OrgWideEmailAddress__c object access via sharing rules
			if ( fromAddress != Userinfo.getUserEmail() && [SELECT count() FROM OrgWideEmailAddress__c WHERE Address__c = :fromAddress] == 0) {
				throw new EWSAdapterException('NOT AUTHORIZED to send email on behalf of: ' + fromAddress);
			}
		} 
        parms.fromAddress = fromAddress;

		replyToAddress = (replyToAddress == null || replyToAddress == ''? fromAddress: replyToAddress);
		if ( !Pattern.matches(wguEmailRegex, replyToAddress) ) {
			throw new EWSAdapterException('Invalid WGU replyTo address (@wgu.edu required): ' + replyToAddress);
		}  
        parms.replyToAddress = replyToAddress;
        
        return send(EWSAdapter.HTTPMethod.POST, SEND_EMAIL, parms.encode() );    	
    }
    
    
    
    //BEGIN Private support code section for EWS API
    
    private virtual class Parms {
        public Parms() {
            this.sessionId = UserInfo.getSessionId();
            this.userId = UserInfo.getUserId();    
            this.serviceEndpoint = URL.getSalesforceBaseUrl().toExternalForm() + APEX_CONTEXT + '/' +  UserInfo.getOrganizationId();        
        }
        public String sessionId;    
        public String userId;
        public String serviceEndpoint;
        public virtual override String toString() {
            return null;
        }
        public virtual String encode() {
            return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', EncodingUtil.base64Decode('VW5Mb0trVGgxc1BMM2VlWg=='), Blob.valueOf(this.toString())));
        }
    }
    
    private class ScheduleMeetingParms extends Parms {
        public ScheduleMeetingParms() {
            super();
        }
        public String meetingOrganizer;
        public String[] requiredAttendees;
        public String[] optionalAttendees;
        public String message;
        public String subject;
        public DateTime startTime;
        public DateTime stopTime;
        public String timezone;
        public override String toString() {
            if ( stopTime.getTime() <= startTime.getTime() ) {
                throw new EWSAdapterException('FreeBusyParms.StartTime must be before FreeBusyParms.StopTime');
            }
            optionalAttendees = optionalAttendees==null? new String[0] : optionalAttendees;
            message = Encodingutil.base64Encode( Blob.valueOf(message) );
            return '{ "ScheduleMeetingParms": '+ JSON.serialize(this) + '}';
        }
    }    
        
    private class FreeBusyParms extends Parms {
        public FreeBusyParms() {
            super();
            // meetingOrganizer must be the primary SMTP address in Exchange
            this.meetingOrganizer = UserInfo.getUserType().equals('CSPLitePortal')? STUDENT_PROXY: Userinfo.getUserEmail(); //the person who's mailbox returns full details for this query, equivalent viewing "My calendar" details if "I" am making the query
        }
        public String meetingOrganizer;
        public String[] mailboxes;
        public DateTime startTime;
        public DateTime stopTime;
        public String timezone;
        public override String toString() {
            if ( stopTime.getTime() <= startTime.getTime() ) {
                throw new EWSAdapterException('FreeBusyParms.StartTime must be before FreeBusyParms.StopTime');
            }
            return '{ "FreeBusyParms": '+ JSON.serialize(this) + '}';
        }
    }
    private class SendEmailParms extends Parms {
        public SendEmailParms() {
            super();
            if ( UserInfo.getUserType().equals('CspLitePortal') ) {
                new EWSAdapterException('Students are NOT AUTHORIZED to send email through the Exchange Web Services Adapter');
            } else {
                // fromAddress must be the primary SMTP address in Exchange
                this.fromAddress = Userinfo.getUserEmail(); 
            }
        }
        public String fromAddress;
        public String replyToAddress;
        public String[] mailboxes;
        public String message;
        public String subject;
        public String priority;
        public String[] attachments;
        public override String toString() {
            attachments = attachments==null? new String[0] : attachments;
            message = Encodingutil.base64Encode( Blob.valueOf(message) );
            return '{ "SendEmailParms": '+ JSON.serialize(this) + '}';
        }
    }
    private class CancelMeetingParms extends Parms {
        public CancelMeetingParms() {
            super();
        }
        public String meetingOrganizer;
        public String meetingEntryId;
        public String message;
        public override String toString() {
        	super.toString(); //code coverage
            message = Encodingutil.base64Encode( Blob.valueOf(message) );
            return '{ "CancelMeetingParms": '+ JSON.serialize(this) + '}';
        }
    }
        
    private static String send( HTTPMethod method, String url, String body ) { 
        HTTPResponse response;  
            
            HttpRequest request = new HttpRequest();  
            request.setEndpoint( url );
            
            if ( method == EWSAdapter.HTTPMethod.POST ) {
                request.setHeader('Content-Type', 'text/plain');
                request.setBody(body);
            } 
            
            request.setMethod( String.ValueOf(method) );
            System.debug(Logginglevel.INFO, request);
	    	request.setTimeout(30000); //heroku timeout is 30 seconds per HTTP request
            response = (!Test.IsRunningTest())? new Http().send(request) : new HTTPResponse();
            if ( Test.isRunningTest() ) {
              response.setStatusCode(200);
              response.setStatus('OK');
              if ( url.equals(SEND_EMAIL) ) {
	              response.setBody('{\"SendEmailResult\":{\"ResponseMessage\":{\"responseCode\":\"NoError\",\"responseClass\":\"Success\"}}}');
              } else if ( url.equals(CANCEL_MTG) ) {
	              response.setBody('{\"CancelMeetingResult\":{\"ResponseMessage\":{\"responseCode\":\"NoError\",\"responseClass\":\"Success\"}}}');
              } else if ( url.equals(FREEBUSY) ) {
	              response.setBody('{\"QueryFreeBusyResult\":{\"ResponseMessage\":{\"responseCode\":\"NoError\",\"responseClass\":\"Success\"}}}');
              } else if ( url.equals(SCHEDULE_MTG) ) {
	              response.setBody('{\"ScheduleMeetingResult\":{\"ResponseMessage\":{\"responseCode\":\"NoError\",\"responseClass\":\"Success\"}}}');
              } else if ( url.equals(TIMEZONES) ) {
	              response.setBody('{\"TimeZonesResult\":{\"ResponseMessage\":{\"responseCode\":\"NoError\",\"responseClass\":\"Success\"}}}');
              }
            }
            System.debug(Logginglevel.INFO, response);
            System.debug(Logginglevel.INFO, response.getBody()==null? '' : response.getBody().replace('\n', ''));
            
        return response.getBody()==null?'':response.getBody();
    }
 
}