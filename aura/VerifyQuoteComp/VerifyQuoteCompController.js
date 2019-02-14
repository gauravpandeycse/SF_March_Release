({
	init : function(component, event, helper) {
		component.set('v.columns', [
			{label: 'Warning', fieldName: 'ErrorMsg__c', type: 'text', sortable:false, cellAttributes: {alignment: 'left'}, iconName: 'utility:warning' },
		]);
	}
	, recordUpdated : function(component, event, helper) {
		var action = component.get("c.verifyQuote");
		var showbanner = false;
		var title, subtitle = "";
		action.setParams({"quoteId": component.get("v.recordId")});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if(component.isValid() && state === "SUCCESS"){

				component.set("v.data", response.getReturnValue());

				if (response.getReturnValue().length > 0) {
					title = $A.get("$Label.c.IMCD_LC_BannerTitle_QuoteVerification");
					subtitle = $A.get("$Label.c.IMCD_LC_BannerSubTitle_QuoteVerification");
					showbanner = true; 
				}

				// Send component event to display or hide banner (using application event)
				var event = $A.get("e.c:showBannerEvent");
				event.setParams({
					"title": title
					, "subtitle": subtitle
					, "showbanner": showbanner
				});
				event.fire();
			}
		});

		$A.enqueueAction(action);
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