/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
Description:   Generic class to return Async Job queries
Inputs:
Test Class:    TestAsyncJobCompController
History
	241/09/2018 Created class
------------------------------------------------------------*/

public with sharing class AsyncJobCompController {

	/**
	* @description  returns aggreated result set of Sharing related Async jobs
	* @return       list of Async jobs
	*/
	@auraEnabled
	public static List<aggregateResult> getSharingJobs () {
		return ([SELECT
					ApexClass.Name ApexClassName, Status, Count(Id) NumJobs, MIN (CreatedDate) OldestJobDt
				 FROM AsyncApexJob
					WHERE ApexClass.Name LIKE '%Sharing'
					GROUP BY ApexClass.Name, Status]);
	}
}