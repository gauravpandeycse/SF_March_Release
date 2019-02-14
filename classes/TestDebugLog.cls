/*------------------------------------------------------------	
Author:        Miguel Coimbra	
Company:       Salesforce	
Description:   Generic Class providing a service for logging messages, error or any ohter information 
to a Debug Log Object for troubehsotting purposes
Inputs:        None	
Test Class:    TestDebugLog  	
History	
	03/29/2018	   Created class
	16/05/2018	   JEBU/SF: Added myTestTruncatedLogMessage test method
------------------------------------------------------------*/	
@isTest
private class TestDebugLog {

	@isTest static void myTestLogMessage (){ 
        Test.startTest(); 
        DebugLog dl = new DebugLog();
        DebugLog.addInfo('This is an Info');
        DebugLog.addError('This is an error'); 
        DebugLog.addInfoFuture('This is an Info logged asynchronously');
        DebugLog.addErrorFuture('This is an error logged asynchronously');
        DebugLog.addInfo('This is an Info', 'with objectId');
        DebugLog.addError('This is an error', 'with objectId');
        Test.StopTest();  
    }
    
   	@isTest static void myTestTruncatedLogMessage (){ 
        Test.startTest(); 
        DebugLog dl = new DebugLog();
        String errMsg = '';
        for (integer i=0; i < 33000; i++) errMsg += '!';
        DebugLog.addInfo(errMsg);
        DebugLog.addError(errMsg); 
        DebugLog.addInfoFuture(errMsg);
        DebugLog.addErrorFuture(errMsg);
		System.assertEquals(32768, [SELECT Message__c FROM DebugLog__c LIMIT 1].Message__c.length(), 'Expected truncated to 32768 chars');
        Test.StopTest();  
    }
    
    @isTest static void myTestLogException (){
	 	try{
	 		Exception ex ;
	 		throw ex;
	 	} catch (exception e){
	 		Test.startTest(); 
	 			DebugLog.addException(e, 'Error on Test Coverage');
	 		Test.StopTest();
            System.assertEquals([Select count() from DebugLog__c], 1); 
	 	}
	 }
}