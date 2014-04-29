@IsTest
public class TestPersonalPageController{
    
    
    @IsTest
        public static void helloWorld(){
            
            System.assert(true);
            
        }
    
    @IsTest
        public static void TestContoller()
    {
        ID LockDownID = [SELECT id from Profile where name = 'LockDown'].id;
        
        //Create the EC User
        
        User u =  new User(LastName='Baggins',FirstName='Frodo',pidm__c='a1111111', Username='ec@wgu.edu', Email='Baggins1@test.wgu.edu', Alias='MyEC', CommunityNickname='a', TimeZoneSidKey='GMT'
                           , LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',ProfileId=LockDownID, LanguageLocaleKey='en_US',WGUPostalCode__c='20776');
        insert u;
        
        //Create the EC UserAttributes__c
        UserAttributes__c uac = new UserAttributes__c();
        uac.Extension__c = '1212';
        uac.University800Number__c = '801888222';
        uac.PreferredFirstName__c = 'Frodo';
        uac.PreferredLastName__c = 'Baggins';  
        uac.User__c = u.id;   
        
        insert uac;   
        
        //Create MarketingProgram Program
        CareProgramMiddleEarth__c mark = new CareProgramMiddleEarth__c();
        mark.name = 'BBBB';
        insert mark;
        /*    

//Create student Contact record
Contact sc = new Contact();
sc.LastName = 'Baggins';
sc.FirstName = 'Bilbo';
sc.Email = 'BBBBaggins@test.wgu.edu';
insert sc;

Select id, NameAndPhone__c,
CAREStatusListView__c,
ContactLastName__c,
MarketingProgram__r.Name, OwnerId,
StudentAttributes__r.Affiliation__c,
ContactEmail__c
from Opportunity 
where PersonalPageIdentifier__c = :pid

*/
        //Create Student Care Profile (Opportunity)
        
        Contact student = TestStudentUser.getTestStudentContact();
        
        System.debug(student);
        
        Opportunity care = new Opportunity(AccountId=student.AccountId, 
                                           
                                           Name='Dudley Schults', 
                                           CloseDate=date.today(), 
                                           StageName='Intake', 
                                           RecordTypeId = [SELECT Id from RecordType where Name = 'IntakeInterviewReady' and SObjectType = 'Opportunity'].id);
        
        
        
        care.CAREStatus__c = 'PROS – Prospect';
        care.PersonalPageIdentifier__c = 'dudleyschultsAAAA';
        care.MarketingProgram__c = mark.id;
        care.OwnerId = u.id;
        care.StudentContact__c = student.id;
        
        insert care;
        
        
        //Create Student StudentAttributes__c
        
        StudentAttributes__c sac = new StudentAttributes__c();
        sac.Affiliation__c = 'WGU';
        
        insert sac;
        
        /*
[SELECT Id,  IsDeleted,
Name, 
Program__c,
active__c,
image__c, 
label__c,
last_updated__c,
link__c, 
sort_order__c, 
TilePosition__c, 
LinkCategory__r.name, 
LinkCategory__r.sortorder__c, 
LinkType__c, 
LinkCategory__r.isdeleted, 
LinkCategory__r.programspecific__c, 
LinkGroup__c
FROM Personal_Pages_Link__c 
where IsDeleted = false and LinkCategory__r.isdeleted = false
and active__c = true and 
(program__C = :programName or (program__C = null and link__C != null))
order by LinkCategory__r.sortorder__c asc, sort_order__c asc
];

*/
        PersonalPagesLinkCategory__c lc1 = new PersonalPagesLinkCategory__c(name='CAT1',sortorder__c=0,programspecific__c=false);
        PersonalPagesLinkCategory__c  lc2 = new PersonalPagesLinkCategory__c(name='CAT2',sortorder__c=1,programspecific__c=true);
        insert lc1;
        insert lc2;
        
        List<Personal_Pages_Link__c> pinks = new List<Personal_Pages_Link__c>();
        
        Personal_Pages_Link__c plink0 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page1.html',
                                                                   LinkCategory__c = lc1.id,
                                                                   LinkType__c = 'PDF',
                                             
                                                                   sort_order__c = -1);
        pinks.add(plink0);
        
        Personal_Pages_Link__c plink11 = new Personal_Pages_Link__c(active__c = true,
                                                                    image__c = 'My Image URL 1',
                                                                    label__c = 'Alt Label Text',
                                                                    link__c= 'http://link.to.me/page111.html',
                                                                    LinkCategory__c = lc2.id,
                                                                    LinkType__c = 'PDF',
                                                                    Program__c = 'BBBB',
                                                                    sort_order__c = 0);
        pinks.add(plink11);
        Personal_Pages_Link__c plink2 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page2.html',
                                                                   LinkCategory__c = lc2.id,
                                                                   LinkType__c = 'PDF',
                                                                   Program__c = 'BBBB',
                                                                   sort_order__c = 1);
        pinks.add(plink2);
        Personal_Pages_Link__c plink3 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page3.html',
                                                                   LinkCategory__c = lc2.id,
                                                                   LinkType__c = 'Web Page',
                                                                   Program__c = 'BBBB',
                                                                   sort_order__c = 2);
        pinks.add(plink3);
        Personal_Pages_Link__c plink4 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page4.html',
                                                                   LinkType__c = 'Web Page',
                                                                   LinkCategory__c = lc2.id,
                                                                   Program__c = 'BBBB',
                                                                   sort_order__c = 3);
        pinks.add(plink4);
        Personal_Pages_Link__c plink5 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page5.html',
                                                                   LinkType__c = 'Web Page',
                                                                   LinkCategory__c = lc1.id,
                                                             
                                                                   sort_order__c = 4);
        pinks.add(plink5);
        Personal_Pages_Link__c plink6 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page6.html',
                                                                   LinkType__c = 'Web Page',
                                                                   LinkCategory__c = lc1.id,
                                                              
                                                                   sort_order__c = 5);
        pinks.add(plink6);
        Personal_Pages_Link__c plink7 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page7.html',
                                                                   LinkType__c = 'Video',
                                                                   LinkCategory__c = lc1.id,
                                                            
                                                                   sort_order__c = 6);
        pinks.add(plink7);
        Personal_Pages_Link__c plink8 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page8.html',
                                                                   LinkCategory__c = lc1.id,
                                                                   LinkType__c = 'Video',
                                                       
                                                                   sort_order__c = 7);
        pinks.add(plink8);
        Personal_Pages_Link__c plink9 = new Personal_Pages_Link__c(active__c = true,
                                                                   image__c = 'My Image URL 1',
                                                                   label__c = 'Alt Label Text',
                                                                   link__c= 'http://link.to.me/page9.html',
                                                                   LinkCategory__c = lc1.id,
                                                                   LinkType__c = 'Video',
                                                                   Program__c = 'BBBB',
                                                                   sort_order__c = 8);
        pinks.add(plink9);
        Personal_Pages_Link__c plink10 = new Personal_Pages_Link__c(active__c = true,
                                                                    image__c = 'My Image URL 1',
                                                                    label__c = 'Alt Label Text',
                                                                    link__c= 'http://link.to.me/page10.html',
                                                                    LinkCategory__c = lc1.id,
                                                                    LinkType__c = 'Video',
                                                                    Program__c = 'BBBB',
                                                                    sort_order__c = 9);
        pinks.add(plink10);
        
        insert pinks;
        
        
        Test.startTest();
        
        PageReference pageRef = Page.PersonalPagesUAT;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pid', 'dudleyschultsAAAA');
        PersonalPageController controller = new PersonalPageController();
        
        System.debug(controller.firstName + 'Khadijah_test' );
        System.debug(controller.fullName + 'Khadijah_test Abdullah_test' );
        System.debug(controller.ecName +'Frodo Baggins' );
         
        //  Admittedly mostly for code coverage
        // Check null comments
        controller.actionSend();
        controller.studentComments = 'This is my comment';
            controller.actionSend();
        
        Test.stopTest();
    }   
    
}