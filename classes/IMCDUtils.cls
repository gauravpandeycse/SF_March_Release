/*------------------------------------------------------------	
Author:        Nimil Christopher	
Company:       Salesforce	
Description:   Generic Class that can be used for reusable methods
Test Class:    TestIMCDUtils  	
History	
03/29/2018	   Created class
------------------------------------------------------------*/	
public class IMCDUtils {
    public static void debugLimits(String origin) {
        system.debug(origin + ' CPQ Triggers enabled: ' + SBQQ.TriggerControl.isEnabled());
        system.debug(origin + ' SOQLs used: ' + Limits.getQueries() + ' out of ' + Limits.getLimitQueries());
        system.debug(origin + ' CPU Time  used: ' + Limits.getCpuTime() + ' out of ' + Limits.getLimitCpuTime());
    }

    //Generic Method to retrieve a record type of an object
    //Inputs - 
    //objectName - Name of SObject
    //developerName - Developer/API name of RecordType
    public static RecordType getRecordType(String objectName, String developerName){
        if(String.isEmpty(objectName) || String.isEmpty(developerName)) return null;
            RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType =: objectName  AND DeveloperName =: developerName LIMIT 1];
        return rt;
    }
    // Get all recordTypeIds in one MAP
    public static Map<String, Id> recordTypeIdMap {get{
        if (recordTypeIdMap == null){
            recordTypeIdMap = new Map<String, Id>();
            for (RecordType rt:[SELECT id, DeveloperName FROM RecordType]){
                recordTypeIdMap.put(rt.DeveloperName, rt.Id);
            }
        }
        return recordTypeIdMap;
        }set;}
    
    //Generic Method to retrieve a queue Id by Name
    //Inputs - 
    //queueName - Name of Queue
    public static Id getQueueId(String queueName){
        List<QueueSObject> queueSobjectList = [SELECT Queue.Id 
                                                FROM QueueSObject 
                                                WHERE Queue.Type ='Queue' 
                                                AND Queue.Name =: queueName ]; 
        if(queueSobjectList.size() == 1){
            return queueSobjectList[0].queue.Id;
        }
        return null;
    }
    //Generic Method to retrieve the default PriceBookId
    //Inputs - none
    //Cannot be unit tested, just code coverage.
    public static Id getDefaultPricebookId(){
        return ([SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id);
    }
    //Generic Method to retrieve the all currencies And current ExchangeRate
    //Inputs - none
    Public Static Map<string, Double>  allCurrencies  {get{
        if (allCurrencies == null){
            allCurrencies = new map<string, Double>();
            for (CurrencyType CT:   [SELECT IsoCode, ConversionRate FROM CurrencyType where IsActive= true]){
                allCurrencies.put(CT.IsoCode, CT.ConversionRate) ;
            }
        }
        return allCurrencies;
    }set;}
    //Generic Method to retrieve picklist Labels because formula fields return their ApiNames and there are cases when Values differ from Labels
    public static Map<String, String> getPickListValues(SObject obj, String fieldName){
        Map<String, String> picklistMap = new Map<String, String>();
        Schema.sObjectType objectType = obj.getSObjectType();
		Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
		List<Schema.PicklistEntry> picklistValues = fieldMap.get(fieldName).getDescribe().getPickListValues();
		Set<String> Strings = new Set<String>();
		for (Schema.PicklistEntry pleValue : picklistValues){
			picklistMap.put(pleValue.getValue(),pleValue.getLabel());
		}
        return picklistMap;
    }
    
	/*------------------------------------------------------------	
	Source:		   http://sfdc.arrowpointe.com/2011/03/28/cloning-records-in-apex/
	Description:   Method creates a SOQL query string for all fields on a given object, to be used e.g. for Cloning records
				   Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
	Inputs:        ID of the triggering Account record	
	Test Class:    ImcdUtils	
	History	
		01/08/2018	   SF/JEBU/Created method
	------------------------------------------------------------*/	
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
         
        String selects = '';
         
        if (String.isEmpty(whereClause) || String.isEmpty(objectName)) return null;  
         
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        List<String> selectFields = New List<String>();
         
        if (!fMap.isEmpty()){ 
            for (Schema.SObjectField ft : fMap.values()) { // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    if (fd.isDeprecatedAndHidden() == false ) { // New 10-10-2018 WvB
                        selectFields.add(fd.getName());
                    }
                }
            }
        }
         
        if (!selectFields.isEmpty()) {
            for (String fieldName : selectFields){
                selects += fieldName + ',';
            }
            if (selects.endsWith(',')) 
                selects = selects.substring(0,selects.lastIndexOf(','));
             
        }
         
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
    }
    // Generic method to transfer amount to formatted string. It is a poor-mans formatting.
    // If major approvement fount: please inform me and get a bottle of wine WvB 

    Public static String formatAmount(Decimal amount, Integer decimals){
        if (Amount == null){return '0';}
        if (Amount == 0){return '0';}
        Double X = 1000.1;
        String decimalPoint =  X.format().mid(5,1);
        String thousandSeperator = X.format().mid(1,1);
        Double AmountWhole = Amount.setScale(decimals);
        Map<Integer, Integer> conversion = new Map<Integer, Integer>();
        conversion.put(0,0);
        conversion.put(1,10);
        conversion.put(2,100);
        conversion.put(3,1000);
        conversion.put(4,10000);
        conversion.put(5,100000);
        Integer AmountDecimals = Integer.valueOf(( amount - amount.intValue() ) * conversion.get(decimals) ) ;
        String ret;
        String decPart = String.valueOf(AmountDecimals);
        decPart =  '00000000'.left(decimals - decPart.length() ) + decPart;
        if (decPart == '00000000'.left(decimals)) {
            decPart = '00000000'.left(decimals);
        }
        String initValue = String.valueOf(amount.intValue());
        if (initValue.length() > 3){
            initValue = initValue.left(initValue.length() - 3)+ thousandSeperator + initValue.right(3); 
        }
        ret = initValue + decimalPoint + decPart;
        return   ret  ;
    }

  /*
    *  limitsWithinRange will return false if one of the indicated limits reached more than given %
    *  Use to limit an unlimmited process
    */
    Public Static Boolean limitsWithinRange(Integer Percent) {
        Double ThePercent = Percent ; 
        if (ThePercent > 100 || ThePercent == 0){ThePercent = 50;}  // Fall back %
        if (LIMITS.getDMLRows() * 100 > (LIMITS.getLimitDMLRows() * Percent ) ) {system.debug('------ LimitRange getDMLRows '+ LIMITS.getDMLRows()) ; return false;}
        if (LIMITS.getCallouts() * 100 > (LIMITS.getLimitCallouts() * Percent )) {system.debug('------ LimitRange getCallouts '+ LIMITS.getCallouts()) ;return false;}
        if (LIMITS.getQueries()  * 100 > (LIMITS.getLimitQueries() * Percent )) {system.debug('------ LimitRange getQueries '+ LIMITS.getQueries()) ;return false;}
        if (LIMITS.getQueryRows()  * 100 > (LIMITS.getLimitQueryRows() * Percent )) {system.debug('------ LimitRange getQueryRows '+ LIMITS.getQueryRows()) ;return false;}
        if (LIMITS.getCpuTime()  * 100 > (LIMITS.getLimitCpuTime() * Percent )) {system.debug('------ LimitRange getCpuTime '+ LIMITS.getCpuTime()) ;return false;}
        if (LIMITS.getDMLStatements()  * 100 > (LIMITS.getLimitDMLStatements() * Percent )) {system.debug('------ LimitRange getDMLStatements '+ LIMITS.getDMLStatements()) ;return false;}
        if (LIMITS.getHeapSize()  * 100 > (LIMITS.getLimitHeapSize() * Percent )) {system.debug('------ LimitRange getHeapSize '+ LIMITS.getHeapSize()) ;return false;}
        if (LIMITS.getFutureCalls() * 100 > (LIMITS.getLimitFutureCalls()  * Percent )) {system.debug('------ LimitRange getFutureCalls '+ LIMITS.getFutureCalls()) ;return false;}
        return true;
    }        
}