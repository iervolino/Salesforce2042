@IsTest
public class TestDiscountsEmailHandler{

    @IsTest static void emailHandlerTest() {
    	Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Help';
        email.fromname = 'Testy McTesterson';
        email.htmlBody = 'I have a question about something.';
        email.fromAddress = 'test@wgu.edu';
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
        email.headers=new Messaging.InboundEmail.Header[1];
        hditem.name='Date';
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;  
        
        Test.startTest();
       	User sysAdmin = [SELECT Id from User where alias = 'sadmi' LIMIT 1];
       	System.runAs( sysAdmin ) {
             DiscountsEmailHandler emailHandler = new DiscountsEmailHandler();
             emailHandler.handleInboundEmail(email, env);          
      	}
      	Test.stopTest();
        
        List<Case> caseList = [SELECT RecordType.Name, OwnerId FROM Case];
        System.assertEquals(1, caseList.size());
        System.assertEquals('Discounts', caseList.get(0).RecordType.Name);
        
        Group queue = [SELECT Id FROM Group WHERE Name = 'Discounts' AND Type = 'Queue'];
        System.assertEquals(queue.Id, caseList.get(0).OwnerId);
    }
    
}