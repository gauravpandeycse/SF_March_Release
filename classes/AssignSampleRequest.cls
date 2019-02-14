/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
Description:   Invocable method (for Flow / Process Builder)
Inputs:        Case ID
Test Class:    TestAssignSampleRequest
History
	16/11/2018 Created class
------------------------------------------------------------*/
global with sharing class AssignSampleRequest {

	// defines input variable which can be passed by the process builder.
	global class AssignSampleRequestRequest {
		@InvocableVariable (required=true)
		global List<Case> lstCase;
	}

	// defines output variables
	global class AssignSampleRequestResult {
		@InvocableVariable (required=false)
		global Boolean success;

		@InvocableVariable (required=false)
		global String error;
	}

	// Bulkified Invocable method
	@InvocableMethod ( label='Assign Sample Request' description='Assigns Sample Stores to Sample Requests' )
	global static List<AssignSampleRequestResult> assignSampleRequest ( List<AssignSampleRequestRequest> requests ) {

		IMCDUtils.debugLimits('[AssignSampleRequest][assignSampleRequest] entry');

		// Merge and handle all requests through a single set
		Set<Id> setCaseId = new Set<Id>();

		// Retrieve all Case Ids (consider potential bulkification)
		for (AssignSampleRequestRequest request : requests) {
			for (Case thisCase : request.lstCase) {
				setCaseId.add(thisCase.Id);
			}
		}

		List<Case> lstCaseToAssign = New List<Case>([SELECT Id
															, QuoteLine__r.SBQQ__Product__r.CompanySampleStore__c
															, QuoteLine__r.SBQQ__Product__r.CentralSampleStore__c
															, toLabel(Account.IMCDCompany__c) // SFDC/JEBU/04-DEC-18
															, QuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__r.ImcdCompany__c
															, AssignedSampleStore__c
													 FROM Case WHERE Id IN :setCaseId]);

		for (Case caseToAssign : lstCaseToAssign) {

			// Sample Stores are assigned based on values associated to the product2 (Company Sample Store and Central Sample Store fields)
			// If the company sample store is populated, the code checks if this current Quote is issued for a company defined in the CompanySampleStore__c field
			// If the company sample store is empty, then the case is assigned with the sample store that is defined in the Central Sample Store
			// If the company sample store and central sample store is not defined - the defaulSampleStore__c defined in the running users profile is assigned
			String companySampleStore = caseToAssign.QuoteLine__r.SBQQ__Product__r.CompanySampleStore__c;
			String centralSampleStore = caseToAssign.QuoteLine__r.SBQQ__Product__r.CentralSampleStore__c;
			String imcdCompanyLabel = caseToAssign.Account.ImcdCompany__c; // retrieved using toLabel() in SOQL
			String imcdCompany = caseToAssign.QuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__r.ImcdCompany__c;

			if (!String.isBlank(companySampleStore)) {
				caseToAssign.AssignedSampleStore__c = getSampleStoreForIMCDCompany(imcdCompany, companySampleStore); // use the imcdCompany API value
			}
			else if (!String.isBlank(centralSampleStore)
					&& String.isBlank(companySampleStore)) {
				caseToAssign.AssignedSampleStore__c = centralSampleStore;
			}
			else if (String.isBlank(centralSampleStore)
					&& String.isBlank(companySampleStore)) {
				caseToAssign.AssignedSampleStore__c = getUserDefaultSampleRegion();
			}

			// If the case record is not assigned a sample store - this means a sample store for the values defined in the CompanySampleStore__c was not found
			// In this case - The Central Sample Store will need to be assigned to the Case
			if (!String.isBlank(companySampleStore)
					&& !String.isBlank(centralSampleStore)
					&& String.isBlank(caseToAssign.AssignedSampleStore__c)) {
				caseToAssign.AssignedSampleStore__c = centralSampleStore;
			}

			// If the case record is still not assigned a sample store - this means a sample store is not defined in the product at the central level
			// In this case - The User Default Sample Store
			if (!String.isBlank(companySampleStore)
					&& String.isBlank(centralSampleStore)
					&& String.isBlank(caseToAssign.AssignedSampleStore__c)) {
				caseToAssign.AssignedSampleStore__c = getUserDefaultSampleRegion();
			}

			// Assign to a queue (void) - errors written to debuglog if any.
			assignToCorrectQueue(caseToAssign);

		}

		// Create list of return objects
		// We merged all request objects, but have to return same number of result objects
		// If any DML error, return same error for all requests (bulkified scenario only)
		List<AssignSampleRequestResult> RequestResults = new List<AssignSampleRequestResult>();
		AssignSampleRequestResult RequestResult = new AssignSampleRequestResult();
		RequestResult.success = true;
		RequestResult.error = '';

		try {
			update lstCaseToAssign;
		} catch (dmlException exc) {
			DebugLog.addException(exc, '[AssignSampleRequest][assignSampleRequest]');
			RequestResult.success = false;
			RequestResult.error = exc.getStackTraceString();
		}

		for (Integer index=0; index < Requests.size(); index++) {
			RequestResults.add(RequestResult);
		}

		IMCDUtils.debugLimits('[AssignSampleRequest][assignSampleRequest] exit');
		return RequestResults;
	}

	//Based on comment above for getSampleStoreForIMCDCompany, return the Sample Store based on the company of the QuoteRecord
	private static String regionToAssign(String imcdCompany, List<String> companySampleStores){
		Map<String, String> companySampleStoreMap = new Map<String, String>();// Will hold the IMCDCompany and IMCD Sample Store
		List<String> splitStringList;
		for(String eachCompanySampleStore : companySampleStores){
			splitStringList = eachCompanySampleStore.split('_');
			companySampleStoreMap = addTOMap(splitStringList,companySampleStoreMap);
		}
		return companySampleStoreMap.get(imcdCompany); //using the imcdCompany as API value
	}

	//Return the default Sample Store that is assigned on the user profile
	private static String getUserDefaultSampleRegion(){
		String defaultSampleStore = '';
		List<User> userRecord = [SELECT DefaultSampleStore__c FROM User WHERE Id =: UserInfo.getUserId()];
		if(userRecord.size() > 0) {
			defaultSampleStore = userRecord[0].DefaultSampleStore__c;
		}
		return defaultSampleStore;
	}

	//CompanySampleStore__c field on product2 uses the format 111000_IMCD France,112200_IMCD India
	//Format Definition - Seperated by comma, each value before the '_' is the originating company, the value after is the Sample Store from which the sample is issued
	//E.g. - IF current quoteLine record is for company 111000, then the sample store should be IMCD France
	//This method splits the CSV and assigns them to a list
	@TestVisible
	private static String getSampleStoreForIMCDCompany(String imcdCompany ,String sampleStoreMapping){
		List<String> companySampleStores = new List<String>();
		companySampleStores = sampleStoreMapping.split(',');
		return regionToAssign(imcdCompany, companySampleStores); // use the imcdCompany as API value here
	}

	private static Map<String, String> addToMap(List<String> companySampleStoreList,Map<String, String> companySampleStoreMap){
		companySampleStoreMap.put(companySampleStoreList[0],companySampleStoreList[1]);
		return companySampleStoreMap;
	}

	//Route the created case to the correct queue
	//The queue is determined based on the AssignedSampleStore__c field that is set perviously
	//The mapping between AssignedSampleStore__c <-> Queue is maintained in the Custom Metadata Company_Country_Queue_Mapping__mdt
	private static void assignToCorrectQueue(Case caseRecord) {
		Boolean success = true;
		Map<String, String> countryQueueMappings = getCountryQueueMappings();
		String errorMessage = '';
		String queueName = '';

		//If the AssignedSampleStore__c value is 'Direct From Supplier' then before searching for the queue name, the IMCDCompany related to the Quote is prefixed.
		if(!(String.isBlank(caseRecord.AssignedSampleStore__c)) && caseRecord.AssignedSampleStore__c.trim().equalsIgnoreCase(Label.DirectFromSupplier)){
			queueName = caseRecord.Account.IMCDCompany__c + ' '; //IMCDCompany__c is retrieved using ToLabel.
			queueName = countryQueueMappings.get(queueName + caseRecord.AssignedSampleStore__c);
		}else {
			queueName = countryQueueMappings.get(caseRecord.AssignedSampleStore__c);
		}

		caseRecord.ownerId = IMCDUtils.getQueueId(queueName); //try to assign

		// If case queue is not found -> then fall back to System Admin Queue
		// Just log the error to the debug log only.
		if(String.isBlank(caseRecord.ownerId)){
			success = false;
			caseRecord.ownerId = getDefaultSystemAdminQueue();
			errorMessage += Label.CouldNotFindQueue + ' Case record Id : ' + caseRecord.Id + '\n';
			errorMessage += 'Product Central Sample Store : ' + caseRecord.QuoteLine__r.SBQQ__Product__r.CompanySampleStore__c + '\n';
			errorMessage += 'Product Company Sample Store : ' + caseRecord.QuoteLine__r.SBQQ__Product__r.CentralSampleStore__c + '\n';
			errorMessage += 'Quote IMCD Company Lookup : ' + caseRecord.QuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__r.ImcdCompany__c + '\n';
			errorMessage += 'User Default Sample Store : ' + getUserDefaultSampleRegion();
			logError('[AssignSampleRequest][assignToCorrectQueue]', errorMessage);
		}
	}

	//Returns the IMCD Sample Store <-> Queue Name mappings - used to determine which queue the created sample request needs to be assigned too
	private static Map<String, String> getCountryQueueMappings(){
		Map<String, String> countryQueueMappings = new Map<String, String>();
		for(Company_Country_Queue_Mapping__mdt eachCountryMappingRecord : [SELECT MasterLabel, QueueName__c FROM Company_Country_Queue_Mapping__mdt]){
			countryQueueMappings.put(eachCountryMappingRecord.MasterLabel, eachCountryMappingRecord.QueueName__c);
		}
		return countryQueueMappings;
	}

	//Returns the system admin queue - used if a suitable queue is not found
	private static String getDefaultSystemAdminQueue() {
		Id sysAdminQueueId = IMCDUtils.getQueueId(Label.SystemAdminQueueName);
		if (Test.isRunningTest()) sysAdminQueueId = IMCDUtils.getQueueId(Label.TestSystemAdminQueueName);
		return sysAdminQueueId;
	}

	private static void logError(String errorOrigin, String errorMessage){
		DebugLog.addError(errorOrigin + ' ' + errorMessage);
	}


}