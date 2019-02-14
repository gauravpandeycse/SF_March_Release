/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Handler Class for AccountLob Trigger
 * Inputs : DB Events
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public with sharing class AccountLobTriggerHandler extends TriggerHandler
{
    private List<AccountLob__c> oldAccountLobList, newAccountLobList;
    private Map<ID, AccountLob__c> newAccountLobMap, oldAccountLobMap;

    public AccountLobTriggerHandler() 
    {
        this.setMaxLoopCount(6);
        oldAccountLobList = (List<AccountLob__c>) Trigger.old;
        newAccountLobList = (List<AccountLob__c>) Trigger.new;
        newAccountLobMap = (Map<Id,AccountLob__c>) Trigger.newMap;
        oldAccountLobMap = (Map<Id,AccountLob__c>) Trigger.oldMap;
    }
    
    protected override void beforeInsert()
    {
		AccountLobTriggerHelper.setUniqueField(newAccountLobList);
    }

    protected override void afterInsert()
    {
        AccountLobTriggerHelper.accountShareBasedLOB(newAccountLobList);
        AccountLobTriggerHelper.validateLOBUpdate(newAccountLobMap);
    }
    
    protected override void beforeUpdate()
    {
		AccountLobTriggerHelper.setUniqueField(newAccountLobList);
    }
    
    protected override void afterUpdate()
    {
        AccountLobTriggerHelper.validateLOBUpdate(newAccountLobMap);
    }
    
    protected override void beforeDelete()
    {
        AccountLobTriggerHelper.validateLOBDelete(oldAccountLobMap);
    }
    protected override void afterDelete()
    {
        AccountLobTriggerHelper.deleteAccountShareOnLOBDelete(oldAccountLobList);
    }
}