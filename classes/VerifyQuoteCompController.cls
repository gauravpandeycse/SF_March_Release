/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
User Story:    https://imcdgroup.atlassian.net/browse/SFDP-1939
Test Class:    TestManualRenewalCompController (has all needed data setup)
History
	30/10/2018     Created class. Acts as controller for the VerifyQuoteComp aura bundle
	31/10/2018     Added test coverage (included as part of TestManualRenewalCompController)
	07/11/2018     Excluded existing CP validation for OpportunityQuote
				   Added basic debug logging
    08/11/2018     Added validation rules for
                   - Not allowed countries
                   - Closed parent opportunities
                   - Closed parent opportunityes w/o a Lost Reason
                   - Exworks check for empty Ship-from City & Country
    21/11/2018     - Excluded Dup Quote Lines check for Renewal Quotes
                   - Changed implementation for Allowed Countries to sell.
                   - Added exception handling (Debuglog)
------------------------------------------------------------*/
public with sharing class VerifyQuoteCompController {

	@auraEnabled
	public static List<SBQQ__QuoteLine__c> verifyQuote(ID quoteId) {

		List<SBQQ__QuoteLine__c> lstResult = New List<SBQQ__QuoteLine__c>();

		try {
			lstResult = runVerification(quoteId);
		} catch (Exception exc) {
			DebugLog.addException(exc, '[VerifyQuoteCompController][[verifyQuote]');
		}

		return lstResult;
	}

	private static List<SBQQ__QuoteLine__c> runVerification(ID quoteId) {
		// Source quote
		SBQQ__Quote__c quote = [SELECT RecordType.DeveloperName, SBQQ__Account__c, LOB1__c, SBQQ__Opportunity2__r.isClosed
									, SBQQ__Opportunity2__r.StageName, SBQQ__Opportunity2__r.Loss_Reason__c
									, Ship_From_Country__c, ShipFromCity__c, IncoTerms2__c
								FROM SBQQ__Quote__c WHERE ID = :quoteId];

		// List of source quote lines to consider for validation
		List<SBQQ__QuoteLine__c> lstQuoteLine = New List<SBQQ__QuoteLine__c>([
											SELECT Name, ProductDisplay__c, ErrorMsg__c, UniqueKey__c
													, SBQQ__Product__r.AllowedCountries__c, SBQQ__Quote__r.SBQQ__Account__r.ShippingCountry
											FROM SBQQ__QuoteLine__c
											WHERE SBQQ__Quote__c = :quoteId]);

		system.debug('[VerifyQuoteCompController][verifyQuote] lstQuoteLine = ' + lstQuoteLine);

		//list of objects to to return; empty is there aren't any errors.
		List<SBQQ__QuoteLine__c> lstResult = New List<SBQQ__QuoteLine__c>();
		List<String> lstAllowedType = New List<String>{'Customer', 'Single'};
		List<String> lstIncludeStatus = New List<String>{'Accepted','Rejected','Presented'};
		List<String> lstCustomerSingle = New List<String>{'CustomerQuote', 'SingleQuote'};
		List<String> lstOpportunityRenewal = New List<String>{'OpportunityQuote', 'RenewalQuote'};
		List<String> lstExworks = New List<String>{'EXW','FCA','FOB'};
		Set<String> setUniqueKey = new Set<String>(); // Set of unique Product keys

		// Test for missing Account on the quote (can only be caused by migrated OpportunityQuotes)
		if (String.isEmpty(quote.SBQQ__Account__c)) {
			lstResult.add(returnError('Quote is missing a valid Account, which is required.\n'));
			return lstResult; // other validation cannot be done without an account
		}

		// Test for missing LOB1 on the quote
		if (String.isEmpty(quote.LOB1__c)) lstResult.add(returnError('Quote is missing the LOB, which is required.\n'));

		// Test Closed parent opportunity for Customer Quotes
		if (quote.RecordType.DeveloperName == 'CustomerQuote') {
			if (quote.SBQQ__Opportunity2__r.isClosed) lstResult.add(returnError('Beware the parent opportunity is Closed-' + quote.SBQQ__Opportunity2__r.StageName + '\n'));
		}

		// Test Closedl-Lost parent opportunity without a Lost Reason for Customer Quotes
		if (quote.RecordType.DeveloperName == 'CustomerQuote') {
			if (quote.SBQQ__Opportunity2__r.isClosed
					&& quote.SBQQ__Opportunity2__r.StageName.equalsIgnoreCase('Lost')
					&& String.isBlank(quote.SBQQ__Opportunity2__r.Loss_Reason__c)
			) {
				lstResult.add(returnError('The parent opportunity is Closed-Lost but the Reason lost should be provided.\n'));
			}
		}

		// Test for allowed country
		// If ShippingCountry on the Account isn't available, but the producs has allowedCountries it's not allowed to sell!
		for (SBQQ__QuoteLine__c quoteLine : lstQuoteLine) {

			String shippingCountry = quoteLine.SBQQ__Quote__r.SBQQ__Account__r.ShippingCountry;
			String allowedCountries = quoteLine.SBQQ__Product__r.AllowedCountries__c;

			if (String.isNotBlank(allowedCountries)) {

				if (String.isBlank(shippingCountry)) {
					lstResult.add(returnError('Product ' + quoteLine.ProductDisplay__c + ' is not allowed in, because the Account has no Main address/country.\n'));
				}
				else if (!allowedCountries.containsIgnoreCase(shippingCountry)) {
					lstResult.add(returnError('Product ' + quoteLine.ProductDisplay__c + ' is not allowed in ' + shippingCountry + '\n'));
				}
			}
		}

		// Test for Exworks incoterms
		if (lstCustomerSingle.contains(quote.RecordType.DeveloperName)) {
			if (String.isBlank(quote.Ship_From_Country__c) && String.isBlank(quote.ShipFromCity__c) && lstExworks.contains(quote.IncoTerms2__c))
				lstResult.add(returnError('The selected Incoterm ' + quote.IncoTerms2__c + ' requires Ship-from City & Country information.\n'));
		}

		// Test for duplicate items on the Quote (e.g. exact same product / price break)
		for (SBQQ__QuoteLine__c quoteLine : lstQuoteLine) {

			if (setUniqueKey.contains(quoteLine.UniqueKey__c)) {
				lstResult.add(returnError('Product ' + quoteLine.ProductDisplay__c + ' is used more than once in this quote.\n'));
			}

			setUniqueKey.add(quoteLine.UniqueKey__c);
		}

		system.debug('[VerifyQuoteCompController][verifyQuote] setUniqueKey = ' + setUniqueKey);

		// Test for duplicate items on other quotes
		// validation isn't required in case it's an opportunity or renewal quote
		if (quote.RecordType.DeveloperName != 'RenewalQuote') {
			for (SBQQ__QuoteLine__c duplicateLine : [
					SELECT Id,
							UniqueKey__c,
							SBQQ__Quote__r.QuoteType__c,
							SBQQ__Quote__r.Name,
							SBQQ__Product__r.Name
					FROM SBQQ__QuoteLine__c
					WHERE SBQQ__Quote__c <> :quoteId //exclude yourself
					AND SBQQ__Quote__r.SBQQ__Account__c = :quote.SBQQ__Account__c
					AND SBQQ__Quote__r.QuoteType__c IN :lstAllowedType // Customer, Single
					AND SBQQ__Quote__r.SBQQ__Status__c IN :lstIncludeStatus // Accepted, Rejected
					AND UniqueKey__c IN :setUniqueKey
			]) {
				lstResult.add(returnError('Duplicate price found on Quote ' + duplicateLine.SBQQ__Quote__r.Name +
						' A combination of the same quantity/incoterms & price restriction already exists for ' + duplicateLine.SBQQ__Product__r.Name +
						' for this customer.\n'));
			}
		}

		// Test for existing contracted prices
		// validation isn't required in case it's an opportunity or renewal quote
			if (!lstOpportunityRenewal.contains(quote.RecordType.DeveloperName)) {
			for (SBQQ__ContractedPrice__c duplicateLine : [
					SELECT Id, UniqueKey__c
							, SBQQ__OriginalQuoteLine__r.ProductDisplay__c
							, SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.Name
					FROM SBQQ__ContractedPrice__c
					WHERE SBQQ__Account__c = :quote.SBQQ__Account__c
					AND SBQQ__OriginalQuoteLine__r.SBQQ__Quote__c <> :quoteId //exclude yourself
					AND UniqueKey__c IN :setUniqueKey
			]) {
				lstResult.add(returnError('Existing contracted price found. ' +
						' A price for the combination of the same quantity/incoterms & price restriction already exists for ' + duplicateLine.SBQQ__OriginalQuoteLine__r.ProductDisplay__c +
						' on Quote ' + duplicateLine.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.Name + ' for this customer.\n'));
			}
		}

		return lstResult;
	}

	private static SBQQ__QuoteLine__c returnError(String error) {
		return new SBQQ__QuoteLine__c(ErrorMsg__c = error);
	}
}