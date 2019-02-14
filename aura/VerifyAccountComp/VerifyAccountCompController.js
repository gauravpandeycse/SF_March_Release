({
    init: function (component, event, helper) {
        component.set('v.columns', [{
            label: 'Warning',
            fieldName: "ErrorMessage",
            type: 'text',
            sortable: false,
            cellAttributes: {alignment: 'left'},
            iconName: 'utility:warning'}
        ])
    },
    recordUpdated: function (component, event, helper) {
        var errorMessages = [];
        if (component.get("v.targetFields.Primary_LOB1__c") == null) {
            errorMessages.push({ErrorMessage: "Missing LOB Classification"});
        }
        if (component.get("v.targetFields.isValidShipping__c") == false) {
            errorMessages.push({ErrorMessage: "Missing Main Address"})
        }
        if (component.get("v.targetFields.ImcdBusinessUnit__c") == null) {
            errorMessages.push({ErrorMessage: "Missing Business Unit"})
        }
        component.set("v.data", errorMessages);
    }
})