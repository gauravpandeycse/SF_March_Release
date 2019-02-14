/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for deleting Sharing based on Quote records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<String, Map <String, List<SharingAccess__c> > >,
* Map<String, List<SharingAccess__c> >, List<AccountShare>, List<OpportunityShare>
* Test Class : TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableQuoteDeleteSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();

    public QueueableQuoteDeleteSharing(Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap,
                                       Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap,Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap,
                                        List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppSharepassedToQueueble)
    {
        this.lob1toSharingAccessNoPrincipalMap = lob1toSharingAccessNoPrincipalMap;
        this.globalSharingAccessesNoPrincipalMap = globalSharingAccessesNoPrincipalMap;
        this.lob1toSharingAccessPrincipalMap = lob1toSharingAccessPrincipalMap;
        this.globalSharingAccessesPrincipalMap = globalSharingAccessesPrincipalMap;
        this.accSharepassedToQueueble = accSharepassedToQueueble;
        this.oppSharepassedToQueueble = oppSharepassedToQueueble;

    }

    public void execute(QueueableContext context)
    {
        try
        {
            List<SBQQ__Quote__Share> qtSharepassedToQueueble = new List<SBQQ__Quote__Share>() ;
            if (!lob1toSharingAccessNoPrincipalMap.isEmpty())
            {
                Map<Id, List<SharingAccess__c>> accsToShareAccsMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, List<SharingAccess__c>> quotesToShareAccessMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, Set<Id>> accIdsToUsrIds = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> quotesIdsToUsrIds = new Map<Id, Set<Id>>();

                Set<String> imcdCompNames = new Set<String>();
                for(map<String, list<SharingAccess__c>> imcdCompanyToShareAccess : lob1toSharingAccessNoPrincipalMap.values())
                {
                    imcdCompNames.addAll(imcdCompanyToShareAccess.keySet());
                }
                List<SBQQ__Quote__c> shareQuoteList = new List<SBQQ__Quote__c>([
                        SELECT Id, LOB1__c, SBQQ__Account__c, SBQQ__Account__r.IMCDCompany__c, SBQQ__Account__r.ParentId
                        FROM SBQQ__Quote__c
                        WHERE LOB1__c IN :lob1toSharingAccessNoPrincipalMap.keySet()
                        AND SBQQ__Account__r.IMCDCompany__c IN : imcdCompNames]);

                if (!shareQuoteList.isEmpty())
                {
                    List<AccountShare> accShareToDelete = new List<AccountShare>() ;
                    List<SBQQ__Quote__Share> quoteShareToDelete = new List<SBQQ__Quote__Share>() ;
                    //aggregating the Sharing access records related to previously deleted LOB Classifications Records
                    SharingUtils.aggregateRecordsToDelete(shareQuoteList, lob1toSharingAccessNoPrincipalMap, accsToShareAccsMap, quotesToShareAccessMap, globalSharingAccessesNoPrincipalMap);

                    if (!accsToShareAccsMap.isEmpty())
                    {   //mapping the users that we need to delete from sharing of Sold To, Regional Accounts
                        SharingUtils.mapSharedUsersToRelObject(accsToShareAccsMap, accIdsToUsrIds);
                        SharingUtils.mapSharedUsersToRelObject(quotesToShareAccessMap, quotesIdsToUsrIds);

                        for (AccountShare acShare : SharingUtils.getAccountShares(accIdsToUsrIds,Label.MANUAL_RAW_CAUSE))
                        {
                            if (accIdsToUsrIds.get(acShare.AccountId).contains(acShare.userOrGroupID) )
                            {
                                accShareToDelete.add(acShare);
                            }
                        }
                        for (SBQQ__Quote__Share quoteShare : SharingUtils.getquoteShares(quotesIdsToUsrIds, Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c))
                        {
                            if (quotesIdsToUsrIds.get(quoteShare.ParentId).contains(quoteShare.userOrGroupID) )
                            {
                                quoteShareToDelete.add(quoteShare);
                            }
                        }
                    }
                    if (!accShareToDelete.isEmpty() || !quoteShareToDelete.isEmpty())
                    {
                        /*if we are going to hit DML limit pass half of the value to
                        next queueable to get fresh set of limits*/
                        if(accSharepassedToQueueble.size() > 0 )
                        {
                            SharingUtils.combineRemainAndSharingList(accShareToDelete,accSharepassedToQueueble);
                        }
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToDelete,accSharepassedToQueueble, oppSharepassedToQueueble, quoteShareToDelete, qtSharepassedToQueueble,false);
                    }
                    else if(accShareToDelete.isEmpty() && quoteShareToDelete.isEmpty())
                    {
                        if (accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0)
                        {
                            SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, oppSharepassedToQueueble, true);
                        }
                    }
                }
            }
            system.debug('+++QueueableQuoteDeleteSharing getHeapSize()'+ Limits.getHeapSize());
            if(!lob1toSharingAccessPrincipalMap.isEmpty() && !Test.isRunningTest())
            {
                //Delete Sharing Accounts and Opps based on OpportunityLineItems
                QueueablePrincipalOppDeleteSharing deleteAccAndOppSharesBasedOppLineJob = new QueueablePrincipalOppDeleteSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap,
                                                                                                        accSharepassedToQueueble,oppSharepassedToQueueble,qtSharepassedToQueueble);
                System.enqueueJob(deleteAccAndOppSharesBasedOppLineJob);
            }
        }
        catch (Exception ex)
        {
            DebugLog.addException(ex, 'QueueableQuoteDeleteSharing') ;
        }
    }
}