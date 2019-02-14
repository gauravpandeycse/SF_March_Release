({
    init: function (component, event, helper) {
        var action = component.get("c.getFollowupReportSummary");
        action.setParams({"quoteLineId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.followupReportSummary", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
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