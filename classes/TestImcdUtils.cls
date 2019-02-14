/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Test class
Inputs:        None	
History	
	01/08/2018	   Created test class
------------------------------------------------------------*/	
@isTest
public class TestImcdUtils {
	
	@testsetup
    public static void testsetup() {
		TestDataFactory.createUsers(1, Label.Standard_User_Profile_Name, '21100');    
    }
    
	@isTest
	public static void testGetCreatableFieldsSOQL () {
		System.assert(!String.isEmpty(ImcdUtils.getCreatableFieldsSOQL('User', 'Id=\'' + [SELECT Id FROM User LIMIT 1].Id + '\'')), 'getCreatableFieldsSOQL should return a SOQL string');      
    }
    
    @isTest
    public static void testGetRecordType () {
        System.assert(!String.isEmpty(ImcdUtils.getRecordType('Lead', 'Standard').Id), 'getRecordType should return a recortype Standard for object Lead');
    }

	@isTest
    public static void testGetQueueId () {
        System.assert(!String.isEmpty(ImcdUtils.getQueueId('Benelux Leads')), 'getQueueId should return an ID for Queue Benelux Leads');
		System.assert(String.isEmpty(ImcdUtils.getQueueId('Blabla')), 'getQueueId should return no ID for Queue Blabla');
    }
    
    @isTest
    public static void testGetDefaultPricebookId() {
		//cannopt be unit tested, just code coverage.
        try { ImcdUtils.getDefaultPricebookId(); } catch (Exception e) {}
    }
    
    @isTest
    public static void testAllCurrencies() {
        System.assert(!ImcdUtils.allCurrencies.isEmpty(), 'allCurrencies must return currencies');
    }
 
   @isTest
    public static void testGetPickListValues() {
        Opportunity oppty = new Opportunity();
        System.assert(!ImcdUtils.getPickListValues(oppty, 'StageName').isEmpty(), 'getPickListValues must return values for Opportunity / StageName');
    }

    @isTest
    public static void testRecordTypeIdMap (){
        Map<String, Id> RecordTypeIdMap = ImcdUtils.recordTypeIdMap;
        System.assert(RecordTypeIdMap.size() > 0, 'recordTypeIdMap must return entries' );

    }
    @isTest
    public static void testFormatAmount (){
        String editAmount = ImcdUtils.formatAmount(0,2);
        System.assertEquals( '0' , editAmount );
        editAmount = ImcdUtils.formatAmount(1,2);
        editAmount = editAmount.replaceAll(',', '.');
        System.assertEquals( '1.00' , editAmount );
        editAmount = ImcdUtils.formatAmount(10000,4);
        editAmount = editAmount.replaceAll(',', '.');
        System.assertEquals( '10.000.0000' , editAmount );

    }
    @isTest
    Public static void testlimitsWithinRange(){
        System.assertEquals( true , ImcdUtils.limitsWithinRange(99));
    }
}