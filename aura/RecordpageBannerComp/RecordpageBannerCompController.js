({
	showBannerEvent: function(component, event, helper) {
		component.set("v.title", event.getParam("title"));
		component.set("v.subtitle", event.getParam("subtitle"));
		component.set("v.showBanner", event.getParam("showbanner"));
	}
})