({
	init: function(component, event, helper) {
		helper.init(component, event, helper);
	}
	, submitProspect: function(component, event, helper){
		component.set("v.disableSubmit", true);
        helper.submitProspect(component, event, helper);
	}
   	, closeAction: function(component, event, helper){
		$A.get("e.force:closeQuickAction").fire();
	}
	, showSpinner : function(component,event,helper){
		// display spinner when aura:waiting (server waiting)
		component.set("v.toggleSpinner", true);  
	}
    , hideSpinner : function(component,event,helper){
		// hide when aura:donewaiting
		component.set("v.toggleSpinner", false);
    }
    , validateIntegrationId : function(component,event,helper) {
		var integrationId = component.find("integrationId");
		if (integrationId.reportValidity()) component.set("v.disableSubmit", false);
		else component.set("v.disableSubmit", true);
	}
})