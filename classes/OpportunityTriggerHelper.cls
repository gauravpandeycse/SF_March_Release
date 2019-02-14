/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: event handler Class for Opportunity Trigger
 * Inputs :
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public without sharing class OpportunityTriggerHelper
{
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: shares Opportunity + Sold To Account + C2 Account to users based on sharingAccess table on Opportunity record insert
    * Inputs : List<Opportunity>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/


    public static void OppAndAccSharingBasedLOB(List<Opportunity> newOpportunitiesList)
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
                    Set<Id> oppAccounts = new Set<Id>();
                    for (Opportunity op : newOpportunitiesList)
                    {
                        oppAccounts.add(op.AccountId);
                    }
                    Map<Id, Account> soldToIdsToC2Accounts = new Map<Id, Account>();
                    List<AccountShare> accShareToInsert = new List<AccountShare>() ;
                    List<OpportunityShare> oppShareToInsert = new List<OpportunityShare>() ;
                    Set<Id> regionalIds = new Set<Id>();

                    if(!oppAccounts.isEmpty())
                    {
                        for(Account soldTo : SharingUtils.getParentAccounts(oppAccounts))
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
                        for(Opportunity op : newOpportunitiesList)
                        {
                            if(op.LOB1__c!=null)
                            {
                                //sharing Account if LOB1 & IMCDCompany match
                                if(lob1toSharingAccessMap.get(op.LOB1__c) != null && soldToIdsToC2Accounts.get(op.AccountId)!=null && lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c) != null)
                                {
                                    //sharing the Opportunity
                                    oppShareToInsert.addAll(SharingUtils.opportunitySharing(op.Id,lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                                    //SharingUtils.debugSharingReason('Opportunity','LOB1 & IMCDCompany match','OpportunityTriggerHelper',lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c));
                                    //sharing the sold to Account and Regional Account
                                    if(soldToIdsToC2Accounts.get(op.AccountId).ParentId != null)
                                    {
                                        accShareToInsert.addAll(SharingUtils.accountSharing(op.AccountId, soldToIdsToC2Accounts.get(op.AccountId).ParentId, lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                       // SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','OpportunityTriggerHelper',lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c));
                                    }
                                    else
                                    {
                                        accShareToInsert.addAll(SharingUtils.accountSharing(op.AccountId, null, lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                        //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','OpportunityTriggerHelper',lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c));

                                    }
                                }
                            }
                        }
                        if(!accShareToInsert.isEmpty() && !oppShareToInsert.isEmpty())
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareToInsert, true);
                            SharingUtils.dmlOperationOnShareRecords(oppShareToInsert, true);
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'OpportunityTriggerHelper');
        }

    }
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: shares Opportunity + Sold To Account + C2 Account to users based on sharingAccess table on Opportunity record update
    * Inputs : Map<Id, Opportunity>, List<Opportunity>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void updateOppAndAccSharingBasedLOB(Map<Id, Opportunity> oldOpportunitiesMap, List<Opportunity> newOpportunitiesList)
    {
        try
        {
            List<Opportunity> lobChangedOppsList = new List<Opportunity>();
            for(Opportunity opp : newOpportunitiesList)
            {
                if(opp.LOB1__c!=null && !opp.LOB1__c.equals(oldOpportunitiesMap.get(opp.Id).LOB1__c) )
                {
                    lobChangedOppsList.add(opp);
                }
            }
            if(!lobChangedOppsList.isEmpty())
            {
                // get the sharingAccess table
                List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(null);
                if(!sharingTableList.isEmpty())
                {
                    Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                    Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();

                    //mapping all Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                    SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toSharingAccessMap, globalSharingAccessesMap);
                    if (!lob1toSharingAccessMap.isEmpty())
                    {
                        Set<Id> oppAccounts = new Set<Id>();
                        for (Opportunity op : lobChangedOppsList)
                        {
                            oppAccounts.add(op.AccountId);
                        }

                        Map<Id, Account> soldToIdsToC2Accounts = new Map<Id, Account>();
                        List<AccountShare> accShareToInsert = new List<AccountShare>() ;
                        List<OpportunityShare> oppShareToInsert = new List<OpportunityShare>() ;
                        Set<Id> regionalIds = new Set<Id>();

                        if(!oppAccounts.isEmpty())
                        {
                            for(Account soldTo : SharingUtils.getParentAccounts(oppAccounts))
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
                            for(Opportunity op : lobChangedOppsList)
                            {
                                if(op.LOB1__c!=null)
                                {
                                    //sharing Account if LOB1 & IMCDCompany match
                                    if(lob1toSharingAccessMap.get(op.LOB1__c) != null && soldToIdsToC2Accounts.get(op.AccountId)!=null && lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c) != null)
                                    {
                                        //sharing the Opportunity
                                        oppShareToInsert.addAll(SharingUtils.opportunitySharing(op.Id,lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.MANUAL_RAW_CAUSE));
                                        //SharingUtils.debugSharingReason('Opportunity','LOB1 & IMCDCompany match','OpportunityTriggerHelper(update)',lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c));
                                        //sharing the sold to Account and Regional Account
                                        if(soldToIdsToC2Accounts.get(op.AccountId).ParentId != null)
                                        {
                                            accShareToInsert.addAll(SharingUtils.accountSharing(op.AccountId, soldToIdsToC2Accounts.get(op.AccountId).ParentId, lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                            //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','OpportunityTriggerHelper(update)',lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c));
                                        }
                                        else
                                        {
                                            accShareToInsert.addAll(SharingUtils.accountSharing(op.AccountId, null, lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap));
                                            //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','OpportunityTriggerHelper(update)',lob1toSharingAccessMap.get(op.LOB1__c).get(soldToIdsToC2Accounts.get(op.AccountId).IMCDCompany__c));
                                        }
                                    }
                                }

                            }
                            if(!accShareToInsert.isEmpty() && !oppShareToInsert.isEmpty())
                            {
                                SharingUtils.dmlOperationOnShareRecords(accShareToInsert, true);
                                SharingUtils.dmlOperationOnShareRecords(oppShareToInsert, true);
                            }
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'OpportunityTriggerHelper');
        }
    }
    /******************************************************************************************************************************************************************
    * Author: NC
    * Company: Salesforce
    * Description: This method checks if the account related to an opportunity has changed, if it has, then a method is called with all the 
    * changed opportunities which in turn sets the lookup to the Account on all related objects. Namely, Sample Requests(case), follow up reports and Quotes 
    * Inputs : Map<Id, Opportunity>old Opportunity, Map<Id,Opportunity> newOpportunityMap
    * Test Class : TestOpportunityTriggerHelper - test_isAccountNotChangedForRelatedObjectsWithContractedPrice,test_isAccountChangedForRelatedObjects
    * History :
    ******************************************************************************************************************************************************************/
    
    public static void checkAccountIsChangedOnOpportunity(Map<Id,Opportunity> oldOpportunityMap, Map<Id,Opportunity> newOpportunityMap){
        Map<Id, Opportunity> changedOpportunities = new Map<Id, Opportunity>();
        for(Opportunity eachOpportunity : newOpportunityMap.values()){
            if(oldOpportunityMap.get(eachOpportunity.Id).AccountId != eachOpportunity.AccountId){
                changedOpportunities.put(eachOpportunity.Id,eachOpportunity);
            }
        }
        if(changedOpportunities != null && !changedOpportunities.isEmpty()){
            changeAccountInRelatedObjects(changedOpportunities);
        }
    }
    /******************************************************************************************************************************************************************
    * Author: NC
    * Company: Salesforce
    * Description: called by checkAccountIsChangedOnOpportunity
    * Inputs : Map<Id, Opportunity>old Opportunity, Map<Id,Opportunity> newOpportunityMap
    * Test Class : TestOpportunityTriggerHelper - test_isAccountNotChangedForRelatedObjectsWithContractedPrice,test_isAccountChangedForRelatedObjects
    * History :
    ******************************************************************************************************************************************************************/
    private static void changeAccountInRelatedObjects(Map<Id, Opportunity> changedOpportunities){
        Map<Id, List<SBQQ__Quote__c>> opportunityQuotesMap = new Map<Id, List<SBQQ__Quote__c>>();// Map Key - OppId, Value - List of Quotes
        Map<Id, List<FollowUpReport__c>> opportunityfollowUpsMap = new Map<Id, List<FollowUpReport__c>>();// Map Key - OppId, Value - List of FollowUps
		Map<Id, List<Case>> opportunitySampleRequestMap = new Map<Id, List<Case>>();// Map Key - OppId, Value - List of SampleRequests
        Map<Id, List<SBQQ__ContractedPrice__c>> opportunityContractedPricesMap = new Map<Id, List<SBQQ__ContractedPrice__c>>();// Map Key - OppId, Value - List of ContractedPrices
        Map<Id, Integer> contractedPricesForOpportunity = new Map<Id, Integer>();
        List <SBQQ__Quote__c> quotesToUpdateList = new List<SBQQ__Quote__c>();
        List <FollowUpReport__c> followUpReportsToUpdateList = new List<FollowUpReport__c>();
        List <Case> sampleRequestToUpdateList = new List<Case>();
       
        retrieveQuoteLineRelatedRecords(changedOpportunities, opportunityfollowUpsMap, opportunitySampleRequestMap, opportunityContractedPricesMap) ;
        checkIfContractedPricesExist(changedOpportunities,opportunityContractedPricesMap);
        retrieveRelatedQuotes(changedOpportunities,opportunityQuotesMap);
        
        
        //Collect all of the related objects of the opportunity and change the account to the new account
        for(Id eachOpp : changedOpportunities.keySet()){
            if(opportunityfollowUpsMap.get(eachOpp) != null && !opportunityfollowUpsMap.get(eachOpp).isEmpty()){
                for(FollowUpReport__c followUpReport : opportunityfollowUpsMap.get(eachOpp)){
                	followUpReport.Account__c = changedOpportunities.get(eachOpp).AccountId;
                	followUpReportsToUpdateList.add(followUpReport);
            	}
        	}
            if(opportunityQuotesMap.get(eachOpp) != null && !opportunityQuotesMap.get(eachOpp).isEmpty()){
                for(SBQQ__Quote__c quote : opportunityQuotesMap.get(eachOpp)){
                    quote.SBQQ__Account__c = changedOpportunities.get(eachOpp).AccountId;
                    quote.ShiptoAddress__c = null; // Ship To Address could be related to old Account, so blanking this. 
                    							   // https://imcdgroup.atlassian.net/browse/SFDP-1000?focusedCommentId=14856&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-14856
                    quotesToUpdateList.add(quote);
                }
            }
            if(opportunitySampleRequestMap.get(eachOpp) != null && !opportunitySampleRequestMap.get(eachOpp).isEmpty()){
                for(Case sampleRequest : opportunitySampleRequestMap.get(eachOpp)){
                    sampleRequest.AccountId = changedOpportunities.get(eachOpp).AccountId;
                    sampleRequestToUpdateList.add(sampleRequest);
                }
            }
        }

        
        Database.SaveResult[] followUpUpdate = Database.update(followUpReportsToUpdateList, false);
        logError(followUpUpdate,'FollowUpReport__c', followUpReportsToUpdateList);
        Database.SaveResult[] quotesUpdate = Database.update(quotesToUpdateList, false);
        logError(quotesUpdate,'SBQQ__Quote__c', quotesToUpdateList);
        Database.SaveResult[] casesUpdate = Database.update(sampleRequestToUpdateList, false);
        logError(casesUpdate,'Case', sampleRequestToUpdateList);
    }
	/*
	 * populate all the followups, samplerequests and contracted prices that are related to the opportunity
	 * */
    private static void retrieveQuoteLineRelatedRecords(Map<ID, Opportunity> changedOpportunities,
                                                        Map<Id, List<FollowUpReport__c>> opportunityfollowUpsMap,
                                                        Map<Id, List<Case>> opportunitySampleRequestMap,
                                                        Map<Id, List<SBQQ__ContractedPrice__c>> opportunityContractedPricesMap
                                                        ){
        for(SBQQ__QuoteLine__c eachQuoteLine : [SELECT ID,
                                                SBQQ__Quote__r.SBQQ__Opportunity2__c , 
                                                (SELECT ID,Account__c FROM Follow_up_Reports__r ), 
                                                (SELECT ID,AccountId FROM Cases__r),
                                                (SELECT ID FROM SBQQ__ContractedPrices__r)
                                                FROM 
                                        		SBQQ__QuoteLine__c 
                                                WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c  in: changedOpportunities.keySet()]){
            if(opportunityContractedPricesMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ) == null && eachQuoteLine.SBQQ__ContractedPrices__r.size() > 0){
                opportunityContractedPricesMap.put(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c , new List<SBQQ__ContractedPrice__c>());
                opportunityContractedPricesMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ).addAll(eachQuoteLine.SBQQ__ContractedPrices__r);
            }else if(opportunityContractedPricesMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ) != null && eachQuoteLine.SBQQ__ContractedPrices__r.size() > 0){
                opportunityContractedPricesMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ).addAll(eachQuoteLine.SBQQ__ContractedPrices__r);
            }
        	if(opportunityfollowUpsMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ) == null && eachQuoteLine.Follow_up_Reports__r.size() > 0){
                opportunityfollowUpsMap.put(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c , new List<FollowUpReport__c>());
                opportunityfollowUpsMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ).addAll(eachQuoteLine.Follow_up_Reports__r);
            }else if(opportunityfollowUpsMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ) != null && eachQuoteLine.Follow_up_Reports__r.size() > 0){
                opportunityfollowUpsMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ).addAll(eachQuoteLine.Follow_up_Reports__r);
            }
            if(opportunitySampleRequestMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ) == null && eachQuoteLine.Cases__r.size() > 0){
                opportunitySampleRequestMap.put(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c , new List<Case>());
                opportunitySampleRequestMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ).addAll(eachQuoteLine.Cases__r);
            }else if(opportunitySampleRequestMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ) != null && eachQuoteLine.Cases__r.size() > 0){
                opportunitySampleRequestMap.get(eachQuoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c ).addAll(eachQuoteLine.Cases__r);
            }
        }
    }
    /**
     * check if there are any related contracted prices, if they exits then the update should not continue
     * */
    private static void checkIfContractedPricesExist(Map<ID, Opportunity> changedOpportunities,Map<Id, List<SBQQ__ContractedPrice__c>> opportunityContractedPricesMap){
        for(Id oppId : opportunityContractedPricesMap.keySet()){
            changedOpportunities.get(oppId).AccountId.addError(Label.Cannot_Change_Account);
            changedOpportunities.remove(oppId);
        }
    }
    /*
	 * populate all the quotes that are related to the opportunity
	 * */
    private static void retrieveRelatedQuotes(Map<ID, Opportunity> changedOpportunities, Map<Id, List<SBQQ__Quote__c>> opportunityQuotesMap){
        for(Opportunity eachOpportunity : [SELECT ID, 
                           					(SELECT ID,SBQQ__Account__c,ShiptoAddress__c FROM SBQQ__Quotes2__r) 
                           				FROM Opportunity WHERE ID in: changedOpportunities.keySet()]){
            if(opportunityQuotesMap.get(eachOpportunity.Id) == null && eachOpportunity.SBQQ__Quotes2__r.size() > 0){
                opportunityQuotesMap.put(eachOpportunity.Id, new List<SBQQ__Quote__c>());
                opportunityQuotesMap.get(eachOpportunity.Id).addAll(eachOpportunity.SBQQ__Quotes2__r);
            }
        }
    }
    private static void logError(Database.SaveResult[] srList, String objectName, List<SObject> updatedList) {
        for(Integer i=0;i<srList.size();i++){
    		if (!srList.get(i).isSuccess()){
                // DML operation failed
                Database.Error error = srList.get(i).getErrors().get(0);
                DebugLog.addError('[OpportunityTriggerHelper][changeAccountInRelatedObjects]['+objectName+'] An error has occurred.\n'
                                      + error.getStatusCode() + ': ' + error.getMessage() + '\n'
                                      + 'Fields affected: ' +  error.getFields() + '\n' 
                        			  + 'Record Id: ' + updatedList.get(i));
     		}

		}
        /*for(Database.SaveResult sr : srList){
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()) {
                    DebugLog.addError('[OpportunityTriggerHelper][changeAccountInRelatedObjects]['+objectName+'] An error has occurred.\n'
                                      + err.getStatusCode() + ': ' + err.getMessage() + '\n'
                                      + 'Fields affected: ' +  err.getFields() + '\n' 
                        			  + 'Record Id: ' + sr.getId());
                }
            }
        }*/
	}
    
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: Validates Opportunity stage transitions, if not allowable raises an user error
    * Inputs : Maps <Opportunity> (old, new)
    * Test Class : 
    * History :
    * 	30/07/2018 - Created for SFDP-715
    *   28/11/2018 - SFDP-1720  Enable step backwards if nu CustomerQuote WvB 
    ******************************************************************************************************************************************************************/
    public static void validateStageTransition (Map<Id,Opportunity> oldOpportunityMap, Map<Id,Opportunity> newOpportunityMap) {
        
        // if the SalesAdminBypass custom permission is granted, bypass all checks. 
        system.debug('SalesAdminBypass? ' + FeatureManagement.checkPermission('SalesAdminBypass'));
        if (FeatureManagement.checkPermission('SalesAdminBypass')) return;
        String x;
        Map<id,id> hasCustomerQuote ;

        
        for ( Opportunity oldOppty : oldOpportunityMap.values() ) {
            
            Opportunity newOppty = newOpportunityMap.get(oldOppty.Id);
            String currStage = oldOppty.StageName;
            String newStage = newOppty.StageName;      

            // continue loop if nothing changed
            if (currStage.equals(newStage)) continue;

            if (hasCustomerQuote == null){  // New Nov18 WvB
                hasCustomerQuote = new Map<id,id>();
                for (SBQQ__Quote__c quote :[SELECT id, Name, SBQQ__Opportunity2__c 
                                                FROM SBQQ__Quote__c
                                                WHERE SBQQ__Opportunity2__c = : newOpportunityMap.keySet()
                                                AND   QuoteType__c = 'Customer' ]){
                    hasCustomerQuote.put(quote.SBQQ__Opportunity2__c , quote.id);
                }
            }
            // add error when changing from end stages (Won, Lost)
            if (Label.IMCD_OPPTY_END_STAGES.containsIgnoreCase(currStage)) {
                if (hasCustomerQuote.get(oldOppty.id) != null){   // New Nov18 WvB
                   newOppty.addError(Label.IMCD_OPPTY_INVALID_STAGE_MSG);
                   continue;
               }
            }
            
            // add error when changing from closing stage to other than won/lost
            if (currStage.equalsIgnoreCase(Label.IMCD_OPPTY_CLOSING_STAGE)
              && !Label.IMCD_OPPTY_END_STAGES.containsIgnoreCase(newStage)) {
                if (hasCustomerQuote.get(oldOppty.id) != null){ // New Nov18 WvB
                    newOppty.addError(Label.IMCD_OPPTY_INVALID_STAGE_MSG);
       				continue;
                }
            }
            
            // add error if opportunity contains Temp products when closing (Closing, Won)
            // addError cannot use unescaped/html formatting
            if (newStage.equalsIgnoreCase(Label.IMCD_OPPTY_CLOSING_STAGE) 
                || newStage.equalsIgnoreCase(Label.IMCD_OPPTY_WON_STAGE)) {
            
                String errorMsg = '';
            	
				for (SBQQ__QuoteLine__c quoteLine : checkTempProducts (oldOppty.Id)) {
					errorMsg += String.format(Label.IMCD_OPPTY_TEMP_PROD_MSG2, new String[]{quoteLine.SBQQ__Quote__r.Name, quoteLine.SBQQ__Product__r.Name}) + ', ';
				}  
                    
                if (String.isNotEmpty(errorMsg)) {
                    errorMsg = String.format(Label.IMCD_OPPTY_TEMP_PROD_MSG1, new String[]{newStage}) + ' ' + errorMsg.removeEnd(', ');
                    newOppty.addError(errorMsg);
				}
   			}
        }
    }
    
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: Queries for any CustomerQuote or OpportunityQuote containing an active (e.g. Line item status <> Lost) Temporary product
    * Inputs : Opportunity.Id
    * Test Class : 
    * History :
    * 	30/07/2018 - Created for SFDP-715
    *   02/08/2018 - Modified WHERE clause to use SBQQ__Quote__r.SBQQ__Opportunity2__c instead of Opportunity__c
    ******************************************************************************************************************************************************************/
    private static List<SBQQ__QuoteLine__c> checkTempProducts (ID opportunityId) {
        return ([SELECT SBQQ__Quote__r.Name, SBQQ__Product__r.Name FROM SBQQ__QuoteLine__c 
                 WHERE SBQQ__Product__r.TempProductFlag__c = true 
                 	   AND Stage__c <> :Label.IMCD_OPPTY_LOST_STAGE 
                       AND SBQQ__Quote__r.SBQQ__Opportunity2__c = :OpportunityId]);
    }
    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Description: Transfer Opportunity stage to Quoteline on change
    * Inputs : Maps <Opportunity> (old, new)
    * Test Class : 
    * History :
    *   new 12-11-2018
    *   New 28 Nov18. Also copy reason Lost
    ******************************************************************************************************************************************************************/
 
    public static void transferStageName (Map<Id,Opportunity> oldOppMap, Map<Id,Opportunity> newOppMap) {

        Map<Id, Opportunity> toDoMap = new Map<Id, Opportunity>();
        // If stage changes and type = 'Opportunity'
        for ( Opportunity newOpp : newOppMap.values() ) {
            if (newOpp.StageName != oldOppMap.get(newOpp.Id).StageName && newOpp.SBQQ__PrimaryQuote__c != null ){
                toDoMap.put(newOpp.SBQQ__PrimaryQuote__c, newOpp);
            }
        }
        system.debug('------ toDoMap '+ toDoMap);
        SBQQ__QuoteLine__c dummyQuoteLine = new SBQQ__QuoteLine__c();
        List<SBQQ__QuoteLine__c> updQuoteLine = new List<SBQQ__QuoteLine__c>();
        Map<String, String> reasonLostPicklistMap = IMCDUtils.getPickListValues(dummyQuoteLine , 'Reason_Lost__c');  // Check for synced terms
        system.debug('------ reasonLostPicklistMap '+ reasonLostPicklistMap);  
        // Get related QuoteLines != 'Lost'
        for (SBQQ__QuoteLine__c quoteLine :[SELECT Id, SBQQ__Quote__c, Stage__c, Reason_Lost__c 
                                            FROM SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Quote__c =: toDoMap.keySet()
                                            AND   SBQQ__Quote__r.QuoteType__c = 'Opportunity'
                                            AND   (Stage__c != 'Lost' OR Reason_Lost__c = null)]){ // New 28 Nov18
            if (quoteLine.Stage__c != toDoMap.get(quoteLine.SBQQ__Quote__c).StageName 
                                            ||
                quoteLine.Reason_Lost__c != toDoMap.get(quoteLine.SBQQ__Quote__c).Loss_Reason__c)   {
                quoteLine.Stage__c = toDoMap.get(quoteLine.SBQQ__Quote__c).StageName;
                if (reasonLostPicklistMap.get(toDoMap.get(quoteLine.SBQQ__Quote__c).Loss_Reason__c) != null){  // New 28 Nov18
                    quoteLine.Reason_Lost__c = toDoMap.get(quoteLine.SBQQ__Quote__c).Loss_Reason__c;
        //        } else {
        //           Debuglog.addError('Reason Lost from Opportunity not synced to QuoteLine: '+ toDoMap.get(quoteLine.SBQQ__Quote__c).Loss_Reason__c);
                }
                updQuoteLine.add(quoteLine);
            }

        }
        update updQuoteLine;
    }



}