/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: SharingAccess__c object Trigger
 * Inputs : DB events
 * Test Class :
 * History : 21/03/18 created
 ******************************************************************************************************************************************************************/

trigger AccountLobTrigger on AccountLob__c (
                                            before insert,
                                            before update,
                                            before delete,
                                            after insert,
                                            after update,
                                            after delete,
                                            after undelete)
{
    new AccountLobTriggerHandler().run();
}