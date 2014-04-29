public with sharing class AccountTestingUtility {
  public TestingStudentInfo student1 {get;set;}
  public TestingMentorInfo mentor1 {get;set;}
  public TestingStudentInfo student2 {get;set;}
  public TestingMentorInfo mentor2 {get;set;}
  public static String boxName {get;set;}
  public static String StudentAccountRecordId {get;set;}
  public static Profile StudentProfile {get;set;}
  public static Profile MentorProfile {get;set;}
  public static UserRole MentorRole {get;set;}
  public String onlyWorkPidm;
  static {
    if(StudentAccountRecordId == null) {
      List<RecordType> rts = [select id,Name
          from RecordType
          where Name in ('StudentRecord') //StudentRecord
          and sObjectType = 'Contact'];
      for(RecordType rt : rts) {
        if(rt.Name == 'StudentRecord') {
          StudentAccountRecordId = rt.id;
        }
      }
    }
    if(MentorRole == null) {
      List<UserRole> roles = [select Id,Name
        from UserRole
        where Name = 'Mentor'];
      for(UserRole role : roles) {
        if(role.Name == 'Mentor') {
          MentorRole = role;
        }
      }
    }
    if(StudentProfile == null) {
      List<Profile> pros = [select Id,Name
            from Profile
            where Name in ('Student Profile','Mentor')];
      for(Profile p : pros) {
        if(p.Name == 'Student Profile') {
          StudentProfile = p;
        } else if(p.Name == 'Mentor') {
          MentorProfile = p;
        }
      }
    }
  }

  public void onlyWorkWith(String pidm) {
    onlyWorkPidm = pidm;
  }

  public AccountTestingUtility(String pBoxName) {
    boxName = pBoxName;
    if(mentor1 == null) {
      mentor1 = new TestingMentorInfo(
        'Teri','Ralto',//name
        boxName,
        '16',//pidm
        'tryahlto',//alias
        10 //capacity
      );
      student1 = new TestingStudentInfo(
        'Pete','Schweddy',
        boxName,
        '11',
        'pschwedd',
        '123456'
      );

      mentor2 = new TestingMentorInfo(
        'Bilbo','Bagghins',
        boxName,
        '17',
        'bbaggins',
        1
      );
      student2 = new TestingStudentInfo(
        'Frodo','Baggins',
        boxName,
        '13',
        'fbaggins',
        '123465'
      );
    }
  }

  public void save() {
  	
  	/*
  	Contact testContact = TestStudentUser.getTestStudentContact();
  	List<Contact> testContacts = new List<Contact>();
  	testContacts.add(testContact);
  	Contact testContact2 = testContact.clone(true);
  	*/
  	
    
    List<Contact> accs = new List<Contact>();
    if(onlyWorkPidm == null) {
      accs.add(student1.contact);
      accs.add(student2.contact);
    } else if(onlyWorkPidm == student1.PIDM) {
      accs.add(student1.contact);
    } else if(onlyWorkPidm == student2.PIDM) {
      accs.add(student2.contact);
    }
    upsert accs;

    if(onlyWorkPidm == null) {
      mentor1.initContact();
      mentor1.initProfile();
      mentor1.initUser();

      mentor2.initContact();
      mentor2.initProfile();
      mentor2.initUser();

      student1.initContact();
      student1.initProfile();
      student1.initUser();

      student2.initContact();
      student2.initProfile();
      student2.initUser();
    } else if(onlyWorkPidm == student1.PIDM) {
      student1.initContact();
      student1.initProfile();
      student1.initUser();
    } else if(onlyWorkPidm == student2.PIDM) {
      student2.initContact();
      student2.initProfile();
      student2.initUser();
    }

    List<User> users = new List<User>();
    List<Map<String,String>> uProps = new List<Map<String,String>>();
    if(onlyWorkPidm == null) {
      users.add(mentor1.user);
      uProps.add(mentor1.userProp);
      users.add(mentor2.user);
      uProps.add(mentor2.userProp);
      users.add(student1.user);
      uProps.add(student1.userProp);
      users.add(student2.user);
      uProps.add(student2.userProp);
    } else if(onlyWorkPidm == student1.PIDM) {
      users.add(student1.user);
      uProps.add(student1.userProp);
    } else if(onlyWorkPidm == student2.PIDM) {
      users.add(student1.user);
      uProps.add(student1.userProp);
    }

    if(Test.isRunningTest()) {
      List<User> insertUsers = new List<User>();
      List<User> updateUsers = new List<User>();
      for(User u : users) {
        if(u.Id == null) {
          insertUsers.add(u);
        } else {
          updateUsers.add(u);
        }
      }

      User myU = [Select Name,Username
        from User
        where Id = :UserInfo.getUserId()];
      System.runAs(myU) {
        insert insertUsers;
        update updateUsers;
      }
    } else {
      upsertUserProp(JSON.serialize(uProps));
    }
    //List<Account> updatedAccounts = new List<Account>();
    List<Contact> updatedContacts = new List<Contact>();
    if(onlyWorkPidm == null) {
      student1.assignMentor(mentor1);
      student2.assignMentor(mentor2);
     // updatedAccounts.add(student1.account);
      //updatedAccounts.add(student2.account);
      updatedContacts.add(student1.contact);
      updatedContacts.add(student2.contact);
    } else if(onlyWorkPidm == student1.PIDM) {
     // updatedAccounts.add(student1.account);
      updatedContacts.add(student1.contact);
    } else if(onlyWorkPidm == student2.PIDM) {
     // updatedAccounts.add(student2.account);
      updatedContacts.add(student2.contact);
    }

  //  update updatedAccounts;
    update updatedContacts;
  }

  @future
  public static void upsertUserProp(String jsonUsers) {
    List<Map<String,String>> users = (List<Map<String,String>>)JSON.deserialize(
               jsonUsers, List<Map<String,String>>.class);
    List<User> updatedUsers = new List<User>();
    List<User> insertedUsers = new List<User>();
    for(Map<String,String> up : users) {
      User newU;
      if(up.containsKey('Id')) {
        String selectStatement = 'select Id';
        String userId = up.remove('Id');
        for(String key : up.keySet()) {
          selectStatement += ',' + key;
        }
        selectStatement += ' from User where Id = \'' + userId + '\'';
        newU = Database.query(selectStatement);
      } else {
        newU = new User();
      }
      for(String key : up.keySet()) {
        if(key == 'IsEmployee__c') {
          if(up.get(key) == 'true') {
            newU.IsEmployee__c = true;
          } else {
            newU.IsEmployee__c = false;
          }
        } else {
          newU.put(key,up.get(key));
        }
      }
      if(newU.Id == null) {
        insertedUsers.add(newU);
      } else {
        updatedUsers.add(newU);
      }
    }
    if(updatedUsers.size() > 0) {
      update updatedUsers;
    }
    if(insertedUsers.size() > 0) {
      insert insertedUsers;
    }
  }

  public with sharing class TestingStudentInfo extends TestingUserInfo {
    public String StudentId {get;set;}

    public TestingStudentInfo(String firstName,String lastName,String pBoxName,String pidm,String alias,String pStudentId) {
        super(firstName,lastName,pBoxName,pidm,alias);
        this.StudentId = pStudentId;
        initContact();
        initTermDates();
    }
    public override void initUser() {
        super.initUser();
        if(user.Id == null && user.ContactId == null) {
            user.ContactId = contact.Id;
            userProp.put('ContactId',contact.Id);
        }
    }

    public void initTermDates() {
      Date termStart = Date.Today();
      termStart = Date.newInstance(termStart.Year(),termStart.Month(),1);
      termStart = termStart.addMonths(-4);
      this.contact.TermStartDate__c = termStart;
      this.contact.TermEndDate__c = termStart.addMonths(6).addDays(-1);
    }

    public override void initContact() {
      super.initContact();
      this.contact.StudentId__c = this.StudentId;
      this.contact.PIDM__c = this.PIDM;
      this.contact.BannerStatus__c = 'FDPTestStudent';
    }

    public void assignMentor(TestingMentorInfo mentor) {
        contact.Mentor__c = mentor.user.Id;
        contact.MentorPidm__c = mentor.user.PIDM__c;
    }
  }

  public with sharing abstract class TestingUserInfo {
    public String FirstName {get;set;}
    public String LastName {get;set;}
    public String Email {get;set;}
    public String PIDM {get;set;}
    public String Alias {get;set;}
    public String UserName {get;set;}
    public Account account {get;set;}
    public Contact contact {get;set;}
    public Profile profile {get;set;}
    public UserRole role {get;set;}
    public User user {get;set;}
    public Map<String,String> userProp {get;set;}

    public TestingUserInfo(String firstName,String lastName,String pBoxName,String pidm,String alias) {
        this.FirstName = firstName;
        this.LastName = lastName;
        this.Email = firstName.toLowerCase().substring(0,1) + lastName.toLowerCase().substring(0,5) + '@wgu.edu';
        this.UserName = this.Email + '.' + pBoxName.toLowerCase();
        this.PIDM = pidm;
        this.Alias = alias;
    }

public virtual void initAccount() {
        try {
          account = [select id,
            FirstName,
            LastName,
            AccountEmail__c,
            PIDM__c,
            RecordTypeId
            from Account
            where PIDM__c = :PIDM];
        } catch(Exception ex) {
          account = new Account();
        }
        account.FirstName = FirstName;
        account.LastName = LastName;
        account.AccountEmail__c = Email;
        account.PIDM__c = PIDM;
        account.RecordTypeID = AccountTestingUtility.StudentAccountRecordId;
    }

    public virtual void initContact() {
        try{
        	contact = [select Id,
        		FirstName,
        		LastName,
        		email,
                TermCode__c,
                TermStartDate__c,
                TermEndDate__c,
                StudentId__c,
                Mentor__c,
                EulaAgreementDate__c,
                PIDM__c
          from Contact
          where PIDM__C = :PIDM];
        } catch(Exception ex) {
          contact = new Contact();
        }
        contact.FirstName=FirstName;
        contact.LastName=lastname;
        contact.Email=email;
        contact.pidm__C=pidm;
        contact.RecordTypeId=StudentAccountRecordId;
        contact.EulaAgreementDate__c = null;
    }

    public virtual void initProfile() {
        profile = AccountTestingUtility.StudentProfile;
    }

    public virtual void initUser() {
        userProp = new Map<String,String>();
        List<User> users = [select alias,
          email,
          firstname,
          lastname,
          username,
          PIDM__c,
          emailEncodingKey,
          languagelocaleKey,
          timezonesidkey,
          profileId,
          ContactId,
          IsEmployee__c,
          UserRoleId
          from User
          where PIDM__c = :PIDM
          or username = :email];
        if(users.size() == 0) {
          user = new User();
        } else if(users.size() == 1) {
          user = users.get(0);
          userProp.put('Id',user.Id);
        } else if (users.size() > 1) {
          Boolean foundMatchingUsername = false;
          for(User u : users) {
            if(u.username == email) {
              user = u;
              userProp.put('Id',user.id);
              foundMatchingUsername = true;
            }
          }
          if(!foundMatchingUsername) {
            user = users.get(0);
            userProp.put('Id',user.Id);
          }
        }
        user.alias = Alias;
        userProp.put('Alias',Alias);
        user.email = Email;
        userProp.put('Email',Email);
        user.firstname = FirstName;
        userProp.put('Firstname',FirstName);
        user.lastname = LastName;
        userProp.put('Lastname',LastName);
        user.username = UserName;
        userProp.put('Username',UserName);
        user.pidm__c = pidm;
        userProp.put('PIDM__c',pidm);
        user.emailencodingkey = 'UTF-8';
        userProp.put('EmailEncodingKey','UTF-8');
        user.languagelocalekey = 'en_US';
        userProp.put('LanguageLocaleKey','en_US');
        user.localesidkey = 'en_US';
        userProp.put('LocaleSidKey','en_US');
        user.timezonesidkey = 'America/Los_Angeles';
        userProp.put('TimeZoneSidKey','America/Los_Angeles');
        user.ProfileId = profile.Id;
        userProp.put('ProfileId',profile.Id);
        user.IsEmployee__c = false;
        userProp.put('IsEmployee__c','false');
    }
  }

  public with sharing class TestingMentorInfo extends TestingUserInfo {
    public Integer MentorCapacity {get;set;}
    public Mentor__c Mentor {get;set;}

    public TestingMentorInfo(String firstName,String lastName,String pBoxName,String pidm,String alias, Integer mentorCapacity) {
        super(firstName,lastName,pBoxName,pidm,alias);
        initAccount();
        this.MentorCapacity = mentorCapacity;
    }

    // Mentors do not have a contact record
    public override void initContact() {
    }

    public override void initProfile() {
        profile = AccountTestingUtility.MentorProfile;
        role = AccountTestingUtility.MentorRole;
    }

    // Mentors do not have an account record
   // public override void initAccount() {
   // }

    public override void initUser() {
        super.initUser();
        user.IsEmployee__c = true;
        userProp.put('IsEmployee__c','true');
        user.UserRoleId = role.Id;
        userProp.put('UserRoleId',role.Id);
    }
  }

  public static String getRandomString(Integer sLength) {
    string randomString = '';
    while(randomString.length() < sLength) {
      Integer i = Math.mod(Crypto.getRandomInteger(),255);
      List<Integer> myIs = new List<Integer>();
      myIs.add(i);
      String s = String.fromCharArray(myIs);
      Pattern p = Pattern.compile('[a-z]');
      Matcher m = p.matcher(s);
      if(m.matches()) {
        randomString += s;
      }
    }
    return randomString;
  }
}