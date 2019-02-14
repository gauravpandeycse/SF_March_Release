/******************************************************************************************************************************************************************
 * Author: Aviad Efergan
 * Company: Salesforce
 * Description: Handler Class for Opportunity Line Item Trigger
 * Inputs : DB Events
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public class OpportunityLineItemTriggerHandler extends TriggerHandler{
	private list<OpportunityLineItem> oldOppLineItemLst, newOppLineItemLst;
    private map<Id, OpportunityLineItem> oldOppLineItemMap, newOppLineItemMap;
   
	public OpportunityLineItemTriggerHandler(){
    	this.setMaxLoopCount(20); // extended to avoid to early loop-error Wim van Beek
		this.oldOppLineItemLst = (list<OpportunityLineItem>) Trigger.old;
        this.newOppLineItemLst = (list<OpportunityLineItem>) Trigger.new;
        this.oldOppLineItemMap = (map<Id, OpportunityLineItem>) Trigger.oldMap;
        this.newOppLineItemMap = (map<Id, OpportunityLineItem>) Trigger.newMap;
        
    }
    
    protected override void afterInsert(){
	    CpqDisableTriggers.cpqDisableTriggers();
	    IMCDUtils.debugLimits('[OpportunityLineItemTriggerHandler][afterInsert][before accountShareBasedOppLineItem]');
	    OpportunityLineItemTriggerHelper.accountShareBasedOppLineItem(newOppLineItemLst);
	    IMCDUtils.debugLimits('[OpportunityLineItemTriggerHandler][afterInsert][after accountShareBasedOppLineItem]');
	    CpqEnableTriggers.cpqEnableTriggers();
    }
}