@isTest
public Class TestAccountTriggerHelper {

    @testSetup 
    static void setup() {
       TestDataFactory.createBypassCustomSetting();
    }

    @isTest
    static void isCompanyLabelCopiedAcrossForInsert(){
        Account testAccount = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '21100')[0];
        String expectedBillingCountryCode = 'AU';
        testAccount.BillingCountryCode = expectedBillingCountryCode;
        String expectedBillingCountryLabel = 'Australia';
        String expectedShippingCountryCode = 'AL';
        testAccount.ShippingCountryCode = expectedShippingCountryCode;
        String expectedShippingCountryLabel = 'Albania';
        Test.startTest();
        
            insert testAccount;
        
        Test.stopTest();
        System.assertEquals(expectedBillingCountryLabel, [SELECT BillingCountryLabel__c FROM Account WHERE ID =: testAccount.Id][0].BillingCountryLabel__c);
        System.assertEquals(expectedShippingCountryLabel, [SELECT ShippingCountryLabel__c FROM Account WHERE ID =: testAccount.Id][0].ShippingCountryLabel__c);
    }

    @isTest
    static void isCompanyLabelCopiedAcrossForUpdate(){
        Account testAccount = TestDataFactory.returnAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '21100')[0];
        String toSetBillingCountryCode = 'AU';
        testAccount.BillingCountryCode = toSetBillingCountryCode;
        String expectedBillingCountryLabel = 'India';
        String toSetShippingCountryCode = 'AL';
        testAccount.ShippingCountryCode = toSetShippingCountryCode;
        String expectedShippingCountryLabel = 'France';

        insert testAccount;

        Test.startTest();

            testAccount.BillingCountryCode = 'IN';        
            testAccount.ShippingCountryCode = 'FR';        
            update testAccount; 
        Test.stopTest();
        System.assertEquals(expectedBillingCountryLabel, [SELECT BillingCountryLabel__c FROM Account WHERE ID =: testAccount.Id][0].BillingCountryLabel__c);
        System.assertEquals(expectedShippingCountryLabel, [SELECT ShippingCountryLabel__c FROM Account WHERE ID =: testAccount.Id][0].ShippingCountryLabel__c);
    }
}