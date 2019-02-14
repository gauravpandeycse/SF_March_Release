/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for AccountLobTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
@IsTest
public with sharing class TestOpportunityTriggerHelper {
    @testSetup static void setup() {
        /*Creating 2 distinct random IMCD company values */
        String imcdCompanyTestValue = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        String imcdCompanyTestValue2;
        do {
            imcdCompanyTestValue2 = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        } while (imcdCompanyTestValue2.equals(imcdCompanyTestValue));

        TestDataFactory.createImcdCompanies(new List<String>{imcdCompanyTestValue,imcdCompanyTestValue2});

        /*Creating 3 distinct random LOB1 values*/
        Set<String> lob1FieldNameTestValuesSet = new Set<String>();
        do {
            String temp = TestDataFactoryUtils.getRandomPickListValue(new AccountLob__c(), Label.LOB1_Field_Name);

            if (!lob1FieldNameTestValuesSet.contains(temp)) {
                lob1FieldNameTestValuesSet.add(temp);
            }
        } while (lob1FieldNameTestValuesSet.size() != 5);

        Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();
        TestDataFactory.createRecordTypeIds();

        /*Creating 4 Sold To and 4 related C2 Accounts for creating Account Shares testing*/
        List<Account> testSoldToAccounts = TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);
        testSoldToAccounts.addAll(TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue2));
        List<Account> testC2Accounts = TestDataFactory.createAccounts(4, Label.Regional_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);

        List<User> testUsers2Insert = new List<User>();
        List<SharingAccess__c> testSharingAccessToInsert = new List<SharingAccess__c>();

        for (Integer i = 0; i < testSoldToAccounts.size(); i++) {
            testSoldToAccounts[i].ParentId = testC2Accounts[i].Id;
        }
        update testSoldToAccounts;

        /*Creating 10 Users each 2 with different Profile*/
        List<User> testUserList1 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
        List<User> testUserList2 = TestDataFactory.returnUsers(2, Label.Contract_Manager_Profile_Name, imcdCompanyTestValue);
        List<User> testUserList3 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, imcdCompanyTestValue);
        List<User> testUserList4 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
        List<User> testUserList5 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, imcdCompanyTestValue);
        List<User> uListForUpdOppTest = TestDataFactory.returnUsers(2,Label.Standard_User_Profile_Name, TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name));


        testUsers2Insert.addAll(testUserList1);
        testUsers2Insert.addAll(testUserList2);
        testUsers2Insert.addAll(testUserList3);
        testUsers2Insert.addAll(testUserList4);
        testUsers2Insert.addAll(testUserList5);
        testUsers2Insert.addAll(uListForUpdOppTest);
        insert testUsers2Insert;

        /*Creating 10 SharingAccess records each 2 related to one of the random LOB1 values and Users*/
        List<String> lob1FieldNameTestValuesList = new List<String>(lob1FieldNameTestValuesSet);
        //List<SharingAccess__c> testGlobalSharList = TestDataFactory.getSharingAccessList(testUserList1, '', lob1FieldNameTestValuesList[0], true);
        //List<SharingAccess__c> testGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList4, '', lob1FieldNameTestValuesList[1], true);
        List<SharingAccess__c> testNonGlobalSharList1 = TestDataFactory.getSharingAccessList(testUserList2, imcdCompanyTestValue, lob1FieldNameTestValuesList[2], false);
        List<SharingAccess__c> testNonGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue2, lob1FieldNameTestValuesList[4], false);
        List<SharingAccess__c> testNonGlobalSharList3 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue, lob1FieldNameTestValuesList[3], false);
        List<SharingAccess__c> testNonGlobalSharList4 = TestDataFactory.getSharingAccessList(testUserList5, imcdCompanyTestValue2, lob1FieldNameTestValuesList[2], false);

        //testSharingAccessToInsert.addAll(testGlobalSharList);
        //testSharingAccessToInsert.addAll(testGlobalSharList2);
        testSharingAccessToInsert.addAll(testNonGlobalSharList1);
        testSharingAccessToInsert.addAll(testNonGlobalSharList2);
        testSharingAccessToInsert.addAll(testNonGlobalSharList3);
        testSharingAccessToInsert.addAll(testNonGlobalSharList4);

        Test.startTest();
            insert testSharingAccessToInsert ;
        Test.stopTest();
        
        
        
    }
    
	/******************************************************************************************************************************************************************
     * Author: Jeroen Burgers
     * Company: Salesforce
     * Description: Test for OpportunityTriggerHelper.validateStageTransition
     * History :
     * 		31/07/2018 - Created
     *      30/11/2018 - SFDP-1720 Added extra Customer quote
     ******************************************************************************************************************************************************************/
    @isTest
    public static void testValidateStageTransition () {      
		TestDataFactoryUtils.runProcessBuilders(false);
		List<Account> lstPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
        List<Product2> lstTempProd = TestDataFactory.createProducts(1, lstPrincipal[0].Id, '02.Temp Pre Sales', 'TempProduct');
        List<Account> lstSoldto = [SELECT Id, Primary_LOB1__c FROM Account Where RecordType.DeveloperName = :Label.Customer_Sold_To_Account_Record_Type];
		TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstTempProd[0].Id);
        List<Opportunity> lstOppty = TestDataFactory.returnOpportunities(1, lstSoldTo[0], new List<String>{'Coatings & Construction'});
        TestDataFactoryUtils.runProcessBuilders(true); // enable process builder to create quote while inserting oppty
        lstOppty[0].StageName = Label.IMCD_OPPTY_CLOSING_STAGE;
        insert lstOppty;
		TestDataFactoryUtils.runProcessBuilders(false); // disable process builder again
        List<SBQQ__Quote__c> lstQuote = [SELECT Id, RecordType.DeveloperName, SBQQ__Opportunity2__c, QuoteType__c FROM SBQQ__Quote__c];
        SBQQ__Quote__c customerQuote = lstQuote[0];  // New Nov18 WvB SFDP-1720. Clone and change QuoteType
        CustomerQuote.QuoteType__c = 'Customer';
        CustomerQuote.id = null;
        insert  customerQuote;  // End change SFDP-1720
        List<SBQQ__QuoteLine__c> lstQuoteLine = TestDataFactory.returnQuoteLine(1, lstQuote[0].Id, lstTempProd[0].Id);
        lstQuoteLine[0].Stage__c = Label.IMCD_OPPTY_WON_STAGE; // set temp product item to 'Won' 
        insert lstQuoteLine;
     
        lstOppty[0].StageName = 'Analysis'; // not allowed to move back from 'Closing' to 'Analysis'
        
        Boolean assertResult;
        
        try { 
            assertResult = false;
            update lstOppty;
        } 
        catch (Exception e) { 
			assertResult = true; 	        
        }
        
        System.assert(assertResult, 'It is not allowed to change from Closing > Analysis');
        
		lstOppty[0].StageName = Label.IMCD_OPPTY_WON_STAGE; // not allowed to move to 'Won' becase quote item has temp product
            
		try { 
            assertResult = false;
            update lstOppty;
        } 
        catch (Exception e) { 
			assertResult = true; 	
        }
            
		System.assert(assertResult, 'It is not allowed to change to Won with a Temp product on a related quote');    

        delete lstQuoteLine; // deleting the temp product
		lstOppty[0].StageName = Label.IMCD_OPPTY_WON_STAGE; // allowed to move to 'Won' because no quote item has temp product
            
		try { 
            assertResult = true;
            update lstOppty;
        } 
        catch (Exception e) { 
			assertResult = false; 	
        }
        
		System.assert(assertResult, 'Without a temp product it should be allowed to move from Closing > Won');   
        lstOppty[0].StageName = Label.IMCD_OPPTY_CLOSING_STAGE; // it is not allowed to move from 'Won' to another stage.

        try { 
            assertResult = false;
            update lstOppty;
        } 
        catch (Exception e) { 
			assertResult = true; 	
        }
        
		System.assert(assertResult, 'It is not allowed to change from Won > Closing');    
    }


    /******************************************************************************************************************************************************************
     * Author: Eli Pogorelov
     * Company: Salesforce
     * Description: Test for OpportunityTriggerHelper.OppAndAccSharingBasedLOBTest, OpportunityTriggerHelper.updateOppAndAccSharingBasedLOB
     * History :
     ******************************************************************************************************************************************************************/
    @IsTest
    public static void OpportunityAndAccountSharingTest() {
        RecordType rt = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type);
        List<Account> testAccs = new List<Account>([SELECT Id, IMCDCompany__c, ParentId, recordtypeId FROM Account Where recordTypeId = :rt.Id]);
        Map<Id, User> testUsers = new Map<Id, User>([Select Id From User Where alias = 'For_Test']);

        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Set<Id> toQueryAccountSet = new Set<Id>();
        Set<String> testLOBsFromDB = new Set<String>();
        Set<String> testLOBnotExistInDB = TestDataFactoryUtils.getPicklistValues(new AccountLob__c(), Label.LOB1_Field_Name);

        for (Account acc : testAccs) {
            toQueryAccountSet.add(acc.Id);
            toQueryAccountSet.add(acc.ParentId);
        }

        List<SharingAccess__c> saTable = SharingUtils.getSharingAccessTable(null);
        Set<String> globalSAFromDB = new Set<String>();

        for (SharingAccess__c sa : saTable) {
            if (!testLOBsFromDB.contains(sa.LOB1__c)) {
                testLOBsFromDB.add(sa.LOB1__c);
            }
            if (testLOBnotExistInDB.contains(sa.LOB1__c)) {
                testLOBnotExistInDB.remove(sa.LOB1__c);
            }
            if (sa.global__c) {
                globalSAFromDB.add(sa.LOB1__c);
            }
        }
        String nonExistentLOB = (new list<String>(testLOBnotExistInDB))[0] ;

        List<String> tempList = new List<String>();
        templist.addAll(testLOBsFromDB);


        for (Integer i = 0; i < templist.size(); i++) {
            //this test Account will be linked to Opportunities that are in the sharingAccess table and global
            if (globalSAFromDB.contains(tempList[i])) {
                oppsToInsert.addAll(TestDataFactory.returnOpportunities(1, testAccs[0], new List<String>{tempList[i]}));
            }
            // this test Account will be linked to Opportunities that are in the sharingAccess table and have the same IMCDCompany as the test account
            else {
                oppsToInsert.addAll(TestDataFactory.returnOpportunities(1, testAccs[1], new List<String>{templist[i]}));
                oppsToInsert.addAll(TestDataFactory.returnOpportunities(1, testAccs[2], new List<String>{templist[i]}));
                oppsToInsert.addAll(TestDataFactory.returnOpportunities(1, testAccs[3], new List<String>{templist[i]}));
            }
        }
        Test.startTest();
        /****************************************** testing OpportunityTriggerHelper.OppAndAccSharingBasedLOB **************************************/
        insert oppsToInsert;
        Map<String, List<SharingAccess__c>> sharingAccessByLOBGlobal = new Map<String, List<SharingAccess__c>>();
        Map<String, Map<String, List<SharingAccess__c> >> lob1toSharingAccessMap = new Map<String, Map<String, List<SharingAccess__c> >>();
        SharingUtils.mappingSharingAccessTable(saTable, lob1toSharingAccessMap, sharingAccessByLOBGlobal);
        List<Account> accsFromDBList = new List<Account>([
                SELECT Id, IMCDCompany__c, OwnerId, (SELECT Id, AccountId, UserOrGroupId, RowCause FROM Shares), (Select Id, AccountId, LOB1__c From Opportunities)
                FROM Account
                WHERE Id IN :toQueryAccountSet]);
        Integer numOfOppSharesExpected = 0;
        Set<Id> oppToQueryIds = new Set<Id>();
        for (Account acc : accsFromDBList) {
            if (!acc.Opportunities.isEmpty()) {
                for (Opportunity opp : acc.Opportunities) {
                    if (lob1toSharingAccessMap.get(opp.LOB1__c) != null && lob1toSharingAccessMap.get(opp.LOB1__c).get(acc.IMCDCompany__c) != null) {
                        numOfOppSharesExpected += lob1toSharingAccessMap.get(opp.LOB1__c).get(acc.IMCDCompany__c).size();
                        oppToQueryIds.add(opp.Id);
                    }
                    if (sharingAccessByLOBGlobal.get(opp.LOB1__c) != null) {
                        numOfOppSharesExpected += sharingAccessByLOBGlobal.get(opp.LOB1__c).size();
                        oppToQueryIds.add(opp.Id);
                    }
                }
            }
        }
        List<OpportunityShare> oppShareList = new List<OpportunityShare>([SELECT Id, RowCause, OpportunityId FROM OpportunityShare WHERE OpportunityId IN : oppToQueryIds AND RowCause =: Label.MANUAL_RAW_CAUSE]) ;

        /*The total number of opportunityShare inserted should be equal to the expected number of OpportunityShares to be
        inserted following the rules LOB1 match & (Global = true OR IMCDCompany match)*/
        //System.assertEquals(numOfOppSharesExpected, oppShareList.size() );
        /****************************************** testing OpportunityTriggerHelper.updateOppAndAccSharingBasedLOB **************************************/

        List<User> queriedUsersList = new List<User>([SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = : Label.Standard_User_Profile_Name]);

        User testUsrForUpdSharOfOpp = new User();
        testUsrForUpdSharOfOpp = queriedUsersList[0];

        User testUsrForUpdSharOfOpp2 = new User();
        testUsrForUpdSharOfOpp2 = queriedUsersList[1];

        List<User> globalUserList = new List<User>{testUsrForUpdSharOfOpp};
        List<User> imcdUserList = new List<User>{testUsrForUpdSharOfOpp2};

        List<Opportunity> testOppList = new List<Opportunity>([SELECT Id, AccountId, Account.IMCDCompany__c FROM Opportunity Where Id =: oppsToInsert[0].Id ]);
        Opportunity testOpp = new Opportunity();
        testOpp =  testOppList[0];

        List<SharingAccess__c> testNonExistSharList = TestDataFactory.getSharingAccessList(globalUserList, '', nonExistentLOB, true);
        testNonExistSharList.addAll(TestDataFactory.getSharingAccessList(imcdUserList, testOpp.Account.IMCDCompany__c, nonExistentLOB, false));

        /*Commented Due to moving this type of Sharing to Criteria Sharing 14/10/18 */
        //insert testNonExistSharList ;


        testOpp.LOB1__c = nonExistentLOB ;
        update testOpp;

        List<OpportunityShare> oppUpdShareList = new List<OpportunityShare>([SELECT Id, RowCause, UserOrGroupId, OpportunityId FROM OpportunityShare WHERE OpportunityId = :testOpp.Id AND RowCause =: Label.MANUAL_RAW_CAUSE]) ;
        Set<Id> userIdsOfOppSharesSet = new Set<Id>();
        for(OpportunityShare ops : oppUpdShareList)
        {
            if(ops.OpportunityId == testOpp.Id && (ops.UserOrGroupId == testUsrForUpdSharOfOpp.Id || ops.UserOrGroupId == testUsrForUpdSharOfOpp2.Id))
            {
                userIdsOfOppSharesSet.add(ops.UserOrGroupId);
            }
        }
        /* After inserting a test User and Sharing access record with LOB that is not one of the LOB's of the Opportunities,
         we expect changing the LOB1__c field, on one of our Opportunities to that LOB,
         will share the Opportunity with the relevant Users matched by LOB & global/IMCD*/
        //system.assertEquals(userIdsOfOppSharesSet.size(), 2);
    }
    @IsTest
    public static void test_isAccountChangedForRelatedObjects() {
    	TestDataFactoryUtils.runProcessBuilders(false);
        RecordType rt = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type);
        List<Account> testAccs = new List<Account>([SELECT Id, IMCDCompany__c, ParentId, recordtypeId FROM Account Where recordTypeId = :rt.Id]);
        System.DEBUG('Account Size : ' + testAccs.size());
        Account actualAccount = testAccs[0];
        Account changedToAcccount = testAccs[1];
        
        List<Account> testAccountsPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
        List<Opportunity> testOpportunities = TestDataFactory.returnOpportunities(1, actualAccount ,  new List<String>{'Coatings & Construction'});
        testOpportunities[0].StageName = 'Identified';
        testOpportunities[0].Application__c = 'Industrial';
        testOpportunities[0].Type = 'Development';
        testOpportunities[0].Key_Opportunity__c = FALSE; 
        insert testOpportunities;
        
        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)CPQTestFactory.createSObject(new SBQQ__Quote__c());
        testQuote.SBQQ__PriceBookId__c = Test.getStandardPricebookId();
        testQuote.SBQQ__Opportunity2__c = testOpportunities[0].Id;
        insert testQuote;
        
        Product2 testProduct = (Product2)CPQTestFactory.createSObject(new Product2(Name='A Name', IsActive=true));
        testProduct.Principal__c = testAccountsPrincipal[0].Id;
        insert testProduct;
        
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, 
                                                                    SBQQ__Product__c = testProduct.Id, 
                                                                    Stage__c = 'Identified');
        insert testQuoteLine;
        Case sampleRequest = new Case(QuoteLine__c = testQuoteLine.Id, AccountId = actualAccount.Id);
        insert sampleRequest;
        FollowUpReport__c followUpReport = new FollowUpReport__c(QuoteLine__c = testQuoteLine.Id, Account__c = actualAccount.Id);
        insert followUpReport;
        
        Test.startTest();
        	testOpportunities[0].AccountId = changedToAcccount.Id;
        	update testOpportunities[0];
        Test.stopTest();
        
        System.assertEquals(changedToAcccount.Id, [Select AccountId FROM Case WHERE ID =: sampleRequest.Id].AccountId);
        System.assertEquals(changedToAcccount.Id, [Select Account__c FROM FollowUpReport__c WHERE ID =: followUpReport.Id].Account__c  );
        System.assertEquals(changedToAcccount.Id, [Select SBQQ__Opportunity2__r.AccountId FROM SBQQ__Quote__c WHERE ID =: testQuote.Id].SBQQ__Opportunity2__r.AccountId  );
        
    }
    @IsTest
    public static void test_isAccountNotChangedForRelatedObjectsWithContractedPrice() {
    	TestDataFactoryUtils.runProcessBuilders(false);
        RecordType rt = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type);
        List<Account> testAccs = new List<Account>([SELECT Id, IMCDCompany__c, ParentId, recordtypeId FROM Account Where recordTypeId = :rt.Id]);
        System.DEBUG('Account Size : ' + testAccs.size());
        Account actualAccount = testAccs[0];
        Account changedToAcccount = testAccs[1];
        
        List<Account> testAccountsPrincipal = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
        List<Opportunity> testOpportunities = TestDataFactory.returnOpportunities(1, actualAccount ,  new List<String>{'Coatings & Construction'});
        testOpportunities[0].StageName = 'Identified';
        testOpportunities[0].Application__c = 'Industrial';
        testOpportunities[0].Type = 'Development';
        testOpportunities[0].Key_Opportunity__c = FALSE; 
        insert testOpportunities;
        
        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)CPQTestFactory.createSObject(new SBQQ__Quote__c());
        testQuote.SBQQ__PriceBookId__c = Test.getStandardPricebookId();
        testQuote.SBQQ__Opportunity2__c = testOpportunities[0].Id;
        insert testQuote;
        
        Product2 testProduct = (Product2)CPQTestFactory.createSObject(new Product2(Name='A Name', IsActive=true));
        testProduct.Principal__c = testAccountsPrincipal[0].Id;
        insert testProduct;
        
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = testQuote.Id, 
                                                                    SBQQ__Product__c = testProduct.Id, 
                                                                    Stage__c = 'Identified');
        insert testQuoteLine;
        Case sampleRequest = new Case(QuoteLine__c = testQuoteLine.Id, AccountId = actualAccount.Id);
        insert sampleRequest;
        FollowUpReport__c followUpReport = new FollowUpReport__c(QuoteLine__c = testQuoteLine.Id, Account__c = actualAccount.Id);
        insert followUpReport;
        SBQQ__ContractedPrice__c contractedPrice = new SBQQ__ContractedPrice__c(SBQQ__OriginalQuoteLine__c = testQuoteLine.Id, 
                                                                                SBQQ__Account__c = actualAccount.Id, 
                                                                                SBQQ__Discount__c = 2, 
                                                                                SBQQ__Product__c = testProduct.Id);
        insert contractedPrice;
        Test.startTest();
        try{
        	testOpportunities[0].AccountId = changedToAcccount.Id;
        	update testOpportunities[0];
        }Catch(Exception e){
            System.DEBUG(e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(actualAccount.Id, [Select AccountId FROM Case WHERE ID =: sampleRequest.Id].AccountId);
        System.assertEquals(actualAccount.Id, [Select Account__c FROM FollowUpReport__c WHERE ID =: followUpReport.Id].Account__c  );
        System.assertEquals(actualAccount.Id, [Select SBQQ__Opportunity2__r.AccountId FROM SBQQ__Quote__c WHERE ID =: testQuote.Id].SBQQ__Opportunity2__r.AccountId  );
        
    }

}