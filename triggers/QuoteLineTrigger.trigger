/******************************************************************************************************************************************************************
 * Author: Aviad Efergan
 * Company: Salesforce
 * Description: SBQQ__QuoteLine__c object Trigger
 * Inputs : DB events
 * Test Class :
 * History : 
 ******************************************************************************************************************************************************************/
trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, 
                                              before update, 
                                                before delete, 
                                                after insert, 
                                                after update, 
                                                after delete, 
                                                after undelete){
    new QuoteLineTriggerHandler().run();
}