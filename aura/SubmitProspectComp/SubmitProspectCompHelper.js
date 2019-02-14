({
    init: function(component, event, helper) {
		var action = component.get("c.getData");
	    /*
	        Get Prospect record details (Map including other attributes)
	        data.Primary_LOB1__c
	        data.LockedForIntegration__c
	        data.isValidShipping__c
	        data.hasActiveIntegration
	        data.sfManagedAccounts
		*/
        action.setParams({"recordId": component.get("v.recordId")});
		action.setCallback(this, function(response) {
            let state = response.getState();
			if(component.isValid() && state === "SUCCESS"){
 				component.set("v.data", response.getReturnValue());
				//in case its a SF-Managed account initially disable the submit until a IntegrationId is provided
				if (component.get("v.data.sfManagedAccounts")) component.set("v.disableSubmit", true);
			}
		});
        $A.enqueueAction(action);
    }
    ,submitProspect: function(component, event, helper) {
		// Submitting Prospect for integration. Logically transactionally in Apex controller.
        var action = component.get("c.integrateProspect");
		var integrationId = '';

		if (component.get("v.data.sfManagedAccounts")) integrationId = component.find("integrationId").get("v.value");

        action.setParams({"recordId": component.get("v.recordId"),
	                      "integrationId": integrationId
                          });
		action.setCallback(this, function(response) {
            let state = response.getState();	
            if(component.isValid() && state === "SUCCESS") {
				var result = response.getReturnValue();          
                var toastMsg = '';
                var toastType = 'success';
                var toastMode = 'dismissible';
                
    			if (result) {
				    if (component.get("v.data.sfManagedAccounts")) toastMsg = $A.get('$Label.c.IMCD_LC_MSG_ConvertProspectSuccess');
					else toastMsg = $A.get('$Label.c.IMCD_LC_MSG_SubmitProspectSuccess');
			    }
				else {
					toastMsg = $A.get('$Label.c.IMCD_LC_MSG_SubmitProspectError');
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
				$A.get('e.force:refreshView').fire();
				$A.get("e.force:closeQuickAction").fire();
            }
            
		});
        $A.enqueueAction(action);
	}
})