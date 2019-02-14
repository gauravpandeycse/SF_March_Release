({
	searchAction: function (component, helper, event) {
		var displaySections     = component.find("displaySections").get("v.value");
		var primaryLob1         = component.find("primaryLob1").get("v.value");
		var keyOpportunity      = component.find("keyOpportunity").get("v.checked");
		var principalId         = component.find("principal").get("v.selectedRecordId");
		var productId           = component.find("product").get("v.selectedRecordId");
		var startDt             = component.find("startDt").get("v.value");
		var endDt               = component.find("endDt").get("v.value");
		var startDtTime         = startDt + 'T00:00:00.000Z'; // for date-time fields
		var endDtTime           = endDt + 'T23:59:59.999Z'; // for date-time fields

		// List of filter variables. Reservered 10 per Object for future use
		// filter10-19 --> Opportunity based queries
		// filter20-29 --> SBQQ__QuoteLine__c based queries
		// filter30-39 --> Sample request (Case) based queries
		// filter40-39 --> NCR (Case) based queries
		// filter50-59 --> Visit Report (VisitReport__) queries
		// filter60-69 --> SBQQ__QuoteLine__c (Renewal and Single) based queries
		// filter70-79 --> Technical request queries (Case)
		// filter80-89 --> Contracted Price queries (SBQQ__ContractedPrice__c)
		// filter90-99 --> Sales Order Line queries (SalesOrderLine__c)

		var filter10 = "CloseDate < TODAY AND Cold_Opportunity__c = false AND isClosed = false";
		var filter11 = "isClosed = false AND Cold_Opportunity__c = false";
		var filter20 = "RecordType.DeveloperName = 'OpportunityQuoteLine' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Cold_Opportunity__c = false";
		var filter30 = "RecordType.DeveloperName = 'Sample_Request'";
		var filter40 = "RecordType.DeveloperName = 'Non_Conformance_Report'";
		var filter50 = "Id <> null";
		var filter60 = "RecordType.DeveloperName IN ('RenewalQuote','SingleQuote')";
		var filter70 = "RecordType.DeveloperName = 'Technical_Request' AND Status <> 'Closed'";
		var filter71 = "RecordType.DeveloperName = 'Technical_Request' AND Status = 'Closed'";
		var filter80 = "Id <> null";
		var filter90 = "Id <> null";

		if (keyOpportunity) {
			filter10 += " AND Key_Opportunity__c = true";
			filter11 += " AND Key_Opportunity__c = true";
			filter20 += " AND KeyOpportunity__c = true";
			filter30 += " AND QuoteLine__r.KeyOpportunity__c = true";
			filter70 += " AND RelatedOpportunity__r.Key_Opportunity__c = true";
			filter71 += " AND RelatedOpportunity__r.Key_Opportunity__c = true";
		}

		if (primaryLob1) {
			filter10 += " AND LOB1__c = '" + primaryLob1 + "'";
			filter11 += " AND LOB1__c = '" + primaryLob1 + "'";
			filter20 += " AND SBQQ__Quote__r.LOB1__c = '" + primaryLob1 + "'";
			filter30 += " AND QuoteLine__r.SBQQ__Quote__r.LOB1__c = '" + primaryLob1 + "'";
			filter60 += " AND LOB1__c = '" + primaryLob1 + "'";
			filter70 += " AND LOB1__c = '" + primaryLob1 + "'";
			filter71 += " AND LOB1__c = '" + primaryLob1 + "'";
		}

		if (startDt) {
			filter10 += " AND CloseDate >= " + startDt;
			filter11 += " AND CloseDate >= " + startDt;
			filter20 += " AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate >= " + startDt;
			filter30 += " AND CreatedDate >= " + startDtTime;
			filter40 += " AND CreatedDate >= " + startDtTime;
			filter50 += " AND Visit_Date__c >= " + startDt;
			filter60 += " AND QuoteExpirationDate__c >= " + startDt;
			filter70 += " AND DueDate__c >= " + startDt;
			filter71 += " AND ClosedDate >= " + startDtTime;
			filter80 += " AND SBQQ__EffectiveDate__c >= " + startDt;
			filter90 += " AND OrderDate__c >= " + startDt;
		}

		if (endDt) {
			filter10 += " AND CloseDate <= " + endDt;
			filter11 += " AND CloseDate <= " + endDt;
			filter20 += " AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate <= " + endDt;
			filter30 += " AND CreatedDate <= " + endDtTime;
			filter40 += " AND CreatedDate <= " + endDtTime;
			filter50 += " AND Visit_Date__c <= " + endDt;
			filter60 += " AND QuoteExpirationDate__c <= " + endDt;
			filter70 += " AND DueDate__c <= " + endDt;
			filter71 += " AND ClosedDate <= " + endDtTime;
			filter80 += " AND SBQQ__ExpirationDate__c <= " + endDt;
			filter90 += " AND OrderDate__c <= " + endDt;
		}

		if (principalId) {
			filter20 += " AND SBQQ__Product__r.Principal__c = '" + principalId + "'";
			filter30 += " AND QuoteLine__r.SBQQ__Product__r.Principal__c = '" + principalId + "'";
			filter40 += " AND CaseOrderLinePrincipalId__c = '" + principalId + "'";
			filter80 += " AND SBQQ__Product__r.Principal__c = '" + principalId + "'";
			filter90 += " AND Product__r.Principal__c = '" + principalId + "'";
		}

		if (productId) {
			filter20 += " AND SBQQ__Product__c = '" + productId + "'";
			filter30 += " AND QuoteLine__r.SBQQ__Product__c = '" + productId + "'";
			filter40 += " AND CaseOrderLineProductId__c = '" + productId + "'";
			filter80 += " AND SBQQ__Product__c = '" + productId + "'";
			filter90 += " AND Product__c = '" + productId + "'";
		}

		console.log ('filter10 = ' + filter10);
		console.log ('filter11 = ' + filter11);
		console.log ('filter20 = ' + filter20);
		console.log ('filter30 = ' + filter30);
		console.log ('filter40 = ' + filter40);
		console.log ('filter50 = ' + filter50);
		console.log ('filter60 = ' + filter60);
		console.log ('filter70 = ' + filter70);
		console.log ('filter71 = ' + filter71);
		console.log ('filter80 = ' + filter80);
		console.log ('filter90 = ' + filter90);

		component.set("v.oppty", false);
		component.set("v.opptyQuote", false);
		component.set("v.custQuote", false);
		component.set("v.contractedPrice", false);
		component.set("v.soLine", false);
		component.set("v.visitReport", false);
		component.set("v.sampleRequest", false);
		component.set("v.technicalRequest", false);
		component.set("v.ncr", false);

		component.set("v.filter10", filter10);
		component.set("v.filter11", filter11);
		component.set("v.filter20", filter20);
		component.set("v.filter30", filter30);
		component.set("v.filter40", filter40);
		component.set("v.filter50", filter50);
		component.set("v.filter60", filter60);
		component.set("v.filter70", filter70);
		component.set("v.filter71", filter71);
		component.set("v.filter80", filter80);
		component.set("v.filter90", filter90);

		component.set("v.oppty", displaySections.includes("oppty"));
		component.set("v.opptyQuote", displaySections.includes("opptyQuote"));
		component.set("v.custQuote", displaySections.includes("custQuote"));
		component.set("v.contractedPrice", displaySections.includes("contractedPrice"));
		component.set("v.soLine", displaySections.includes("soLine"));
		component.set("v.visitReport", displaySections.includes("visitReport"));
		component.set("v.sampleRequest", displaySections.includes("sampleRequest"));
		component.set("v.technicalRequest", displaySections.includes("technicalRequest"));
		component.set("v.ncr", displaySections.includes("ncr"));

	}
	, printPageAction: function(component, event, helper) {
		var url = location.origin + '/apex/AccountSummary?id=' + component.get("v.recordId");
		window.open(url, '_blank');

	}
	, printAction: function(component, event, helper) {
		window.print();
	}
})