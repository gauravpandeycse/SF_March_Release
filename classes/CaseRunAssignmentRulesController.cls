/*------------------------------------------------------------  
Author:        Aviad Efergan
Company:       Salesforce   
Description:   Class supporting the CaseRunAssignmentRules Component
Inputs:        ID of Case   
Test Class:    TestCaseRunAssignmentRulesController 
History 
------------------------------------------------------------*/  
public class CaseRunAssignmentRulesController {
    
    @AuraEnabled
    public static Boolean runAssignmentRules(Case cs){      
        cs.Status = 'Assigned';
        list<Case> caseLst = new list<Case>{cs};
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        Database.SaveResult[] srLst = Database.update(caseLst, dmo);
        //Error Handling
        set<String> errors = new set<String>();
        for (Database.SaveResult sr : srLst) {
            if (!sr.isSuccess()) {                  
                Database.Error err = sr.getErrors()[0]; 
                String error = '[CaseRunAssignmentRulesController][runAssignmentRules] An error has occurred updating Case.\n'
                        + err.getStatusCode() + ': ' + err.getMessage() + '\n'
                        + 'Fields affected: ' + + err.getFields();
                errors.add (error); // add to set
            }
        }
        
        if (!errors.isEmpty()) {
            DebugLog.addError(String.join(new List<String>(errors), ';'));
            return false;
        }
        //Update done successfuly
        return true;            
    }
    
    @AuraEnabled
    public static String getRecordTypeCaseNCR(){
        Schema.DescribeSObjectResult caseDescribe  = Case.SObjectType.getDescribe();
        return caseDescribe.getRecordTypeInfosByDeveloperName().get('Non_Conformance_Report').getRecordTypeId();
    }
    
}