@isTest
private class TestQueueableAvoidDMLLimit {
	
	@testSetup static void setup(){
        Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();
        TestDataFactory.createRecordTypeIds();
        TestDataFactory.createIntegrationSettings();
        
        TestDataFactory.createImcdCompanies(new List<String>{'79100'});
	}


	@isTest 
	static void test_avoidLimitALL() {
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;		
		list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

		List<Opportunity> oppLst = TestDataFactory.returnOpportunities(1, testSoldToAccounts[0], new List<String>{'Food'});
		insert oppLst;
		list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};


		List<SBQQ__Quote__c> quoteLst = TestDataFactory.createQuotes(1, testSoldToAccounts[0], users[0]);
		List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>{new SBQQ__Quote__Share(UserOrGroupId = users[0].Id, ParentId = quoteLst[0].Id, AccessLevel = Label.READ_WRITE_ACCESS, RowCause = Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c )};

		Test.startTest();
		QueueableAvoidDMLLimit cls = new QueueableAvoidDMLLimit(accShareLst, oppShareLst, quoteShareLst, true);
		cls.execute(null);
		Test.stopTest(); 

	}
	
	@isTest 
	static void test_avoidLimitAccount() {
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;		
		list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

		Test.startTest();
		QueueableAvoidDMLLimit cls = new QueueableAvoidDMLLimit(accShareLst, new list<OpportunityShare>(), new list<SBQQ__Quote__Share>(), true);
		cls.execute(null);
		Test.stopTest();

	}

	@isTest 
	static void test_avoidLimitOppWithQuotes() {
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;		
		list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

		List<Opportunity> oppLst = TestDataFactory.returnOpportunities(1, testSoldToAccounts[0], new List<String>{'Food'});
		insert oppLst;
		list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};


		List<SBQQ__Quote__c> quoteLst = TestDataFactory.createQuotes(1, testSoldToAccounts[0], users[0]);
		List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>{new SBQQ__Quote__Share(UserOrGroupId = users[0].Id, ParentId = quoteLst[0].Id, AccessLevel = Label.READ_WRITE_ACCESS, RowCause = Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c )};

		Test.startTest();
		QueueableAvoidDMLLimit cls = new QueueableAvoidDMLLimit(new list<AccountShare>(), oppShareLst, quoteShareLst, true);
		cls.execute(null);
		Test.stopTest();

	}
	
	@isTest 
	static void test_avoidLimitOpp() {
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;		
		list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

		List<Opportunity> oppLst = TestDataFactory.returnOpportunities(1, testSoldToAccounts[0], new List<String>{'Food'});
		insert oppLst;
		list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

		Test.startTest();
		QueueableAvoidDMLLimit cls = new QueueableAvoidDMLLimit(new list<AccountShare>(), oppShareLst, new list<SBQQ__Quote__Share>(), true);
		cls.execute(null);
		Test.stopTest();

	}

	@isTest 
	static void test_avoidLimitQuotes() {
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;		
		list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

		List<Opportunity> oppLst = TestDataFactory.returnOpportunities(1, testSoldToAccounts[0], new List<String>{'Food'});
		insert oppLst;
		list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};


		List<SBQQ__Quote__c> quoteLst = TestDataFactory.createQuotes(1, testSoldToAccounts[0], users[0]);
		List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>{new SBQQ__Quote__Share(UserOrGroupId = users[0].Id, ParentId = quoteLst[0].Id, AccessLevel = Label.READ_WRITE_ACCESS, RowCause = Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c )};

		Test.startTest();
		QueueableAvoidDMLLimit cls = new QueueableAvoidDMLLimit(new list<AccountShare>(), new list<OpportunityShare>(), quoteShareLst, true);
		cls.execute(null);
		Test.stopTest();

	}
	
	
}