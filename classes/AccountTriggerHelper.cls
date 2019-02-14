/*------------------------------------------------------------
  Author		: Nimil Christopher
  Company		: Salesforce
  Description	: Trigger Helper Class
  Inputs 		: 
  Test Class 	: TestAccountTriggerHelper
  History		: 23/05/2018 created
------------------------------------------------------------*/	
public with sharing class AccountTriggerHelper {
    /*
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Sets the Label of the Picklists - BillingCountry(Postal) and ShippingCountry(Main) as their api and labels are different
    * Inputs : List<Account>
    * Test Class : TestAccountTriggerHelper.isCompanyLabelCopiedAcrossForInsert()
    * Test Class : TestAccountTriggerHelper.isCompanyLabelCopiedAcrossForUpdate()
    * History :
    */
    public static void setLabel(List<Account> newAccountList){
        Account account = new Account();
        Map<String, String> countryPicklistMap = IMCDUtils.getPickListValues(account, 'BillingCountryCode');
        System.DEBUG('Country Picklist : ' + countryPicklistMap);
        for(Account eachAddress : newAccountList){
            eachAddress.BillingCountryLabel__c = countryPicklistMap.get(eachAddress.BillingCountryCode);
            eachAddress.ShippingCountryLabel__c = countryPicklistMap.get(eachAddress.ShippingCountryCode);
        }        
        System.DEBUG('AddresList : ' + newAccountList);
    }
}