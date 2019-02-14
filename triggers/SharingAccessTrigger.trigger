/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: SharingAccess__c object Trigger
 * Inputs : DB events
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
trigger SharingAccessTrigger on SharingAccess__c (  before insert,
                                                    before update,
                                                    before delete,
                                                    after insert,
                                                    after update,
                                                    after delete,
                                                    after undelete)
{
    new SharingAccessTriggerHandler().run();
}