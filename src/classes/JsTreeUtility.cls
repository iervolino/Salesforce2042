/*
*Author John Chan
*Slalom
*/
global with sharing class JsTreeUtility {
	public static JsTree createJsTreeFromCourseList(List<WGUCourse__c> courses, Set<String> courseVersionIds) {
		JsTree jsTree = null;
		if (courses != null && courses.size() > 0) {
			List<JsTreeData> courseNode = new List<JsTreeData>();
			
			for (WGUCourse__c course : courses) {
				
				//Create Course Versions
				List<JsTreeData> courseVersionNode = null;
				if (course.WGUCourseVersions__r != null && course.WGUCourseVersions__r.size() > 0) {
					courseVersionNode = new List<JsTreeData>();
					for (WGUCourseVersion__c courseVersion : course.WGUCourseVersions__r) {
						boolean checked = (courseVersionIds != null && courseVersionIds.size() > 0 && courseVersionIds.contains(courseVersion.Id)) ? true : false;
						String courseVersionName = courseVersion.Name + ' v' + courseVersion.MajorVersion__c + ': ' + courseVersion.title__c;
						courseVersionNode.add(new JsTreeData(courseVersionName, new JsTreeDataAttr(courseVersion.Id, checked)));
					}
				}
				
				//Create Course
				courseNode.add(new JsTreeData(course.Name, courseVersionNode));
			}
			jsTree = new JsTree(courseNode);
		}
		return jsTree;
	}
	global class JsTree {
    	public JsTree(List<JsTreeData> dataNode) {
    		this.dataNode = dataNode;
    	}
    	public List<JsTreeData> dataNode;
    }
    
    public class JsTreeData {
    	public JsTreeData(String data, List<JsTreeData> children) {
    		this.data = data;
    		this.children = children;
    	}
    	public JsTreeData(String data, JsTreeDataAttr attr) {
    		this.data = data;
    		this.attr = attr;
    	}
    	public String data;
    	public JsTreeDataAttr attr;
    	public List<JsTreeData> children;
    }
    
    public class JsTreeDataAttr {
    	public JsTreeDataAttr(String value) {
    		this.value = value;
    	}
    	public JsTreeDataAttr(String value, boolean checked) {
    		this.value = value;
    		this.checked = checked;
    	}
    	public String value;
    	public boolean checked;
    }
}