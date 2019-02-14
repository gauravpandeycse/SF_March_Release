({
	init: function(component, event, helper)  {
		var inputfield = component.find("lightning-input");
		inputfield.set("v.value", component.get("v.value"));
	}
})