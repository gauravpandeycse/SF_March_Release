/******************************************************************************************************************************************************************
 * Author: Aviad Efergan,Eli Pogorelov
 * Company: Salesforce
 * Description: event handler Class for QuoteLine Trigger
 * Inputs :
 * Test Class :  TestQuoteLineItemTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
public without sharing class QuoteLineTriggerHelper
{
    /******************************************************************************************************************************************************************
    * Author: Aviad Efergan, Eli Pogorelov
    * Company: Salesforce
    * Description: shares Sold To Account + Regional Account to users based on sharingAccess table on QuoteLine record insert
    * Inputs : List<SBQQ__QuoteLine__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void accountShareBasedQtLine(list<SBQQ__QuoteLine__c> newQtLineLst)
    {
        try
        {
            List<SBQQ__QuoteLine__c> qtLineLst = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.LOB1__c, SBQQ__Product__r.Principal__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, SBQQ__Quote__r.SBQQ__Account__r.ParentId
                                                  FROM SBQQ__QuoteLine__c
                                                  WHERE Id IN :newQtLineLst];
            //Filter sharing access records by principal
            Set<Id> principalIds = new Set<Id>();
            Set<Id> relAccIds = new Set<Id>();
            for(SBQQ__QuoteLine__c ql : qtLineLst)
            {
            	principalIds.add(ql.SBQQ__Product__r.Principal__c);
                relAccIds.add(ql.SBQQ__Quote__r.SBQQ__Account__c);
                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                {
                    relAccIds.add(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId);
                }
            }
            List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(principalIds);
            
            if(!sharingTableList.isEmpty())
            {
                Map<String, Map<String, List<SharingAccess__c>>> lob1toSharingAccessMap = new Map<String, Map<String, List<SharingAccess__c>>>();
            	Map<String, List<SharingAccess__c>> globalSharingAccessesMap = new Map<String, List<SharingAccess__c>>();
                SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toSharingAccessMap, globalSharingAccessesMap);                               
                
                if(!lob1toSharingAccessMap.isEmpty())
                {
                    List<AccountShare> accShareLst = new List<AccountShare>();
                    List<SBQQ__Quote__Share> quoteShareLst = new List<SBQQ__Quote__Share>();

                    // get Owners to Accounts Id's to avoid sharing the Account to the owner
                    Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(relAccIds);
                    List<SharingAccess__c> filteredSaLst = new List<SharingAccess__c>();
                    for(SBQQ__QuoteLine__c ql : qtLineLst)
                    {
                        //sharing Account and Quote if LOB1 & IMCDCompany match
                        if(ql.SBQQ__Quote__r.LOB1__c!=null && lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c)!=null)
                        {
                            if(lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c).containsKey(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c))
                            {
                                if(!filteredSaLst.isEmpty())
                                {
                                    quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                    //SharingUtils.debugSharingReason('Quote','LOB1 & IMCDCompany match','QuoteLineTriggerHelper',lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c).get(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                                    if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','QuoteLineTriggerHelper',lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c).get(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                                    }
                                    else
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','QuoteLineTriggerHelper',lob1toSharingAccessMap.get(ql.SBQQ__Quote__r.LOB1__c).get(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
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
                                    //SharingUtils.debugSharingReason('Quote','LOB1 match and SharingAccess record is Global','QuoteLineTriggerHelper',globalSharingAccessesMap.get(ql.SBQQ__Quote__r.LOB1__c));
                                    if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 match and SharingAccess record is Global','QuoteLineTriggerHelper',globalSharingAccessesMap.get(ql.SBQQ__Quote__r.LOB1__c));
                                    }
                                    else
                                    {
                                        accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 match and SharingAccess record is Global','QuoteLineTriggerHelper',globalSharingAccessesMap.get(ql.SBQQ__Quote__r.LOB1__c));
                                    }
                                }
                            }
                        }
                        //Sharing access without LOB
                        if(lob1toSharingAccessMap.containsKey('empty_lob') && lob1toSharingAccessMap.get('empty_lob').containsKey(ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c))
                        {
                            filteredSaLst = SharingUtils.filterByPrincipal('empty_lob', ql.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, ql, lob1toSharingAccessMap);
                            if(!filteredSaLst.isEmpty()) {
                                quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                            } 
                        }
                        //Sharing access without LOB - Global
                        if(globalSharingAccessesMap.containsKey('empty_lob_global'))
                        {
                            filteredSaLst = SharingUtils.filterByPrincipal('empty_lob_global', ql, globalSharingAccessesMap);
                            if(!filteredSaLst.isEmpty())
                            {
                                quoteShareLst.addAll(SharingUtils.quoteSharing(ql.SBQQ__Quote__c, filteredSaLst, Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                if(ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, ql.SBQQ__Quote__r.SBQQ__Account__r.ParentId, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                                else
                                {
                                    accShareLst.addAll(SharingUtils.accountSharing(ql.SBQQ__Quote__r.SBQQ__Account__c, null, filteredSaLst, Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                }
                            }
                        }
                    }
                    if(!accShareLst.isEmpty() && !quoteShareLst.isEmpty())
                    {
                        SharingUtils.dmlOperationOnShareRecords(accShareLst, true);
                        SharingUtils.dmlOperationOnShareRecords(quoteShareLst, true);
                    }
            	}
            }
        }
        catch(Exception ex){
            DebugLog.addException(ex, 'QuoteLineTriggerHelper') ;
        }
    }
     /******************************************************************************************************************************************************************
    * Author:Eli Pogorelov
    * Company: Salesforce
    * Description: prevents deletion of QuoteLine record if it has related list records
    * Inputs : List<SBQQ__QuoteLine__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void preventDelete(Map<Id, SBQQ__QuoteLine__c> oldQtLineMap)
    {
        try
        {
           for(SBQQ__QuoteLine__c qli : [SELECT Id,SBQQ__ContractedPrice__c, SBQQ__ContractedPrice__r.SBQQ__OriginalQuoteLine__c, (SELECT Id FROM Market_Info_BO__r ),
                                        (SELECT Id FROM Follow_up_Reports__r ), (SELECT Id FROM Cases__r )
                                        FROM SBQQ__QuoteLine__c WHERE ID IN : oldQtLineMap.keySet() ])
           {
              if(qli.Cases__r.size() <> 0)
              {
                  oldQtLineMap.get(qli.Id).addError(Label.prevent_delete_of_Quote_Line_Case_scenario);
              }
              if(qli.Market_Info_BO__r.size() <> 0)
              {
                  oldQtLineMap.get(qli.Id).addError(Label.prevent_delete_of_Quote_Line_MInfo_scenario);
              }
              if(qli.Follow_up_Reports__r.size() <> 0)
              {
                  oldQtLineMap.get(qli.Id).addError(Label.prevent_delete_of_Quote_Line_FReports_scenario);
              }
           }
        }
		catch(Exception ex)
        {
        	DebugLog.addException(ex, 'QuoteLineTriggerHelper') ;
        }
    }



    /******************************************************************************************************************************************************************
   * Author:Eli Pogorelov
   * Company: Salesforce
   * Description: prevents deletion of QuoteLine record if it's Id is populatged in a contractedprice
   * Inputs : List<SBQQ__QuoteLine__c>
   * Test Class :
   * History :
   ******************************************************************************************************************************************************************/
    public static void preventDeleteIfQtInConPrice(Map<Id, SBQQ__QuoteLine__c> oldQtLineMap)
    {
        try
        {
            for(SBQQ__ContractedPrice__c price : [Select id,SBQQ__OriginalQuoteLine__c, Old__c FROM SBQQ__ContractedPrice__c WHERE SBQQ__OriginalQuoteLine__c = :oldQtLineMap.keySet()])
            {
                oldQtLineMap.get(price.SBQQ__OriginalQuoteLine__c).addError(Label.prevent_delete_of_Quote_Line_ContPrice_Scenario);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QuoteLineTriggerHelper') ;
        }
    }
}