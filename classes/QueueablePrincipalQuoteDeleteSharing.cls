/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for deleting on Account and Opportunity Sharing based on QuoteLineItems records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<String, Map <String, List<SharingAccess__c> > >,
* Map<String, List<SharingAccess__c> >, List<AccountShare>, List<OpportunityShare>, List<SBQQ__Quote__Share>
* Test Class : TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueablePrincipalQuoteDeleteSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();
    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();
    List<SBQQ__Quote__Share> qtSharepassedToQueueble = new List<SBQQ__Quote__Share>();

    public QueueablePrincipalQuoteDeleteSharing(Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap,
            List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble)
    {
        this.lob1toSharingAccessPrincipalMap = lob1toSharingAccessPrincipalMap;
        this.globalSharingAccessesPrincipalMap = globalSharingAccessesPrincipalMap;
        this.accSharepassedToQueueble = accSharepassedToQueueble;
        this.oppSharepassedToQueueble = oppSharepassedToQueueble;
        this.qtSharepassedToQueueble = qtSharepassedToQueueble;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            if(!lob1toSharingAccessPrincipalMap.isEmpty())
            {
                Map<Id, List<SharingAccess__c>> accsToShareAccsMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, List<SharingAccess__c>> quotesToShareAccessMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, Set<Id>> accIdsToUsrIds = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> quotesIdsToUsrIds = new Map<Id, Set<Id>>();

                Set<String> imcdCompNames = new Set<String>();

                //get the relevant IMCD Company Id to agregate the right records for deletion and avoid 50000 DML limit
                for(Map<String, List<SharingAccess__c>> imcdCompanyToShareAccess : lob1toSharingAccessPrincipalMap.values())
                {
                    imcdCompNames.addAll(imcdCompanyToShareAccess.keySet());
                }

                Set<Id> globalPrincipals = new Set<Id>();
                Set<Id> imcdCompPrincipals = new Set<Id>();
                Set<String> imcdCompEmptyLobNames = new Set<String>();
                Set<Id> globalPrincipalsForLob = new Set<Id>();

                //get the relevant principals Id and IMCD company to agregate the right records for deletion and avoid 50000 DML limit
                if(lob1toSharingAccessPrincipalMap.containsKey('empty_lob'))
                {
                    for(String imcdComp : lob1toSharingAccessPrincipalMap.get('empty_lob').keySet() )
                    {
                        for(SharingAccess__c sa : lob1toSharingAccessPrincipalMap.get('empty_lob').get(imcdComp))
                        {
                            imcdCompPrincipals.add(sa.PrincipalId__c);
                            imcdCompEmptyLobNames.add(sa.IMCDCompany__c);
                        }
                    }
                }
                //get the relevant principals Id to agregate the right records for deletion and avoid 50000 DML limit
                if(globalSharingAccessesPrincipalMap.containsKey('empty_lob_global'))
                {
                    for(SharingAccess__c sa : globalSharingAccessesPrincipalMap.get('empty_lob_global'))
                    {
                        globalPrincipals.add(sa.PrincipalId__c);
                    }
                }

                //get the relevant principals Id to agregate the right records for deletion and avoid 50000 DML limit
                for(List<SharingAccess__c> saList : globalSharingAccessesPrincipalMap.values() )
                {
                    for(SharingAccess__c sa : saList)
                    {
                        globalPrincipalsForLob.add(sa.PrincipalId__c);
                    }
                }

                List<SBQQ__QuoteLine__c> ShareQuoteLineItemLst = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.LOB1__c, SBQQ__Product__r.Principal__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, SBQQ__Quote__r.SBQQ__Account__r.ParentId
                FROM SBQQ__QuoteLine__c
                WHERE (SBQQ__Quote__r.LOB1__c IN : lob1toSharingAccessPrincipalMap.keySet() AND  SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c IN : imcdCompNames) // UC6 lob + company
                OR (SBQQ__Quote__r.LOB1__c IN : globalSharingAccessesPrincipalMap.keySet() AND SBQQ__Product__r.Principal__c IN : globalPrincipalsForLob) // UC2 lob + global
                OR (SBQQ__Product__r.Principal__c IN : imcdCompPrincipals AND SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c IN : imcdCompEmptyLobNames) //UC5 empty lob + company
                OR (SBQQ__Product__r.Principal__c IN : globalPrincipals)];
                if (!ShareQuoteLineItemLst.isEmpty())
                {
                    List<AccountShare> accShareToDelete = new List<AccountShare>() ;
                    List<SBQQ__Quote__Share> quoteShareToDelete = new List<SBQQ__Quote__Share>() ;
                    //aggregating the Sharing access records related to previously deleted LOB Classifications Records
                    SharingUtils.aggregateRecordsToDelete(ShareQuoteLineItemLst, lob1toSharingAccessPrincipalMap, accsToShareAccsMap, quotesToShareAccessMap, globalSharingAccessesPrincipalMap);

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
                        for (SBQQ__Quote__Share quoteShare : SharingUtils.getQuoteShares(quotesIdsToUsrIds,Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c))
                        {
                            if (quotesIdsToUsrIds.get(quoteShare.ParentId).contains(quoteShare.userOrGroupID) )
                            {
                                quoteShareToDelete.add(quoteShare);
                            }
                        }
                    }
                    if (!accShareToDelete.isEmpty() || !quoteShareToDelete.isEmpty())
                    {
                        /*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                        next queueable to get fresh set of limits*/
                        SharingUtils.combineRemainAndSharingList(accShareToDelete,accSharepassedToQueueble);
                        SharingUtils.combineRemainAndSharingList(quoteShareToDelete,qtSharepassedToQueueble);
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToDelete, accSharepassedToQueueble, oppSharepassedToQueueble, quoteShareToDelete, qtSharepassedToQueueble,false);
                    }
                    else
                    {
                        if(accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0 || qtSharepassedToQueueble.size() > 0)
                        {
                            SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, false);
                        }
                    }
                    system.debug('+++QueueablePrincipalQuoteDeleteSharing getHeapSize()'+ Limits.getHeapSize());
                    //calling extension Queueable class for DML operations on the remained sharing records
                    if(!Test.isRunningTest() && (accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0 || qtSharepassedToQueueble.size() > 0) )
                    {
                        SharingUtils.removeListDups(accSharepassedToQueueble);
                        SharingUtils.removeListDups(oppSharepassedToQueueble);
                        SharingUtils.removeListDups(qtSharepassedToQueueble);
                        QueueableAvoidDMLLimit deleteSharingRemainedRecordsJob = new QueueableAvoidDMLLimit(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, false) ;
                        System.enqueueJob(deleteSharingRemainedRecordsJob);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            DebugLog.addException(ex, 'QueueablePrincipalQuoteDeleteSharing') ;
        }
    }
}