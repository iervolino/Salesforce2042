@isTest
private class TestPkbWguArticleViewController {
	
	@isTest static void testLoad() {
		StudentHandbook__kav studentHandbookArticle = new StudentHandbook__kav();
		studentHandbookArticle.Title = 'Unit Test kbWguArticleViewController';
		studentHandbookArticle.UrlName = studentHandbookArticle.Title.replace(' ', '-');
		insert studentHandbookArticle;
		studentHandbookArticle = [SELECT Id, KnowledgeArticleId FROM StudentHandbook__kav WHERE Id = :studentHandbookArticle.Id];
		KbManagement.PublishingService.publishArticle(studentHandbookArticle.KnowledgeArticleId, true);

		ApexPages.KnowledgeArticleVersionStandardController ctl = new ApexPages.KnowledgeArticleVersionStandardController(studentHandbookArticle);
		PkbWguArticleViewController articleViewController = new PkbWguArticleViewController(ctl);
		System.assertEquals(studentHandbookArticle.Id, articleViewController.theAV.Id);
		System.assertEquals(studentHandbookArticle.KnowledgeArticleId, articleViewController.theArticle.Id);
	}
}