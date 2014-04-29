global with sharing class StudentHandbookURLRewriter implements Site.UrlRewriter{
    
    final String TEACHER_LICENSURE_ARTICLE_URL = '/articles/TeacherLicensureArticle/';
    final String URL_PARAM_IN_FRAME = 'inFrame';

    global PageReference mapRequestUrl(PageReference myFriendlyUrl)
    {
        String url = myFriendlyUrl.getUrl();
        System.debug('StudentHandbookURLRewriter:mapRequestUrl url = ' + url);

        if (myFriendlyUrl.getParameters().get(URL_PARAM_IN_FRAME) != null && myFriendlyUrl.getParameters().get(URL_PARAM_IN_FRAME) != '1' && url.contains(TEACHER_LICENSURE_ARTICLE_URL)) {
            String[] articleUrl = url.substring(TEACHER_LICENSURE_ARTICLE_URL.length(), url.length()).split('/');
            System.debug('StudentHandbookURLRewriter:mapRequestUrl articleUrlName = ' + articleUrl);
        }

        return null;
        /*
        
        
        List<String>  urlStrings = new List<String>();
        if (url.length() <= 1)
        {
             return  myFriendlyUrl;
        }
        
        if (url.length() > 1)
        {
            urlStrings = url.split('&');
        }   
        String urlnamevalue;
        System.debug('urlStringslength' + urlStrings.size());
        for (String s : urlStrings)
        {
            if (s.startsWith('urlName'))
            {
                urlnamevalue = s.removeStartIgnoreCase('urlName=');
            }
            
        }  
        System.debug(urlnamevalue);
        

        
        List<StudentHandbook__kav>  articlesSH = new List<StudentHandbook__kav>();
 		List<FAQArticle__kav>  articlesFAQ = new List<FAQArticle__kav>();
        List<TeacherLicensureArticle__kav>  articlesTLA = new List<TeacherLicensureArticle__kav>();
        articlesSH = [Select  id, KnowledgeArticleId, ArticleType, URLName from StudentHandbook__kav where PublishStatus ='online'  and Language='en_US' and URLName = :urlnamevalue];
        articlesFAQ = [Select  id, KnowledgeArticleId, ArticleType, URLName from FAQArticle__kav where PublishStatus ='online'  and Language='en_US' and URLName = :urlnamevalue];
        articlesTLA = [Select  id, KnowledgeArticleId, ArticleType, URLName from TeacherLicensureArticle__kav where PublishStatus ='online'  and Language='en_US' and URLName = :urlnamevalue];
   
        System.debug(articlesSH);
        System.debug(articlesFAQ);
        System.debug(articlesTLA);
        
        
        if (articlesSH.size()> 0)
        {    
        	System.debug( 'SH:  /PkbWguHome?Id=' + articlesSH.get(0).KnowledgeArticleId + '&articleTypeName=' + articlesSH.get(0).ArticleType + '&urlName=' + articlesSH.get(0).URLName);
        	return new PageReference('/PkbWguHome?Id=' + articlesSH.get(0).KnowledgeArticleId + '&articleTypeName=' + articlesSH.get(0).ArticleType + '&urlName=' + articlesSH.get(0).URLName);    
        }
		
        if (articlesFAQ.size()> 0)
        {
        	System.debug( '/PkbWguHome?Id=' + articlesFAQ.get(0).KnowledgeArticleId + '&articleTypeName=' + articlesFAQ.get(0).ArticleType + '&urlName=' + articlesFAQ.get(0).URLName);
        	return new PageReference('/PkbWguHome?Id=' + articlesFAQ.get(0).KnowledgeArticleId + '&articleTypeName=' + articlesFAQ.get(0).ArticleType + '&urlName=' + articlesFAQ.get(0).URLName);  
        }
        if (articlesFAQ.size()> 0)
        {
        	System.debug( '/PkbWguHome?Id=' + articlesTLA.get(0).KnowledgeArticleId + '&articleTypeName=' + articlesTLA.get(0).ArticleType + '&urlName=' + articlesTLA.get(0).URLName);
        	return new PageReference('/PkbWguHome?Id=' + articlesTLA.get(0).KnowledgeArticleId + '&articleTypeName=' + articlesTLA.get(0).ArticleType + '&urlName=' + articlesTLA.get(0).URLName);  
        }
        
         return  myFriendlyUrl;*/
    }
    
    global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls){
        //System.debug( mySalesforceUrls);
        //return mySalesforceUrls;   
        return null;
    }

}