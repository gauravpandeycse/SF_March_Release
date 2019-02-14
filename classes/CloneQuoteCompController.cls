/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Class supporting the CloneQuoteComp.cmp
Inputs:        ID of SBQQ__Quote__c	
Test Class:    TestCloneCompController	
History	
	01/08/2018 Created class
------------------------------------------------------------*/	

public class CloneQuoteCompController {

    public class customException extends Exception{}

	/**
	* @description     Return the number of Quotes under the SBQQ__Quote__c's parent Opportunity.
	* @param           quoteId
	* @return          Number of child quotes
	*/
	@AuraEnabled
    public static Integer getNumQuotes (ID quoteId) {
        ID opportunityId = [SELECT SBQQ__Opportunity2__r.Id FROM SBQQ__Quote__c WHERE Id = :quoteId].SBQQ__Opportunity2__r.Id;
        return ([SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__r.Id = :opportunityId]).size();
    }

	/**
	* @description  clone the quote
	* @param        quoteId
	* @param        quoteExpirationJson
	* @param        validityFromJson
	* @param        validityToJson
	* @param        cloneLines
	* @return       a SBQQ__Quote__c ID in case of success, otherwise null
	*/
	@auraEnabled
    public static ID cloneQuote (ID quoteId, String quoteExpirationJson, String validityFromJson, String validityToJson, String incoTerms, Boolean cloneLines) {
		ID clonedQuoteId;
		String quoteSoql = '';
		String quoteLineSoql = '';
		Savepoint sp = Database.setSavepoint();
		System.debug('[CloneQuoteCompController][cloneQuote] Method entry');
		System.debug('[CloneQuoteCompController][cloneQuote] quoteId  = ' + quoteId);
		System.debug('[CloneQuoteCompController][cloneQuote] quoteExpirationJson  = ' + quoteExpirationJson);
		System.debug('[CloneQuoteCompController][cloneQuote] validityFromJson  = ' + validityFromJson);
		System.debug('[CloneQuoteCompController][cloneQuote] validityToJson  = ' + validityToJson);
		System.debug('[CloneQuoteCompController][cloneQuote] incoTerms  = ' + incoTerms);
		System.debug('[CloneQuoteCompController][cloneQuote] cloneLines  = ' + cloneLines);

        try {
			Date quoteExpiration = Date.valueOf(quoteExpirationJson);
        	Date validityFrom = Date.valueOf(validityFromJson);
        	Date validityTo = Date.valueOf(validityToJson);
            
            if (String.isEmpty(quoteId))
            	throw new customException('Quote Id is missing from the invocation');
        
        	quoteSoql = ImcdUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'Id=\'' + quoteId + '\'');

	        System.debug('[CloneQuoteCompController][cloneQuote] quoteSoql  = ' + quoteSoql);
            
			// only query line 
            quoteLineSoql = ImcdUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c=\'' + quoteId + '\' AND Stage__c<>\'' + Label.IMCD_OPPTY_LOST_STAGE + '\'');

	        System.debug('[CloneQuoteCompController][cloneQuote] quoteLineSoql  = ' + quoteLineSoql);

        	SBQQ__Quote__c orgQuote = (SBQQ__Quote__c)Database.query(quoteSoql);
			SBQQ__Quote__c clonedQuote = orgQuote.clone(false, true, false, false); 
            clonedQuote.QuoteExpirationDate__c = quoteExpiration;
            clonedQuote.PriceValidityFrom__c = validityFrom;
            clonedQuote.PriceValidityTo__c = validityTo;
	        clonedQuote.IncoTerms2__c = incoTerms;
            clonedQuote.RecordTypeId = ImcdUtils.getRecordType('SBQQ__Quote__c', 'CustomerQuote').Id;
	        clonedQuote.SBQQ__Primary__c = false;
	        clonedQuote.Migrated__c = false;
            clonedQuote.QuoteType__c = 'Customer';

			System.debug('[CloneQuoteCompController][cloneQuote] Going to insert clonedQuote  = ' + clonedQuote);

	        insert clonedQuote;
            clonedQuoteId = clonedQuote.Id; // clonedQuoteId will be returned to the lightning component
                
            List<SBQQ__QuoteLine__c> lstClonedQuoteLines = new List<SBQQ__QuoteLine__c>();

            if (cloneLines) {
                for (SBQQ__QuoteLine__c orgQuoteLine : (List<SBQQ__QuoteLine__c>)Database.query(quoteLineSoql)) {
                    SBQQ__QuoteLine__c clonedQuoteLine = orgQuoteLine.clone(false, true, false, false);
                    clonedQuoteLine.SBQQ__Quote__c = clonedQuoteId; //re-parent the lines
	                clonedQuoteLine.Stage__c = '';
	                clonedQuoteLine.KeyOpportunity__c = false;
	                clonedQuoteLine.TechnicalSupport__c = '';
	                clonedQuoteLine.Opportunity__c = null;
	                clonedQuoteLine.PriceValidityStart__c = validityFrom;
	                clonedQuoteLine.PriceValidityEnd__c = validityTo;
                    lstClonedQuoteLines.add(clonedQuoteLine);
                }

	            System.debug('[CloneQuoteCompController][cloneQuote] Going to insert lstClonedQuoteLines  = ' + lstClonedQuoteLines);
	            insert lstClonedQuoteLines;
            }
        }
        catch (Exception e) {
	        System.debug('[CloneQuoteCompController][cloneQuote] Exception, check DebugLog__c');
	        Database.rollback(sp); // rollback complete transaction
            clonedQuoteId = null; // reset (will be in return) DML rolled-back
            DebugLog.addException(e, '[CloneQuoteCompController][cloneQuote] Exception while cloning a (SBQQ__Quote__c) Opportunity Quote. See related debug entries. Quote Id = ' + quoteId);
            DebugLog.addInfo('[CloneQuoteCompController][cloneQuote] quoteSoql = ' + quoteSoql);
            DebugLog.addInfo('[CloneQuoteCompController][cloneQuote] quoteLineSoql = ' + quoteLineSoql);
        }
        
        return clonedQuoteId; // return new Quote Id or null in case of faillure
    }
}