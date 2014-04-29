// Accesible from ~/services/apexrest/leadqual
@RestResource(urlMapping='/gradeaccess')
global class GradeAccessRestService{
    
    @HttpPost
    global static String gradLeadCare(String jsonstring)
    {

        
        AnswerInternalClass student= (AnswerInternalClass)JSON.deserialize(jsonstring, AnswerInternalClass.class);
        
       Set<String> questions = student.data.keySet();
      List<String> answrs = new List<String>();
      
      for (String q : questions)
      {
          answrs.add(student.data.get(q));
      }
      
      
      List<EnrollmentAnswers__C> activeAnswers = [SELECT AnswerText__c, Id, QuestionKey__c, QuestionText__c, Multiplier__c ,MultiplierValue__c, Value__c FROM EnrollmentAnswers__c
        where answertext__C in :answrs];
       
       Double leadScoreResult = 0.0;
        
       for (EnrollmentAnswers__C ans : activeAnswers)
       {
       
           if (ans.QuestionText__c.equals('What year did you graduate from high school?'))
           {
             System.debug('GRAD');
                Long gradYear = Long.valueOf(ans.AnswerText__c);
                Long expectedAge = (2014 - gradYear) + 18;
                System.debug(expectedAge);
                // Possitive grade if between 25 and 40
                if (expectedAge >= 25 && expectedAge <= 40){
                    leadScoreResult += 0.206504671635885;
                } 
                // Otherwise, no change
                else {
                    leadScoreResult += 0.0;
                }
             
             
           }
           else
           {
                    leadScoreResult += (ans.Multiplier__c * ans.MultiplierValue__c);  
           
           }
         
         }
         leadScoreResult += -5.56783865284557;
        Double finalResult = Math.exp(leadScoreResult)/ (1 + Math.exp(leadScoreResult));
        
        System.debug(finalResult );
        
        // Return as ScoreResult Object
        System.debug( CAREforceUtility.decodeGrade(finalResult));
       
       
       
       
       
        
       return null;
                     
    }
    
    
    
  public class AnswerInternalClass{
      String wguainf {get;set;}
      Map<String,String> data {get;set;}
      
        
  
        
  }
    

}