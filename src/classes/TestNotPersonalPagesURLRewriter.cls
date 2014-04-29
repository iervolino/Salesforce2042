@IsTest
public class TestNotPersonalPagesURLRewriter 

{
    @IsTest
        public static void helloWorld(){
            
            System.assert(true);
            
        }   
    
     @IsTest
        public static  void perurlrw(){
            NotPersonalPagesURLRewriter pprw = new NotPersonalPagesURLRewriter();
            PageReference pr = new PageReference('http://test.me/frank1234');
    
            PageReference opr = pprw.mapRequestUrl(pr);
            String afterURL = opr.getUrl();
   
            System.assert(afterURL.contains('pid=frank1234'));
            
        }   
    
  
    

    
}