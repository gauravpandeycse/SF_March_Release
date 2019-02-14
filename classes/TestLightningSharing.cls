/******************************************************************************************************************************************************************
 * Author:      Shane McLaughlin (shane.mclaughlin@salesforce.com, https://github.com/mshanemc/LightningSharing)
 * Company:     Salesforce
 * Title:       Lightning Components + Apex to implement adhoc sharing in Lightning Experience
 * Description: Sharing logic class
 * Test Class:  TestLightningSharing
 * History:     Michael Simkin (msimkin@salsforce.com)  - minor changes for better test coverage and code readability
 * 	20/06/2018 - JEBU/SF - Disabled triggers and processes in TestDataSetup
 ******************************************************************************************************************************************************************/
@isTest
private class TestLightningSharing {

	@isTest
    static void testCoverExceptions () {
        insert new Pricebook2 (IntegrationId__c='21100',IsActive=true, ImcdCompany__c='21100', Name='21100', DefaultCurrencyIsoCode__c='EUR');
        ID wrongId = [SELECT Id FROM Pricebook2 WHERE IntegrationId__c = '21100'].Id;
        delete [SELECT Id FROM Pricebook2 WHERE Id =: wrongId];

        try { LightningSharing.canIEditPerms(wrongId); } catch (Exception e) {}
        try { LightningSharing.deletePerm(wrongId, wrongId); } catch (Exception e) {}
		try { LightningSharing.upsertPerm(wrongId, wrongId, 'bogus'); } catch (Exception e) {}
		try { LightningSharing.getSharingDescribe(wrongId); } catch (Exception e) {}
        try { LightningSharing.buildQuery(wrongId); } catch (Exception e) {}
	}
    
	@isTest
  static void test_sayMyName() {
    final Lead ld = [SELECT Id, Name FROM Lead LIMIT 1];

    Test.startTest();

    final String rsjson = LightningSharing.sayMyName(ld.Id);

    Test.stopTest();

    LightningSharing.recordStuff rs = (LightningSharing.recordStuff) JSON.deserialize(rsjson, LightningSharing.recordStuff.class);

    System.assertEquals('Lead', rs.objectType);
    System.assertEquals(ld.Name, rs.recordName);
  }

	static testMethod void testSOSL() {
  	LightningSharing.doSOSL('McLaughlin', 'Lead');
  }

  static testMethod void testReturning() {
    system.assertEquals('User(Id, Name, UserType WHERE UserType IN (\'Standard\', \'PowerCustomerSuccess\', \'PowerPartner\'))', LightningSharing.getReturning('User'));
    system.assertEquals('Group(Id, Name, Type)', LightningSharing.getReturning('Group'));
    system.assertEquals('Custom__c(Id, Name)', LightningSharing.getReturning('Custom__c'));
    system.assertEquals('Lead(Id, Name)', LightningSharing.getReturning('Lead'));
  }

  static testMethod void testuserTypes() {
  	LightningSharing.huh('PowerCustomerSuccess');
  	LightningSharing.huh('PowerPartner');
  	LightningSharing.huh('CustomerSuccess');
  	LightningSharing.huh('CsnOnly');
  	LightningSharing.huh('CSPLitePortal');
  	system.assertEquals('MadeUpStuff', LightningSharing.huh('MadeUpStuff'));
  }

  static testMethod void testInnerClass(){
  	LightningSharing.sharingHolder sh = new LightningSharing.sharingHolder();
  	sh.UserOrGroupName = 'test';
  	sh.SubType = 'test';
  	sh.UserOrGroupType = 'test';
  	sh.UserOrGroupID = 'test';
  	sh.AccessLevel = 'test';
  	sh.RowCause = 'test';

    system.assertEquals(sh.UserOrGroupName, 'test');
    system.assertEquals(sh.SubType, 'test');
    system.assertEquals(sh.UserOrGroupType, 'test');
    system.assertEquals(sh.UserOrGroupID, 'test');
    system.assertEquals(sh.AccessLevel, 'test');
    system.assertEquals(sh.RowCause, 'test');
  }

  static testMethod void testGetSharings() {
  	list<lead> l = [select id from lead];
  	LightningSharing.getSharings(l[0].id);

  	list<Opportunity> o = [select id from Opportunity];
  	LightningSharing.getSharings(l[0].id);

    list<Opportunity> ptos = [select id from Opportunity];
    list<Opportunity> rotos = [select id from Opportunity];

    LightningSharing.getSharings(ptos[0].id);
    LightningSharing.getSharings(rotos[0].id);
  }

  static testMethod void testcanIEditPermsAdmin() {
  	list<lead> l = [select id from lead];
  	LightningSharing.canIEditPerms(l[0].id);

    list<Opportunity> ptos = [select id from Opportunity];
    list<Opportunity> rotos = [select id from Opportunity];

    boolean perm = LightningSharing.canIEditPerms(ptos[0].id);
    system.assertEquals(perm, true);
    perm = LightningSharing.canIEditPerms(rotos[0].id);
    system.assertEquals(perm, true);
  }

  static testMethod void testcanIEditPermsAdminNonOwner() {
    list<Opportunity> ptos = [select id from Opportunity];
    list<Opportunity> rotos = [select id from Opportunity];

    user u = createAdmin();
    boolean perm1;
    boolean perm2;

  	system.runAs(u){
      perm1 =LightningSharing.canIEditPerms(ptos[0].id);
      perm2 =LightningSharing.canIEditPerms(rotos[0].id);
  	}

    system.assertEquals(perm1, true);
    system.assertEquals(perm2, true);

  }

  static testMethod void testDelete() {

  	//list<lead> l = [select id from Lead];
    list<Opportunity> ptos = [select Id from Opportunity];
  	user u = createUsers(1)[0];

    LightningSharing.upsertPerm(u.id, ptos[0].id, 'Edit');

  	LightningSharing.deletePerm(u.id, ptos[0].id);
  }


  static testMethod void testUpsertPerm() {
  	list<Opportunity> o = [select id from Opportunity];
  	list<lead> l = [select id from Lead];
    list<Opportunity> ptos = [select id from Opportunity];
    list<Opportunity> rotos = [select id from Opportunity];

  	user u = createUsers(1)[0];

    LightningSharing.upsertPerm(u.id, ptos[0].id, 'Edit');
    LightningSharing.upsertPerm(u.id, ptos[0].id, 'Read');
    LightningSharing.upsertPerm(u.id, ptos[0].id, 'Edit');

    LightningSharing.getSharings(ptos[0].id);

    LightningSharing.deletePerm(u.id, ptos[0].id);


    LightningSharing.upsertPerm(u.id, rotos[0].id, 'Edit');
    LightningSharing.getSharings(rotos[0].id);
    LightningSharing.deletePerm(u.id, rotos[0].id);

  	try {
  		LightningSharing.upsertPerm(u.id, o[0].id, 'Edit');
  		LightningSharing.deletePerm(u.id, o[0].id);
  	} catch (exception e){
  		//ok, sharing may not be on
  		system.debug(e);
  	}

  	try {
  		LightningSharing.upsertPerm(u.id, o[0].id, 'Read');
  		LightningSharing.deletePerm(u.id, o[0].id);
  	} catch (exception e){
  		system.debug(e);
  		//ok, sharing may not be on
  	}

  	try {
  		LightningSharing.upsertPerm(u.id, l[0].id, 'Edit');
  		LightningSharing.deletePerm(u.id, l[0].id);
  	} catch (exception e){
  		//ok, sharing may not be on
  		system.debug(e);
  	}

  	try {
  		LightningSharing.upsertPerm(u.id, l[0].id, 'Read');
  		LightningSharing.deletePerm(u.id, l[0].id);
  	} catch (exception e){
  		system.debug(e);
  		//ok, sharing may not be on
  	}
  }

  static testMethod void testStringStuff(){
  	LightningSharing.getLookupField('Account');
  	LightningSharing.getAccessLevelField('Account');
  	System.assertEquals('AccountShare', LightningSharing.getSharingTableName('Account'));

  	LightningSharing.getLookupField('Custom__c');
  	LightningSharing.getAccessLevelField('Custom__c');
    System.assertEquals('Custom__Share', LightningSharing.getSharingTableName('Custom__c'));

  	System.assertEquals('NS__Custom__Share', LightningSharing.getSharingTableName('NS__Custom__c'));

  }


  static testMethod void testBuildQuery(){
  	list<lead> l = [select id from lead];
  	LightningSharing.buildQuery(l[0].id);
  }

  static testMethod void testcanIEditPermsNonAdmin() {
  	//list<lead> l = [select id from lead];
    list<Opportunity> ptos = [select id from Opportunity];
    list<Opportunity> rotos = [select id from Opportunity];

  	list<user> users = createUsers(1);

    LightningSharing.upsertPerm(users[0].id, ptos[0].id, 'Edit');
    LightningSharing.upsertPerm(users[0].id, rotos[0].id, 'Edit');

  	System.RunAs(users[0]){

      //LightningSharing.getSharings(l[0].id);
      //LightningSharing.getSharings(ptos[0].id);
      //LightningSharing.getSharings(rotos[0].id);

      //system.assert(LightningSharing.canIEditPerms(l[0].id), false);
  		system.assertEquals(LightningSharing.canIEditPerms(ptos[0].id), false);
      system.assertEquals(LightningSharing.canIEditPerms(rotos[0].id), false);

  	}
  }

  static testMethod void testGroupStuff(){
    list<group> groups = [select id from group where Name = 'the knights who say nee'];
    list<lead> l = [select id from lead];
    list<Opportunity> ptos = [select id from Opportunity];
    list<Opportunity> rotos = [select id from Opportunity];

    list<user> users = createUsers(2);

    list<GroupMember> gms = new list<GroupMember>();
    gms.add(new GroupMember(GroupId=groups[0].id, UserOrGroupId=users[0].id));
    gms.add(new GroupMember(GroupId=groups[0].id, UserOrGroupId=users[1].id));

    insert gms;

    test.startTest();
    system.RunAs(createAdmin()){

      //LightningSharing.upsertPerm(groups[0].id, l[0].id, 'Read');
      LightningSharing.upsertPerm(groups[0].id, ptos[0].id, 'Read');
      //LightningSharing.upsertPerm(groups[0].id, rotos[0].id, 'Read');

      LightningSharing.getSharings(l[0].id);
      LightningSharing.getSharings(ptos[0].id);
      LightningSharing.getSharings(rotos[0].id);
    }
    test.stopTest();

  }

  @testSetup
  static void makeData() {
      
	  // disable process builders and triggers
      TestDataFactoryUtils.runTriggers(false);
      TestDataFactoryUtils.runProcessBuilders(false);

      // preparation for testings

      /* Creating 2 distinct random IMCD company values */
      String imcdCompanyTestValue = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
      String imcdCompanyTestValue2;
      do {
          imcdCompanyTestValue2 = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
      } while (imcdCompanyTestValue2.equals(imcdCompanyTestValue));

      /*Creating 3 distinct random LOB1 values*/
      Set<String> lob1FieldNameTestValuesSet = new Set<String>();
      do {
          String temp = TestDataFactoryUtils.getRandomPickListValue(new AccountLob__c(), Label.LOB1_Field_Name);

          if (!lob1FieldNameTestValuesSet.contains(temp)) {
              lob1FieldNameTestValuesSet.add(temp);
          }
      } while (lob1FieldNameTestValuesSet.size() != 5);

      /* Creating 4 Sold To and 4 related C2 Accounts for creating Account Shares testing*/
      List<Account> testSoldToAccounts = TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);
      testSoldToAccounts.addAll(TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue2));
      List<Account> testC2Accounts = TestDataFactory.createAccounts(4, Label.Regional_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);

      List<User> testUsers2Insert = new List<User>();
      List<SharingAccess__c> testSharingAccessToInsert = new List<SharingAccess__c>();

      for (Integer i = 0; i < testSoldToAccounts.size(); i++) {
          testSoldToAccounts[i].ParentId = testC2Accounts[i].Id;
      }
      update testSoldToAccounts;

      /* Creating 10 Users each 2 with different Profile*/
      List<User> testUserList1 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
      List<User> testUserList2 = TestDataFactory.returnUsers(2, Label.Contract_Manager_Profile_Name, imcdCompanyTestValue);
      List<User> testUserList3 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, imcdCompanyTestValue);
      List<User> testUserList4 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
      List<User> testUserList5 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, imcdCompanyTestValue);

      testUsers2Insert.addAll(testUserList1);
      testUsers2Insert.addAll(testUserList2);
      testUsers2Insert.addAll(testUserList3);
      testUsers2Insert.addAll(testUserList4);
      testUsers2Insert.addAll(testUserList5);
      insert testUsers2Insert;

      /*Creating 10 SharingAccess records each 2 related to one of the random LOB1 values and Users*/
      List<String> lob1FieldNameTestValuesList = new List<String>(lob1FieldNameTestValuesSet);
      //List<SharingAccess__c> testGlobalSharList = TestDataFactory.getSharingAccessList(testUserList1, '', lob1FieldNameTestValuesList[0], true);
      //List<SharingAccess__c> testGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList4, '', lob1FieldNameTestValuesList[1], true);
      List<SharingAccess__c> testNonGlobalSharList1 = TestDataFactory.getSharingAccessList(testUserList2, imcdCompanyTestValue, lob1FieldNameTestValuesList[2], false);
      List<SharingAccess__c> testNonGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue2, lob1FieldNameTestValuesList[4], false);
      List<SharingAccess__c> testNonGlobalSharList3 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue, lob1FieldNameTestValuesList[3], false);
      List<SharingAccess__c> testNonGlobalSharList4 = TestDataFactory.getSharingAccessList(testUserList5, imcdCompanyTestValue2, lob1FieldNameTestValuesList[2], false);

      //testSharingAccessToInsert.addAll(testGlobalSharList);
      //testSharingAccessToInsert.addAll(testGlobalSharList2);
      testSharingAccessToInsert.addAll(testNonGlobalSharList1);
      testSharingAccessToInsert.addAll(testNonGlobalSharList2);
      testSharingAccessToInsert.addAll(testNonGlobalSharList3);
      testSharingAccessToInsert.addAll(testNonGlobalSharList4);

      insert testSharingAccessToInsert ;



    	//make some object for testing, like a lead
      insert new lead(Lastname = 'McLaughlin', company = 'Salesforce', email = 'm.shane.mclaughlin@gmail.com');

      Account testSoldToAccount = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue)[0];
      insert TestDataFactory.returnOpportunities(
          1, testSoldToAccount,
          new List<String>{ SharingUtils.getSharingAccessTable(null)[0].LOB1__c }
      );

      insert new group(Name = 'the knights who say nee', Type = 'Regular');
  }

  public static user createAdmin(){
  	Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

		// create User
		User u = new User();

		u.FirstName = 'A';
		u.LastName = 'S';
		u.Email = 'test@testLightningSharing2017.com';
		u.Username = 'astest@testLightningSharing2017.com';
		u.Alias = 'astest';
		u.ProfileId = p.Id;
		u.TimeZoneSidKey    = 'America/Denver';
		u.LocaleSidKey      = 'en_US';
		u.EmailEncodingKey  = 'UTF-8';
		u.LanguageLocaleKey = 'en_US';

		insert u;
		system.debug('u contains ' + u);
		return u;
	}

	public static list<user> createUsers(integer numberOfUsers){
		list<user> users = new list<user>();

		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];


		for (integer i=0; i<numberOfUsers; i++){
			string x = string.valueOf(i);
			User u = new User(Alias = 't'+x, Email='standarduser'+x+'@testLightningSharing2017.msm',
				EmailEncodingKey='UTF-8', LastName='Testing' + x, LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = p.Id,
				TimeZoneSidKey='America/Los_Angeles', UserName='standarduser'+x+'@testLightningSharing2017.msm');
			users.add(u);
		}

		insert users;
		return users;
	}

}