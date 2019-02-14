/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for deleting Sharing based on Opportunity records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<String, Map <String, List<SharingAccess__c> > >,
* Map<String, List<SharingAccess__c> >, List<AccountShare>
* Test Class : TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableOppDeleteSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();

    public QueueableOppDeleteSharing(Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap,
                                    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap,Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap,List<AccountShare> accSharepassedToQueueble)
    {
        this.lob1toSharingAccessNoPrincipalMap = lob1toSharingAccessNoPrincipalMap;
        this.globalSharingAccessesNoPrincipalMap = globalSharingAccessesNoPrincipalMap;
        this.lob1toSharingAccessPrincipalMap = lob1toSharingAccessPrincipalMap;
        this.globalSharingAccessesPrincipalMap = globalSharingAccessesPrincipalMap;
        this.accSharepassedToQueueble = accSharepassedToQueueble;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            if (!lob1toSharingAccessNoPrincipalMap.isEmpty())
            {
                Map<Id, List<SharingAccess__c>> accsToShareAccsMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, List<SharingAccess__c>> oppsToShareAccessMap = new Map<Id, List<SharingAccess__c>>();
                Map<Id, Set<Id>> accIdsToUsrIds = new Map<Id, Set<Id>>();
                Map<Id, Set<Id>> oppIdsToUsrIds = new Map<Id, Set<Id>>();

                Set<String> imcdCompNames = new Set<String>();
                for(map<String, list<SharingAccess__c>> imcdCompanyToShareAccess : lob1toSharingAccessNoPrincipalMap.values())
                {
                    imcdCompNames.addAll(imcdCompanyToShareAccess.keySet());
                }

                List<Opportunity> ShareOppList = new List<Opportunity>([
                        SELECT Id, LOB1__c, AccountId, Account.IMCDCompany__c, Account.ParentId
                        FROM Opportunity
                        WHERE (LOB1__c IN :lob1toSharingAccessNoPrincipalMap.keySet() AND Account.IMCDCompany__c IN : imcdCompNames)]);

                if(!ShareOppList.isEmpty())
                {
                    List<AccountShare> accShareToDelete = new List<AccountShare>() ;
                    List<OpportunityShare> oppShareToDelete = new List<OpportunityShare>() ;
                    //aggregating the Sharing access records related to previously deleted LOB Classifications Records
                    SharingUtils.aggregateRecordsToDelete(ShareOppList, lob1toSharingAccessNoPrincipalMap, accsToShareAccsMap, oppsToShareAccessMap, globalSharingAccessesNoPrincipalMap);

                    if(!accsToShareAccsMap.isEmpty())
                    {   //mapping the users that we need to delete from sharing of Sold To, Regional Accounts
                        SharingUtils.mapSharedUsersToRelObject(accsToShareAccsMap, accIdsToUsrIds);
                        SharingUtils.mapSharedUsersToRelObject(oppsToShareAccessMap, oppIdsToUsrIds);

                        for(AccountShare acShare : SharingUtils.getAccountShares(accIdsToUsrIds,Label.MANUAL_RAW_CAUSE))
                        {
                            if (accIdsToUsrIds.get(acShare.AccountId).contains(acShare.userOrGroupID) )
                            {
                                accShareToDelete.add(acShare);
                            }
                        }
                        for(OpportunityShare opShare : SharingUtils.getOpportunityShares(oppIdsToUsrIds,Label.MANUAL_RAW_CAUSE))
                        {
                            if(oppIdsToUsrIds.get(opShare.OpportunityId).contains(opShare.userOrGroupID) )
                            {
                                oppShareToDelete.add(opShare);
                            }
                        }
                    }
                    if(!oppShareToDelete.isEmpty() || !accShareToDelete.isEmpty())
                    {
                        /*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing record next queueable to get fresh set of limits*/
                        SharingUtils.combineRemainAndSharingList(accShareToDelete,accSharepassedToQueueble);
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToDelete,accSharepassedToQueueble,oppShareToDelete,oppSharepassedToQueueble,false);
                    }
                    else if(oppShareToDelete.isEmpty() && accShareToDelete.isEmpty())
                    {
                        if(accSharepassedToQueueble.size() > 0)
                        {
                            SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, false);
                        }
                    }
                }
            }
            system.debug('+++QueueableOppDeleteSharing getHeapSize()'+ Limits.getHeapSize());
            //Delete Sharing Accounts and Quotes based on Quotes
            QueueableQuoteDeleteSharing deleteAccAndQuoteSharesBasedQtJob = new QueueableQuoteDeleteSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap,
                    lob1toSharingAccessPrincipalMap,globalSharingAccessesPrincipalMap, accSharepassedToQueueble, oppSharepassedToQueueble);
            if(!Test.isRunningTest())
            {
                System.enqueueJob(deleteAccAndQuoteSharesBasedQtJob);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableOppDeleteSharing') ;
        }
    }
}