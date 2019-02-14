/*------------------------------------------------------------
  Author		: Jeroen Burgers
  Company		: Salesforce
  Description	: SBQQ__DiscountSchedule__c object Trigger
  Inputs 		: Trigger events
  Test Class 	:
  History		: 23/05/2018 created
------------------------------------------------------------*/	
trigger DiscountScheduleTrigger on SBQQ__DiscountSchedule__c (before insert,
																before update,
																before delete,
																after insert,
																after update,
																after delete,
																after undelete) {
    new DiscountScheduleTriggerHandler().run();
}