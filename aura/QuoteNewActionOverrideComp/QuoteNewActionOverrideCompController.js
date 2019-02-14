({
	goBack: function(component, event, handler) {

		var scope = '';
		if (document.URL.indexOf("SBQQ__Quote__c") > 1)
			scope = "SBQQ__Quote__c";
		if  (document.URL.indexOf("SBQQ__QuoteLine__c") > 1)
			scope = "SBQQ__QuoteLine__c";

		if (scope.length > 0) {
			var homeEvent = $A.get("e.force:navigateToObjectHome");
			homeEvent.setParams({
				"scope": scope
			});
			homeEvent.fire();
		}
	}
})