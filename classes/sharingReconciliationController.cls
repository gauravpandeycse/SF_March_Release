public with sharing class sharingReconciliationController 
{
    @AuraEnabled
    public static void execReconciliationBatch(Id recordId) 
    {
        SharingReconciliationBatch b = new SharingReconciliationBatch(recordId);
        Database.executeBatch(b,1);
    }
}