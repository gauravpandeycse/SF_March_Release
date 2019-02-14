global class QuoteThrottledRecalculate_Batch implements Database.Batchable<sObject> {

 /*********************************************
  * Author:  Jan Janssen, Salesforce.com
  * Purpose: the prupose of this batch is to perform an update to a set of Quotes in order to
  *          trigger a recalculation of the Quote on Heroku. Since there is a limit of 
  *          3600 Heroku calls per hour, we will only process 2500 updates.
  *          The batch can therefore be scheduled to run every hour.
  *          There are two sets of Quotes that need recalculation:
  *          1. Quotes that were migrated and have the TF_MigrationRecalcNeeded__c set to TRUE
  *         2. Quotes that failed their calculation and are present in the SBQQ__RecordJobs__c object
  *         We will first process all migrated Quotes; if there's zero of them, we will process errors
  * ********************************************/
    
   global Database.QueryLocator start(Database.BatchableContext BC) {
       IntegrationSettings__c intSettings = IntegrationSettings__c.getInstance() ;
       Integer limitRows = intSettings.Quote_Recalculations_Per_Hour__c.intValue();
       String queryMig = 'SELECT id FROM SBQQ__Quote__c WHERE TF_MigrationRecalcNeeded__c = TRUE LIMIT :limitRows';
       return Database.getQueryLocator(queryMig);
   }
 
   global void execute(Database.BatchableContext BC, List<SBQQ__QUote__c> scope) {
      for(SBQQ__QUote__c thisQuote : scope)
      {
        thisQuote.TF_MigrationRecalcNeeded__c = FALSE; 
      } 

     Database.SaveResult[] lsr = Database.update(scope,false);
      Integer recordid = 0;
      for (Database.SaveResult SR : lsr) {
	     if (!SR.isSuccess()) {
	        system.debug('Quote update failed: ' + scope[recordid].id + ', ' + SR.getErrors()[0].getMessage());
	    }
        recordid++;
     }
  } 
 
   global void finish(Database.BatchableContext BC) {
       //Nothing to do here
   }
    
}