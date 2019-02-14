/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Opportunity object Trigger
 * Inputs : DB events
 * Test Class :
 * History : 15/04/18 created
 ******************************************************************************************************************************************************************/

trigger OpportunityTrigger on Opportunity (
before insert,
before update,
before delete,
after insert,
after update,
after delete,
after undelete)
{
    new OpportunityTriggerHandler().run();
}