/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for recalculation of Sharing based on QuoteLineItems records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<Id,Set<Id>>
* List<AccountShare>, List<OpportunityShare>, List<SBQQ__Quote__Share>
* Test Class : TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableQtPrincipalRecalculateSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();
    Map<Id,Set<Id>> ownersToAccIds = new Map<Id,Set<Id>>();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();
    List<SBQQ__Quote__Share> qtSharepassedToQueueble = new List<SBQQ__Quote__Share>();

    public QueueableQtPrincipalRecalculateSharing( Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap, Map<Id,Set<Id>> ownersToAccIds,
            List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble)
    {
        this.lob1toSharingAccessMap = lob1toSharingAccessMap;
        this.globalSharingAccessesMap = globalSharingAccessesNoPrincipalMap;
        this.ownersToAccIds = ownersToAccIds;
        this.accSharepassedToQueueble = accSharepassedToQueueble;
        this.oppSharepassedToQueueble = oppSharepassedToQueueble;
        this.qtSharepassedToQueueble = qtSharepassedToQueueble;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            if(!lob1toSharingAccessMap.isEmpty())
            {
                List<AccountShare> accShareLst = new List<AccountShare>();
                List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>();

                Set<Id> globalPrincipals = new Set<Id>();
                Set<Id> globalPrincipalsForLob = new Set<Id>();
                Set<Id> imcdCompPrincipals = new Set<Id>();
                Set<String> imcdCompEmptyLobNames = new Set<String>();
                Set<String> imcdCompNames = new Set<String>();

                //get the relevant principals Id and IMCD company to agregate the right records for deletion and avoid 50000 DML limit
                if(lob1toSharingAccessMap.containsKey('empty_lob'))
                {
                    for(String imcdComp : lob1toSharingAccessMap.get('empty_lob').keySet() )
                    {
                        for(SharingAccess__c sa : lob1toSharingAccessMap.get('empty_lob').get(imcdComp))
                        {
                            imcdCompPrincipals.add(sa.PrincipalId__c);
                            imcdCompEmptyLobNames.add(sa.IMCDCompany__c);
                        }
                    }
                }
                //get the relevant principals Id to agregate the right records for deletion and avoid 50000 DML limit
                if(globalSharingAccessesMap.containsKey('empty_lob_global'))
                {
                    for(SharingAccess__c sa : globalSharingAccessesMap.get('empty_lob_global'))
                    {
                        globalPrincipals.add(sa.PrincipalId__c);
                    }
                }

                //get the relevant principals Id to agregate the right records for deletion and avoid 50000 DML limit
                for(List<SharingAccess__c> saList : globalSharingAccessesMap.values() )
                {
                    for(SharingAccess__c sa : saList)
                    {
                        globalPrincipalsForLob.add(sa.PrincipalId__c);
                    }
                }
                //get the relevant IMCD Company Id to agregate the right records for deletion and avoid 50000 DML limit
                for(Map <String, List<SharingAccess__c> >  value : lob1toSharingAccessMap.values() )
                {
                    imcdCompNames.addAll(value.keySet());
                }


                List<SharingAccess__c> filteredSaLst = new List<SharingAccess__c>();

                for(SBQQ__QuoteLine__c ql : [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.LOB1__c, SBQQ__Product__r.Principal__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, SBQQ__Quote__r.SBQQ__Account__r.ParentId
                FROM SBQQ__QuoteLine__c
                WHERE (SBQQ__Quote__r.LOB1__c IN : lob1toSharingAccessMap.keySet() AND  SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c IN : imcdCompNames) // UC6 lob + company
                OR (SBQQ__Quote__r.LOB1__c IN : globalSharingAccessesMap.keySet() AND SBQQ__Product__r.Principal__c IN : globalPrincipalsForLob) // UC2 lob + global
                OR (SBQQ__Product__r.Principal__c IN : imcdCompPrincipals AND SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c IN : imcdCompEmptyLobNames) //UC5 empty lob + company
                OR (SBQQ__Product__r.Principal__c IN : globalPrincipals)] ) //UC1 empty lob + global
                {
                    //sharing Account and Quote if LOB1 & IMCDCompany match
                    if(ql.SBQQ__Quote__r.LOB1__c!=null)
                    {
                        if(lob1toSharingAccessMap.containsKey(ql.SBQQ__Quote__r.LOB1__c) && lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c).containsKey(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c))
                        {
                            filteredSaLst = SharingUtils.filterByPrincipal(ql.SBQQ__Quote__r.LOB1__c, ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, ql, lob1toSharingAccessMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                //SharingUtils.debugSharingReason('Quote','LOB1 & IMCDCompany match','QueueableQtPrincipalRecalculateSharing',lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c).get(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','QueueableQtPrincipalRecalculateSharing',filteredSaLst);
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','QueueableQtPrincipalRecalculateSharing', filteredSaLst);
                                }
                            }
                        }
                        //Sharing Account and Quote if LOB1 match and SharingAccess record is Global
                        if(globalSharingAccessesMap.containsKey(ql.SBQQ__Quote__r.LOB1__c))
                        {
                            filteredSaLst = SharingUtils.filterByPrincipal(ql.SBQQ__Quote__r.LOB1__c, ql, globalSharingAccessesMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                //SharingUtils.debugSharingReason('Quote','LOB1 match and SharingAccess record is Global','QueueableQtPrincipalRecalculateSharing',filteredSaLst);
                                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 match and SharingAccess record is Global','QueueableQtPrincipalRecalculateSharing',filteredSaLst);
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                    SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 match and SharingAccess record is Global','QueueableQtPrincipalRecalculateSharing',filteredSaLst);
                                }
                            }
                        }
                        //Sharing access without LOB
                        if(lob1toSharingAccessMap.containsKey('empty_lob') && lob1toSharingAccessMap.get('empty_lob').containsKey(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c)){
                            filteredSaLst = SharingUtils.filterByPrincipal('empty_lob', ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, ql, lob1toSharingAccessMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                }
                            }
                        }
                        //Sharing access without LOB - Global
                        if(globalSharingAccessesMap.containsKey('empty_lob_global')){
                            filteredSaLst = SharingUtils.filterByPrincipal('empty_lob_global', ql, globalSharingAccessesMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                }
                            }
                        }
                    }
                }
                if(!accShareLst.isEmpty() && !quoteShareLst.isEmpty())
                {/*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                    next queueable to get fresh set of limits*/
                    SharingUtils.combineRemainAndSharingList(accShareLst,accSharepassedToQueueble);
                    SharingUtils.combineRemainAndSharingList(quoteShareLst,qtSharepassedToQueueble);
                    SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareLst, accSharepassedToQueueble, oppSharepassedToQueueble,
                            quoteShareLst, qtSharepassedToQueueble,true);
                }
                else
                {
                    if(accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0 || qtSharepassedToQueueble.size() > 0)
                    {
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, true);
                    }
                }
                system.debug('+++QueueableQtPrincipalRecalculateSharing getHeapSize()'+ Limits.getHeapSize());
                //calling extension Queueable class for DML operations on the remained sharing records
                if(!Test.isRunningTest() && (accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0 || qtSharepassedToQueueble.size() > 0) )
                {
                    SharingUtils.removeListDups(accSharepassedToQueueble);
                    SharingUtils.removeListDups(oppSharepassedToQueueble);
                    SharingUtils.removeListDups(qtSharepassedToQueueble);
                    QueueableAvoidDMLLimit insertSharingRemainedRecordsJob = new QueueableAvoidDMLLimit(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, true) ;
                    System.enqueueJob(insertSharingRemainedRecordsJob);
                }
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableQtPrincipalRecalculateSharing') ;
        }
    }

}