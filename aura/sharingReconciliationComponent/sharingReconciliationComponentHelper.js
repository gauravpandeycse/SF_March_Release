({
	init : function(component, event, helper) {
        
        var action = component.get("c.execReconciliationBatch");
	  
        action.setParams({"recordId": component.get("v.recordId")});
		action.setCallback(this, function(response) {
            let state = response.getState();
			if(component.isValid() && state === "SUCCESS"){
 				//component.set("v.data", response.getReturnValue());
 				$A.get("e.force:closeQuickAction").fire();
			}
		});
        $A.enqueueAction(action);

	}
})