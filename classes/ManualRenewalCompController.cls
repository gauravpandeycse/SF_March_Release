/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
User Story:    https://imcdgroup.atlassian.net/browse/SFDP-628
History
	03/08/2018     Created class
	06/11/2018     Updated Sort order on getContractedPrices to include CreatedDate DESC
					https://imcdgroup.atlassian.net/browse/SFDP-1768
	03/01/2019	   Fix adding 'Confirmed' to SOQL to support Renewal-over-renewal quotes
------------------------------------------------------------*/
without sharing public class ManualRenewalCompController {

	public class customException extends Exception{}

	/**
	 * @description returns whether the user is assigned the CpqManualPriceRenewalPilot custom permission
	 * @return true if permission is assigned, false otherwise
	 */
	@AuraEnabled
    public static Boolean isFeatureEnabled() {
		return FeatureManagement.checkPermission('CpqManualPriceRenewalPilot');
	}
    
	/**
	* @description  Return the applicable Contract prices for this account.
	*               Prices should be for the specific accountId provided
	*               Prices should have effective date in the past: SBQQ__EffectiveDate <= Today
	*               Ordered by UniqueKeyLob1__c (this includes Product, Quantity, UoM, Incoterms and the ShipToAddressId
	*               ShipToAddressId is a formula field which return ShipToAccount__c in case Incoterms are provided
	*               The Lob1 is added, as prices are considered 'different' depending on the LOB1 for which they are created
	*               Order By is specific such that prices with Expiration most in the future are returned first
	*               While looping through the results, only the first price for a given UniqueKeyLob__c are kept
	* @param        accountId
	* @return       list of Contracted Prices
	*/
	@AuraEnabled
    public static List<SBQQ__ContractedPrice__c> getContractedPrices (ID accountId) {

		Set<String> uniqueKeyLob1 = new Set<String>();
		List<SBQQ__ContractedPrice__c> lstContractedPrice = new List<SBQQ__ContractedPrice__c>();

	    // UniqueKeyLob1__c ex. 01t0O00000ETLbd|15|KG|CFR|a1w1w00000000A4|Pharmaceuticals
	    for (SBQQ__ContractedPrice__c cp : [
			    SELECT Id, UniqueKey__c, UniqueKeyLob1__c, SBQQ__Product__r.Name, Quantity__c, UOM__c
					    , Incoterms__c, SBQQ__EffectiveDate__c, SBQQ__ExpirationDate__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShiptoAddress__r.Name
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.PriceRestriction__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB1__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB2__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB3__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PricebookId__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__c
					    , SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.CurrencyIsoCode
					    , SBQQ__Account__c, CurrencyIsoCode
			    FROM SBQQ__ContractedPrice__c
			    WHERE SBQQ__Account__c=:accountId
			    AND SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__Status__c IN ('Accepted', 'Confirmed')
			    AND SBQQ__EffectiveDate__c<=TODAY
			    ORDER BY UniqueKeyLob1__c, SBQQ__ExpirationDate__c DESC, CreatedDate DESC
	    ]) {
			/* if the UniqueKeyLob1__c does not exist in the set, add it, otherwise continue  */
            if (uniqueKeyLob1.add(cp.UniqueKeyLob1__c)) {lstContractedPrice.add(cp);}
        }

	    System.debug('[ManualRenewalCompController][getContractedPrices] Returning lstContractedPrice = ' + lstContractedPrice);
        return lstContractedPrice;
    }

	/**
	* @description  This method validates the selected products (which are effectively SBQQ__ContractedPrice__c records
	* @param        lstProducts
	* @return       copy of lstProducts with ValidationErrors__c populated if applicable (= concatenated list of validation errors per product)
	*/
	@AuraEnabled
	public static List<SBQQ__ContractedPrice__c> validateRenewalProducts (List<SBQQ__ContractedPrice__c> lstProducts) {

		Map<Id, SBQQ__ContractedPrice__c> mapProducts = new Map<Id, SBQQ__ContractedPrice__c>(lstProducts);
		Map<Id, List<String>> mapValidation = new Map <Id, List<String>>();
		List<SBQQ__ContractedPrice__c> lstResult = lstProducts;
		Set<String> uniqueKeys = new Set<String>();
		String formattedError;
		ID accountId=lstProducts[0].SBQQ__Account__c; /* SBQQ__Account__c is same for all records...  */

		// Populate uniqueKey set
		for (SBQQ__ContractedPrice__c cp : lstProducts) {
			uniqueKeys.add(cp.UniqueKey__c);}

		if (!validateLob(lstProducts)) {
			for (SBQQ__ContractedPrice__c cp : lstProducts) mapValidation=addValidationError(mapValidation, cp.Id, Label.IMCD_LC_MSG_CannotRenewMixedLobs);}

		if (!validateIncoterms(lstProducts)) {
			for (SBQQ__ContractedPrice__c cp : lstProducts) mapValidation=addValidationError(mapValidation, cp.Id, Label.IMCD_LC_MSG_CannotRenewMixedIncoterms);}

		if (!validateShipTo(lstProducts)) {
			for (SBQQ__ContractedPrice__c cp : lstProducts) mapValidation=addValidationError(mapValidation, cp.Id, Label.IMCD_LC_MSG_CannotRenewMixedShipToAddresses);}

		//Check if there are future dated quote lines which conflict with this manual renewal
		for (SBQQ__QuoteLine__c quoteLine : validateQuoteLine(lstProducts)) {
			formattedError = String.format(Label.IMCD_LC_MSG_CannotRenewExistingQuoteLine, new List<String> {quoteLine.SBQQ__Quote__r.Name});
			mapValidation = addValidationError(mapProducts, mapValidation, quoteLine, formattedError);
		}

		// Check if there is a Price renewal campaign which conflicts with this manual renewal
		for (PriceRenewalCampaignItem__c renewalItem : [
				SELECT Id, Status__c, PriceRenewalCampaign__r.Name, ContractedPrice__c
				FROM PriceRenewalCampaignItem__c
				WHERE ContractedPrice__c IN :mapProducts.keySet()
				AND Status__c!='Processed'
		]) {
				formattedError=String.format(Label.IMCD_LC_MSG_CannotRenewExistingPRC, new List<String> {
				renewalItem.PriceRenewalCampaign__r.Name, renewalItem.Status__c
			});
			mapValidation=addValidationError(mapValidation, renewalItem.ContractedPrice__c, formattedError);
		}

		// Check if there are future dates contracted prices which conflicts with this manual renewal
		for (SBQQ__ContractedPrice__c cp : [
				SELECT Id, UniqueKey__c, SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.Name
				FROM SBQQ__ContractedPrice__c
				WHERE SBQQ__Account__c=:accountId
				AND UniqueKey__c IN:uniqueKeys
				AND SBQQ__EffectiveDate__c>TODAY
		]) {
			 formattedError=String.format(Label.IMCD_LC_MSG_RenewalWithFutureContractedPrices, new List<String> {
										cp.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.Name
									});

			// fetch the Contracted price Id from the lstResult and add to mapValidation
			for (SBQQ__ContractedPrice__c cpResult : lstResult) {
				if (cp.UniqueKey__c.equalsIgnoreCase(cpResult.UniqueKey__c)) {
					mapValidation=addValidationError(mapValidation, cpResult.Id, formattedError);
				}
			}
		}

		// Set the ValidationErros__c field on the price record (this will not be committed - only to pass back to the lightning component)
		for (SBQQ__ContractedPrice__c cp : lstResult) {
			if (mapValidation.get(cp.Id)!=null) {
				cp.ValidationErrors__c=String.join(mapValidation.get(cp.Id), '\n');
			}
		}

		System.debug('[ManualRenewalCompController][validateRenewalProducts] Returning lstResult = ' + lstResult);
		return lstResult;
	}

	/**
	* @description  Creating the Renewal Quote - beware lobId is Contracted Price object from which LOB1/2/3 should be used
	* @param        lstProducts
	* @param        quoteExpirationJson
	* @param        validityFromJson
	* @param        validityToJson
	* @param        lobId
	* @return       SBQQ__Quote__Id for the renewal quote created in case of success, otherwise null
	*/
	@AuraEnabled
    public static ID createRenewalQuote(List<SBQQ__ContractedPrice__c> lstProducts, String quoteExpirationJson, String validityFromJson, String validityToJson, ID lobId) {
        
        ID  renewalQuoteId;
        SBQQ__Quote__c renewalQuote;
        List<SBQQ__QuoteLine__c> lstRenewalQuoteLine;
		Savepoint sp = Database.setSavepoint();
        
        try {
			Map<Id, SBQQ__ContractedPrice__c> mapProducts = new Map<Id, SBQQ__ContractedPrice__c>(lstProducts);
            renewalQuote = new SBQQ__Quote__c();
            
            renewalQuote.RecordTypeId = ImcdUtils.getRecordType('SBQQ__Quote__c', 'RenewalQuote').Id;
            renewalQuote.QuoteType__c = 'Renewal'; // Should NOT set renewalQuote.SBQQ__Type__c = 'Renewal';
            renewalQuote.SBQQ__Status__c = 'Draft';
            renewalQuote.SBQQ__QuoteLanguage__c = 'English';
            renewalQuote.OwnerId = UserInfo.getUserId();
            renewalQuote.SBQQ__SalesRep__c = UserInfo.getUserId();
            renewalQuote.ImcdCompanyLookup__c = lstProducts[0].SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__c;
            renewalQuote.CurrencyIsoCode = lstProducts[0].SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.CurrencyIsoCode;
            renewalQuote.SBQQ__Account__c = lstProducts[0].SBQQ__Account__c;
            renewalQuote.QuoteExpirationDate__c = Date.valueOf(quoteExpirationJson);
            renewalQuote.PriceValidityFrom__c = Date.valueOf(validityFromJson);	
			renewalQuote.PriceValidityTo__c = Date.valueOf(validityToJson);
            renewalQuote.LOB1__c = mapProducts.get(lobId).SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB1__c; //lobId is SBQQ__Quote__c record to pick LOB1/2/3 from
            renewalQuote.LOB2__c = mapProducts.get(lobId).SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB2__c;
			renewalQuote.LOB3__c = mapProducts.get(lobId).SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB3__c;
            renewalQuote.IncoTerms2__c = lstProducts[0].Incoterms__c;
            renewalQuote.SBQQ__PricebookId__c = lstProducts[0].SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PricebookId__c;
            
            if (!String.isEmpty(lstProducts[0].SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c)) {
				renewalQuote.ShiptoAddress__c =  lstProducts[0].SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c;
                renewalQuote.PriceRestriction__c = lstProducts[0].SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.PriceRestriction__c;
            }
            
            insert renewalQuote;
            renewalQuoteId = renewalQuote.Id;
            
            if (String.isEmpty(renewalQuoteId)) {throw new customException ('Unable to fetch the renewalQuote.Id');}
            
			/* returnQuoteLines returns a list of SBQQ__QuoteLine__c objects
			*  returnQuoteLines assembles the list and queries for the required fields
			*  Similar to how a CPQ Price Renewal Campaign would create Quote line records
			*  Input: Set of SBQQ__ContractedPrice__c IDs
			*/
           	lstRenewalQuoteLine = PriceRenewalCampaignUtils.returnQuoteLines(mapProducts.keySet(), renewalQuoteId);
            
            if (lstProducts.size() == lstRenewalQuoteLine.size()) {
                insert lstRenewalQuoteLine;}
            else {
				 throw new customException ('Unexpected number of lines from PriceRenewalCampaignUtils.returnQuoteLines() = '  + lstRenewalQuoteLine);}
 		}
		catch (Exception e) {
			Database.rollback(sp); // rollback complete transaction
            renewalQuoteId = null; // reset (will be in return) DML rolled-back
            DebugLog.addException(e, '[ManualRenewalCompController][createRenewalQuote] Exception while creating renewal quite (SBQQ__Quote__c). See related debug entries.');
            DebugLog.addInfo('[ManualRenewalCompController][createRenewalQuote] Tried to insert renewal quote = ' + renewalQuote);
            DebugLog.addInfo('[ManualRenewalCompController][createRenewalQuote] Tried to insert renewal quote lines = ' + lstRenewalQuoteLine);
        }

        return renewalQuoteId;
    }

	/**
	* @description  validates if the list of records contains mixed lobs
	* @param        lstProducts
	* @return       true if validation passes
	*/
	private static boolean validateLob (List<SBQQ__ContractedPrice__c> lstProducts) {

		Set <String> lob = new Set<String>();

		for (SBQQ__ContractedPrice__c cp : lstProducts) {
			lob.add(cp.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB1__c);}

		return (lob.size() == 1);
	}

	/**
	* @description  validates if the list of records contains mixed incoterms
	* @param        lstProducts
	* @return       true if validation passes
	*/
	private static boolean validateIncoterms (List<SBQQ__ContractedPrice__c> lstProducts) {

		Set <String> incoTerms = new Set<String>();

		for (SBQQ__ContractedPrice__c cp : lstProducts) {
			incoTerms.add(cp.IncoTerms__c);}

		return (incoTerms.size() == 1);
	}

	/**
    * @description  validates if the list of records contains mixed shipto addresses
    * @param        lstProducts
    * @return       true if validation passes
    */
	private static boolean validateShipto (List<SBQQ__ContractedPrice__c> lstProducts) {

		Set <String> shipToAddress = new Set<String>();

		for (SBQQ__ContractedPrice__c cp : lstProducts) {
			shipToAddress.add(cp.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c);}

		return (shipToAddress.size() == 1);
	}

	/**
    * @description  validates if the list of records contains future-dates quote lines for the same product
    * @param        lstProducts
    * @return       true if validation passes
    * @History
    *       22/08/18 JEBU/SF Changed WHERE clause see https://imcdgroup.atlassian.net/browse/SFDP-1322
    */
	private static List<SBQQ__QuoteLine__c> validateQuoteLine (List<SBQQ__ContractedPrice__c> lstProducts) {

		Set<String> uniqueKey = new Set<String>();
		ID accountId = lstProducts[0].SBQQ__Account__c; // all products/prices have same account

		for (SBQQ__ContractedPrice__c cp : lstProducts) {
			uniqueKey.add(cp.UniqueKey__c);}

		return [
				SELECT
						SBQQ__Quote__r.Name, UniqueKey__c
				FROM
						SBQQ__QuoteLine__c
				WHERE
					SBQQ__Quote__r.SBQQ__Status__c = 'Draft'
					AND SBQQ__Quote__r.SBQQ__Account__c = :accountId
					AND UniqueKey__c IN :uniqueKey
		];
	}

	/**
	 * @description     adds validationError to the validationMap if it does not yet exists for the contractedPriceId
	 * @param           validationMap
	 * @param           contractedPriceId
	 * @param           validationError
	 * @return          validationMap
	 */
	@TestVisible
	private static Map<ID, List<String>> addValidationError (Map<Id, List<String>> validationMap, ID contractedPriceId, String validationError) {

		List<String> errors = validationMap.get(contractedPriceId);

		if (errors == null) {
			validationMap.put(contractedPriceId, new List<String> {	validationError	});
		} else {
			errors.add(validationError);
			validationMap.put(contractedPriceId, errors);
		}

		return validationMap;
	}

	/**
	 * @description     overloaded method, includes quoteLine as input. Adds validationError to the validationMap if it does not exist in
	 * 	                the mapProducts map for the contractedPriceId
	 * @param           mapProducts
	 * @param           validationMap
	 * @param           quoteLine
	 * @param           validationError
	 * @return          validationMap
	 */
	@TestVisible
	private static Map<ID, List<String>> addValidationError (Map<Id, SBQQ__ContractedPrice__c> mapProducts, Map<Id, List<String>> validationMap, SBQQ__QuoteLine__c quoteLine, String validationError) {

		for (SBQQ__ContractedPrice__c cp : mapProducts.values()) {
			if (cp.UniqueKey__c.equalsIgnoreCase(quoteLine.UniqueKey__c)) {
				return addValidationError(validationMap, cp.Id, validationError);}
		}

		return validationMap;
	}
}