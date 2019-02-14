/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for recalculation of Sharing based on Opportunities records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >,
* Map<String, List<SharingAccess__c> >,  Map<Id,Set<Id>>, List<AccountShare>
* Test Class :  TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableOppRecalculateSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();
    Map<Id,Set<Id>> ownersToAccIds = new Map<Id,Set<Id>>();

    List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();


    public QueueableOppRecalculateSharing(Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap, Map<Id,Set<Id>> ownersToAccIds,
                                        Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap,Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap, List<AccountShare> accSharepassedToQueueble)
    {
        this.lob1toSharingAccessMap = lob1toSharingAccessMap;
        this.globalSharingAccessesMap = globalSharingAccessesNoPrincipalMap;
        this.ownersToAccIds = ownersToAccIds;
        this.lob1toSharingAccessPrincipalMap = lob1toSharingAccessPrincipalMap;
        this.globalSharingAccessesPrincipalMap = globalSharingAccessesPrincipalMap;
        this.accSharepassedToQueueble = accSharepassedToQueueble;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            List<OpportunityShare> oppSharepassedToQueueble = new List<OpportunityShare>();
            if(!lob1toSharingAccessMap.isEmpty())
            {

                List<AccountShare> accShareToInsert = new List<AccountShare>();
                List<OpportunityShare> oppShareToInsert = new List<OpportunityShare>();
                Set<String> imcdCompNames = new Set<String>();

                for(Map <String, List<SharingAccess__c> >  value : lob1toSharingAccessMap.values() )
                {
                    imcdCompNames.addAll(value.keySet());
                }

                for(Opportunity op : [SELECT Id, AccountId, Account.IMCDCompany__c, Account.ParentId, LOB1__c
                                      FROM Opportunity
                                      WHERE LOB1__c IN : lob1toSharingAccessMap.keySet() AND Account.IMCDCompany__c IN :  imcdCompNames])
                {//sharing Account if LOB1 & IMCDCompany match
                    if(lob1toSharingAccessMap.get(op.LOB1__c)!=null && lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c)!=null)
                    {
                        //sharing the Opportunity
                        oppShareToInsert.addAll(SharingUtils.opportunitySharing(op.Id,lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                        //SharingUtils.debugSharingReason('Opportunity','LOB1 & IMCDCompany match','QueueableOppRecalculateSharing',lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                        //sharing the sold to Account and Regional Account
                        if(op.Account.ParentId!=null)
                        {
                            accShareToInsert.addAll(SharingUtils.accountSharing(op.AccountId, op.Account.ParentId, lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','QueueableOppRecalculateSharing',lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                        }
                        else
                        {
                            accShareToInsert.addAll(SharingUtils.accountSharing(op.AccountId, null, lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds));
                            //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','QueueableOppRecalculateSharing',lob1toSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                        }
                    }
                }
                if (!accShareToInsert.isEmpty() && !oppShareToInsert.isEmpty())
                {/*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                    next queueable to get fresh set of limits*/
                    SharingUtils.combineRemainAndSharingList(accShareToInsert,accSharepassedToQueueble);
                    SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToInsert,accSharepassedToQueueble,oppShareToInsert,oppSharepassedToQueueble,true);
                }// if we only have remains of AccountShare from other queueable and we can insert them all in current transaction
                else
                {
                    if(accSharepassedToQueueble.size() > 0)
                    {
                        SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accSharepassedToQueueble, true);
                    }
                }
            }
            system.debug('+++QueueableOppRecalculateSharing getHeapSize()'+ Limits.getHeapSize());
            //Sharing Accounts and Quotes based on Quotes
            if(!Test.isRunningTest())
            {
                QueueableQuoteRecalculateSharing insertAccAndQuoteSharesBasedQtJob = new QueueableQuoteRecalculateSharing(lob1toSharingAccessMap, globalSharingAccessesMap, ownersToAccIds,
                lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, accSharepassedToQueueble, oppSharepassedToQueueble) ;
                System.enqueueJob(insertAccAndQuoteSharesBasedQtJob);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableOppRecalculateSharing') ;
        }
    }

}