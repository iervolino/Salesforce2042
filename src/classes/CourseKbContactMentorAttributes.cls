/*
*Author John Chan
*Slalom
*Attributes to pass back and forth between component and controller
*/
public with sharing class CourseKbContactMentorAttributes {
	public boolean isVisible { get; set; }
	public boolean displayMessages { get; set; }
		
	public CourseKbContactMentorAttributes() {
		isVisible = false;
		displayMessages = false;
	}
}