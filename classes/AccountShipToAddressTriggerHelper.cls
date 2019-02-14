/*------------------------------------------------------------
  Author		: Nimil Christopher
  Company		: Salesforce
  Description	: Trigger Helper Class
  Inputs 		: 
  Test Class 	: TestAccountShipToAddressTriggerHelper
  History		: 23/05/2018 created
------------------------------------------------------------*/	
public with sharing class AccountShipToAddressTriggerHelper {
    /*
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Sets the Label of the Picklists - Company and IncoTerms as their api and labels are different
    * Inputs : List<AccountShiptoAddress__c>
    * Test Class : TestSbqqQuoteTrigerHelper.isCompanyLabelCopiedAcrossForInsert()
    * Test Class : TestSbqqQuoteTrigerHelper.isCompanyLabelCopiedAcrossForUpdate()
    * History :
    */
    public static void setLabel(List<AccountShiptoAddress__c> newAccountShiptoAddressList){
        AccountShipToAddress__c shipToAddress = new AccountShipToAddress__c();
        Map<String, String> countryPicklistMap = IMCDUtils.getPickListValues(shipToAddress, 'Country__c');
        for(AccountShiptoAddress__c eachAddress : newAccountShiptoAddressList){
            eachAddress.CountryLabel__c = countryPicklistMap.get(eachAddress.Country__c);
        }        
        System.DEBUG('AddresList : ' + newAccountShiptoAddressList);
    }
}