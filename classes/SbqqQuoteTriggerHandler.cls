/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Handler class SBQQ__Quote__c Trigger
 * Inputs :
 * Test Class :
 * History :
 *   Wim van Beek 29-6-2018 Changed SbqqQuoteTriggerHelper.countNrOfQuotes(newQuoteList) from afterinsert to beforeinsert
 *   SF/JEBU/021018/Added debugLimits instrumentation
 *   Wim van Beek 30-10-18 Deleted SbqqQuoteTriggerHelper.countNrOfQuotes(newQuoteList) 
 ******************************************************************************************************************************************************************/
public with sharing class SbqqQuoteTriggerHandler  extends TriggerHandler
{
    private List<SBQQ__Quote__c> oldQuoteList, newQuoteList;
    private Map<ID, SBQQ__Quote__c> newQuoteMap, oldQuoteMap;

    public SbqqQuoteTriggerHandler()
    {
        this.setMaxLoopCount(40);  // Increased to 40 for use in PRC  Wim van Beek Nov18
        
        oldQuoteList = (List<SBQQ__Quote__c>) Trigger.old;
        newQuoteList = (List<SBQQ__Quote__c>) Trigger.new;
        newQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
        oldQuoteMap = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
    }


    protected override void beforeInsert()
    {
        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeInsert][before setIMCDCompanyLookup]');
        SbqqQuoteTriggerHelper.setIMCDCompanyLookup(newQuoteList);
        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeInsert][after setIMCDCompanyLookup]');
        SbqqQuoteTriggerHelper.setLabel(newQuoteList);
   //     IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeInsert][after setLabel]');
   //     SbqqQuoteTriggerHelper.countNrOfQuotes(newQuoteList);   // Obsolite 30-10-18 WvB
   //     IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeInsert][after countNrOfQuotes]');
        CpqEnableTriggers.cpqEnableTriggers();
    }

    protected override void afterInsert()
    {
        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][afterInsert][before QuoteAndAccSharingBasedLOB]');
        SbqqQuoteTriggerHelper.QuoteAndAccSharingBasedLOB(newQuoteList);
        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][afterInsert][after QuoteAndAccSharingBasedLOB]');
        CpqEnableTriggers.cpqEnableTriggers();
    }

    protected override void beforeUpdate()
    {
        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeUpdate][before setIMCDCompanyLookup]');
        SbqqQuoteTriggerHelper.setIMCDCompanyLookup(newQuoteList);
        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeUpdate][after setIMCDCompanyLookup]');
        SbqqQuoteTriggerHelper.setLabel(newQuoteList);

        IMCDUtils.debugLimits('[SbqqQuoteTriggerHandler][beforeUpdate][after setLabel]');
        CpqEnableTriggers.cpqEnableTriggers();
    }

    protected override void afterUpdate()
    {

        QuoteLineTriggerHelper2.checkDoubleProducts(oldQuoteMap, newQuoteMap);  // new WvB 9-11-18

         SbqqQuoteTriggerHelper.updateQuoteAndAccSharingBasedLOB(oldQuoteMap, newQuoteList);
 //      SbqqQuoteTriggerHelper.countNrOfQuotes(newQuoteList);  // Optional 
    }
}