@isTest
public class TestDataFactoryUtils {
    
    // Org-wide controller for triggers
    public static void runTriggers (Boolean enabledState) {
    	Global_Bypass_Processes_Settings__c  setting = Global_Bypass_Processes_Settings__c.getOrgDefaults();
		setting.Run_Triggers__c = enabledState;
		upsert setting;
    }
    
	// Org-wide controller for Process builders
    public static void runProcessBuilders (Boolean enabledState) {
    	Global_Bypass_Processes_Settings__c  setting = Global_Bypass_Processes_Settings__c.getOrgDefaults();
		setting.Run_Process_Builder__c = enabledState;
		upsert setting;
    }

	// Org-wide controller for Validation rules
	public static void runValidationRules (Boolean enabledState) {
		Global_Bypass_Processes_Settings__c  setting = Global_Bypass_Processes_Settings__c.getOrgDefaults();
		setting.Run_Validation_Rules__c = enabledState;
		upsert setting;
	}
    
    // Object-specific bypasses, enabledBypasses contains comma-seperate sObject list. 
	public static void triggerObjectBypass (String enabledBypasses) {
    	Global_Bypass_Processes_Settings__c  setting = Global_Bypass_Processes_Settings__c.getOrgDefaults();
		setting.Trigger_Objects_Bypass__c  = (String.isBlank(enabledBypasses) ? '' : enabledBypasses);
		upsert setting;
    }
    
    //returns a random Integer
	public static Integer getRandomNumber(Integer size) {
		Double d = math.random() * size;
		return d.intValue();
	}
    
    //Return a random string from a list of strings
    public static String getRandomString(List<String> strings) {
		List<Double> ranks = new List<Double>();
		Map<Double, String> rankMap = new Map<Double,String>();

		for (String s : strings) {
			Boolean isDup = true;
			Double rank;

			while (isDup) {
				Double x = getRandomNumber(100000);
				if(!rankMap.containsKey(x)) {
					rank = x;
					isDup = false;
				}
			}

			ranks.add(rank);
			rankMap.put(rank,s);
		}

		ranks.sort();
		return rankMap.get(ranks.get(0));
     } 
    
    //Returns a random picklist value 
     public static string getRandomPickListValue(SObject obj, String fieldName){
		List<String> Strings = new List<String>();
		Schema.sObjectType objType = obj.getSObjectType();
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
		List<Schema.PicklistEntry> pleValues = fieldMap.get(fieldName).getDescribe().getPickListValues();
		for (Schema.PicklistEntry pleValue : pleValues) {
			Strings.add(pleValue.getValue());
		}
		return getRandomString(Strings);
	}

	/******************************************************************************************************************************************************************
	* Author: Eli Pogorelov
	* Company: Salesforce
	* Description: returns Set of picklist values (API names) for a field
	* Inputs : Sobject, String
	* History :
	******************************************************************************************************************************************************************/
	public Static Set<String> getPicklistValues(SObject obj, String picklistName)
	{
		Schema.sObjectType objType = obj.getSObjectType();
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
		List<Schema.PicklistEntry> pleValues = fieldMap.get(picklistName).getDescribe().getPickListValues();
		Set<String> Strings = new Set<String>();
		for (Schema.PicklistEntry pleValue : pleValues)
		{
			Strings.add(pleValue.getValue());
		}
		return Strings;
	}
    
	/******************************************************************************************************************************************************************
	* Author: Jeroen Burgers
	* Company: Salesforce
	* Description: returns Map of picklist value LABELS for a field
	* Inputs : Sobject, String
	* History :
    * 	Created 06/06/2018
	******************************************************************************************************************************************************************/
	public Static Map<String, String> getPicklistValueLabels(SObject obj, String picklistName) {
        Schema.sObjectType objType = obj.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<Schema.PicklistEntry> pleValues = fieldMap.get(picklistName).getDescribe().getPickListValues();
        Map<String, String> Values = new Map<String, String>();
        for (Schema.PicklistEntry pleValue : pleValues) {
			if (pleValue.isActive()) Values.put(pleValue.getValue(), pleValue.getLabel());                    
        }
        return Values;
	}

	/******************************************************************************************************************************************************************
	* Author: Eli Pogorelov
	* Company: Salesforce
	* Description: returns context userId
	* Inputs : none
	* History :
	******************************************************************************************************************************************************************/
	public static Id getContextUserId()
	{
		return UserInfo.getUserId();
	}

	@isTest
    public static void testRunTriggers () {
        TestDataFactoryUtils.runTriggers(true);
        System.assertEquals(true, [SELECT Id, Run_Triggers__c FROM Global_Bypass_Processes_Settings__c Where SetupOwnerId =: UserInfo.getOrganizationId()].Run_Triggers__c, 
                        'Global_Bypass_Processes_Settings__c.Run_Triggers__c should be true');
    }
    
    @isTest
	public static void testTriggerObjectBypass () {
        TestDataFactoryUtils.triggerObjectBypass('Account');
        System.assertEquals('Account', [SELECT Id, Trigger_Objects_Bypass__c FROM Global_Bypass_Processes_Settings__c Where SetupOwnerId =: UserInfo.getOrganizationId()].Trigger_Objects_Bypass__c, 
						'Global_Bypass_Processes_Settings__c.Trigger_Objects_Bypass__c should be Account');
    }

}