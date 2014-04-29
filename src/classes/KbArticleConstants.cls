/*
*Author John Chan
*Slalom
*/
public with sharing class KbArticleConstants {
    public enum PublicationStatus {
        Draft,
        Online,
        Archived
    }
    
    public enum Channel {
        AllChannels,
        App,
        Pkb,
        Csp,
        Prm
    }
    
    public static final String ArticleTypeWelcomeVideo = 'Welcome Video';
    public static final String ArticleTypeGettingStarted = 'Getting Started';
    public static final String ArticleTypeLearningResource = 'Learning Resource Navigation';
    public static final String ArticleTypeCourseAtAGlance = 'Course At-a-Glance';
    public static final String ArticleTypeOther = 'Other';
}