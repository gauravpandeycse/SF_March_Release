/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: trigger Handler Opportunity Trigger
 * Inputs :
 * Test Class :
 * History :
 * 	30/07/2018 - JEBU. Added beforeUpdate handler method calling validateStageTransition() method
 ******************************************************************************************************************************************************************/

public with sharing class OpportunityTriggerHandler extends TriggerHandler
{
    private List<Opportunity> oldOpportunityList, newOpportunityList;
    private Map<ID, Opportunity> newOpportunityMap, oldOpportunityMap;

    public OpportunityTriggerHandler()
    {
        this.setMaxLoopCount(18);
        oldOpportunityList = (List<Opportunity>) Trigger.old;
        newOpportunityList = (List<Opportunity>) Trigger.new;
        newOpportunityMap = (Map<Id,Opportunity>) Trigger.newMap;
        oldOpportunityMap = (Map<Id,Opportunity>) Trigger.oldMap;
    }

    protected override void afterInsert()
    {
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][afterInsert][before OppAndAccSharingBasedLOB]');
        OpportunityTriggerHelper.OppAndAccSharingBasedLOB(newOpportunityList);
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][afterInsert][after OppAndAccSharingBasedLOB]');
    }

    protected override void afterUpdate()
    {
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][afterUpdate][before updateOppAndAccSharingBasedLOB]');
        OpportunityTriggerHelper.updateOppAndAccSharingBasedLOB(oldOpportunityMap, newOpportunityList);
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][afterUpdate][after updateOppAndAccSharingBasedLOB]');
        OpportunityTriggerHelper.checkAccountIsChangedOnOpportunity(oldOpportunityMap, newOpportunityMap);
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][afterUpdate][after checkAccountIsChangedOnOpportunity]');
        OpportunityTriggerHelper.transferStageName(oldOpportunityMap, newOpportunityMap);
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][afterUpdate][after transferStageName]');
    }
    
    protected override void beforeUpdate()
    {
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][beforeUpdate][before validateStageTransition]');
        OpportunityTriggerHelper.validateStageTransition(oldOpportunityMap, newOpportunityMap);
        IMCDUtils.debugLimits('[OpportunityTriggerHandler][beforeUpdate][after validateStageTransition]');
    }

}