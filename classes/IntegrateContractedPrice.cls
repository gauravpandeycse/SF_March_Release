/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Integrate Contracted Prices once a Temp product becomes a Sales product
			   Used as part of PB 'Show all versionsDefault Process Builder for Contracted Price'
			   Developed under generic pattern for Invocable methods using Request/Result classes
			   such that it could be possible used as Apex API service.
		       Method IntegrateContractedPrices is bulkified.
Inputs:        InvocableVariable --> productId	
Outputs:	   InvocableVariable --> success, error
Test Class:    TestIntegrateContractedPrice	
User Story:	   https://imcdgroup.atlassian.net/browse/SFDP-610
History	
	05/09/2018	   Created class
	14/09/2018	   Updated, bulkified and tidied-up
------------------------------------------------------------*/	
global class IntegrateContractedPrice {
    
	// defines input variable which can be passed by the process builder.
    global class IntegrateContractedPriceRequest {
		@InvocableVariable(required=true)
		global ID productId;
    }
    
    // defines output variables 
 	global class IntegrateContractedPriceResult {
        @InvocableVariable(required=false)
		global Boolean success;
        
		@InvocableVariable(required=false)
		global String error;
    }
    
    // Custom exception
	class IntegrateContractedPriceException extends Exception {}

	// Invocable method, should be bulkified for List<IntegrateContractgedPriceRequest> size > 1
    @InvocableMethod (label='Integrate Contracted Prices' description='Identifies target contracted price records to be send for integration')
    global static List<IntegrateContractedPriceResult> IntegrateContractedPrices ( List<IntegrateContractedPriceRequest> requests ) {
        List<IntegrateContractedPriceResult> results = new List<IntegrateContractedPriceResult>();
        Set<String> errors = new Set<String>();
        Set<ID> productIds = new Set<ID>();
        
		// fetch all product Ids to set
        for (IntegrateContractedPriceRequest request : requests) {
	        productIds.add(request.productId);
		}

		// Fetch Event (as custom setting)        
        String event = IntegrationSettings__c.getInstance(UserInfo.getUserId()).EvtCreateContractedPrice__c;
		List<IntegrationLog__c> lstIntLog = new List<IntegrationLog__c>();
        
		// Fetches all Contracted price record for the Set of productIds
        // SBQQ__EffectiveDate__c / SBQQ__ExpirationDate__c are irrelevant, prices to be integrated regardless
        // SOQL should typically return just few records as Temp products aren't used in many quotes. 
        // Add IntegrationLog records to list
        for (SBQQ__ContractedPrice__c price : [SELECT Id FROM SBQQ__ContractedPrice__c 
                                                 WHERE SBQQ__Product__c IN :productIds]) {
			lstIntLog.add(new IntegrationLog__c (ContractedPrice__c  = price.Id, Status__c = 'Queued', Event__c = event) );
        }

		// create result object
        IntegrateContractedPriceResult result = new IntegrateContractedPriceResult();        
        
		// Use Database class and Saveresult. 
		Database.SaveResult[] lstSrInt = Database.insert(lstIntLog, false); //allow partial succes
        
		// Iterate through each returned result
		for (Database.SaveResult srInt : lstSrInt) {

            if (!srInt.isSuccess()) {
        		// Operation failed, get Errors
        		Database.Error err = srInt.getErrors()[0];	
				String error = '[IntegrateContractedPrice][IntegrateContractedPrice] An error has occurred insert IntegrationLog__c records.\n'
					+ err.getStatusCode() + ': ' + err.getMessage() + '\n'
					+ 'Fields affected: ' + + err.getFields();
				errors.add (error); // add to set
			}
 		}
        
        String debugErrors = '';
        for (String error : errors) {
            debugErrors += error;
        }
        
        // write list of errors to debug log (if any)
        if (!String.isBlank (debugErrors)) {
            DebugLog.addError(debugErrors);
            result.success = false;
            result.error = debugErrors;
        }
        
		results.add (result);
		return results;

    }
}