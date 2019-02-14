/*------------------------------------------------------------
        Author:         Wim van Beek
        Company:        Salesforce / NNCourage
        Description:    Sdend a Quote document as alternative to CPQmassmail
        

        History
        01-2019     Wim van Beek Initial

    ------------------------------------------------------------*/  


public with sharing class CPQsendDocument {

	public class emailClass{
		public SBQQ__Quote__c Quote;
		public SBQQ__QuoteDocument__c quoteDoc;
		public Messaging.SingleEmailMessage theMail;
	}

	@InvocableMethod(label='Send Quote Document')
	public Static void emailQuoteDocument(List<Id> quoteDocId){
		Map<Id, emailClass> emailClassMap = new Map<Id, emailClass>();
		List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
		Map<Id, SBQQ__Quote__c> resultQuotes = new Map<Id, SBQQ__Quote__c>();

		// Get the related (valid) quotes
		for (SBQQ__Quote__c quote : [SELECT id, 
											Name, 
											SBQQ__DocumentStatus__c, 
											SBQQ__PrimaryContact__r.Email, 
											SBQQ__PrimaryContact__r.Name, 
											SBQQ__PrimaryContact__c, 
											SBQQ__SalesRep__c,
											SBQQ__SalesRep__r.Email,
											SBQQ__SalesRep__r.Name,
											OwnerId, 
											Owner.Email, 
											SBQQ__EmailTemplateId__c , 
											SBQQ__QuoteLanguage__c, 
											SBQQ__QuoteTemplateId__c 
									FROM   	SBQQ__Quote__c
									WHERE  	SBQQ__DocumentStatus__c = 'Pending'
									AND 	Id IN  (SELECT SBQQ__Quote__c FROM SBQQ__QuoteDocument__c WHERE Id IN : quoteDocId)]){
			system.debug('[CPQsendDocument.emailQuoteDocument]------ quote '+ quote);
			emailClass emailClass = new emailClass();
			emailClass.Quote = quote;
			emailClassMap.put(quote.id, emailClass);   // Store Quotes in Map

		}

		// Get the documents
		for (SBQQ__QuoteDocument__c theDoc :[SELECT id, SBQQ__ViewRecordId__c, SBQQ__Quote__c, SBQQ__Version__c  
												FROM SBQQ__QuoteDocument__c 
												WHERE Id =: quoteDocId]){   // Get last
			emailClass emailClass = emailClassMap.get(theDoc.SBQQ__Quote__c);
			emailClass.QuoteDoc = theDoc;
			emailClass.theMail = 	compileEmailMsg(emailClass);
		}
		for (emailClass emailClass : emailClassMap.values()) { // this loop will be only for one record (dummy loop)
			if (emailClass.theMail != null){
				system.debug('[CPQsendDocument.emailQuoteDocument]------ theMail '+ emailClass.theMail);
				try {
					For (Messaging.SendEmailResult res : Messaging.sendEmail(new list<Messaging.Email>{emailClass.theMail} , true)){
						system.debug('[CPQsendDocument.emailQuoteDocument] ------ res '+ res);
						if (res.isSuccess() == true){
							emailClass.Quote.SBQQ__DocumentStatus__c = 'Sent';
							resultQuotes.put(emailClass.Quote.Id, emailClass.Quote);
						} else {
							DebugLog.addError(emailClass.Quote.Name +  ' sending FAILED  ' + res.getErrors()[0].getMessage(),  emailClass.Quote.Id);
						}				
					}
				} catch (Exception E){
					DebugLog.addError(emailClass.Quote.Name +  ': '+ E.getMessage(),  emailClass.Quote.Id);
				}
			}  else {
				DebugLog.addError(emailClass.Quote.Name +  ' Email could not be compiled', emailClass.Quote.Id);
			}
		}
		update resultQuotes.values();
	}

	public Static Messaging.SingleEmailMessage compileEmailMsg(emailClass emailClass){
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setTemplateId(emailClass.Quote.SBQQ__EmailTemplateId__c);
	 		if (Test.isRunningTest() == false) { mail.setEntityAttachments(new List<String>{emailClass.QuoteDoc.SBQQ__ViewRecordId__c});}
	 		mail.setWhatId(emailClass.Quote.Id);
	 		mail.setTargetObjectId(emailClass.Quote.SBQQ__PrimaryContact__c);
	 		Boolean useOwner = true;
	 		if (emailClass.Quote.SBQQ__SalesRep__c != null && emailClass.Quote.SBQQ__SalesRep__r.Email != null){
	 			useOwner = false;
	 		}
	 		mail.setCcAddresses(new List<string>{(useOwner ? emailClass.Quote.OwnerId :emailClass.Quote.SBQQ__SalesRep__c)});
	 		mail.setReplyTo((useOwner ? emailClass.Quote.Owner.Email: emailClass.Quote.SBQQ__SalesRep__r.Email));
	 		mail.setSenderDisplayName((useOwner ?  emailClass.Quote.Owner.Name :emailClass.Quote.SBQQ__SalesRep__r.Name));
	 		try {
	 			system.debug('[CPQsendDocument.compileEmailMsg]------ mail '+ mail);
		 	} catch (Exception E ){
		 		DebugLog.addError(emailClass.Quote.Name + ' Error in template or compiled email', emailClass.Quote.Id );
		 		return null;
		 	}
		 	return mail;
	 	}
}