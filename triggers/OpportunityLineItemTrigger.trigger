/******************************************************************************************************************************************************************
 * Author: Aviad Efergan
 * Company: Salesforce
 * Description: Opp Line Item object Trigger
 * Inputs : DB events
 * Test Class :
 * History : 
 ******************************************************************************************************************************************************************/

trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    new OpportunityLineItemTriggerHandler().run();
}