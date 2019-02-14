@isTest
public class TestCPQCreateContracedPrice {
/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
User Story:	   
History	
	21/06/2018	   Created test class for coverage purposes only
				   Since this is invocable method expect the PriceRenewalCampaign class 
				   to implement actual unit test. 
------------------------------------------------------------*/
 	@testsetup
    public static void testsetup() {
		// disable process builders and triggers
        TestDataFactoryUtils.runTriggers(false);
        TestDataFactoryUtils.runProcessBuilders(false);
		List<Account> soldToAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
        insert TestDataFactory.returnOpportunities(1, soldToAccounts[0], new List<String>{'Coatings & Construction'});
    }    
    
    @isTest
    public static void runInvocableMethodPositive() {   
        List<Id> lstOptyId = new List<Id>();
        lstOptyId.add([SELECT Id FROM Opportunity][0].Id);
		CPQcreateContracedPrice.go(lstOptyId);
    }
   
    @isTest
	public static void runInvocableMethodNegative() {   
        List<Id> lstOptyId = new List<Id>();
        lstOptyId.add([SELECT Id FROM Opportunity][0].Id);
        delete [SELECT Id FROM Opportunity];
		CPQcreateContracedPrice.go(lstOptyId);
    }
}