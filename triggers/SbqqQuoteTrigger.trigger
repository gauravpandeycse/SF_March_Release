/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: SBQQ_Quote object Trigger
 * Inputs : DB events
 * Test Class :
 * History : 17/04/18 created
 ******************************************************************************************************************************************************************/
trigger SbqqQuoteTrigger on SBQQ__Quote__c (
before insert,
before update,
before delete,
after insert,
after update,
after delete,
after undelete)
{
    new SbqqQuoteTriggerHandler ().run();
}