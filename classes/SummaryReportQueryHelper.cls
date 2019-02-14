/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
Description:   Helper class for Create Principal Report flow
			   Support queries which cannot be done bulkified with Flow builder
			   Class can only hold single InvocableMethod, hence input parameters differ per support scenario.
Inputs:        See comments
Test Class:    TestSummaryReportQueryHelper
History
	26/11/2018 Created class
	08/01/2019 Included additional scenarios for Principal reports (scenario's F - I
	30/01/2019 Included additional scenario J for Customer Summary Reporting (replacing fastLookup in flow)
	01/02/2019 Added Key clause to Scenario A (Customer Summary Reporting)
------------------------------------------------------------*/

global with sharing class SummaryReportQueryHelper {

	/*
	* Scenario A - Retrieving List<SBQQ__QuoteLine__c> for List<Opportunity>
	* Scenario B - Retrieving List<FollowupReport__c> for List<SBQQ__QuoteLine__c>
	* Scenario C - Retrieving List<MarketInfoBO__c> for List<SBQQ__QuoteLine__c>
	* Scenario D - Retrieving List<MarketInfoMarket__c> for Account
	* Scenario E - Retrieving List<VisitReportOppty__c> for List<Opportunity>
	* Scenario F - Retrieving List<SBQQ__QuoteLine__c> for list <Product2> for Principal (including additional query params)
	* Scenario G - Retrieving List<Product2> as unique list of products from List<SBQQ__QuoteLine__c> (including additional query params)
	* Scenario H - Retrieving List<Product2> as unique list of product from List<MarketInfoMarket__c> for Principal (including additional query params)
	* Scenario I - Retrieving List<MarketInfoMarket__c> for list <Product2> for Principal cluding additional query params)
	* Scenario J - Retrieving List<Opportunity> for accountId (including additional params)
	* Scenario K - Retrieving List<VisitReport__c> for accountId (including Start / End Date)
	*/

	global class HelperQueryRequest {
		// Scenario A
		@InvocableVariable (required=false label='List<Opportunity>' description='Provide as well lstQuoteLineFields, lstMarketInfoBoFields or lstVisitreportFields')
		global List<Opportunity> lstOpportunity;
		@InvocableVariable (required=false label='List<String> of SBQQ__QuoteLine__c fields' description='Provide as well lstOpportunity')
		global List<String> lstQuoteLineFields;

		// Scenario B
		@InvocableVariable (required=false label='List<SBQQ__Quote__Line__c>' description='Provide as well lstFollowupReportFields')
		global List<SBQQ__QuoteLine__c> lstQuoteLine;
		@InvocableVariable (required=false label='List<String> of FollowUpReport__c fields' description='Provide as well lstQuoteLine')
		global List<String> lstFollowupReportFields;

		// Scenario C
		@InvocableVariable (required=false label='List<String> of lstMarketInfoBoFields__c fields' description='Provide as well lstQuoteLine')
		global List<String> lstMarketInfoBoFields;

		// Scenario D
		@InvocableVariable (required=false label='<Account> Id field (Sold-to/Prospect Id)' description='Provide as well lstMarketInfoMarketFields')
		global ID accountId;

		@InvocableVariable (required=false label='List<String> of lstMarketInfoMarketFields fields' description='Provide as well accountId')
		global List<String> lstMarketInfoMarketFields;

		// Scenario E
		@InvocableVariable (required=false label='List<String> of VisitReport__c fields' description='Provide as well lstOpportunity')
		global List<String> lstVisitreportFields;

		// Scenario F
		@InvocableVariable (required=false label='<Account> Id field (Principal Id)' description='Provide as well lstQuoteLineFields, Key, Lob, Start/End Dates.')
		global ID principalId;
		@InvocableVariable (required=false label='List<Product2>' description='Provide as well lstQuoteLineFields, principalId, Key, Lob, Start/End Dates.')
		global List<Product2> lstProduct;
		@InvocableVariable (required=false label='LOB1' description='Provide as well lstQuoteLineFields, principalId, Key, Lob, Start/End Dates.')
		global String lob;
		@InvocableVariable (required=false label='Key Opportunities' description='Provide as well lstQuoteLineFields, principalId, Lob, Start/End Dates.')
		global Boolean key;
		@InvocableVariable (required=false label='BO Types (;-separated string)' description='Provide as well lstQuoteLineFields, principalId, Lob, Start/End Dates.')
		global String boType;
		@InvocableVariable (required=false label='Start date' description='Provide as well lstQuoteLineFields, principalId, Lob, Start/End Dates.')
		global DateTime startDate;
		@InvocableVariable (required=false label='End date' description='Provide as well lstQuoteLineFields, principalId, Lob, Start/End Dates.')
		global DateTime endDate;
		@InvocableVariable (required=false label='Exclude Cold Opportunities')
		global Boolean excludeColdOppties;
		@InvocableVariable (required=false label='Exclude Lost Lines')
		global Boolean excludeLostLines;

		@InvocableVariable (required=false label='soqlLimit' description='Added as LIMIT n')
		global Integer soqlLimit = 0; // 0 means no limit.

		// Scenario G
		@InvocableVariable (required=false label='List<String> of Product2 fields')
		global List<String> lstProductFields;
		@InvocableVariable (required=false label='Boolean, return only <SBQQ__QuoteLine__c> unique products')
		global Boolean returnQuoteLineProducts = false;

		//Scenario H
		@InvocableVariable (required=false label='Boolean, return only <MarketInfoMarket__c> unique products')
		global Boolean returnMarketInfoMarketProducts = false;

		//Scenario J
		@InvocableVariable (required=false label='List<String> of Opportunity fields')
		global List<String> lstOpportunityFields;

		//Scenario K
		@InvocableVariable (required=false label='List<String> of VisitReport__c fields (Unrelated)')
		global List<String> lstUnrelatedVisitReportFields;
	}

	global class HelperQueryResult {
		// Scenario A & Scenario F
		@InvocableVariable (required=false label='List<SBQQ__QuoteLine__c>' description='Output for lstOpportunity/lstQuoteLineFields')
		global List<SBQQ__QuoteLine__c> lstQuoteLine;

		// Scenario B
		@InvocableVariable (required=false label='List<FollowUpReport__c>' description='Output for lstQuoteLine/lstFollowupReportFields')
		global List<FollowUpReport__c> lstFollowupReport;

		// Scenario C
		@InvocableVariable (required=false label='List<MarketInfoBO__c>' description='Output for lstQuoteLine/lstMarketInfoBoFields')
		global List<MarketInfoBO__c> lstMarketInfoBo;

		// Scenario D
		@InvocableVariable (required=false label='List<MarketInfoMarket__c>' description='Output for accountId/lstMarketInfoMarketFields')
		global List<MarketInfoMarket__c> lstMarketInfoMarket;

		// Scenario E
		@InvocableVariable (required=false label='List<VisitReportOppty__c>' description='Output for lstOpportunity/lstVisitreportFields')
		global List<VisitReportOppty__c> lstVisitReportOptty;

		// Scenario G
		@InvocableVariable (required=false label='List<Product2>' description='Output for principalId/returnQuoteLineProducts')
		global List<Product2> lstProduct;

		// Scenario J
		@InvocableVariable (required=false label='List<Opportunity>' description='Output for accountId/lstOpportunityFields')
		global List<Opportunity> lstOpportunity;

		// Scenario K
		@InvocableVariable (required=false label='List<VisitReport__c>' description='Output for accountId/lstUnrelatedVisitReportFields')
		global List<VisitReport__c> lstVisitReport;

		// All scenarios
		@InvocableVariable (required=false label='Number of records queried.' description='Number of records returned.')
		global Integer numRecords;
	}

	class SummaryReportQueryHelperException extends Exception {}

	@InvocableMethod ( label='Execute Helper Query' description='Executes a helper query based on provided inputs' )
	global static List<HelperQueryResult> executeHelperQuery ( List<HelperQueryRequest> requests ) {

		String origin = '[SummaryReportQueryHelper][executeHelperQuery]';
		IMCDUtils.debugLimits(origin + ' Method entry');

		// Returning object
		HelperQueryResult result = new HelperQueryResult();
		result.numRecords = 0; // default
		List<HelperQueryResult> lstResult = new List<HelperQueryResult>();
		Set<Id> setIds = new Set<Id>();
		HelperQueryRequest request = new HelperQueryRequest();
		String soql = '';

		// No bulkification, only single request allowed!
		if (requests.size() != 1) {
			throw new SummaryReportQueryHelperException ('Method is not bulkified, only allows a single request.');
		}
		else {
			request = requests[0]; // take the single request
		}

		// Decide which scenario
		// Scenario A
		if (request.lstOpportunity <> null && request.lstQuoteLineFields <> null) {
			setIds = getIds(request.lstOpportunity);
			String keyClause = (request.key) ? ' KeyOpportunity__c = true AND ' : '';

			soql = 'SELECT ' + String.join(request.lstQuoteLineFields, ',') + ' ' +
					'FROM SBQQ__QuoteLine__c WHERE' + keyClause + ' Opportunity__c IN :setIds ORDER BY Opportunity__r.Name ASC';
			result.lstQuoteLine = Database.query(soql);
			result.numRecords = result.lstQuoteLine.size();
			if (result.lstQuoteLine.size() == 0) result.lstQuoteLine = null;
		}
		// Scenario B
		else if (request.lstQuoteLine <> null && request.lstFollowupReportFields <> null) {
			setIds = getIds(request.lstQuoteLine);
			soql = 'SELECT ' + String.join(request.lstFollowupReportFields, ',') + ' ' +
					'FROM FollowUpReport__c WHERE QuoteLine__c IN :setIds ORDER BY QuoteName__c ASC, ProductDisplayName__c ASC, CreatedDate DESC';
			result.lstFollowupReport = Database.query(soql);
			result.numRecords = result.lstFollowupReport.size();
			if (result.lstFollowupReport.size() == 0) result.lstFollowupReport = null;
		}
		// Scenario C
		else if (request.lstQuoteLine <> null && request.lstMarketInfoBoFields <> null) {
			setIds = getIds(request.lstQuoteLine);
			soql = 'SELECT ' + String.join(request.lstMarketInfoBoFields, ',') + ' ' +
					'FROM MarketInfoBO__c WHERE QuoteLine__c IN :setIds ORDER BY QuoteName__c ASC, ProductDisplayName__c ASC';
			result.lstMarketInfoBo = Database.query(soql);
			result.numRecords = result.lstMarketInfoBo.size();
			if (result.lstMarketInfoBo.size() == 0) result.lstMarketInfoBo = null;
		}
		// Scenario D
		else if (request.accountId <> null && request.lstMarketInfoMarketFields <> null) {
			system.debug(origin + ' accountId = ' + request.accountId);
			soql = 'SELECT ' + String.join(request.lstMarketInfoMarketFields, ',') + ' ' +
					'FROM MarketInfoMarket__c WHERE Account__c = \'' + request.accountId + '\' ORDER BY OpportunityName__c ASC, ProductName__c ASC';
			result.lstMarketInfoMarket = Database.query(soql);
			result.numRecords = result.lstMarketInfoMarket.size();
			if (result.lstMarketInfoMarket.size() == 0) result.lstMarketInfoMarket = null;
		}
		// Scenario E
		else if (request.lstOpportunity <> null && request.lstVisitreportFields <> null) {
			setIds = getIds(request.lstOpportunity);
			soql = 'SELECT ' + String.join(request.lstVisitreportFields, ',') + ' ' +
					'FROM VisitReportOppty__c WHERE PrimaryQuoteId__c <> null AND Opportunity__c IN :setIds ORDER BY OpportunityName__c ASC, VisitDate__c ASC';
			result.lstVisitReportOptty = Database.query(soql);
			result.numRecords = result.lstVisitReportOptty.size();
			if (result.lstVisitReportOptty.size() == 0) result.lstVisitReportOptty = null;
		}
		// Scenario F
		else if (request.principalId <> null && request.lstQuoteLineFields <> null && request.lstProduct <> null) {
			// Building the WHERE clause
			String keyClause = (request.key) ? ' AND KeyOpportunity__c = true' : '';
			String lobClause = (!String.isEmpty(request.lob)) ? ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.LOB1__c = \'' + request.lob + '\'' : '';
			Set<String> setBoType = getSetBoType(request.boType);
			String boTypeClause = (!setBoType.isEmpty()) ? ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Type IN :setBoType' : '';
			String lostLinesClause = (request.excludeLostLines) ? ' AND Stage__c <> \'Lost\'' : '';
			String coldOpptyClause = (request.excludeColdOppties) ? ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Cold_Opportunity__c = false' : '';
			String soqlLimit = (request.soqlLimit > 0) ? ' LIMIT ' + request.soqlLimit : '';
			Set<ID> setProductIds = new Set<ID>();

			for (Product2 product : request.lstProduct) {
				setProductIds.add(product.Id);
			}

			String productClause = ' AND SBQQ__Product__c IN :setProductIds';

			soql = 'SELECT ' + String.join(request.lstQuoteLineFields, ',') + ' ' +
					'FROM SBQQ__QuoteLine__c ' +
					'WHERE SBQQ__Product__r.Principal__c = \'' + request.principalId + '\'' +
					' AND SBQQ__Quote__r.RecordType.DeveloperName = \'OpportunityQuote\'' +
					' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.isClosed = false' +
					' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate > ' + request.startDate.format('yyyy-MM-dd') +
					' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate < ' + request.endDate.format('yyyy-MM-dd') +
					keyClause +
					lobClause +
					boTypeClause +
					productClause +
					lostLinesClause +
					coldOpptyClause +
					' ORDER BY ProductDisplay__c, Stage__c' +
					soqlLimit;

			result.lstQuoteLine = Database.query(soql);
			result.numRecords = result.lstQuoteLine.size();
			if (result.lstQuoteLine.size() == 0) result.lstQuoteLine = null;
		}
		// Scenario G
		else if (request.principalId <> null && request.lstProductFields <> null && request.returnQuoteLineProducts) {
			String keyClause = (request.key) ? ' AND KeyOpportunity__c = true' : '';
			String lobClause = (!String.isEmpty(request.lob)) ? ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.LOB1__c = \'' + request.lob + '\'' : '';
			Set<String> setBoType = getSetBoType(request.boType);
			String boTypeClause = (!setBoType.isEmpty()) ? ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Type IN :setBoType' : '';
			String lostLinesClause = (request.excludeLostLines) ? ' AND Stage__c <> \'Lost\'' : '';
			String coldOpptyClause = (request.excludeColdOppties) ? ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Cold_Opportunity__c = false' : '';
			String soqlLimit = (request.soqlLimit > 0) ? ' LIMIT ' + request.soqlLimit : '';

			// Hard soqlLimit for the number of records
			String soqlSubQuery = 'SELECT SBQQ__Product__c ' +
					'FROM SBQQ__QuoteLine__c ' +
					'WHERE SBQQ__Product__r.Principal__c = \'' + request.principalId + '\'' +
					' AND SBQQ__Quote__r.RecordType.DeveloperName = \'OpportunityQuote\'' +
					' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.isClosed = false' +
					' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate > ' + request.startDate.format('yyyy-MM-dd') +
					' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate < ' + request.endDate.format('yyyy-MM-dd') +
					keyClause +
					lobClause +
					boTypeClause +
					lostLinesClause +
					coldOpptyClause +
					' GROUP BY SBQQ__Product__c, SBQQ__Product__r.TradeName__c' +
					' ORDER BY SBQQ__Product__r.TradeName__c' +
					soqlLimit;


			system.debug(soqlSubQuery);
			Set<String> setProductIds = new Set<String>();

			// Creating a unique set of products among the queried quote lines
			for (AggregateResult quoteLine : Database.query(soqlSubQuery)) {
				setProductIds.add(quoteLine.get('SBQQ__Product__c').toString());
			}
			// handle soqlLimit
			if (setProductIds.size() <= request.soqlLimit) {
				soql = 'SELECT ' + String.join(request.lstProductFields, ',') + ' ' +
						'FROM Product2 ' +
						'WHERE Id IN :setProductIds';
				result.lstProduct = Database.query(soql);
				result.numRecords = result.lstProduct.size();
			}
			else {
				result.numRecords = request.soqlLimit;
			}

			if (result.lstProduct.size() == 0) result.lstProduct = null;
		}
		// Scenario H
		else if (request.principalId <> null && request.lstProductFields <> null && request.returnMarketInfoMarketProducts) {
			String soqlLimit = (request.soqlLimit > 0) ? ' LIMIT ' + request.soqlLimit : '';

			// Hard soqlLimit for the number of records
			String soqlSubQuery = 'SELECT Product__c ' +
					'FROM MarketInfoMarket__c ' +
					'WHERE ( PrincipalId__c = \'' + request.principalId + '\'' +
					' OR PrincipalLookup__c = \'' + request.principalId + '\' )' +
					' AND RecordType.DeveloperName = \'MarketInfoOngoing\'' +
					' AND Product__c <> null' +
					' GROUP BY Product__c, Product__r.Name' +
					' ORDER BY Product__r.Name' +
					soqlLimit;

			Set<String> setProductIds = new Set<String>();

			// Creating a unique set of products among the queried MarketInfoMarket lines
			for (AggregateResult marketInfoMarket : Database.query(soqlSubQuery)) {
				setProductIds.add(marketInfoMarket.get('Product__c').toString());
			}

			// handle soqlLimit
			if (setProductIds.size() <= request.soqlLimit) {
				soql = 'SELECT ' + String.join(request.lstProductFields, ',') + ' ' +
						'FROM Product2 ' +
						'WHERE Id IN :setProductIds';
				result.lstProduct = Database.query(soql);
				result.numRecords = result.lstProduct.size();
			}
			else {
				result.numRecords = request.soqlLimit;
			}

			if (result.lstProduct.size() == 0) result.lstProduct = null;
		}
		// Scenario I
		else if (request.principalId <> null && request.lstProduct <> null && request.lstMarketInfoMarketFields <> null) {
			String soqlLimit = (request.soqlLimit > 0) ? ' LIMIT ' + request.soqlLimit : '';
			Set<ID> setProductIds = new Set<ID>();

			for (Product2 product : request.lstProduct) {
				setProductIds.add(product.Id);
			}

			String productClause = 'Product__c IN :setProductIds';

			// Hard soqlLimit for the number of records
			soql = 'SELECT ' + String.join(request.lstMarketInfoMarketFields, ',') + ' ' +
					'FROM MarketInfoMarket__c ' +
					'WHERE ( ' + productClause +
					' OR PrincipalId__c = \'' + request.principalId + '\'' +
					' OR PrincipalLookup__c = \'' + request.principalId + '\' )' +
					' AND RecordType.DeveloperName = \'MarketInfoOngoing\'' +
					' ORDER BY Product__r.Name' +
					soqlLimit;

			result.lstMarketInfoMarket = Database.query(soql);
			result.numRecords = result.lstMarketInfoMarket.size();

			if (result.lstMarketInfoMarket.size() == 0) result.lstMarketInfoMarket = null;
		}
		// Scenario J
		else if (request.accountId <> null && request.lstOpportunityFields <> null) {
			String keyClause = (request.key) ? ' AND Key_Opportunity__c = true' : '';
			String lobClause = (!String.isEmpty(request.lob)) ? ' AND LOB1__c = \'' + request.lob + '\'' : '';
			Set<String> setBoType = getSetBoType(request.boType);
			String boTypeClause = (!setBoType.isEmpty()) ? ' AND Type IN :setBoType' : '';
			String coldOpptyClause = (request.excludeColdOppties) ? ' AND Cold_Opportunity__c = false' : '';

			soql = 'SELECT ' + String.join(request.lstOpportunityFields, ',') + ' ' +
					'FROM Opportunity ' +
					'WHERE AccountId = \'' + request.accountId + '\'' +
					' AND CloseDate > ' + request.startDate.format('yyyy-MM-dd') +
					' AND CloseDate < ' + request.endDate.format('yyyy-MM-dd') +
					keyClause +
					lobClause +
					boTypeClause +
					coldOpptyClause +
					' ORDER BY CloseDate DESC';

		system.debug(soql);
			result.lstOpportunity = Database.query(soql);
			result.numRecords = result.lstOpportunity.size();
			if (result.lstOpportunity.size() == 0) result.lstOpportunity = null;
		}
		// Scenario K
		else if (request.accountId <> null && request.lstUnrelatedVisitreportFields <> null) {
			soql = 'SELECT ' + String.join(request.lstUnrelatedVisitreportFields, ',') + ' ' +
					'FROM VisitReport__c ' +
					'WHERE Account__c = \'' + request.accountId + '\'' +
					' AND Visit_Date__c > ' + request.startDate.format('yyyy-MM-dd') +
					' AND Visit_Date__c < ' + request.endDate.format('yyyy-MM-dd') +
					' ORDER BY Visit_Date__c DESC';

			result.lstVisitReport = Database.query(soql);
			result.numRecords = result.lstVisitReport.size();
			if (result.lstVisitReport.size() == 0) result.lstVisitReport = null;
		}
		// No valid inputs
		else {
			throw new SummaryReportQueryHelperException ('No valid inputs received.');
		}

		system.debug(origin + ' setIds = ' + setIds);
		system.debug(origin + ' SOQL excuted = ' + soql);
		system.debug(origin + ' result = ' + result);

		lstResult.add(result);

		IMCDUtils.debugLimits(origin + ' Method exit');
		return lstResult;
	}

	// Get the Ids of the passed-in list of objects
	private static Set<Id> getIds (List<sObject> lstSObject) {
		return (new Map<Id,SObject>(lstSObject)).keySet();
	}

	private static Set<String> getSetBoType(String boTypes) {
		Set<String> setBoTypes = new Set<String>();

		for (String boType : boTypes.split(';'))
			setBoTypes.add(boType.normalizeSpace());

		return setBoTypes;
	}
}