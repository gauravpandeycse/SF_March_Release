/*------------------------------------------------------------
  Author		: Jeroen Burgers
  Company		: Salesforce
  Description	: SBQQ__DiscountSchedule__c trigger handler class
				  this class implements two overriden methods 'updatePricebookEntries'
				  for Insert/Delete triggers the new respectively old list is processed
			      for every PBE matching the Product2Id / Pricebook2Id the 'Modified__c' is populated with Now()
				  for Update trigger, the old and new lists are bot processes as we want to update both
				  PBE records for the 'old' product and the 'new' product associated with the discount schedule
  Inputs 		: 
  Test Class 	: TestDiscountScheduleTriggerHelper
  History		: 23/05/2018 created
------------------------------------------------------------*/	
public with sharing class DiscountScheduleTriggerHelper {
    
	//For Update trigger, we process both new and old lists
	public static void updatePricebookEntries(List<SBQQ__DiscountSchedule__c> newDiscountScheduleList, List<SBQQ__DiscountSchedule__c> oldDiscountScheduleList) {
        updatePricebookEntries (newDiscountScheduleList);
        updatePricebookEntries (oldDiscountScheduleList);
    }

	//For Insert & Delete trigger, we process the new respectively the old list
    public static void updatePricebookEntries(List<SBQQ__DiscountSchedule__c> discountScheduleList) {
        try {
	        //map containing ProductId, PricebookId
    	    Map<ID, ID> pbEntries = new Map<ID, ID>();
	        List<PricebookEntry> lstPbeUpdate = new List<PricebookEntry>();
            Set<String> errors = new Set<String>();
        
    	    for (SBQQ__DiscountSchedule__c schedule : discountScheduleList) {
				pbEntries.put(schedule.SBQQ__Product__c, schedule.SBQQ__Pricebook__c);
			}
        
			for (PricebookEntry pbEntry : [SELECT Product2Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id IN :pbEntries.keySet()]) {
    	        // pricebook matches? Then its a Pbe to update!
        	    if (pbEntry.Pricebook2Id == pbEntries.get(pbEntry.Product2Id)) {
            	    lstPbeUpdate.add(new PricebookEntry ( Id = pbEntry.Id, Modified__c = datetime.now(), Incoterm__c='CIP') );
            	}
			}
			
            // forcing an exception while unit testing / test coverage runs
            if (Test.isRunningTest() && discountScheduleList[0].Name == 'RaiseException') 
				lstPbeUpdate[0].Incoterm__c = 'Raise Exception';
            
            Savepoint sp = Database.setSavepoint();
			Database.SaveResult[] srLstPbe = Database.update(lstPbeUpdate, false); //allow partial success, otherwise throws DML exception
			// Iterate through each returned result
			for (Database.SaveResult srPbe : srLstPbe) {
				if (!srPbe.isSuccess()) {
                    // Operation failed, get Errors
        			Database.Error err = srPbe.getErrors()[0];	
					String error = '[DiscountScheduleTriggerHelper][updatePricebookEntries] An error has occurred updating PricebookEntry.\n'
						+ err.getStatusCode() + ': ' + err.getMessage() + '\n'
						+ 'Fields affected: ' + + err.getFields();
					errors.add (error); // add to set
				}
 			}
        
            if (!errors.isEmpty()) {
                Database.rollback(sp); // rollback (remember, provided AllorNone = false!)
				DebugLog.addError(String.join(new List<String>(errors), ';'));
            }
            
			return;
        }
		catch(Exception ex) {
            DebugLog.addException(ex, '[DiscountScheduleTriggerHelper][updatePricebookEntries]');
        } 
    }
}