public with sharing class CaseTriggerHandler extends TriggerHandler{
	private List<Case> oldCaseList, newCaseList;
    private Map<ID, Case> newCaseMap, oldCaseMap;
    
    public CaseTriggerHandler(){
        this.setMaxLoopCount(18);  
        oldCaseList = (List<Case>) Trigger.old;
        newCaseList = (List<Case>) Trigger.new;
        newCaseMap = (Map<Id, Case>) Trigger.newMap;
        oldCaseMap = (Map<Id, Case>) Trigger.oldMap;
    }
    
    protected override void beforeInsert(){
        CaseTriggerHelper.setIMCDCompanyLookup(newCaseList);
    }
    
    protected override void beforeUpdate(){
        CaseTriggerHelper.setIMCDCompanyLookup(newCaseList);
    }
}