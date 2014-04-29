public class HttpWeather {

    public static String getWeather(String zipcode) {
        Http h = new Http();
        String uri = 'http://api.wunderground.com/api/5b6d5232cd3a1fc5/conditions/q/' + zipcode + '.json';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(uri);
        req.setMethod('GET');
        
        // Send the request and get the response
        HttpResponse res = h.send(req);
        return res.getBody();   
    
    }
    
    public static Double getTemp(String body){
        JSONParser parser = JSON.createParser(body);
        Double temp;
        while(parser.nextToken() != null) {
            if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'temp_c')) {
                parser.nextToken();
                temp = parser.getDoubleValue();
            }
        }
        System.debug('----------------------->' + temp);
        return temp;
    }
}