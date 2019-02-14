public  class PriceRenewalCampaignTriggerHelper {

/******************************************************************************************************************************************************************
 * Author: 		Wim van Beek
 * Company: 	Salesforce / NNcourage
 * Description: Event Handler PriceRenewalCampaign Helper
 * Inputs :		From PriceRenewalCampaignTriggerHandler
 * Test Class : 
 * History :	5-18
 ******************************************************************************************************************************************************************/

			// Translate RPC-status into actions and update status 
	public static void beforeUpdateAction(List<PriceRenewalCampaign__c> newPriceRenewalCampaignList, Map<Id,PriceRenewalCampaign__c> oldPriceRenewalCampaignMap){

		for (PriceRenewalCampaign__c pc: newPriceRenewalCampaignList){

			// Stage moves to Ready  Start Main scheduler. 
			if ((pc.Stage__c == 'Ready' ) && (pc.Stage__c != oldPriceRenewalCampaignMap.get(pc.id).Stage__c  )){
				if (pc.Ownerid != Userinfo.getUserid()  ){
					pc.Stage__c = 'Review';
					DebugLog.addError('Qwner and User must be equal to activate a Price Renewal Campain');
					pc.addError('Only owner can start the processing');
				} else {
					// Start the Schedulded job to process Items.
					PriceRenewalCampaignUtils.resetItemErrors (pc.Ownerid);
					PriceRenewalCampaignUtils.startSchedulder(pc.Ownerid, pc.EffectiveDate__c, 'day');	
					pc.Stage__c = 'Queued';
				}
			}

			// Stage moves to Select : Start search and set status to Revieuw
			if (pc.Stage__c == 'Select' && oldPriceRenewalCampaignMap.get(pc.id).Stage__c != 'Select'){
				PriceRenewalCampaignTriggerHelper.searchProducts(pc);
				pc.Stage__c = 'Review';
			}
			// Stage moves to Processed : Check everything has been processed // New 21-11-2018
			if (pc.Stage__c == 'Processed' && oldPriceRenewalCampaignMap.get(pc.id).Stage__c != 'Processed'){
				if (checkItemsProcessed(pc) == false){
					pc.addError('Not all items are processed yet');
				}
			}
		}
	}

/******************************************************************************************************************************************************************
 * Author: 		Wim van Beek
 * Company: 	Salesforce / NNcourage
 * Description: Search CP and/or Pricebookentries
 * 				1 Search for products/pricebookentries and/or Contracted pricing. Add results to items. 
 *  			2 Anti-duplication process to remove records-in-progress
 * Inputs :		From PriceRenewalCampaignTriggerHandler
 * Test Class : 
 * History :	5-18
 *         Selection of products adjusted 14-1-2019
 *         Selection of future changed
 ******************************************************************************************************************************************************************/


	public static void searchProducts(PriceRenewalCampaign__c priceRenewalCampaign){ 
	//	List<String> skipProductSelection = new List<String>{'06.Inactive','07.Obsolete'};
		List<String> wheresPurchase = new List<String>();  // Store WHERE clauses in List for Purchase 
		List<String> wheresContracted = new List<String>(); // Store WHERE clauses in List for Contracted 
		List<PriceBookEntry> priceBookEntry = new List<PriceBookEntry>();
		List<SBQQ__ContractedPrice__c> contractedPrice = new List<SBQQ__ContractedPrice__c>();

		// Some required selections
		wheresPurchase.add(' PriceBook2id = \'' + priceRenewalCampaign.PriceBook__c + '\' ');
		wheresPurchase.add(' PriceBook2.IsActive = true ');
		wheresPurchase.add(' Product2.IsActive = true ');
		wheresPurchase.add(' Product2.CanCreateCP__c = true ');
		wheresPurchase.add(' UnitPrice != 0');
	//	wheresPurchase.add(' Product2.ItemStatus__c != :  skipProductSelection ');  // obsolite 28-8-18
	//	wheresPurchase.add(' Product2.NoActiveProd__c = false');  // new 28-8-18 Old 14-1-2019
		
		wheresContracted.add(' Old__c = false ');
		wheresContracted.add(' SBQQ__Product__r.IsActive = true ');
		wheresContracted.add(' SBQQ__Product__r.CanCreateCP__c = true ');
		wheresContracted.add(' Quantity__c != null ');   
		if (Test.isRunningTest() == false){ // hate it, no other way to full set of testdata
			wheresContracted.add(' SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__Pricebook__c = \'' + priceRenewalCampaign.PriceBook__c + '\' ');
		}
//		wheresContracted.add(' SBQQ__Product__r.NoActiveProd__c = false');  // new 28-8-18 Old 14-1-2019

		// All seclection fields in Campaign will be put in array
		if (priceRenewalCampaign.ReportingLine__c != null){
			wheresPurchase.add(' Product2.ReportingLine__c LIKE \'%' + String.escapeSingleQuotes(priceRenewalCampaign.ReportingLine__c) + '%\' ');
			wheresContracted.add(' SBQQ__Product__r.ReportingLine__c LIKE \'%' + String.escapeSingleQuotes(priceRenewalCampaign.ReportingLine__c) + '%\' ');
		}

		if (priceRenewalCampaign.Principal__c != null){
			wheresPurchase.add(' Product2.Principal__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.Principal__c) + '\' ');
			wheresContracted.add(' SBQQ__Product__r.Principal__c = \'' +String.escapeSingleQuotes(priceRenewalCampaign.Principal__c) + '\' ');
		}

		if (priceRenewalCampaign.Account__c != null){
			wheresContracted.add(' SBQQ__Account__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.Account__c) + '\' ');
		}


		if (priceRenewalCampaign.ProductManager__c != null){
			wheresPurchase.add(' Product2.ProductManager__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.ProductManager__c) + '\' ');
			wheresContracted.add(' SBQQ__Product__r.ProductManager__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.ProductManager__c) + '\' ');
		}
		if (priceRenewalCampaign.TradeName__c != null){
			wheresPurchase.add(' Product2.TradeName__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.TradeName__c) + '\' ');
			wheresContracted.add(' SBQQ__Product__r.TradeName__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.TradeName__c) + '\' ');
		}

		
		// SOQL1 will search all PricBookEntries
		String SOQL1 = 'SELECT id, PriceBook2id, Product2Id, UnitPrice, CurrencyIsoCode  FROM PriceBookEntry WHERE ' ;
		SOQL1 = SOQL1 +  String.join(wheresPurchase, ' AND ') ;
		system.debug('------ SOQL1 '+ SOQL1);
		Map<Id, PriceRenewalCampaignItem__c> priceRenewalCampaignItemMap = new Map<Id, PriceRenewalCampaignItem__c>();

			// Fill Items for Purchase Prices
		if ( priceRenewalCampaign.PricesToProcess__c == 'Purchase' || priceRenewalCampaign.PricesToProcess__c == 'All' ){
			for (PriceBookEntry pbe: Database.Query(SOQL1)){
				priceRenewalCampaignItemMap.put(pbe.id, new PriceRenewalCampaignItem__c(
					PriceRenewalCampaign__c = priceRenewalCampaign.id,
					Product__c = pbe.Product2id,
					TF_PriceBookEntry__c = pbe.Id,
					CurrencyIsoCode = pbe.CurrencyIsoCode,
					TF_CurrentPrice__c  = pbe.UnitPrice,
					PriceIncrease__c = priceRenewalCampaign.PurchasePriceIncrease__c
					));
			}
			if (priceRenewalCampaignItemMap.size() > 0){
				// Step 1 Collected entries for Purchase prices,
				// Step 2 Remove Items if PriceBookEntry is already menthioned in other Campaign and not processed (De-Duplication)
				for (PriceRenewalCampaignItem__c pcl: [SELECT Product__c, TF_PriceBookEntry__c FROM PriceRenewalCampaignItem__c 
															WHERE TF_PriceBookEntry__c =: priceRenewalCampaignItemMap.keyset()
																AND   Status__c != 'Processed' ]){
					priceRenewalCampaignItemMap.remove(pcl.TF_PriceBookEntry__c);
					
				}
			}
			
		}
		// Add wheresContracted for Contracted only
		if (priceRenewalCampaign.LOB1__c != null){
	 		wheresContracted.add(' SBQQ__Account__r.Primary_LOB1__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.LOB1__c) + '\' ');
		}

		if (priceRenewalCampaign.LOB2__c != null){
			wheresContracted.add(' SBQQ__Account__r.Primary_LOB2__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.LOB2__c) + '\' ');
		}

		if (priceRenewalCampaign.SalesRep__c != null){
			wheresContracted.add(' SBQQ__Account__r.Ownerid = \'' + String.escapeSingleQuotes(priceRenewalCampaign.SalesRep__c) + '\' ');
		}
		
		if (priceRenewalCampaign.ImcdBusinessUnit__c != null){
			wheresContracted.add(' SBQQ__Account__r.ImcdBusinessUnit__c = \'' + String.escapeSingleQuotes(priceRenewalCampaign.ImcdBusinessUnit__c) + '\'');
		}

		// Step 1 Fill Items for Contracted Prices
		if ( priceRenewalCampaign.PricesToProcess__c == 'Contracted' || priceRenewalCampaign.PricesToProcess__c == 'All' ){
			String SOQL2 = 'SELECT id, SBQQ__Product__c, Incoterms__c, SBQQ__EffectiveDate__c, UniqueKey__c, SBQQ__ExpirationDate__c, CurrencyIsoCode, SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c, SBQQ__Account__c, Quantity__c, Number__c, SBQQ__Price__c, UOM__c,SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShiptoAddress__c,  SBQQ__OriginalQuoteLine__r.Incoterms__c FROM SBQQ__ContractedPrice__c ' + 
							( wheresContracted.size() == 0 ? '' : ' WHERE '     ) + String.join(wheresContracted, ' AND ') +
							' ORDER BY SBQQ__ExpirationDate__c DESC, CreatedDate DESC ';
			system.debug('------ SOQL2 '+ SOQL2);

			Set<String> uniqueCP = new Set<String>();
			for (SBQQ__ContractedPrice__c cp: Database.Query(SOQL2)){
	//			String productKey = String.join(new List<String>{cp.SBQQ__Account__c, cp.SBQQ__Product__c, String.valueOf(Integer.valueOf(cp.Quantity__c)),cp.UOM__c,cp.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c,cp.Incoterms__c},';').toLowerCase();
				String productKey = String.join(new List<String>{cp.SBQQ__Account__c, cp.UniqueKey__c},'|').toLowerCase(); // chaned 19-11-2018
				system.debug('------ productKey '+ productKey + ' ' + cp.id );
		//		if (cp.SBQQ__EffectiveDate__c <= Date.today()  ){  // New 7-8-18  Only already started CP Removed 4-2-2019
					if (priceRenewalCampaign.ContractedUntilTo__c == null || priceRenewalCampaign.ContractedUntilTo__c >= cp.SBQQ__ExpirationDate__c ){
						if (priceRenewalCampaign.ContractedUntilFrom__c == null || priceRenewalCampaign.ContractedUntilFrom__c <= cp.SBQQ__ExpirationDate__c ){
							if (uniqueCP.contains(productKey) == false){   // With ORDER BY in SOQL2 make sure the most recent cp is used
								priceRenewalCampaignItemMap.put(cp.id, new PriceRenewalCampaignItem__c(
									PriceRenewalCampaign__c = PriceRenewalCampaign.id,
									Product__c = cp.SBQQ__Product__c,
									Account__c = cp.SBQQ__Account__c,
									ContractedPrice__c = cp.id,
									Quantity__c = cp.Quantity__c,
									TF_CurrentPrice__c  = cp.SBQQ__Price__c,
									CurrencyIsoCode = cp.CurrencyIsoCode,
									PriceIncrease__c = PriceRenewalCampaign.ContractedPriceIncrease__c
									));
								uniqueCP.add(productKey);
							} else {
								system.debug('------ productKey exists '+ productKey);
							}
						}
					}
	//			}
			}
			system.debug('------ uniqueCP.size() '+ uniqueCP.size());
			if (priceRenewalCampaignItemMap.size() > 0){

				// Step 2 Skip if Contracted Prices already Listed and not processed
				
				for (PriceRenewalCampaignItem__c pcl: [SELECT ContractedPrice__c 
																		 FROM PriceRenewalCampaignItem__c 
																		 WHERE ContractedPrice__c =: priceRenewalCampaignItemMap.keyset()
																		 AND   Status__c != 'Processed' ]){
					priceRenewalCampaignItemMap.remove(pcl.ContractedPrice__c);
					
				}
				for (SBQQ__QuoteLine__c quoteLine: [SELECT PrevContractedPrice__c 
																		 FROM SBQQ__QuoteLine__c 
																		 WHERE PrevContractedPrice__c =: priceRenewalCampaignItemMap.keyset()
																		 AND   (SBQQ__Quote__r.SBQQ__Status__c = 'Draft'  
																			 OR SBQQ__Quote__r.SBQQ__Status__c = 'Presented' )
																		  ]){
					priceRenewalCampaignItemMap.remove(quoteLine.PrevContractedPrice__c);
				}
			}
		}
		insert priceRenewalCampaignItemMap.values();
	}

/******************************************************************************************************************************************************************
 * Author: 		Wim van Beek
 * Company: 	Salesforce / NNcourage
 * Description: Check if all items are processed
 * Inputs :		From PriceRenewalCampaignTriggerHandler
 * Test Class : 
 * History :	5-18
 ******************************************************************************************************************************************************************/


	public static boolean checkItemsProcessed(PriceRenewalCampaign__c priceRenewalCampaign){ 

		for  (PriceRenewalCampaignItem__c item : [SELECT id FROM PriceRenewalCampaignItem__c WHERE PriceRenewalCampaign__c =: priceRenewalCampaign.id AND Status__c != 'Processed' LIMIT 1]){
			system.debug('------ found error to close campaign ');
			return false;
		}
		return true;
	}	
}