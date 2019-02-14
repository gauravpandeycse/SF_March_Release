/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
User Story:    https://imcdgroup.atlassian.net/browse/SFDP-628
History
	10/08/2018     Created class
	31/08/2018     Disabled test coverage. Related with 'active' process builder.
	21/11/2018     Added test coverage for VerifyQuoteCompController
------------------------------------------------------------*/
@isTest
private class TestManualRenewalCompController {

	@testSetup
	public static void testSetup() {
		TestDataFactory.createIntegrationSettings();
		TestDataFactoryUtils.runProcessBuilders(false);
		TestDataFactoryUtils.runTriggers(false);
		TestDataFactoryUtils.runValidationRules(false);
		String companyNumber = '21100';
		TestDataFactory.createRecordTypeIds();
		TestDataFactory.createImcdCompanies(new List<String>{companyNumber});
		List<Contact> lstContact = TestDataFactory.returnContacts(1);
		insert lstContact;
		List<Account> lstAccount  = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), companyNumber);
		List<Account> lstPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
		List<Product2> lstProduct = TestDataFactory.createProducts(2, lstPrincipal[0].Id, '04.Active Sales', 'Product');
		TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstProduct[0].Id);
		TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstProduct[1].Id);
		RecordType singleQuoteRt = ImcdUtils.getRecordType('SBQQ__Quote__c', 'SingleQuote');
		Test.startTest(); // fresh limits
		IMCDUtils.debugLimits('[TestManualRenewalCompController][testSetup] fresh limits');
		List<SBQQ__Quote__c> lstSingleQuote = new List<SBQQ__Quote__c>();
		lstSingleQuote.add(TestDataFactory.createQuoteWithLines(singleQuoteRt, 'Single', lstAccount[0], lstContact[0], TestDataFactoryUtils.getContextUserId(), lstProduct, 'Draft'));
		lstSingleQuote.add(TestDataFactory.createQuoteWithLines(singleQuoteRt, 'Single', lstAccount[0], lstContact[0], TestDataFactoryUtils.getContextUserId(), lstProduct, 'Draft'));
		IMCDUtils.debugLimits('[TestManualRenewalCompController][testSetup] after TestDataFactory.createQuoteWithLine()');
		TestDataFactoryUtils.runProcessBuilders(true); // don't run 'm earlier... SOQL limit!
		TestDataFactoryUtils.runTriggers(false); // don't run 'm earlier... SOQL limit!
		lstSingleQuote[0].SBQQ__Status__c = 'Presented'; // this generates contracted prices
		lstSingleQuote[1].SBQQ__Status__c = 'Presented'; // this generates contracted prices
		update lstSingleQuote;
		IMCDUtils.debugLimits('[TestManualRenewalCompController][testSetup] after updating lstSingleQuote as Presented');
		lstSingleQuote[0].SBQQ__Status__c = 'Accepted'; // Final stage New WvB 28-8-18
		lstSingleQuote[1].SBQQ__Status__c = 'Accepted'; // Final stage New WvB 28-8-18
		update lstSingleQuote;
		IMCDUtils.debugLimits('[TestManualRenewalCompController][testSetup] after updating lstSingleQuote as Accepted');
		Test.stopTest();
	}

	@isTest
	static void testIsFeatureEnabled () {
		ManualRenewalCompController.isFeatureEnabled(); // just coverage
	}

	@isTest
	static void testGetContractedPrices () {
		system.debug('testGetContractedPrices=' + ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c));
		System.assert(ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c).size() == 4, 'Four Contracted prices should be returned');
	}

	@isTest
	static void testValidateRenewalProductsNoErrors () {
		List<SBQQ__ContractedPrice__c> lstContractedPrice = ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c);
		List<SBQQ__ContractedPrice__c> lstValidationResult = ManualRenewalCompController.validateRenewalProducts(lstContractedPrice);
		Test.startTest();
		System.assert([SELECT Id FROM SBQQ__ContractedPrice__c WHERE ValidationErrors__c = null].size() == 4, 'There should be no errors reported');
		Test.stopTest();
	}

	@isTest
	static void testValidateRenewalProductsWithLobErrors () {
		List<SBQQ__Quote__c> lstQuote = [SELECT Id, LOB1__c FROM SBQQ__Quote__c];

		while (lstQuote[0].LOB1__c == lstQuote[1].LOB1__c) {
			lstQuote[0].LOB1__c = TestDataFactoryUtils.getRandomPickListValue(new Account(), 'Primary_LOB1__c');
			lstQuote[1].LOB1__c = TestDataFactoryUtils.getRandomPickListValue(new Account(), 'Primary_LOB1__c');
		}

		update lstQuote;
		List<SBQQ__ContractedPrice__c> lstContractedPrice = ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c);
		List<SBQQ__ContractedPrice__c> lstValidationResult = ManualRenewalCompController.validateRenewalProducts(lstContractedPrice);
		System.assert(!String.isEmpty(lstValidationResult[0].ValidationErrors__c), 'There should have been two LOB  errors reported');
	}

	@isTest
	static void testValidateRenewalProductsWithIncotermErrors () {
		List<SBQQ__Quote__c> lstQuote = [SELECT Id, IncoTerms2__c FROM SBQQ__Quote__c];

		while (lstQuote[0].IncoTerms2__c == lstQuote[1].IncoTerms2__c) {
			lstQuote[0].IncoTerms2__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'IncoTerms2__c');
			lstQuote[1].IncoTerms2__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'IncoTerms2__c');
		}

		update lstQuote;
		List<SBQQ__ContractedPrice__c> lstContractedPrice = ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c);
		List<SBQQ__ContractedPrice__c> lstValidationResult = ManualRenewalCompController.validateRenewalProducts(lstContractedPrice);
		System.assert(!String.isEmpty(lstValidationResult[0].ValidationErrors__c), 'There should have been two Incoterms errors reported');
	}

	@isTest
	static void testValidateRenewalProductsWithShiptoErrors () {
		List<SBQQ__Quote__c> lstQuote = [SELECT Id, IncoTerms2__c, SBQQ__Account__c FROM SBQQ__Quote__c];
		List<AccountShiptoAddress__c> lstShipto = TestDataFactory.returnShipto(1, lstQuote[0].SBQQ__Account__c);
		insert lstShipto;
		lstQuote[0].ShiptoAddress__c = lstShipto[0].Id;
		lstQuote[0].PriceRestriction__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'PriceRestriction__c');
		update lstQuote;

		List<SBQQ__ContractedPrice__c> lstContractedPrice = ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c);
		List<SBQQ__ContractedPrice__c> lstValidationResult = ManualRenewalCompController.validateRenewalProducts(lstContractedPrice);
		System.assert(!String.isEmpty(lstValidationResult[0].ValidationErrors__c), 'There should have been two Shipto address errors reported');
	}

	@isTest
	static void testCreateRenewalQuote () {
		String expirationDt = String.valueOf(date.today());
		String validityToDt = String.valueOf(date.today() + 10);
		String validityFromDt = String.valueOf(date.today() + 30);
		List<SBQQ__ContractedPrice__c> lstContractedPrice = ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c);

		ID quoteId = ManualRenewalCompController.createRenewalQuote(lstContractedPrice, expirationDt, validityToDt, validityFromDt, lstContractedPrice[0].Id);
		Integer numLines = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId].size();

		System.assert(!String.isEmpty(quoteId), 'createRenewalQuote did not create the renewal quote');
		System.assert(numLines == 4, 'createRenewalQuote did not create 4 quote lines');
	}

	@isTest
	static void testCreateRenewalQuoteExceptions () {
		String expirationDt = String.valueOf(date.today());
		String validityToDt = String.valueOf(date.today() + 10);
		String validityFromDt = String.valueOf(date.today() + 30);
		List<SBQQ__ContractedPrice__c> lstContractedPrice = ManualRenewalCompController.getContractedPrices([SELECT SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1].SBQQ__Account__c);

		// Make it FAIL to go into exception. Providing lstContractedPrice[0].SBQQ__Account__c instead of lstContractedPrice[0].Id
		ID quoteId = ManualRenewalCompController.createRenewalQuote(lstContractedPrice, expirationDt, validityToDt, validityFromDt, lstContractedPrice[0].SBQQ__Account__c);
		System.assert(String.isEmpty(quoteId), 'createRenewalQuote should not create the renewal quote');
	}

	@isTest
	static void testAddValidationError () {
		Map <Id, List<String>> validationMap = new Map <Id, List<String>>();
		Map <Id, SBQQ__ContractedPrice__c> priceMap
				= new Map <Id, SBQQ__ContractedPrice__c>([SELECT Id, UniqueKey__c FROM SBQQ__ContractedPrice__c LIMIT 1]);
		ID contractedPriceId = [SELECT Id FROM SBQQ__ContractedPrice__c LIMIT 1].Id;
		validationMap = ManualRenewalCompController.addValidationError(validationMap, contractedPriceId, 'a first bogus error');
		System.assertEquals(1, validationMap.get(contractedPriceId).size(), 'Map with one  error expected');

		List<String> lstErr = new List<String>();
		lstErr.add('yet a seond bogus error');
		validationMap.put(contractedPriceId, lstErr);
		validationMap = ManualRenewalCompController.addValidationError(validationMap, contractedPriceId, 'another bogus error');
		System.assertEquals(2, validationMap.get(contractedPriceId).size(), 'Map with two errors expected');

		priceMap.put(contractedPriceId, [SELECT Id, UniqueKey__c FROM SBQQ__ContractedPrice__c WHERE Id =: contractedPriceId]);
		SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Quote__r.Name, UniqueKey__c FROM SBQQ__QuoteLine__c LIMIT 1];
		validationMap = ManualRenewalCompController.addValidationError(priceMap, validationMap, quoteLine, 'bogus error');
		System.assertEquals(3, validationMap.get(contractedPriceId).size(), 'Map with three errors expected');
	}

	@isTest
	static void testVerifyCompController_verifyQuote_noWarnings () {
		// Quote lines are created with random quantities
		List<SBQQ__Quote__c> lstQuote = [SELECT Id, IncoTerms2__c FROM SBQQ__Quote__c LIMIT 1];
		lstQuote[0].LOB1__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'LOB1__c');
		update lstQuote;
		List<SBQQ__QuoteLine__c> results = VerifyQuoteCompController.verifyQuote(lstQuote[0].Id);
		System.assertEquals(0, VerifyQuoteCompController.verifyQuote(lstQuote[0].Id).size(), 'verifyQuote_noWarnings should return an empty list | ' +
				VerifyQuoteCompController.verifyQuote(lstQuote[0].Id));
	}

	@isTest
	static void testVerifyCompController_verifyQuote_LobError () {
		// Quote lines are created with random quantities
		List<SBQQ__Quote__c> lstQuote = [SELECT Id, IncoTerms2__c FROM SBQQ__Quote__c LIMIT 1];
		lstQuote[0].LOB1__c = '';
		update lstQuote;
		List<SBQQ__QuoteLine__c> results = VerifyQuoteCompController.verifyQuote(lstQuote[0].Id);
		System.assertEquals(1, VerifyQuoteCompController.verifyQuote(lstQuote[0].Id).size(), 'verifyQuote_LobError should return one error | ' +
				VerifyQuoteCompController.verifyQuote(lstQuote[0].Id));
	}

	@isTest
	static void testVerifyCompController_verifyQuote_DoubleProductWarning () {
		TestDataFactoryUtils.runProcessBuilders(false);
		TestDataFactoryUtils.runTriggers(false);
		TestDataFactoryUtils.runValidationRules(false);
		List<SBQQ__Quote__c> lstQuote = [SELECT Id, IncoTerms2__c FROM SBQQ__Quote__c LIMIT 2];
		lstQuote[0].LOB1__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'LOB1__c');
		lstQuote[1].LOB1__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'LOB1__c');
		update lstQuote;

		List<SBQQ__QuoteLine__c> lstQuoteLine = New List<SBQQ__QuoteLine__c>([SELECT Id, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c]);

		// Same quantity & UOM force a warning (in total 2 quotes each with 2 lines)
		for (SBQQ__QuoteLine__c quoteLine : lstQuoteLine) {
			quoteLine.SBQQ__Quantity__c = 1;
			quoteLine.Quant__c = 1;
			quoteLine.UOM__c = 'KG';
		}

		update lstQuoteLine;
		delete [SELECT Id FROM IntegrationLog__c]; // Delete IntegrationLog in order to delete CPs
		delete [SELECT Id FROM SBQQ__ContractedPrice__c]; // prevent CP warning

		// Two lines are conflicting with two same lines on another quote, verifyQuote returns a single error.
		System.assertEquals(2, VerifyQuoteCompController.verifyQuote(lstQuote[0].Id).size(), 'verifyQuote_DoubeProductWarning should return two errors');
	}
}