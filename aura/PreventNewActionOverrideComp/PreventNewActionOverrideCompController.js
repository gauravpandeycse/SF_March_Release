({
	goBack: function(component, event, handler) {

		var scope = document.location.pathname;
		scope = scope.substr(13);
		scope = scope.substr(0, scope.indexOf("/"));

		if (scope.length > 0) {
			var homeEvent = $A.get("e.force:navigateToObjectHome");
			homeEvent.setParams({
				"scope": scope
			});
			homeEvent.fire();
		}
	}
})