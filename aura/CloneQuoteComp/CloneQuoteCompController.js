({
	init: function(component, event, helper) {
		helper.init(component, event, helper);
	}
    , validateInput: function(component, event, helper) {
        helper.validateInput(component, event, helper);
    }
    , cloneQuoteAction: function(component, event, helper){
		component.set("v.formValid", false); // disable button - immediately
        helper.cloneQuoteAction(component, event, helper);
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
})