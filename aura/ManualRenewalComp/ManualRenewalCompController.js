({
	init: function(component, event, helper) {
		helper.init(component, event, helper);
	}
    , validateInput: function(component, event, helper) {
       helper.validateInput(component, event, helper);
    }
    , createRenewalAction: function(component, event, helper){
		component.set("v.formValid", false); // disable button - immediately
		helper.createRenewalAction(component, event, helper);
    }
   	, closeAction: function(component, event, helper){
		$A.get("e.force:closeQuickAction").fire();
	}
	, showSpinner: function(component,event,helper){
		// display spinner when aura:waiting (server waiting)
		component.set("v.toggleSpinner", true);  
	}
    , hideSpinner: function(component,event,helper){
		// hide when aura:donewaiting
		component.set("v.toggleSpinner", false);
    }
    , rowSelectAction: function (component, event, helper) {
		var numSelectedRows = event.getParam("selectedRows").length;
        var maxSelectedRows = component.get("v.maxSelection");
 
        if (numSelectedRows > maxSelectedRows) {
            helper.showNotification(component, "error", "Too many products selected"
                     , helper.format($A.get("$Label.c.IMCD_LC_MSG_TooManyProductsSelected"), maxSelectedRows));
        	component.set("v.canNext", false);
        }
        else if (numSelectedRows > 0)
     		component.set("v.canNext", true);
		else
			component.set("v.canNext", false);
    }
	, nextAction: function (component, event, helper) {
		component.set("v.dataResult", component.find("datatable").getSelectedRows());
        component.set("v.canNext", false); 
        component.set("v.canPrevious", true); 
		$A.util.toggleClass(component.find("datatable-container"), "slds-hide");
        $A.util.toggleClass(component.find("datatable-results-container"), "slds-hide");
        component.set("v.listLob", helper.getUniqueLobs(component.get("v.dataResult")));
        helper.validateProducts(component, event, helper);
    }
    , previousAction: function (component, event, helper) {
        component.set("v.canPrevious", false);
        component.set("v.canNext", true); 
        $A.util.toggleClass(component.find("datatable-container"), "slds-hide");
        $A.util.toggleClass(component.find("datatable-results-container"), "slds-hide");
    }
    , updateColumnSorting: function (component, event, helper) {
		var fieldName = event.getParam("fieldName");
		var sortDirection = event.getParam("sortDirection");
		component.set("v.sortedBy", fieldName);
		component.set("v.sortedDirection", sortDirection);
		helper.sortData(component, fieldName, sortDirection);
	}
   
})