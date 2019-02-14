/*------------------------------------------------------------	
Author:        Jeroen Burgers	
Company:       Salesforce	
Description:   Test class
Inputs:        None	
History	
03/22/2018	   Created test class
------------------------------------------------------------*/	
@isTest
public class TestDummyClass {
	@isTest
	public static void TestDummyMethod () {
		DummyClass.DummyMethod();
		system.assert(true);
	}
}