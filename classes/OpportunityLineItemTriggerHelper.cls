public without sharing class OpportunityLineItemTriggerHelper {
    /******************************************************************************************************************************************************************
	* Author: Aviad Efergan, Eli Pogorelov
	* Company: Salesforce
	* Description: shares Sold To Account + C2 Account to users based on sharingAccess table on OpportunityLineItem record insert
	* Inputs : List<OpportunityLineItem>
	* Test Class :
	* History :
	******************************************************************************************************************************************************************/
    public static void accountShareBasedOppLineItem(list<OpportunityLineItem> newOppLineItemLst)
    {
        try
        {
            List<OpportunityLineItem> oppLineItemLst = [SELECT Id, OpportunityId, Opportunity.LOB1__c, Product2.Principal__c, Opportunity.AccountId, Opportunity.Account.IMCDCompany__c, Opportunity.Account.ParentId
                                                        FROM OpportunityLineItem WHERE Id IN :newOppLineItemLst];

            //Filter sharing access records by principal
            Set<Id> principalIds = new Set<Id>();
            Set<Id> relAccIds = new Set<Id>();
            for(OpportunityLineItem oli : oppLineItemLst)
            {
            	principalIds.add(oli.Product2.Principal__c);
                relAccIds.add(oli.Opportunity.AccountId);
                if(oli.Opportunity.Account.ParentId!=null)
                {
                    relAccIds.add(oli.Opportunity.Account.ParentId);
                }
            }

            List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(principalIds);
            if(!sharingTableList.isEmpty())
            {
                Map<String, Map<String, List<SharingAccess__c>>> lob1toSharingAccessMap = new Map<String, Map<String, List<SharingAccess__c>>>();
                Map<String, List<SharingAccess__c>> globalSharingAccessesMap = new Map<String, List<SharingAccess__c>>();

                SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toSharingAccessMap, globalSharingAccessesMap);
                if (!lob1toSharingAccessMap.isEmpty())
                {
                    List<AccountShare> accShareLst = new List<AccountShare>();
                    List<OpportunityShare> oppShareLst = new List<OpportunityShare>();


                    // get Owners to Accounts Id's to avoid sharing the Account to the owner
                    Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(relAccIds);
                    List<SharingAccess__c> filteredSaLst = new List<SharingAccess__c>();
                    for(OpportunityLineItem oli : oppLineItemLst)
                    {
                        //sharing Account and Opp if LOB1 & IMCDCompany match
                        if(oli.Opportunity.LOB1__c!=null && lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c)!=null)
                        {
                            if(lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).containsKey(oli.Opportunity.Account.IMCDCompany__c))
                            {
                                filteredSaLst = SharingUtils.filterByPrincipal(oli.Opportunity.LOB1__c, oli.Opportunity.Account.IMCDCompany__c, oli, lob1toSharingAccessMap);
                                if(!filteredSaLst.isEmpty())
                                {
                                    oppShareLst.addAll(SharingUtils.opportunitySharing(oli.OpportunityId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                                    //SharingUtils.debugSharingReason('Opportunity','LOB1 & IMCDCompany match','OpportunityLineItemTriggerHelper',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                    if(oli.Opportunity.Account.ParentId!=null)
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','OpportunityLineItemTriggerHelper',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                    }
                                    else
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','OpportunityLineItemTriggerHelper',lob1toSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                                    }
                                }
                            }
                            //Sharing Account and Opp if LOB1 match and SharingAccess record is Global
                            if(globalSharingAccessesMap.containsKey(oli.Opportunity.LOB1__c))
                            {
                                filteredSaLst = SharingUtils.filterByPrincipal(oli.Opportunity.LOB1__c, oli, globalSharingAccessesMap);
                                if(!filteredSaLst.isEmpty())
                                {
                                    oppShareLst.addAll(SharingUtils.opportunitySharing(oli.OpportunityId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                                    //SharingUtils.debugSharingReason('Opportunity','LOB1 match and SharingAccess record is Global','OpportunityLineItemTriggerHelper',globalSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                                    if(oli.Opportunity.Account.ParentId!=null)
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo + C2 LOB1 match and SharingAccess record is Global','OpportunityLineItemTriggerHelper',globalSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                                    }
                                    else
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 match and SharingAccess record is Global','OpportunityLineItemTriggerHelper',globalSharingAccessesMap.get(oli.Opportunity.LOB1__c));
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
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
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
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, oli.Opportunity.Account.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(oli.Opportunity.AccountId, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                            }
                        }
                    }
                    if(!accShareLst.isEmpty() && !oppShareLst.isEmpty())
                    {
                        SharingUtils.dmlOperationOnShareRecords(accShareLst, true);
                        SharingUtils.dmlOperationOnShareRecords(oppShareLst, true);
                    }
            	}
            }
        }
        catch(Exception ex){
            DebugLog.addException(ex, 'OpportunityLineItemTriggerHelper') ;
        }
    }
    
    
}