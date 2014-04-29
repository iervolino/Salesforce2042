public with sharing class PkbWguArticleViewController extends pkb_Controller {
	public PkbWguArticleViewController(ApexPages.KnowledgeArticleVersionStandardController ctl) {
		setQueryStringParms();
    	getSessionCookie();

	    SObject article = ctl.getRecord();
	    String knowledgeArticleId = (String)article.get('KnowledgeArticleId');
	    theKad = new KnowledgeArticleData(knowledgeArticleId, selectedLanguage);
      	theAV = theKad.theAV;
        List<PKB_Article_Feedback_Deflection__c> afds = [
          select
            Id
          from PKB_Article_Feedback_Deflection__c
          where
            Session_ID__c = :sessionId and
            Article_Number__c = :theKad.articleNumber
        ];
        feedbackRecorded = !afds.isEmpty();
		theArticle = [SELECT Id FROM KnowledgeArticle WHERE Id = :knowledgeArticleId];
	}
}