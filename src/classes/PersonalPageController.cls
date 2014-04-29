public class PersonalPageController {
    
    public String firstName { get; set; }
    public Integer step { get; set; }
    public String lastName { get; set; }
    public String ecName { get; set; }
    public String ecEmail { get; set; }
    public String ecPhone { get; set; }
    public String ecPhoto { get; set; }
    public String programName { get; set; }
    public String personalPagesLinksJson { get; set; }
 //   public List<PageLink> tileLinks { get; set; }
    public Map<Integer,PageLink> tileLinks { get; set; }
    public List<LinkCategory> pageLinks { get; set; }
    public String errorMessage { get; set; }
    public String studentEmail{get; set; }
    public Map<String, String> textAreaMap { get; set; }
    public String studentComments {get; set; }
    public String studentPhone {get; set; }
    public String fullName { get; set; }
    public String careProgramTitle { get; set; }

    
    public PageReference initCheck()
    {
        String pid = Apexpages.currentPage().getParameters().get('pid');
        if(pid == null) {
            PageReference pag = new PageReference('/apex/PersonalPagesErrorPage');
            pag.setRedirect(true);
            return pag;
       }
       
        List<Opportunity> profiles = [Select id, NameAndPhone__c,
                                      CAREStatusListView__c,
                                      ContactLastName__c,
                                      MarketingProgram__r.Name, OwnerId,
                                      StudentAttributes__r.Affiliation__c,
                                      ContactEmail__c
                                      from Opportunity 
                                      where PersonalPageIdentifier__c = :pid];
        
        if (profiles.size() < 1)
        {

            PageReference pag = new PageReference('/apex/PersonalPagesErrorPage');
            pag.setRedirect(true);
            return pag;
        }
       // PageReference pag = new PageReference('http://devfull-wgu.cs16.force.com/personalpage/' + pid);
        return null;
    }
    
    public PersonalPageController() {
        String pid = Apexpages.currentPage().getParameters().get('pid');
        if(pid == null) {
            

             return;
        }
        
        String errorMessage = 'none';
       List<Opportunity> profiles = [Select id, NameAndPhone__c,
                                      CAREStatusListView__c,
                                      ContactLastName__c,
                                     MarketingProgram__r.CAREProgramTitle__c,
                                      MarketingProgram__r.Name, OwnerId,
                                      StudentAttributes__r.Affiliation__c,
                                      ContactEmail__c
                                      from Opportunity 
                                      where PersonalPageIdentifier__c = :pid];
        
        if (profiles.size() < 1)
        {

             return;
        }
        
        Opportunity profile = profiles.get(0);
        firstName = profile.NameAndPhone__c;
        studentEmail = profile.ContactEmail__c;
        fullName = profile.NameAndPhone__c + ' ' + profile.ContactLastName__c;
        
        if (profile.CAREStatusListView__c == 'PROS')
        {
            step = 1;
        }
        else if (profile.CAREStatusListView__c == 'APIN' || 
                 profile.CAREStatusListView__c == 'APNN' ||
                 profile.CAREStatusListView__c == 'PRAP' ||
                 profile.CAREStatusListView__c == 'APCO' )
        {
            step = 2;
        }
        else if (profile.CAREStatusListView__c == 'APAC')
        {
            step = 3;
        }
                 
        else {
            step = 4;
        }

        
        List<UserAttributes__c> owners = [SELECT Id, OwnerId, IsDeleted, Name, RecordTypeId,
                                          
                                          Extension__c, Personal800Number__c, 
                                          PreferredFirstName__c, PreferredLastName__c, UserEmail__c,
                                          University800Number__c, User__c,  JsonConfigData__c FROM UserAttributes__c
                                          where  User__c = :profile.OwnerId];
        

        ecName = owners.get(0).PreferredFirstName__c + ' ' +  owners.get(0).PreferredLastName__c;
        ecEmail = owners.get(0).UserEmail__c;
        ecPhone = owners.get(0).University800Number__c + ' x' + owners.get(0).Extension__c; 
        
        
        //ConnectApi.UserDetail ecUserDetail = ConnectApi.ChatterUsers.getUser(null, owners.get(0).OwnerId);
        //String ecPhoto = ecUserDetail.photo.smallPhotoUrl;
        careProgramTitle  = profile.MarketingProgram__r.CAREProgramTitle__c;   
     
        programName = profile.MarketingProgram__r.name;
        String affiliation = profile.StudentAttributes__r.Affiliation__c;
        //System.debug('programName: ' + programName);
        
        List<Personal_Pages_Link__c> personalPagesLinks = 
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
      //  System.debug(personalPagesLinks);
        LinkCategory currentCategory;
        pageLinks = new List<LinkCategory>();
      //  tileLinks = new PageLink[12];
      tileLinks  = new Map<Integer,PageLink>();
        
        for(Personal_Pages_Link__c link : personalPagesLinks) {
     //       System.debug(link);
            String nameLink = link.LinkCategory__r.name;
                        
            if(currentCategory == null ||   currentCategory.name != nameLink  ) {
                
                currentCategory = new LinkCategory(nameLink);
                
                pageLinks.add(currentCategory);
            }
            
            String linkType = link.LinkType__c;
            if (linktype == 'PDF') {
                linktype = 'pdf';
            } else if (linktype == 'Web Page') {
                linktype = 'link';
                
            } else if (linktype == 'Video') {
                linktype = 'video';
            }
            else if (linktype == 'Image'){
                 linktype = 'video';
            } 
                
            PageLink pageLink = new PageLink(linkType,
                                             link.link__c,
                                             link.label__c,
                                             link.TilePosition__c
                                             );
             currentCategory.linkList.add(pageLink);
           // System.debug('PageLink: ' + pageLink);
            if(link.TilePosition__c != null && link.TilePosition__c >= 0 && link.TilePosition__c < 12) {
           //    tileLinks[(Integer)link.TilePosition__c] = pageLink;
            //    System.debug('link.TilePosition__c' + link.TilePosition__c);
               tileLinks.put((Integer)link.TilePosition__c, pageLink);
          //      for (Integer i =0; i < 12; i++)
          //      {
         //           System.debug('tileLink ' + i + ' : ' + tileLinks[i]);
         //           }
             //   System.debug('tileLinks' + tileLinks[(Integer)link.TilePosition__c]);
                
            }
            // System.debug(tileLinks);
        }
        
        for (LinkCategory lc: pageLinks)        
        {
            Boolean includeProgram = false;
            for (PageLink pl : lc.linkList)
            {
                if (pl.tilePos  == 0)
                {
                    includeProgram =true;
                    break;
                }
            }
            if (includeProgram )
            {
                lc.name += ': ' + careProgramTitle;
                break;
            }
        }
        
        personalPagesLinksJson = JSON.serialize(personalPagesLinks);
        
        List<PersonalPagesTextArea__c> textAreaList = [SELECT Name,TextArea__c FROM PersonalPagesTextArea__c];
        
        textAreaMap = new Map<String, String>();
        for(PersonalPagesTextArea__c textArea : textAreaList) {
            textAreaMap.put(textArea.name, textArea.textArea__c);
        }
        
        fillInBlankTileItems();
    }
    
    private void fillInBlankTileItems() {
       for(integer i = 0; i < 12; i++) {
       if (tileLinks.get(i) == null)
       {
           tileLinks.put(i,new PageLink('none', '', 'none', (Decimal) i));
         //    System.debug('Null Link' + i);
       }

       //       System.debug(tileLinks[i]);
      //      if(tileLinks[i] == null) {
      //          tileLinks[i] = new PageLink();
      //          System.debug('Null Link' + i);
      //     }
        }
    }
    
    public class PageLink {
        
        public String type { get; set; }
        public String address { get; set; }
        public String label { get; set; }
        public Decimal tilePos{ get; set; }
       public Boolean isNotBlank;
         public Boolean isBlank;
        
        public Boolean getIsBlank()
        {
            if ((address == null) || address.length() < 1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
                public Boolean getIsNotBlank()
        {
           
                return !getIsBlank();
     
        }
        
        
        public PageLink() {}
        
        public PageLink(String type, String address, String label, Decimal tilePos) {
            this.type = type;
            this.address = address;
            this.label = label;
            this.tilePos = tilePos;
            this.isNotBlank= isNotBlank;
            this.isBlank= isBlank;
        }
        
    }
    
    public class LinkCategory {
        
        public String name { get; set; }
        public List<PageLink> linkList { get; set; }
        
        public LinkCategory(String name) {
            this.name = name;
            linkList = new List<PageLink>();
        }
        
    }
    
    public void actionSend() {
        List<String> listofst =  new List<String>();
        if (!(studentComments == null))
        {
            listofst = studentComments.split('\n');
        }
        //studentComments.replaceAll('(\r\n|\n)', '<br />');
     //   system.debug(studentComments);
        String[] recipients = new String[]{ecEmail};
            Messaging.reserveSingleEmailCapacity(recipients.size());
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setSenderDisplayName(fullName);
        msg.setReplyTo(studentEmail);
        msg.setToAddresses(recipients);
        msg.setSubject('Personal Page Message from ' + fullName );
        String htmlBody = 'Student Name: ' + fullName + '<br/>';
        htmlBody += 'Student Email Address: ' + studentEmail + '<br/>';
        htmlBody += 'Student Phone: ' + studentPhone + '<br/>';
        htmlBody += 'Student Comments: <br/>';
        for (String s: listofst)
        {
            htmlBody += s + '<br/>';
        }
        msg.setHtmlBody(htmlBody );
        //  msg.setPlainTextBody('Student Name: ' + fullName + '\nStudent Email Address: ' + studentEmail + '\nStudent Phone: ' + studentPhone + '\nStudent Comments: ' +   studentComments);
        msg.setSaveAsActivity(false);
        msg.setUseSignature(false);
        
        if (Test.isRunningTest())
        {
        }
        else
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {msg}, false);
            
            
            
        }
        
        studentComments = null;
       
        // PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
        //pageRef.setRedirect(true);
        // return pageRef;
        
    }
    
}