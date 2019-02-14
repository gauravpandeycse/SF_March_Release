@isTest
public class TestAccountLobTrigger {
    /* Tests four LOB Classification (LOBC) scenarios:
     * 1. insertNonPrimary(): Error when first LOBC is non-primary.
     * 2. insertTwoPrimaries(): First primary LOBC is automatically unmarked
     *    as primary when second one is inserted.
     * 3. deletePrimaryLOB(): Error when primary LOBC is deleted.
     * 4. accountFields(): Account's 'Primary LOB' fields are updated when
     *                     inserting a new primary LOBC.
     */
    
    @testSetup static void setup() {
        
        // Create test User, Account and AccountLOB.
        List<User> users = TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '21100');
		List<Account> accounts = TestDataFactory.createAccounts(1, 'Customer_Prospect', users[0].Id, '21100');
        TestDataFactory.createBypassCustomSetting();
        
    }
    
    /* Insert a non-primary LOBC as the first LOBC for the Account.
     * Expected behavior: an error will be returned, because at least
	   one primary LOBC is required. */
    @isTest static void testInsertNonPrimary() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccountLob__c lobC = new AccountLob__c(Account__c = account.Id, LOB1__c = 'Lubricants', LOB2__c = 'Fuels', LOB3__c = 'Diesel additives');
        
        Test.startTest();
        try {
      		insert lobC;
        }
        catch(DMLException e) {
            System.assertEquals(Label.ERROR_LOB_MUST_BE_PRIMARY, e.getDmlMessage(0));
        }
        Test.stopTest();
    }
    
    /* Try to insert two primary LOBCs for one Account.
     * Expected behavior: after insertion of the second LOBC,
     * the first one is automatically unmarked as primary. */
    @isTest static void testInsertTwoPrimaries() {
        System.runAs([SELECT Id FROM User LIMIT 1][0]) {
            Account account = [SELECT Id FROM Account LIMIT 1];
            
            List<AccountLob__c> lobCList = new List<AccountLob__c>();
    
            // Add two primary LOB Classifications for the same Account.
            lobCList.add(new AccountLob__c(Account__c = account.Id, Primary__c = TRUE, LOB1__c = 'Lubricants'));
            lobCList.add(new AccountLob__c(Account__c = account.Id, Primary__c = TRUE, LOB1__c = 'Lubricants', LOB2__c = 'Fuels'));
            
        	// Push LOB Classifications to database and get their IDs.
            Test.startTest();
            Database.SaveResult[] insertResults = Database.insert(lobCList);
            Test.stopTest();
        
        	List<ID> lobCIds = new List<ID>();
        
            for (Database.SaveResult result : insertResults) {
                if (result.isSuccess()) {
                    lobCIds.add(result.getId());
                }
            }
            
            System.debug('lobCIds ' + lobCIds);
               
            // Query recently pushed LOB Classifications to see if only one is still primary.
            List<AccountLob__c> accLobs = [SELECT Id, Primary__c
                                           FROM AccountLob__c
                                           WHERE Id in :lobCIds];
            
            Integer primaryCounter = 0;
            
            System.debug('accLobs ' + accLobs);
            
            for (AccountLob__c accLob : accLobs) {
                if (accLob.Primary__c == TRUE) primaryCounter++;
            }
            
            System.assertEquals(1, primaryCounter);
        }
    }
    
    /* Insert a new primary LOBC, and then delete it.
     * Expected behavior: error because primary LOB cannot
     * be deleted. */
    @isTest static void testDeletePrimaryLOB() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        AccountLob__c lobC = new AccountLob__c(Account__c = account.Id, LOB1__c = 'Lubricants', LOB2__c = 'Fuels', LOB3__c = 'Diesel additives', Primary__c = TRUE);
        
        Test.startTest();
      	insert lobC;
        try {
        	delete lobC;
        } catch(DmlException e) {
            System.assertEquals(Label.ERROR_CANT_DELETE_PRIMARY, e.getDmlMessage(0));
        }
        Test.stopTest();
    }
    
    @isTest static void testAccountFields() {
        System.runAs([SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1][0]) {
            Account account = [SELECT Id FROM Account LIMIT 1];
            
            AccountLob__c lobC = new AccountLob__c(Account__c = account.Id, Primary__c = TRUE, LOB1__c = 'Lubricants', LOB2__c = 'Fuels', LOB3__c = 'Diesel additives');
            
            Test.startTest();
            insert lobC;
            Test.stopTest();
            
            account = [SELECT Id, Primary_LOB1__c, Primary_LOB2__c, Primary_LOB3__c FROM Account WHERE Id =: account.Id LIMIT 1][0];
            
            System.assertEquals('Lubricants', account.Primary_LOB1__c);
            System.assertEquals('Fuels', account.Primary_LOB2__c);
            System.assertEquals('Diesel additives', account.Primary_LOB3__c);
        }
    }
}