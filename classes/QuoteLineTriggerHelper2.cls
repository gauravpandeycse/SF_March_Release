public without sharing class QuoteLineTriggerHelper2
{
    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Description: Prepaire check on double products if quote change
    * Inputs : Map<Id, SBQQ__Quote__c>
    * Test Class : TestPriceRenewalCampaign.checkDoubleProductsTEST
    * History :
    * new 9-11-18 Wim 
    * 
    ******************************************************************************************************************************************************************/
    public Class DoubleProductCheck{
        Public id errId;
        Public String errMsg;
    }

    public static void checkDoubleProducts(Map<id, SBQQ__Quote__c> oldQtMap, Map<id, SBQQ__Quote__c> newQtMap){

        Map<Id, SBQQ__QuoteLine__c> todoLines = new  Map<Id, SBQQ__QuoteLine__c>();
        for (SBQQ__Quote__c quote: newQtMap.values()){
            if (quote.QuoteType__c == 'Customer'  || quote.QuoteType__c ==  'Single'){
                if (quote.IncoTerms2__c != oldQtMap.get(quote.id).IncoTerms2__c  || 
                    quote.ShipToAdressId__c != oldQtMap.get(quote.id).ShipToAdressId__c){
                    todoLines.put(quote.id, null);
                    system.debug('------ todoLines '+ todoLines);
                }
            }
        }
        if (todoLines.size() > 0){
            todoLines = new map<id,SBQQ__QuoteLine__c>([SELECT id, UniqueKey__c, SBQQ__Product__c 
                                                        FROM SBQQ__QuoteLine__c 
                                                        WHERE SBQQ__Quote__c =: todoLines.keyset()]);
            DoubleProductCheck DoubleProductCheck = new DoubleProductCheck();
            DoubleProductCheck = checkDoubleProducts(todoLines, true);
            system.debug('------ DoubleProductCheck '+ DoubleProductCheck);
            if (DoubleProductCheck.errId != null){
                SBQQ__Quote__c quoteWithError = newQtMap.get(DoubleProductCheck.errId);
                quoteWithError.addError(DoubleProductCheck.errMsg);
            }
        }

    }


    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Description: Check if productdefinitions already exists. 
    *               Reads all QL of account with one of the UniqueKeys in  newQtLineLst
    *               If Finding = ToFindFrom and 'Single' quote. trow Exception
    * Inputs : Map<Id, SBQQ__QuoteLine__c>
    * Test Class : TestPriceRenewalCampaign.checkDoubleProductsTEST
    * History :
    * new 7-8-18 Wim 
    * Include Customer quote 21-8-18
    * Check for identical QL per quote and check in opportunity quote 11-10-2018
    ******************************************************************************************************************************************************************/

    public static DoubleProductCheck checkDoubleProducts(Map<id, SBQQ__QuoteLine__c> newQtLineMap, Boolean returnErrors){
        DoubleProductCheck DoubleProductCheck = new DoubleProductCheck();
        Map<String, SBQQ__QuoteLine__c> quoteLinesMap = new Map<String, SBQQ__QuoteLine__c>();
        Set<String> theCPIds = new Set<String>();
        Set<String> theUniqueIds = new Set<String>();
        Set<Id> theUniqueProducts = new Set<Id>();
        Map<String, SBQQ__QuoteLine__c> uniqueOrg = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, SBQQ__QuoteLine__c> uniqueComp = new Map<String, SBQQ__QuoteLine__c>();
        Set<Id> theAccIds = new Set<Id>();
        List<String> allowedType = new List<String>{'Customer','Single'};
        for (SBQQ__QuoteLine__c quoteLine : newQtLineMap.values() ){
            if (theUniqueIds.contains(quoteLine.UniqueKey__c) == true  ){   // Change 3-12-2018  
//            if (theUniqueIds.contains(quoteLine.UniqueKey__c) == true && Test.isRunningTest() == false ){   // New 11-10-2018  Check for double NEW QL only
                String err = 'Same product configuration found in this quote';
                if (returnErrors == true){
                    DoubleProductCheck.errId = quoteLine.SBQQ__Quote__c;
                    DoubleProductCheck.errMsg = err;
                    } else {
                    quoteLine.addError(err);
                }
            }
            theCPIds.add(quoteLine.id);
            theUniqueIds.add(quoteLine.UniqueKey__c);
            theUniqueProducts.add(quoteLine.SBQQ__Product__c);
        }
        system.debug('------ checkDoubleProducts, theUniqueIds.size() '+ theUniqueIds.size());
        system.debug('------ checkDoubleProducts, theUniqueIds '+ theUniqueIds);
        for (SBQQ__QuoteLine__c quoteLine:[SELECT   Id, 
                                                    SBQQ__Quote__r.SBQQ__Account__c, 
                                                    UniqueKey__c 
                                                FROM SBQQ__QuoteLine__c 
                                                WHERE Id =: theCPIds]){
            theAccIds.add(quoteLine.SBQQ__Quote__r.SBQQ__Account__c);
        }

        for (SBQQ__QuoteLine__c quoteLine :[SELECT  Id, 
                                                    SBQQ__Quote__r.SBQQ__Account__c, 
                                                    UniqueKey__c, 
                                                    SBQQ__Quote__r.QuoteType__c, 
                                                    SBQQ__Quote__r.Name,
                                                    SBQQ__Product__R.Name 
                                                FROM SBQQ__QuoteLine__c  
                                                WHERE SBQQ__Quote__r.SBQQ__Account__c = : theAccIds  
                                                AND   SBQQ__Quote__r.QuoteType__c = : allowedType  
                                                AND   SBQQ__Product__c = :  theUniqueProducts  // New 29-10-18                                           
                                                AND  UniqueKey__c = : theUniqueIds ]){

            String Unique =quoteLine.SBQQ__Quote__r.SBQQ__Account__c + ';' + quoteLine.UniqueKey__c;
            if (theCPIds.contains(quoteLine.id) == true){
                uniqueOrg.put(Unique, quoteLine);  // Looking for this
            }
            if (theCPIds.contains(quoteLine.id) == false){
                uniqueComp.put(Unique, quoteLine);  // Looking into this
            }
            if (uniqueOrg.containsKey(Unique) == true && uniqueComp.containsKey(Unique) == true){ // Both have match
                if (uniqueOrg.get(Unique).SBQQ__Quote__r.QuoteType__c == 'Customer'  || 
                    uniqueOrg.get(Unique).SBQQ__Quote__r.QuoteType__c == 'Single'  ){  // For Customer and Single 21-8-18
                    SBQQ__QuoteLine__c errQL= newQtLineMap.get(uniqueOrg.get(Unique).id);
    //                if (  Test.isRunningTest() == false){
                        String err = 'Cannot use '+  uniqueOrg.get(Unique).SBQQ__Product__R.Name  +', product already exists in Quote ' + uniqueComp.get(Unique).SBQQ__Quote__r.Name;
                        if (returnErrors == true){
                            DoubleProductCheck.errId = uniqueOrg.get(Unique).SBQQ__Quote__c;
                            DoubleProductCheck.errMsg = err;

                        } else {
                            errQL.addError(err);
                        }
    //               }
                }
            }
        }
        return DoubleProductCheck;
    }

    /******************************************************************************************************************************************************************
    * Author: Wim van Beek
    * Company: Salesforce/NNcourage
    * Description: Reset the SetContracted bit to indicate the QuoteLine has been changed
    * Inputs : List<SBQQ__QuoteLine__c> Map<Id, SBQQ__QuoteLine__c>
    * Start: From beforeupdate trigger
    * History :
    * new 27-8-18 Wim 
    * 29-8-18 Also in beforeinsert.
    * 16-10-18 Updated some other required fields 
    * 21-11-2018 SFDP-2032 Format amount field 
    * 4-12-2018 SFDP-2159 Format totalamount field
    ******************************************************************************************************************************************************************/

    public static void updateSetContracted(List<SBQQ__QuoteLine__c> newQtLineLst, Map<Id, SBQQ__QuoteLine__c> oldQtLineMap){
        for (SBQQ__QuoteLine__c newQuoteLine : newQtLineLst){
            newQuoteLine.SBQQ__ContractedPrice__c = null;  // New 26-9-2018 Reset all (including wrong) connections to Contracted Prices.
            if (newQuoteLine.TF_PricePerUOMwithUOM__c != ImcdUtils.formatAmount(newQuoteLine.UOMPrice__c, 4)){
                newQuoteLine.TF_PricePerUOMwithUOM__c = ImcdUtils.formatAmount(newQuoteLine.UOMPrice__c, 4) ;  // SFDP-2032 01-12-2018 WvB
            }
            // New 4-2-2019 Added currency
            if (newQuoteLine.TF_CustomerTotal__c != newQuoteLine.CurrencyIsoCode + ' ' +  ImcdUtils.formatAmount(newQuoteLine.SBQQ__CustomerTotal__c, 2)){
                newQuoteLine.TF_CustomerTotal__c  = newQuoteLine.CurrencyIsoCode + ' ' + ImcdUtils.formatAmount(newQuoteLine.SBQQ__CustomerTotal__c, 2);  // SFDP-2159 04-12-2018 WvB
            }
            newQuoteLine.CanCreateCP__c = newQuoteLine.TF_CanCreateCP__c;

            if (newQuoteLine.RecordTypeId != newQuoteLine.RequiredRecordtypeId__c){
                newQuoteLine.RecordTypeId = newQuoteLine.RequiredRecordtypeId__c; // Fix recordtypeid 16-10-18
            }
            if (oldQtLineMap == null){
                newQuoteLine.SetContracted__c = false;  
            } else {
                SBQQ__QuoteLine__c oldQuoteLine = oldQtLineMap.get(newQuoteLine.id);
                system.debug('------ oldQuoteLine '+ oldQuoteLine);
                system.debug('------ newQuoteLine '+ newQuoteLine);
//                for (SBQQ__QuoteLine__c ql: newQtLineLst){  // Copy CanCreateCP from Product2 to QL to Quote via Rollup
  //                  ql.CanCreateCP__c = ql.TF_CanCreateCP__c;
           //         ql.TF_PricePerUOMwithUOM__c = ImcdUtils.formatAmount(ql.UOMPrice__c, 4);  // SFDP-2032 21-11-2018 WvB

    //            }
                if (oldQuoteLine != null 
                                    && oldQuoteLine.SBQQ__NetPrice__c != null 
                                    && newQuoteLine.SBQQ__NetPrice__c != null
                                    && newQuoteLine.PricePerUOM__c != null 
                                    && oldQuoteLine.PricePerUOM__c != null 
                                    && newQuoteLine.SetContracted__c == true   // Make sure all elements exist
                                    ){
                    if (
                        (newQuoteLine.PriceValidityStart__c != oldQuoteLine.PriceValidityStart__c)  ||  
                        (newQuoteLine.PriceValidityEnd__c != oldQuoteLine.PriceValidityEnd__c)  ||  
                        (Math.abs( newQuoteLine.SBQQ__NetPrice__c  -  oldQuoteLine.SBQQ__NetPrice__c ) > 0.001) ||  // abs to avoid silly rounding issues 
                        (Math.abs( newQuoteLine.PricePerUOM__c   -  oldQuoteLine.PricePerUOM__c  ) > 0.001) ||  
                        (newQuoteLine.UniqueKey__c != oldQuoteLine.UniqueKey__c)  ||  
                        (newQuoteLine.UOM__c != oldQuoteLine.UOM__c)  
                        ) 
                        {
                            newQuoteLine.SetContracted__c = false;  
                            system.debug('------ updateSetContracted SetContracted__c = false'+ newQuoteLine);
                        } 
                } 
            }
        }
    }

}