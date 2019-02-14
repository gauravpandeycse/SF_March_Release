({
	init: function(component, event, helper) {
		helper.init(component, event, helper);
	}
	, showSpinner: function(component,event,helper){
		// display spinner when aura:waiting (server waiting)
		component.set("v.toggleSpinner", true);
	}
	, hideSpinner: function(component,event,helper){
		// hide when aura:donewaiting
		component.set("v.toggleSpinner", false);
	}
})