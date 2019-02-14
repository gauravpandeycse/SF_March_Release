/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Class supporting the SubmitProspectComp.cmp
Inputs:        ID of the triggering Account record	
Test Class:    TestSubmitProspectController	
History	
03/28/2018	   Created class
04/10/2018     SF/JEBU/Implemented SFDP-1512
22/01/2019	   SF/MICO/Including ImcdBusinessUnit__c required prior to Submit the prospect 	(SFDP-2025)
------------------------------------------------------------*/	

public class SubmitProspectController {

	/*------------------------------------------------------------
	Description:   Aura enabled method, invoked from SubmitProspectComp
	Inputs:        ID of the triggering Account record
	Functionality: Get basic data needed for the SubmitProspectComp.
	Return value:  Map of Objects
	History
		05/10/2018	   SF/JEBU/Created Method (part of SFDP-1512) -- refactoring
	------------------------------------------------------------*/
	@AuraEnabled
	public static Map<String, Object> getData (ID recordId) {
		Map <String, Object> data = new Map<String, Object>();
		Account prospect = getProspect(recordId);
		data.put('Id', prospect.Id);
		data.put('Primary_LOB1__c', prospect.Primary_LOB1__c);
		data.put('LockedForIntegration__c', prospect.LockedForIntegration__c);
		data.put('isValidShipping__c', prospect.isValidShipping__c);
        data.put('ImcdBusinessUnit__c', prospect.ImcdBusinessUnit__c);
		data.put('hasActiveIntegration', hasActiveIntegration(recordId));
		data.put('sfManagedAccounts', checkPermission('SfManagedAccounts'));
		return data;
	}

	private static Account getProspect (ID recordId) {
		return ([SELECT Id, Primary_LOB1__c, LockedForIntegration__c, isValidShipping__c, ImcdBusinessUnit__c FROM Account WHERE id = :recordId]);
    }
    
    /*
    * Method checking if there is a record in the IntegrationLog__c indicating an active integration
    */
    @AuraEnabled
	public static Boolean hasActiveIntegration (ID recordId) {
        return ([SELECT Id FROM IntegrationLog__c WHERE Account__c = :recordId AND Status__c IN ('Queued', 'Message Triggered', 'Message Delivered')].size() > 0);
    }
    
    /*------------------------------------------------------------	
	Description:   Aura enabled method, invoked from SubmitProspect.cmp
	Inputs:        ID of the triggering Account record	
	Functionality: Created IntegrationLog__c (transaction) including exception handling
	Return value:  Boolean, true indicating success. 
	History	
	03/30/2018	   Created Method
	------------------------------------------------------------*/	
    @AuraEnabled
	public static Boolean integrateProspect (ID recordId, String integrationId) {
	    if (!checkPermission('SfManagedAccounts')) return createIntegrationLog(recordId);
	    else return convertSoldtoAccount(recordId, integrationId);
    }

	private static Boolean checkPermission(String permission) {
		return FeatureManagement.checkPermission(permission);
	}

	@TestVisible
	private static Boolean convertSoldtoAccount(ID recordId, String integrationId) {
		Account accnt = [SELECT Id, RecordTypeId, IMCDCompany__c FROM Account WHERE Id = :recordId LIMIT 1];
		accnt.RecordTypeId = IMCDUtils.getRecordType(Label.Account_object_Name, Label.Customer_Sold_To_Account_Record_Type).Id;
		accnt.SfManagedAccount__c = true;
		accnt.IntegrationId__c = integrationId;
		accnt.LocalErpId__c = integrationId + '__' + accnt.IMCDCompany__c;

		// Savepoint to rollback
		Savepoint sp = Database.setSavepoint();
		Database.SaveResult srAccnt = Database.update(accnt, false);

		// Error handling
		if (srAccnt.isSuccess())
			return true;
		else {
			Database.rollback(sp);
			logSrError(srAccnt);
			return false;
		}
	}

	@TestVisible
	private static Boolean createIntegrationLog(ID recordId) {
		Boolean result = false;
		String event = IntegrationSettings__c.getInstance(UserInfo.getUserId()).EvtCreateSoldTo__c;
		Account accnt = [SELECT Id, LockedForIntegration__c FROM Account WHERE Id =: recordId LIMIT 1];

		IntegrationLog__c lstIntLog = new IntegrationLog__c (Account__c = recordId, Status__c = 'Queued', Event__c = event);

		// Added for Test coverage, provoke DML exceptions
		if (Test.isRunningTest() && accnt.LockedForIntegration__c == true)
			lstIntLog.Status__c = 'SETTING_UP_FOR_DML_FAILURE';

		accnt.LockedForIntegration__c = true;

		// Savepoint to rollback
		Savepoint sp = Database.setSavepoint();
		Database.SaveResult srInt = Database.insert(lstIntLog, false);
		Database.SaveResult srAccnt = Database.update(accnt, false);

		// Error handling
		if (srInt.isSuccess() && srAccnt.isSuccess()) result = true;
		// Rollback?
		if (!result) Database.rollback(sp); else return result;

		if (!srInt.isSuccess()) logSrError(srInt);
		if (!srAccnt.isSuccess()) logSrError(srAccnt);

		return result;
	}
                              
	private static void logSrError(Database.SaveResult sr) {
		for(Database.Error err : sr.getErrors()) {
			DebugLog.addError('[SubmitProspectController][integrateProspect] An error has occurred.\n'
                              + err.getStatusCode() + ': ' + err.getMessage() + '\n'
                              + 'Fields affected: ' + + err.getFields());
		}                              
	}
 }