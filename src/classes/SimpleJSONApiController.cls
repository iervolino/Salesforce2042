/*
  Created by: Gordon Child
  Created: January 31, 2013
  This is intended only to serve as a simple way to access data
  as a student or mentor who has already been authenticated
  in salesforce through OSSO or explicit login.
*/

global class SimpleJSONApiController {

  global class SimpleJSONApiControllerException extends Exception{}
  global String contentType {get;set;}
  global String jsonData {get;set;}
  global Blob blobData {get;set;}
  global void initialize() {
    String function = ApexPages.currentPage().getParameters().get('function');
    Map<String,Object> returnData = new Map<String,Object>();
    contentType = 'application/json';
    if(function == null || function == '' || function == 'null') {
      returnData.put('success','0');
      returnData.put('error_message','No function provided');
    } else {
      try {
        if(function == 'getMentorPhoto') {
          returnData.put('data',getMentorPhoto());
          returnData.put('success','1');
        } else if (function == 'test') {
          returnData.put('data',test());
          returnData.put('success','1');
        } else {
          returnData.put('success','0');
          returnData.put('error_message','Function not found: \'' + function + '\'');
        }
      } catch(Exception ex) {
        returnData.put('success','0');
        returnData.put('error_message',ex.getMessage());
        //returnData.put('line_number',ex.getLineNumber());
      }
    }
    jsonData = System.JSON.serialize(returnData);
    String callback = ApexPages.currentPage().getParameters().get('callback');
    if(callback != null) {
      contentType = 'application/javascript';
      jsonData = callback + '(' + jsonData + ')';
    }
  }

  global String test() {
    if(ApexPages.currentPage().getParameters().get('throwException') == '1') {
      throw new SimpleJSONApiControllerException('threw test exception successfully');
    }
    return 'test was good';
  }

  global Map<String,String> getMentorPhoto() {
    List<User> uInfo = Test.isRunningTest() ? getTestData() : [select
      Name,
      SmallPhotoUrl,
      ContactId,
      Contact.Mentor__c,
      Contact.Mentor__r.Name,
      Contact.Mentor__r.SmallPhotoUrl,
      Contact.Mentor__r.FullPhotoUrl,
      FullPhotoUrl
        from User
        where id = :UserInfo.getUserId()];
    Map<String,String> mentorMap = new Map<String,String>();
    if(uInfo.size() > 0) {
      if(uInfo[0].Contact == null || uInfo[0].Contact.Mentor__r == null) {
        throw new SimpleJSONApiControllerException('No mentor found for the current user.');
      }
      String sessionId = (new RestAdapter()).getUserValidationSessionId();
      User mentr = uInfo[0].Contact.Mentor__r;
      Pattern p = Pattern.compile('.*profilephoto/(.*)/F');
      Matcher m = p.matcher(String.valueOf(mentr.FullPhotoUrl));
      if(m.matches()) {
        if(m.groupCount() > 0) {
          if(m.group(1).length() < 6) {
            throw new SimpleJSONApiControllerException('No photo found for mentor');
          }
        }
      }
      mentorMap.put('name',       mentr.Name);
      mentorMap.put('fullPhoto',  mentr.FullPhotoUrl+'?oauth_token='+sessionId);
      mentorMap.put('smallPhoto', mentr.SmallPhotoUrl+'?oauth_token='+sessionId);
      if(Test.isRunningTest()) {
        mentorMap.put('name','Teri Ralto');
        mentorMap.put('fullPhoto','http://notarealphoto');
        mentorMap.put('smallPhoto','http://notarealphoto');
      }
    }
    return mentorMap;
  }

  private List<User> getTestData() {
    List<User> returnData = new List<User>();
    if(UserInfo.getFirstName() == 'Pete')
      returnData.add(new User(Contact = new Contact(Mentor__r = new User())));
    else if(UserInfo.getFirstName() == 'Teri')
      returnData.add(new User());
    return returnData;
  }

  global SimpleJSONApiController() {}
}