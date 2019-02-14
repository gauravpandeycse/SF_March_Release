/*------------------------------------------------------------
  Author		: Jeroen Burgers
  Company		: Salesforce
  Description	: Tests for DiscountScheduleTriggerHelper class
  Inputs 		: 
  Test Class 	:
  History		: 23/05/2018 created
------------------------------------------------------------*/	
@IsTest
public class TestDiscountScheduleTriggerHelper {
    
	@testSetup 
	static void testsetup() {
		// disable process builders and enable triggers
        TestDataFactoryUtils.runTriggers(true); 
        TestDataFactoryUtils.runProcessBuilders(false);
        List<User> lstUsers = TestDataFactory.createUsers(1, 'IMCD Standard Profile', '21100');
        List<Account> lstPrincipal = TestDataFactory.createAccounts(1, 'Principal_Global', lstUsers[0].Id, '21100');
		List<Product2> lstProduct = TestDataFactory.createProducts(1, lstPrincipal[0].Id);
		PriceBookEntry pbEntry = TestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), lstProduct[0].Id);
        SBQQ__DiscountSchedule__c schedule = TestDataFactory.createDiscountSchedule(Test.getStandardPricebookId(), lstProduct[0].Id);
        List<SBQQ__DiscountTier__c> tiers = TestDataFactory.createDiscountTier(schedule);
	}
    
	@isTest 
	static void testUpdateSchedule() {
        SBQQ__DiscountSchedule__c schedule = [SELECT Id, Name FROM SBQQ__DiscountSchedule__c LIMIT 1];
        schedule.Name = 'Updated';
        update schedule;
        PricebookEntry pbe = [SELECT Modified__c, Id FROM PricebookEntry LIMIT 1];
        System.assertEquals(true, !(pbe.Modified__c.millisecond() > 0), 'Modified__c should be populated after updating a schedule');
    }
    
	@isTest 
	static void testUpdateTier() {
		SBQQ__DiscountTier__c tier = [SELECT Id, SBQQ__Discount__c FROM SBQQ__DiscountTier__c LIMIT 1];
		tier.SBQQ__Discount__c = 50; // update to 50%
		update tier;
		PricebookEntry pbe = [SELECT Modified__c, Id FROM PricebookEntry LIMIT 1];
		System.assertEquals(true, !(pbe.Modified__c.millisecond() > 0), 'Modified__c should be populated after updating a tier');
    }
    
	@isTest 
	static void testDmlException() {
        SBQQ__DiscountSchedule__c schedule = [SELECT Id, Name FROM SBQQ__DiscountSchedule__c LIMIT 1];
        schedule.Name = 'RaiseException';
        update schedule;
        List<DebugLog__c> debugLog = [SELECT Id FROM DebugLog__c LIMIT 1];
        System.assertEquals(1, debugLog.size(), 'DML Exception should have been logged in DebugLog__c');
    }

    @isTest 
	static void testDeleteTier() {
		SBQQ__DiscountTier__c tier = [SELECT Id, SBQQ__Discount__c FROM SBQQ__DiscountTier__c LIMIT 1];
		delete tier;
        PricebookEntry pbe = [SELECT Modified__c, Id FROM PricebookEntry LIMIT 1];
		System.assertEquals(true, !(pbe.Modified__c.millisecond() > 0), 'Modified__c should be populated after deleting a tier');
    }
    
    
	@isTest 
	static void testMainException() {
		List<SBQQ__DiscountSchedule__c> schedule = [SELECT Id, Name FROM SBQQ__DiscountSchedule__c LIMIT 1];
        delete schedule; // deleting record, should raise an exception in updatePricebookEntries
		DiscountScheduleTriggerHelper.updatePricebookEntries(schedule);
    }

}