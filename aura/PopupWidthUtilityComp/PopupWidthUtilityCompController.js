({
	init: function (component, event, helper) {
        setTimeout( function() {
            component.find('notifLib').showNotice({
                "variant": "warning",
                "title": "Spring is in the air",
                "header": "Spring is in the air",
                "message": "We will be releasing the IMCD January '19 release momentarily. This will be completed by noon CET."
            });
        }, 10000);
	}
})