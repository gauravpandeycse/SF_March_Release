public class CaseTriggerHelper {
	/*
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Creates a look up relationship to ImcdCompany object based on the IMCD Company value set on the user profile.
    * Inputs : List<Case>
    * Test Class : TestCaseTrigerHelper.isIMCDLookupSetOnCaseForInsertandUpdate()
    * History :
    */
    public static void setIMCDCompanyLookup(List<Case> newCaseList){
        Map<String, Id> IMCDCompaniesMap = new Map<String, Id>();
        Set<String> IMCDCompanies = new Set<String>();
        for(Case eachCaseLine : newCaseList){
            IMCDCompanies.add(eachCaseLine.ImcdCompany__c);
        }
        for(IMCDCompany__c eachCompany : [SELECT ID, ImcdCompany__c FROM IMCDCompany__c WHERE ImcdCompany__c in: IMCDCompanies]){
            IMCDCompaniesMap.put(eachCompany.ImcdCompany__c, eachCompany.Id);
        }
        System.DEBUG('Companies Map : ' + IMCDCompaniesMap);
        for(Case eachCaseRecord : newCaseList){
            if(!(String.isBlank(eachCaseRecord.IMCDCompany__c))){
                if(!(String.isBlank(IMCDCompaniesMap.get(eachCaseRecord.ImcdCompany__c)))){
                    eachCaseRecord.ImcdCompanyLookup__c = IMCDCompaniesMap.get(eachCaseRecord.ImcdCompany__c);    
                }else{
                    DebugLog.addError('[CaseTriggerHelper][setIMCDCompanyLookup] Unable to find corresponding IMCD Company record for Case :' + eachCaseRecord.Id);
                    eachCaseRecord.ImcdCompanyLookup__c.addError('[CaseTriggerHelper][setIMCDCompanyLookup] Unable to find corresponding IMCD Company record for IMCD Company :' + eachCaseRecord.ImcdCompany__c);
                }
            }
        }
    }
}