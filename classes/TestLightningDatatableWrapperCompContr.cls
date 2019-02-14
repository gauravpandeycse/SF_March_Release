/*------------------------------------------------------------
Author:        Moa Hultin & Kevin Ruibin Do (Salesforce)
Company:       Salesforce
User Story:    https://imcdgroup.atlassian.net/browse/SFDP-904
Description:   Test class for the LightningDatatableWrapperCompController
History
	15/11/2018     Created class
------------------------------------------------------------*/
@IsTest
private class TestLightningDatatableWrapperCompContr {
	static List<String> testLstFields = new List<String>();

	@testSetup static void setup() {
		Account testAccount = new Account(Name='Moas account', Phone='02739685765', IntegrationId__c='123');
		insert testAccount;
		List<Contact> lstTestContact = TestDataFactory.returnContacts(1);
		lstTestContact[0].AccountId = [SELECT Id FROM Account LIMIT 1].Id;
		insert lstTestContact;
	}

	@IsTest
	public static void testSetup() {
		System.assertEquals( true , [SELECT Id FROM Account LIMIT 1].size() > 0, 'One Account should be created in the setup.');
		System.assertEquals( true , [SELECT Id FROM Contact LIMIT 1].size() > 0, 'One Contact should be created in the setup.');
	}

	@IsTest
	public static void testColumnTypes() {
		String res = LightningDatatableWrapperCompController.getSObjectColumns([SELECT Name, Phone FROM Account LIMIT 1], testLstFields, true, true);
		System.debug(res);
		System.assertEquals( true , res.containsIgnoreCase('"type":"phone"')
				&& res.containsIgnoreCase('"type":"text"'), 'Not the expected column-types returned');
	}

	@isTest
	public static void testFieldOrder() {
		testLstFields.add('Phone');
		testLstFields.add('Name');
		String res = LightningDatatableWrapperCompController.getSObjectColumns([SELECT Name, Phone FROM Account LIMIT 1], testLstFields, true, true);
		//RegEx (.)* means any number of any character
		System.assert(Pattern.matches('(.)*"fieldName":"Phone"(.)*"fieldName":"Name"(.)*', res), 'Returned columns should be in the order of Name then Phone');
	}

	@IsTest
	public static void testHideIdFieldTrue() {
		String res = LightningDatatableWrapperCompController.getSObjectColumns([SELECT Id, Name, Phone FROM Account LIMIT 1], testLstFields, true, false);
		System.assertEquals( false , res.containsIgnoreCase('Id'), 'Columns should not contain id field');
	}

	@IsTest
	public static void testHideReferenceFieldTrue() {
		String res = LightningDatatableWrapperCompController.getSObjectColumns([SELECT Id, AccountId, Phone FROM Contact LIMIT 1], testLstFields, false, true);
		System.assertEquals( false , res.containsIgnoreCase('Reference'), 'Returned columns should not contain any reference fields');
		System.assertEquals( true , res.containsIgnoreCase('Id'), 'Returned columns should contain the Id field');
	}

	@isTest
	public static void testHideSoftReferenceFields() {
		String res = LightningDatatableWrapperCompController.getSObjectColumns([SELECT Name, Phone, IntegrationId__c FROM Account LIMIT 1], testLstFields, false, true);
		System.assert(!res.containsIgnoreCase('IntegrationId__c'), 'Returned columns should not contain any soft reference fields with fieldName ending with "Id__c"');
	}

	@IsTest
	public static void testNumberOfColumns() {
		String res = LightningDatatableWrapperCompController.getSObjectColumns([SELECT Name, Phone FROM Account LIMIT 1], testLstFields, false, false);
		System.assertEquals( 3, res.toLowerCase().countMatches('"type":'), 'Not returning the expected number of columns');
	}
}