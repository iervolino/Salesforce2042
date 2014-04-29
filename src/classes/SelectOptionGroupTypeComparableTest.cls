@IsTest
public class SelectOptionGroupTypeComparableTest {
    
    @IsTest static void compareToTest_GroupBothNull() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, null);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, null);
        
        System.assertEquals(0, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_GroupANull() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, null);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_GroupBNull() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, null);
        
        System.assertEquals(-1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_ACollegeBDegree() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
        groupTypeA.GroupLevel__c = 'College';
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
        groupTypeB.GroupLevel__c = 'Program';
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(-1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_ACollegeBCourse() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
        groupTypeA.GroupLevel__c = 'College';
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
        groupTypeB.GroupLevel__c = 'Course';
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(-1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_ACourseBCollege() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
        groupTypeA.GroupLevel__c = 'Course';
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
        groupTypeB.GroupLevel__c = 'College';
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_ADegreeBCollege() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
        groupTypeA.GroupLevel__c = 'Program';
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
        groupTypeB.GroupLevel__c = 'College';
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_ADegreeBCourse() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
        groupTypeA.GroupLevel__c = 'Program';
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
        groupTypeB.GroupLevel__c = 'Course';
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(-1, objectA.compareTo(objectB));
    }
    
    @IsTest static void compareToTest_Equal() {
        SelectOption optionA = new SelectOption('1', 'Option A');
        SelectOption optionB = new SelectOption('2', 'Option B');
        
        CommunityAccessControl__c groupTypeA = new CommunityAccessControl__c();
        groupTypeA.GroupLevel__c = 'Course';
        CommunityAccessControl__c groupTypeB = new CommunityAccessControl__c();
        groupTypeB.GroupLevel__c = 'Course';
    
        SelectOptionGroupTypeComparable objectA = new SelectOptionGroupTypeComparable(optionA, groupTypeA);
        SelectOptionGroupTypeComparable objectB = new SelectOptionGroupTypeComparable(optionB, groupTypeB);
        
        System.assertEquals(1, objectA.compareTo(objectB));
    }
    
}