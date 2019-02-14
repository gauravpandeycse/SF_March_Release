/******************************************************************************************************************************************************************
 * Author: Aviad Efergan
 * Company: Salesforce
 * Description: Tests for CaseRunAssignmentRulesController (lightning componenet apex controller)
 * History :
 ******************************************************************************************************************************************************************/
@isTest
public with sharing class TestCaseRunAssignmentRulesController {
    
    @isTest
    static void test_helperMethods() {
        List<User> testUsers    = TestDataFactory.createUsers(1, 'System Administrator', '21100');
        List<Case> caseLst = TestDataFactory.returnCases(1, 'Non_Conformance_Report', null, null, testUsers[0]);
        insert caseLst;

        Test.startTest();
        System.assertEquals(true,CaseRunAssignmentRulesController.runAssignmentRules(caseLst[0]));
        CaseRunAssignmentRulesController.getRecordTypeCaseNCR();
        Test.stopTest();
    }
    
    @isTest
    static void test_helperMethods_negativeTest() {
        Case caseToFail = new Case();

        Test.startTest();
        //Test would return as the Case would not be inserted
        System.assertEquals(false, CaseRunAssignmentRulesController.runAssignmentRules(caseToFail));
         
        Test.stopTest();
    }
}