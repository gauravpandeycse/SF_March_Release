/******************************************************************************************************************************************************************
 * Author: Aviad Efergan, Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for OpportunityLineItemTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
@isTest
	private class TestOpportunityLineItemTriggerHelper {

	@testSetup
	static void createTestData() {
		Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();
		TestDataFactory.createRecordTypeIds();
		TestDataFactory.createIntegrationSettings();

		list<Account> soldToAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		soldToAccounts.addAll(TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '13100'));

		soldToAccounts.addAll(TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '91100'));
		List<Account> regionAccounts = TestDataFactory.createAccounts(3, Label.Global_Principa_Account_RecordType, TestDataFactoryUtils.getContextUserId(), '13100');

		for (Integer i = 0; i < soldToAccounts.size(); i++) {
			soldToAccounts[i].ParentId = regionAccounts[i].Id;
		}

		update soldToAccounts;

		/*Creating Test Standard, and Custom Pricebook, pricebookEntry*/
		List<Pricebook2> defpricebooks = TestDataFactory.createDefaultPricebooks();

		Pricebook2 standardPricebook = new Pricebook2(
				Id = Test.getStandardPricebookId(),
				IsActive = true,
				ImcdCompany__c = '22100'
		);
		update standardPricebook;

		List<String> imcdCompaniesForTest = new List<String>{'79100','13100','91100'};
		TestDataFactory.createImcdCompanies(imcdCompaniesForTest);

		list<Opportunity> oppLst = TestDataFactory.returnOpportunities(1, soldToAccounts[0], new List<String>{'Coatings & Construction'});
		oppLst.addAll(TestDataFactory.returnOpportunities(1, soldToAccounts[1], new List<String>{'Coatings & Construction'}));
		oppLst.addAll(TestDataFactory.returnOpportunities(1, soldToAccounts[1], new List<String>{'Food'}));
		oppLst.addAll(TestDataFactory.returnOpportunities(1, soldToAccounts[2], new List<String>{'Lubricants'}));
		oppLst[0].SBQQ__QuotePricebookId__c = defpricebooks[1].Id;
		oppLst[1].SBQQ__QuotePricebookId__c = defpricebooks[1].Id;
		insert oppLst;

		list<User> usersLst = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

		list<SharingAccess__c> shareAccsLst = TestDataFactory.getSharingAccessList(usersLst, '79100', 'Coatings & Construction', false);
		shareAccsLst[0].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst, '79100', 'Food', true));
		shareAccsLst[1].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst, '79100', 'Lubricants', false));
		shareAccsLst[2].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst, '79100', '', true));
		shareAccsLst[3].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst, '79100', '', false));
		shareAccsLst[4].PrincipalId__c = regionAccounts[0].Id;
		insert shareAccsLst;

		/*Creatting product to relate to Opp/Quote LineItems*/
		Product2 prod = TestDataFactory.createProduct(regionAccounts[0].Id, 'kjdfsfgfhs898');

		/*Creating pbentry to relate to Opp LineItems*/
		Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
		PricebookEntry standardPBE = TestDataFactory.createPricebookEntry(standardPB.Id, prod.Id, 'USD');
		//PricebookEntry standardPBE = TestDataFactory.createPricebookEntry(standardPB.Id, prod.Id);
		PricebookEntry pbentry = TestDataFactory.createPricebookEntry(defpricebooks[1].Id, prod.Id);
	}

	@isTest
	static void test_accountShareBasedOppLineItem_match() {
		Test.startTest();
		//Below test data is created to relate opportunity product with quotelineitem
		Product2 prod = [Select Id from Product2 WHERE FullSegmentsNumber__c = 'kjdfsfgfhs898' limit 1];
		PriceBookEntry pbEntry= [Select Id,UnitPrice from PriceBookEntry where Product2Id=: prod.Id AND Pricebook2Id !=: Test.getStandardPriceBookId() limit 1];

		list<Opportunity> oppLst = [Select Id, CurrencyIsoCode, AccountId, Account.ParentId From Opportunity Where Account.ImcdCompany__c = '79100' And LOB1__c = 'Coatings & Construction'];

		List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;

		list<Sbqq__Quote__c> quoteList = TestDataFactory.returnQuotes(1, testSoldToAccounts[0], new List<String>{'Food'});
		quoteList[0].SBQQ__Opportunity2__c = oppLst[0].Id;
		insert quoteList;
		/*Creating Opp/Quote Line Items for Principal match scenario*/

		list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, prod.Id);
		insert qtLineLst ;

		list<OpportunityLineItem> oppLineItemList = TestDataFactory.returnOpportunityLineItem(1, oppLst[0].Id, pbEntry);
		oppLineItemList[0].SBQQ__QuoteLine__c = qtLineLst[0].Id;

		Test.stopTest();

		insert oppLineItemList;

		Id sharedUserId = [Select Id From User Where Profile.Name =: Label.Standard_User_Profile_Name and ImcdCompany__c = '79100' limit 1].Id;
		//Assert correct share match by LOB, Company and Principal to Opportunity
		//System.assert([Select UserOrGroupId From OpportunityShare Where OpportunityId =: oppLst[0].Id and UserOrGroupId =: sharedUserId].size() > 0);
		//Assert match soldTo and regional account
		//System.assert([Select UserOrGroupId From AccountShare Where AccountId =: oppLst[0].AccountId and UserOrGroupId =: sharedUserId].size() > 0);
		//System.assert([Select UserOrGroupId From AccountShare Where AccountId =: oppLst[0].Account.ParentId and UserOrGroupId =: sharedUserId].size() > 0);
	}

	@isTest
	static void test_accountShareBasedOppLineItem_match_global() {
		Test.startTest();
		Product2 prod = [Select Id from Product2 WHERE FullSegmentsNumber__c = 'kjdfsfgfhs898' limit 1];

		PriceBookEntry pbEntry= [Select Id,UnitPrice from PriceBookEntry where Product2Id=: prod.Id AND Pricebook2Id !=: Test.getStandardPriceBookId() limit 1];

		list<Opportunity> oppLst = [Select Id, CurrencyIsoCode, AccountId, Account.ParentId From Opportunity Where Account.ImcdCompany__c = '13100' And LOB1__c = 'Food'];

		List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;

		list<Sbqq__Quote__c> quoteList = TestDataFactory.returnQuotes(1, testSoldToAccounts[0], new List<String>{'Food'});
		quoteList[0].SBQQ__Opportunity2__c = oppLst[0].Id;
		insert quoteList;
		/*Creating Opp/Quote Line Items for Principal match scenario*/

		list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, prod.Id);
		insert qtLineLst ;

		list<OpportunityLineItem> oppLineItemList = TestDataFactory.returnOpportunityLineItem(1, oppLst[0].Id, pbEntry);
		oppLineItemList[0].SBQQ__QuoteLine__c = qtLineLst[0].Id;

		Test.stopTest();

		insert oppLineItemList;

		Id sharedUserId = [Select Id From User Where Profile.Name =: Label.Standard_User_Profile_Name and ImcdCompany__c = '79100' limit 1].Id;
		//Assert correct share match by LOB, Company and Principal to Opportunity
		//System.assert([Select UserOrGroupId From OpportunityShare Where OpportunityId =: oppLst[0].Id and UserOrGroupId =: sharedUserId].size() > 0);
		//Assert match soldTo and regional account
		//System.assert([Select UserOrGroupId From AccountShare Where AccountId =: oppLst[0].AccountId and UserOrGroupId =: sharedUserId].size() > 0);
		//System.assert([Select UserOrGroupId From AccountShare Where AccountId =: oppLst[0].Account.ParentId and UserOrGroupId =: sharedUserId].size() > 0);
	}

	@isTest
	static void test_accountShareBasedOppLineItem_no_match() {
		Test.startTest();
		Product2 prod = [Select Id from Product2 WHERE FullSegmentsNumber__c = 'kjdfsfgfhs898' limit 1];

		PriceBookEntry pbEntry= [Select Id,UnitPrice from PriceBookEntry where Product2Id=: prod.Id AND Pricebook2Id !=: Test.getStandardPriceBookId() limit 1];

		list<Opportunity> oppLst = [Select Id, CurrencyIsoCode, AccountId, Account.ParentId From Opportunity Where Account.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];

		List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		insert testSoldToAccounts;

		list<Sbqq__Quote__c> quoteList = TestDataFactory.returnQuotes(1, testSoldToAccounts[0], new List<String>{'Food'});
		quoteList[0].SBQQ__Opportunity2__c = oppLst[0].Id;
		insert quoteList;
		/*Creating Opp/Quote Line Items for Principal match scenario*/

		list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, prod.Id);
		insert qtLineLst ;

		list<OpportunityLineItem> oppLineItemList = TestDataFactory.returnOpportunityLineItem(1, oppLst[0].Id, pbEntry);
		oppLineItemList[0].SBQQ__QuoteLine__c = qtLineLst[0].Id;
		Test.stopTest();

		insert oppLineItemList;

		Id sharedUserId = [Select Id From User Where Profile.Name =: Label.Standard_User_Profile_Name and ImcdCompany__c = '79100' limit 1].Id;
		//Assert no share match by LOB, Company and Principal to Opportunity
		//System.assert([Select UserOrGroupId From OpportunityShare Where OpportunityId =: oppLst[0].Id and UserOrGroupId =: sharedUserId].size() == 0);
		//Assert no match soldTo and regional account
		//System.assert([Select UserOrGroupId From AccountShare Where AccountId =: oppLst[0].AccountId and UserOrGroupId =: sharedUserId].size() == 0);
		//System.assert([Select UserOrGroupId From AccountShare Where AccountId =: oppLst[0].Account.ParentId and UserOrGroupId =: sharedUserId].size() == 0);
	}
}