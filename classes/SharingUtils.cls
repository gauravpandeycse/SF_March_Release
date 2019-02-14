/*****************************************************************************************************************************************************************
* Author: Eli Pogorelov, Aviad Efergan
* Company: Salesforce
* Description: Event Handler AccountLob__c Trigger
* Inputs :
* Test Class :
* History :
*       05/02/2018  - JEBU/SF Updated getSharingAccessTable method to return only records for Active users ( UserId__r.IsActive = true )
*****************************************************************************************************************************************************************/
public without sharing class SharingUtils
{
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns sharingAccess table sorted by global__c
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<SharingAccess__c>  getSharingAccessTable(set<Id> principalIds){
        if(principalIds != null){
            return [SELECT Id, Global__c, IMCDCompany__c, PrincipalId__c, UserId__c, LOB1__c, LOB2__c FROM SharingAccess__c WHERE UserId__r.IsActive = true AND PrincipalId__c IN: principalIds ORDER BY Global__c];
        }
        return [SELECT Id, Global__c, IMCDCompany__c, PrincipalId__c, UserId__c, LOB1__c, LOB2__c FROM SharingAccess__c WHERE UserId__r.IsActive = true AND PrincipalId__c = NULL ORDER BY Global__c];
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
        * Description: returns parent Accounts
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<Account> getParentAccounts(Set<Id> accIdSet)
    {
        return [SELECT Id, ParentId, RecordTypeId, IMCDCompany__c
        FROM Account
        WHERE Id IN : accIdSet AND (RecordType.DeveloperName =: 'Customer_Sold_To' OR RecordType.DeveloperName =: 'Customer_Regional' OR RecordType.DeveloperName =: 'Customer_Prospect' )] ;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns AccountShares by Account Id's and RowCause
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<AccountShare> getAccountShares(Map<Id, Set<Id>> accIdsToUsrIds, String RowCause)
    {
        Set<Id> userIds  = new Set<Id>() ;
        for(Id accId : accIdsToUsrIds.keySet())
        {
            userIds.addAll(accIdsToUsrIds.get(accId));
        }

        return [SELECT Id, UserOrGroupId, AccountId, RowCause
                FROM AccountShare
                WHERE AccountId IN : accIdsToUsrIds.keySet() AND UserOrGroupId IN : userIds AND RowCause = : RowCause FOR UPDATE ] ;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns OpportunityShares by Opportunity Id's and RowCause
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<OpportunityShare> getOpportunityShares(Map<Id, Set<Id>> oppIdsToUsrIds, String RowCause)
    {
        Set<Id> userIds  = new Set<Id>() ;
        for(Id oppId : oppIdsToUsrIds.keySet())
        {
            userIds.addAll(oppIdsToUsrIds.get(oppId));
        }

        return [SELECT Id, UserOrGroupId, OpportunityId, RowCause
                FROM OpportunityShare
                WHERE OpportunityId IN : oppIdsToUsrIds.keySet() AND UserOrGroupId IN : userIds
                AND RowCause = : RowCause FOR UPDATE] ;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns QuoteShares by Quote Id's and RowCause
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<SBQQ__Quote__Share> getQuoteShares(Map<Id, Set<Id>> qtIdsToUsrIds, String RowCause)
    {
        Set<Id> userIds  = new Set<Id>() ;
        for(Id accId : qtIdsToUsrIds.keySet())
        {
            userIds.addAll(qtIdsToUsrIds.get(accId));
        }

        return [SELECT Id, UserOrGroupId, ParentId, RowCause
                FROM SBQQ__Quote__Share
                WHERE ParentId IN : qtIdsToUsrIds.keySet() AND UserOrGroupId IN : userIds AND RowCause = : RowCause FOR UPDATE] ;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns AccountShare list of records
    * Inputs : Id , List<SharingAccess__c> ,String, String, String
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<AccountShare> accountSharing(Id soldToAccId, Id regionalAccId, List<SharingAccess__c> sharing2WhoTable,
            String accAccessLevel, String oppAccessLevel, String rawCause, Map<Id,Set<Id>> ownersToAcountMap)
    {
        List<AccountShare> shareList = new List<AccountShare>();

        for (SharingAccess__c sa : sharing2WhoTable)
        {

            if(ownersToAcountMap == null || !ownersToAcountMap.containsKey(sa.UserId__c) || !ownersToAcountMap.get(sa.UserId__c).contains(soldToAccId))
            {
                AccountShare share = new AccountShare();
                share.AccountId = soldToAccId;
                share.AccountAccessLevel = accAccessLevel;
                share.OpportunityAccessLevel = oppAccessLevel;
                share.UserOrGroupId = sa.UserId__c;
                share.RowCause = rawCause ;

                shareList.add(share);
            }

            if(regionalAccId!=null && (ownersToAcountMap == null ||  !ownersToAcountMap.containsKey(sa.UserId__c) || !ownersToAcountMap.get(sa.UserId__c).contains(regionalAccId)))
            {
                AccountShare shareRegional = new AccountShare();
                shareRegional.AccountId = regionalAccId;
                shareRegional.AccountAccessLevel = accAccessLevel;
                shareRegional.OpportunityAccessLevel = oppAccessLevel;
                shareRegional.UserOrGroupId = sa.UserId__c;
                shareRegional.RowCause = rawCause ;
                shareList.add(shareRegional);
            }
        }
        return shareList ;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns OpportunityShare records List
    * Inputs : Id , List<SharingAccess__c> ,String, String, String
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<OpportunityShare> opportunitySharing(Id sharedOppId, List<SharingAccess__c> sharing2WhoTable, String oppAccessLevel, String rawCause)
    {
        List<OpportunityShare> shareList = new List<OpportunityShare>();

        for (SharingAccess__c sa : sharing2WhoTable)
        {
            OpportunityShare share = new OpportunityShare();
            share.OpportunityId = sharedOppId;
            share.OpportunityAccessLevel = oppAccessLevel;
            share.UserOrGroupId = sa.UserId__c;
            share.RowCause = rawCause ;
            shareList.add(share);
        }
        return shareList ;
    }

    /******************************************************************************************************************************************************************
    * Author: Aviad Efergan
    * Company: Salesforce
    * Description: returns QuoteShare records List
    * Inputs : Id , List<SharingAccess__c> ,String, String, String
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<SBQQ__Quote__Share> quoteSharing(Id sharedQtId, List<SharingAccess__c> sharing2WhoTable, String qtAccessLevel, String rawCause)
    {
        List<SBQQ__Quote__Share> shareList = new List<SBQQ__Quote__Share>();
        for (SharingAccess__c sa : sharing2WhoTable){
            SBQQ__Quote__Share share = new SBQQ__Quote__Share();
            share.ParentId  = sharedQtId;
            share.AccessLevel  = qtAccessLevel;
            share.UserOrGroupId = sa.UserId__c;
            share.RowCause = rawCause ;
            shareList.add(share);
        }
        return shareList ;
    }

    /******************************************************************************************************************************************************************
    * Author: Aviad Efergan
    * Company: Salesforce
    * Description: maps the Sharing Access records table with LOB1 as key
    * Inputs : List<SharingAccess__c> , Map<String, Map <String, List<SharingAccess__c> >> , Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void mappingSharingAccessTable(List<SharingAccess__c> sharingTableList, Map<String, Map<String, List<SharingAccess__c>>> lob1toSharingAccessMap,
            Map<String, List<SharingAccess__c>> globalSharingAccessesMap )
    {
        for(SharingAccess__c sa : sharingTableList)
        {
            //build mapping with the global modifier
            if(sa.Global__c)
            {
                if(String.isEmpty(sa.LOB1__c))
                {
                    if(!globalSharingAccessesMap.containsKey('empty_lob_global'))
                    {
                        globalSharingAccessesMap.put('empty_lob_global', new List<SharingAccess__c>());
                    }
                    globalSharingAccessesMap.get('empty_lob_global').add(sa);
                }
                else
                {
                    if(!globalSharingAccessesMap.containsKey(sa.LOB1__c))
                    {
                        globalSharingAccessesMap.put(sa.LOB1__c, new List<SharingAccess__c>());
                    }
                    globalSharingAccessesMap.get(sa.LOB1__c).add(sa);
                }
        }
        //build mapping for lob1 to company name to sharing access
        if(String.isEmpty(sa.LOB1__c))
        {
            if(!lob1toSharingAccessMap.containsKey('empty_lob'))
            {
                lob1toSharingAccessMap.put('empty_lob', new Map<String, List<SharingAccess__c>>());
            }
            if(!lob1toSharingAccessMap.get('empty_lob').containsKey(sa.IMCDCompany__c))
            {
                lob1toSharingAccessMap.get('empty_lob').put(sa.IMCDCompany__c, new List<SharingAccess__c>());
            }
            lob1toSharingAccessMap.get('empty_lob').get(sa.IMCDCompany__c).add(sa);
        }
        else
        {
            if(!lob1toSharingAccessMap.containsKey(sa.LOB1__c))
            {
                lob1toSharingAccessMap.put(sa.LOB1__c, new Map<String, List<SharingAccess__c>>());
            }
            if(!lob1toSharingAccessMap.get(sa.LOB1__c).containsKey(sa.IMCDCompany__c))
            {
                lob1toSharingAccessMap.get(sa.LOB1__c).put(sa.IMCDCompany__c, new List<SharingAccess__c>());
            }
            lob1toSharingAccessMap.get(sa.LOB1__c).get(sa.IMCDCompany__c).add(sa);
        }
    }
}
/***********************************************************************************************************************************************************/

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: aggregates and maps Users to Sobject records that are shared to Users
    * Inputs : List<AccountLob__c>, Map<String, Map<String, List<SharingAccess__c> > > , Map<Id, List<SharingAccess__c>>, Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void mapSharedUsersToRelObject(Map<Id,List<SharingAccess__c> > sobjectIdsToShareAccsMap, Map<Id,Set<Id>> sobjectIdsToUsrIds)
    {
        for(Id sId : sobjectIdsToShareAccsMap.keySet())
        {
            sobjectIdsToUsrIds.put(sId, new Set<Id>());
        }
        for(Id sId : sobjectIdsToShareAccsMap.keySet())
        {
            for(SharingAccess__c sa : sobjectIdsToShareAccsMap.get(sId))
            {
                sobjectIdsToUsrIds.get(sId).add(sa.UserId__c);
            }
        }
    }

    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: divides sharingAccess List, by principal
   * Inputs : List<SharingAccess__c>, List<SharingAccess__c>, List<SharingAccess__c>
   * Test Class :
   * History :
   ******************************************************************************************************************************************************************/
    public static void divideByPrincipal(List<SharingAccess__c> SaListTodivide, List<SharingAccess__c> princiPalSaList, List<SharingAccess__c> nonPrincipalSaList)
    {
        for(SharingAccess__c sa : SaListTodivide)
        {
            if(sa.PrincipalId__c!=null)
            {
                principalSaList.add(sa);
            }
            else
            {
                nonPrincipalSaList.add(sa);
            }
        }
    }

    /******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: returns the SharingAccessList that does match by SharingAccess.Principal to OpportunityLine.Product.Principal for Lob&Company & Principal match in
* QueueableOppPrincipalRecalculateSharing
* Inputs : List<SBQQ__QuoteLine__c>, Map<String, Map <String, List<SharingAccess__c> > >
* Test Class :
* History :
********************************************************************************************************************************************************************/
    public static List<SharingAccess__c> filterByPrincipal(String lob, String imcdComp, OpportunityLineItem oli, Map<String, Map <String, List<SharingAccess__c> >> lob1toSharingAccessMap)
    {
        List<SharingAccess__c> filteredSaList = new List<SharingAccess__c>();

        for(SharingAccess__c sa : lob1toSharingAccessMap.get(lob).get(imcdComp))
        {
            if(sa.PrincipalId__c == oli.Product2.Principal__c)
            {
                filteredSaList.add(sa);
            }
        }
        return filteredSaList;
    }

/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: returns the SharingAccessList that does match by SharingAccess.Principal to OpportunityLine.Product.Principal for Lob&Global=TRUE & Principal match in
* QueueableOppPrincipalRecalculateSharing
* Inputs : List<SBQQ__QuoteLine__c>, Map<String, Map <String, List<SharingAccess__c> > >
* Test Class :
* History :
********************************************************************************************************************************************************************/
    public static List<SharingAccess__c> filterByPrincipal(String lob, OpportunityLineItem oli, Map<String, List<SharingAccess__c> > globalSharingAccessesMap)
    {
        List<SharingAccess__c> filteredSaList = new List<SharingAccess__c>();

        for(SharingAccess__c sa : globalSharingAccessesMap.get(lob))
        {
            if(sa.PrincipalId__c == oli.Product2.Principal__c)
            {
                filteredSaList.add(sa);
            }
        }
        return filteredSaList;
    }



    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: returns the SharingAccessList that does match by SharingAccess.Principal to QuoteLine.Product.Principal for Lob&Company&Principal match in
   * QueueableQtPrincipalRecalculateSharing
   * Inputs : List<SBQQ__QuoteLine__c>, Map<String, Map <String, List<SharingAccess__c> > >
   * Test Class :
   * History :
   ********************************************************************************************************************************************************************/
    public static List<SharingAccess__c> filterByPrincipal(String lob, String imcdComp, SBQQ__QuoteLine__c qli, Map<String, Map <String, List<SharingAccess__c> >> lob1toSharingAccessMap)
    {
        List<SharingAccess__c> filteredSaList = new List<SharingAccess__c>();

        for(SharingAccess__c sa : lob1toSharingAccessMap.get(lob).get(imcdComp))
        {
            if(sa.PrincipalId__c == qli.SBQQ__Product__r.Principal__c)
            {
                filteredSaList.add(sa);
            }
        }
        return filteredSaList;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns the SharingAccessList that does match by SharingAccess.Principal to QuoteLine.Product.Principal for Lob&Global=TRUE&Principal match in
    * QueueableQtPrincipalRecalculateSharing
    * Inputs : List<SBQQ__QuoteLine__c>, Map<String, Map <String, List<SharingAccess__c> > >
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<SharingAccess__c> filterByPrincipal(String lob, SBQQ__QuoteLine__c qli, Map<String, List<SharingAccess__c> > globalSharingAccessesMap)
    {
        List<SharingAccess__c> filteredSaList = new List<SharingAccess__c>();

        for(SharingAccess__c sa : globalSharingAccessesMap.get(lob))
        {
            if(sa.PrincipalId__c == qli.SBQQ__Product__r.Principal__c)
            {
                filteredSaList.add(sa);
            }
        }
        return filteredSaList;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: aggregates and maps SharingAccess records , based on AccountLoB list
    * Inputs : List<AccountLob__c>, Map<String, Map<String, List<SharingAccess__c> > > , Map<Id, List<SharingAccess__c>>, Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void aggregateRecordsToDelete(String className, List<AccountLob__c> newAccLOBList, Map<String, Map<String, List<SharingAccess__c> > > lob1toDeleteSharingAccessMap,
            Map<Id, List<SharingAccess__c>>accsToShareAccsMap, Map<String, List<SharingAccess__c> >globaltoDeleteSharingAccessesMap)
    {
        for(AccountLob__c al : newAccLOBList)
        {
            //deleting sharing on Account if LOB1 & IMCDCompany match
            if(lob1toDeleteSharingAccessMap.containsKey(al.LOB1__c) && lob1toDeleteSharingAccessMap.get(al.LOB1__c).containsKey(al.Account__r.IMCDCompany__c))
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 & IMCDCompany match',className,lob1toDeleteSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                //aggregating records to delete sharing from sold to account
                if(accsToShareAccsMap.containsKey(al.Account__c))
                {
                    accsToShareAccsMap.get(al.Account__c).addAll(lob1toDeleteSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                    accsToShareAccsMap.put(al.Account__c, tempList);
                }
                //aggregating records to delete sharing from regional account
                if(al.Account__r.ParentId!=null)
                {
                    //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 & IMCDCompany match',className,lob1toDeleteSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                    if(accsToShareAccsMap.containsKey(al.Account__r.ParentId))
                    {
                        accsToShareAccsMap.get(al.Account__r.ParentId).addAll(lob1toDeleteSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                    }
                    else
                    {
                        List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                        tempList.addAll(lob1toDeleteSharingAccessMap.get(al.LOB1__c).get(al.Account__r.IMCDCompany__c));
                        accsToShareAccsMap.put(al.Account__r.ParentId, tempList);
                    }
                }
            }
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: aggregates and maps SharingAccess records based on Opportunities List
    * Inputs : List<AccountLob__c>, Map<String, Map<String, List<SharingAccess__c> > > , Map<Id, List<SharingAccess__c>>, Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void aggregateRecordsToDelete(List<Opportunity> newOppList, Map<String, Map<String, List<SharingAccess__c> > > lob1toDeleteSharingAccessMap,
            Map<Id, List<SharingAccess__c>>accsToShareAccsMap, Map<Id, List<SharingAccess__c>>oppsToShareAccsMap, Map<String, List<SharingAccess__c> >globaltoDeleteSharingAccessesMap)
    {
        for(Opportunity op : newOppList)
        {
            Boolean globalShared = false;
            Boolean companyShared = false ;
            //deleting sharing Account if LOB1 & IMCDCompany match
            if(lob1toDeleteSharingAccessMap.containsKey(op.LOB1__c) && lob1toDeleteSharingAccessMap.get(op.LOB1__c).containsKey(op.Account.IMCDCompany__c))
            {
                companyShared = true ;
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 & IMCDCompany match','QueueableOppDeleteSharing',lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                //aggregating records to delete sharing from sold to account and Opportunity
                if(accsToShareAccsMap.containsKey(op.AccountId))
                {
                    accsToShareAccsMap.get(op.AccountId).addAll(lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                    accsToShareAccsMap.put(op.AccountId, tempList);
                }
                //aggregating records to delete sharing from regional account
                if(op.Account.ParentId!=null)
                {
                    //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 & IMCDCompany match','QueueableOppDeleteSharing',lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                    if(accsToShareAccsMap.containsKey(op.Account.ParentId))
                    {
                        accsToShareAccsMap.get(op.Account.ParentId).addAll(lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                    }
                    else
                    {
                        List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                        tempList.addAll(lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                        accsToShareAccsMap.put(op.Account.ParentId, tempList);
                    }
                }
            }
            //aggregating records to delete sharing from opportunity
            if(companyShared)
            {
                //SharingUtils.debugSharingReason('Opportunity','deleting sharing LOB1 & IMCDCompany match','QueueableOppDeleteSharing',lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                if(oppsToShareAccsMap.containsKey(op.Id))
                {
                    oppsToShareAccsMap.get(op.Id).addAll(lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(op.LOB1__c).get(op.Account.IMCDCompany__c));
                    oppsToShareAccsMap.put(op.Id, tempList);
                }
            }
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: aggregates and maps SharingAccess records based on Quotes
    * Inputs : List<AccountLob__c>, Map<String, Map<String, List<SharingAccess__c> > > , Map<Id, List<SharingAccess__c>>, Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void aggregateRecordsToDelete(List<SBQQ__Quote__c> newQuoteList, Map<String, Map<String, List<SharingAccess__c> > > lob1toDeleteSharingAccessMap,
            Map<Id, List<SharingAccess__c>>accsToShareAccsMap, Map<Id,List<SharingAccess__c>>quotesToShareAccsMap, Map<String, List<SharingAccess__c> >globaltoDeleteSharingAccessesMap)
    {
        for(SBQQ__Quote__c qt : newQuoteList)
        {
            Boolean globalShared = false;
            Boolean companyShared = false;
            //deleting sharing Account if LOB1 & IMCDCompany match
            if(lob1toDeleteSharingAccessMap.containsKey(qt.LOB1__c) && lob1toDeleteSharingAccessMap.get(qt.LOB1__c).containsKey(qt.SBQQ__Account__r.IMCDCompany__c))
            {
                companyShared = true;
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 & IMCDCompany match','QueueableQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                //aggregating records to delete sharing from sold to account
                if(accsToShareAccsMap.containsKey(qt.SBQQ__Account__c))
                {
                    accsToShareAccsMap.get(qt.SBQQ__Account__c).addAll(lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                    accsToShareAccsMap.put(qt.SBQQ__Account__c, tempList);
                }
                //aggregating records to delete sharing from regional account
                if(qt.SBQQ__Account__r.ParentId!=null)
                {
                    //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 & IMCDCompany match','QueueableQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                    if(accsToShareAccsMap.containsKey(qt.SBQQ__Account__r.ParentId))
                    {
                        accsToShareAccsMap.get(qt.SBQQ__Account__r.ParentId).addAll(lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                    }
                    else
                    {
                        List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                        tempList.addAll(lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                        accsToShareAccsMap.put(qt.SBQQ__Account__r.ParentId, tempList);
                    }
                }
            }
            //aggregating records to delete sharing from quote
            if(companyShared)
            {
                //SharingUtils.debugSharingReason('Quote','deleting sharing LOB1 & IMCDCompany match','QueueableQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                if(quotesToShareAccsMap.containsKey(qt.Id))
                {
                    quotesToShareAccsMap.get(qt.Id).addAll(lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(qt.LOB1__c).get(qt.SBQQ__Account__r.IMCDCompany__c));
                    quotesToShareAccsMap.put(qt.Id, tempList);
                }
            }
         }
    }
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: aggregates and maps SharingAccess records based on OpportunityLineItem
    * Inputs : List<AccountLob__c>, Map<String, Map<String, List<SharingAccess__c> > > , Map<Id, List<SharingAccess__c>>, Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void aggregateRecordsToDelete(List<OpportunityLineItem> newOliList, Map<String, Map<String, List<SharingAccess__c> > > lob1toDeleteSharingAccessMap,
            Map<Id, List<SharingAccess__c>>accsToShareAccsMap, Map<Id, List<SharingAccess__c>>oppsToShareAccsMap, Map<String, List<SharingAccess__c> >globaltoDeleteSharingAccessesMap)
    {
        List<SharingAccess__c> filteredSaLst = new List<SharingAccess__c>();
        for(OpportunityLineItem oli : newOliList)
        {
            Boolean companyshared = false;
            Boolean globalshared = false;
            Boolean emptyLob = false;
            Boolean emptyLobGlobal = false;

            //mapping sharing access to the quote and account soldto + Regional
            if(oli.Opportunity.LOB1__c != null)
            {
                if(lob1toDeleteSharingAccessMap.containsKey(oli.Opportunity.LOB1__c) && lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).containsKey(oli.Opportunity.Account.IMCDCompany__c))
                {
                    filteredSaLst = filterByPrincipal(oli.Opportunity.LOB1__c, oli.Opportunity.Account.IMCDCompany__c, oli, lob1toDeleteSharingAccessMap);
                    companyshared = true;
                    //SharingUtils.debugSharingReason('Opportunity','deleteng sharing LOB1 & IMCDCompany match','QueueablePrincipalOppDeleteSharing',lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                    if(!filteredSaLst.isEmpty() )
                    {
                        if (oppsToShareAccsMap.containsKey(oli.OpportunityId))
                        {
                            oppsToShareAccsMap.get(oli.OpportunityId).addAll(filteredSaLst) ;
                        }
                        else
                        {
                            List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                            tempList.addAll(filteredSaLst);
                            oppsToShareAccsMap.put(oli.OpportunityId, tempList);
                        }
                    }
                }
                if(globaltoDeleteSharingAccessesMap.containsKey(oli.Opportunity.LOB1__c))
                {
                    filteredSaLst = filterByPrincipal(oli.Opportunity.LOB1__c, oli, globaltoDeleteSharingAccessesMap);
                    globalshared = true;
                    //SharingUtils.debugSharingReason('Opportunity','deleteng sharing LOB1 match and SharingAccess record is Global','QueueablePrincipalOppDeleteSharing',globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                    if(!filteredSaLst.isEmpty())
                    {
                        if (oppsToShareAccsMap.containsKey(oli.OpportunityId))
                        {
                            oppsToShareAccsMap.get(oli.OpportunityId).addAll(filteredSaLst) ;
                        }
                        else
                        {
                            List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                            tempList.addAll(filteredSaLst);
                            oppsToShareAccsMap.put(oli.OpportunityId, tempList);
                        }
                    }
                }
                if(lob1toDeleteSharingAccessMap.containsKey('empty_lob') && lob1toDeleteSharingAccessMap.get('empty_lob').containsKey(oli.Opportunity.Account.IMCDCompany__c))
                {
                    filteredSaLst = filterByPrincipal('empty_lob', oli.Opportunity.Account.IMCDCompany__c, oli, lob1toDeleteSharingAccessMap);
                    emptyLob = true;
                    if(!filteredSaLst.isEmpty())
                    {
                        //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 & IMCDCompany match','QueueablePrincipalOppDeleteSharing',lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                        if (oppsToShareAccsMap.containsKey(oli.OpportunityId))
                        {
                            oppsToShareAccsMap.get(oli.OpportunityId).addAll(filteredSaLst) ;
                        }
                        else
                        {
                            List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                            tempList.addAll(filteredSaLst);
                            oppsToShareAccsMap.put(oli.OpportunityId, tempList);
                        }
                    }
                }
                //Sharing access without LOB - Global
                if(globaltoDeleteSharingAccessesMap.containsKey('empty_lob_global'))
                {
                    emptyLobGlobal = true;
                    filteredSaLst = filterByPrincipal('empty_lob_global', oli, globaltoDeleteSharingAccessesMap);
                    if(!filteredSaLst.isEmpty())
                    {
                        if (oppsToShareAccsMap.containsKey(oli.OpportunityId))
                        {
                            oppsToShareAccsMap.get(oli.OpportunityId).addAll(filteredSaLst) ;
                        }
                        else
                        {
                            List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                            tempList.addAll(filteredSaLst);
                            oppsToShareAccsMap.put(oli.OpportunityId, tempList);
                        }
                    }
                }
            }
            mapSharingAccessToAccount(oli, lob1toDeleteSharingAccessMap, globaltoDeleteSharingAccessesMap, accsToShareAccsMap,
                    companyshared, globalshared, emptyLob, emptyLobGlobal, filteredSaLst);
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: aggregates and maps SharingAccess records based on QuoteLineItem
    * Inputs : List<AccountLob__c>, Map<String, Map<String, List<SharingAccess__c> > > , Map<Id, List<SharingAccess__c>>, Map<String, List<SharingAccess__c> >
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void aggregateRecordsToDelete(List<SBQQ__QuoteLine__c> newQuoteLineList, Map<String, Map<String, List<SharingAccess__c> > > lob1toDeleteSharingAccessMap,
            Map<Id, List<SharingAccess__c>>accsToShareAccsMap, Map<Id, List<SharingAccess__c>>quotesToShareAccsMap, Map<String, List<SharingAccess__c> >globaltoDeleteSharingAccessesMap)
    {
        List<SharingAccess__c> filteredSaLst = new List<SharingAccess__c>();
        for(SBQQ__QuoteLine__c qli : newQuoteLineList)
        {
            Boolean companyshared = false;
            Boolean globalshared = false;
            Boolean emptyLob = false;
            Boolean emptyLobGlobal = false;

            //mapping sharing access to the quote and account soldto + Regional

            if(qli.SBQQ__Quote__r.LOB1__c != null)
            {
                if(lob1toDeleteSharingAccessMap.containsKey(qli.SBQQ__Quote__r.LOB1__c) && lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).containsKey(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c))
                {
                    filteredSaLst = SharingUtils.filterByPrincipal(qli.SBQQ__Quote__r.LOB1__c, qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, qli, lob1toDeleteSharingAccessMap);
                    companyshared = true;
                    //SharingUtils.debugSharingReason('Quote','deleteng sharing LOB1 & IMCDCompany match','QueueablePrincipalQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                    if(!filteredSaLst.isEmpty() )
                    {
                        if (quotesToShareAccsMap.containsKey(qli.SBQQ__Quote__c))
                        {
                            quotesToShareAccsMap.get(qli.SBQQ__Quote__c).addAll(lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c)) ;
                        }
                        else
                        {
                            List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                            tempList.addAll(lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                            quotesToShareAccsMap.put(qli.SBQQ__Quote__c, tempList);
                        }
                    }
                }
                if (globaltoDeleteSharingAccessesMap.containsKey(qli.SBQQ__Quote__r.LOB1__c))
                {
                    filteredSaLst = SharingUtils.filterByPrincipal(qli.SBQQ__Quote__r.LOB1__c, qli, globaltoDeleteSharingAccessesMap);
                    globalshared = true ;
                    //SharingUtils.debugSharingReason('Quote','deleteng sharing LOB1 match and SharingAccess record is Global','QueueablePrincipalQuoteDeleteSharing',globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
                    if(!filteredSaLst.isEmpty() )
                    {
                        if (quotesToShareAccsMap.containsKey(qli.SBQQ__Quote__c))
                        {
                            quotesToShareAccsMap.get(qli.SBQQ__Quote__c).addAll(globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c)) ;
                        }
                        else
                        {
                            List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                            tempList.addAll(globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
                            quotesToShareAccsMap.put(qli.SBQQ__Quote__c, tempList);
                        }
                    }
                }
            }
            if(lob1toDeleteSharingAccessMap.containsKey('empty_lob') && lob1toDeleteSharingAccessMap.get('empty_lob').containsKey(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c))
            {
                filteredSaLst = SharingUtils.filterByPrincipal('empty_lob', qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c, qli, lob1toDeleteSharingAccessMap);
                emptyLob = true;
                if(!filteredSaLst.isEmpty())
                {
                    if (quotesToShareAccsMap.containsKey(qli.SBQQ__Quote__c))
                    {
                        quotesToShareAccsMap.get(qli.SBQQ__Quote__c).addAll(filteredSaLst) ;
                    }
                    else
                    {
                        List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                        tempList.addAll(filteredSaLst);
                        quotesToShareAccsMap.put(qli.SBQQ__Quote__c, tempList);
                    }
                }
            }
            //Sharing access without LOB - Global
            if(globaltoDeleteSharingAccessesMap.containsKey('empty_lob_global'))
            {
                filteredSaLst = SharingUtils.filterByPrincipal('empty_lob_global', qli, globaltoDeleteSharingAccessesMap);
                emptyLobGlobal = true;
                if(!filteredSaLst.isEmpty())
                {
                    if (quotesToShareAccsMap.containsKey(qli.SBQQ__Quote__c))
                    {
                        quotesToShareAccsMap.get(qli.SBQQ__Quote__c).addAll(filteredSaLst) ;
                    }
                    else
                    {
                        List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                        tempList.addAll(filteredSaLst);
                        quotesToShareAccsMap.put(qli.SBQQ__Quote__c, tempList);
                    }
                }
            }
            mapSharingAccessToAccount(qli, lob1toDeleteSharingAccessMap, globaltoDeleteSharingAccessesMap, accsToShareAccsMap,
                    companyshared, globalshared, emptyLob, emptyLobGlobal, filteredSaLst);
        }
    }

    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: aggregates and maps SharingAccess to accounts : sold to + regional and to Opportunities
   * Inputs : OpportunityLineItem,  Map<String, Map<String, List<SharingAccess__c> >>,Map<String, List<SharingAccess__c>>, Map<Id,List<SharingAccess__c>>, Boolean, Boolean
   * Test Class :
   * History :
   ******************************************************************************************************************************************************************/
    public static void mapSharingAccessToAccount(OpportunityLineItem oli, Map<String, Map<String, List<SharingAccess__c> > >lob1toDeleteSharingAccessMap, Map<String, List<SharingAccess__c>>globaltoDeleteSharingAccessesMap,
            Map<Id,List<SharingAccess__c>>accsToShareAccsMap, Boolean companyshared, Boolean globalshared, Boolean emptyLob, Boolean emptyLobGlobal, List<SharingAccess__c> filteredSaLst)
    {
        if(companyshared)
        {
            //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 & IMCDCompany match','QueueablePrincipalOppDeleteSharing',lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
            if(accsToShareAccsMap.containsKey(oli.Opportunity.AccountId))
            {
                accsToShareAccsMap.get(oli.Opportunity.AccountId).addAll(lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c)) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                accsToShareAccsMap.put(oli.Opportunity.AccountId, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(oli.Opportunity.Account.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 & IMCDCompany match','QueueablePrincipalOppDeleteSharing',lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                if (accsToShareAccsMap.get(oli.Opportunity.Account.ParentId) != null)
                {
                    accsToShareAccsMap.get(oli.Opportunity.Account.ParentId).addAll(lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c)) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(oli.Opportunity.LOB1__c).get(oli.Opportunity.Account.IMCDCompany__c));
                    accsToShareAccsMap.put(oli.Opportunity.Account.ParentId, tempList);
                }
            }
        }
        if(globalshared)
        {
            //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 match and SharingAccess record is Global','QueueablePrincipalOppDeleteSharing',globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c));
            if(accsToShareAccsMap.containsKey(oli.Opportunity.AccountId))
            {
                accsToShareAccsMap.get(oli.Opportunity.AccountId).addAll(globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c)) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                accsToShareAccsMap.put(oli.Opportunity.AccountId, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(oli.Opportunity.Account.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 match and SharingAccess record is Global','QueueablePrincipalOppDeleteSharing',globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                if (accsToShareAccsMap.get(oli.Opportunity.Account.ParentId)!=null)
                {
                    accsToShareAccsMap.get(oli.Opportunity.Account.ParentId).addAll(globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c)) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                    accsToShareAccsMap.put(oli.Opportunity.Account.ParentId, tempList);
                }
            }
        }
        if(emptyLob)
        {
            if(accsToShareAccsMap.containsKey(oli.Opportunity.AccountId))
            {
                accsToShareAccsMap.get(oli.Opportunity.AccountId).addAll(filteredSaLst) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(filteredSaLst);
                accsToShareAccsMap.put(oli.Opportunity.AccountId, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(oli.Opportunity.Account.ParentId!=null)
            {
                if (accsToShareAccsMap.get(oli.Opportunity.Account.ParentId) != null)
                {
                    accsToShareAccsMap.get(oli.Opportunity.Account.ParentId).addAll(filteredSaLst) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(filteredSaLst);
                    accsToShareAccsMap.put(oli.Opportunity.Account.ParentId, tempList);
                }
            }
        }
        if(emptyLobGlobal)
        {
            if(accsToShareAccsMap.containsKey(oli.Opportunity.AccountId))
            {
                accsToShareAccsMap.get(oli.Opportunity.AccountId).addAll(filteredSaLst) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(filteredSaLst);
                accsToShareAccsMap.put(oli.Opportunity.AccountId, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(oli.Opportunity.Account.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 match and SharingAccess record is Global','QueueablePrincipalOppDeleteSharing',globaltoDeleteSharingAccessesMap.get(oli.Opportunity.LOB1__c));
                if (accsToShareAccsMap.get(oli.Opportunity.Account.ParentId)!=null)
                {
                    accsToShareAccsMap.get(oli.Opportunity.Account.ParentId).addAll(filteredSaLst) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(filteredSaLst);
                    accsToShareAccsMap.put(oli.Opportunity.Account.ParentId, tempList);
                }
            }
        }
    }
    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: aggregates and maps SharingAccess to accounts : sold to + regional and to Quotes
   * Inputs : SBQQ__QuoteLine__c,  Map<String, Map<String, List<SharingAccess__c> >>,Map<String, List<SharingAccess__c>>, Map<Id,List<SharingAccess__c>>,
   * Boolean, Boolean
   * Test Class :
   * History :
   ******************************************************************************************************************************************************************/
    public static void mapSharingAccessToAccount(SBQQ__QuoteLine__c qli, Map<String, Map<String, List<SharingAccess__c> >>lob1toDeleteSharingAccessMap, Map<String, List<SharingAccess__c>>globaltoDeleteSharingAccessesMap,
            Map<Id,List<SharingAccess__c>> accsToShareAccsMap, Boolean companyshared, Boolean globalshared, Boolean emptyLob, Boolean emptyLobGlobal, List<SharingAccess__c> filteredSaLst)
    {
        if(companyshared)
        {
            //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 & IMCDCompany match','QueueablePrincipalQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
            if(accsToShareAccsMap.containsKey(qli.SBQQ__Quote__r.SBQQ__Account__c))
            {
                accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__c).addAll(lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c)) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__c, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 & IMCDCompany match','QueueablePrincipalQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                if(accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId) != null)
                {
                    accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId).addAll(lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c)) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                    accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId, tempList);
                }
            }
        }
        if(globalshared)
        {
            //SharingUtils.debugSharingReason('Account','deleteng sharing on the soldTo LOB1 match and SharingAccess record is Global','QueueablePrincipalQuoteDeleteSharing',globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
            if(accsToShareAccsMap.containsKey(qli.SBQQ__Quote__r.SBQQ__Account__c))
            {
                accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__c).addAll(globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c)) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
                accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__c, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 match and SharingAccess record is Global','QueueablePrincipalQuoteDeleteSharing',globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
                if(accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId) != null)
                {
                    accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId).addAll(globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c)) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
                    accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId, tempList);
                }
            }
        }
        if(emptyLob)
        {
            if(accsToShareAccsMap.containsKey(qli.SBQQ__Quote__r.SBQQ__Account__c))
            {
                accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__c).addAll(filteredSaLst) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(filteredSaLst);
                accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__c, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 & IMCDCompany match','QueueablePrincipalQuoteDeleteSharing',lob1toDeleteSharingAccessMap.get(qli.SBQQ__Quote__r.LOB1__c).get(qli.SBQQ__Quote__r.SBQQ__Account__r.IMCDCompany__c));
                if(accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId) != null)
                {
                    accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId).addAll(filteredSaLst) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(filteredSaLst);
                    accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId, tempList);
                }
            }
        }
        if(emptyLobGlobal)
        {
            if(accsToShareAccsMap.containsKey(qli.SBQQ__Quote__r.SBQQ__Account__c))
            {
                accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__c).addAll(filteredSaLst) ;
            }
            else
            {
                List<SharingAccess__c> tempList = new List<SharingAccess__c>() ;
                tempList.addAll(filteredSaLst);
                accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__c, tempList);
            }
            //aggregating records to delete sharing from regional account
            if(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId!=null)
            {
                //SharingUtils.debugSharingReason('Account','deleteng sharing on the C5 LOB1 match and SharingAccess record is Global','QueueablePrincipalQuoteDeleteSharing',globaltoDeleteSharingAccessesMap.get(qli.SBQQ__Quote__r.LOB1__c));
                if(accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId) != null)
                {
                    accsToShareAccsMap.get(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId).addAll(filteredSaLst) ;
                }
                else
                {
                    List<SharingAccess__c> tempList = new List<SharingAccess__c>();
                    tempList.addAll(filteredSaLst);
                    accsToShareAccsMap.put(qli.SBQQ__Quote__r.SBQQ__Account__r.ParentId, tempList);
                }
            }
        }
    }
    /***********************************************************************************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: map AccountOwners to the Accounts they own for Sold To + Regional C2 Accs , for the given accountId set, or null as param
    * Inputs : Set<Id> relevantAccIds
    * Test Class :
    * History :
    **************************************************************************************************************************************************************************************/
    public static Map<Id,Set<Id>> mapOwnersToAcoountAccountsByIds(Set<Id> relevantIds)
    {
        Map<Id,Account> accountsMap = new Map<Id,Account>();
        List<Id> checkTypeList = new List<Id>();

        if(relevantIds != null && !relevantIds.isEmpty())
        {
            checkTypeList.addAll(relevantIds);
        }

        if(relevantIds == null && Test.isRunningTest())
        {
            accountsMap = new Map<Id,Account>([SELECT Id,OwnerId, RecordTypeId FROM Account WHERE RecordType.DeveloperName =: 'Customer_Sold_To' OR RecordType.DeveloperName =: 'Customer_Regional']);
        }
        else if(!checkTypeList.isEmpty() && checkTypeList[0].getSobjectType() == Schema.Account.SObjectType)
        {
            accountsMap = new Map<Id,Account>([SELECT Id,OwnerId FROM Account WHERE Id IN : relevantIds ]);
        }
        else if(!checkTypeList.isEmpty() && checkTypeList[0].getSobjectType() == Schema.User.SobjectType)
        {
            accountsMap = new Map<Id,Account>([SELECT Id,OwnerId FROM Account WHERE OwnerId IN : relevantIds]);
        }

        Map<Id, Set<Id>> ownersToAccountsMap = new Map<Id, Set<Id>>();

        if(accountsMap!=null && !accountsMap.isEmpty())
        {
            for(Id accId : accountsMap.KeySet())
            {
                if(ownersToAccountsMap.keySet().contains(accountsMap.get(accId).OwnerId) )
                {
                    ownersToAccountsMap.get(accountsMap.get(accId).OwnerId).add(accId);
                }
                else
                {
                    Set<Id> accIds = new Set<Id>();
                    accIds.add(accId);
                    ownersToAccountsMap.put(accountsMap.get(accId).OwnerId, accIds);
                }
            }
            return ownersToAccountsMap;
        }
        return null;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: prints the reason for sharing the Account/Opportunity/Quote to standard debug
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void debugSharingReason(String sobj, String reason, String runningContext, List<SharingAccess__c> toWhom)
    {
        System.debug('+++ Sharing the Sobject: ' + sobj);
        System.debug('+++ Sharing reason : ' + reason);
        System.debug('+++ Running Context: ' + runningContext);
        for(SharingAccess__c sa : toWhom)
        {
            system.debug('+++Sharing Access Id : ' + sa.Id + ' ' + 'User Id : ' + sa.UserId__c);
        }
    }

   /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: limits list of sharing records to DML limit allowed in current transaction, used in classes where hitting the DML 10000 limit
    * Inputs : List<AccountShare>, List<AccountShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<AccountShare> limitListSize(List<AccountShare> splittedList, List<AccountShare> newListforValues, Integer dmlLimit)
    {
        if(splittedList.size() > 0)
        {
            Integer remainsSize = splittedList.size() - dmlLimit ;
            for(Integer i = remainsSize - 1 ; i >= 0; i--)
            {
                AccountShare temp = new AccountShare();
                temp = splittedList.get(i);
                newListforValues.add(temp);
            }
            for(Integer i = remainsSize - 1; i >= 0; i--)
            {
                splittedList.remove(i);
            }
        }
        return newListforValues;
    }


    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: limits list of sharing records for OpportunityShare to DML limit allowed in current transaction records, used in classes where hitting the DML 10000 limit
    * Inputs : List<OpportunityShare>, List<OpportunityShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<OpportunityShare> limitListSize(List<OpportunityShare> splittedList, List<OpportunityShare> newListforValues, Integer dmlLimit)
    {
        if(splittedList.size() > 0 )
        {
            Integer remainsSize = splittedList.size() - dmlLimit ;
            for(Integer i = remainsSize - 1 ; i >= 0; i--)
            {
                OpportunityShare temp = new OpportunityShare();
                temp = splittedList.get(i);
                newListforValues.add(temp);
            }
            for(Integer i = remainsSize - 1; i >= 0; i--)
            {
                splittedList.remove(i);
            }
        }
        return newListforValues;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: limits list of sharing records to DML limit allowed in current transaction, used in classes where hitting the DML 10000 limit
    * Inputs : List<SBQQ__Quote__Share>, List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static List<SBQQ__Quote__Share> limitListSize(List<SBQQ__Quote__Share> splittedList, List<SBQQ__Quote__Share> newListforValues, Integer dmlLimit)
    {
        if(splittedList.size() > 0)
        {
            Integer remainsSize = splittedList.size() - dmlLimit ;
            for(Integer i = remainsSize - 1 ; i >= 0; i--)
            {
                SBQQ__Quote__Share temp = new SBQQ__Quote__Share();
                temp = splittedList.get(i);
                newListforValues.add(temp);
            }
            for(Integer i = remainsSize - 1; i >= 0; i--)
            {
                splittedList.remove(i);
            }
        }
        return newListforValues;
    }

    /******************************************************************************************************************************************************************
       * Author: Eli Pogorelov
       * Company: Salesforce
       * Description: removes duplicate in AccountShare list, called both upon Insert and Delete of AccountShare records
       * Inputs : List<AccountShare>
       * Test Class :
       * History :
       ********************************************************************************************************************************************************************/
    public static void removeListDups(List<AccountShare>listToremoveDups)
    {
        Set<String> uniqueIdSet = new Set<String>();
        for(AccountShare acShare : listToremoveDups)
        {
            if(acShare.AccountId!=null && acShare.UserOrGroupId !=null)
            {
                if(acShare.Id != null)
                {
                    uniqueIdSet.add(String.ValueOf(acShare.AccountId) + ' ' + String.valueOf(acShare.UserOrGroupId) + '*' + acShare.Id);
                }
                else
                {
                    uniqueIdSet.add(String.ValueOf(acShare.AccountId) + ' ' + String.valueOf(acShare.UserOrGroupId) + '*' + '');
                }
            }
        }
        listToremoveDups.clear();
        for(String uniqueCom : uniqueIdSet)
        {
            if(String.isNotBlank(uniqueCom.substringAfter('*')))
            {
                listToremoveDups.add(new AccountShare(
                        Id = Id.valueOf(uniqueCom.substringAfter('*')),
                        AccountId = Id.valueOf(uniqueCom.substringBefore(' ')),
                        AccountAccessLevel = Label.READ_WRITE_ACCESS,
                        OpportunityAccessLevel = Label.NO_ACCESS,
                        UserOrGroupId = Id.valueOf(uniqueCom.substringBetween(' ','*')),
                        RowCause = Label.MANUAL_RAW_CAUSE ) ) ;
            }
            else
            {
                listToremoveDups.add(new AccountShare(AccountId = Id.valueOf(uniqueCom.substringBefore(' ')),
                        AccountAccessLevel = Label.READ_WRITE_ACCESS,
                        OpportunityAccessLevel = Label.NO_ACCESS,
                        UserOrGroupId = Id.valueOf(uniqueCom.substringBetween(' ','*')),
                        RowCause = Label.MANUAL_RAW_CAUSE ) ) ;
            }
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: removes duplicate in OpportunityShare list called both upon Insert and Delete of OpportunityShare records
    * Inputs : List<AccountShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void removeListDups(List<OpportunityShare>listToremoveDups)
    {
        Set<String> uniqueIdSet = new Set<String>();
        for(OpportunityShare opShare : listToremoveDups)
        {
            if(opShare.OpportunityId !=null && opShare.UserOrGroupId!=null)
            {
                if(opShare.Id!=null)
                {
                    uniqueIdSet.add(String.ValueOf(opShare.OpportunityId) + ' ' + String.valueOf(opShare.UserOrGroupId) + '*' + opShare.Id);
                }
                else
                {
                    uniqueIdSet.add(String.ValueOf(opShare.OpportunityId) + ' ' + String.valueOf(opShare.UserOrGroupId) + '*' + '');
                }
            }
        }
        listToremoveDups.clear();
        for(String uniqueCom : uniqueIdSet)
        {
            if(String.isNotBlank(uniqueCom.substringAfter('*')))
            {
                listToremoveDups.add(new OpportunityShare(
                        Id = Id.valueOf(uniqueCom.substringAfter('*')),
                        OpportunityId = Id.valueOf(uniqueCom.substringBefore(' ')),
                        OpportunityAccessLevel = Label.READ_WRITE_ACCESS,
                        UserOrGroupId = Id.valueOf(uniqueCom.substringBetween(' ','*')),
                        RowCause = Label.MANUAL_RAW_CAUSE)) ;
            }
            else
            {
                listToremoveDups.add(new OpportunityShare(
                        OpportunityId = Id.valueOf(uniqueCom.substringBefore(' ')),
                        OpportunityAccessLevel = Label.READ_WRITE_ACCESS,
                        UserOrGroupId = Id.valueOf(uniqueCom.substringBetween(' ','*')),
                        RowCause = Label.MANUAL_RAW_CAUSE)) ;
            }
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: removes duplicate in QuoteShare list, called both upon Insert and Delete of QuoteShare records
    * Inputs : List<AccountShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void removeListDups(List<SBQQ__Quote__Share>listToremoveDups)
    {
        Set<String> uniqueIdSet = new Set<String>();
        for(SBQQ__Quote__Share qtShare : listToremoveDups)
        {
            if(qtShare.ParentId !=null && qtShare.UserOrGroupId !=null)
            {
                if(qtShare.Id!=null)
                {
                    uniqueIdSet.add(String.ValueOf(qtShare.ParentId) + ' ' + String.valueOf(qtShare.UserOrGroupId) + '*' + qtShare.Id);
                }
                else
                {
                    uniqueIdSet.add(String.ValueOf(qtShare.ParentId) + ' ' + String.valueOf(qtShare.UserOrGroupId) + '*' + '');
                }
            }
        }
        listToremoveDups.clear();
        for(String uniqueCom : uniqueIdSet)
        {
            if(String.isNotBlank(uniqueCom.substringAfter('*')))
            {
                listToremoveDups.add(new SBQQ__Quote__Share(
                        Id = Id.valueOf(uniqueCom.substringAfter('*')),
                        ParentId = Id.valueOf(uniqueCom.substringBefore(' ')),
                        AccessLevel = Label.READ_WRITE_ACCESS,
                        UserOrGroupId = Id.valueOf(uniqueCom.substringBetween(' ','*')),
                        RowCause = Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c)) ;
            }
            else
            {
                listToremoveDups.add(new SBQQ__Quote__Share(
                        ParentId = Id.valueOf(uniqueCom.substringBefore(' ')),
                        AccessLevel = Label.READ_WRITE_ACCESS,
                        UserOrGroupId = Id.valueOf(uniqueCom.substringBetween(' ','*')),
                        RowCause = Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c)) ;
            }
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: checks if AccountShare list exceeding DML 10000 limit and then splits the list, and inserts/delete (depending on the flag parameter) the rest of the records
    * made for QueueableAccLobRecalculateSharing, QueueableAccLobDeleteSharing
    * Inputs : List<AccountShare>,List<AccountShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void checkForDMLlimitAndInsertOrDeleteSharing(List<AccountShare> accShareToInsert, List<AccountShare> accSharepassedToQueueble, Boolean insertFlag)
    {
        if(accShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
        {
            accSharepassedToQueueble.addAll(SharingUtils.limitListSize(accShareToInsert,accSharepassedToQueueble,SharingUtils.numOfDMLThatCanBeProcessed()) );
        }
        if(insertFlag)
        {
            dmlOperationOnShareRecords(accShareToInsert, true);
        }
        else
        {
            dmlOperationOnShareRecords(accShareToInsert, false);
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: checks if AccountShare or OpportunityShare list exceeding DML 10000 limit and then splits the list, and inserts/delete
    * (depending on the flag parameter) the rest of the records
    * made for QueueableOppRecalculateSharing,QueueableOppDeleteSharing
    * Inputs : List<AccountShare>, List<AccountShare>, List<OpportunityShare>, List<OpportunityShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void checkForDMLlimitAndInsertOrDeleteSharing(List<AccountShare> accShareToInsert, List<AccountShare> accSharepassedToQueueble,
            List<OpportunityShare> oppShareToInsert, List<OpportunityShare> oppSharepassedToQueueble, Boolean insertFlag)
    {
        if(accShareToInsert.size() + oppShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
        {
            //AccountShare >= then DML limit for transaction
            if(accShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
            {
                accSharepassedToQueueble.addAll(SharingUtils.limitListSize(accShareToInsert, accSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
                oppSharepassedToQueueble.addAll(oppShareToInsert);
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accShareToInsert, false);
                }
            }
            //OpportunityShare >= then DML limit for transaction
            else if(oppShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
            {
                oppSharepassedToQueueble.addAll(SharingUtils.limitListSize(oppShareToInsert, oppSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
                accSharepassedToQueueble.addAll(accShareToInsert);
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(oppShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(oppShareToInsert, false);
                }
            }
            //AccountShare + OpportunityShare >= then DML limit for transaction
            else if(accShareToInsert.size() < SharingUtils.numOfDMLThatCanBeProcessed() && oppShareToInsert.size() < SharingUtils.numOfDMLThatCanBeProcessed())
            {
                Integer calculateLimitAfterAccShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accShareToInsert.size();
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accShareToInsert, false);
                }
                oppSharepassedToQueueble.addAll(SharingUtils.limitListSize(oppShareToInsert, oppSharepassedToQueueble, calculateLimitAfterAccShareDML) );
                if(calculateLimitAfterAccShareDML > 0 && insertFlag)
                {
                    dmlOperationOnShareRecords(oppShareToInsert, true);
                }
                else if(calculateLimitAfterAccShareDML > 0 && !insertFlag)
                {
                    dmlOperationOnShareRecords(oppShareToInsert, false);
                }
            }
        }
        // Can insert/delete all AccountShare & OpportunityShare in current transaction
        else
        {
            if(insertFlag)
            {
                dmlOperationOnShareRecords(oppShareToInsert, true);
                dmlOperationOnShareRecords(accShareToInsert, true);
            }
            else
            {
                dmlOperationOnShareRecords(oppShareToInsert, false);
                dmlOperationOnShareRecords(accShareToInsert, false);
            }
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: checks if AccountShare or QuoteShare list exceeding DML 10000 limit and then splits the list, and inserts/delete (depending on the flag parameter)
    * the rest of the records
    * made for QueueableQuoteRecalculateSharing,QueueableQtPrincipalRecalculateSharing
    * Inputs : List<AccountShare>, List<AccountShare>, List<OpportunityShare>,  List<SBQQ__Quote__Share>,  List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void checkForDMLlimitAndInsertOrDeleteSharing(List<AccountShare> accShareToInsert, List<AccountShare> accSharepassedToQueueble,
            List<OpportunityShare> oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtShareToInsert, List<SBQQ__Quote__Share>qtSharepassedToQueueble, Boolean insertFlag)
    {
        if(accShareToInsert.size() + qtShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
        {
            //AccountShare >= then DML limit for transaction
            if(accShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
            {
                accSharepassedToQueueble.addAll(SharingUtils.limitListSize(accShareToInsert, accSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
                qtSharepassedToQueueble.addAll(qtShareToInsert);
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accShareToInsert, false);
                }
            }
            //QuoteShare >= then DML limit for transaction
            else if(qtShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
            {
                qtSharepassedToQueueble.addAll(SharingUtils.limitListSize(qtShareToInsert, qtSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
                accSharepassedToQueueble.addAll(accShareToInsert);
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(qtShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(qtShareToInsert, false);
                }
            }
            //AccountShare + QuoteShare >= then DML limit for transaction
            else if(accShareToInsert.size() < SharingUtils.numOfDMLThatCanBeProcessed() && qtShareToInsert.size() < SharingUtils.numOfDMLThatCanBeProcessed())
            {
                Integer calculateLimitAfterAccShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accShareToInsert.size();
                dmlOperationOnShareRecords(accShareToInsert, insertFlag);
                qtSharepassedToQueueble.addAll(SharingUtils.limitListSize(qtShareToInsert, qtSharepassedToQueueble, calculateLimitAfterAccShareDML) );
                if(calculateLimitAfterAccShareDML > 0 && insertFlag)
                {
                    dmlOperationOnShareRecords(qtShareToInsert, true);
                }
                else if(calculateLimitAfterAccShareDML > 0 && !insertFlag)
                {
                    dmlOperationOnShareRecords(qtShareToInsert, false);
                }

            }
        }
        else
        {
            if(insertFlag)
            {
                dmlOperationOnShareRecords(accShareToInsert, true);
                dmlOperationOnShareRecords(qtShareToInsert, true);
            }
            else
            {
                dmlOperationOnShareRecords(accShareToInsert, false);
                dmlOperationOnShareRecords(qtShareToInsert, false);
            }

            Integer calculateLimitAfterAccAndQuoteShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accShareToInsert.size() - qtShareToInsert.size();
            //if we have remains from OpportunityShare chk possibility to insert/delete  some of them
            if(calculateLimitAfterAccAndQuoteShareDML > 0)
            {
                SharingUtils.chkRemainsOfOppShares(calculateLimitAfterAccAndQuoteShareDML,oppSharepassedToQueueble, insertFlag);
            }
        }
    }
    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: checks if AccountShare or QuoteShare list exceeding DML 10000 limit and then splits the list, and inserts/delete (depending on the flag parameter) the rest of the records
   * made for QueueableOppPrincipalRecalculateSharing
   * Inputs : List<AccountShare>, List<AccountShare>, List<OpportunityShare>, List<OpportunityShare>,  List<SBQQ__Quote__Share>
   * Test Class :
   * History :
   ********************************************************************************************************************************************************************/
    public static void checkForDMLlimitAndInsertOrDeleteSharing(List<AccountShare> accShareToInsert, List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppShareToInsert,
            List<OpportunityShare> oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble, Boolean insertFlag)
    {
        if(accShareToInsert.size() + oppShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
        {
            //AccountShare >= then DML limit for transaction
            if(accShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
            {
                accSharepassedToQueueble.addAll(SharingUtils.limitListSize(accShareToInsert, accSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
                oppSharepassedToQueueble.addAll(oppShareToInsert);
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accShareToInsert, false);
                }
            }
            //OpportunityShare >= then DML limit for transaction
            else if(oppShareToInsert.size() >= SharingUtils.numOfDMLThatCanBeProcessed())
            {
                oppSharepassedToQueueble.addAll(SharingUtils.limitListSize(oppShareToInsert, oppSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
                accSharepassedToQueueble.addAll(accShareToInsert);
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(oppShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(oppShareToInsert, false);
                }
            }
            //AccountShare + OpportunityShare >= then DML limit for transaction
            else if(accShareToInsert.size() < SharingUtils.numOfDMLThatCanBeProcessed() && oppShareToInsert.size() < SharingUtils.numOfDMLThatCanBeProcessed())
            {
                Integer calculateLimitAfterAccShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accShareToInsert.size();
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accShareToInsert, false);

                }
                oppSharepassedToQueueble.addAll(SharingUtils.limitListSize(oppShareToInsert, oppSharepassedToQueueble, calculateLimitAfterAccShareDML) );
                if(calculateLimitAfterAccShareDML > 0 && insertFlag)
                {
                    dmlOperationOnShareRecords(oppShareToInsert, true);
                }
                else
                {
                    dmlOperationOnShareRecords(oppShareToInsert, false);
                }
            }
        }
        // Can insert/delete all AccountShare & OpportunityShare in current transaction
        else
        {
            if(insertFlag)
            {
                dmlOperationOnShareRecords(accShareToInsert, true);
                dmlOperationOnShareRecords(oppShareToInsert, true);
            }
            else
            {
                dmlOperationOnShareRecords(accShareToInsert, false);
                dmlOperationOnShareRecords(oppShareToInsert, false);
            }
            Integer calculateLimitAfterAccAndQuoteShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accShareToInsert.size() - oppShareToInsert.size();
            //if we have remains from QuoteShare chk possibility to insert/delete  some of them
            if(calculateLimitAfterAccAndQuoteShareDML > 0)
            {
                SharingUtils.chkRemainsOfQtShares(calculateLimitAfterAccAndQuoteShareDML,qtSharepassedToQueueble, insertFlag);
            }
        }
    }

    /***************************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: checks if AccountShare list exceeding DML 10000 limit and then splits the list, and inserts/deletes(depending on the flag parameter) the rest of the records
    * runs on AccountShares that are remains of past transaction received from other queueable, returns true if we need to split the records again
    * made for QueueableOppRecalculateSharing, QueueableAvoidDMLLimit
    * Inputs : List<AccountShare>
    * Test Class :
    * History :
    *****************************************************************************************************************************************************************************/
    public static Boolean checkForDMLlimitAndInsertOrDeleteSharingRemains(List<AccountShare> accSharepassedToQueueble, Boolean insertFlag)
    {
        // if we only have remains of AccountShare from other queueable and we can insert/delete only part of them in this transaction
        if(accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
        {
            SharingUtils.insertOrDeleteAccSharesAndInitRemains(accSharepassedToQueueble, insertFlag);
            return true ;
        }
        // if we only have remains of AccountShare from other queueable and we can insert/delete all of them in this transaction
        else if(accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
        {
            if(insertFlag)
            {
                dmlOperationOnShareRecords(accSharepassedToQueueble, true);
            }
            else
            {
                dmlOperationOnShareRecords(accSharepassedToQueueble, false);
            }
            return false ;
        }
        return false;
    }

    /******************************************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: checks if AccountShare/OpportunityShare list exceeding DML 10000 limit and then splits the list, and inserts/deletes(depending on the flag parameter) the rest of the records
   * made for QueueableAvoidDMLLimit, QueueableQuoteRecalculateSharing
   * Inputs : List<AccountShare>, List<OpportunityShare>
   * Test Class :
   * History :
   *********************************************************************************************************************************************************************************************/
    public static Boolean checkForDMLlimitAndInsertOrDeleteSharingRemains(List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppSharepassedToQueueble, Boolean insertFlag)
    {
        /* if we only have remains of AccountShare/OpportunityShare from other queueable
        and the sum of the sizes is greater the DML limit for transaction*/
        if((accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                || (oppSharepassedToQueueble.size() > 0 && oppSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                && (oppSharepassedToQueueble.size() + accSharepassedToQueueble.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) )
        {
            // if we have remains of AccountShare from other queueable and we can insert/delete part of AccountShare this transaction
            if(accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteAccSharesAndInitRemains(accSharepassedToQueueble, insertFlag);
            }
            // if we have remains of OpportunityShare from other queueable and we can insert/delete only part of OpportunityShare in this transaction
            else if(oppSharepassedToQueueble.size() > 0 && oppSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteOppSharesAndInitRemains(oppSharepassedToQueueble, insertFlag);
            }
            // if we have remains of AccountShare/OpportunityShare from other queueable and we can insert/delete some part of both this transaction
            else
            {
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, false);
                }
                Integer calculateLimitAfterAccShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accSharepassedToQueueble.size();
                if(calculateLimitAfterAccShareDML > 0)
                {
                    SharingUtils.insertOrDeleteOppSharesAndInitRemains(oppSharepassedToQueueble, insertFlag);
                }
            }
            return true;
        }
        /* if we only have remains of AccountShare or OpportunityShare
        from other queueable and we can insert/delete them all in current transaction*/
        else
        {
            if(insertFlag)
            {
                if(accSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, true);
                }
                if(oppSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, true);
                }
            }
            else
            {
                if(accSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, false);
                }
                if(oppSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, false);
                }
            }
            return false;
        }
    }

    /**************************************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: checks if AccountShare/QuoteShare list exceeding DML 10000 limit and then splits the list, and inserts/deletes(depending on the flag parameter) the rest of the records
   * made for QueueableAvoidDMLLimit
   * Inputs : List<AccountShare>, List<SBQQ__Quote__Share>
   * Test Class :
   * History :
   ****************************************************************************************************************************************************************************************/
    public static Boolean checkForDMLlimitAndInsertOrDeleteSharingRemains(List<AccountShare> accSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble, Boolean insertFlag)
    {
        /* if we only have remains of AccountShare/QuoteShare from other queueable
        and the sum of the sizes is greater the DML limit for transaction*/
        if((accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                || (qtSharepassedToQueueble.size() > 0 && qtSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                && (qtSharepassedToQueueble.size() + accSharepassedToQueueble.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) )
        {
            // if we have remains of AccountShare from other queueable and we can insert/delete part of AccountShare this transaction
            if(accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteAccSharesAndInitRemains(accSharepassedToQueueble, insertFlag);
            }
            // if we have remains of QuoteShare from other queueable and we can insert/delete only part of QuoteShare in this transaction
            else if(qtSharepassedToQueueble.size() > 0 && qtSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteQtSharesAndInitRemains(qtSharepassedToQueueble, insertFlag);
            }
            // if we have remains of AccountShare/QuoteShare from other queueable and we can insert/delete some part of both this transaction
            else
            {
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, true);
                }
                else
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, false);
                }
                Integer calculateLimitAfterAccShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accSharepassedToQueueble.size();
                if(calculateLimitAfterAccShareDML > 0)
                {
                    SharingUtils.insertOrDeleteQtSharesAndInitRemains(qtSharepassedToQueueble, insertFlag);
                }
            }
            return true;
        }
        /* if we only have remains of AccountShare or QuoteShare
        from other queueable and we can insert/delete them all in current transaction*/
        else
        {
            if(insertFlag)
            {
                if(accSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, true);
                }
                if(qtSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(qtSharepassedToQueueble, true);
                }
            }
            else
            {
                if(accSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, false);
                }
                if(qtSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(qtSharepassedToQueueble, false);
                }
            }
            return false;
        }
    }

    /****************************************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: checks if OpportunityShare/QuoteShare list exceeding DML 10000 limit and then splits the list, and inserts/deletes(depending on the flag parameter) the rest of the records
   * made for QueueableAvoidDMLLimit
   * Inputs : List<OpportunityShare>, List<SBQQ__Quote__Share>
   * Test Class :
   * History :
   *******************************************************************************************************************************************************************************************/
    public static Boolean checkForDMLlimitAndInsertOrDeleteSharingRemains(List<OpportunityShare> oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble, Boolean insertFlag)
    {
        /* if we only have remains of OpportunityShare/QuoteShare from other queueable
        and the sum of the sizes is greater the DML limit for transaction*/
        if((oppSharepassedToQueueble.size() > 0 && oppSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                || (qtSharepassedToQueueble.size() > 0 && qtSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                && (qtSharepassedToQueueble.size() + oppSharepassedToQueueble.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) )
        {
            // if we have remains of Opportunity from other queueable and we can insert/delete part of AccountShare this transaction
            if(oppSharepassedToQueueble.size() > 0 && oppSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteOppSharesAndInitRemains(oppSharepassedToQueueble,insertFlag);
            }
            // if we have remains of QuoteShare from other queueable and we can insert/delete only part of QuoteShare in this transaction
            else if(qtSharepassedToQueueble.size() > 0 && qtSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteQtSharesAndInitRemains(qtSharepassedToQueueble,insertFlag);
            }
            // if we have remains of OpportunityShare/QuoteShare from other queueable and we can insert/delete some part of both this transaction
            else
            {
                if(insertFlag)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, true);
                }
                else
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, false);
                }
                Integer calculateLimitAfterOppShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - oppSharepassedToQueueble.size();
                if(calculateLimitAfterOppShareDML > 0)
                {
                    SharingUtils.insertOrDeleteQtSharesAndInitRemains(qtSharepassedToQueueble,insertFlag);
                }
            }
            return true;
        }
        /* if we only have remains of OpportunityShare or QuoteShare
        from other queueable and we can insert/delete them all in current transaction*/
        else
        {
            if(insertFlag)
            {
                if(oppSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, true);
                }
                if(qtSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(qtSharepassedToQueueble, true);
                }
            }
            else
            {
                if(oppSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, false);
                }
                if(qtSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(qtSharepassedToQueueble, false);
                }
            }
            return false;
        }
    }

    /******************************************************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: checks if AccountShare/OpportunityShare/QuoteShare list exceeding DML 10000 limit and then splits the list, and inserts/deletes(depending on the flag parameter) the rest of the records
    * runs on AccountShares that are remains of past transaction received from other queueable
    * made for QueueableOppPrincipalRecalculateSharing
    * Inputs : List<AccountShare>, List<OpportunityShare>, List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    *********************************************************************************************************************************************************************************************************/
    public static Boolean checkForDMLlimitAndInsertOrDeleteSharingRemains(List<AccountShare> accSharepassedToQueueble, List<OpportunityShare> oppSharepassedToQueueble,
            List<SBQQ__Quote__Share> qtSharepassedToQueueble, Boolean insertFlag)
    {
        /* if we only have remains of AccountShare/OpportunityShare/QuoteShare from other queueable
        and the sum of the sizes is greater the DML limit for transaction*/
        if((accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                || (oppSharepassedToQueueble.size() > 0 && oppSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed())
                || (qtSharepassedToQueueble.size() > 0 && qtSharepassedToQueueble.size() < SharingUtils.numOfDMLThatCanBeProcessed() )
                && (oppSharepassedToQueueble.size() + accSharepassedToQueueble.size() + qtSharepassedToQueueble.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) )
        {
            // if we have remains of AccountShare from other queueable and we can insert/delete part of AccountShare this transaction
            if(accSharepassedToQueueble.size() > 0 && accSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteAccSharesAndInitRemains(accSharepassedToQueueble, insertFlag);
            }
            // if we have remains of OpportunityShare from other queueable and we can insert/delete only part of OpportunityShare in this transaction
            else if(oppSharepassedToQueueble.size() > 0 && oppSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteOppSharesAndInitRemains(oppSharepassedToQueueble,insertFlag);
            }
            // if we have remains of QuoteShare from other queueable and we can insert/delete only part of OpportunityShare in this transaction
            else if(qtSharepassedToQueueble.size() > 0 && qtSharepassedToQueueble.size() > SharingUtils.numOfDMLThatCanBeProcessed())
            {
                SharingUtils.insertOrDeleteQtSharesAndInitRemains(qtSharepassedToQueueble,insertFlag);
            }
            // if we have remains of AccountShare/OpportunityShare/QuoteShare from other queueable and we can insert/delete some part of both this transaction
            else
            {
                dmlOperationOnShareRecords(accSharepassedToQueueble, insertFlag);
                Integer calculateLimitAfterAccShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - accSharepassedToQueueble.size();
                if(calculateLimitAfterAccShareDML > 0)
                {
                    Integer oppShareSize = oppSharepassedToQueueble.size();
                    SharingUtils.insertOrDeleteOppSharesAndInitRemains(oppSharepassedToQueueble,insertFlag);
                    Integer calculateLimitAfterOppShareDML = SharingUtils.numOfDMLThatCanBeProcessed() - oppShareSize;
                    if(calculateLimitAfterOppShareDML > 0)
                    {
                        SharingUtils.insertOrDeleteQtSharesAndInitRemains(qtSharepassedToQueueble,insertFlag);
                    }
                }
            }
            return true;
        }
        /* if we only have remains of AccountShare or OpportunityShare
        from other queueable and we can insert/delete them all in current transaction*/
        else
        {
            if(insertFlag)
            {
                if(accSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, true);
                }
                if(oppSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, true);
                }
                if(qtSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(qtSharepassedToQueueble, true);
                }
            }
            else
            {
                if(accSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(accSharepassedToQueueble, false);
                }
                if(oppSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(oppSharepassedToQueueble, false);
                }
                if(qtSharepassedToQueueble.size() > 0)
                {
                    dmlOperationOnShareRecords(qtSharepassedToQueueble, false);
                }
            }
            return false;
        }
    }

    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: checks if there are OpportunityShare remains, insert/delete (depending on the flag) some of them, and stores the rest in a list
   * used in SharingUtils.checkForDMLlimitAndInsertSharing() for QueueableOppRecalculateSharing
   * Inputs : Integer, List<OpportunityShare>, Boolean
   * Test Class :
   * History :
   ********************************************************************************************************************************************************************/
    public static void chkRemainsOfOppShares(Integer calculateLimitAfterAccAndQuoteShareDML, List<OpportunityShare> oppSharepassedToQueueble, Boolean insertFlag)
    {
        List<OpportunityShare> tempOppSharepassedToQueueble = new List<OpportunityShare>();
        tempOppSharepassedToQueueble.addAll(SharingUtils.limitListSize(oppSharepassedToQueueble, tempOppSharepassedToQueueble, calculateLimitAfterAccAndQuoteShareDML) );
        if(insertFlag)
        {
            dmlOperationOnShareRecords(oppSharepassedToQueueble, true);
        }
        else
        {
            dmlOperationOnShareRecords(oppSharepassedToQueueble, false);
        }
        oppSharepassedToQueueble.clear();
        oppSharepassedToQueueble.addAll(tempOppSharepassedToQueueble);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: checks if there are QuoteShare remains, insert some of them, and stores the rest in a list
    * used in SharingUtils.checkForDMLlimitAndInsertSharing() for QueueableOppPrincipalRecalculateSharing
    * Inputs : Integer, List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void chkRemainsOfQtShares(Integer calculateLimitAfterAccAndQuoteShareDML, List<SBQQ__Quote__Share> quoteSharepassedToQueueble, Boolean insertFlag)
    {
        List<SBQQ__Quote__Share> tempQtSharepassedToQueueble = new List<SBQQ__Quote__Share>();
        tempQtSharepassedToQueueble.addAll(SharingUtils.limitListSize(quoteSharepassedToQueueble, tempQtSharepassedToQueueble, calculateLimitAfterAccAndQuoteShareDML) );
        if(insertFlag)
        {
            dmlOperationOnShareRecords(quoteSharepassedToQueueble, true);
        }
        else
        {
            dmlOperationOnShareRecords(quoteSharepassedToQueueble, false);
        }
        quoteSharepassedToQueueble.clear();
        quoteSharepassedToQueueble.addAll(tempQtSharepassedToQueueble);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Performs DML (insert/delete depending on flag parameter) for DML.limit size of records for AccountShare remains, and stores the rest in a list
    * used in SharingUtils.checkForDMLlimitAndInsertSharing(),QueueableAvoidDMLLimit
    * Inputs : Integer, List<AccountShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void insertOrDeleteAccSharesAndInitRemains(List<AccountShare> accSharepassedToQueueble, Boolean insertFlag)
    {
        List<AccountShare> tempAccSharepassedToQueueble = new List<AccountShare>();
        tempAccSharepassedToQueueble.addAll(SharingUtils.limitListSize(accSharepassedToQueueble, tempAccSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
        if(insertFlag)
        {
            dmlOperationOnShareRecords(accSharepassedToQueueble, true);
        }
        else
        {
            dmlOperationOnShareRecords(accSharepassedToQueueble, false);
        }
        accSharepassedToQueueble.clear();
        accSharepassedToQueueble.addAll(tempAccSharepassedToQueueble);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Performs DML(insert/delete depending on flag parameter) for DML.limit size of records for OpportunityShare remains, and stores the rest in a list
    * used in SharingUtils.checkForDMLlimitAndInsertSharing(),QueueableAvoidDMLLimit
    * Inputs : Integer, List<OpportunityShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void insertOrDeleteOppSharesAndInitRemains(List<OpportunityShare> oppSharepassedToQueueble, Boolean insertFlag)
    {
        List<OpportunityShare> tempOppSharepassedToQueueble = new List<OpportunityShare>();
        tempOppSharepassedToQueueble.addAll(SharingUtils.limitListSize(oppSharepassedToQueueble, tempOppSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
        if(insertFlag)
        {
            dmlOperationOnShareRecords(oppSharepassedToQueueble, true);
        }
        else
        {
            dmlOperationOnShareRecords(oppSharepassedToQueueble, false);
        }
        oppSharepassedToQueueble.clear();
        oppSharepassedToQueueble.addAll(tempOppSharepassedToQueueble);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Performs DML(insert/delete depending on flag parameter) for DML.limit size of records for QuoteShare remains, and stores the rest in a list
    * used in SharingUtils.checkForDMLlimitAndInsertSharing(),QueueableAvoidDMLLimit
    * Inputs : Integer, List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void insertOrDeleteQtSharesAndInitRemains(List<SBQQ__Quote__Share> qtSharepassedToQueueble, Boolean insertFlag)
    {
        List<SBQQ__Quote__Share> tempQtSharepassedToQueueble = new List<SBQQ__Quote__Share>();
        tempQtSharepassedToQueueble.addAll(SharingUtils.limitListSize(qtSharepassedToQueueble, tempQtSharepassedToQueueble, SharingUtils.numOfDMLThatCanBeProcessed()) );
        if(insertFlag)
        {
            dmlOperationOnShareRecords(qtSharepassedToQueueble, true);
        }
        else
        {
            dmlOperationOnShareRecords(qtSharepassedToQueueble, false);
        }
        qtSharepassedToQueueble.clear();
        qtSharepassedToQueueble.addAll(tempQtSharepassedToQueueble);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Instantiates and runs QueueableAvoidDMLLimit job
    * used in QueueableAvoidDMLLimit
    * Inputs : Integer, List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    ************************************************************************************************************************************************************************************************/
    public static void createAndRunAvoidDMLJob(List<AccountShare>accSharepassedToQueueble, List<OpportunityShare>oppSharepassedToQueueble, List<SBQQ__Quote__Share> qtSharepassedToQueueble, Boolean insertFlag)
    {
        QueueableAvoidDMLLimit insertSharingRemainedRecordsJob = new QueueableAvoidDMLLimit(accSharepassedToQueueble, oppSharepassedToQueueble, qtSharepassedToQueueble, insertFlag);
        System.enqueueJob(insertSharingRemainedRecordsJob);
    }

    /*************************************************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: combining quoteShare remains from last queueable with sharing records of this class,to parse easily
    * used in all Queueable sharing classes
    * Inputs : Integer, List<AccountShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void combineRemainAndSharingList(List<AccountShare> accShareLst, List<AccountShare> accSharepassedToQueueable)
    {
        if(accSharepassedToQueueable.size() > 0 )
        {
            accShareLst.addAll(accSharepassedToQueueable);
            accSharepassedToQueueable.clear();
        }
        SharingUtils.removeListDups(accShareLst);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: combining opportunityShare remains from last queueable with sharing records of this class,to parse easily
    * used in all Queueable sharing classes
    * Inputs : Integer, List<OpportunityShare>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void combineRemainAndSharingList(List<OpportunityShare> oppShareLst, List<OpportunityShare> oppSharepassedToQueueble)
    {
        if(oppSharepassedToQueueble.size() > 0 )
        {
            oppShareLst.addAll(oppSharepassedToQueueble);
            oppSharepassedToQueueble.clear();
        }
        SharingUtils.removeListDups(oppShareLst);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: combining quoteShare remains from last queueable with sharing records of this class,to parse easily
    * used in all Queueable sharing classes
    * Inputs : Integer, List<SBQQ__Quote__Share>
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void combineRemainAndSharingList(List<SBQQ__Quote__Share> quoteShareLst, List<SBQQ__Quote__Share> qtSharepassedToQueueble)
    {
        if(qtSharepassedToQueueble.size() > 0 )
        {
            quoteShareLst.addAll(qtSharepassedToQueueble);
            qtSharepassedToQueueble.clear();
        }
        SharingUtils.removeListDups(quoteShareLst);
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: calculates and returns the number of DML rows that can be processed in current transaction
    * used in all Queueable sharing classes
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static Integer numOfDMLThatCanBeProcessed()
    {
        return Limits.getLimitDMLRows() - Limits.getDMLRows();
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Inserts/Deletes a list of AccountShare records
    * used in SharingUtils
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void dmlOperationOnShareRecords(List<AccountShare> accShareLst, Boolean option)
    {
        if(option)
        {
            Database.SaveResult[] resultArr = Database.insert(accShareLst,false);
            loopThroughDBSaveResult(resultArr);
        }
        else
        {
            Database.DeleteResult[] resultArr = Database.delete(accShareLst,false);
            loopThroughDBSaveResult(resultArr);
        }
    }

    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: Inserts/Deletes a list of OpportunityShare records
   * used in SharingUtils
   * Inputs :
   * Test Class :
   * History :
   ********************************************************************************************************************************************************************/
    public static void dmlOperationOnShareRecords(List<OpportunityShare>oppShareLst, Boolean option)
    {
        if(option)
        {
            Database.SaveResult[] resultArr = Database.insert(oppShareLst,false);
            loopThroughDBSaveResult(resultArr);
        }
        else
        {
            Database.DeleteResult[] resultArr = Database.delete(oppShareLst,false);
            loopThroughDBSaveResult(resultArr);
        }
    }

    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: Inserts/Deletes a list of QuoteShare records
   * used in SharingUtils
   * Inputs :
   * Test Class :
   * History :
   ********************************************************************************************************************************************************************/
    public static void dmlOperationOnShareRecords(List<SBQQ__Quote__Share> qthareLst, Boolean option)
    {
        if(option)
        {
            Database.SaveResult[] resultArr = Database.insert(qthareLst,false);
            loopThroughDBSaveResult(resultArr);
        }
        else
        {
            Database.DeleteResult[] resultArr = Database.delete(qthareLst,false);
            loopThroughDBSaveResult(resultArr);
        }
    }
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Loops over an array of Database.SaveResult and logs the error
    * used in SharingUtils
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void loopThroughDBSaveResult(Database.SaveResult [] resultArr)
    {
        String s = '';
        Set<Id> successAccShareIds = new Set<Id>();
        for(Database.SaveResult sr : resultArr)
        {
            if(!sr.isSuccess())
            {
                Database.Error ferr = sr.getErrors()[0];
                if ((ferr.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY && ferr.getMessage().contains('insufficient access rights on cross-reference id')))
                {
                    continue;
                }
                else
                {
                	for(Database.Error err : sr.getErrors())
                    {
                        s += err.getStatusCode();
                        s += '\n';
                        s += err.getMessage();
                        s += '\n';
                        s += err.getFields();
                	}   
                }
            }
        }
        if(String.isNotBlank(s))
        {
            DebugLog.addError( 'failed to insert AccountShare record: ' + '\n' + s );
        }
    }
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Loops over an array of Database.DeleteResult and logs error
    * used in SharingUtils
    * Inputs :
    * Test Class :
    * History :
    ********************************************************************************************************************************************************************/
    public static void loopThroughDBSaveResult(Database.DeleteResult [] resultArr)
    {
        String s = '';
        Set<Id> successAccShareIds = new Set<Id>();
        for (Database.DeleteResult sr : resultArr)
        {
            if (!sr.isSuccess())
            {
                Database.Error ferr = sr.getErrors()[0];
                if ((ferr.getStatusCode() == StatusCode.INVALID_CROSS_REFERENCE_KEY && ferr.getMessage().contains('id does not exist')))
                {
                    continue;
                }
                else
                {
                	for(Database.Error err : sr.getErrors())
                    {
                        s += err.getStatusCode();
                        s += '\n';
                        s += err.getMessage();
                        s += '\n';
                        s += err.getFields();
                	}   
                }
            }
        }
        if(String.isNotBlank(s))
        {
            DebugLog.addError( 'failed to delete AccountShare record: ' + '\n' + s );
        }
    }
}