/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
Description:   https://imcdgroup.atlassian.net/browse/SFDP-2223
Test Class     TestQuoteLineItemTriggerHelper
History
    17/12/2018	   Created class
------------------------------------------------------------*/
public without sharing class FollowupReportSummaryCompController {
    @auraEnabled
    public static FollowupReportSummary__c getFollowupReportSummary(ID quoteLineId) {
        return [SELECT ExternalComments__c, InternalComments__c FROM FollowupReportSummary__c WHERE QuoteLine__c =: quoteLineId LIMIT 1];
    }
}