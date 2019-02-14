({  doInit : function(component, event, helper) {
        var action = component.get("c.getRecordTypeCaseNCR");
        action.setCallback(this, function(response){                       
            var state = response.getState();
            if (state === "SUCCESS") {				
                component.set("v.RecIdNCR", response.getReturnValue());
            } else {
                console.log("Failed with state: " + state);
            }
            component.set("v.initDone", true);
        }); 
    	$A.enqueueAction(action);
	},
	runAssignment : function(component, event, helper) {
		var action = component.get("c.runAssignmentRules");
        action.setParams({
            cs: component.get("v.caseRec")
		});
         action.setCallback(this, function(response){           
             var state = response.getState();
             var updSuccess = response.getReturnValue();
             if (state === "SUCCESS" && updSuccess) {	
                 helper.showSuccessToast();
				$A.get('e.force:refreshView').fire();
			} else if(!updSuccess){
                helper.showErrorToast();
            } else{                            
				console.log("Failed with state: " + state);
                helper.showErrorToast();
			}
        }); 
        $A.enqueueAction(action);
    }
})