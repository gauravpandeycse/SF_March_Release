/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for recalculation of Sharing based on Quote records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, Map <String, List<SharingAccess__c> > > ,  Map<String, List<SharingAccess__c> >,
* Map<String, List<SharingAccess__c> >, Map<Id,Set<Id>>,  List<AccountShare>, List<OpportunityShare>
* Test Class :  TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableQuoteRecalculateSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();
    Map<Id,Set<Id>> ownersToAccIds = new Map<Id,Set<Id>>();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();

    public QueueableQuoteRecalculateSharing( Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap, Map<Id,Set<Id>> ownersToAccIds,
                                            Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap,Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap,
                                            List<AccountShare> accSharepassedToQueueble,  List<OpportunityShare> oppSharepassedToQueueble)
    {
        this.lob1toSharingAccessMap = lob1toSharingAccessMap;
        this.globalSharingAccessesMap = globalSharingAccessesNoPrincipalMap;
        this.ownersToAccIds = ownersToAccIds;
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
            if(!lob1toSharingAccessMap.isEmpty())
            {
                List<AccountShare> accShareToInsert = new List<AccountShare>();
                List<SBQQ__Quote__Share> qtShareToInsert = new List<SBQQ__Quote__Share>();
                Set<String> imcdCompNames = new Set<String>();

                for(Map <String, List<SharingAccess__c> >  value : lob1toSharingAccessMap.values() )
                {
                    imcdCompNames.addAll(value.keySet());
                }

                for(SBQQ__Quote__c qt : [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.IMCDCompany__c, SBQQ__Account__r.ParentId, LOB1__c
                                         FROM SBQQ__Quote__c
                                         WHERE LOB1__c IN : lob1toSharingAccessMap.keySet() AND SBQQ__Account__r.IMCDCompany__c IN : imcdCompNames])
                {
                    //sharing Account if LOB1 & IMCDCompany match
                    if(lob1toSharingAccessMap.get(qt.LOB1__c)!=null && lob1toSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c)!=null)
                    {
                        //sharing the Opportunity
                        qtShareToInsert.addAll(SharingUtils.quoteSharing(qt.Id,lob1toSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c), Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c));
                        //SharingUtils.debugSharingReason('Quote','LOB1 & IMCDCompany match','QueueableQuoteRecalculateSharing',lob1toSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                        //sharing the sold to Account and Regional Account
                        if(qt.SBQQ__Account__r.ParentId!=null)
                        {
                            accShareToInsert.addAll(SharingUtils.accountSharing(qt.SBQQ__Account__c, qt.SBQQ__Account__r.ParentId, lob1toSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','QueueableQuoteRecalculateSharing',lob1toSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                        }
                        else
                        {
                            accShareToInsert.addAll(SharingUtils.accountSharing(qt.SBQQ__Account__c, null, lob1toSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                        }
                    }
                }
                if (!accShareToInsert.isEmpty() && !qtShareToInsert.isEmpty())
                {
                    /*if we are going to hit DML limit pass half of the value to
                    next queueable to get fresh set of limits*/
                    if(accSharepassedToQueueble.size() > 0 )
                    {
                        SharingUtils.combineRemainAndSharingList(accShareToInsert,accSharepassedToQueueble);
                    }
                    SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToInsert,accSharepassedToQueueble, oppSharepassedToQueueble, qtShareToInsert, qtSharepassedToQueueble,true);
                }
                else
                {
                    if (accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0) {
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, oppSharepassedToQueueble, true);
                    }
                }
            }
            system.debug('+++QueueableQuoteRecalculateSharing getHeapSize()'+ Limits.getHeapSize());
            //in this case we recalculate sharing on OpportunityLineItem, QuoteLineItem
            if(!lob1toSharingAccessPrincipalMap.isEmpty() && !Test.isRunningTest())
            {
                //Sharing Accounts and Opps based on OpportunityLineItems
                QueueableOppPrincipalRecalculateSharing insertAccAndOppSharesBasedOppLineJob = new QueueableOppPrincipalRecalculateSharing(lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, ownersToAccIds,
                                                                                                    accSharepassedToQueueble,oppSharepassedToQueueble,qtSharepassedToQueueble);
                System.enqueueJob(insertAccAndOppSharesBasedOppLineJob);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableQuoteRecalculateSharing') ;
        }
    }
}