@isTest
global class TestQuoteThrottledRecalculate_Batch {


        @isTest static void testBatch(){

        // Create custom setting record
        IntegrationSettings__c intSetting = new IntegrationSettings__c(Quote_Recalculations_Per_Hour__c = 2500
                                                                      ,EvtCreateContractedPrice__c = 'Test1'
                                                                       ,EvtCreateSoldTo__c = 'Test2'
                                                                       ,EvtCreateTempProduct__c  = 'Test3'
                                                                       ,LocalErpComps__c = 'Test5'
                                                                       ,stdPricebookId__c = 'Test6');
         insert intSetting;
       
        // Create a set of test data
        List<Account> soldToAccounts = TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '79100');
            soldToAccounts.addAll(TestDataFactory.createAccounts(1, Label.Customer_Sold_To_Account_Record_Type, TestDataFactoryUtils.getContextUserId(), '13100'));
           
        list<SBQQ__Quote__c> qtLst = TestDataFactory.returnQuotes(1, soldToAccounts[0], new List<String>{'Coatings & Construction'});
        qtLst[0].TF_MigrationRecalcNeeded__c=TRUE;
        insert qtLst;

        // Run the batch
      	Test.startTest();
      	Database.executeBatch(new QuoteThrottledRecalculate_Batch());
      	Test.stopTest();

        // Assert the results
       SBQQ__Quote__c[] testQuote = [select id,TF_MigrationRecalcNeeded__c from SBQQ__Quote__c];
       system.assertEquals(FALSE,testQuote[0].TF_MigrationRecalcNeeded__c);

    }

}