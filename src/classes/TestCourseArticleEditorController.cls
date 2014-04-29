@isTest
private with sharing class TestCourseArticleEditorController {
	 
	static testMethod void testOnLoadCreate() {
		CourseArticleEditorController controller = new CourseArticleEditorController();
		System.assertEquals(controller.createText, controller.subHeaderTitle);
		System.assertEquals(controller.displayPropertyNone, controller.displayProperty);
		System.assertEquals(null, controller.courseArticle.Id);
		System.assert(controller.courseArticle.isVisibleInCsp);
	}
	
	static testMethod void testOnLoadEdit() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticle__kav courseArticle = TestCourseArticleHelper.createCourseArticleFull('Load Edit', 
					Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'Test Course');
			PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?id=' + courseArticle.Id);
			Test.setCurrentPage(pageRef);
			
			CourseArticleEditorController controller = new CourseArticleEditorController();
			System.assertEquals(controller.editText, controller.subHeaderTitle);
			System.assertEquals(controller.displayPropertyBlock, controller.displayProperty);
			System.assertEquals(courseArticle.Id, controller.courseArticle.Id);
			System.assertEquals(courseArticle.Title, controller.courseArticle.Title);
			System.assertEquals(courseArticle.FileUpload__Name__s, controller.uploadFileTitle);
			
			Set<Id> kbCourseVersionLinkIds = new Set<Id>();
			for (KnowledgeBaseWguCourseVersionLink__c kbCourseVersionLink : [SELECT Id FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id]) {
				kbCourseVersionLinkIds.add(kbCourseVersionLink.Id);
			}
			for (KnowledgeBaseWguCourseVersionLink__c kbCourseVersionLink : controller.courseAssignmentList) {
				System.assert(kbCourseVersionLinkIds.contains(kbCourseVersionLink.Id));
			}
		}
	} 
	
	static testMethod void testPreviousUrl() {
		final String returnUrl = '/apex/fakeReturnPage&SearchTerm=searchTermTest&CourseCode=courseCodeTest&CourseId=courseIdTest&RefineSearchTerm=refineSearchTermTest';
		PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?rtn=' + returnUrl);
		Test.setCurrentPage(pageRef);
		
		CourseArticleEditorController controller = new CourseArticleEditorController();
		System.assertEquals(returnUrl, controller.previousUrl);
	}
	
	static testMethod void testGetArticleTypes() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticleEditorController controller = new CourseArticleEditorController();
			Set<String> articleTypeValues = new Set<String>();
			articleTypeValues.add('None');
			for(Schema.PicklistEntry pickList : CourseArticle__kav.ArticleType__c.getDescribe().getPickListValues()) {
	        	articleTypeValues.add(pickList.getValue());
	        }
	        for (SelectOption articleSelectOption : controller.getArticleTypes()) {
	        	System.assert(articleTypeValues.contains(articleSelectOption.getValue()));
	        }
		}
	}
	
	static testMethod void testGetCourseListJson() {
		final Integer courseVersionCount = 2;
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			WGUCourse__c course = TestCourseArticleHelper.createCourse('Unit Test Course', courseVersionCount, 1);
			TestCourseArticleHelper.createMentorKbCourseManagement(mentorUser, course);
				
			List<WGUCourse__c> courseList = [SELECT Name, (Select Id, Name, MajorVersion__c, Title__c From WGUCourseVersions__r) FROM WGUCourse__c WHERE Id = :course.Id];
			Set<String> courseVersionIds = new Set<String>();
			courseVersionIds.add(courseList[0].WGUCourseVersions__r[0].Id);
			JsTreeUtility.JsTree jsTree = JsTreeUtility.createJsTreeFromCourseList(courseList, courseVersionIds);
			Map<String, JsTreeUtility.JsTreeData> jsTreeDataFirstChildMap = new Map<String, JsTreeUtility.JsTreeData>();
			for (JsTreeUtility.JsTreeData jsTreeData : jsTree.dataNode[0].children) {
				jsTreeDataFirstChildMap.put(jsTreeData.data, jsTreeData);
			}
		
			
			JsTreeUtility.JsTree jsTreeRemote = CourseArticleEditorController.getCourseListJson(courseList[0].WGUCourseVersions__r[0].Id);
			System.assertEquals(jsTree.dataNode[0].data, jsTreeRemote.dataNode[0].data);
			for (JsTreeUtility.JsTreeData jsTreeData : jsTreeRemote.dataNode[0].children) {
				System.assert(jsTreeDataFirstChildMap.containsKey(jsTreeData.data));
				System.assertEquals(jsTreeDataFirstChildMap.get(jsTreeData.data).attr.checked, jsTreeData.attr.checked);
			}
		}
	}
	
	static testMethod void testValidateInputFileNameLength() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.uploadFileContents = Blob.valueOf('test');
			controller.uploadFileName = 'Test Validate Looooooooooooooooooooooooooooooooooooooooger then 40 characters';
			controller.courseAssignmentsString = 'test course assignment';
			System.assertEquals(null, controller.save());
			System.assertEquals(1, ApexPages.getMessages().size());
		}
	}
	
	static testMethod void testValidateInputFileTitleLength() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.uploadFileContents = Blob.valueOf('test');
			controller.uploadFileTitle = 'Test Validate Looooooooooooooooooooooooooooooooooooooooger then 40 characters';
			controller.courseAssignmentsString = 'test course assignment';
			System.assertEquals(null, controller.save());
			System.assertEquals(1, ApexPages.getMessages().size());
		}
	}
	
	static testMethod void testValidateCourseAssignment() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.uploadFileName = 'Test Title';
			System.assertEquals(null, controller.save());
			System.assertEquals(1, ApexPages.getMessages().size());
		}
	}
	
	static testMethod void testValidateRichTextArea() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.uploadFileName = 'Test Title';
			controller.courseAssignmentsString = 'test course assignment';
			String richTextArea = '';
			for (integer i = 0; 33 > i; i++) {
				richTextArea += ('1000 character stringgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg' +
						'ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg' +
						'ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg' +
						'ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg' +
						'ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg' +
						'ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg' +
						'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg');
			}
			controller.courseArticle.RichTextArea__c = richTextArea;
			System.assertEquals(null, controller.save());
			System.assertEquals(1, ApexPages.getMessages().size());
		}
	}
	
	static testMethod void testSaveNew() {
		final String courseArticleTitle = 'Test Title';
		final String courseArticleFileName = 'Test File Name';
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			List<WGUCourseVersion__c> newCourseVersions = TestCourseArticleHelper.createCourseVersions(1, 'New Test Course');
			
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.courseArticle.Title = courseArticleTitle;
			controller.uploadFileContents = Blob.valueOf('test');
			controller.uploadFileName = courseArticleFileName;
			controller.courseAssignmentsString = newCourseVersions.get(0).Id;
			controller.uploadContentType = Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue();
			PageReference reference = controller.save();
			System.assertEquals(0, ApexPages.getMessages().size());
			
			CourseArticle__kav updatedCourseArticle = [SELECT Title, FileUpload__Name__s , FileUpload__ContentType__s  FROM CourseArticle__kav WHERE Id = :reference.getParameters().get('id')];
			System.assertEquals(courseArticleTitle, updatedCourseArticle.Title);
			System.assertEquals(courseArticleFileName, updatedCourseArticle.FileUpload__Name__s);
			System.assertEquals(Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), updatedCourseArticle.FileUpload__ContentType__s);
			
			KnowledgeBaseReporting__c kbReport = [SELECT Title__c, ArticleCreatedBy__c, PublishStatus__c FROM KnowledgeBaseReporting__c WHERE KnowledgeArticleVersionId__c = :reference.getParameters().get('id')];
			System.assertEquals(courseArticleTitle, kbReport.Title__c);
			System.assertEquals(mentorUser.Id, kbReport.ArticleCreatedBy__c);
			System.assertEquals(KbArticleConstants.PublicationStatus.Draft.name(), kbReport.PublishStatus__c);
			
			System.assert(reference.getUrl().contains(Page.CourseArticleEditor.getUrl()));
		}
	}
	
	static testMethod void testPublishArticleDraftAndUpdateCourseVersion() {
		final String courseArticleSummary = 'Test Publish Update';
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticle__kav courseArticle = TestCourseArticleHelper.createCourseArticleFull('Publish Article Test', 
					Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'Test Course');
			PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?id=' + courseArticle.Id);
			Test.setCurrentPage(pageRef);
			 
			Set<Id> newCourseVersionIds = new Set<Id>();
			String newCourseAssignemnts = '';
			for (WGUCourseVersion__c newCourseVersion : TestCourseArticleHelper.createCourseVersions(2, 'New Test Courses')) {
				newCourseVersionIds.add(newCourseVersion.Id);
				newCourseAssignemnts += newCourseVersion.Id + ',';
			}
			
			for (KnowledgeBaseWguCourseVersionLink__c kbCourseLink : [SELECT WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id]) {
				System.assert(!newCourseVersionIds.contains(kbCourseLink.WGUCourseVersion__c));
			}
			
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.courseAssignmentsString = newCourseAssignemnts;
			controller.courseArticle.Summary = courseArticleSummary;
			PageReference redirectReference = controller.publishArticle();
			System.assertEquals(Page.WGUArticles.getUrl(), redirectReference.getUrl());
			
			courseArticle = [SELECT Summary, PublishStatus FROM CourseArticle__kav WHERE Id = :courseArticle.Id];
			System.assertEquals(courseArticleSummary, courseArticle.Summary);
			System.assertEquals(KbArticleConstants.PublicationStatus.Online.name(), courseArticle.PublishStatus);
			
			for (KnowledgeBaseWguCourseVersionLink__c kbCourseLink : [SELECT WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id]) {
				System.assert(newCourseVersionIds.contains(kbCourseLink.WGUCourseVersion__c));
			}
		}
	}
	
	static testMethod void testSaveAndCloseAndEditOfOnline() {
		final String courseArticleTitle = 'Test Title Update';
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			CourseArticle__kav courseArticle = TestCourseArticleHelper.createCourseArticleFull('Publish Article Test', 
					Schema.SObjectType.CourseArticle__kav.fields.ArticleType__c.getPickListValues()[0].getValue(),
					Schema.SObjectType.CourseArticle__kav.fields.FileUpload__ContentType__s.getPickListValues()[0].getValue(), 'Test Course');
			PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?id=' + courseArticle.Id);
			Id knowledgeArticleId = [SELECT KnowledgeArticleId FROM CourseArticle__kav WHERE Id = :courseArticle.Id].KnowledgeArticleId;
			KBManagement.PublishingService.publishArticle(knowledgeArticleId, false); 
			Test.setCurrentPage(pageRef);
			
			String courseAssignemnts = '';
			
			for (KnowledgeBaseWguCourseVersionLink__c kbCourseLink : [SELECT WGUCourseVersion__c FROM KnowledgeBaseWguCourseVersionLink__c WHERE KnowledgeArticleVersionId__c = :courseArticle.Id]) {
				courseAssignemnts += kbCourseLink.WGUCourseVersion__c + ',';
			}
			
			CourseArticleEditorController controller = new CourseArticleEditorController();
			controller.courseAssignmentsString = courseAssignemnts;
			PageReference redirectReference = controller.saveAndClose();
			System.assertEquals(Page.WGUArticles.getUrl(), redirectReference.getUrl());
			
			CourseArticle__kav priorArticle = [SELECT PublishStatus FROM CourseArticle__kav WHERE Id = :courseArticle.Id];
			System.assertEquals(KbArticleConstants.PublicationStatus.Archived.name(), priorArticle.PublishStatus);
			
			CourseArticle__kav newArticle = [SELECT Id, PublishStatus FROM CourseArticle__kav WHERE KnowledgeArticleId = :knowledgeArticleId AND PublishStatus = 'Online'];
			System.assertEquals(KbArticleConstants.PublicationStatus.Online.name(), newArticle.PublishStatus);
			System.assertNotEquals(courseArticle.id, newArticle.Id);
		}
	}
	
	static testMethod void testDeleteArticle() {
		User mentorUser = TestCourseArticleHelper.getTestUser('testmentor', 'Mentor', true);
		System.runAs(mentorUser) {
			List<CourseArticle__kav> courseArticles = TestCourseArticleHelper.createCourseArticle(1);
			PageReference pageRef = new PageReference(Page.CourseArticleEditor.getUrl() + '?id=' + courseArticles[0].Id);
			Test.setCurrentPage(pageRef);
			
			CourseArticleEditorController controller = new CourseArticleEditorController();
			PageReference redirectReference = controller.deleteArticle();
			
			System.assertEquals(Page.WGUArticles.getUrl(), redirectReference.getUrl());
			System.assertEquals(0, [SELECT COUNT() FROM CourseArticle__kav WHERE Id = :courseArticles[0].Id]);
			
			//Exception test, article is already deleted attemting to delete again
			System.assertEquals(0, ApexPages.getMessages().size());
			System.assert(String.isEmpty(controller.errorMessage));
			redirectReference = controller.deleteArticle();
			System.assertEquals(null, redirectReference);
			System.assertEquals(1, ApexPages.getMessages().size());
			System.assert(String.isNotEmpty(controller.errorMessage));
		}
	}
}