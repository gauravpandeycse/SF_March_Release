/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
User Story:	   https://imcdgroup.atlassian.net/browse/SFDP-109
History	
	06/06/2018	   Created test class, 100% test coverage.
------------------------------------------------------------*/	
@isTest
private class TestTempProductPrice {

	@testsetup
    public static void testsetup() {
		// disable process builders and triggers
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactoryUtils.runProcessBuilders(false);
        List<User> lstUsers = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '21100');
        List<Account> lstPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, lstUsers[0].Id, '21100');
		List<Product2> lstProduct = TestDataFactory.createProducts(2, lstPrincipal[0].Id, '02.Temp Pre Sales', 'TempProduct');
        TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstProduct[0].Id);
		TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstProduct[1].Id);
        TestDataFactory.createDefaultPricebooks();
	}
    
	@isTest
    static void testDataSetup () {
        System.assertEquals(1, [SELECT ImcdCompany__c FROM Pricebook2 WHERE ImcdCompany__c = '21100'].size(), 'TestSetup issue, Pricebooks did not get created');
        System.assertEquals(2, [SELECT Id FROM Product2 WHERE ItemStatus__c='02.Temp Pre Sales'].size(), 'TestSetup issue, Temp product did not get created');
    }
    
	@isTest
	static void testCreateProductPriceSingle () {
		List <TempProductPrice.TempProductPriceRequest> lstRequest = new List <TempProductPrice.TempProductPriceRequest>();
 		TempProductPrice.TempProductPriceRequest request = new TempProductPrice.TempProductPriceRequest();
		List<Product2> lstProduct = [SELECT Id FROM Product2];
        request.productId = lstProduct[0].Id;
        request.imcdCompany = '21100';
		lstRequest.add(request);
        TempProductPrice.CreateTempProductPrice(lstRequest);

        System.assertEquals(1, [SELECT Id FROM PricebookEntry WHERE Pricebook2.ImcdCompany__c = '21100'].size(), 'A single PriceBookEntry record should have been created');
    }
    
	@isTest
	static void testCreateProductDmlException () {
		List <TempProductPrice.TempProductPriceRequest> lstRequest = new List <TempProductPrice.TempProductPriceRequest>();
 		TempProductPrice.TempProductPriceRequest request = new TempProductPrice.TempProductPriceRequest();
		List<Product2> lstProduct = [SELECT Id FROM Product2];
        request.productId = lstProduct[0].Id;
        request.imcdCompany = '21100';
		lstRequest.add(request);
        // remove products to cause exception
        delete [SELECT Id FROM Product2 WHERE Id =: lstProduct[0].Id];
        TempProductPrice.CreateTempProductPrice(lstRequest);

        System.assertEquals(1, [SELECT Id FROM DebugLog__c].size(), 'Test should fail, exception not logged in DebugLog__c');
    }
    
    @isTest
	static void testCreateProductPriceMulti () {
		List <TempProductPrice.TempProductPriceRequest> lstRequest = new List <TempProductPrice.TempProductPriceRequest>();
        TempProductPrice.TempProductPriceRequest request1 = new TempProductPrice.TempProductPriceRequest();
		TempProductPrice.TempProductPriceRequest request2 = new TempProductPrice.TempProductPriceRequest();
		List<Product2> lstProduct = [SELECT Id FROM Product2];     
		request1.productId = lstProduct[0].Id;
        request1.imcdCompany = '21100';
		lstRequest.add(request1);
        request2.productId = lstProduct[1].Id;
        request2.imcdCompany = '21100';
		lstRequest.add(request2);
        TempProductPrice.CreateTempProductPrice(lstRequest);
		System.assertEquals(2, [SELECT Id FROM PricebookEntry WHERE Pricebook2.ImcdCompany__c = '21100'].size(), 'Two PriceBookEntry records should have been created');
    }
}