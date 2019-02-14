public with sharing class CPQAdvancedSearchUtils {
/******************************************************************************************************************************************************************
* Author:        	Wim van Beek
* Company:     		Salesforce / NNcourage
* Description: 		CPQAdvancedSearchUtils: Create Pricebookentries Just-in-time, Rerate prices
* Inputs :			New Quotelines
* History :      	New 4-2018.
******************************************************************************************************************************************************************/

	public CPQAdvancedSearchUtils() {
		
	}
	Public Class ReRatePrice {
		public String Cur1;
		public String Cur2;
		public Double Price1;
		public Double Price2;
	}

	// Main entrypoint. New quotelines (no Id yet) will be investigated, 
	// ProductId collected and the needed PriceBookEntries will be created
	// If UnitPrice = 0, An attempt will be made te racalculate the price from other Currencies if marked as BasePrice__c

	public static void createPriceBookEntries(List<SBQQ__QuoteLine__c> quoteLines){

		Map<String, PricebookEntry> PricebookEntry = new Map<String, PricebookEntry>();
		List<PricebookEntry> PricebookEntryNew = new List<PricebookEntry>();

		Map<String, reRatePrice> thePrice = new Map<String, reRatePrice>();
		Map<Id, SBQQ__Quote__c> theQuotes = new Map<Id, SBQQ__Quote__c>();
		Set<Id> priceBookIds = new  Set<Id>();
		Set<Id> productIds = new  Set<Id>();
		Id standardPB;
		system.debug('------ quoteLines '+quoteLines);
		for (SBQQ__QuoteLine__c quoteLine : quoteLines){
			theQuotes.put(quoteLine.SBQQ__Quote__c, null);
			productIds.add(quoteLine.SBQQ__Product__c);
		}
		theQuotes = new Map<Id, SBQQ__Quote__c>([SELECT 
													Id, 
													SBQQ__Pricebook__c, 
													CurrencyIsoCode
												FROM SBQQ__Quote__c 
												WHERE id =: theQuotes.keyset()]);
		for (SBQQ__Quote__c quote:theQuotes.values() ){
			priceBookIds.add(quote.SBQQ__Pricebook__c);
		}
		for (PricebookEntry priceBookE: [SELECT 	Id, 
													UnitPrice, 
													Product2id, 
													Pricebook2Id, 
													CurrencyIsoCode, 
													BasePrice__c, 
													PriceBook2.IsStandard
												FROM   PricebookEntry
												WHERE  Product2id = : productIds
													AND ( Pricebook2Id =: priceBookIds 
														OR PriceBook2.IsStandard = true
														)
											    	]){
			String key = String.join(new List<string>{priceBookE.Pricebook2Id, priceBookE.Product2id, priceBookE.CurrencyIsoCode}, ';'); 
			system.debug('------ key '+ key);
			if (priceBookE.PriceBook2.IsStandard == true ){
				standardPB = priceBookE.Pricebook2Id;
			}
			PricebookEntry.put(key,priceBookE );
		}
		if (standardPB == null && Test.isRunningTest() == true){standardPB = Test.getStandardPricebookId();}
		List<PricebookEntry> standardPBE = new List<PricebookEntry>();

		for (SBQQ__QuoteLine__c quoteLine : quoteLines){
			SBQQ__Quote__c quote = theQuotes.get(quoteLine.SBQQ__Quote__c);
			// key = unique ident for PricebookEntry
			if (quote != null){  // Patch 21-11-2018 No reason why this failed
				String key = String.join(new List<String>{quote.SBQQ__Pricebook__c,  quoteLine.SBQQ__Product__c, quoteLine.CurrencyIsoCode}, ';'); 
				// Keyo = unique ident for Standard PricebookEntry
				String key0 = String.join(new List<String>{standardPB,  quoteLine.SBQQ__Product__c, quoteLine.CurrencyIsoCode}, ';'); 
				system.debug('------ key '+ key);
				system.debug('------ Key0 '+ Key0);
				Double price = 0;
				String mode = null;
				if (PricebookEntry.get(key0) == null ){
					PricebookEntry pbnew = new PricebookEntry(
						UnitPrice = 0,
						Product2id = quoteLine.SBQQ__Product__c ,
						Pricebook2Id =   standardPB ,
						IsActive = true,
						CurrencyIsoCode = quoteLine.CurrencyIsoCode
						);
					standardPBE.add(pbnew);
					PricebookEntry.put(key0, pbnew);  // Add to avoid problems with more 1 entry
				}
				if ( PricebookEntry.get(key) == null){
					PricebookEntry pbnew = new PricebookEntry(
						UnitPrice = 0,
						Product2id = quoteLine.SBQQ__Product__c ,
						Pricebook2Id =   quote.SBQQ__Pricebook__c  ,
						IsActive = true,
						CurrencyIsoCode = quoteLine.CurrencyIsoCode
						);
					PricebookEntryNew.add(pbnew);
					PricebookEntry.put(key, pbnew); // Add to avoid problems with more 1 entry
				}
				// reRate the Unitprice besed on BasePrice of with other currency
				ReRatePrice reRate = new ReRatePrice();
				reRate.Cur1 = quoteLine.CurrencyIsoCode;
				reRate.Price1 = PricebookEntry.get(key).UnitPrice;
				reRate.Price2 = 0;
				thePrice.put(key.left(key.length()-4), reRate);
				system.debug('------ reRate '+ reRate);
			} // If quote = null

		}
		for (String key  : PricebookEntry.keyset()){
			system.debug('------ key '+ key);
			PricebookEntry priceBookE = PricebookEntry.get(key);
			if (priceBookE.BasePrice__c == true){
				String newKey = key.left(key.length() -4 )  ;
				ReRatePrice reRate = thePrice.get(newKey);
				if (reRate != null  && priceBookE.UnitPrice != 0 ){
					system.debug('------ reRate '+ reRate);
					reRate.Cur2 = priceBookE.CurrencyIsoCode;
					if (reRate.Price2 == 0){
						reRate.Price2 = priceBookE.UnitPrice * (   IMCDUtils.allCurrencies.get(reRate.Cur1) / IMCDUtils.allCurrencies.get(reRate.Cur2));
					} else {
				//		DebugLog.addInfo('More than 1 BasePrice on '+ priceBookE.Product2id);
						reRate.Price2 = null;
					}
				}
			system.debug('------ reRate '+ reRate);
			}
		}
		for (SBQQ__QuoteLine__c quoteLine : quoteLines){
			SBQQ__Quote__c quote = theQuotes.get(quoteLine.SBQQ__Quote__c);
			String key = String.join(new list<string>{quote.SBQQ__Pricebook__c,  quoteLine.SBQQ__Product__c}, ';'); 
			quoteLine.SBQQ__ListPrice__c = thePrice.get(key).Price2;
		}
        if (Test.isRunningTest() == false){  // Pricebook en entries react a bit different in a testclass. 
	        insert standardPBE;
			insert PricebookEntryNew;
			PricebookEntryNew.clear();
			standardPBE.clear();
		}
	}
}