/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: event handler Class for SBQQ__Quote__c Trigger
 * Inputs :
 * Test Class :  TestSbqqQuoteTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
public without sharing class SbqqQuoteTriggerHelper
{
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: shares Sold To Account + C2 Account to users based on sharingAccess table on SBQQ__Quote__c record insert
    * Inputs : List<SBQQ__Quote__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void QuoteAndAccSharingBasedLOB(List<SBQQ__Quote__c> newQuoteList)
    {
        try
        {
            // get the sharingAccess table
            List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(null);
            if(!sharingTableList.isEmpty())
            {
                Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();

                //mapping all Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toSharingAccessMap, globalSharingAccessesMap);
                if(!lob1toSharingAccessMap.isEmpty())
                {
                    Set<Id> quoteAccounts = new Set<Id>();
                    for (SBQQ__Quote__c qt : newQuoteList)
                    {
                        quoteAccounts.add(qt.SBQQ__Account__c);
                    }
                    Map<Id, Account> soldToIdsToC2Accounts = new Map<Id, Account>();
                    List<AccountShare> accShareToInsert = new List<AccountShare>() ;
                    List<SBQQ__Quote__Share> quoteShareToInsert = new List<SBQQ__Quote__Share>() ;
                    Set<Id> regionalIds = new Set<Id>();

                    if(!quoteAccounts.isEmpty())
                    {
                        for(Account soldTo : SharingUtils.getParentAccounts(quoteAccounts))
                        {
                            soldToIdsToC2Accounts.put(soldTo.Id, soldTo);
                            if(soldTo.ParentId!=null)
                            {
                                regionalIds.add(soldTo.ParentId);
                            }
                        }

                        Set<Id> accountsToOwnersSetIds = new Set<Id>();
                        accountsToOwnersSetIds.addAll(soldToIdsToC2Accounts.keySet());
                        accountsToOwnersSetIds.addAll(regionalIds);
                        // get Owners to Accounts Id's to avoid sharing the Account to the owner
                        Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(accountsToOwnersSetIds);
                        //creating the accountShare records, to share the accounts to users from the Sharing Access table
                        for(SBQQ__Quote__c qt : newQuoteList)
                        {
                            if(qt.LOB1__c != null)
                            {
                                //sharing Account and Quote if LOB1 & IMCDCompany match
                                if(lob1toSharingAccessMap.get(qt.LOB1__c) != null && soldToIdsToC2Accounts.get(qt.SBQQ__Account__c)!=null && lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c) != null)
                                {
                                    //sharing the Quote
                                    quoteShareToInsert.addAll(SharingUtils.quoteSharing(qt.Id, lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.ShAcTable__c));
                                    //SharingUtils.debugSharingReason('Quote','LOB1 & IMCDCompany match','SbqqQuoteTriggerHelper',lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c));
                                    //sharing the sold to Account and Regional Account
                                    if(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).ParentId!=null)
                                    {
                                        accShareToInsert.addAll(SharingUtils.accountSharing(qt.SBQQ__Account__c, soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).ParentId, lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','SbqqQuoteTriggerHelper',lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c));
                                    }
                                    else
                                    {
                                        accShareToInsert.addAll(SharingUtils.accountSharing(qt.SBQQ__Account__c, null, lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','SbqqQuoteTriggerHelper',lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c));
                                    }
                                }
                            }
                        }
                        if(!accShareToInsert.isEmpty() && !quoteShareToInsert.isEmpty())
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareToInsert, true);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareToInsert, true);
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'SbqqQuoteTriggerHelper');
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: shares Sold To Account + C2 Account to users based on sharingAccess table on SBQQ__Quote__c record update
    * Inputs : Map<Id, SBQQ__Quote__c>, List<SBQQ__Quote__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void updateQuoteAndAccSharingBasedLOB(Map<Id, SBQQ__Quote__c>oldQuoteMap, List<SBQQ__Quote__c>newQuoteList)
    {
        try
        {
            List<SBQQ__Quote__c> lobChangedquoteList = new List<SBQQ__Quote__c>();
            for(SBQQ__Quote__c qt : newQuoteList)
            {
                if(qt.LOB1__c!=null && !qt.LOB1__c.equals(oldQuoteMap.get(qt.Id).LOB1__c) )
                {
                    lobChangedquoteList.add(qt);
                }
            }
            if(!lobChangedquoteList.isEmpty())
            {
                // get the sharingAccess table
                List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(null);
                if(!sharingTableList.isEmpty())
                {
                    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();

                    //mapping all Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                    SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toSharingAccessMap, globalSharingAccessesMap);

                    if(!lob1toSharingAccessMap.isEmpty())
                    {
                        Set<Id> quoteAccounts = new Set<Id>();
                        for(SBQQ__Quote__c qt : lobChangedquoteList)
                        {
                            quoteAccounts.add(qt.SBQQ__Account__c);
                        }
                        Map<Id, Account> soldToIdsToC2Accounts = new Map<Id, Account>();
                        List<AccountShare> accShareToInsert = new List<AccountShare>() ;
                        List<SBQQ__Quote__Share> quoteShareToInsert = new List<SBQQ__Quote__Share>() ;
                        Set<Id> regionalIds = new Set<Id>();

                        if(!quoteAccounts.isEmpty())
                        {
                            for(Account soldTo : SharingUtils.getParentAccounts(quoteAccounts))
                            {
                                soldToIdsToC2Accounts.put(soldTo.Id, soldTo);
                                if(soldTo.ParentId!=null)
                                {
                                    regionalIds.add(soldTo.ParentId);
                                }
                            }

                            Set<Id> accountsToOwnersSetIds = new Set<Id>();
                            accountsToOwnersSetIds.addAll(soldToIdsToC2Accounts.keySet());
                            accountsToOwnersSetIds.addAll(regionalIds);
                            // get Owners to Accounts Id's to avoid sharing the Account to the owner
                            Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(accountsToOwnersSetIds);
                            //creating the accountShare records, to share the accounts to users from the Sharing Access table
                            for(SBQQ__Quote__c qt : newQuoteList)
                            {
                                if(qt.LOB1__c!=null)
                                {
                                    //sharing Account if LOB1 & IMCDCompany match
                                    if(lob1toSharingAccessMap.get(qt.LOB1__c) != null && soldToIdsToC2Accounts.get(qt.SBQQ__Account__c)!=null && lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c) != null)
                                    {
                                        //sharing the Quote
                                        quoteShareToInsert.addAll(SharingUtils.quoteSharing(qt.Id, lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Schema.SBQQ__Quote__Share.RowCause.Sharing_Access_Table__c));
                                        //SharingUtils.debugSharingReason('Quote','LOB1 & IMCDCompany match','SbqqQuoteTriggerHelper (update)',lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c));
                                        //sharing the sold to Account and Regional Account
                                        if(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).ParentId!=null)
                                        {
                                            accShareToInsert.addAll(SharingUtils.accountSharing(qt.SBQQ__Account__c, soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).ParentId, lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.READ_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                            //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','SbqqQuoteTriggerHelper',lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c));
                                        }
                                        else
                                        {
                                            accShareToInsert.addAll(SharingUtils.accountSharing(qt.SBQQ__Account__c, soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).ParentId, lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                            //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','SbqqQuoteTriggerHelper',lob1toSharingAccessMap.get(qt.LOB1__c).get(soldToIdsToC2Accounts.get(qt.SBQQ__Account__c).IMCDCompany__c));
                                        }
                                    }
                                }
                            }
                            if(!accShareToInsert.isEmpty() && !quoteShareToInsert.isEmpty())
                            {
                                SharingUtils.dmlOperationOnShareRecords(accShareToInsert, true);
                                SharingUtils.dmlOperationOnShareRecords(quoteShareToInsert, true);
                            }
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            DebugLog.addException(ex, 'SbqqQuoteTriggerHelper');
        }
    }
    /*************************************************************************************************************************************************************************
    /*
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Creates a look up relationship to ImcdCompany object based on the IMCD Company value set on the user profile.
    * Inputs : List<SBQQ__Quote__c>
    * Test Class : TestSbqqQuoteTrigerHelper.isIMCDLookupSetOnQouteForInsertandUpdate()
    * History :
    */
    public static void setIMCDCompanyLookup(List<SBQQ__Quote__c> newQuoteList){
        Map<String, Id> IMCDCompaniesMap = new Map<String, Id>();
        Set<String> IMCDCompanies = new Set<String>();
        for(SBQQ__Quote__c eachQuoteLine : newQuoteList){
            IMCDCompanies.add(eachQuoteLine.ImcdCompany__c);
        }
        for(IMCDCompany__c eachCompany : [SELECT ID, ImcdCompany__c FROM IMCDCompany__c WHERE ImcdCompany__c in: IMCDCompanies]){
            IMCDCompaniesMap.put(eachCompany.ImcdCompany__c, eachCompany.Id);
        }
        for(SBQQ__Quote__c eachQuoteRecord : newQuoteList){
            if(!(String.isBlank(eachQuoteRecord.IMCDCompany__c))){
                if(!(String.isBlank(IMCDCompaniesMap.get(eachQuoteRecord.ImcdCompany__c)))){
                    eachQuoteRecord.ImcdCompanyLookup__c = IMCDCompaniesMap.get(eachQuoteRecord.ImcdCompany__c);    
                }else{
                    DebugLog.addError('[SBQQQuoteTriggerHelper][setIMCDCompanyLookup] Unable to find corresponding IMCD Company record for Quote :' + eachQuoteRecord.Id);
                    eachQuoteRecord.ImcdCompanyLookup__c.addError('[SBQQQuoteTriggerHelper][setIMCDCompanyLookup] Unable to find corresponding IMCD Company record for IMCD Company :' + eachQuoteRecord.ImcdCompany__c);
                }
            }
        }
    }

    /*
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Sets the Label of the Picklists - Company and IncoTerms as their api and labels are different
    * Inputs : List<SBQQ__Quote__c>
    * Test Class : TestSbqqQuoteTrigerHelper.isLabelSetForInsert()
    * Test Class : TestSbqqQuoteTrigerHelper.isLabelSetForUpdate()
    * History :
    */
    public static void setLabel(List<SBQQ__Quote__c> newQuoteList)
    {
        SBQQ__Quote__c quoteRecord = new SBQQ__Quote__c();
        Map<String, String> incoTermsPicklistMap = IMCDUtils.getPickListValues(quoteRecord, 'Incoterms2__c');
        for(SBQQ__Quote__c eachQuoteRecord : newQuoteList){
            eachQuoteRecord.IncoTermsLabel__c = incoTermsPicklistMap.get(eachQuoteRecord.IncoTerms2__c);
        }
    }
    /*
    * Author: Wim van Beek
    * Company: Salesforce/ Nncourage
    * Description: Counts nr of Quotes per opportunity. 
    * Inputs : List<SBQQ__Quote__c>
    * History :
    * Obsolute Wim van Beek 14-8-18
    */
 //   public static void countNrOfQuotes(List<SBQQ__Quote__c> newQuoteList){
        /*  Obsolute Wim van Beek 14-8-18
        Map<id, Opportunity> oppMap = new Map<id, Opportunity>();
        for (SBQQ__Quote__c quote: newQuoteList){
            if (quote.SBQQ__Opportunity2__c != null){
               oppMap.put(quote.SBQQ__Opportunity2__c, new Opportunity(id = quote.SBQQ__Opportunity2__c, NrOfQuotes__c = 0)); 
            }
        }
        
        if (oppMap.size() == 0){return;}

        for (SBQQ__Quote__c quote: [SELECT id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c 
                                        WHERE SBQQ__Opportunity2__c = : oppMap.keyset() ]){
            Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c);
            if (opp != null){
                opp.NrOfQuotes__c ++;
            }
        }
        // Need to skip update if count identical WvB 20-6-2018 TODO
        upsert oppMap.values();
        */

  //  }


}