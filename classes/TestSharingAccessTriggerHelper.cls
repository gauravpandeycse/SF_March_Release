/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for SharingAccessTriggerHelper
 * History :
 *     07-DEC-2018  SF/JEBU/Added additional test method to cover SharingUtils
 *      - testGetSharingAccessTable
 ******************************************************************************************************************************************************************/

@isTest
public class TestSharingAccessTriggerHelper
{
    @testSetup static void setup()
    {
        Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();

        /*Creating distinct Lobs values to test each sharing recalculation scenario*/
        String TestLobCompanyValueAccLobInsert = 'Food';
        String TestLobCompanyValueOppsInsert = 'Lubricants';
        String TestLobCompanyValueQuoteInsert = 'Personal Care';
        String TestLobCompanyValueOppLineInsert = 'Synthesis';
        String TestLobCompanyValueQuoteLineInsert = 'Pharmaceuticals';

        /*Creating 5 Sold To matching LOB1 Accounts and 5 related C2 Accounts */
        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(6, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');

        /*distinct IMCD values to test each sharing recalculation scenario*/
        testSoldToAccounts[0].IMCDCompany__c = '79100';
        testSoldToAccounts[1].IMCDCompany__c = '71100';
        testSoldToAccounts[2].IMCDCompany__c = '76100';
        testSoldToAccounts[3].IMCDCompany__c = '45100';
        testSoldToAccounts[4].IMCDCompany__c = '66100';
        testSoldToAccounts[5].IMCDCompany__c = '21100';

        testSoldToAccounts[3].Primary_LOB1__c = TestLobCompanyValueOppLineInsert;
        testSoldToAccounts[5].Primary_LOB1__c = TestLobCompanyValueOppLineInsert;

        List<String> imcdCompaniesForTest = new List<String>{'79100', '71100', '76100', '45100', '66100','21100'};
        TestDataFactory.createImcdCompanies(imcdCompaniesForTest);

        List<Account> testC2Accounts = TestDataFactory.createAccounts(6, Label.Regional_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');

        testSoldToAccounts[0].ParentId = testC2Accounts[0].Id;
        testSoldToAccounts[1].ParentId = testC2Accounts[1].Id;
        testSoldToAccounts[2].ParentId = testC2Accounts[2].Id;
        testSoldToAccounts[3].ParentId = testC2Accounts[3].Id;
        testSoldToAccounts[4].ParentId = testC2Accounts[4].Id;
        testSoldToAccounts[5].ParentId = testC2Accounts[5].Id;

        /*Creting Region Accounts to relate to product*/
        List<Account> regionAccounts = TestDataFactory.returnAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '13100');
        List<Account> regionAccounts2 = TestDataFactory.returnAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '76100');

        List<Account> tetAccDmlList = new List<Account>();
        tetAccDmlList.addAll(testSoldToAccounts);
        tetAccDmlList.addAll(regionAccounts);
        tetAccDmlList.addAll(regionAccounts2);
        insert tetAccDmlList;

        /*Creating 2 AccountLob primary*/
        List<AccountLob__c> testAccLobList = new List<AccountLob__c>();
        testAccLobList.addAll(TestDataFactory.returnAccountLobs(1, testSoldToAccounts[0], new List<String>{TestLobCompanyValueAccLobInsert}, true));
        insert testAccLobList ;

        /*Creating Opportunity for Opp match scenario*/
        List<Opportunity> oppLst = TestDataFactory.returnOpportunities(1, testSoldToAccounts[1], new List<String>{
                TestLobCompanyValueOppsInsert
        });
        /*Creating Opportunity for OppLine match scenario*/
        List<Opportunity> oppForLineLst = TestDataFactory.returnOpportunities(1, testSoldToAccounts[3], new List<String>{
                TestLobCompanyValueOppLineInsert
        });
        /*Creating Opportunity for OppLine empty LOB match scenario*/
        List<Opportunity> oppForLineLst2 = TestDataFactory.returnOpportunities(1, testSoldToAccounts[3], new List<String>{
        });
        /*Creating Opportunity for OppLine pbentry match*/
        List<Opportunity> oppForLineLst3 = TestDataFactory.returnOpportunities(1, testSoldToAccounts[5], new List<String>{
        });

        TestDataFactory.createRecordTypeIds();
        TestDataFactory.createIntegrationSettings();
        Test.startTest();
        /*Creating Test Standard, and Custom Pricebook, pricebookEntry*/
        List<Pricebook2> defpricebooks = TestDataFactory.createDefaultPricebooks();

        Pricebook2 standardPricebook = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true,
                ImcdCompany__c = '22100'
        );
        update standardPricebook;


        Id pricebookId = defpricebooks[6].Id;

        /*Creatting product to relate to Opp/Quote LineItems*/
        Product2 prod = TestDataFactory.createProduct(regionAccounts2[0].Id, 'kjdfsfgfhs898');
        Product2 proddef = TestDataFactory.createProduct(regionAccounts[0].Id, 'jhgsreg4kjv');

        /*Creating pbentry to relate to Opp LineItems*/
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
        /*PricebookEntries for proddef,prod products*/
        PricebookEntry standardPBE = TestDataFactory.createPricebookEntry(standardPB.Id, prod.Id, 'USD');
        //PricebookEntry standardPBE = TestDataFactory.createPricebookEntry(standardPB.Id, prod.Id);
        PricebookEntry pbentry = TestDataFactory.createPricebookEntry(defpricebooks[1].Id, prod.Id);

        PricebookEntry standardPBE2 = TestDataFactory.createPricebookEntry(standardPB.Id, proddef.Id, 'USD');
        //PricebookEntry standardPBE2 = TestDataFactory.createPricebookEntry(standardPB.Id, proddef.Id);
        PricebookEntry pbentry2 = TestDataFactory.createPricebookEntry(defpricebooks[1].Id, proddef.Id);

        List<Opportunity> tempDmlList = new List<Opportunity>();
        tempDmlList.addAll(oppLst);
        tempDmlList.addAll(oppForLineLst);
        tempDmlList.addAll(oppForLineLst2);
        tempDmlList.addAll(oppForLineLst3);

        /*assigning pricebook with Opportunities, quotes will be assigned to pricebooks from the related opportunities*/
        tempDmlList[0].SBQQ__QuotePricebookId__c = pricebookId;
        tempDmlList[1].SBQQ__QuotePricebookId__c = pricebookId;
        tempDmlList[2].SBQQ__QuotePricebookId__c = defpricebooks[1].Id;
        insert tempDmlList ;

        /*Creating Quote for Quote match scenario and assign them to pricebook*/
        List<SBQQ__Quote__c> qtLst = TestDataFactory.returnQuotes(1, testSoldToAccounts[2], new List<String>{TestLobCompanyValueQuoteInsert}, pricebookId);
        /*Creating Quote for QuoteLine match scenario*/
        List<SBQQ__Quote__c> qtLnLst = TestDataFactory.returnQuotes(1, testSoldToAccounts[4], new List<String>{TestLobCompanyValueQuoteLineInsert}, pricebookId);
        /*Creating Quote for QuoteLine empty LOB1 match scenario*/
        List<SBQQ__Quote__c> qtLnLst2 = TestDataFactory.returnQuotes(1, testSoldToAccounts[4], new List<String>{}, pricebookId);

        List<SBQQ__Quote__c> tempDmlList2 = new List<SBQQ__Quote__c>();
        tempDmlList2.addAll(qtLst);
        tempDmlList2[0].SBQQ__Opportunity2__c = tempDmlList[0].Id;
        tempDmlList2.addAll(qtLnLst);
        tempDmlList2[1].SBQQ__Opportunity2__c = tempDmlList[1].Id;
        tempDmlList2.addAll(qtLnLst2);
        tempDmlList2[2].SBQQ__Opportunity2__c = tempDmlList[2].Id;
        insert tempDmlList2 ;

        /*Creating 10 Users each 2 with different Profile and IMCD value*/
        List<User> testUserList1 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, '79100');
        List<User> testUserList2 = TestDataFactory.returnUsers(2, Label.Contract_Manager_Profile_Name, '71100');
        List<User> testUserList3 = TestDataFactory.returnUsers(2, Label.Profile_IMCD_Standard_Profile, '76100');
        List<User> testUserList4 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, '45100');
        List<User> testUserList5 = TestDataFactory.returnUsers(2, Label.Standard_User_Profile_Name, '66100');

        List<User> testUsers2Insert = new List<User>();

        testUsers2Insert.addAll(testUserList1);
        testUsers2Insert.addAll(testUserList2);
        testUsers2Insert.addAll(testUserList3);
        testUsers2Insert.addAll(testUserList4);
        testUsers2Insert.addAll(testUserList5);
        insert testUsers2Insert;

        List<String> relProfileName = new List<String>{Label.IMCD_Standard_Profile,Label.Contract_Manager_Profile_Name,Label.Profile_IMCD_Standard_Profile,Label.System_Admin_Profile_Name,Label.Standard_User_Profile_Name};

        Map<String,List<User>> profileToUserMap = new Map<String,List<User>>();

        for( User u : [SELECT id, ProfileId, Profile.Name FROM User Where Profile.Name IN : relProfileName])
        {
            if(profileToUserMap.containsKey(u.Profile.Name))
            {
                profileToUserMap.get(u.Profile.Name).add(u);
            }
            else
            {
                profileToUserMap.put(u.Profile.Name, new List<User>{u});
            }
        }

        /*Creating Opp/Quote Line Items for Principal match scenario*/

        list<SBQQ__QuoteLine__c> qtLineLst = TestDataFactory.returnQuoteLine(1, tempDmlList2[1].Id, prod.Id);
        qtLineLst.addAll(TestDataFactory.returnQuoteLine(1, tempDmlList2[0].Id, prod.Id));

        /*to avoid Same product configuration found in this quote custom VR rule*/
        qtLineLst[0].SBQQ__Quantity__c = 2 ;
        qtLineLst[1].SBQQ__Quantity__c = 3 ;
        /* Fix SF/JEBU/04-DEC-18/Using Quant__c instead of standard field */
        qtLineLst[0].Quant__c = 2 ;
        qtLineLst[1].Quant__c = 3 ;

        insert qtLineLst ;

        List<OpportunityLineItem> oppLineItemList = TestDataFactory.returnOpportunityLineItem(1, tempDmlList[2].Id, pbentry);
        oppLineItemList.addAll(TestDataFactory.returnOpportunityLineItem(1, tempDmlList[2].Id,pbentry ));
        oppLineItemList[0].SBQQ__QuoteLine__c = qtLineLst[1].Id ;
        oppLineItemList[1].SBQQ__QuoteLine__c = qtLineLst[0].Id ;
        oppLineItemList[1].product2Id = proddef.Id;
        insert oppLineItemList;
        Test.stopTest();
    }

    @isTest
    public static void recalculateOnInsertSharing()
    {
        List<String> relProfileName = new List<String>{Label.IMCD_Standard_Profile,Label.Contract_Manager_Profile_Name,Label.Profile_IMCD_Standard_Profile,Label.System_Admin_Profile_Name,Label.Standard_User_Profile_Name};

        Map<String,List<User>> profileToUserMap = new Map<String,List<User>>();

        for( User u : [SELECT id, ProfileId, Profile.Name FROM User Where Profile.Name IN : relProfileName AND isActive = TRUE AND alias = 'For_Test'])
        {
            if(profileToUserMap.containsKey(u.Profile.Name))
            {
                profileToUserMap.get(u.Profile.Name).add(u);
            }
            else
            {
                profileToUserMap.put(u.Profile.Name, new List<User>{u});
            }
        }

        RecordType rt = IMCDUtils.getRecordType('Account', Label.Global_Principa_Account_Recordtype);

        List<Account> principalAccsList = [SELECT Id FROM Account WHERE recordTypeId =: rt.Id];

        List<SharingAccess__c> shareAccsLst = new List<SharingAccess__c>();

        /*AccLob match scenario*/
        SharingAccess__c temp2 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.IMCD_Standard_Profile)[1], '79100', 'Food', false);
        shareAccsLst.add(temp2);

        /*Opportunity match scenario*/
        SharingAccess__c temp4 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Contract_Manager_Profile_Name)[1], '71100', 'Lubricants', false);
        shareAccsLst.add(temp4);

        /*Quote match scenario*/
        SharingAccess__c temp6 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Profile_IMCD_Standard_Profile)[1], '76100', 'Personal Care', false);
        shareAccsLst.add(temp6);

        /*OppLineItem match scenario & empty LOB*/
        SharingAccess__c temp7 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[0], '', 'Synthesis', true);
        SharingAccess__c emptytemp7 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[0], '', '', true);
        temp7.PrincipalId__c = principalAccsList[1].Id;
        emptytemp7.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(temp7);
        shareAccsLst.add(emptytemp7);

        SharingAccess__c temp8 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[1], '45100', 'Synthesis', false);
        SharingAccess__c emptytemp8 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[1], '45100', '', false);
        temp8.PrincipalId__c = principalAccsList[1].Id;
        emptytemp8.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(temp8);
        shareAccsLst.add(emptytemp8);

        /*QuoteLineItem match scenario & empty LOB*/
        SharingAccess__c tempqt = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[0], '', 'Pharmaceuticals', true);
        SharingAccess__c emptytempqt = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[0], '', '', true);
        tempqt.PrincipalId__c = principalAccsList[1].Id;
        emptytempqt.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(tempqt);
        shareAccsLst.add(emptytempqt);

        SharingAccess__c tempqt2 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[1], '66100', 'Pharmaceuticals', false);
        SharingAccess__c emptytempqt2 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[1], '66100', '', false);
        tempqt2.PrincipalId__c = principalAccsList[1].Id;
        emptytempqt2.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(tempqt2);
        shareAccsLst.add(emptytempqt2);

        Test.startTest();
        insert shareAccsLst ;
        Test.stopTest();


        /*preparing testData to populate constructors of queueables classes*/

        List<SharingAccess__c> principalSaList = new List<SharingAccess__c>();
        List<SharingAccess__c> nonPrincipalSaList = new List<SharingAccess__c>();

        List<SharingAccess__c> newSharingAccessList = new List<SharingAccess__c>([SELECT Id, PrincipalId__c, Global__c, LOB1__c,IMCDCompany__c,UserId__c
                                                                                  FROM SharingAccess__c
                                                                                  WHERE Id IN : shareAccsLst]);
        //dividing the sharing access by principal
        SharingUtils.divideByPrincipal(newSharingAccessList,principalSaList, nonPrincipalSaList);
        // get Owners to Accounts Id's to avoid sharing the Account to the owner
        Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(null);

        Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
        Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();

        //mapping principalId__c == NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
        SharingUtils.mappingSharingAccessTable(nonPrincipalSaList, lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap);

        Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
        Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

        //mapping principalId__c != NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
        SharingUtils.mappingSharingAccessTable(PrincipalSaList, lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);
        /*************************************************************************************************************************************************/

        QueueableAccLobRecalculateSharing accSharing = new QueueableAccLobRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);
        accSharing.execute(null);

        QueueableOppRecalculateSharing accAndOppsharing = new  QueueableOppRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new List<AccountShare>());
        accAndOppsharing.execute(null);

        QueueableQuoteRecalculateSharing accAndQuoteSharing = new QueueableQuoteRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new List<AccountShare>(), new List<OpportunityShare>());
        accAndQuoteSharing.execute(null);

        QueueableOppPrincipalRecalculateSharing accAndOppPrincipal = new  QueueableOppPrincipalRecalculateSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, ownersToAccsMap,
            new List<AccountShare>(), new List<OpportunityShare>(), new List<SBQQ__Quote__Share>());
        accAndOppPrincipal.execute(null);

        QueueableQtPrincipalRecalculateSharing accAndQuotePrincipal = new  QueueableQtPrincipalRecalculateSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, ownersToAccsMap,
            new List<AccountShare>(), new List<OpportunityShare>(), new List<SBQQ__Quote__Share>());
        accAndQuotePrincipal.execute(null);
    }

    @isTest
    public static void recalculateOnDeleteSharing()
    {
        List<String> relProfileName = new List<String>{Label.IMCD_Standard_Profile,Label.Contract_Manager_Profile_Name,Label.Profile_IMCD_Standard_Profile,Label.System_Admin_Profile_Name,Label.Standard_User_Profile_Name};

        Map<String,List<User>> profileToUserMap = new Map<String,List<User>>();

        for( User u : [SELECT id, ProfileId, Profile.Name FROM User Where Profile.Name IN : relProfileName AND isActive = TRUE AND alias = 'For_Test'])
        {
            if(profileToUserMap.containsKey(u.Profile.Name))
            {
                profileToUserMap.get(u.Profile.Name).add(u);
            }
            else
            {
                profileToUserMap.put(u.Profile.Name, new List<User>{u});
            }
        }

        RecordType rt = IMCDUtils.getRecordType('Account', Label.Global_Principa_Account_Recordtype);

        List<Account> principalAccsList = [SELECT Id FROM Account WHERE recordTypeId =: rt.Id];

        List<SharingAccess__c> shareAccsLst = new List<SharingAccess__c>();

        SharingAccess__c temp2 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.IMCD_Standard_Profile)[1], '79100', 'Food', false);
        shareAccsLst.add(temp2);

        SharingAccess__c temp4 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Contract_Manager_Profile_Name)[1], '71100', 'Lubricants', false);
        shareAccsLst.add(temp4);

        SharingAccess__c temp6 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Profile_IMCD_Standard_Profile)[1], '76100', 'Personal Care', false);
        shareAccsLst.add(temp6);

        /*OppLineItem match scenario  & empty LOB in SharingAccess*/
        SharingAccess__c temp7 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[0], '', 'Synthesis', true);
        SharingAccess__c emptytemp7 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[0], '', '', true);
        temp7.PrincipalId__c = principalAccsList[1].Id;
        emptytemp7.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(temp7);
        shareAccsLst.add(emptytemp7);
        SharingAccess__c temp8 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[1], '45100', 'Synthesis', false);
        SharingAccess__c emptytemp8 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.System_Admin_Profile_Name)[1], '45100', '', false);
        temp8.PrincipalId__c = principalAccsList[1].Id;
        emptytemp8.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(temp8);
        shareAccsLst.add(emptytemp8);

        /*QuoteLineItem match scenario  & empty LOB in SharingAccess*/
        SharingAccess__c tempqt = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[0], '', 'Pharmaceuticals', true);
        SharingAccess__c emptytempqt = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[0], '', '', true);
        tempqt.PrincipalId__c = principalAccsList[1].Id;
        emptytempqt.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(tempqt);
        shareAccsLst.add(emptytempqt);
        SharingAccess__c tempqt2 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[1], '66100', 'Pharmaceuticals', false);
        SharingAccess__c emptytempqt2 = TestDataFactory.getSharingAccess(profileToUserMap.get(Label.Standard_User_Profile_Name)[1], '66100', '', false);
        tempqt2.PrincipalId__c = principalAccsList[1].Id;
        emptytempqt2.PrincipalId__c = principalAccsList[1].Id;
        shareAccsLst.add(tempqt2);
        shareAccsLst.add(emptytempqt2);

        insert shareAccsLst;

        List<SharingAccess__c> newSharingAccessList = new List<SharingAccess__c>([SELECT Id, PrincipalId__c, Global__c, LOB1__c,IMCDCompany__c,UserId__c
        FROM SharingAccess__c
        WHERE Id IN : shareAccsLst]);


        /*preparing testData to populate constructors of queueables classes which delete sharing*/

        List<SharingAccess__c> principalSaList = new List<SharingAccess__c>();
        List<SharingAccess__c> nonPrincipalSaList = new List<SharingAccess__c>();

        //dividing the sharing access by principal
        SharingUtils.divideByPrincipal(shareAccsLst, principalSaList, nonPrincipalSaList);

        // get Owners to Accounts Id's to avoid sharing the Account to the owner
        Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(null);

        Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
        Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();

        //mapping principalId__c == NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
        SharingUtils.mappingSharingAccessTable(nonPrincipalSaList, lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap);

        Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
        Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

        //mapping principalId__c != NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
        SharingUtils.mappingSharingAccessTable(PrincipalSaList, lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);


        Test.startTest();
            delete shareAccsLst;
        Test.stopTest();

        //first creating the sharing before we test the deleteion
        /*************************************************************************************************************************************************/

        QueueableAccLobRecalculateSharing accSharing = new QueueableAccLobRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);
        accSharing.execute(null);

        QueueableOppRecalculateSharing accAndOppsharing = new  QueueableOppRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new  List<AccountShare>());
        accAndOppsharing.execute(null);

        QueueableQuoteRecalculateSharing accAndQuoteSharing = new QueueableQuoteRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap,new List<AccountShare>(), new List<OpportunityShare>());
        accAndQuoteSharing.execute(null);

        QueueableOppPrincipalRecalculateSharing accAndOppPrincipal = new  QueueableOppPrincipalRecalculateSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, ownersToAccsMap,
            new List<AccountShare>(), new List<OpportunityShare>(), new List<SBQQ__Quote__Share>());
        accAndOppPrincipal.execute(null);

        QueueableQtPrincipalRecalculateSharing accAndQuotePrincipal = new  QueueableQtPrincipalRecalculateSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, ownersToAccsMap,
            new List<AccountShare>(), new List<OpportunityShare>(), new List<SBQQ__Quote__Share>());
        accAndQuotePrincipal.execute(null);


        /*************************************************************************************************************************************************/

        QueueableAccLobDeleteSharing accdelSharing = new QueueableAccLobDeleteSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);
        accdelSharing.execute(null);

        QueueableOppDeleteSharing accAndOppdelsharing = new  QueueableOppDeleteSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new List<AccountShare>());
        accAndOppdelsharing.execute(null);

        QueueableQuoteDeleteSharing accAndQuotedelSharing = new QueueableQuoteDeleteSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new List<AccountShare>(), new List<OpportunityShare>());
        accAndQuotedelSharing.execute(null);

        QueueablePrincipalOppDeleteSharing accAndOppdelPrincipal = new  QueueablePrincipalOppDeleteSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new List<AccountShare>(), new List<OpportunityShare>(),new List<SBQQ__Quote__Share>());
        accAndOppdelPrincipal.execute(null);

        QueueablePrincipalQuoteDeleteSharing accAndQuotedelPrincipal = new  QueueablePrincipalQuoteDeleteSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, new List<AccountShare>(), new List<OpportunityShare>(),new List<SBQQ__Quote__Share>());
        accAndQuotedelPrincipal.execute(null);
        
    }

    /* testing methods from SharingUtils explicitly to extend SharingUtils class code coverage 4.12.18*/
    @isTest
    public static void test_SharingUtils(){
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
        insert testSoldToAccounts;     

        list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        list<AccountShare> accShareLst2 =  new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[1].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        

        List<Opportunity> oppLst = TestDataFactory.returnOpportunities(2, testSoldToAccounts[0], new List<String>{'Synthesis','Lubricants'});
        insert oppLst;
        list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        list<OpportunityShare> oppShareLst2 = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[1].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

        Test.startTest();
        SharingUtils.limitListSize(accShareLst, accShareLst2, 1);
        SharingUtils.limitListSize(oppShareLst, oppShareLst2, 1);
        
        SharingUtils.getParentAccounts(new set<Id>{testSoldToAccounts[0].Id});

        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, false);
        accShareLst.remove(0);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, true);
        SharingUtils.insertOrDeleteAccSharesAndInitRemains(accShareLst2, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, false);
        SharingUtils.insertOrDeleteAccSharesAndInitRemains(accShareLst2, false);
        Test.stopTest();
    }

    /* testing methods from SharingUtils explicitly to extend SharingUtils class code coverage 4.12.18*/
    @isTest
    public static void test_SharingUtils2(){
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
        insert testSoldToAccounts;     

        list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        list<AccountShare> accShareLst2 =  new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[1].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        

        List<Opportunity> oppLst = TestDataFactory.returnOpportunities(2, testSoldToAccounts[0], new List<String>{'Synthesis','Lubricants'});
        insert oppLst;
        list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        list<OpportunityShare> oppShareLst2 = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[1].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

        List<SBQQ__Quote__c> quoteLst = TestDataFactory.createQuotes(1, testSoldToAccounts[0], users[0]);
        List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>{new SBQQ__Quote__Share(UserOrGroupId = users[0].Id, ParentId = quoteLst[0].Id, AccessLevel = Label.READ_WRITE_ACCESS, RowCause = Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c )};
        
        Test.startTest();
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, false);
        List<AccountShare> accShareLst3 = new list<AccountShare>();
        accShareLst3 = accShareLst.clone();
        accShareLst.remove(0);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, false);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst3, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst3, quoteShareLst, false);

        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareLst, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareLst, quoteShareLst, false);
        List<OpportunityShare> oppShareLst3 = new list<OpportunityShare>();
        oppShareLst3 = oppShareLst2.clone();
        oppShareLst2.remove(0);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareLst2, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareLst2, quoteShareLst, false);

        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, quoteShareLst, false);

        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareLst3, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareLst3, quoteShareLst, false);


        Test.stopTest();
    }

    /* testing methods from SharingUtils explicitly to extend SharingUtils class code coverage 4.12.18*/
    @isTest
    public static void test_SharingUtils3(){
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '79100');

        List<Account> testSoldToAccounts = TestDataFactory.returnAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
        insert testSoldToAccounts;

        list<AccountShare> accShareLst = new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[0].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        list<AccountShare> accShareLst2 =  new list<AccountShare>{new AccountShare(AccountId = testSoldToAccounts[1].Id, UserOrGroupId = users[0].Id, AccountAccessLevel = Label.READ_WRITE_ACCESS, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};


        List<Opportunity> oppLst = TestDataFactory.returnOpportunities(2, testSoldToAccounts[0], new List<String>{'Synthesis','Lubricants'});
        insert oppLst;
        list<OpportunityShare> oppShareLst = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[0].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};
        list<OpportunityShare> oppShareLst2 = new list<OpportunityShare>{new OpportunityShare(OpportunityId = oppLst[1].Id, UserOrGroupId = users[0].Id, OpportunityAccessLevel = Label.READ_WRITE_ACCESS)};

        List<SBQQ__Quote__c> quoteLst = TestDataFactory.createQuotes(1, testSoldToAccounts[0], users[0]);
        List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>{new SBQQ__Quote__Share(UserOrGroupId = users[0].Id, ParentId = quoteLst[0].Id, AccessLevel = Label.READ_WRITE_ACCESS, RowCause = Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c )};

        Test.startTest();
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, quoteShareLst, false);
        accShareLst.remove(0);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, quoteShareLst, true);
        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareLst, oppShareLst, quoteShareLst, false);

        Test.stopTest();
    }
}