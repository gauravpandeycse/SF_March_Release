/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Test class for CloneQuoteCompController 
History	
	02/08/2018	   JEBU/SF: Created class
	04/10/2018     JEBU/SF: Updated testClone method to use RunAs
------------------------------------------------------------*/	
@isTest
private class TestCloneQuoteCompController {

    @testSetup
    static void setup() {
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '21100');
        SBQQ.TriggerControl.disable(); // disable CPQ package triggers
        TestDataFactoryUtils.runProcessBuilders(false);
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactory.createRecordTypeIds(); // pre-req for process builder which references record type ids from custom setting
		List<Account> lstPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, users[0].Id, '21100');
        List<Account> testSoldToAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, users[0].Id, '21100');
        List<Product2> lstTempProd = TestDataFactory.createProducts(1, lstPrincipal[0].Id, '02.Temp Pre Sales', 'TempProduct');
        List<Product2> lstProd = TestDataFactory.createProducts(1, lstPrincipal[0].Id, '03.Active Pre Sales', 'Product');
        List<Account> lstSoldto = [SELECT Id, Primary_LOB1__c FROM Account Where RecordType.DeveloperName = :Label.Customer_Sold_To_Account_Record_Type];
		TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstTempProd[0].Id);
        TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstProd[0].Id);
        List<Opportunity> lstOppty = TestDataFactory.returnOpportunities(1, lstSoldTo[0], new List<String>{'Coatings & Construction'});    
        TestDataFactoryUtils.runProcessBuilders(true); // enable process builder to create 'Opportunity Quote' while inserting oppty
        lstOppty[0].StageName = Label.IMCD_OPPTY_CLOSING_STAGE;
        insert lstOppty;
		TestDataFactoryUtils.runProcessBuilders(false); // disable process builder again
        List<SBQQ__Quote__c> lstQuote = [SELECT Id, RecordType.DeveloperName, SBQQ__Opportunity2__c FROM SBQQ__Quote__c];
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>();
        lstQUoteLine.addAll(TestDataFactory.returnQuoteLine(1, lstQuote[0].Id, lstProd[0].Id));
        lstQuoteLine[0].Stage__c = Label.IMCD_OPPTY_WON_STAGE; // set product item to 'Won' 
        insert lstQuoteLine;
    }

    @isTest
    static void testDataSetup() {
        System.assert([SELECT Id FROM Opportunity].size() == 1, 'A Single Opportunity should have been created in testSetup');
        System.assert([SELECT Id FROM SBQQ__Quote__c].size() == 1, 'A Single Opportunity Quote should have been created in testSetup');
        System.assert([SELECT Id FROM SBQQ__QuoteLine__c].size() == 1, 'A Single Quote line should have been created in testSetup');
    }

    @isTest
    static void testGetNumQuotes() {
        System.assert(CloneQuoteCompController.getNumQuotes([SELECT Id FROM SBQQ__Quote__c].Id) == 1 , 'There should be a single Quote under the Opportunity Quotes parent opportunity.');
    }
    
    @isTest
    static void testcloneQuoteExceptions() {
        String expirationDt = String.valueOf(date.today());
        String validityToDt = String.valueOf(date.today());
        String validityFromDt = String.valueOf(date.today());
        String incoTerms = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'IncoTerms2__c');
        Boolean cloneLines = true;
        ID quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
        CloneQuoteCompController.cloneQuote(null, expirationDt, validityToDt, validityFromDt, incoTerms, cloneLines);
        System.assert([SELECT Id FROM DebugLog__c].size() == 3, 'Without providing QuoteId, three DebugLog__c entries are expected.');
    }

    @isTest
    static void testcloneQuote() {
        String expirationDt = String.valueOf(date.today());
        String validityToDt = String.valueOf(date.today());
        String validityFromDt = String.valueOf(date.today());
        String incoTerms = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__Quote__c(), 'IncoTerms2__c');
        Boolean cloneLines = true;

        ID quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
        ID clonedQuoteId = CloneQuoteCompController.cloneQuote(quoteId, expirationDt, validityFromDt, validityToDt, incoTerms, cloneLines);
        System.assert(!String.isEmpty(clonedQuoteId), 'QuoteId should be returned upon succesfull clone. Error = ' + [SELECT Message__c FROM DebugLog__c]);
    }
}