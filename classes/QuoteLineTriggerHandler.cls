/******************************************************************************************************************************************************************
 * Author: Aviad Efergan
 * Company: Salesforce
 * Description: Handler Class for QuoteLine Trigger
 * Inputs : DB Events
 * Test Class :
 * History :
 *      01/10/2018 - SF/JEBU/Instrumented with debugLimits debugging
 *      13-11-2018 - WvB Extra transferStageName call
 * 
 ******************************************************************************************************************************************************************/
public class QuoteLineTriggerHandler extends TriggerHandler{
    private list<SBQQ__QuoteLine__c> oldQtLineLst, newQtLineLst;
    private map<Id,SBQQ__QuoteLine__c> oldQtLineMap, newQtLineMap;

    QuoteLineTriggerHelper2.DoubleProductCheck DoubleProductCheck = new QuoteLineTriggerHelper2.DoubleProductCheck();
   
    public QuoteLineTriggerHandler(){
        this.setMaxLoopCount(100);
        this.oldQtLineLst = (list<SBQQ__QuoteLine__c>) Trigger.old;
        this.newQtLineLst = (list<SBQQ__QuoteLine__c>) Trigger.new;
        this.oldQtLineMap = (map<Id,SBQQ__QuoteLine__c>) Trigger.oldMap;
        this.newQtLineMap = (map<Id,SBQQ__QuoteLine__c>) Trigger.newMap;        
    }
    
    protected override void afterInsert(){
        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][afterInsert][before accountShareBasedQtLine]');
       	QuoteLineTriggerHelper.accountShareBasedQtLine(newQtLineLst);
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][afterInsert][after accountShareBasedQtLine]');
        DoubleProductCheck = QuoteLineTriggerHelper2.checkDoubleProducts(newQtLineMap, false);  // Wim 7-8-18 + 9-11-18
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][afterInsert][after checkDoubleProducts]');
        CpqEnableTriggers.cpqEnableTriggers();
    }

    protected override void beforeInsert(){
        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][beforeInsert][before createPriceBookEntries]');
        CPQAdvancedSearchUtils.createPriceBookEntries(newQtLineLst);
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][beforeInsert][after createPriceBookEntries]');
        QuoteLineTriggerHelper2.updateSetContracted(newQtLineLst, oldQtLineMap);  // Wim 29-8-18
   //     QuoteLineTriggerHelper2.updateQuoteLineFields(newQtLineLst);  // Wim 8-10-18   obsolete 31-10-18     
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][beforeInsert][after updateSetContracted]');
        CpqEnableTriggers.cpqEnableTriggers();
    }
    protected override void afterUpdate(){

        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][afterUpdate][before checkDoubleProducts]');
        DoubleProductCheck = QuoteLineTriggerHelper2.checkDoubleProducts(newQtLineMap, false);  // Wim 7-8-18 + 9-11-18
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][afterUpdate][after checkDoubleProducts]');
        CpqEnableTriggers.cpqEnableTriggers();
    }    
    protected override void beforeUpdate(){

        CpqDisableTriggers.cpqDisableTriggers();
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][beforeUpdate][before updateSetContracted]');
        QuoteLineTriggerHelper2.updateSetContracted(newQtLineLst, oldQtLineMap);  // Wim 22-8-18
  //      QuoteLineTriggerHelper2.updateQuoteLineFields(newQtLineLst);  // Wim 8-10-18    obsolete 31-10-18     
        IMCDUtils.debugLimits('[QuoteLineTriggerHandler][beforeUpdate][after updateSetContracted]');
        CpqEnableTriggers.cpqEnableTriggers();
    }    

    protected override void beforeDelete(){
        QuoteLineTriggerHelper.preventDelete(oldQtLineMap);
        QuoteLineTriggerHelper.preventDeleteIfQtInConPrice(oldQtLineMap);
    }
}