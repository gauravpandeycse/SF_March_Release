/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for recalculation of Sharing based on AccountLob records
* Inputs : Map<String, Map <String, List<SharingAccess__c> > >, Map<String, Map <String, List<SharingAccess__c> > >, Map<String, List<SharingAccess__c> >,
* Map<String, List<SharingAccess__c> >, Map<Id,Set<Id>>
* Test Class :  TestSharingAccessTriggerHelper
* History :
******************************************************************************************************************************************************************/
public without sharing class QueueableAccLobRecalculateSharing implements Queueable
{
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();
    Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();
    Map<Id,Set<Id>> ownersToAccIds = new Map<Id,Set<Id>>();

    public QueueableAccLobRecalculateSharing( Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap, Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap, Map<Id,Set<Id>> ownersToAccIds,
                                            Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap, Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap)
    {
        this.lob1toSharingAccessMap = lob1toSharingAccessMap;
        this.globalSharingAccessesMap = globalSharingAccessesNoPrincipalMap;
        this.lob1toSharingAccessPrincipalMap = lob1toSharingAccessPrincipalMap;
        this.globalSharingAccessesPrincipalMap = globalSharingAccessesPrincipalMap;
        this.ownersToAccIds = ownersToAccIds;
    }

    public void execute(QueueableContext context)
    {
        try
        {
            List<AccountShare> accSharepassedToQueueble = new List<AccountShare>();
            if(!lob1toSharingAccessMap.isEmpty())
            {
                List<AccountLob__c> accLobList = new List<AccountLob__c>();
                List<AccountShare> accShareToInsert = new List<AccountShare>();
                Set<String> imcdCompNames = new Set<String>();

                for(Map <String, List<SharingAccess__c> >  value : lob1toSharingAccessMap.values() )
                {
                    imcdCompNames.addAll(value.keySet());
                }

                for(AccountLob__c al : [SELECT Id, Account__c, Account__r.IMCDCompany__c, Account__r.ParentId, LOB1__c
                                        FROM AccountLob__c
                                        WHERE LOB1__c IN : lob1toSharingAccessMap.keySet() AND Account__r.IMCDCompany__c IN : imcdCompNames])
                {
                    //sharing Account if LOB1 & IMCDCompany match
                    if(lob1toSharingAccessMap.get(al.LOB1__c)!=null && lob1toSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c)!=null)
                    {//sharing the sold to Account and Regional Account
                        if(al.Account__r.ParentId!=null)
                        {
                            accShareToInsert.addAll(SharingUtils.accountSharing(al.Account__c, al.Account__r.ParentId, lob1toSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds ));
                            SharingUtils.debugSharingReason('Account','delete the soldTo LOB1 & IMCDCompany match','QueueableAccLobDeleteSharing',lob1toSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                        }
                        else
                        {
                            accShareToInsert.addAll(SharingUtils.accountSharing(al.Account__c, null, lob1toSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccIds ));
                            SharingUtils.debugSharingReason('Account','sharing the C2 LOB1 & IMCDCompany match','QueueableAccLobRecalculateSharing',lob1toSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                        }
                    }
                }
                if(!accShareToInsert.isEmpty())
                {/*if we are going to hit DML limit we'll insert what possible and pass the remains of the sharing records
                    next queueable to get fresh set of limits*/
                    SharingUtils.checkForDMLlimitAndInsertOrDeleteSharing(accShareToInsert,accSharepassedToQueueble, true);
                }

            }
            //Sharing Accounts and Opps based on Opportunities
            QueueableOppRecalculateSharing insertAccAndOppSharesBasedOppJob = new QueueableOppRecalculateSharing(lob1toSharingAccessMap, globalSharingAccessesMap, ownersToAccIds, lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap, accSharepassedToQueueble);
            if(!Test.isRunningTest() )
            {
                System.enqueueJob(insertAccAndOppSharesBasedOppJob);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableAccLobRecalculateSharing') ;
        }
    }

}