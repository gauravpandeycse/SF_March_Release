/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for deleting Sharing on Account and Opportunity based on OpportunityLineItems records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<String, Map <String, List<SharingAccess__c> > >,
* Map<String, List<SharingAccess__c> >, List<AccountShare>, List<OpportunityShare>, List<SBQQ__Quote__Share>
* Test Class : TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueablePrincipalOppDeleteSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();
    List<SBQQ__Quote__Share> qtSharepassedToQueueble = new List<SBQQ__Quote__Share>();

    public QueueablePrincipalOppDeleteSharing(Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap,
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
            List<AccountShare> accShareLst = new List<AccountShare>();
            List<OpportunityShare> oppShareLst = new List<OpportunityShare>();

            if(!lob1toSharingAccessPrincipalMap.isEmpty())
            {
                Map<Id, List<SharingAccess__c>> accsToShareAccsMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, List<SharingAccess__c>> oppsToShareAccessMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, Set<Id>> accIdsToUsrIds = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> oppIdsToUsrIds = new Map<Id, Set<Id>>();

                Set<String> imcdCompNames = new Set<String>();

                //get the relevant IMCD Company Id to agregate the right records for deletion and avoid 50000 DML limit
                for(Map<String, list<SharingAccess__c>> imcdCompanyToShareAccess : lob1toSharingAccessPrincipalMap.values())
                {
                    imcdCompNames.addAll(imcdCompanyToShareAccess.keySet());
                }

                Set<Id> globalPrincipals = new Set<Id>();
                Set<Id> globalPrincipalsForLob = new Set<Id>();
                Set<Id> imcdCompPrincipals = new Set<Id>();
                Set<String> imcdCompEmptyLobNames = new Set<String>();

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

                List<OpportunityLineItem> ShareoppLineItemLst = [SELECT Id, OpportunityId, Opportunity.LOB1__c, Product2.Principal__c, Opportunity.AccountId, Opportunity.Account.IMCDCompany__c, Opportunity.Account.ParentId
                FROM OpportunityLineItem
                WHERE (Opportunity.LOB1__c IN :lob1toSharingAccessPrincipalMap.keySet() AND Opportunity.Account.IMCDCompany__c  IN : imcdCompNames) // UC6 lob + company
                OR (Opportunity.LOB1__c IN : globalSharingAccessesPrincipalMap.keySet() AND Product2.Principal__c IN : globalPrincipalsForLob) // UC2 lob + global
                OR (Product2.Principal__c IN : imcdCompPrincipals  AND Opportunity.Account.IMCDCompany__c IN : imcdCompEmptyLobNames) //UC5 empty lob + company
                OR (Product2.Principal__c IN : globalPrincipals) ];
                if (!ShareoppLineItemLst.isEmpty())
                {
                    List<AccountShare> accShareToDelete = new List<AccountShare>() ;
                    List<OpportunityShare> oppShareToDelete = new List<OpportunityShare>() ;
                    //aggregating the Sharing access records related to previously deleted LOB Classifications Records
                    SharingUtils.aggregateRecordsToDelete(ShareoppLineItemLst, lob1toSharingAccessPrincipalMap, accsToShareAccsMap, oppsToShareAccessMap, globalSharingAccessesPrincipalMap);

                    if (!accsToShareAccsMap.isEmpty())
                    {   //mapping the users that we need to delete from sharing of Sold To, Regional Accounts
                        SharingUtils.mapSharedUsersToRelObject(accsToShareAccsMap, accIdsToUsrIds);
                        SharingUtils.mapSharedUsersToRelObject(oppsToShareAccessMap, oppIdsToUsrIds);

                        for (AccountShare acShare : SharingUtils.getAccountShares(accIdsToUsrIds,Label.MANUAL_RAW_CAUSE))
                        {
                            if (accIdsToUsrIds.get(acShare.AccountId).contains(acShare.userOrGroupID) )
                            {
                                accShareToDelete.add(acShare);
                            }
                        }

                        for (OpportunityShare opShare : SharingUtils.getOpportunityShares(oppIdsToUsrIds,Label.MANUAL_RAW_CAUSE))
                        {
                            if (oppIdsToUsrIds.get(opShare.OpportunityId).contains(opShare.userOrGroupID) )
                            {
                                oppShareToDelete.add(opShare);
                            }
                        }
                    }
                    if (!accShareToDelete.isEmpty() || !oppShareToDelete.isEmpty())
                    {
                        /*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                        next queueable to get fresh set of limits*/
                        SharingUtils.combineRemainAndSharingList(accShareToDelete,accSharepassedToQueueble);
                        SharingUtils.combineRemainAndSharingList(oppShareToDelete,oppSharepassedToQueueble);
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToDelete, accSharepassedToQueueble, oppShareToDelete, oppSharepassedToQueueble, qtSharepassedToQueueble,false);
                    }
                    // if we only have remains of AccountShare from other queueable and we can insert them all in current transaction
                    else
                    {
                        if(accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0 || qtSharepassedToQueueble.size() > 0)
                        {
                            SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, false);
                        }
                    }
                    system.debug('+++QueueablePrincipalOppDeleteSharing getHeapSize()'+ Limits.getHeapSize());
                }
                //Delete Sharing Accounts and Quotes based on QuoteLineItems
                QueueablePrincipalQuoteDeleteSharing deleteAccAndQuoteSharesBasedQtLineJob = new QueueablePrincipalQuoteDeleteSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap,
                        accSharepassedToQueueble,oppSharepassedToQueueble,qtSharepassedToQueueble);
                if(!Test.isRunningTest())
                {
                    System.enqueueJob(deleteAccAndQuoteSharesBasedQtLineJob);
                }
            }
        }
        catch (Exception ex)
        {
            DebugLog.addException(ex, 'QueueablePrincipalOppDeleteSharing') ;
        }
    }
}