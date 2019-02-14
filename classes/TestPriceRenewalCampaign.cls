@isTest(SeeAllData=false)
/*------------------------------------------------------------	
Author:        Wim van Beek / Nncourage	
Company:       Salesforce	
Description:   Test class for RPC
				Creates a Quote and QouteLines
				Generate CP
				Create PRC
				Fill it with CP
				Generate Renewal Quote
Inputs:        None	
History	
04/16/2018	   Created test class
------------------------------------------------------------*/	
private class TestPriceRenewalCampaign {
		@testSetup 
		Public Static void setupData(){
			// Create all objects to be used in all methods in this class

			SBQQ__QuoteTemplate__c QuoteTemplate = (SBQQ__QuoteTemplate__c) CPQTestFactory.createSObject(new SBQQ__QuoteTemplate__c(Key__c = '1', SBQQ__Default__c = true)); 
			insert QuoteTemplate;

			TestDataFactory.createIntegrationSettings();
			CPQsetting__c cpqSet = new CPQsetting__c(IDdefaultQuoteTemplate__c = QuoteTemplate.id);
			insert cpqSet;


			String IMCDref = Account.IMCDCompany__c.getDescribe().getPicklistValues()[0].getValue(); 

	        PriceBook2 testPriceBook = new Pricebook2(ImcdCompany__c = IMCDref, Id = Test.getStandardPricebookId(),IsActive = true);
	        upsert testPriceBook;

			IMCDref = Account.IMCDCompany__c.getDescribe().getPicklistValues()[1].getValue(); 
			Pricebook2 priceBook = (Pricebook2) CPQTestFactory.createSObject(new Pricebook2(name = 'test', IntegrationId__c = IMCDref, IMCDCompany__c =IMCDref)); 
			insert priceBook;

			EmailTemplatePRC__c emailTemplatePRC = (EmailTemplatePRC__c) CPQTestFactory.createSObject(new EmailTemplatePRC__c()); 
		    for (EmailTemplate emailTemplate:[SELECT id FROM EmailTemplate LIMIT 1]){
		    	emailTemplatePRC.EmailTemplateID__c = emailTemplate.id;
		    }	
			insert emailTemplatePRC;




			Account theSupplier = (Account) CPQTestFactory.createSObject(new Account(Name = 'supl', OwnerId= Userinfo.getuserid(), IMCDCompany__c =IMCDref)) 	;
			theSupplier.recordTypeid = IMCDUtils.getRecordType('Account', 'Principal_Supplier').id;
			theSupplier.CorrespondenceLanguage__c = 'EN';
			insert theSupplier;	

			Account thePrincipal = (Account) CPQTestFactory.createSObject(new Account(Name = 'Princ', OwnerId= Userinfo.getuserid(), IMCDCompany__c =IMCDref)) 	;
			thePrincipal.recordTypeid = IMCDUtils.getRecordType('Account', 'Principal_Global').id;
			thePrincipal.CorrespondenceLanguage__c = 'EN';
			insert thePrincipal;


			Account theCustomer = (Account) CPQTestFactory.createSObject(new Account(Name = 'cust', OwnerId= Userinfo.getuserid(), IMCDCompany__c =IMCDref)) 	;
			theCustomer.recordTypeid = IMCDUtils.getRecordType('Account', 'Customer_Sold_To').id;
			theCustomer.CorrespondenceLanguage__c = 'EN';
			insert theCustomer;
			Contact con = (Contact) CPQTestFactory.createSObject(new Contact(LastName = 'A cust', AccountId = theCustomer.id, email='aaa@aaa.nl')) 	;
			insert con	;

			PriceRenewalCampaign__c PriceRenCam = (PriceRenewalCampaign__c) CPQTestFactory.createSObject(new PriceRenewalCampaign__c()); 
	 		PriceRenCam.PriceBook__c=  priceBook.id;
	 		PriceRenCam.EmailTemplate__c =  emailTemplatePRC.id;
			insert PriceRenCam;

			Product2 prod = (Product2) CPQTestFactory.createSObject(new Product2());  	
			prod.FullSegmentsNumber__c = '123';
			prod.IntegrationId__c = '123';
			prod.itemStatus__c =   '04.Active Sales' ; // New 11-18
			insert prod;

			PriceBookEntry PBE0 = (PriceBookEntry) CPQTestFactory.createSObject(new PriceBookEntry(
													Pricebook2id = testPriceBook.id,
													UnitPrice = 0,
													Supplier__c = thePrincipal.Id,
													Product2id = prod.id )) ;
			insert PBE0;

			SBQQ__ContractedPrice__c contactPrice = (SBQQ__ContractedPrice__c) CPQTestFactory.createSObject(new SBQQ__ContractedPrice__c(
									Quantity__c = 1,
									SBQQ__Price__c = 10,
									SBQQ__EffectiveDate__c = Date.today().addDays(-2),
									SBQQ__ExpirationDate__c = Date.today().addDays(5),
									SBQQ__Account__c = theCustomer.Id,
									SBQQ__Product__c = prod.Id
				                     )); 
			insert contactPrice;

			PriceBookEntry PBE = (PriceBookEntry) CPQTestFactory.createSObject(new PriceBookEntry());  	
			PBE.Product2Id = prod.id;
			PBE.PriceBook2id = priceBook.id;
			PBE.BasePrice__c = true;
			PBE.UnitPrice = 1;
			PBE.Supplier__c = thePrincipal.id;
			insert PBE;

			IMCDCompany__c comp = (IMCDCompany__c) CPQTestFactory.createSObject(new IMCDCompany__c(Name ='test', ImcdCompany__c=priceBook.ImcdCompany__c));  
			insert comp;

			SBQQ__Quote__c  quoteSingle = (SBQQ__Quote__c) CPQTestFactory.createSObject(new SBQQ__Quote__c(SBQQ__Account__c = theCustomer.id, SBQQ__PrimaryContact__c = con.id, QuoteType__c = 'Single', RecordTypeId = IMCDUtils.recordTypeIdMap.get('SingleQuote')));
			insert quoteSingle;	
			SBQQ__QuoteLine__c  quoteLineSingle = (SBQQ__QuoteLine__c) CPQTestFactory.createSObject(new SBQQ__QuoteLine__c(SBQQ__Quote__c =quoteSingle.id, SBQQ__Quantity__c = 1, SBQQ__Product__c = prod.Id,  RecordTypeId = IMCDUtils.recordTypeIdMap.get('SingleQuoteLine')));
			insert quoteLineSingle;
		}

	
	@isTest (seealldata=false)
	    static void PRCmain() {
	    	// This testclass will test a full cycle. Other testclasses will do a more specific unit test
	    Test.startTest();
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactoryUtils.runProcessBuilders(false);   
        PriceBook2 testPriceBook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        Pricebook2 priceBook = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Pricebook2', 'id != null LIMIT 1'));
        EmailTemplatePRC__c emailTemplatePRC = Database.Query(IMCDUtils.getCreatableFieldsSOQL('EmailTemplatePRC__c', 'id != null LIMIT 1'));
        Account thePrincipal = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Account', 'Name = \'princ\' LIMIT 1'));
        Account theCustomer = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Account', 'Name = \'cust\' LIMIT 1'));
        PriceRenewalCampaign__c priceRenCam  = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceRenewalCampaign__c', 'id != null LIMIT 1'));
		Product2 prod;
		prod = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Product2', 'id != null LIMIT 1'));
		IMCDCompany__c comp =  Database.Query(IMCDUtils.getCreatableFieldsSOQL('IMCDCompany__c', 'id != null LIMIT 1'));

		Test.stopTest();

		// Create Qmodel and fill to use in CPQ-api
		PriceRenewalCampaignUtils.QuoteModel QModel = new PriceRenewalCampaignUtils.QuoteModel();
		QModel.nextKey = 1;
		SBQQ__Quote__c quote0 = new SBQQ__Quote__c();
		quote0.RecordTypeId = IMCDUtils.getRecordType('SBQQ__Quote__c','RenewalQuote').id;
		quote0.QuoteType__c = 'Renewal';
		quote0.SBQQ__Account__c = theCustomer.Id;
		quote0.SBQQ__PriceBook__c = priceBook.id;// 	Test.getStandardPricebookId(); 	
		quote0.Migrated__c = false;	
		quote0.PriceValidityFrom__c = Date.today().addDays(-2);
		quote0.PriceValidityTo__c = Date.today().addDays(2);
		QModel.record = quote0;

		PriceRenewalCampaignUtils.QuoteLineModel QModelLine = new PriceRenewalCampaignUtils.QuoteLineModel();	
		SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
		quoteLine.SBQQ__Product__c = prod.id;
		quoteLine.SetContracted__c = false;

		quoteLine.PricePerUOM__c = 1;
		quoteLine.SBQQ__Quantity__c = 1;
		QModelLine.record = quoteLine;	
		QModel.lineItems.add(QModelLine);

		// Create Quote via CPQ-api now

		String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(QModel));
		system.debug('------ quoteJSON '+quoteJSON);

	// Deactivated 10-10-2018 as change in results from CPQ-API

		JSONParser parser;

		PriceRenewalCampaignUtils.QuoteModelReturn QModelRes = new PriceRenewalCampaignUtils.QuoteModelReturn();
		parser = JSON.createParser(quoteJSON);
        while(parser.nextToken() != null ) {
			QModelRes = (PriceRenewalCampaignUtils.QuoteModelReturn)parser.readValueAsStrict(PriceRenewalCampaignUtils.QuoteModelReturn.class);
		}  

		system.debug('------ QModelRes '+JSON.serializePretty( QModelRes));
		
		List<SBQQ__Quote__c> newQuote = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'QuoteType__c = \'Renewal\' '));
		newQuote[0].PriceValidityFrom__c = Date.today().addDays(-1);
		newQuote[0].PriceValidityTo__c = Date.today().addDays(10);
		update newQuote;
		System.assertEquals(newQuote.size() , 1);  // Check 1 quote
		Id newQuoteId = newQuote[0].id;
		List<SBQQ__QuoteLine__c> newQuoteLine = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c = : newQuoteId '));
		newQuoteLine[0].PriceValidityStart__c = Date.today().addDays(-1);
		newQuoteLine[0].PriceValidityEnd__c  = Date.today().addDays(10);
		update newQuoteLine;
		System.assertEquals(1, newQuoteLine.size() ); // Check 1 quoteLine

		Id QLId = QModelRes.lineItems[0].record.Id;

        TestDataFactoryUtils.runTriggers(true);
        TestDataFactoryUtils.runProcessBuilders(false); //31-8-18   
		
		// Will create CP now

		List<SBQQ__ContractedPrice__c > contPrices0 = [SELECT id FROM SBQQ__ContractedPrice__c];
		System.assertEquals(1, contPrices0.size());  // New CP
		for (SBQQ__ContractedPrice__c cp :Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__ContractedPrice__c', 'id != null')) ){
			system.debug('------ cp '+ cp);
		}

		newQuote[0].SBQQ__Status__c = 'Presented';
		update newQuote[0];
        PriceRenewalCampaignUtils.createContractedPrices(new List<id>{QLId});


        PriceRenewalCampaignTriggerHelper.searchProducts(priceRenCam);

		List<SBQQ__ContractedPrice__c > contPrices = [SELECT id FROM SBQQ__ContractedPrice__c];
		for (SBQQ__ContractedPrice__c cp :Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__ContractedPrice__c', 'id != null')) ){
			system.debug('------ cp '+ cp);
		}

		System.assertEquals(2, contPrices.size());  // New CP

		// Search to get all records in RPC
		priceRenCam.Stage__c = 'Setup';
        update priceRenCam;
		priceRenCam.Stage__c = 'Select';
        update priceRenCam;


   		priceRenCam.Stage__c = 'Ready';
        update priceRenCam;

        // Wll generate new Quote




        PriceRenewalCampaignUtils.futureProcessing(Userinfo.getuserid());
        PriceRenewalCampaignUtils.processingPurchasePrice(Userinfo.getuserid());
        PriceRenewalCampaignUtils.processingContractedPrice(Userinfo.getuserid());

        List<SBQQ__Quote__c> checkQuote = [SELECT Id FROM SBQQ__Quote__c ];
		system.assertNotEquals(1, checkQuote.size());         

		List<PriceRenewalCampaignItem__c> itemResults = [SELECT id FROM PriceRenewalCampaignItem__c];
		system.assertNotEquals(1, itemResults.size()); 

		PriceRenewalCampaignUtils.closeCampaigns(Userinfo.getuserid());

		for (SBQQ__Quote__c quote: [SELECT id, SBQQ__Status__c, QuoteType__c, SBQQ__Account__c FROM SBQQ__Quote__c]){
			system.debug('------ quote '+ quote);
			quote.SBQQ__Account__c = priceRenCam.Principal__c;
			quote.SBQQ__Status__c = 'Presented';
			update quote;
			CPQcreateContracedPrice.go(new list<id>{quote.id});
		}
		for (SBQQ__ContractedPrice__c cp: [SELECT SBQQ__Product__r.IsActive, SBQQ__Product__r.CanCreateCP__c, Quantity__c, SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__Pricebook__c FROM SBQQ__ContractedPrice__c]){
			system.debug('------ cp '+ cp);
			system.debug('------ cp '+ cp.SBQQ__Product__r.IsActive);
			system.debug('------ cp '+ cp.SBQQ__Product__r.CanCreateCP__c);
			system.debug('------ cp '+ cp.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__Pricebook__c);
//			system.debug('------ cp '+ cp.SBQQ__Product__r.NoActiveProd__c);


		}
		priceRenCam.Stage__c = 'Setup';
        update priceRenCam;
		priceRenCam.Stage__c = 'Select';
        update priceRenCam;
        // Now do a dummy search in RPC
		priceRenCam.ImcdBusinessUnit__c = Account.ImcdBusinessUnit__c.getDescribe().getPicklistValues()[0].getValue();
		priceRenCam.SalesRep__c = Userinfo.getuserid();
		priceRenCam.ProductManager__c = Userinfo.getuserid();
		priceRenCam.ContractedUntilTo__c  = Date.today();
		priceRenCam.TradeName__c  = 'abc';
		priceRenCam.LOB1__c = 'Food';
		priceRenCam.LOB2__c	= 'Bakery';
		priceRenCam.Principal__c  = thePrincipal.Id;
		priceRenCam.Account__c   = theCustomer.Id;
		priceRenCam.ReportingLine__c  ='Rep';
		priceRenCam.Stage__c = 'Select';
		update priceRenCam;

		itemResults = [SELECT id FROM PriceRenewalCampaignItem__c];
		system.debug('------ itemResults '+itemResults);
		system.assertEquals(4, itemResults.size()); 
	// }

	}
	



    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Test Class for : QuoteLineTriggerHelper2.checkDoubleProducts for QuoteLines
    * History :
    * new 8-18 Wim 
    ******************************************************************************************************************************************************************/

	@isTest (seealldata=false)
	public static void checkDoubleProductsTEST (){
        TestDataFactoryUtils.runProcessBuilders(false);   
        SBQQ__Quote__c  quoteSingle;
			quoteSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
		quoteSingle.QuoteType__c = 'Single';

		update quoteSingle;
		String quoteId = quoteSingle.Id;
		SBQQ__QuoteLine__c  quoteLineSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c = :quoteId  LIMIT 1'));
		quoteLineSingle.RecordTypeId = IMCDUtils.recordTypeIdMap.get('SingleQuoteLine');
		update quoteLineSingle;

        TestDataFactoryUtils.runTriggers(true);

		quoteLineSingle.id = null;
		quoteLineSingle.Quant__c = 2;
		insert quoteLineSingle;

        // Change to equal quantity. Must raise error
		quoteLineSingle.Quant__c = 1;
		try {
			update quoteLineSingle;
		} catch (Exception e){
			Boolean expectedExceptionThrown =  (e.getMessage().contains('product already exists in Quote') ? true : false);
			system.AssertEquals(false, expectedExceptionThrown); 
			return;
		}
		// Should not happen
		system.assert(true, 'No error trow occured');
	}
	
    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Test Class for : QuoteLineTriggerHelper2.checkDoubleProducts for Quotes
    * History :
    * new 11-18 Wim 
    ******************************************************************************************************************************************************************/

	@isTest (seealldata=false)
	public static void checkDoubleProductsViaQuoteTEST (){
        TestDataFactoryUtils.runProcessBuilders(false);   
        SBQQ__Quote__c  quoteSingle1;
		quoteSingle1 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
		quoteSingle1.QuoteType__c = 'Single';
		quoteSingle1.IncoTerms2__c = 'CIF';
		update quoteSingle1;
        SBQQ__Quote__c  quoteSingle2;
		quoteSingle2 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
		quoteSingle2.QuoteType__c = 'Single';
		quoteSingle2.IncoTerms2__c = 'DAF';
		quoteSingle2.id = null;
		insert quoteSingle2;

		String quoteId = quoteSingle1.Id;
		SBQQ__QuoteLine__c  quoteLineSingle1 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c = :quoteId  LIMIT 1'));
		quoteLineSingle1.RecordTypeId = IMCDUtils.recordTypeIdMap.get('SingleQuoteLine');
		update quoteLineSingle1;

		SBQQ__QuoteLine__c  quoteLineSingle2 = quoteLineSingle1;
		quoteLineSingle2.id = null;
		quoteLineSingle2.SBQQ__Quote__c = quoteSingle2.id;
		insert quoteLineSingle2;
        TestDataFactoryUtils.runTriggers(true);

        quoteSingle1.IncoTerms2__c = quoteSingle2.IncoTerms2__c;
        

        // Change to equal quantity. Must raise error
		try {
			update quoteSingle1;
		} catch (Exception e){
			Boolean expectedExceptionThrown =  (e.getMessage().contains('product already exists in Quote') ? true : false);
			system.AssertEquals(true, expectedExceptionThrown); 
			return;
		}
		// Should not happen
		system.assert(true, 'No error trow occured');
		
	}
	
	

    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Test Class for : QuoteLineTriggerHelper2.checkDoubleProducts
    * History :
    * new 8-18 Wim 
    ******************************************************************************************************************************************************************/

	
	@isTest (seealldata=false)
	public static void PriceRenewalCampaignUtilsTEST  (){
		// Test the status of RPC's 1. No RPC
		System.assertEquals(true, PriceRenewalCampaignUtils.allCampaignsDone(Userinfo.getuserid()));
		System.assertEquals(true,  PriceRenewalCampaignUtils.allCampaignsItemsDone(Userinfo.getuserid()));

		PriceRenewalCampaign__c PriceRenCam = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceRenewalCampaign__c', 'Id != null  LIMIT 1'));
		PriceRenCam.Stage__c = 'Queued';
		update PriceRenCam;

		// 2. There is one PRC, No items
		System.assertEquals(false, PriceRenewalCampaignUtils.allCampaignsDone(Userinfo.getuserid()));
		System.assertEquals(true,  PriceRenewalCampaignUtils.allCampaignsItemsDone(Userinfo.getuserid()));
		// Create RPC-item
		PriceBookEntry PBE0 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceBookEntry', 'Id != null  LIMIT 1'));
		String prodId = PBE0.Product2id;
		SBQQ__ContractedPrice__c contactPrice =  Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__ContractedPrice__c', 'Id != null  LIMIT 1'));

		PriceRenewalCampaignItem__c PRCitem =  new PriceRenewalCampaignItem__c (PriceRenewalCampaign__c = PriceRenCam.id,
			TF_PriceBookEntry__c = PBE0.id,
			Status__c = 'Updated',
			ContractedPrice__c = contactPrice.id,   // New 18-12-18
			Product__c = prodId,
			TF_CurrentPrice__c = 1
			);
		insert PRCitem;
		// Not all done.
		System.assertEquals(false,  PriceRenewalCampaignUtils.allCampaignsItemsDone(Userinfo.getuserid()));
		PRCitem.Status__c = 'Processed';
		update PRCitem;
		// Now all done
		System.assertEquals(true,  PriceRenewalCampaignUtils.allCampaignsItemsDone(Userinfo.getuserid()));
		// Can close PRC?
		PriceRenewalCampaignUtils.closeCampaigns(Userinfo.getuserid()); 
		// Yes all closed
		System.assertEquals(true, PriceRenewalCampaignUtils.allCampaignsDone(Userinfo.getuserid()));

	}
	


    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Test Class for : PriceRenewalCampaignUtils.processingContractedPrice
    * History :
    * new 8-18 Wim 
    ******************************************************************************************************************************************************************/


	@isTest (seealldata=false)
	public static void processingContractedPriceTEST  (){
		// Setup Dataset
		Test.startTest();

		// Quote (line).
		SBQQ__Quote__c  quoteSingle;
			quoteSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'Id != null  LIMIT 1'));
		String quoteId  = quoteSingle.Id;
		SBQQ__QuoteLine__c  quoteLineSingle;
			quoteLineSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c = : quoteId  LIMIT 1'));
		// Contracted Price
		SBQQ__ContractedPrice__c contactPrice;
			contactPrice =  Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__ContractedPrice__c', 'Id != null  LIMIT 1'));
		contactPrice.SBQQ__OriginalQuoteLine__c = quoteLineSingle.Id;
		update contactPrice;

		// PRC (item)

		PriceRenewalCampaign__c PriceRenCam = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceRenewalCampaign__c', 'Id != null  LIMIT 1'));
		PriceRenCam.Stage__c = 'Queued';
		update PriceRenCam;
		PriceRenewalCampaignItem__c PRCitem;
	    PRCitem =  new PriceRenewalCampaignItem__c (PriceRenewalCampaign__c = PriceRenCam.id,
		ContractedPrice__c = contactPrice.Id,
		PriceIncrease__c = 10,
		Account__c  = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Account', 'Name = \'cust\' LIMIT 1')).Id,
		Product__c = Database.Query(IMCDUtils.getCreatableFieldsSOQL('Product2', 'Id != null   LIMIT 1')).Id,
		Quantity__c = 1,
		Status__c = 'Review',
		TF_CurrentPrice__c = 10
		);

		insert PRCitem;
		Test.stopTest();
		// Dataset ok, run procedure to create Renewal-Quote from a Contracted price

		PriceRenewalCampaignUtils.processingContractedPrice(Userinfo.getuserid());

		// Should now have created a new Quote(line)
		List<SBQQ__Quote__c> quotes;
			quotes = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'QuoteType__c = \'Renewal\' '));
		System.assertEquals(1,  quotes.size());
		quoteId = quotes[0].Id;

			for (SBQQ__QuoteLine__c ql : Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c = : quoteId  '))){
				system.debug('------ ql'+ql);
				System.assertEquals(11, ql.PricePerUOM__c);
				return;
			}
		System.assert(false, 'Did not create Renewal quote(line)');

	}
	

	@isTest (seealldata=false)
	public static void startSchedulderTEST  (){
		// Start normal scheduler.
		Test.startTest();
		PriceRenewalCampaignUtils.startSchedulder(Userinfo.getuserid(), Date.today(), 'day');
		Test.stopTest();
		// Start again, schould not make a difference
		PriceRenewalCampaignUtils.startSchedulder(Userinfo.getuserid(), Date.today().addDays(1), 'day');
		String theName = 'RPRC_day_'+ Userinfo.getuserid();
		// Check for an entry in scheduler
		for (CronJobDetail ctd : [SELECT Id, Name, JobType FROM CronJobDetail WHERE Name Like : theName ]){
			String cronName= ctd.Name;
			System.assertEquals(cronName, theName) ;
			return;
			system.debug('------ cronName '+ cronName);
		}
		// Scheduler not created
		System.assert(true, 'No Crontab created');

	}
	


	@isTest (seealldata=false)
	public static void futureProcessingTEST  (){

		Test.startTest();
		PriceRenewalCampaign__c priceRenCam  = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceRenewalCampaign__c', 'id != null LIMIT 1'));
		PriceBookEntry PBE0 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceBookEntry', 'Id != null  LIMIT 1'));
		PBE0.UnitPrice = 10;
		PBE0.BasePrice__c = true;
		update PBE0;
		PriceRenewalCampaignItem__c item = new PriceRenewalCampaignItem__c(
			TF_PriceBookEntry__c = PBE0.id,
			PriceRenewalCampaign__c = priceRenCam.id,
			TF_CurrentPrice__c = PBE0.UnitPrice,
			PriceIncrease__c = 10
			);
		insert item;

		priceRenCam.Stage__c = 'Queued' ;
		update priceRenCam;
		PriceRenewalCampaignUtils.futureProcessing(Userinfo.getUserid());
		Test.stopTest();

		for (PriceHistory__c hist:[SELECT NewValue__c, OldValue__c FROM PriceHistory__c]){
			System.assertEquals(10, hist.OldValue__c);
			System.assertEquals(11, hist.NewValue__c);
			system.debug('------ hist '+ hist);
			return;
		}
		System.assert(false, 'No history record created');
	}
	

	@isTest (seealldata=false)
	public static void createContractedPricesTEST  (){	
		Test.startTest();	
		// Have Single Quote;
		SBQQ__Quote__c  quoteSingle;
			quoteSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
		String quoteId = quoteSingle.Id;
		SBQQ__QuoteLine__c  quoteLineSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'SBQQ__Quote__c = :quoteId  LIMIT 1'));

		quoteLineSingle.SetContracted__c = false;
		quoteLineSingle.PricePerUOM__c  = 10;
		quoteLineSingle.PriceValidityStart__c = Date.today().addDays(-5);
		quoteLineSingle.PriceValidityEnd__c =  Date.today().addDays(10);
		update quoteLineSingle;
		String quoteLineSingleId = quoteLineSingle.Id;
		// Set ready for create Contracted price
		quoteSingle.SBQQ__Status__c = 'Presented';
		update quoteSingle;
		Test.stopTest();

		// Do it

		PriceRenewalCampaignUtils.createContractedPrices(new List<id>{quoteSingle.id});

		quoteLineSingle.PriceValidityStart__c = Date.today().addDays(-20);
		quoteLineSingle.PriceValidityEnd__c =  Date.today().addDays(101);
		update quoteLineSingle;
		PriceRenewalCampaignUtils.createContractedPrices(new List<id>{quoteSingle.id});


		for (SBQQ__ContractedPrice__c cp: Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__ContractedPrice__c', 'SBQQ__OriginalQuoteLine__c = : quoteLineSingleId '))){
			system.debug('------ cp '+ cp);
			System.assertEquals(10, CP.SBQQ__Price__c);
			TestDataFactoryUtils.runTriggers(true);
			try {
				delete quoteLineSingle;
			} catch (Exception e){
				system.AssertEquals(e.getMessage().contains('Delete not possible') , true);	
				
			}
			try {
				delete quoteSingle;
			} catch (Exception e){
		//		system.AssertEquals(e.getMessage().contains('Delete not possible') , true);	// TODO
				
			}
			return;
		}
		System.assert(false, 'No Contacted Price created'); 
	}


	@isTest (seealldata=false)
	public static void beforeUpdateActionWrongUserTEST  (){	
	//	Test.startTest();	
		TestDataFactoryUtils.runTriggers(true);

		// Have PRC;
		PriceRenewalCampaign__c PriceRenCam = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceRenewalCampaign__c', 'Id != null  LIMIT 1'));
		List<User> testUsers    = TestDataFactory.createUsers(2, 'System Administrator', '21100');
		PriceRenCam.OwnerId = testUsers[1].Id;
		PriceRenCam.Stage__c = 'Review';
		update PriceRenCam;
		try {
			PriceRenCam.Stage__c = 'Ready';
			update PriceRenCam;
		} catch (Exception e){
			Boolean expectedExceptionThrown =  (e.getMessage().contains('Only owner can start') ? true : false);
			system.AssertEquals(expectedExceptionThrown, true);	
			return;		
		}
		system.Assert(true , 'Owner test not performed');	

	}

	@isTest (seealldata=false)
	public static void doubeNewProductCheck  (){	
		TestDataFactoryUtils.runTriggers(true);

        SBQQ__Quote__c  quoteSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
        List<SBQQ__QuoteLine__c>  quoteLineSingle = new List<SBQQ__QuoteLine__c> ();
        quoteLineSingle.add(Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'id != null LIMIT 1')));
        quoteLineSingle[0].id = null;
        quoteLineSingle.add(quoteLineSingle[0]);

		try {
		
			upsert  quoteLineSingle;
		} catch (Exception e){
			Boolean expectedExceptionThrown =  (e.getMessage().contains('Before Insert or Upsert list must not have two identically equal elements') ? true : false);
			system.AssertEquals(expectedExceptionThrown, true);	
			return;		
		}
		system.Assert(true , 'Double new product not detected');	

	}

    

	/*
	@isTest (seealldata=false)
	public static void doubeProductCheck  (){	
		TestDataFactoryUtils.runTriggers(true);

        SBQQ__Quote__c  quoteSingle = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
        SBQQ__QuoteLine__c  quoteLineSingle1 = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__QuoteLine__c', 'id != null LIMIT 1'));
        update quoteLineSingle1;
        SBQQ__QuoteLine__c  quoteLineSingle2 =  quoteLineSingle1;
        quoteLineSingle2.id = null;

		try {
		
			insert quoteLineSingle2;
		} catch (Exception e){
			Boolean expectedExceptionThrown =  (e.getMessage().contains('Cannot use Test Product, product already exists in Quote') ? true : false);
			system.AssertEquals(expectedExceptionThrown, true);	
			return;		
		}
		system.Assert(true , 'Double product not detected');	

	}
	*/


	@isTest (seealldata=false)
	public static void CPQcreateDocument(){   // There are no system.assert posible, as both (generating doc and sending document) does not provide any outcome
			TestDataFactoryUtils.runTriggers(false);
			SBQQ__Quote__c  testQuote = Database.Query(IMCDUtils.getCreatableFieldsSOQL('SBQQ__Quote__c', 'id != null LIMIT 1'));
			testQuote.QuoteType__c = 'Renewal';

			PriceRenewalCampaign__c PriceRenCam  = Database.Query(IMCDUtils.getCreatableFieldsSOQL('PriceRenewalCampaign__c', 'id != null LIMIT 1'));
			testQuote.PriceRenewalCampaign__c = PriceRenCam.id;
	
			EmailTemplate emailTemplate = [SELECT id FROM EmailTemplate LIMIT 1];
			testQuote.SBQQ__EmailTemplateId__c = emailTemplate.id;
	
			update testQuote;

			TestDataFactoryUtils.runTriggers(true);

			testQuote.SBQQ__Status__c = 'Confirmed';
//			try {
				update testQuote;	
//			}	catch (Exception E){
//				system.debug('------ Exception '+ E.getCause());
//			}	


			Id FolderId;
			for (Folder folder:[SELECT id FROM Folder WHERE Type = 'Document' AND IsReadonly = false]){
				FolderId = folder.id;
			}
			Document doc = new Document(
				Name = 'test',
				FolderId = FolderId,
				Body = Blob.valueof('abc'));
			insert Doc;

			SBQQ__QuoteDocument__c qDoc = new SBQQ__QuoteDocument__c(
				SBQQ__Quote__c = testQuote.id,
				SBQQ__Documentid__c = Doc.id
				);
			insert qDoc;  // error: SendEmail failed. First exception on row 0; first error: NO_MASS_MAIL_PERMISSION, Single email is not enabled for your organization or profile.

	}	


}