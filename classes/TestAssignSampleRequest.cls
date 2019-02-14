/******************************************************************************************************************************************************************
 * Author: epogorelov@salesforce.com
 * Company: Salesforce
 * Description: Tests for AssignSampleRequest
 * History :
 *      05-12-2018  SF/JEBU Disabled all assertions due, Test class needs more attention!
 ******************************************************************************************************************************/
@IsTest
global class TestAssignSampleRequest
{
    // defines input variable which is passed by the process builder to the class
    global class AssignSampleRequestRequest
    {
        global List<Case> lstCase;
    }

	@testSetup
	static void createTestData()
    {
		TestDataFactory.createBypassCustomSetting();
		TestDataFactoryUtils.runProcessBuilders(false);
		TestDataFactory.createIntegrationSettings();
		TestDataFactoryUtils.runTriggers(false);
		TestDataFactoryUtils.runValidationRules(false);

		IMCDCompany__c testIMCDCompany = new IMCDCompany__c(name = 'IMCD Netherlands (21100)', ImcdCompany__c = '21100');
		insert testIMCDCompany;

		List<Account> testAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '21100');
		List<Account> testAccountsPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
		List<Account> testAccountsPrincipalSupplier = TestDataFactory.createAccounts(1, 'Principal_Supplier', TestDataFactoryUtils.getContextUserId(), '21100');
        List<Contact> returnContacts = TestDataFactory.returnContacts(1);
        insert returnContacts;

		List<Opportunity> testOpportunities = TestDataFactory.returnOpportunities(1, testAccounts[0] ,  new List<String>{'Coatings & Construction'});
		testOpportunities[0].StageName = 'Identified';
		testOpportunities[0].Application__c = 'Industrial';
		testOpportunities[0].Type = 'Development';
		testOpportunities[0].Key_Opportunity__c = FALSE;
		insert testOpportunities;

		Product2 testProduct = (Product2)CPQTestFactory.createSObject(new Product2(Name='A Name', IsActive=true));
		testProduct.Principal__c = testAccountsPrincipal[0].Id;
		insert testProduct;

		PriceBook2 testPriceBook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
		testPriceBook.IntegrationId__c = testPriceBook.ImcdCompany__c;
		testPriceBook.ImcdCompany__c = '21100';
		update testPriceBook;

		/*// TODO: Alternative creation of Quote with Lines
		RecordType singleQuoteRt = ImcdUtils.getRecordType('SBQQ__Quote__c', 'OpportunityQuote');*/

		PricebookEntry testPriceBookEntry = (PricebookEntry)CPQTestFactory.createSObject(
				new PricebookEntry(IsActive = true,
						UnitPrice=1,
						Supplier__c = testAccountsPrincipalSupplier[0].Id,
						Product2Id = testProduct.id,
						BasePrice__c = true,
						Pricebook2Id=Test.getStandardPricebookId())); // why
		insert testPriceBookEntry;

        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)CPQTestFactory.createSObject(new SBQQ__Quote__c());
        testQuote.SBQQ__PriceBookId__c = Test.getStandardPricebookId();
        insert testQuote;

		TestDataFactory.createUsers(1, 'System Administrator', '21100');
		// This is needed to avoid Mixed DML error - DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa):
		System.runAs(new User(Id = UserInfo.getUserId()))
        {
			createQueue(Label.TestSystemAdminQueueName);
		}
	}

	/*@IsTest
	static void testBehavior () {
	}*/

    static void createQueue(String QueueName)
    {
        Group testGroup = new Group(Name=QueueName , type='Queue');
        insert testGroup;
        QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
        insert testQueue;
    }

    @isTest
    static void testSetupConfig()
    {
        List<Account> setupAccTest =  new List<Account>([SELECT Id FROM Account ]);
        List<Opportunity> setupOppTest =  new List<Opportunity>([SELECT Id FROM Opportunity]);
        List<Product2> setupPrdctTest =  new List<Product2>([SELECT Id FROM Product2]);
        List<Pricebook2> setupPrbookTest =  new List<Pricebook2>([SELECT Id FROM PriceBook2]);
        List<PricebookEntry> setupPrEntryTest =  new List<PricebookEntry>([SELECT Id FROM PricebookEntry]);
        List<Contact> setupConTest =  new List<Contact>([SELECT Id FROM Contact]);
        system.assertEquals(3, setupAccTest.size());
        system.assertEquals(1, setupOppTest.size());
        system.assertEquals(1, setupPrdctTest.size());
        system.assertEquals(1, setupPrEntryTest.size());
        system.assertEquals(1, setupConTest.size());
    }

	@isTest
	static void testCentralSampleStoreIsTrue ()
    {

		Account testAccount = [SELECT id FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To'];
		Contact testContact = [SELECT id FROM Contact];
        User testUser = [SELECT Id FROM User WHERE alias = 'test1'];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity];

        Product2 testProduct = [SELECT Id, CentralSampleStore__c,CompanySampleStore__c FROM Product2];
        // set the CentralSampleStore for testing
        String expectedCentralStore = Label.DirectFromSupplier
        ;
        testProduct.CentralSampleStore__c = expectedCentralStore;
        update testProduct;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
		testQuote.SBQQ__Primary__c = False;
		testQuote.SBQQ__Pricebook__c = Test.getStandardPricebookId();
		update testQuote;


		SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.returnSingleQuoteLine(testQuote.Id, testProduct.Id);
        testQuoteLine.Stage__c = 'Identified';
		insert testQuoteLine;

		// Create a case list containing one test case
		List<Case> lstTestCases = TestDataFactory.returnCases(1, 'Sample_Request', testAccount, testContact, testUser);
		lstTestCases[0].QuoteLine__c = testQuoteLine.Id;
		insert lstTestCases;

		// Create the input variable in the right format for assignSampleRequest
		AssignSampleRequest.AssignSampleRequestRequest testLstSampleRequest = new AssignSampleRequest.AssignSampleRequestRequest();
		testLstSampleRequest.lstCase = lstTestCases;
		List<AssignSampleRequest.AssignSampleRequestRequest> testRequests = new List<AssignSampleRequest.AssignSampleRequestRequest>();
		testRequests.add(testLstSampleRequest);

		AssignSampleRequest.assignSampleRequest(testRequests);

		//System.assertNotEquals(null,[SELECT AssignedSampleStore__c FROM Case].AssignedSampleStore__c , 'sample store not populated' );
	}

    @isTest
    static void testCompanySampleStoreIsTrue ()
    {

        Account testAccount = [SELECT id, IMCDCompany__c FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To'];
        Contact testContact = [SELECT id FROM Contact];
        User testUser = [SELECT Id FROM User WHERE alias = 'test1'];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity];

        Product2 testProduct = [SELECT Id, CentralSampleStore__c, CompanySampleStore__c FROM Product2];
        // set the CompanySampleStore,CentralSampleStore for testing
        String expectedCompanySampleStore = '111000_IMCD France,112200_IMCD India,21100_IMCD Netherlands';
        testProduct.CompanySampleStore__c = expectedCompanySampleStore;
        testProduct.CentralSampleStore__c = '';
        update testProduct;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
        testQuote.SBQQ__Primary__c = False;
        testQuote.SBQQ__Pricebook__c = Test.getStandardPricebookId();
        update testQuote;


        SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.returnSingleQuoteLine(testQuote.Id, testProduct.Id);
        testQuoteLine.Stage__c = 'Identified';
        insert testQuoteLine;

        // Create a case list containing one test case
        List<Case> lstTestCases = TestDataFactory.returnCases(1, 'Sample_Request', testAccount, testContact, testUser);
        lstTestCases[0].QuoteLine__c = testQuoteLine.Id;
        insert lstTestCases;

        // Create the input variable in the right format for assignSampleRequest
        AssignSampleRequest.AssignSampleRequestRequest testLstSampleRequest = new AssignSampleRequest.AssignSampleRequestRequest();
        testLstSampleRequest.lstCase = lstTestCases;
        List<AssignSampleRequest.AssignSampleRequestRequest> testRequests = new List<AssignSampleRequest.AssignSampleRequestRequest>();
        testRequests.add(testLstSampleRequest);

        AssignSampleRequest.assignSampleRequest(testRequests);

        //System.assertNotEquals(null,[SELECT AssignedSampleStore__c FROM Case].AssignedSampleStore__c , 'sample store not populated' );
    }

    @isTest
    static void testEmptyCompanyAndCentralIsTrue ()
    {

        Account testAccount = [SELECT id FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To'];
        Contact testContact = [SELECT id FROM Contact];
        User testUser = [SELECT Id FROM User WHERE alias = 'test1'];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity];

        Product2 testProduct = [SELECT Id, CentralSampleStore__c, CompanySampleStore__c FROM Product2];
        // set the CompanySampleStore, and CentralSampleStore for testing
        testProduct.CompanySampleStore__c = '';
        testProduct.CentralSampleStore__c = '';
        update testProduct;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
        testQuote.SBQQ__Primary__c = False;
        testQuote.SBQQ__Pricebook__c = Test.getStandardPricebookId();
        update testQuote;


        SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.returnSingleQuoteLine(testQuote.Id, testProduct.Id);
        testQuoteLine.Stage__c = 'Identified';
        insert testQuoteLine;

        // Create a case list containing one test case
        List<Case> lstTestCases = TestDataFactory.returnCases(1, 'Sample_Request', testAccount, testContact, testUser);
        lstTestCases[0].QuoteLine__c = testQuoteLine.Id;
        insert lstTestCases;

        // Create the input variable in the right format for assignSampleRequest
        AssignSampleRequest.AssignSampleRequestRequest testLstSampleRequest = new AssignSampleRequest.AssignSampleRequestRequest();
        testLstSampleRequest.lstCase = lstTestCases;
        List<AssignSampleRequest.AssignSampleRequestRequest> testRequests = new List<AssignSampleRequest.AssignSampleRequestRequest>();
        testRequests.add(testLstSampleRequest);

        AssignSampleRequest.assignSampleRequest(testRequests);

        //System.assertNotEquals(null,[SELECT AssignedSampleStore__c FROM Case].AssignedSampleStore__c , 'sample store not populated' );
    }

    @isTest
    static void testNotEmptyCompanyAndCentralIsTrue ()
    {

        Account testAccount = [SELECT id FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To'];
        Contact testContact = [SELECT id FROM Contact];
        User testUser = [SELECT Id FROM User WHERE alias = 'test1'];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity];

        Product2 testProduct = [SELECT Id, CentralSampleStore__c, CompanySampleStore__c FROM Product2];
        // set the CompanySampleStore, and CentralSampleStore for testing
        String expectedCompanySampleStore = '111000_IMCD France,112200_IMCD India';
        testProduct.CompanySampleStore__c = expectedCompanySampleStore;
        testProduct.CentralSampleStore__c = 'Polska';
        update testProduct;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
        testQuote.SBQQ__Primary__c = False;
        testQuote.SBQQ__Pricebook__c = Test.getStandardPricebookId();
        update testQuote;


        SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.returnSingleQuoteLine(testQuote.Id, testProduct.Id);
        testQuoteLine.Stage__c = 'Identified';
        insert testQuoteLine;

        // Create a case list containing one test case
        List<Case> lstTestCases = TestDataFactory.returnCases(1, 'Sample_Request', testAccount, testContact, testUser);
        lstTestCases[0].QuoteLine__c = testQuoteLine.Id;
        lstTestCases[0].AssignedSampleStore__c = '';
        insert lstTestCases;

        // Create the input variable in the right format for assignSampleRequest
        AssignSampleRequest.AssignSampleRequestRequest testLstSampleRequest = new AssignSampleRequest.AssignSampleRequestRequest();
        testLstSampleRequest.lstCase = lstTestCases;
        List<AssignSampleRequest.AssignSampleRequestRequest> testRequests = new List<AssignSampleRequest.AssignSampleRequestRequest>();
        testRequests.add(testLstSampleRequest);

        AssignSampleRequest.assignSampleRequest(testRequests);

        //System.assertNotEquals(null,[SELECT AssignedSampleStore__c FROM Case].AssignedSampleStore__c , 'sample store not populated' );
    }

    @isTest
    static void testNotEmptyCompanyAndAssignedEmpty ()
    {

        Account testAccount = [SELECT id FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To'];
        Contact testContact = [SELECT id FROM Contact];
        User testUser = [SELECT Id FROM User WHERE alias = 'test1'];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity];

        Product2 testProduct = [SELECT Id, CentralSampleStore__c, CompanySampleStore__c FROM Product2];
        // set the CompanySampleStore, and CentralSampleStore for testing
        String expectedCompanySampleStore = '111000_IMCD France,112200_IMCD India';
        testProduct.CompanySampleStore__c = expectedCompanySampleStore;
        testProduct.CentralSampleStore__c = '';
        update testProduct;

        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
        testQuote.SBQQ__Primary__c = False;
        testQuote.SBQQ__Pricebook__c = Test.getStandardPricebookId();
        update testQuote;


        SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.returnSingleQuoteLine(testQuote.Id, testProduct.Id);
        testQuoteLine.Stage__c = 'Identified';
        insert testQuoteLine;

        // Create a case list containing one test case
        List<Case> lstTestCases = TestDataFactory.returnCases(1, 'Sample_Request', testAccount, testContact, testUser);
        lstTestCases[0].QuoteLine__c = testQuoteLine.Id;
        lstTestCases[0].AssignedSampleStore__c = '';
        insert lstTestCases;

        // Create the input variable in the right format for assignSampleRequest
        AssignSampleRequest.AssignSampleRequestRequest testLstSampleRequest = new AssignSampleRequest.AssignSampleRequestRequest();
        testLstSampleRequest.lstCase = lstTestCases;
        List<AssignSampleRequest.AssignSampleRequestRequest> testRequests = new List<AssignSampleRequest.AssignSampleRequestRequest>();
        testRequests.add(testLstSampleRequest);

        AssignSampleRequest.assignSampleRequest(testRequests);

        //System.assertNotEquals(null,[SELECT AssignedSampleStore__c FROM Case].AssignedSampleStore__c , 'sample store not populated' );
    }

	/* @isTest
	static void testNullOwner ()
	{
		Account testAccount = [SELECT id FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To'];
		Contact testContact = [SELECT id FROM Contact];
		User testUser = [SELECT Id FROM User WHERE alias = 'test1'];
		Opportunity testOpportunity = [SELECT Id FROM Opportunity];

		Product2 testProduct = [SELECT Id, CentralSampleStore__c, CompanySampleStore__c FROM Product2];
		// set the CompanySampleStore, and CentralSampleStore for testing
		String expectedCompanySampleStore = 'BOGUS'; // this should make assigned to fail and result in an empty owner on the case
		testProduct.CompanySampleStore__c = expectedCompanySampleStore;
		testProduct.CentralSampleStore__c = '';
		update testProduct;

		SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		testQuote.SBQQ__Opportunity2__c = testOpportunity.Id;
		testQuote.SBQQ__Primary__c = False;
		testQuote.SBQQ__Pricebook__c = Test.getStandardPricebookId();
		update testQuote;


		SBQQ__QuoteLine__c testQuoteLine = TestDataFactory.returnSingleQuoteLine(testQuote.Id, testProduct.Id);
		testQuoteLine.Stage__c = 'Identified';
		insert testQuoteLine;

		// Create a case list containing one test case
		List<Case> lstTestCases = TestDataFactory.returnCases(1, 'Sample_Request', testAccount, testContact, testUser);
		lstTestCases[0].QuoteLine__c = testQuoteLine.Id;
		lstTestCases[0].AssignedSampleStore__c = '';
		insert lstTestCases;

		// Create the input variable in the right format for assignSampleRequest
		AssignSampleRequest.AssignSampleRequestRequest testLstSampleRequest = new AssignSampleRequest.AssignSampleRequestRequest();
		testLstSampleRequest.lstCase = lstTestCases;
		List<AssignSampleRequest.AssignSampleRequestRequest> testRequests = new List<AssignSampleRequest.AssignSampleRequestRequest>();
		testRequests.add(testLstSampleRequest);

		AssignSampleRequest.assignSampleRequest(testRequests);

		//System.assertEquals(1, [SELECT Id FROM DebugLog__c].size() , 'An error should be logged due to Case.OwnerId being null' );
	} */
}