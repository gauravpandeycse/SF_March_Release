@isTest
public Class TestAccountShipToAddressTriggerHelper {

    @testSetup 
    static void setup() {
       TestDataFactory.createBypassCustomSetting();
       List<Account> testAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '21100'); 
        
    }

    @isTest
    static void isCompanyLabelCopiedAcrossForInsert(){
        Account testAccount = [SELECT Id FROM Account][0];
        String expectedCountryCode = 'AU';
        String expectedCountryLabel = 'Australia';
        AccountShipToAddress__c testAddress = new AccountShipToAddress__c(Account__c = testAccount.Id,
                                                                Country__c = expectedCountryCode);
        Test.startTest();
        
            insert testAddress;
        
        Test.stopTest();
        System.assertEquals(expectedCountryLabel, [SELECT CountryLabel__c FROM AccountShipToAddress__c WHERE ID =: testAddress.Id][0].CountryLabel__c);
    }

    @isTest
    static void isCompanyLabelCopiedAcrossForUpdate(){
        Account testAccount = [SELECT Id FROM Account][0];
        String expectedCountryCode = 'AU';
        String expectedCountryLabel = 'Albania';
        AccountShipToAddress__c testAddress = new AccountShipToAddress__c(Account__c = testAccount.Id,
                                                                Country__c = expectedCountryCode);
        insert testAddress;
        Test.startTest();

            testAddress.Country__c = 'AL';
            update testAddress;
        
        Test.stopTest();
        System.assertEquals(expectedCountryLabel, [SELECT CountryLabel__c FROM AccountShipToAddress__c WHERE ID =: testAddress.Id][0].CountryLabel__c);
    }
}