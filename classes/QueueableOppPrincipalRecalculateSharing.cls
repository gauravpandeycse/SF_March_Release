/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
    * Description: Queueable for recalculation of Sharing based on OpportunityLineItems records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >, Map<Id,Set<Id>>, List<AccountShare>,
* List<OpportunityShare>, List<SBQQ__Quote__Share>
* Test Class :  TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableOppPrincipalRecalculateSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();
    Map<Id,Set<Id>> ownersToAccIds = new Map<Id,Set<Id>>();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
    List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();
    List<SBQQ__Quote__Share> qtSharepassedToQueueble = new List<SBQQ__Quote__Share>();

    public QueueableOppPrincipalRecalculateSharing( Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap, Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap, Map<Id,Set<Id>> ownersToAccIds,
            List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble)
    {
        this.lob1toSharingAccessMap = lob1toSharingAccessMap;
        this.globalSharingAccessesMap = globalSharingAccessesPrincipalMap;
        this.ownersToAccIds = ownersToAccIds;
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

            if(!lob1toSharingAccessMap.isEmpty())
            {
                Set<Id> globalPrincipals = new Set<Id>();
                Set<Id> globalPrincipalsForLob = new Set<Id>();
                Set<Id> imcdCompPrincipals = new Set<Id>();
                Set<String> imcdCompNames = new Set<String>();
                Set<String> imcdCompEmptyLobNames = new Set<String>();

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

                for(OpportunityLineItem oli : [SELECT Id, OpportunityId, Opportunity.LOB1__c, Product2.Principal__c, Opportunity.AccountId, Opportunity.Account.IMCDCompany__c, Opportunity.Account.ParentId
                FROM OpportunityLineItem
                WHERE (Opportunity.LOB1__c IN :lob1toSharingAccessMap.keySet() AND Opportunity.Account.IMCDCompany__c  IN : imcdCompNames) // UC6 lob + company
                OR (Opportunity.LOB1__c IN : globalSharingAccessesMap.keySet() AND Product2.Principal__c IN : globalPrincipalsForLob) // UC2 lob + global
                OR (Product2.Principal__c IN : imcdCompPrincipals  AND Opportunity.Account.IMCDCompany__c IN : imcdCompEmptyLobNames) //UC5 empty lob + company
                OR (Product2.Principal__c IN : globalPrincipals) ]) //UC1 empty lob + global
                {
                    //sharing Account and Opp if LOB1 & IMCDCompany match
                    if(oli.Opportunity.LOB1__c != null)
                    {
                        if (lob1toSharingAccessMap.containsKey(oli.Opportunity.LOB1__c) && lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).containsKey(oli.Opportunity.Account.IMCDCompany__c))
                        {
                            filteredSaLst = SharingUtils.filterByPrincipal(oli.Opportunity.LOB1__c, oli.Opportunity.Account.IMCDCompany__c, oli, lob1toSharingAccessMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                oppShareLst.addAll(SharingUtils.opportunitySharing(oli.OpportunityId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                                //SharingUtils.debugSharingReason('Opportunity','LOB1 & IMCDCompany match','QueueableOppPrincipalRecalculateSharing',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                if(oli.Opportunity.Account.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE,ownersToAccIds));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','QueueableOppPrincipalRecalculateSharing',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                    //SharingUtils.debugSharingReason('Account', 'sharing the soldTo LOB1 & IMCDCompany match', 'QueueableOppPrincipalRecalculateSharing', lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                }
                            }
                        }
                        //Sharing Account and Opp if LOB1 match and SharingAccess record is Global
                        if (globalSharingAccessesMap.containsKey(oli.Opportunity.LOB1__c))
                        {
                            filteredSaLst = SharingUtils.filterByPrincipal(oli.Opportunity.LOB1__c, oli, globalSharingAccessesMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                oppShareLst.addAll(SharingUtils.opportunitySharing(oli.OpportunityId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                                //SharingUtils.debugSharingReason('Opportunity','LOB1 match and SharingAccess record is Global','QueueableOppPrincipalRecalculateSharing',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                if(oli.Opportunity.Account.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE,ownersToAccIds));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 match and SharingAccess record is Global','QueueableOppPrincipalRecalculateSharing',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                                    // SharingUtils.debugSharingReason('Account', 'sharing the soldTo LOB1 match and SharingAccess record is Global', 'QueueableOppPrincipalRecalculateSharing', lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                }
                            }
                        }
                    }
                    //Sharing access without LOB
                    if(lob1toSharingAccessMap.containsKey('empty_lob') && lob1toSharingAccessMap.get('empty_lob').containsKey(oli.Opportunity.Account.IMCDCompany__c))
                    {
                        filteredSaLst = SharingUtils.filterByPrincipal('empty_lob', oli.Opportunity.Account.IMCDCompany__c, oli, lob1toSharingAccessMap);

                        if(!filteredSaLst.isEmpty()) {
                            oppShareLst.addAll(SharingUtils.opportunitySharing(oli.OpportunityId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                            if(oli.Opportunity.Account.ParentId!=null)
                            {
                                accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            }
                            else
                            {
                                accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            }
                        }
                    }
                    //Sharing access without LOB - Global
                    if(globalSharingAccessesMap.containsKey('empty_lob_global'))
                    {
                        filteredSaLst = SharingUtils.filterByPrincipal('empty_lob_global', oli, globalSharingAccessesMap);
                        if(!filteredSaLst.isEmpty())
                        {
                            oppShareLst.addAll(SharingUtils.opportunitySharing(oli.OpportunityId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                            if(oli.Opportunity.Account.ParentId!=null)
                            {
                                accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            }
                            else
                            {
                                accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            }
                        }
                    }
                }
            }
            if (!accShareLst.isEmpty() && !oppShareLst.isEmpty())
            {/*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                next queueable to get fresh set of limits*/
                SharingUtils.combineRemainAndSharingList(accShareLst,accSharepassedToQueueble);
                SharingUtils.combineRemainAndSharingList(oppShareLst,oppSharepassedToQueueble);
                SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareLst, accSharepassedToQueueble, oppShareLst, oppSharepassedToQueueble, qtSharepassedToQueueble,true);
            }
            // if we only have remains of AccountShare from other queueable and we can insert them all in current transaction
            else
            {
                if(accSharepassedToQueueble.size() > 0 || oppSharepassedToQueueble.size() > 0 || qtSharepassedToQueueble.size() > 0)
                {
                    SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, true);
                }
            }
            system.debug('+++QueueableOppPrincipalRecalculateSharing getHeapSize()'+ Limits.getHeapSize());
            //Sharing Accounts and Quotes based on QuoteLineItems
            if(!Test.isRunningTest())
            {
                QueueableQtPrincipalRecalculateSharing insertAccAndQuoteSharesBasedQtLineJob = new QueueableQtPrincipalRecalculateSharing(lob1toSharingAccessMap, globalSharingAccessesMap,
                        ownersToAccIds, accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble) ;
                System.enqueueJob(insertAccAndQuoteSharesBasedQtLineJob);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableOppPrincipalRecalculateSharing') ;
        }
    }
}