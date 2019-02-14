/******************************************************************************************************************************************************************
 * Author: Nimil Christopher
 * Company: Salesforce
 * Description: Handler Class for AccountShiptoAddress Trigger
 * Inputs : DB Events
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public class AccountShipToAddressTriggerHandler extends TriggerHandler{
    private List<AccountShiptoAddress__c> oldAccountShiptoAddressList, newAccountShiptoAddressList;
    private Map<ID, AccountShiptoAddress__c> newAccountShiptoAddressMap, oldAccountShiptoAddressMap;

    public AccountShiptoAddressTriggerHandler(){
        oldAccountShiptoAddressList = (List<AccountShiptoAddress__c>) Trigger.old;
        newAccountShiptoAddressList = (List<AccountShiptoAddress__c>) Trigger.new;
        newAccountShiptoAddressMap = (Map<Id, AccountShiptoAddress__c>) Trigger.newMap;
        oldAccountShiptoAddressMap = (Map<Id, AccountShiptoAddress__c>) Trigger.oldMap;
    }

    protected override void beforeInsert(){
        AccountShipToAddressTriggerHelper.setLabel(newAccountShiptoAddressList);
    }

    protected override void beforeUpdate(){
        AccountShipToAddressTriggerHelper.setLabel(newAccountShiptoAddressList);
    }
}