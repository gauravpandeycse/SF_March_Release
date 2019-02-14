@IsTest
private class TestAssignCaseToMe {

    @testSetup
    static void createTestData() {
        TestDataFactory.createBypassCustomSetting();
       	TestDataFactoryUtils.runProcessBuilders(false);
    }

    @IsTest
    static void testAssignCaseSuccess() {
        // create two users - one to initially own the case, the other to be the target of the assignment
        List<User> testUsers    = TestDataFactory.createUsers(2, 'System Administrator', '21100');
        User currentCaseOwner   = testUsers.get(0);
        User targetCaseOwner    = testUsers.get(1);

        // Create a set of cases that are initially owned by the currentCaseOwner
        List<Case> sampleRequestCases = TestDataFactory.returnCases(5, 'Sample_Request', null, null, currentCaseOwner);
        insert sampleRequestCases;

        // run the test - the intent is that updateCases method will update all the case owners from
        // currentCaseOwner to targetCaseOwner - which will be the 'in context' user for the test
        Test.startTest();
        System.runAs(targetCaseOwner) {

            PageReference pageRef = Page.AssignCaseToMe;
            Test.setCurrentPageReference(pageRef);

            ApexPages.StandardSetController controller = new ApexPages.StandardSetController(sampleRequestCases);
            controller.setSelected(sampleRequestCases);
            AssignCaseToMeController caseController = new AssignCaseToMeController(controller);

            caseController.updateCases();
        }

        // Verify that the current owner and the target owner are not the same user (otherwise test is invalid)
        System.assertNotEquals(targetCaseOwner, currentCaseOwner);

        // Check that the cases now all belong to the target owner
        for(Case c: sampleRequestCases) {
            System.assertEquals(targetCaseOwner.Id, c.OwnerId, 'Case owner does not match target owner!');
        }

        Test.stopTest();

    }

    

    @IsTest
    static void testAssignCaseFail()
    {
        
        // create two users - one to initially own the case, the other to be the target of the assignment
        List<User> testUsers    = TestDataFactory.createUsers(2, 'System Administrator', '21100');
        User currentCaseOwner   = testUsers.get(0);
        User targetCaseOwner    = testUsers.get(1);

        RecordType rt = IMCDUtils.getRecordType('Case', 'Sample_Request');
        List<Case> updatedSampleRequests = new List<Case>();

        User usr = [Select id from User where Id = :UserInfo.getUserId()];

        System.RunAs(usr)

        {

            avoidSetupNonSetupWorkaround(currentCaseOwner.Id);

        }

        // run the test - the intent is that updateCases method will update all the case owners from
        // currentCaseOwner to targetCaseOwner - which will be the 'in context' user for the test
        //Test.startTest();
        System.runAs(targetCaseOwner)
        {

            PageReference pageRef = Page.AssignCaseToMe;
            Test.setCurrentPageReference(pageRef);
            List<Case> sampleRequestCases = [SELECT Id, AccountId, ContactId, OwnerId, RecordTypeId FROM Case WHERE RecordTypeId =: rt.Id];
        
            // Assign an invalid id to the Case.AccountId to break the cases so they fail their update...
            for(Case c: sampleRequestCases) {
                c.AccountId = targetCaseOwner.Id;
            }
            ApexPages.StandardSetController controller = new ApexPages.StandardSetController(sampleRequestCases);
            controller.setSelected(sampleRequestCases);
            AssignCaseToMeController caseController = new AssignCaseToMeController(controller);
            Test.startTest();
                caseController.updateCases();
            Test.stopTest();
            // Check that the cases have the same owner as the update would have failed.
            updatedSampleRequests = [Select Id, OwnerId FROM Case WHERE Id in: sampleRequestCases];
            for(Case c: updatedSampleRequests) {
                System.assertEquals(currentCaseOwner.Id, c.OwnerId, 'Case owner should not change');
            }
        }

    }


    private static void avoidSetupNonSetupWorkaround(Id curCaseOwnerId)
    {
        User currentCaseOwner = [Select id from User where Id = :curCaseOwnerId];
        System.DEBUG('In Here');
        // Create a set of cases that are initially owned by the currentCaseOwner
        List<Case> sampleRequestCases = TestDataFactory.returnCases(5, 'Sample_Request', null, null, currentCaseOwner);
        insert sampleRequestCases;
    }


}