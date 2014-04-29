public with sharing class SendSmsUtil {
	
	public static void createOutboundMessage(String message, String contactId) {
		List<Contact> contactList = [SELECT Id FROM Contact WHERE Id = :contactId];
		if(contactList.isEmpty()) {
			return;
		}

		createOutboundMessage(message, contactList.get(0));
	}

	public static void createOutboundMessage(String message, Contact con) {
		String destinationPhoneNumber;

		OutboundSmsMessage__c sms = new OutboundSmsMessage__c();
		sms.DestinationPhoneNumber__c = destinationPhoneNumber;
		sms.Message__c = message;
		insert sms;
	}

}