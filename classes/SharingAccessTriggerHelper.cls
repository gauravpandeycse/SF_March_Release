/******************************************************************************************************************************************************************
 * Author: Eli Pogorelov
 * Company: Salesforce
 * Description: Event Handler SharingAccessTrigger
 * Inputs :
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
public without sharing class SharingAccessTriggerHelper
{
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Changes the name of the SharingAccess record according to UserDisplayName__c field on SharingAccess record insert,
    * Inputs : List<SharingAccess__c>, Map<Id,SharingAccess__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void updateRecordName(List<SharingAccess__c> newSharingAccessList)
    {
        try
        {
            List<SharingAccess__c> saToInsertList = new List<SharingAccess__c>();
            for(SharingAccess__c sa : newSharingAccessList)
            {
                SharingAccess__c saTemp = new SharingAccess__c();
                saTemp = sa.clone(true,true,true,true);
                saTemp.bypassEditValidationRule__c = true;
                saTemp.Name = sa.UserDisplayName__c;
                saToInsertList.add(saTemp);
            }
            if(!saToInsertList.isEmpty())
            {
                update saToInsertList;
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'SharingAccessTriggerHelper') ;
        }
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Updates sharing for Accounts, Opportunities, Quotes, OpportunityLineItems, QuoteLineItems on insert of SharingAccess record
    * Inputs : List<SharingAccess__c>
    * Test Class :
    * History :
    ******************************************************************************************************************************************************************/
    public static void recalculateOnInsertSharing(List<SharingAccess__c> newSharingAccessList)
    {
        try
        {
             List<SharingAccess__c> principalSaList = new List<SharingAccess__c>();
             List<SharingAccess__c> nonPrincipalSaList = new List<SharingAccess__c>();

             //dividing the sharing access by principal
             SharingUtils.divideByPrincipal(newSharingAccessList,principalSaList, nonPrincipalSaList);
             // get Owners to Accounts Id's to avoid sharing the Account to the owner
             Set<Id> relUserId = new Set<Id>();
             for(SharingAccess__c sa : newSharingAccessList)
             {
                 relUserId.add(sa.UserId__c);
             }
             Map<Id,Set<Id>> ownersToAccsMap = SharingUtils.mapOwnersToAcoountAccountsByIds(relUserId);

             Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
             Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();

             //mapping principalId__c == NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
             SharingUtils.mappingSharingAccessTable(nonPrincipalSaList, lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap);

             Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
             Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

             //mapping principalId__c != NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
             SharingUtils.mappingSharingAccessTable(PrincipalSaList, lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);

            /*Sharing Accounts,Opportunities Quotes based on rules for AccountLob,Opportunity,Quote,OpportunityLineItem,QuoteLineItem queueable jobs are chained
            in this order, parent is : QueueableAccLobRecalculateSharing*/
            QueueableAccLobRecalculateSharing insertAccSharesBasedLobJob = new QueueableAccLobRecalculateSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap, ownersToAccsMap,
            lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap) ;
            if(!Test.isRunningTest())
            {
                System.enqueueJob(insertAccSharesBasedLobJob);
            }
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'SharingAccessTriggerHelper') ;
        }
    }

   /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: Deletes sharing for Accounts, Opportunities, Quotes, OpportunityLineItems, QuoteLineItems on delete of SharingAccess record
   * Inputs : List<SharingAccess__c>
   * Test Class :
   * History :
   ******************************************************************************************************************************************************************/
    public static void recalculateOnDeleteSharing( List<SharingAccess__c> oldSharingAccList)
    {
        try
        {
            List<SharingAccess__c> principalSaList = new List<SharingAccess__c>();
            List<SharingAccess__c> nonPrincipalSaList = new List<SharingAccess__c>();

            //dividing the sharing access by principal
            SharingUtils.divideByPrincipal(oldSharingAccList, principalSaList, nonPrincipalSaList);

            if (oldSharingAccList != null && !oldSharingAccList.isEmpty())
            {
                Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessNoPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                Map<String, List<SharingAccess__c> > globalSharingAccessesNoPrincipalMap = new Map<String, List<SharingAccess__c> >();

                //mapping principalId__c == NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                SharingUtils.mappingSharingAccessTable(nonPrincipalSaList, lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap);

                Map<String, Map <String, List<SharingAccess__c> > > lob1toSharingAccessPrincipalMap = new Map<String, Map <String, List<SharingAccess__c> > >();
                Map<String, List<SharingAccess__c> > globalSharingAccessesPrincipalMap = new Map<String, List<SharingAccess__c> >();

                //mapping principalId__c != NULL Sharing Access records by LOB1 keys and IMCDCompany and creating the global Sharing Access table
                SharingUtils.mappingSharingAccessTable(PrincipalSaList, lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);

                /*Delete Sharing Accounts based AccountLob,Opportunity,Quote,OpportunityLineItem,QuoteLineItem queueable jobs are chained
                in this order, parent is : QueueableAccLobDeleteSharing*/
                QueueableAccLobDeleteSharing deleteAccSharesBasedLobJob = new QueueableAccLobDeleteSharing(lob1toSharingAccessNoPrincipalMap, globalSharingAccessesNoPrincipalMap,
                        lob1toSharingAccessPrincipalMap, globalSharingAccessesPrincipalMap);
                if(!Test.isRunningTest())
                {
                    System.enqueueJob(deleteAccSharesBasedLobJob);
                }
            }
        }
        catch (Exception ex)
        {
            DebugLog.addException(ex, 'SharingAccessTriggerHelper');
        }
    }
}