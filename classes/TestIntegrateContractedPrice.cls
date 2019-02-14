/*------------------------------------------------------------  
Author:        Jeroen Burgers   
Company:       Salesforce   
User Story:    https://imcdgroup.atlassian.net/browse/SFDP-610
History 
    05/11/2018     Created class
    14/09/2018     Updated, bulkified test method and tidied-up
------------------------------------------------------------*/  
@isTest
private class TestIntegrateContractedPrice {

    @testsetup
    public static void testsetup() {
        // disable process builders and triggers
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactoryUtils.runProcessBuilders(false);
        List<User> lstUsers = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '21100');
        List<Account> lstAccount = TestDataFactory.createAccounts(1, 'Customer_Sold_To', lstUsers[0].Id, '21100');
        List<Account> lstPrincipal0 = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, lstUsers[0].Id, '62100');
        List<Account> lstPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, lstUsers[0].Id, '21100');
        List<Product2> lstProduct = TestDataFactory.createProducts(1, lstPrincipal[0].Id);
        List<SBQQ__ContractedPrice__c> lstPrice = TestDataFactory.createContractedPrices(1, lstAccount[0], lstProduct); // total numrecordss * listproduct.size()

    }
    
    @isTest
    static void testDataSetup () {
        //System.assertEquals([SELECT ImcdCompany__c FROM Account LIMIT 1].ImcdCompany__c, '21100', 'IMCD Company does not match, should be updated by PB after saving account');
        System.assertEquals([SELECT Id FROM SBQQ__ContractedPrice__c].size(), 1, 'TestSetup issue, no SBQQ__ContractedPrice__c records created');
    }
    
    @isTest
    static void testIntegrationLogsDmlInsertException () {
        // This test should fail, because the IntegrationSettings__c custom setting is not present. 
        List <IntegrateContractedPrice.IntegrateContractedPriceRequest> lstRequest = new List <IntegrateContractedPrice.IntegrateContractedPriceRequest>();
        IntegrateContractedPrice.IntegrateContractedPriceRequest request = new IntegrateContractedPrice.IntegrateContractedPriceRequest();
        request.productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        lstRequest.add(request);
        IntegrateContractedPrice.IntegrateContractedPrices(lstRequest);
        System.assertEquals(1, [SELECT Id FROM DebugLog__c].size(), 'Test should fail, exception not logged in DebugLog__c');
        System.assertEquals(0, [SELECT Id FROM IntegrationLog__c].size(), 'Test should fail, no errors expected in SBQQ__ContractedPrice__c');
    }
    
    
    @isTest
    static void testIntegrationLogsBulkification () {
        TestDataFactory.createIntegrationSettings(); // create prereq custom settings 
        List <IntegrateContractedPrice.IntegrateContractedPriceRequest> lstRequest = new List <IntegrateContractedPrice.IntegrateContractedPriceRequest>();
        RecordType rtPrincipal = IMCDUtils.getRecordType('Account', Label.Global_Principa_Account_Recordtype);
        List<Product2> lstProduct = TestDataFactory.createProducts(200, [SELECT Id FROM Account WHERE RecordTypeId = :rtPrincipal.Id AND IMCDCompany__c = '62100' LIMIT 1].Id);
        RecordType rtAccount = IMCDUtils.getRecordType('Account', 'Customer_Sold_To'); 
        List<SBQQ__ContractedPrice__c> lstPrice = TestDataFactory.createContractedPrices(10, [SELECT Id FROM Account WHERE RecordTypeId =: rtAccount.Id], lstProduct); // total numrecordss * listproduct.size()
       
        // Add same for all 200 products to verify bulkification
        for (Product2 product : [SELECT Id FROM Product2]) {
            IntegrateContractedPrice.IntegrateContractedPriceRequest request = new IntegrateContractedPrice.IntegrateContractedPriceRequest();
            request.productId = product.Id;
            lstRequest.add(request);            
        }
        Test.startTest(); // start test
        IntegrateContractedPrice.IntegrateContractedPrices(lstRequest);
        Test.stopTest(); // stop test
        System.assertEquals(0, [SELECT Id FROM DebugLog__c].size(), 'Test should succeed, no exception expected in DebugLog__c');
        System.assertEquals(2001, [SELECT Id FROM IntegrationLog__c].size(), 'Test should succeed, 2001 records are expected in SBQQ__ContractedPrice__c');
    }
    
    @isTest
    static void testIntegrationLogs () {
        TestDataFactory.createIntegrationSettings(); // create prereq custom settings
        List <IntegrateContractedPrice.IntegrateContractedPriceRequest> lstRequest = new List <IntegrateContractedPrice.IntegrateContractedPriceRequest>();
        IntegrateContractedPrice.IntegrateContractedPriceRequest request = new IntegrateContractedPrice.IntegrateContractedPriceRequest();
        request.productId = [SELECT Id FROM Product2 LIMIT 1].Id;
        lstRequest.add(request);
        IntegrateContractedPrice.IntegrateContractedPrices(lstRequest);
        System.assertEquals(0, [SELECT Id FROM DebugLog__c].size(), 'Test should succeed, no exception expected in DebugLog__c');
        System.assertEquals(1, [SELECT Id FROM IntegrationLog__c].size(), 'Test should succeed, 1 record is expected in SBQQ__ContractedPrice__c');
    }
}