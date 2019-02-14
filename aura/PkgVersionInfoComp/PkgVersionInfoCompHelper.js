({
	init: function (component, event, helper) {
		var action = component.get("c.getPackageInfo");
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
			}
		});
		$A.enqueueAction(action);

		component.set('v.columns', [
			{label: 'Name', fieldName: 'Name', type: 'text',sortable: false},
			{label: 'Namespace Prefix', fieldName: 'NamespacePrefix', type: 'text',sortable:false},
			{label: 'Major Version', fieldName: 'MajorVersion', type: 'number', sortable:false, cellAttributes: {alignment: 'left'}},
			{label: 'Minor Version', fieldName: 'MinorVersion', type: 'number', sortable:false, cellAttributes: {alignment: 'left'}}
		]);
	}
})