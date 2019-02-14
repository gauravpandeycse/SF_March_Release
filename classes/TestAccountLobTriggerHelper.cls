/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for AccountLobTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/

@IsTest
public class TestAccountLobTriggerHelper
{

    @testSetup static void setup()
    {
        /*Creating 2 distinct random IMCD company values */
        String imcdCompanyTestValue = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        String imcdCompanyTestValue2;
        do
        {
            imcdCompanyTestValue2 = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        }
        while(imcdCompanyTestValue2.equals(imcdCompanyTestValue));

        /*Creating 3 distinct random LOB1 values*/
        Set<String> lob1FieldNameTestValuesSet = new Set<String>();
        do
        {
            String temp = TestDataFactoryUtils.getRandomPickListValue(new AccountLob__c(), Label.LOB1_Field_Name);

            if(!lob1FieldNameTestValuesSet.contains(temp) )
            {
                lob1FieldNameTestValuesSet.add(temp);
            }
        }
        while(lob1FieldNameTestValuesSet.size()!=5);

        Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();

        /*Creating 4 Sold To and 4 related C2 Accounts for creating Account Shares testing*/
        List<Account> testSoldToAccounts = TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue);
        testSoldToAccounts.addAll(TestDataFactory.createAccounts(2, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), imcdCompanyTestValue2));
        List<Account> testC2Accounts = TestDataFactory.createAccounts(4, Label.Regional_Account_Record_Type,TestDataFactoryUtils.getContextUserId(),imcdCompanyTestValue);

        List<User> testUsers2Insert = new List<User>();
        List<SharingAccess__c> testSharingAccessToInsert = new List<SharingAccess__c>();

        for(Integer i=0; i< testSoldToAccounts.size() ; i++)
        {
            testSoldToAccounts[i].ParentId = testC2Accounts[i].Id;
        }
        update testSoldToAccounts;

        /*Creating 10 Users each 2 with different Profile*/
        List<User> testUserList1 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
        List<User> testUserList2 = TestDataFactory.returnUsers(2, Label.Contract_Manager_Profile_Name, imcdCompanyTestValue);
        List<User> testUserList3 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, imcdCompanyTestValue);
        List<User> testUserList4 = TestDataFactory.returnUsers(2, Label.IMCD_Standard_Profile, imcdCompanyTestValue);
        List<User> testUserList5 = TestDataFactory.returnUsers(2, Label.System_Admin_Profile_Name, imcdCompanyTestValue);

        testUsers2Insert.addAll(testUserList1);
        testUsers2Insert.addAll(testUserList2);
        testUsers2Insert.addAll(testUserList3);
        testUsers2Insert.addAll(testUserList4);
        testUsers2Insert.addAll(testUserList5);
        insert testUsers2Insert;

        /*Creating 10 SharingAccess records each 2 related to one of the random LOB1 values and Users*/
        List<String> lob1FieldNameTestValuesList = new List<String>(lob1FieldNameTestValuesSet);
        //List<SharingAccess__c> testGlobalSharList = TestDataFactory.getSharingAccessList(testUserList1,'',lob1FieldNameTestValuesList[0], true);
        //List<SharingAccess__c> testGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList4,'',lob1FieldNameTestValuesList[1], true);
        List<SharingAccess__c> testNonGlobalSharList1 = TestDataFactory.getSharingAccessList(testUserList2, imcdCompanyTestValue,lob1FieldNameTestValuesList[2],false);
        List<SharingAccess__c> testNonGlobalSharList2 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue2,lob1FieldNameTestValuesList[4],false);
        List<SharingAccess__c> testNonGlobalSharList3 = TestDataFactory.getSharingAccessList(testUserList3, imcdCompanyTestValue,lob1FieldNameTestValuesList[3],false);
        List<SharingAccess__c> testNonGlobalSharList4 = TestDataFactory.getSharingAccessList(testUserList5, imcdCompanyTestValue2,lob1FieldNameTestValuesList[2],false);

        //testSharingAccessToInsert.addAll(testGlobalSharList);
        //testSharingAccessToInsert.addAll(testGlobalSharList2);
        testSharingAccessToInsert.addAll(testNonGlobalSharList1);
        testSharingAccessToInsert.addAll(testNonGlobalSharList2);
        testSharingAccessToInsert.addAll(testNonGlobalSharList3);
        testSharingAccessToInsert.addAll(testNonGlobalSharList4);

        insert testSharingAccessToInsert ;
    }


    /******************************************************************************************************************************************************************
     * Author: Eli Pogorelov
     * Company: Salesforce
     * Description: Test for AccountLobTriggerHelper.accountShareBasedLOB, AccountLobTriggerHelper.deleteAccountShareOnLOBDelete
     * History :
     ******************************************************************************************************************************************************************/
    @IsTest
    public static void accountSharingTest()
    {
        RecordType rt = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type);
        List<Account> testAccs = new List<Account>([SELECT Id, IMCDCompany__c, ParentId, recordtypeId FROM Account Where recordTypeId =:rt.Id]);
        Map<Id,User> testUsers = new Map<Id,User>([Select Id From User Where alias = 'For_Test']);

        List<AccountLob__c> accLobToInsertPrimary = new List<AccountLob__c>();
        List<AccountLob__c> accLobToInsert = new List<AccountLob__c>();
        Set<Id> toQueryAccountSet = new Set<Id>();
        Set<String> testLOBsFromDB = new Set<String>();
        Set<String> testLOBnotExistInDB = TestDataFactoryUtils.getPicklistValues(new AccountLob__c(), Label.LOB1_Field_Name);

        for(Account acc : testAccs)
        {
            toQueryAccountSet.add(acc.Id);
            toQueryAccountSet.add(acc.ParentId);
        }

        List<SharingAccess__c> saTable = SharingUtils.getSharingAccessTable(null);
        Set<String> globalSAFromDB = new Set<String>();

        for(SharingAccess__c sa : saTable)
        {
            if(!testLOBsFromDB.contains(sa.LOB1__c))
            {
                testLOBsFromDB.add(sa.LOB1__c);
            }
            if(testLOBnotExistInDB.contains(sa.LOB1__c))
            {
                testLOBnotExistInDB.remove(sa.LOB1__c);
            }
            if(sa.global__c)
            {
                globalSAFromDB.add(sa.LOB1__c);
            }
        }

        String nonExistentLOB = (new list<String>(testLOBnotExistInDB))[0] ;
        String nonExistentLOB2 = (new list<String>(testLOBnotExistInDB))[1] ;

        List<String> tempList = new List<String>();
        templist.addAll(testLOBsFromDB);

        //setting up primary LOB
        for(Account acc : testAccs)
        {
            accLobToInsertPrimary.addAll(TestDataFactory.returnAccountLobs(1,acc,new List<String>{nonExistentLOB}, true));
        }

        insert accLobToInsertPrimary;

        for(Integer i=0; i<templist.size(); i++)
        {
            //this test Account will be linked to LOB that are  in the sharingAccess table
            if(globalSAFromDB.contains(tempList[i]))
            {
                accLobToInsert.addAll(TestDataFactory.returnAccountLobs(1,testAccs[0],new List<String>{tempList[i]},false));
            }
            // this test Account will be linked to LOB that are in the sharingAccess table and have the same IMCDCompany as the test account
            else
            {
                accLobToInsert.addAll(TestDataFactory.returnAccountLobs(1, testAccs[1], new List<String>{templist[i]}, false));
                accLobToInsert.addAll(TestDataFactory.returnAccountLobs(1,testAccs[2],new List<String>{templist[i]},false));
                accLobToInsert.addAll(TestDataFactory.returnAccountLobs(1,testAccs[3],new List<String>{templist[i]},false));
            }
        }
        Test.startTest();
        /****************************************** testing AccountLobTriggerHelper.accountShareBasedLOB **************************************/
        insert accLobToInsert;
        Map<String,List<SharingAccess__c>> sharingAccessByLOBGlobal = new Map<String,List<SharingAccess__c>>();
        Map<String, Map<String, List<SharingAccess__c> >> lob1toSharingAccessMap = new Map<String, Map<String, List<SharingAccess__c> >>();
        SharingUtils.mappingSharingAccessTable(saTable, lob1toSharingAccessMap, sharingAccessByLOBGlobal);
        List<Account> accsFromDBList = new List<Account>([SELECT Id, IMCDCompany__c, OwnerId,
                                                            (SELECT Id, AccountId, UserOrGroupId, RowCause FROM Shares),
                                                            (SELECT Id, LOB1__c, primary__c FROM LOB_Classifications__r) FROM Account WHERE Id IN : toQueryAccountSet]);
        Integer numOfAccSharesGlobalExpected = 0;
        Integer numOfAccSharesByCompanyExpected = 0;
        Integer totalNumOfAccShares = 0 ;
        Integer noOwnerNumOfAccShares = 0 ;
        for(Account acc : accsFromDBList)
        {
            if(!acc.LOB_Classifications__r.isEmpty())
            {
                for(AccountLob__c acLob : acc.LOB_Classifications__r)
                {
                    if(lob1toSharingAccessMap.get(acLob.LOB1__c)!=null && lob1toSharingAccessMap.get(acLob.LOB1__c).get(acc.IMCDCompany__c)!=null )
                    {
                        numOfAccSharesByCompanyExpected += lob1toSharingAccessMap.get(acLob.LOB1__c).get(acc.IMCDCompany__c).size() * 2 ;
                    }
                    if(sharingAccessByLOBGlobal.get(acLob.LOB1__c)!=null)
                    {
                        numOfAccSharesGlobalExpected +=  sharingAccessByLOBGlobal.get(acLob.LOB1__c).size() * 2;
                    }
                }
            }
            if(!acc.Shares.isEmpty())
            {
                for(AccountShare sh : acc.Shares)
                {
                    if(sh.RowCause.equals(Label.MANUAL_RAW_CAUSE) )
                    {
                        noOwnerNumOfAccShares+= 1;
                    }
                }
                totalNumOfAccShares += acc.Shares.size();
            }
        }
        /*The total number of accountShares inserted should be equal to the expected number of AccountShares to be inserted following the rules LOB1 match & (Global = true OR IMCDCompany match)
         * not including accShares added because of the Owner */
        //System.assertEquals(noOwnerNumOfAccShares, numOfAccSharesByCompanyExpected + numOfAccSharesGlobalExpected);

        /****************************************** testing AccountLobTriggerHelper.deleteAccountShareOnLOBDelete *******************************************************************************************/
        List<AccountLob__c> accLobsToDelete = new List<AccountLob__c>();
        Set<Id> chkDeleted4secondTest = new Set<Id>();
        for(AccountLob__c acLOB : accLobToInsert)
        {
            if(acLOB.LOB1__c.equals(nonExistentLOB2) && !acLOB.primary__c)
            {
                accLobsToDelete.add(acLOB);
                chkDeleted4secondTest.add(acLOB.Id);
            }
        }
        Delete accLobsToDelete ;
        List<AccountShare> accSharesAfterDelete = new List<AccountShare>([SELECT Id FROM AccountShare]);

        /*Deleting the lob that has no match in the Sharing Access table should not affect AccountShare*/
        //System.assertEquals(accSharesAfterDelete.size(),totalNumOfAccShares);
        accLobsToDelete.clear();
        for(AccountLob__c acLOB : accLobToInsert)
        {
            if(!acLOB.primary__c && !acLOB.LOB1__c.equals(nonExistentLOB) && !chkDeleted4secondTest.contains(acLOB.Id))
            {
                accLobsToDelete.add(acLOB);
            }
        }
        Delete accLobsToDelete ;
        accSharesAfterDelete = new List<AccountShare>([SELECT Id,RowCause FROM AccountShare]);

        /*Deleting all lob's except primaries should result in deleting
        all AccountShare except those inherited from primary LOB in our case all primary LOB
        classifications are dummies so we expect all sharing except shares for OwnerId to be deleted*/
        for(AccountShare ach : accSharesAfterDelete)
        {
            //System.assert(ach.RowCause.equals('Owner'));
        }
        Test.stopTest();
    }
}