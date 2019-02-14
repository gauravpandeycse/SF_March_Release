({
	showSuccessToast : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : '',
            message: 'The case is successfully assigned',
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    showErrorToast : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : '',
            message: 'An error has occurred updating Case.',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
})