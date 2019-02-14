({
    handleUpdate: function(component, event) {
        component.set('v.startDate', event.getParam('startDate'));
        component.set('v.endDate', event.getParam('endDate'));
    }
})