/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: recalculates custom sharing for given list of sharingAccess records
* Inputs : Boolean, List<ID>
* Test Class :
* History :
******************************************************************************************************************************************************************/
global class SharingReconciliationBatch implements Database.Batchable<SObject>
{
    private Id sharingRecordId;

    public SharingReconciliationBatch(Id recordId)
    {
        sharingRecordId = recordId ;
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator([SELECT Id, Global__c, IMCDCompany__c, PrincipalId__c, UserId__c, LOB1__c
                                         FROM SharingAccess__c
                                         WHERE Id =: sharingRecordId LIMIT 1 ]);
    }

    global void execute(Database.BatchableContext BC, List<SharingAccess__c> scope)
    {
        SharingAccessTriggerHelper.recalculateOnInsertSharing(scope);
    }

    global void finish(Database.BatchableContext BC)
    {
		update(new SharingAccess__c(Id = sharingRecordId, lastSharingReconciliationDate__c = Datetime.now()));
    }
}