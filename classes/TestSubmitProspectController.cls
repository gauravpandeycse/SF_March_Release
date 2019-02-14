/*------------------------------------------------------------  
Author:        Jeroen Burgers   
Company:       Salesforce   
User Story:    
History 
05/11/2018     Created class
------------------------------------------------------------*/  
@isTest
private class TestSubmitProspectController {

    @testsetup
    public static void testsetup() {
        // enable AccountLob__c triggers
        TestDataFactoryUtils.runTriggers(true);
        TestDataFactoryUtils.runProcessBuilders(true);
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '21100');
        // passing in null for IMCDCompany, should be set by BP (part of test)
        List<Account> accounts;
        System.runAs(users[0])
        {
            accounts = TestDataFactory.createAccounts(1, 'Customer_Prospect', users[0].Id, null);
        }
        // Don't care about dependencies of LOB's - just have random LOBs picked
        List<AccountLob__c> lobs = TestDataFactory.createAccountLobs(1, accounts);
        // Create IntegrationLog__c record
        List<IntegrationLog__c> intlogs = TestDataFactory.createIntegrationLogs(1, 'Queued', 'CREATE_CUSTOMER');
        // Update Account__c Lookup
        IntegrationLog__c intLog = [SELECT Id FROM IntegrationLog__c LIMIT 1];
        intLog.Account__c = accounts[0].Id;
        update intLog;
        // Create custom settings
        TestDataFactory.createIntegrationSettings();
    }

    @isTest
    static void testPrimaryLob () {
        List<AccountLob__c> lstLob = [SELECT LOB1__c, LOB2__c, LOB3__c, Account__c FROM AccountLob__c WHERE Primary__c = True LIMIT 1];
        List<Account> lstAccount = [SELECT Primary_LOB1__c , Primary_LOB2__c , Primary_LOB3__c FROM Account WHERE Id =: lstLob[0].Account__c LIMIT 1];
        System.assert(lstLob[0].LOB1__c == lstAccount[0].Primary_LOB1__c &&
                      lstLob[0].LOB2__c == lstAccount[0].Primary_LOB2__c &&
                      lstLob[0].LOB3__c == lstAccount[0].Primary_LOB3__c, 'Primary LOB values are not copied from related AccountLob__c related lists');
    }
    
    @isTest
    static void testGetData () {
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> data = SubmitProspectController.getData(lstAccount[0].Id);
        System.assertEquals(data.get('Id'), lstAccount[0].Id, 'One prospect should be returned');
    }    

    @isTest
    static void testHasActiveIntegration () {
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        Boolean hasIntegration = SubmitProspectController.hasActiveIntegration(lstAccount[0].Id);
        System.assertEquals(True, hasIntegration, 'Should have Integration');
    }    
    
    @isTest
    static void testCreateIntegrationLog () {
        // Tests for normal situation where user does not have the SfManagedAccounts permission
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        Boolean result = SubmitProspectController.CreateIntegrationLog(lstAccount[0].Id);
        System.assertEquals(True, result, 'Calling CreateIntegrationLog should return success');
        
        //setting up for failure, class uses if (Test.isRunningTest() && accnt.LockedForIntegration__c) condition
        lstAccount[0].LockedForIntegration__c = true;
        update lstAccount;
        result = SubmitProspectController.CreateIntegrationLog(lstAccount[0].Id);
        System.assertEquals(False, result, 'Calling CreateIntegrationLog should fail');
    }

    @isTest
    static void testconvertSoldtoAccount () {
        // Tests for situation where user does have the SfManagedAccounts permission
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        Boolean result = SubmitProspectController.convertSoldtoAccount(lstAccount[0].Id, '99999');
        System.assertEquals(True, result, 'Calling convertProspect should return success');
    }
    
}