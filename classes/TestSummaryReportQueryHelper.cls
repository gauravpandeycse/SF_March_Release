/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
Inputs:        See comments
Test Class:    TestSummaryReportQueryHelper
History
	03/12/2018 Created class
	28/01/2018 Updated class with Scenarios F, G, H, I
------------------------------------------------------------*/
@IsTest
private class TestSummaryReportQueryHelper {

	static List<SummaryReportQueryHelper.HelperQueryRequest> lstHelperRequest = new List<SummaryReportQueryHelper.HelperQueryRequest>();
	static SummaryReportQueryHelper.HelperQueryRequest helperRequest = new SummaryReportQueryHelper.HelperQueryRequest();

	@testsetup
	public static void testsetup() {
		TestDataFactory.createBypassCustomSetting();
		TestDataFactoryUtils.runProcessBuilders(false);
		TestDataFactory.createIntegrationSettings();
		TestDataFactoryUtils.runTriggers(false);
		TestDataFactoryUtils.runValidationRules(false);

		List<Account> testAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '21100');
		List<Contact> testContacts = TestDataFactory.returnContacts(1);
		List<Account> testPrincipals = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
		List<Product2> testProducts = TestDataFactory.createProducts(2, testPrincipals[0].Id, '04.Active Sales', 'Product');
		List<Opportunity> testOpportunities0 = TestDataFactory.returnOpportunities(1, testAccounts[0], new List<String>{'Coatings & Construction'});
		testOpportunities0[0].Type = 'Development';
		insert testOpportunities0;

		List<Opportunity> testOpportunities = [SELECT Id, Name, SBQQ__PrimaryQuote__c FROM Opportunity];
		RecordType opptyQuoteRt = ImcdUtils.getRecordType('SBQQ__Quote__c', 'OpportunityQuote');
		SBQQ__Quote__c testQuote = TestDataFactory.createQuoteWithLines(opptyQuoteRt, 'OpportunityQuote', testAccounts[0], testContacts[0], TestDataFactoryUtils.getContextUserId(), testProducts, 'Draft');
		testQuote.SBQQ__Opportunity2__c = testOpportunities[0].Id;
		update testQuote;

		List<SBQQ__QuoteLine__c> testQuoteLines = [SELECT Id, Opportunity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testQuote.Id];
		for (SBQQ__QuoteLine__c  quoteLine: testQuoteLines) {
			quoteLine.Opportunity__c = testOpportunities[0].Id;
		}

		RecordType mimoRt = ImcdUtils.getRecordType('MarketInfoMarket__c', 'MarketInfoOngoing');
		List<MarketInfoMarket__c> testMimo = New List<MarketInfoMarket__c>();
		testMimo.add ( new MarketInfoMarket__c ( RecordTypeId = mimoRt.Id, Account__c = testAccounts[0].Id, Product__c = testProducts[0].Id) );

		insert testContacts;
		update testQuote;
		update testQuoteLines;
		insert testMimo;
	}

	@isTest
	static void testSetupConfig() {
		system.assertEquals(2, [SELECT Id FROM Account].size());
		system.assertEquals(1, [SELECT Id From Contact].size());
		system.assertEquals(2, [SELECT Id FROM Product2].size());
		system.assertEquals(1, [SELECT Id FROM Opportunity].size());
		system.assertEquals(1, [SELECT Id FROM SBQQ__Quote__c].size());
		system.assertEquals(2, [SELECT Id FROM SBQQ__QuoteLine__c].size());
	}

	@isTest
	static void testBulkificationError () {
		lstHelperRequest.add(helperRequest);
		lstHelperRequest.add(helperRequest);
		String error = '';
		String errorExpected = 'Method is not bulkified, only allows a single request.';

		try {
			SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest);
		}
		catch (Exception exc) {
			error =  exc.getMessage();
		}

		System.assertEquals(errorExpected, error, errorExpected);
	}

	@isTest
	static void testNoValidInputs () {
		lstHelperRequest.add(helperRequest);
		String error = '';
		String errorExpected = 'No valid inputs received.';

		try {
			SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest);
		}
		catch (Exception exc) {
			error = exc.getMessage();
		}

		System.assertEquals(errorExpected, error, errorExpected);
	}

	@isTest
	static void testScenarioA () {
		List<String> testQuoteLineFields = new List<String>{'Id', 'Name'};
		List<Opportunity> testOpportunities = new List<Opportunity>([SELECT Id, Name FROM Opportunity LIMIT 1]);
		helperRequest.key = false;
		helperRequest.lstOpportunity = testOpportunities;
		helperRequest.lstQuoteLineFields = testQuoteLineFields;
		lstHelperRequest.add(helperRequest);
		System.assertNotEquals(null, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].lstQuoteLine, 'Testing Scenario A failed');
	}

	@isTest
	static void testScenarioB () {
		List<String> testFollowUpReportFields = new List<String>{'Id', 'Name'};
		List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c>([SELECT Id, Name FROM SBQQ__QuoteLine__c]);
		FollowUpReport__c testFollowUpReport = new FollowUpReport__c(QuoteLine__c = testQuoteLines[0].Id);
		insert testFollowUpReport;
		helperRequest.lstQuoteLine = testQuoteLines;
		helperRequest.lstFollowupReportFields = testFollowUpReportFields;
		lstHelperRequest.add(helperRequest);
		System.assertNotEquals(null, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].lstFollowupReport, 'Testing Scenario B failed');
	}

	@isTest
	static void testScenarioC () {
		List<String> testMarketInfoBoFields = new List<String>{'Id', 'Name'};
		List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c>([SELECT Id, Name FROM SBQQ__QuoteLine__c]);
		MarketInfoBO__c testMarketInfoBO = new MarketInfoBO__c(QuoteLine__c = testQuoteLines[0].Id);
		insert testMarketInfoBO;
		helperRequest.lstQuoteLine = testQuoteLines;
		helperRequest.lstMarketInfoBoFields = testMarketInfoBoFields;
		lstHelperRequest.add(helperRequest);
		System.assertNotEquals(null, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].lstMarketInfoBo, 'Testing Scenario C failed');
	}

	@isTest
	static void testScenarioD () {
		List<String> testMarketInfoMarketFields = new List<String>{'Id', 'Name'};
		List<Account> testAccounts = new List<Account>([SELECT Id, Name FROM Account LIMIT 1]);
		MarketInfoMarket__c testMarketInfoMarket = new MarketInfoMarket__c(Account__c = testAccounts[0].Id);
		insert testMarketInfoMarket;
		helperRequest.accountId = testAccounts[0].Id;
		helperRequest.lstMarketInfoMarketFields = testMarketInfoMarketFields;
		lstHelperRequest.add(helperRequest);
		System.assertNotEquals(null, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].lstMarketInfoMarket, 'Testing Scenario D failed');
	}

	@isTest
	static void testScenarioE () {
		List<String> testVisitReportFields = new List<String>{'Id', 'Name'};
		List<Opportunity> testOpportunities = new List<Opportunity>([SELECT Id, Name FROM Opportunity LIMIT 1]);
		VisitReport__c testVisitReport = new VisitReport__c();
		insert testVisitReport;
		List<VisitReport__c> testVisitReports = [SELECT Id FROM VisitReport__c LIMIT 1];
		VisitReportOppty__c testVisitReportOppty = new VisitReportOppty__c(Opportunity__c = testOpportunities[0].Id, VisitReport__c = testVisitReports[0].Id); // PrimaryQuoteId__c <> null 'Field is not writeable: VisitReportOppty__c.PrimaryQuoteId__c'
		insert testVisitReportOppty;
		helperRequest.lstOpportunity = testOpportunities;
		helperRequest.lstVisitReportFields = testVisitReportFields;
		lstHelperRequest.add(helperRequest);
		//Does not actually check the query
		System.assertEquals(null, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].lstVisitReportOptty, 'Testing Scenario E failed');
	}
	@isTest //(request.principalId <> null && request.lstProductFields <> null && request.returnQuoteLineProducts)
	static void TestScenarioFandG () {
		List<String> lstFields = new List<String>{'Id', 'Name'};
		ID principalId = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :Label.Global_Principa_Account_Recordtype LIMIT 1].Id;
		helperRequest.principalId = principalId;
		helperRequest.lstProductFields = lstFields;
		helperRequest.returnQuoteLineProducts = true; // this triggers scenario G
		helperRequest.key = false;
		helperRequest.lob = 'Coatings & Construction';
		helperRequest.boType = 'Development';
		helperRequest.excludeColdOppties = false;
		helperRequest.excludeLostLines = false;
		helperRequest.soqlLimit = 10;
		helperRequest.startDate =  system.today(); // queries take ">" predicate
		helperRequest.endDate =  system.today().addYears(2);  // oppty close date is set 1 year in the future
		lstHelperRequest.add(helperRequest);

		System.assertEquals(2, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].numRecords, 'Testing Scenario G failed');

		lstHelperRequest[0].lstProduct = [SELECT Id FROM Product2];
		lstHelperRequest[0].returnQuoteLineProducts = false; // this triggers scenario F
		lstHelperRequest[0].lstQuoteLineFields = lstFields; // just Id, Name
		lstHelperRequest[0].lstProductFields = null;

		System.assertEquals(2, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].numRecords, 'Testinng Scenario F Failed');
	}
	@isTest //(request.principalId <> null && request.lstProductFields <> null && request.returnMarketInfoMarketProducts)
	static void TestScenarioHandI () {
		List<String> lstFields = new List<String>{'Id', 'Name'};
		ID principalId = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :Label.Global_Principa_Account_Recordtype LIMIT 1].Id;

		helperRequest.soqlLimit = 10;
		helperRequest.principalId = principalId;
		helperRequest.lstProductFields = lstFields;
		helperRequest.returnMarketInfoMarketProducts = true; // this triggers scenario H
		lstHelperRequest.add(helperRequest);

		System.assertEquals(1, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].numRecords, 'Testing Scenario H failed');

		lstHelperRequest[0].lstProduct = [SELECT Id FROM Product2];
		lstHelperRequest[0].returnMarketInfoMarketProducts = false; // this triggers scenario I
		lstHelperRequest[0].lstMarketInfoMarketFields = lstFields; // just Id, Name
		lstHelperRequest[0].lstProductFields = null;

		System.assertEquals(1, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].numRecords, 'Testing Scenario I Failed');
	}
	@isTest //(request.accountId <> null && request.lstOpportunityFields <> null)
	static void TestScenarioJ () {
		List<String> lstFields = new List<String>{'Id', 'Name'};
		ID accountId = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :Label.Customer_Sold_To_Account_Record_Type LIMIT 1].Id;

		helperRequest.accountId = accountId;
		helperRequest.lstOpportunityFields = lstFields;
		helperRequest.key = false;
		helperRequest.lob = 'Coatings & Construction';
		helperRequest.boType = 'Development';
		helperRequest.excludeColdOppties = false;
		helperRequest.excludeLostLines = false;
		helperRequest.startDate =  system.today(); // queries take ">" predicate
		helperRequest.endDate =  system.today().addYears(2);  // oppty close date is set 1 year in the future
		lstHelperRequest.add(helperRequest);

		System.assertEquals(1, SummaryReportQueryHelper.executeHelperQuery(lstHelperRequest)[0].numRecords, 'Testing Scenario J failed');
	}


}