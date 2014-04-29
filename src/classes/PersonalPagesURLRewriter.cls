global with sharing class PersonalPagesURLRewriter implements Site.UrlRewriter{
    
    
    global PageReference mapRequestUrl(PageReference myFriendlyUrl)
    {
  
            String url = myFriendlyUrl.getUrl();    
 
  			
            Integer lastSlash = url.lastIndexOf('/'); 
        
        	System.debug(url);
            String urlMinusPid = url.substring(0,lastSlash + 1);  
            
                                
            String pid = url.substringAfterLast('/');   
            
 	    if (url.containsIgnoreCase('Error'))
        {
        return  myFriendlyUrl;
        }
        if (url.length() < 4)
        {
        return  myFriendlyUrl;
        }
      //  call 'http://cnn.com';
        //return null;
           return new PageReference(  urlMinusPid + '?pid=' + pid);
     //   return new PageReference('http://cnn.com');
 

        
    }
    global List<PageReference> generateUrlFor(List<PageReference>   mySalesforceUrls){
              System.debug( mySalesforceUrls);
        return mySalesforceUrls;   
    }
    
   
}