/**
 * Created by kdoruibin on 2019-01-10.
 */

@isTest
public with sharing class testCreateProductQueryHelper {
    static List<CreateProductQueryHelper.HelperQueryRequest> lstHelperRequest = new List<CreateProductQueryHelper.HelperQueryRequest>();
    static CreateProductQueryHelper.HelperQueryRequest helperRequest = new CreateProductQueryHelper.HelperQueryRequest();

    @testsetup
    public static void testsetup() {
        TestDataFactory.createBypassCustomSetting();
        TestDataFactoryUtils.runProcessBuilders(false);
        TestDataFactory.createIntegrationSettings();
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactoryUtils.runValidationRules(false);

        List<Account> testPrincipals = TestDataFactory.createAccounts(1, Label.Global_Principa_Account_Recordtype, TestDataFactoryUtils.getContextUserId(), '21100');
        List<Product2> testProducts = TestDataFactory.createProducts(2, testPrincipals[0].Id, '04.Active Sales', 'Product');
    }

    @isTest
    static void testSetupConfig() {
        system.assertEquals(1, [SELECT Id FROM Account].size());
        system.assertEquals(2, [SELECT Id FROM Product2].size());
    }

    @isTest
    static void testBulkificationError () {
        lstHelperRequest.add(helperRequest);
        lstHelperRequest.add(helperRequest);
        String error = '';
        String errorExpected = 'Method is not bulkified, only allows a single request.';

        try {
            CreateProductQueryHelper.executeCreateProductQueryHelper(lstHelperRequest);
        }
        catch (Exception exc) {
            error =  exc.getMessage();
        }

        System.assertEquals(errorExpected, error, errorExpected);
    }

    @isTest
    static void testNoValidInputs () {
        lstHelperRequest.add(helperRequest);
        String error = '';
        String errorExpected = 'No valid inputs received.';

        try {
            CreateProductQueryHelper.executeCreateProductQueryHelper(lstHelperRequest);
        }
        catch (Exception exc) {
            error = exc.getMessage();
        }

        System.assertEquals(errorExpected, error, errorExpected);
    }

    @isTest
    static void testScenarioA () {
        List<String> testProductFields = new List<String>{'Id', 'Name'};
        List<Account> testPrincipals = new List<Account>([SELECT Id, Name FROM Account LIMIT 1]);
        helperRequest.PrincipalId = testPrincipals[0].Id;
        helperRequest.lstProductFields = testProductFields;
        helperRequest.soqlLimit = 50;
        lstHelperRequest.add(helperRequest);
        System.assertNotEquals(null, CreateProductQueryHelper.executeCreateProductQueryHelper(lstHelperRequest)[0], 'Testing Scenario A failed');
        system.debug(lstHelperRequest);
    }
}