/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov, Leon Kempers
 * Company: Salesforce
 * Description: Event Handler AccountLob__c Trigger
 * Inputs :
 * Test Class : TestAccountLobTriggerHelper, TestAccountLobTrigger
 * History :
 * mcoimbra@salesforce.com 	25/4/2018 	Changed Unique Id format 
 ******************************************************************************************************************************************************************/
public without sharing class AccountLobTriggerHelper
{
    public static boolean isExecuting = FALSE;
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: shares Sold To Account + C2 Account to users based on sharingAccess table on AccountLob__c record insert
    * Inputs : List<AccountLob__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void accountShareBasedLOB(List<AccountLob__c> newAccountLobList)
    {
        try
        {
            // get the sharingAccess table
            List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(null);

            if(sharingTableList!=null && !sharingTableList.isEmpty() )
            {
                Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                Map<String, List<SharingAccess__c> > globalSharingAccessesMap = new Map<String, List<SharingAccess__c> >();

                //mapping all Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toSharingAccessMap, globalSharingAccessesMap);

                if(!lob1toSharingAccessMap.isEmpty())
                {
                    Set<Id> lobAccounts = new Set<Id>();
                    for(AccountLob__c al : newAccountLobList)
                    {
                        lobAccounts.add(al.Account__c);
                    }

                    Map<Id,Account> soldToIdsToC2Accounts = new Map<Id, Account>();
                    List<AccountShare> accShareToInsert = new List<AccountShare>() ;
                    Set<Id> regionalIds = new Set<Id>();

                    if(!lobAccounts.isEmpty() )
                    {
                        for(Account soldTo : SharingUtils.getParentAccounts(lobAccounts))
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
                        for(AccountLob__c al : newAccountLobList)
                        {
                            //sharing Account if LOB1 & IMCDCompany match
                            if(lob1toSharingAccessMap.get(al.LOB1__c)!=null && soldToIdsToC2Accounts.get(al.Account__c)!=null && lob1toSharingAccessMap.get(al.LOB1__c).get(soldToIdsToC2Accounts.get(al.Account__c).IMCDCompany__c)!=null)
                            {
                                //sharing the sold to and Regional Account
                                if(soldToIdsToC2Accounts.get(al.Account__c).ParentId!=null)
                                {
                                    accShareToInsert.addAll(SharingUtils.accountSharing(al.Account__c, soldToIdsToC2Accounts.get(al.Account__c).ParentId, lob1toSharingAccessMap.get(al.LOB1__c).get(soldToIdsToC2Accounts.get(al.Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap ));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo+C2 LOB1 & IMCDCompany match','AccountLobTriggerHelper',lob1toSharingAccessMap.get(al.LOB1__c).get(soldToIdsToC2Accounts.get(al.Account__c).IMCDCompany__c));
                                }
                                else
                                {
                                    accShareToInsert.addAll(SharingUtils.accountSharing(al.Account__c, null, lob1toSharingAccessMap.get(al.LOB1__c).get(soldToIdsToC2Accounts.get(al.Account__c).IMCDCompany__c), Label.READ_WRITE_ACCESS, Label.NO_ACCESS, Label.MANUAL_RAW_CAUSE, ownersToAccsMap ));
                                    //SharingUtils.debugSharingReason('Account','sharing the soldTo LOB1 & IMCDCompany match','AccountLobTriggerHelper',lob1toSharingAccessMap.get(al.LOB1__c).get(soldToIdsToC2Accounts.get(al.Account__c).IMCDCompany__c));
                                }
                            }
                        }
                        if(!accShareToInsert.isEmpty())
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareToInsert, true);
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'AccountLobTriggerHelper') ;
        }
    }
    /***********************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: deletes AccountShare on Sold To Account + C2 Account to users based on sharingAccess table, upon AccountLob__c record deletion
    * Inputs : List<AccountLob__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void deleteAccountShareOnLOBDelete(List<AccountLob__c> oldAccLOBList)
    {
        try
        {
            // get the sharingAccess table
            List<SharingAccess__c> sharingTableList = SharingUtils.getSharingAccessTable(null);
            //get the deleted LOB
            Set<Id> accLobIdsSet = new Set<Id>();
            for(AccountLob__c acLob : oldAccLOBList)
            {
                accLobIdsSet.add(acLob.Id);
            }
            Map<Id,AccountLob__c> newAccountLobMap = new Map<Id,AccountLob__c>([SELECT Id, Name, Account__c, Account__r.IMCDCompany__c, Account__r.ParentId, LOB1__c
            FROM AccountLob__c
            WHERE Id IN : accLobIdsSet AND isDeleted = TRUE ALL ROWS ]);
            if(!sharingTableList.isEmpty() && newAccountLobMap!=null && !newAccountLobMap.isEmpty())
            {
                Map<String, Map <String, List<SharingAccess__c> > > lob1toDeleteSharingAccessMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                Map<String, List<SharingAccess__c> > globaltoDeleteSharingAccessesMap = new Map<String, List<SharingAccess__c> >();

                //mapping all Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                SharingUtils.mappingSharingAccessTable(sharingTableList, lob1toDeleteSharingAccessMap, globaltoDeleteSharingAccessesMap);

                if(!lob1toDeleteSharingAccessMap.isEmpty())
                {
                    Map<Id, List<SharingAccess__c>> accsToShareAccsMap = new Map<Id, List<SharingAccess__c>>();
                    Map<Id, Set<Id>> accIdsToUsrIds = new Map<Id, Set<Id>>();

                    //aggregating the Sharing access records related to previously deleted LOB Classifications Records
                    SharingUtils.aggregateRecordsToDelete(AccountLobTriggerHelper.class.getName(),newAccountLobMap.values(), lob1toDeleteSharingAccessMap, accsToShareAccsMap, globaltoDeleteSharingAccessesMap);
                    if(!accsToShareAccsMap.isEmpty())
                    {
                        //mapping the users that we need to delete from sharing of Sold To, Regional Accounts
                        SharingUtils.mapSharedUsersToRelObject(accsToShareAccsMap,accIdsToUsrIds);

                        List<AccountShare> accShareToDelete = new List<AccountShare>() ;
                        for(Account acc : [SELECT Id,
                                          (SELECT Id, AccountId, RowCause, UserOrGroupId FROM Shares)
                                           FROM Account
                                            WHERE Id IN : accsToShareAccsMap.keySet()])
                                            {
                                                for(AccountShare ac  : acc.Shares)
                                                {
                                                    if(accIdsToUsrIds.get(acc.Id).contains(ac.userOrGroupID) && ac.RowCause.equals(Label.MANUAL_RAW_CAUSE))
                                                    {
                                                        accShareToDelete.add(ac);
                                                    }
                                                }
                                            }
                        if(!accShareToDelete.isEmpty() )
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareToDelete, false);
                        }
                    }
                }
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'AccountLobTriggerHelper') ;
        }
    }

    /************************************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Set the 'Unique ID' field for a list of LOBCs.
    * Inputs: List<SObject>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    *************************************************************************/
    public static void setUniqueField(List<AccountLob__c> newItems) {
        for(AccountLob__c lob : newItems){
            String lob1 = String.isEmpty(lob.LOB1__c) ? '':  String.ValueOf(lob.LOB1__c) ; 
            String lob2 = String.isEmpty(lob.LOB2__c) ? '':  String.ValueOf(lob.LOB2__c) ; 
            String lob3 = String.isEmpty(lob.LOB3__c) ? '':  String.ValueOf(lob.LOB3__c) ; 
            lob.Unique_ID__c = String.ValueOf(lob.Account__c) + '|' + lob1 + '|' + lob2 + '|' + lob3;
        }
    }

    /**********************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Validate insert/update of AccountLob__c
    * Inputs: List<SObject>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    ***********************************************************/
    public static void validateLOBUpdate(Map<ID, AccountLob__c> newItemsMap) {

        if(AccountLobTriggerHelper.isExecuting) return;
        AccountLobTriggerHelper.isExecuting = true;

        Map<Id, List<AccountLob__c>> primLOBsMap = queryPrimaryLOBs(newItemsMap);

        Map<Id, Account> updateAccounts = new Map<Id, Account>();
        Map<Id, AccountLOB__c> updateLOBs = new Map<Id, AccountLOB__c>();

        for(AccountLOB__c lob : newItemsMap.values()){
            lob = atLeastOnePrimary(lob, primLOBsMap);

            if (lob.Primary__c) {
                updateAccounts = setAccountFields(lob, updateAccounts);
                updateLOBs = maxOnePrimaryLob(lob, primLOBsMap, updateLOBs);
            }
        }

        // Update Accounts + Primary LOBs.
        try {
            if (updateAccounts != null && !updateAccounts.isEmpty()) update updateAccounts.values();
            if (updateLOBs != null && !updateLOBs.isEmpty())         update updateLOBs.values();
        } catch (DmlException e) {
            DebugLog.addError(e.getMessage());
        }

        AccountLobTriggerHelper.isExecuting = false;
    }

    /**********************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Enforce that there must be a primary LOB.
    * Inputs: AccountLob__c, Map<Id, List<AccountLob__c>>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    *       20/08/2018  SF/JEBU/Added bypass baced on custom permission LockedAccountBypass
    ***********************************************************/
    public static AccountLob__c atLeastOnePrimary(AccountLob__c lob, Map<Id, List<AccountLob__c>> primLOBsMap) {
        if (!lob.Primary__c && !FeatureManagement.checkPermission('LockedAccountBypass') &&
                (!primLOBsMap.containsKey(lob.Account__c)) ||
                (primLOBsMap.containsKey(lob.Account__c) && primLOBsMap.get(lob.Account__c).size() < 1)) {
            lob.Primary__c.addError(Label.ERROR_LOB_MUST_BE_PRIMARY);
        }

        return lob;
    }

    /**********************************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Enforce that there cannot be more than one primary LOB.
    * Inputs: AccountLob__c, Map<Id, List<AccountLob__c>>, Map<Id, AccountLOB__c>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    ***********************************************************************/
    public static Map<Id, AccountLOB__c> maxOnePrimaryLob(AccountLob__c lob, Map<Id, List<AccountLob__c>> primLOBsMap, Map<Id, AccountLOB__c> updateLOBs) {
        List<AccountLob__c> accLOBs = primLOBsMap.get(lob.Account__c);
        if (accLOBs.size() > 1) {
            for (Integer i=0; i < accLOBs.size(); i++) {
                if      (accLOBs[i].Id == lob.Id) accLOBs[i].Primary__c = TRUE;
                else if (accLOBs[i].Id != lob.Id) accLOBs[i].Primary__c = FALSE;
                updateLOBs.put(accLOBs[i].Id, accLOBs[i]);
            }
        }
        return updateLOBs;
    }

    /*******************************************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Set LOB1/2/3 fields on Account appropriately (if LOB is primary).
    * Inputs: AccountLob__c, Map<Id, Account>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    *******************************************************************************/
    public static Map<Id, Account> setAccountFields(AccountLob__c lob, Map<Id, Account> updateAccounts) {
        updateAccounts.put(lob.Account__c,
                new Account(Id = lob.Account__c,
                        Primary_LOB1__c = lob.LOB1__c,
                        Primary_LOB2__c = lob.LOB2__c,
                        Primary_LOB3__c = lob.LOB3__c));

        return updateAccounts;
    }

    /*******************************************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Collect all Primary LOBCs related to the Accounts being updated.
    * Inputs: List<SObject>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    *******************************************************************************/
    public static Map<Id, List<AccountLob__c>> queryPrimaryLOBs(Map<ID, AccountLob__c> newItemsMap) {

        // Collect all related Account IDs into a set.
        Set<Id> accountIds = new Set<Id>();
        for (AccountLob__c accLob : newItemsMap.values()) {
            accountIds.add(accLob.Account__c);
        }

        // Collect all primary LOBs associated to the queried Accounts.
        List<AccountLob__c> primLOBs = [SELECT Id,
                Account__c,
                Primary__c,
                Unique_ID__c
        FROM   AccountLob__c
        WHERE  Account__c IN :accountIds
        AND    Primary__c = TRUE];

        // Create a map with the primary LOBs for each Account.
        Map <Id, List<AccountLob__c>> primLOBsMap = new Map <Id, List<AccountLob__c>>();
        for(AccountLob__c primLOB : primLOBs){
            if(!primLOBsMap.containsKey(primLOB.Account__c) && primLOBsMap.containsKey(primLOB.Id) == false){
                primLOBsMap.put(primLOB.Account__c, new List<AccountLob__c> { primLOB });
            } else if(primLOBsMap.containsKey(primLOB.Account__c) && primLOBsMap.containsKey(primLOB.Id) == false){
                primLOBsMap.get(primLOB.Account__c).add(primLOB);
            }
        }

        return primLOBsMap;
    }

    /*****************************************************************
	* Author: Leon Kempers
    * Company: Salesforce
    * Description: Prevents primary AccountLob__c from being deleted.
    * Inputs: List<SObject>
    * Test Class: TestAccountLobTrigger.apxc
    * History:
    *       20/08/2018  SF/JEBU/Added bypass baced on custom permission LockedAccountBypass
    *****************************************************************/
    public static void validateLOBDelete(Map<Id, SObject> oldItems) {
        for (AccountLob__c accLob : (List<AccountLob__c>) oldItems.values()) {
            if (accLob.Primary__c && !FeatureManagement.checkPermission('LockedAccountBypass')) {
                accLob.Primary__c.addError(Label.ERROR_CANT_DELETE_PRIMARY);
            }
        }
    }
}