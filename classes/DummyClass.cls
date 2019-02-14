/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Dummy class with dummy invocable method for process builders	
Inputs:        None	
Test Class:    TestDummyClass	
History	
03/22/2018	   Created class
------------------------------------------------------------*/	
global class DummyClass {
	@InvocableMethod(label='Dummy Apex step for Process Builder')
	global static void DummyMethod() { return; }
}