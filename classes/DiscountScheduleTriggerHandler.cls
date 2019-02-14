/*------------------------------------------------------------
  Author		: Jeroen Burgers
  Company		: Salesforce
  Description	: SBQQ__DiscountSchedule__c trigger handler class
  Inputs 		: 
  Test Class 	:
  History		: 23/05/2018 created
------------------------------------------------------------*/	
public with sharing class DiscountScheduleTriggerHandler extends TriggerHandler {
    
	private List<SBQQ__DiscountSchedule__c> oldDiscountScheduleList, newDiscountScheduleList;
	private Map<ID, SBQQ__DiscountSchedule__c> newDiscountScheduleMap, oldDiscountScheduleMap;

	public DiscountScheduleTriggerHandler() {
		this.setMaxLoopCount(5);
		oldDiscountScheduleList = (List<SBQQ__DiscountSchedule__c>) Trigger.old;
		newDiscountScheduleList = (List<SBQQ__DiscountSchedule__c>) Trigger.new;
		newDiscountScheduleMap = (Map<Id,SBQQ__DiscountSchedule__c>) Trigger.newMap;
		oldDiscountScheduleMap = (Map<Id,SBQQ__DiscountSchedule__c>) Trigger.oldMap;
	}

    protected override void afterInsert() {
        DiscountScheduleTriggerHelper.updatePricebookEntries (newDiscountScheduleList);
	}

	protected override void afterUpdate() {
        DiscountScheduleTriggerHelper.updatePricebookEntries (oldDiscountScheduleList, newDiscountScheduleList);
	}
    
	protected override void afterDelete() {
		DiscountScheduleTriggerHelper.updatePricebookEntries (oldDiscountScheduleList);
	}
}