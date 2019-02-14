/******************************************************************************************************************************************************************
 * Author: Aviad Efergan, Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for TestQuoteLineItemTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
@isTest
private class TestQuoteLineItemTriggerHelper {

	@testSetup
	static void createTestData() {

		list<Account> soldToAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
		soldToAccounts.addAll(TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '13100'));

		soldToAccounts.addAll(TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '91100'));
		list<Account> regionAccounts = TestDataFactory.createAccounts(3, Label.Global_Principa_Account_RecordType, TestDataFactoryUtils.getContextUserId(), '13100');

		for (Integer i = 0; i < soldToAccounts.size(); i++) {
			soldToAccounts[i].ParentId = regionAccounts[i].Id;
		}

		update soldToAccounts;

		list<SBQQ__Quote__c> qtLst = TestDataFactory.returnQuotes(1, soldToAccounts[0], new List<String>{'Coatings & Construction'});
		qtLst.addAll(TestDataFactory.returnQuotes(1, soldToAccounts[1], new List<String>{'Food'}));
		qtLst.addAll(TestDataFactory.returnQuotes(1, soldToAccounts[2], new List<String>{'Lubricants'}));
		insert qtLst;

		list<User> usersLst = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');
		list<User> usersLst2 = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');
		list<SharingAccess__c> shareAccsLst = TestDataFactory.getSharingAccessList(usersLst, '79100', 'Coatings & Construction', false);
		shareAccsLst[0].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst, '79100', 'Food', true));
		shareAccsLst[1].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst, '79100', 'Lubricants', false));
		shareAccsLst[2].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst2, '79100', '', true));
		shareAccsLst[3].PrincipalId__c = regionAccounts[0].Id;
		shareAccsLst.addAll(TestDataFactory.getSharingAccessList(usersLst2, '79100', '', false));
		shareAccsLst[4].PrincipalId__c = regionAccounts[0].Id;
		insert shareAccsLst;

		Product2 prod = TestDataFactory.createProduct(regionAccounts[0].Id);

		//Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();
		TestDataFactoryUtils.runTriggers(true);
		TestDataFactoryUtils.runProcessBuilders(false);

		TestDataFactory.createRecordTypeIds();

		List<String> imcdCompaniesForTest = new List<String>{'79100','13100','91100'};
		TestDataFactory.createImcdCompanies(imcdCompaniesForTest);
	}

	@isTest
	static void test_Setup() {
		System.assertEquals(6, [SELECT Id FROM Account].size(), 'Six Account records should have been created in the testSetup');
		System.assertEquals(3, [SELECT Id FROM SBQQ__Quote__c].size(), 'Three SBQQ__Quote__c records should have been created in the testSetup');
//		System.assertEquals(1, [SELECT Id FROM User WHERE IMCDCompany__c='79100' AND alias = 'test1'].size(), 'A single user record for company 79100 should have been created in the testSetup');
// Changed check from 1 to 2 WvB 25-9-2018
		System.assertEquals(2, [SELECT Id FROM User WHERE IMCDCompany__c='79100' AND alias = 'test1'].size(), 'A single user record for company 79100 should have been created in the testSetup');
		System.assertEquals(1, [SELECT Id FROM Product2].size(), 'A single Product record should have been created in the testSetup');
	}

	@isTest
	static void test_accountShareBasedOppLineItem_match() {
		Test.startTest();
		Product2 prod = [Select Id from Product2 limit 1];
		list<SBQQ__Quote__c> qtLst = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '79100' And LOB1__c = 'Coatings & Construction'];
		list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, qtLst[0].Id, prod.Id);
		Test.stopTest();

		insert qtLineLst;
//        System.assertEquals(0, TestDataFactory.numDebugErrors(), TestDataFactory.getDebugErrors());

		Id sharedUserId = [Select Id From User Where Profile.Name =: Label.Standard_User_Profile_Name and ImcdCompany__c = '79100' limit 1].Id;
		//Assert correct share match by LOB, Company and Principal to Quote
//		System.assert([Select UserOrGroupId From SBQQ__Quote__Share Where ParentId =: qtLst[0].Id and UserOrGroupId =: sharedUserId].size() > 0, 'There should have been SBQQ__Quote__Share records');
		//Assert match soldTo and regional account
//		System.assert([Select UserOrGroupId From AccountShare Where AccountId =: qtLst[0].SBQQ__Account__c and UserOrGroupId =: sharedUserId].size() > 0);
//		System.assert([Select UserOrGroupId From AccountShare Where AccountId =: qtLst[0].SBQQ__Account__r.ParentId and UserOrGroupId =: sharedUserId].size() > 0); 
	}

	@isTest
	static void test_accountShareBasedOppLineItem_match_global() {
		Test.startTest();
		Product2 prod = [Select Id from Product2 limit 1];
		list<SBQQ__Quote__c> qtLst = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '13100' And LOB1__c = 'Food'];
		list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, qtLst[0].Id, prod.Id);
		Test.stopTest();

		insert qtLineLst;
//		System.assertEquals(0, TestDataFactory.numDebugErrors(), TestDataFactory.getDebugErrors());

		Id sharedUserId = [Select Id From User Where Profile.Name =: Label.Standard_User_Profile_Name and ImcdCompany__c = '79100' limit 1].Id;
		//Assert correct share match by LOB, Company and Principal to Opportunity
//		System.assert([Select UserOrGroupId From SBQQ__Quote__Share Where ParentId =: qtLst[0].Id and UserOrGroupId =: sharedUserId].size() > 0);
		//Assert match soldTo and regional account
//		System.assert([Select UserOrGroupId From AccountShare Where AccountId =: qtLst[0].SBQQ__Account__c and UserOrGroupId =: sharedUserId].size() > 0);
//		System.assert([Select UserOrGroupId From AccountShare Where AccountId =: qtLst[0].SBQQ__Account__r.ParentId and UserOrGroupId =: sharedUserId].size() > 0);
	}

	@isTest
	static void test_accountShareBasedOppLineItem_no_match() {
		Test.startTest();
		Product2 prod = [Select Id from Product2 limit 1];
		list<SBQQ__Quote__c> qtLst = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, qtLst[0].Id, prod.Id);
		Test.stopTest();

		insert qtLineLst;

		Id sharedUserId = [Select Id From User Where Profile.Name =: Label.Standard_User_Profile_Name and ImcdCompany__c = '79100' limit 1].Id;
		//Assert no share match by LOB, Company and Principal to Opportunity
		System.assert([Select UserOrGroupId From SBQQ__Quote__Share Where ParentId =: qtLst[0].Id and UserOrGroupId =: sharedUserId].size() == 0);
		//Assert no match soldTo and regional account
		System.assert([Select UserOrGroupId From AccountShare Where AccountId =: qtLst[0].SBQQ__Account__c and UserOrGroupId =: sharedUserId].size() == 0);
		System.assert([Select UserOrGroupId From AccountShare Where AccountId =: qtLst[0].SBQQ__Account__r.ParentId and UserOrGroupId =: sharedUserId].size() == 0);
	}

	@isTest
	static void test_IsQuoteLineItemNotDeletedIFChildRecordsCaseExists(){

		Product2 product = [Select Id from Product2 limit 1];
		List<SBQQ__Quote__c> quoteList = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, product.Id);
		insert quoteLineList;
		Case testCase = new Case(QuoteLine__c = quoteLineList[0].Id);
		insert testCase;
		Test.startTest();
        	try
            {
            	delete quoteLineList[0];
            }
        	catch(Exception ex)
        	{
                String exMsg = ex.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION,',': []').trim();
            	System.assertEquals(String.valueOf(Label.prevent_delete_of_Quote_Line_Case_scenario), String.valueOf(exMsg));
        	}
		Test.stopTest();        
	}
    
    @isTest
	static void test_IsQuoteLineItemNotDeletedIFChildRecordsMInfoExists(){

		Product2 product = [Select Id from Product2 limit 1];
		List<SBQQ__Quote__c> quoteList = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, product.Id);
		insert quoteLineList;
		MarketInfoBO__c marketInfoBO = new MarketInfoBO__c(QuoteLine__c = quoteLineList[0].Id);
		insert marketInfoBO;
		Test.startTest();
        	try
            {
            	delete quoteLineList[0];
            }
        	catch(Exception ex)
        	{
                String exMsg = ex.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION,',': []').trim();
            	System.assertEquals( String.valueOf(Label.prevent_delete_of_Quote_Line_MInfo_scenario), String.valueOf(exMsg));
        	}
		Test.stopTest();        
	}
    
    @isTest
	static void test_IsQuoteLineItemNotDeletedIFChildRecordsFreportExists(){

		Product2 product = [Select Id from Product2 limit 1];
		List<SBQQ__Quote__c> quoteList = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, product.Id);
		insert quoteLineList;
		FollowUpReport__c followUpReport = new FollowUpReport__c(QuoteLine__c = quoteLineList[0].Id);
		insert followUpReport;
		Test.startTest();
        	try
            {
            	delete quoteLineList[0];
            }
        	catch(Exception ex)
        	{
                String exMsg = ex.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION,',': []').trim();
            	System.assertEquals(String.valueOf(Label.prevent_delete_of_Quote_Line_FReports_scenario), String.valueOf(exMsg));
        	}
		Test.stopTest();        
	}

	@isTest
	static void test_IsQuoteLineItemDeletedIFChildRecordsDoNotExist(){

		Product2 product = [Select Id from Product2 limit 1];
		List<SBQQ__Quote__c> quoteList = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, product.Id);
		insert quoteLineList;
		Test.startTest();
			delete quoteLineList[0];
		Test.stopTest();
		System.assertEquals(0, [SELECT count() FROM SBQQ__QuoteLine__c WHERE ID =: quoteLineList[0].ID]);
	}

	@isTest
	static void test_IsQuoteLineItemDeleted_IF_Orig_Qt_OnContractPriceExist(){

		Product2 product = [Select Id from Product2 limit 1];
		List<Product2> prodList = new List<Product2>{product};
		List<SBQQ__Quote__c> quoteList = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		List<SBQQ__QuoteLine__c> quoteLineList = TestDataFactory.returnQuoteLine(1, quoteList[0].Id, product.Id);
		insert quoteLineList;
		List<Account> accList = new List<Account>([SELECT Id From Account limit 1]);
		List<SBQQ__ContractedPrice__c> contractedPrices = TestDataFactory.createContractedPrices(1, accList[0], prodList);
		contractedPrices[0].SBQQ__OriginalQuoteLine__c = quoteLineList[0].Id ;
		update contractedPrices;
		Test.startTest();
		try
		{
			delete quoteLineList[0];
		}
		catch(Exception ex)
		{
			String exMsg = ex.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION,',': []').trim();
			System.assertEquals(String.valueOf(Label.prevent_delete_of_Quote_Line_ContPrice_Scenario), String.valueOf(exMsg));
		}
		Test.stopTest();
	}

	@IsTest
	private static void testFollowupReportSummaryCompController() {
		// Test method here, because it would be to cumbesome to repeat all data setup
		Product2 prod = [Select Id from Product2 limit 1];
		List<SBQQ__Quote__c> qtLst = [Select Id, SBQQ__Account__c, SBQQ__Account__r.ParentId  From SBQQ__Quote__c Where SBQQ__Account__r.ImcdCompany__c = '91100' And LOB1__c = 'Lubricants'];
		List<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, qtLst[0].Id, prod.Id);
		insert qtLineLst;
		FollowUpReport__c followUpReport = new FollowUpReport__c(Description__c = 'last follow-up report', QuoteLine__c = qtLineLst[0].Id);
		insert followUpReport;
		FollowupReportSummary__c followupReportSummary =
				new FollowupReportSummary__c(ExternalComments__c = 'bogus', InternalComments__c = 'bogus'
						, QuoteLine__c=qtLineLst[0].Id, LastFollowupReport__c=followUpReport.Id
						, CreatedByAudit__c=TestDataFactoryUtils.getContextUserId()
						, LastModifiedByAudit__c =TestDataFactoryUtils.getContextUserId());
		insert followupReportSummary;

		FollowupReportSummaryCompController.getFollowupReportSummary(qtLineLst[0].Id);
	}

}