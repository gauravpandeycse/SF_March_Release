/******************************************************************************************************************************************************************
 * Author: Wim van Beek
 * Company: Salesforce / NNcourage
 * Description: PriceCampaign object Trigger
 * Inputs : DB events
 * Test Class :
 * History :
 ******************************************************************************************************************************************************************/
// Price Renewal Campaign
trigger PriceRenewalCampaign on PriceRenewalCampaign__c (
                                            before insert,
                                            before update,
                                            before delete,
                                            after insert,
                                            after update,
                                            after delete,
                                            after undelete)
{
    new PriceRenewalCampaignTriggerHandler().run();
}