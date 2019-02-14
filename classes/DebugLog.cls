/*------------------------------------------------------------	
Author:        Miguel Coimbra	
Company:       Salesforce	
Description:   Generic Class providing a service for logging messages, error or any ohter information 
to a Debug Log Object for troubehsotting purposes
Inputs:        None	
Test Class:    TestDebugLog  	
History	
	03/29/2018	   Created class
	16/05/2018	   JEBU/SF: Added truncation to createLog() / createException() methods
	03/01/2018	   JEBU/SF: Added overridden methods including objectId (treated as string, truncated at 18)
------------------------------------------------------------*/	
global without sharing class DebugLog {
	private final static String INFO 		= 'Info';
	private final static String ERROR		= 'Error';  	 
	private final static String FATAL		= 'Fatal';

    global DebugLog(){} 

	public static void addInfo(String description){
	  	createLog(DebugLog.INFO, description);	
	}

	public static void addInfo(String description, String objectId){
		createLog(DebugLog.INFO, description, objectId);
	}

	public static void addError(String description){
	  	createLog(DebugLog.ERROR, description);	
	}

	public static void addError(String description, String objectId){
		createLog(DebugLog.ERROR, description, objectId);
	}

	public static void addException(Exception ex, String Comments){
	  	createException(DebugLog.FATAL,''+ex.getCause(), ''+ex.getLineNumber(), ''+ex.getMessage(), ''+ex.getStackTraceString(), ''+ex.getTypeName(), '' +comments);	
	}

	@future
	public static void addInfoFuture(String description){
	  	createLog(DebugLog.INFO, description);	
	}

	@future
	public static void addErrorFuture(String description){
	  	createLog(DebugLog.ERROR, description);	
	}
		
	private static void createLog(String severity, String description){
			debugLog__c dl = new debugLog__c();
			dl.Severity__c = severity;
			dl.Message__c = description.left(32768);
        	dl.Date_Time__c = System.now(); 
			Database.Saveresult saveresult = Database.insert(dl);
	}

	private static void createLog(String severity, String description, String objectId){
		debugLog__c dl = new debugLog__c();
		dl.Severity__c = severity;
		dl.Message__c = description.left(32768);
		dl.Date_Time__c = System.now();
		dl.ObjectId__c = objectId.left(18);
		Database.Saveresult saveresult = Database.insert(dl);
	}

	private static void createException(String severity, String cause, String linenumber, String message, String stacktracestring, String typename, String Comments){
			debugLog__c dl = new debugLog__c();
			dl.Severity__c = severity;
			dl.Cause__c = cause.left(32768);
			dl.LineNumber__c = linenumber;
			dl.Message__c = message.left(32768);
			dl.StackTraceString__c = stacktracestring.left(32768);
			dl.TypeName__c = typename.left(32768);
        	dl.Comments__c = comments.left(32768); 
        	dl.Date_Time__c = System.now(); 
			Database.Saveresult saveresult = Database.insert(dl);
	}
 

}