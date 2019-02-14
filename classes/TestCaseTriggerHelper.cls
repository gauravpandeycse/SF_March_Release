/******************************************************************************************************************************************************************
 * Author: NC
 * Company: Salesforce
 * Description: Tests for CaseTriggerHelper
 * History :
 ******************************************************************************************************************************************************************/
@IsTest
public class TestCaseTriggerHelper {
    @testSetup static void setup(){
		Global_Bypass_Processes_Settings__c cs = TestDataFactory.createBypassCustomSetting();
        /*Creating 2 distinct random IMCD company values */
        String imcdCompanyTestValue;
        do {
            imcdCompanyTestValue = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        } while (imcdCompanyTestValue.indexOf('0') < 3);
        String imcdCompanyTestValue2;
        do {
            imcdCompanyTestValue2 = TestDataFactoryUtils.getRandomPickListValue(new Account(), Label.IMCDCompany_Field_Name);
        } while (imcdCompanyTestValue2.equals(imcdCompanyTestValue) || imcdCompanyTestValue2.indexOf('0') < 3);
        List<String> imcdCompaniesForTest = new List<String>{imcdCompanyTestValue,imcdCompanyTestValue2};
		TestDataFactory.createImcdCompanies(imcdCompaniesForTest);
        System.DEBUG(imcdCompaniesForTest);
    }
    
    @isTest
    public static void isIMCDCompanyLookupSet_onInsert(){
        String imcdCompanyTestValue ;
        List<IMCDCompany__c> existingCompanies = [SELECT ID, Name, IMCDCompany__c FROM IMCDCompany__c];
        imcdCompanyTestValue = existingCompanies[0].IMCDCompany__c;
        
        Case caseToInsert = new Case(IMCDCompany__c = imcdCompanyTestValue);
        
        Test.startTest();
        	insert caseToInsert;
        Test.stopTest();
        
        System.assertEquals(imcdCompanyTestValue, [SELECT IMCDCompanyLookup__r.ImcdCompany__c FROM Case where Id =: caseToInsert.Id][0].IMCDCompanyLookup__r.ImcdCompany__c);
		
    }
    
    @isTest
    public static void isIMCDCompanyLookupSet_onUpdate(){
        String imcdCompanyTestValue ;
        List<IMCDCompany__c> existingCompanies = [SELECT ID, Name, IMCDCompany__c FROM IMCDCompany__c];
        System.debug(existingCompanies);
        imcdCompanyTestValue = existingCompanies[0].IMCDCompany__c;
        String imcdCompanyTestValueToChangeToo = existingCompanies[1].IMCDCompany__c;
        Case caseToInsert = new Case(IMCDCompany__c = imcdCompanyTestValue);
        insert caseToInsert;
        Test.startTest();
        	caseToInsert.IMCDCompany__c = imcdCompanyTestValueToChangeToo;
        	update caseToInsert;
        Test.stopTest();
        
        System.assertEquals(imcdCompanyTestValueToChangeToo, [SELECT IMCDCompanyLookup__r.ImcdCompany__c FROM Case where Id =: caseToInsert.Id][0].IMCDCompanyLookup__r.ImcdCompany__c);
		
    }
}