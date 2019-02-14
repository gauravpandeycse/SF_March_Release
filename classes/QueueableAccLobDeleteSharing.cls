/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for deleting Sharing based on AccountLob records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >
* Test Class : TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableAccLobDeleteSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

    public QueueableAccLobDeleteSharing(Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap,
                                        Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap)
    {
        this.lob1toSharingAccessNoPrincipalMap = lob1toSharingAccessNoPrincipalMap;
        this.globalSharingAccessesNoPrincipalMap = globalSharingAccessesNoPrincipalMap;
        this.lob1toSharingAccessPrincipalMap = lob1toSharingAccessPrincipalMap;
        this.globalSharingAccessesPrincipalMap = globalSharingAccessesPrincipalMap;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
            if(!lob1toSharingAccessNoPrincipalMap.isEmpty())
            {
                Map<Id, List<SharingAccess__c>> accsToShareAccsMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, Set<Id>> accIdsToUsrIds = new Map<Id, Set<Id>>();

                Set<String> imcdCompNames = new Set<String>();
                for(map<String, list<SharingAccess__c>> imcdCompanyToShareAccess : lob1toSharingAccessNoPrincipalMap.values())
                {
                    imcdCompNames.addAll(imcdCompanyToShareAccess.keySet());
                }
                
                List<AccountLob__c> shareAccLobList = new List<AccountLob__c>([
                        SELECT Id, LOB1__c, Account__c, Account__r.IMCDCompany__c, Account__r.ParentId
                        FROM AccountLob__c
                        WHERE (LOB1__c IN :lob1toSharingAccessNoPrincipalMap.keySet() AND Account__r.IMCDCompany__c IN : imcdCompNames)]);

                if(!shareAccLobList.isEmpty())
                {
                    List<AccountShare> accShareToDelete = new List<AccountShare>() ;
                    //aggregating the Sharing access records related to previously deleted LOB Classifications Records
                    SharingUtils.aggregateRecordsToDelete(QueueableAccLobDeleteSharing.class.getName(), shareAccLobList, lob1toSharingAccessNoPrincipalMap, accsToShareAccsMap, globalSharingAccessesNoPrincipalMap);

                    if(!accsToShareAccsMap.isEmpty())
                    {//mapping the users that we need to delete from sharing of Sold To, Regional Accounts
                        SharingUtils.mapSharedUsersToRelObject(accsToShareAccsMap, accIdsToUsrIds);
                        for(AccountShare acShare : SharingUtils.getAccountShares(accIdsToUsrIds,Label.MANUAL_RAW_CAUSE))
                        {
                            if(accIdsToUsrIds.get(acShare.AccountId).contains(acShare.userOrGroupID) )
                            {
                                accShareToDelete.add(acShare);
                            }
                        }
                    }
                    if(!accShareToDelete.isEmpty())
                    {
                        /*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                        next queueable to get fresh set of limits*/
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToDelete,accSharepassedToQueueble, false);
                    }
                }
            }
            system.debug('+++QueueableAccLobDeleteSharing getHeapSize()'+ Limits.getHeapSize());
            //Delete Sharing Accounts and Opps based on Opportunities
            QueueableOppDeleteSharing deleteAccAndOppSharesBasedOppJob = new QueueableOppDeleteSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap,
                                                                                                      lob1toSharingAccessPrincipalMap,globalSharingAccessesPrincipalMap,accSharepassedToQueueble);
            if(!Test.isRunningTest())
            {
                System.enqueueJob(deleteAccAndOppSharesBasedOppJob);
            }
        }
        catch (Exception ex)
        {
            DebugLog.addException(ex, 'QueueableAccLobDeleteSharing') ;
        }
    }
}