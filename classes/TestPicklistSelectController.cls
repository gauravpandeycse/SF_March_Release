@isTest
private class TestPicklistSelectController {

    @isTest
    static void test_get_field_label() {
		Test.startTest();
        String fieldLabel = PicklistSelectController.getFieldLabel( 'Account', 'Type' );
        Test.stopTest();
        System.assertEquals( Account.Type.getDescribe().getLabel(), fieldLabel );
    }
    
    @isTest
    static void test_get_picklist_values() {
		List<Account> testSoldToAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '21100');
        Test.startTest();
        List<PicklistSelectController.PicklistOption> options = PicklistSelectController.getPicklistOptions('Account', 'Type', testSoldToAccounts[0].Id);
        Test.stopTest();
        
        List<PicklistEntry> values = Account.Type.getDescribe().getPicklistValues();

        for ( Integer i = 1 ; i < options.size(); i++ ) {
            System.assertEquals( values[i-1].getLabel(), options[i].label );
            System.assertEquals( values[i-1].getValue(), options[i].value );
        }
        
    }

    @isTest
    static void test_get_picklist_values_without_recordid () {
        Test.startTest();
        List<PicklistSelectController.PicklistOption> options = PicklistSelectController.getPicklistOptions('Account', 'Type', '');
        Test.stopTest();

        List<PicklistEntry> values = Account.Type.getDescribe().getPicklistValues();

        for ( Integer i = 1 ; i < options.size(); i++ ) {
            System.assertEquals( values[i-1].getLabel(), options[i].label );
            System.assertEquals( values[i-1].getValue(), options[i].value );
        }
    }
    
}