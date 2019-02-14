/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Tests for SharingReconciliationBatch
 * History :
 *******************************************************************************************************************************/
@isTest
public without sharing class TestSharingReconciliationBatch
{
    @testSetup
    public static void testSetup()
    {
        TestDataFactory.createIntegrationSettings();
        TestDataFactoryUtils.runProcessBuilders(false);
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactoryUtils.runValidationRules(false);
        String companyNumber = '21100';
        TestDataFactory.createImcdCompanies(new List<String>{companyNumber});
        List<User> uList = TestDataFactory.createUsers(1,'Standard User',companyNumber);
        insert(TestDataFactory.getSharingAccess(uList[0], companyNumber, 'Food', false));
    }

    static testMethod void testMethod1()
    {


        Test.startTest();

        SharingReconciliationBatch obj = new SharingReconciliationBatch([SELECT Id FROM SharingAccess__c limit 1].Id);

        DataBase.executeBatch(obj);

        Test.stopTest();

        System.assertNotEquals([SELECT lastSharingReconciliationDate__c FROM SharingAccess__c limit 1].lastSharingReconciliationDate__c, null);
    }
}