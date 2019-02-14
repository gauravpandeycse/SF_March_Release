/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Handler Class SharingAccess__c Trigger
 * Inputs :
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public with sharing class SharingAccessTriggerHandler extends TriggerHandler
{
    private List<SharingAccess__c> oldSharingAccessList, newSharingAccessList;
    private Map<ID, SharingAccess__c> newSharingAccessMap, oldSharingAccessMap;

    public SharingAccessTriggerHandler()
    {
        this.setMaxLoopCount(8);
        oldSharingAccessList = (List<SharingAccess__c>) Trigger.old;
        newSharingAccessList = (List<SharingAccess__c>) Trigger.new;
        newSharingAccessMap = (Map<Id, SharingAccess__c>) Trigger.newMap;
        oldSharingAccessMap = (Map<Id, SharingAccess__c>) Trigger.oldMap;
    }

    protected override void afterInsert()
    {
        SharingAccessTriggerHelper.updateRecordName(newSharingAccessList);
        SharingAccessTriggerHelper.recalculateOnInsertSharing(newSharingAccessList);
    }

    protected override void afterDelete()
    {
        SharingAccessTriggerHelper.recalculateOnDeleteSharing(oldSharingAccessList);
    }
}