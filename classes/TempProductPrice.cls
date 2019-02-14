/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Create a Price in the User's Price Book for a new Temp Product
			   Used as part of PB 'Default Process Builder for Product'
		       Method CreateTempProductPrice is bulkified.
Inputs:        InvocableVariable --> productId
Outputs:	   InvocableVariable --> success, error
Test Class:    TestTempProductPrice
User Story:	   https://imcdgroup.atlassian.net/browse/SFDP-109
History	
	06/05/2018	   Created class
------------------------------------------------------------*/	
global class TempProductPrice {

    // defines input variable which can be passed by the process builder.
    global class TempProductPriceRequest {
		@InvocableVariable (required=true)
		global ID productId;
        @InvocableVariable (required=true)
        global String imcdCompany;
    }
    
    // defines output variables 
 	global class TempProductPriceResult {
        @InvocableVariable (required=false)
		global Boolean success;
        
		@InvocableVariable (required=false)
		global String error;
    }
    
	// Custom exception
	class TempProductPriceException extends Exception {}
    
	@InvocableMethod ( label='Create Temp Product Price' description='Creates 0,00 Price Book Entry for User Local Price Book' )
    global static List<TempProductPriceResult> CreateTempProductPrice ( List<TempProductPriceRequest> requests ) {
       
		List<TempProductPriceResult> results = new List<TempProductPriceResult>();
		Set<String> errors = new Set<String>();
		Map<ID, String> mapProd = new Map<ID, String>();
        Set<String> comps = new Set<String>();
        Map<String, Pricebook2> mapPb = new Map<String, Pricebook2>();
        List<PricebookEntry> lstPbe = new List<PricebookEntry>();
        
		for ( TempProductPriceRequest request : requests ) {
			mapProd.put( request.productId, request.imcdCompany );
            comps.add( request.imcdCompany );
		}
        
        for ( Pricebook2 pb : [SELECT Id, ImcdCompany__c, DefaultCurrencyIsoCode__c FROM Pricebook2 WHERE ImcdCompany__c IN :comps 
                              AND IsActive = true AND isStandard = false AND DefaultCurrencyIsoCode__c <> null] ) {
        	mapPb.put( pb.ImcdCompany__c, pb );                          
		}
        
        for ( ID prodId : mapProd.keySet() ) {
            
            Pricebook2 pb = MapPb.get(MapProd.get(prodId));
            
            lstPbe.add (
                	new PricebookEntry ( Pricebook2Id = pb.Id
										, Product2Id = prodId
										, BasePrice__c = true
										, CurrencyIsoCode = 'EUR'
										, UnitPrice = 0
										, UseStandardPrice = false
										, IsActive = true )
			);
        }
        
		// create result object
        TempProductPriceResult result = new TempProductPriceResult();        
        
		// Use Database class and Saveresult. 
		Database.SaveResult[] lstSrPb = Database.insert(lstPbe, false); //allow partial succes
        
		// Iterate through each returned result
		for (Database.SaveResult srPb : lstSrPb) {

            if (!srPb.isSuccess()) {
        		// Operation failed, get Errors
        		Database.Error err = srPb.getErrors()[0];	
				String error = '[TempProductPrice][CreateTempProductPrice] An error has occurred insert PricebookEntry records.\n'
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