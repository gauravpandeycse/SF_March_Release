@istest
	public class testCPQadvancedSearchPlugin {

/*------------------------------------------------------------
		Author:        	Wim van Beek
		Company:       	NNCourage
		Description:   	Testclass for CPQadvancedSearchPlugin
		Inputs:        	https://community.steelbrick.com/t5/Developer-Guidebook/Product-Search-Plugin/ta-p/13626

		History
		May 18      Initial
------------------------------------------------------------*/	
	@testSetup 
	Public Static void setupData(){
		Account acc = (Account)CPQTestFactory.createSObject(new Account());
		insert acc;

		String IMCDref = Account.IMCDCompany__c.getDescribe().getPicklistValues()[0].getValue(); 
		PriceBook2 PB = (PriceBook2)CPQTestFactory.createSObject(new PriceBook2(Name='pb', ImcdCompany__c=IMCDref));
		insert PB;

		SBQQ__Quote__c quote = (SBQQ__Quote__c)CPQTestFactory.createSObject(new SBQQ__Quote__c());
		quote.SBQQ__PriceBookId__c = PB.id;
		quote.SBQQ__Account__c = acc.id;
		Insert quote;		

		Product2 Pr2 = (Product2)CPQTestFactory.createSObject(new Product2(Name='A Name45100', IsActive=true));
		Pr2.RecordType = IMCDUtils.getRecordType('Product2', 'TempProduct');
		insert Pr2;
		update Pr2;
		System.debug('------ Pr2 '+ Pr2);

		PricebookEntry PBE = (PricebookEntry)CPQTestFactory.createSObject(
							new PricebookEntry(IsActive = true, 
								UnitPrice=0,
								CurrencyIsoCode = 'EUR',
								Product2Id = Pr2.id, 
								Pricebook2Id=Test.getStandardPricebookId()));
		insert PBE;		
		
		System.debug('------ PBE '+ PBE);
		PBE = (PricebookEntry)CPQTestFactory.createSObject(
							new PricebookEntry(IsActive = true,
								UnitPrice=0, 
								BasePrice__c = true, 
								Product2Id = Pr2.id, 
								Pricebook2Id=quote.SBQQ__PriceBookId__c));
		insert PBE;	
}



	@istest (seealldata=false)
	Public Static void CPQadvancedMain(){
		Test.startTest();	
		Account acc = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Account', 'id != null LIMIT 1'));
		PriceBook2 PB = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceBook2', 'id != null LIMIT 1'));
		SBQQ__Quote__c quote = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
		Product2 Pr2 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Product2', 'id != null LIMIT 1'));
		List<PricebookEntry> PBE = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PricebookEntry', 'id != null '));
		Test.stopTest();

		CPQadvancedSearchPlugin plug = new CPQadvancedSearchPlugin();

		Map<String,Object> fieldValuesMap = new Map<String,Object>();
		fieldValuesMap.put('Principal__c',acc.Id);
		fieldValuesMap.put('Name','A');
		fieldValuesMap.put('ItemStatus__c','01.New');
		List<PricebookEntry> PBEres =  plug.search(quote, fieldValuesMap);
		System.debug('------ PBEres '+ PBEres);

		System.assertEquals(PBEres.size(), 1);
		System.assertEquals(PBEres[0].UnitPrice, 0);

		String billCountryCode = User.Countrycode.getDescribe().getPicklistValues()[1].getValue();
		acc.ShippingCountry =  billCountryCode ;
		update acc;
		Pr2.AllowedCountries__c = 'xx';
		update Pr2;
		PBEres =  plug.search(quote, fieldValuesMap);
		System.debug('------ PBEres '+ PBEres[0].Product2.Alert__c);
		System.assertEquals(PBEres[0].Product2.Alert__c, 'Invalid for country '+billCountryCode );

		acc.ShippingCountry =  null ;
		update acc;
		PBEres =  plug.search(quote, fieldValuesMap);
		System.debug('------ PBEres '+ PBEres[0].Product2.Alert__c);
		System.assertEquals(PBEres[0].Product2.Alert__c, 'Customer needs Sold To Country' );

		fieldValuesMap.clear();
		List<PricebookEntry> PBEres1 =  plug.search(quote, fieldValuesMap);
		System.assertEquals(PBEres1.size(), 0);
		
		// Rest of methods are not used but required by SBQQ.ProductSearchPlugin. Just to get covverage :(		
		plug.getAdditionalSearchFilters(quote, null);
		plug.isSearchCustom(quote, null);
		plug.isFilterHidden(quote, null);
		plug.getFilterDefaultValue(quote, null);
		plug.getAdditionalSearchFilters(quote, null);
		plug.isInputHidden(quote, null);
		plug.getInputDefaultValue(quote, null);
		plug.getAdditionalSuggestFilters(quote, null);
		plug.suggest(quote, null);
		plug.isSuggestCustom(quote, null);


	
	}
}