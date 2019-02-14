/******************************************************************************************************************************************************************
 * Author:          Wim van Beek
 * Company:         Salesforce / NNcourage
 * Description:     Event Handler PriceRenewalCampaign Helper
 * Inputs :         Comes from PriceRenewalCampaign.trigger
 * Test Class :
 * History :        May 18
 ******************************************************************************************************************************************************************/

public with sharing class PriceRenewalCampaignTriggerHandler extends TriggerHandler{

    private List<PriceRenewalCampaign__c>  newPriceRenewalCampaignList;
    private Map<ID, PriceRenewalCampaign__c>  oldPriceRenewalCampaignMap;

    public PriceRenewalCampaignTriggerHandler()
    {
        this.setMaxLoopCount(20);
        newPriceRenewalCampaignList =  (List<PriceRenewalCampaign__c>) Trigger.new;
    
        oldPriceRenewalCampaignMap =  (Map<Id,PriceRenewalCampaign__c>) Trigger.oldMap;
    }
    // Handle stage into actions
    protected override void beforeUpdate()
    {
        PriceRenewalCampaignTriggerHelper.beforeUpdateAction(newPriceRenewalCampaignList, oldPriceRenewalCampaignMap);
    }
}