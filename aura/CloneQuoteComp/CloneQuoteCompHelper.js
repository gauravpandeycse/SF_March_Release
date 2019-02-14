({
	init : function(component, event, helper) {
        var action = component.get("c.getNumQuotes");
		// Get the number of Quotes for the Opportunity Quote's parent opportunity
        action.setParams({"quoteId": component.get("v.recordId")});
		action.setCallback(this, function(response) {
            let state = response.getState();
			if(component.isValid() && state === "SUCCESS"){
 				component.set("v.numQuotes", response.getReturnValue());   		
			}
		});
        $A.enqueueAction(action);
		
	}
    , validateInput : function(component, event, helper) {  
        var validityFrom = component.find("validityFrom");
        var validityTo = component.find("validityTo");
        var quoteExpiration = component.find("quoteExpiration");
		var incoTerms = component.find("incoTerms");
        
        if (validityFrom.get("v.value") > validityTo.get("v.value")) {
           validityFrom.setCustomValidity($A.get('$Label.c.IMCD_LC_MSG_ValidityDtValidation'));
           validityTo.setCustomValidity($A.get('$Label.c.IMCD_LC_MSG_ValidityDtValidation')); 
        }
		else {
           validityFrom.setCustomValidity('');
           validityTo.setCustomValidity('');
		}

        if (new Date(quoteExpiration.get("v.value")) <= new Date())
            quoteExpiration.setCustomValidity($A.get('$Label.c.IMCD_LC_MSG_ExpirationDtValidation')); 
        else
            quoteExpiration.setCustomValidity('');
        
        if (validityFrom.reportValidity() && 
        	validityTo.reportValidity() &&
        	quoteExpiration.reportValidity() &&
            incoTerms.get("v.value").length != 0)
            component.set("v.formValid", true);
        else 
			component.set("v.formValid", false);
        
		validityFrom.reportValidity();
        validityTo.reportValidity();
        quoteExpiration.reportValidity();
    }
    , cloneQuoteAction: function(component, event, helper){
        var action = component.get("c.cloneQuote");
		// Clone the Opportunity quote and its line items
		
        var quoteExpirationJson = new Date(component.find("quoteExpiration").get("v.value")).toJSON();
        var validityToJson = new Date(component.find("validityTo").get("v.value")).toJSON();
        var validityFromJson = new Date(component.find("validityFrom").get("v.value")).toJSON();
        var cloneLines = component.find("cloneLines").get("v.checked");
		var incoTerms = component.find("incoTerms").get("v.value");
        
        action.setParams({
            				"quoteId": component.get("v.recordId")
							, "quoteExpirationJson": quoteExpirationJson
        					, "validityToJson": validityToJson
							, "validityFromJson": validityFromJson
	                        , "incoTerms": incoTerms
           					, "cloneLines": cloneLines
                        });

		action.setCallback(this, function(response) {
            let state = response.getState();	
            if (component.isValid() && state === "SUCCESS") {
				var result = response.getReturnValue(); // it should return the Cloned quotes Id. If empty, an error occurred         
                var toastMsg = '';
                var toastType = 'success';
                var toastMode = 'dismissible';
                
    			if (result != null)
                    toastMsg = $A.get('$Label.c.IMCD_LC_MSG_CloneQuoteSuccess');
				else {
					toastMsg = $A.get('$Label.c.IMCD_LC_MSG_CloneQuoteError') + component.get("v.recordId");
					toastType = 'error';
                    toastMode = 'sticky';
                }
                
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
					"title": 'Results',
					"message": toastMsg,
					"type": toastType,
					"mode": toastMode
				});
                	
				toastEvent.fire();
				
                if (result != null) {
					$A.get("e.force:closeQuickAction").fire();
					var navEvt = $A.get("e.force:navigateToSObject");
    				navEvt.setParams({
      					"recordId": result
      					, "slideDevName": "detail"
        			});
    				navEvt.fire();
                }
            }
            
		});
        $A.enqueueAction(action);
		
    }
})