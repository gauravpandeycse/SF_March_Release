/*------------------------------------------------------------  
  Author:        Wim van Beek 
  Company:       Salesforce / NNcourage 
  Description:   Update and/or Create Contracted prices from Quote. 
  Inputs:        QuoteId OR OpportunityID (can be mixed) via Invocable

  History 
  
  2/5/2018      Initial 
------------------------------------------------------------
*/  
public with sharing class CPQcreateContracedPrice {

// Call from Process builder. 
@InvocableMethod(label='Create Contracted prices ' description='Create Contracted prices from Quote')
    public Static List<SBQQ__Quote__c> go(List<Id> quoteOrOpportunityId){
        IMCDUtils.debugLimits('[CPQcreateContracedPrice][go] at method entry');
        system.debug('------ quoteOrOpportunityId '+ quoteOrOpportunityId);
        PriceRenewalCampaignUtils.createContractedPrices(quoteOrOpportunityId);
        IMCDUtils.debugLimits('[CPQcreateContracedPrice][go] at method exit');
        return null;
    }
}