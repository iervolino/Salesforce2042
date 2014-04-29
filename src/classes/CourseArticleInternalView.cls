/*
*Author John Chan
*Slalom
*Wrapper class to pull in saved date for scheduled publish/archive from reporting table in KnowledgeBaseReporting__c.  This was done because we do not have access within the API
*to grab this date.
*/
global class CourseArticleInternalView {
	public CourseArticleInternalView(CourseArticle__kav courseArticle) {
		this.courseArticle = courseArticle;
	}
	public CourseArticle__kav courseArticle { get; private set; }
	public Date ScheduledPublishDate { get; set; }
	public Date ScheduledArchiveDate { get; set; }
}