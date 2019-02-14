({
	init: function (component, event, helper) {
		// If feature isn't enabled per custom permission exit the init
		var promise = this.isEnabled(component, event, helper);
		var self = this;

		/* First check if manual renewal is enabled for this user*/
		promise.then(function (component, event, helper) {
			if (!component.get("v.isFeatureEnabled")) {
				$A.util.toggleClass(component.find("datatable-container"), "slds-hide");
				$A.util.toggleClass(component.find("featureDisabled-container"), "slds-hide");
				return;
			}
			/* If enabled continue with init of the component */
			self.setupComponent(component, event, helper);
		});
	}
    , setupComponent: function (component, event, helper) {
		component.set("v.maxSelection", parseInt($A.get("$Label.c.IMCD_LC_ManualRenewalMaxSelection")));
		// Get the renewable contracted prices/products
		var action = component.get("c.getContractedPrices");
		action.setParams({"accountId": component.get("v.recordId")});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				component.set("v.data", this.flattenQueryResult(response.getReturnValue()));
				this.sortData (component, "SBQQ__Product__r_Name", "asc");
			}
		});
		$A.enqueueAction(action);

        component.set('v.columns', [
            {label: 'Product', fieldName: 'SBQQ__Product__r_Name', type: 'text',sortable: true, initialWidth: 300},
            {label: 'Quantity', fieldName: 'Quantity__c', type: 'number',sortable:false, cellAttributes: {alignment: 'left'}},
            {label: 'UoM', fieldName: 'UOM__c', type: 'text', sortable:false},
            {label: 'Incoterms', fieldName: 'Incoterms__c', type: 'text', sortable:false},
            {label: 'LOB', fieldName: 'SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB1__c', type: 'text', sortable:false},
            {label: 'Validity from', fieldName: 'SBQQ__EffectiveDate__c', type: 'text', sortable:false},
            {label: 'Validity to', fieldName: 'SBQQ__ExpirationDate__c', type: 'text', sortable:false},
            {label: 'Ship to', fieldName: 'SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_ShiptoAddress__r_Name', type: 'text', sortable: false},
            {label: 'Price restriction', fieldName: 'SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_PriceRestriction__c', type: 'text', sortable: false}
        ]);

        component.set('v.columnsResult', [
            {label: 'Product', fieldName: 'SBQQ__Product__r_Name', type: 'text', sortable:false},
            {label: 'Quantity', fieldName: 'Quantity__c', type: 'number',sortable:false, cellAttributes: {alignment: 'left'}, initialWidth: 100},
            {label: 'UoM', fieldName: 'UOM__c', type: 'text', sortable:false, initialWidth: 100},
            {label: 'Validation errors', fieldName: 'ValidationErrors__c', type: 'text', sortable: false, initialWidth: 500}
        ]);
    }
	, validateInput: function (component, event, helper) {
		var validityFrom = component.find("validityFrom");
		var validityTo = component.find("validityTo");
		var quoteExpiration = component.find("quoteExpiration");
		var lob = component.find("lob");

		if (validityFrom.get("v.value") > validityTo.get("v.value")) {
			validityFrom.setCustomValidity($A.get('$Label.c.IMCD_LC_MSG_ValidityDtValidation'));
			validityTo.setCustomValidity($A.get('$Label.c.IMCD_LC_MSG_ValidityDtValidation'));
		}
		else {
			validityFrom.setCustomValidity('');
			validityTo.setCustomValidity('');
		}

		if (new Date(quoteExpiration.get("v.value")) <= new Date())
			quoteExpiration.setCustomValidity($A.get('$Label.c.IMCD_LC_MSG_ExpirationDtValidation'));
		else
			quoteExpiration.setCustomValidity('');

		if (validityFrom.reportValidity() &&
			validityTo.reportValidity() &&
			quoteExpiration.reportValidity() &&
			lob.get("v.validity").valid)
			component.set("v.formValid", true);
		else
			component.set("v.formValid", false);
	}
	, validateProducts: function (component, event, helper) {
		var action = component.get("c.validateRenewalProducts");
		// Validate whether the selected products are valid for renewal
		action.setParams({
			"lstProducts": component.get("v.dataResult")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var dataResult = this.flattenQueryResult(response.getReturnValue());
				component.set("v.dataResult", dataResult);
				component.set("v.hasValidationErrors", false); //reset

				for (var index = 0; index < dataResult.length; index++)
					if (dataResult[index].hasOwnProperty("ValidationErrors__c")) component.set("v.hasValidationErrors", true); // in case of error
			}
		});

		$A.enqueueAction(action);
	}
	, createRenewalAction: function (component, event, helper) {
		var action = component.get("c.createRenewalQuote");
		// Clone the Opportunity quote and its line items

		var quoteExpirationJson = new Date(component.find("quoteExpiration").get("v.value")).toJSON();
		var validityToJson = new Date(component.find("validityTo").get("v.value")).toJSON();
		var validityFromJson = new Date(component.find("validityFrom").get("v.value")).toJSON();
		var lobId = component.find("lob").get("v.value"); // this is an SBQQ__ContractedPrice__c Id from which the LOB1/2/3 should be retrieved

		action.setParams({
			"lstProducts": component.get("v.dataResult")
			, "quoteExpirationJson": quoteExpirationJson
			, "validityToJson": validityToJson
			, "validityFromJson": validityFromJson
			, "lobId": lobId
		});

		action.setCallback(this, function (response) {
			let state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var result = response.getReturnValue(); // it should return the Renewal quote Id. If empty, an error occurred

				if (result != null) {
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"title": 'Results',
						"message": $A.get('$Label.c.IMCD_LC_MSG_RenewalQuoteSuccess'),
						"type": 'success',
						"mode": 'dismissible'
					});

					toastEvent.fire();

					$A.get("e.force:closeQuickAction").fire();
					var navEvt = $A.get("e.force:navigateToSObject");
					navEvt.setParams({
						"recordId": result
						, "slideDevName": "detail"
					});
					navEvt.fire();
				}
				else {
					this.showNotification(component, "error", "Error"
						, $A.get("$Label.c.IMCD_LC_MSG_RenewalQuoteError"));
				}
			}

		});
		$A.enqueueAction(action);
	}
	, flattenObject: function (propName, obj) {
		var flatObject = [];

		for (var prop in obj) {
			//if this property is an object, we need to flatten again
			var propIsNumber = isNaN(propName);
			var preAppend = propIsNumber ? propName + '_' : '';
			if (typeof obj[prop] == 'object') {
				flatObject[preAppend + prop] = Object.assign(flatObject, this.flattenObject(preAppend + prop, obj[prop]));
			}
			else {
				flatObject[preAppend + prop] = obj[prop];
			}
		}
		return flatObject;
	}
	, flattenQueryResult: function (listOfObjects) {

		for (var i = 0; i < listOfObjects.length; i++) {
			var obj = listOfObjects[i];

			for (var prop in obj) {
				if (!obj.hasOwnProperty(prop)) continue;

				if (typeof obj[prop] == 'object' && typeof obj[prop] != 'Array') {
					obj = Object.assign(obj, this.flattenObject(prop, obj[prop]));
				}
				else if (typeof obj[prop] == 'Array') {
					for (var j = 0; j < obj[prop].length; j++) {
						obj[prop + '_' + j] = Object.assign(obj, this.flattenObject(prop, obj[prop]));
					}
				}
			}
		}
		return listOfObjects;
	}
	, showNotification: function (component, variant, header, message) {
		component.find('notifLib').showNotice({
			"variant": variant,
			"header": header,
			"message": message,
			closeCallback: function () {
			}
		});
	}
	, format: function (string) {
		var outerArguments = arguments;
		return string.replace(/\{(\d+)\}/g, function () {
			return outerArguments[parseInt(arguments[1]) + 1];
		});
	}
	, isEnabled: function (component, event, helper) {
		return new Promise(function (resolve, reject) {
			var action = component.get("c.isFeatureEnabled");
			action.setCallback(this, function (response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					component.set("v.isFeatureEnabled", response.getReturnValue());
					resolve(component, event, helper);
				}
			});
			$A.enqueueAction(action);
		});
	}
	, getUniqueLobs: function (lstObjects) {
		var lstLobs = [];
		var lob1, lob2 = '';
		var exists;

		for (var index1 = 0; index1 < lstObjects.length; index1++) {
			try {
				lob1 = lstObjects[index1].SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB1__c +
					lstObjects[index1].SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB2__c +
					lstObjects[index1].SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB3__c;

				exists = false;

				for (var index2 = 0; lstLobs.length; index2++) {
					lob2 = lstLobs[index2].SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB1__c +
						lstLobs[index2].SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB2__c +
						lstLobs[index2].SBQQ__OriginalQuoteLine__r_SBQQ__Quote__r_LOB3__c;

					if (lob1 === lob2)
						exists = true;
				}

				if (!exists) lstLobs.push(lstObjects[index1]);
			} catch (ex) {
				console.log(ex);
			}
		}

		return (lstLobs);
	}
	, sortData: function (component, fieldName, sortDirection) {
		var data = component.get("v.data");
		var reverse = sortDirection !== 'asc';
		data.sort(this.sortBy(fieldName, reverse))
		component.set("v.data", data);
	}
	, sortBy: function (field, reverse, primer) {
		var key = primer ?
			function(x) {return primer(x[field])} :
			function(x) {return x[field]};
		//checks if the two rows should switch places
		reverse = !reverse ? 1 : -1;
		return function (a, b) {
			return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
		}
	}
})