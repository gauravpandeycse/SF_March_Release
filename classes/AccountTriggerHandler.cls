/******************************************************************************************************************************************************************
 * Author: Nimil Christopher
 * Company: Salesforce
 * Description: Handler Class for Account Trigger
 * Inputs : DB Events
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public class AccountTriggerHandler extends TriggerHandler{

    private List<Account> oldAccountList, newAccountList;
    private Map<ID, Account> newAccountMap, oldAccountMap;

    public AccountTriggerHandler(){
        oldAccountList = (List<Account>) Trigger.old;
        newAccountList = (List<Account>) Trigger.new;
        newAccountMap = (Map<Id, Account>) Trigger.newMap;
        oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
    }

    protected override void beforeInsert(){
        AccountTriggerHelper.setLabel(newAccountList);
    }

    protected override void beforeUpdate(){
        AccountTriggerHelper.setLabel(newAccountList);
    }
}