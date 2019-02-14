/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for SbqqQuoteTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
@IsTest
public with sharing class TestSbqqQuoteTriggerHelper
{
@testSetup static void setup() {
/*Creating 2 distinct random IMCD company values */
String imcdCompanyTestValue = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
String imcdCompanyTestValue2;
do {
imcdCompanyTestValue2 = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
} while (imcdCompanyTestValue2.equals(imcdCompanyTestValue));

/*Creating 3 distinct random LOB1 values*/
Set<String> lob1FieldNameTestValuesSet = new Set<String>();
do {
String temp = TestDataFactoryUtils.getRandomPickListValue(new AccountLob__c(), Label.LOB1_Field_Name);

if (!lob1FieldNameTestValuesSet.contains(temp)) {
lob1FieldNameTestValuesSet.add(temp);
}
} while (lob1FieldNameTestValuesSet.size() != 5);

Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();

/*Creating 4 Sold To and 2 related C2 Accounts for creating Account Shares testing*/
List<Account> testSoldToAccounts = TestDataFactory.createAccounts(4, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);
testSoldToAccounts.addAll(TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue2));
List<Account> testC2Accounts = TestDataFactory.createAccounts(2, Label.Regional_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);
List<Account> regionAccounts = TestDataFactory.returnAccounts(1, Label.Principal_Regional_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '13100');

List<User> testUsers2Insert = new List<User>();
List<SharingAccess__c> testSharingAccessToInsert = new List<SharingAccess__c>();

testSoldToAccounts[0].ParentId = testC2Accounts[0].Id;
testSoldToAccounts[1].ParentId = testC2Accounts[1].Id;

update testSoldToAccounts;

/*Creating 10 Users each 2 with different Profile*/
List<User> testUserList1 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
List<User> testUserList2 = TestDataFactory.returnUsers(2, Label.Contract_Manager_Profile_Name, imcdCompanyTestValue);
List<User> testUserList3 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name	, imcdCompanyTestValue);
List<User> testUserList4 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
List<User> testUserList5 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name	, imcdCompanyTestValue);
List<User> testUserList6 = TestDataFactory.returnUsers(1, Label.System_Admin_Profile_Name, imcdCompanyTestValue2);
List<User> uListForUpdQuoteTest = TestDataFactory.returnUsers(2,Label.Standard_User_Profile_Name, imcdCompanyTestValue2);


testUsers2Insert.addAll(testUserList1);
testUsers2Insert.addAll(testUserList2);
testUsers2Insert.addAll(testUserList3);
testUsers2Insert.addAll(testUserList4);
testUsers2Insert.addAll(testUserList5);
testUsers2Insert.addAll(testUserList6);
testUsers2Insert.addAll(uListForUpdQuoteTest);
insert testUsers2Insert;

/*Creating 10 SharingAccess records each 2 related to one of the random LOB1 values and Users*/
List<String> lob1FieldNameTestValuesList = new List<String>(lob1FieldNameTestValuesSet);
//List<SharingAccess__c> testGlobalSharList = TestDataFactory.getSharingAccessList(testUserList1, '', lob1FieldNameTestValuesList[0], true);
//List<SharingAccess__c> testGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList4, '', lob1FieldNameTestValuesList[1], true);
List<SharingAccess__c> testNonGlobalSharList1 = TestDataFactory.getSharingAccessList(testUserList2, imcdCompanyTestValue, lob1FieldNameTestValuesList[2], false);
List<SharingAccess__c> testNonGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue2, lob1FieldNameTestValuesList[4], false);
List<SharingAccess__c> testNonGlobalSharList3 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue, lob1FieldNameTestValuesList[3], false);
List<SharingAccess__c> testNonGlobalSharList4 = TestDataFactory.getSharingAccessList(testUserList5, imcdCompanyTestValue2, lob1FieldNameTestValuesList[2], false);
List<SharingAccess__c> testNonGlobalSharList5 = TestDataFactory.getSharingAccessList(testUserList6, imcdCompanyTestValue2, lob1FieldNameTestValuesList[2], false);


    for(SharingAccess__c sa : testNonGlobalSharList5)
        sa.PrincipalId__c = regionAccounts[0].Id ;

//testSharingAccessToInsert.addAll(testGlobalSharList);
//testSharingAccessToInsert.addAll(testGlobalSharList2);
testSharingAccessToInsert.addAll(testNonGlobalSharList1);
testSharingAccessToInsert.addAll(testNonGlobalSharList2);
testSharingAccessToInsert.addAll(testNonGlobalSharList3);
testSharingAccessToInsert.addAll(testNonGlobalSharList4);
testSharingAccessToInsert.addAll(testNonGlobalSharList5);
Test.startTest();
    insert testSharingAccessToInsert ;
Test.stopTest();
    //creating IMCD companies records for test
List<String> imcdCompaniesForTest = new List<String>{imcdCompanyTestValue,imcdCompanyTestValue2};
TestDataFactory.createImcdCompanies(imcdCompaniesForTest);
}

    class MyException extends Exception {}


/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Test for SbqqQuoteTriggerHelper.QuoteAndAccSharingBasedLOB, SbqqQuoteTriggerHelper.updateQuoteAndAccSharingBasedLOB
 * History :
 ******************************************************************************************************************************************************************/
@IsTest
public static void QuoteAndAccountSharingTest()
{
    RecordType rt = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type);
    List<Account> testAccs = new List<Account>([SELECT Id, IMCDCompany__c, ParentId, recordtypeId FROM Account Where recordTypeId = :rt.Id]);
    Map<Id, User> testUsers = new Map<Id, User>([Select Id From User Where alias = 'For_Test']);

    List<SBQQ__Quote__c> quotesToInsert = new List<SBQQ__Quote__c>();
    Set<Id> toQueryAccountSet = new Set<Id>();
    Set<String> testLOBsFromDB = new Set<String>();
    Set<String> testLOBnotExistInDB = TestDataFactoryUtils.getPicklistValues(new AccountLob__c(), Label.LOB1_Field_Name);

    for (Account acc : testAccs)
    {
        toQueryAccountSet.add(acc.Id);
        if(acc.ParentId!=null)
        toQueryAccountSet.add(acc.ParentId);
    }

    List<SharingAccess__c> saTable = SharingUtils.getSharingAccessTable(null);
    Set<String> globalSAFromDB = new Set<String>();

    for (SharingAccess__c sa : saTable)
    {
        if (!testLOBsFromDB.contains(sa.LOB1__c))
        {
            testLOBsFromDB.add(sa.LOB1__c);
        }
        if (testLOBnotExistInDB.contains(sa.LOB1__c))
        {
            testLOBnotExistInDB.remove(sa.LOB1__c);
        }
        if (sa.global__c)
        {
            globalSAFromDB.add(sa.LOB1__c);
        }
    }
    String nonExistentLOB = (new list<String>(testLOBnotExistInDB))[0] ;

    List<String> tempList = new List<String>();
    templist.addAll(testLOBsFromDB);


    for (Integer i = 0; i < templist.size(); i++)
    {
        //this test Account will be linked to Quotes that are in the sharingAccess table and global
        if (globalSAFromDB.contains(tempList[i]))
        {
            quotesToInsert.addAll(TestDataFactory.returnQuotes(1, testAccs[0], new List<String>{tempList[i]}));
        }
        // this test Account will be linked to Quotes that are in the sharingAccess table and have the same IMCDCompany as the test account
        else {
            quotesToInsert.addAll(TestDataFactory.returnQuotes(1, testAccs[1], new List<String>{templist[i]}));
            quotesToInsert.addAll(TestDataFactory.returnQuotes(1, testAccs[2], new List<String>{templist[i]}));
            quotesToInsert.addAll(TestDataFactory.returnQuotes(1, testAccs[3], new List<String>{templist[i]}));
        }
    }
    Test.startTest();
    /****************************************** testing OpportunityTriggerHelper.OppAndAccSharingBasedLOB **************************************/
    insert quotesToInsert;
    Map<String, List<SharingAccess__c>> sharingAccessByLOBGlobal = new Map<String, List<SharingAccess__c>>();
    Map<String, Map<String, List<SharingAccess__c> >> lob1toSharingAccessMap = new Map<String, Map<String, List<SharingAccess__c> >>();
    SharingUtils.mappingSharingAccessTable(saTable, lob1toSharingAccessMap, sharingAccessByLOBGlobal);
    List<Account> accsFromDBList = new List<Account>([
            SELECT Id, IMCDCompany__c, OwnerId, (Select Id, SBQQ__Account__c, LOB1__c From SBQQ__Quotes__r)
            FROM Account
            WHERE Id IN :toQueryAccountSet]);

    Integer numOfQuoteSharesExpected = 0;

    Set<Id> quoteToQueryIds = new Set<Id>();
    for (Account acc : accsFromDBList)
    {
        if(!acc.SBQQ__Quotes__r.isEmpty())
        {
            for (SBQQ__Quote__c qt : acc.SBQQ__Quotes__r)
            {
                if (lob1toSharingAccessMap.get(qt.LOB1__c) != null && lob1toSharingAccessMap.get(qt.LOB1__c).get(acc.IMCDCompany__c) != null)
                {
                    numOfQuoteSharesExpected += lob1toSharingAccessMap.get(qt.LOB1__c).get(acc.IMCDCompany__c).size();
                    quoteToQueryIds.add(qt.Id);
                }
                if (sharingAccessByLOBGlobal.get(qt.LOB1__c) != null)
                {
                    numOfQuoteSharesExpected += sharingAccessByLOBGlobal.get(qt.LOB1__c).size();
                    quoteToQueryIds.add(qt.Id);
                }
            }
        }
    }
    List<SBQQ__Quote__Share> quoteShareList = new List<SBQQ__Quote__Share>([SELECT Id, RowCause, ParentId FROM SBQQ__Quote__Share WHERE ParentId IN :quoteToQueryIds AND RowCause =: Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c]) ;

    /*The total number of SBQQ__Quote__Share inserted should be equal to the expected number of SBQQ__Quote__Share to be
    inserted following the rules LOB1 match & (Global = true OR IMCDCompany match)*/
    //System.assertEquals(quoteShareList.size(),numOfQuoteSharesExpected );
    /****************************************** testing OpportunityTriggerHelper.updateOppAndAccSharingBasedLOB **************************************/

    User testUsrForUpdSharOfQuote = new User();
    User testUsrForUpdSharOfQuote2 = new User();


    List<User> queriedUsersList = new List<User>([SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = : Label.Standard_User_Profile_Name]);

    testUsrForUpdSharOfQuote = queriedUsersList[0];
    testUsrForUpdSharOfQuote2 = queriedUsersList[1];

    List<User> globalUserList = new List<User>{testUsrForUpdSharOfQuote};
    List<User> imcdUserList = new List<User>{testUsrForUpdSharOfQuote2};

    List<SBQQ__Quote__c> testQuoteList = new List<SBQQ__Quote__c>([SELECT Id, SBQQ__Account__c, SBQQ__Account__r.IMCDCompany__c FROM SBQQ__Quote__c Where Id =: quotesToInsert[0].Id ]);
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
    testQuote =  testQuoteList[0];

    //List<SharingAccess__c> testNonExistSharList = TestDataFactory.getSharingAccessList(globalUserList, '', nonExistentLOB, true);
    List<SharingAccess__c> testNonExistSharList = new List<SharingAccess__c>();
    testNonExistSharList.addAll(TestDataFactory.getSharingAccessList(imcdUserList, testQuote.SBQQ__Account__r.IMCDCompany__c, nonExistentLOB, false));
    insert testNonExistSharList ;
    testQuote.LOB1__c = nonExistentLOB ;
    update testQuote;

    List<SBQQ__Quote__Share> quoteUpdShareList = new List<SBQQ__Quote__Share>([SELECT Id, RowCause, UserOrGroupId, ParentId FROM SBQQ__Quote__Share WHERE ParentId = :testQuote.Id AND RowCause =: Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c]) ;
    Set<Id> userIdsOfQuoteSharesSet = new Set<Id>();
    for(SBQQ__Quote__Share qs : quoteUpdShareList)
    {
        if(qs.ParentId == testQuote.Id && (qs.UserOrGroupId == testUsrForUpdSharOfQuote.Id || qs.UserOrGroupId == testUsrForUpdSharOfQuote2.Id))
        {
            userIdsOfQuoteSharesSet.add(qs.UserOrGroupId);
        }
    }
    /* After inserting a test User and Sharing access record with LOB that is not one of the LOB's of the existing Quotes,
     we expect changing the LOB1__c field, on one of our Quotes to that LOB,
     will share the Quote with the relevant Users matched by LOB & global/IMCD*/
    //system.assertEquals(userIdsOfQuoteSharesSet.size(), 2);
    Test.stopTest();
    }

 /******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Test for SbqqQuoteTriggerHelper.setIMCDCompanyLookup,
 * History :
 ******************************************************************************************************************************************************************/
    @IsTest
    public static void setIMCDCompanyLookupTest()
    {
        RecordType rt = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type);

        List<Account> testAccs = new List<Account>([SELECT Id, IMCDCompany__c, ParentId, recordtypeId FROM Account Where recordTypeId = :rt.Id]);
        Set<String> lobValuesForTest = TestDataFactoryUtils.getPicklistValues(new AccountLob__c(), Label.LOB1_Field_Name);

        List<String> tempList = new List<String>();
        tempList.addAll(lobValuesForTest);

        List<SBQQ__Quote__c> quotesToInsert = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> quotesToInsertForAddError = new List<SBQQ__Quote__c>();
        quotesToInsert.addAll(TestDataFactory.returnQuotes(1, testAccs[1], new List<String>{tempList[1]}));

        Set<String> existImcdComp = new Set<String>();

        Id imcdCompIdForAssert ;

        for(IMCDCompany__c imcdc : [SELECT ID, ImcdCompany__c FROM IMCDCompany__c])
        {
            existImcdComp.add(imcdc.ImcdCompany__c);
            if(imcdc.IMCDCompany__c.equals(testAccs[1].IMCDCompany__c) )
            {
                imcdCompIdForAssert = imcdc.Id;
            }
        }

        String imcdCompanyTestValue ;

        do
        {
            imcdCompanyTestValue = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        }
        while(existImcdComp.contains(imcdCompanyTestValue));

        List<Account> testgetErrorAccount = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);

        insert quotesToInsert ;
        quotesToInsert[0].SBQQ__BillingStreet__c = 'test' ;
        update quotesToInsert;

        List<SBQQ__Quote__c> insertedQuoteList = new List<SBQQ__Quote__c>([SELECT Id,ImcdCompanyLookup__c FROM SBQQ__Quote__c WHERE Id = : quotesToInsert[0].Id]);
        /*We expect that ImcdCompanyLookup__c will be populated with the ID of the IMCDCompany__c record that has the same IMCDCompany__c picklist value as the Account that is related to quote*/
        //system.assertEquals(insertedQuoteList[0].ImcdCompanyLookup__c, imcdCompIdForAssert);

        /*We expect that quote that will be related to an Account that has an IMCDCompany__c picklist value that does not exist in the IMCDCompany__c object records, will throw an error*/
        List<SBQQ__Quote__c> insertedQuoteList2;
        try
        {
            quotesToInsertForAddError.addAll(TestDataFactory.returnQuotes(1, testgetErrorAccount[0], new List<String>{tempList[2]}));
            insert quotesToInsertForAddError;
            //If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
            throw new MyException('An exception should have been thrown by the trigger but was not.');
        }

        catch(Exception e)
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('[SBQQQuoteTriggerHelper][setIMCDCompanyLookup] Unable to find corresponding IMCD Company record for IMCD Company :' + testgetErrorAccount[0].ImcdCompany__c) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }

    }
}