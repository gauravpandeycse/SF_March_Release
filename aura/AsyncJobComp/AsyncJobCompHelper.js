({
	init: function (component, event, helper) {

		var action = component.get("c.getSharingJobs");
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				component.set("v.data", response.getReturnValue());
			}
		});
		$A.enqueueAction(action);

		component.set('v.columns', [
			{label: 'Sharing Class', fieldName: 'ApexClassName', type: 'text',sortable: true},
			{label: 'Status', fieldName: 'Status', type: 'text',sortable:false},
			{label: 'Oldest Job Date', fieldName: 'OldestJobDt', type: 'text', sortable:false},
			{label: 'Number of jobs', fieldName: 'NumJobs', type: 'number', sortable:false, cellAttributes: {alignment: 'left'}}
		]);
	}
})