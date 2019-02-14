public class CPQcreateDocument {
    /*------------------------------------------------------------
        Author:         Wim van Beek
        Company:        Salesforce / NNCourage
        Description:    Create a Quote document as alternative to CPQmassmail
        

        History
        01-2019     Wim van Beek Initial

    ------------------------------------------------------------*/  
	public class QuoteProposalModel {
	    public String name;
	    public Id quoteId;
	    public Id templateId;
	    public String language;
	    public String outputFormat;
	    public String paperSize;
	}
	@InvocableMethod(label='Generate Quote Document')
	public static void createDocument(List<id> quoteIds) {
		system.debug('[CPQcreateDocument.createDocument]------ quoteIds '+ quoteIds);
		for (SBQQ__Quote__c quote : [SELECT id, 
										Name, 
										SBQQ__DocumentStatus__c, 
										SBQQ__EmailTemplateId__c , 
										SBQQ__PrimaryContact__c, 
										SBQQ__QuoteLanguage__c, 
										SBQQ__QuoteTemplateId__c
									FROM   SBQQ__Quote__c
									WHERE SBQQ__DocumentStatus__c  = 'Pending' 
									AND  id IN : quoteIds]){
			QuoteProposalModel quoteDoc = new QuoteProposalModel();
			quoteDoc.name = quote.name + '_' + DateTime.now().format('YYYYMMdd_HHmm');
			system.debug('[CPQcreateDocument.createDocument]------ quoteDoc.name '+ quoteDoc.name);
			quoteDoc.quoteId = quote.Id;
			quoteDoc.templateId = quote.SBQQ__QuoteTemplateId__c;
			quoteDoc.language = quote.SBQQ__QuoteLanguage__c;

			// Optional: hit quoteline to recalc outputfields

			// Error in testclass : Methods defined as TestMethod do not support Web service callouts
			String jobId = '70700056789';
			if (Test.isRunningTest() == false){
				jobId = SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', JSON.serialize(quoteDoc)); // CPQ-Api
			}
			jobId = jobId.replaceAll('"', '');
			Flow.Interview controlFlow ;
			Map<string, String> params = new Map<string, String>();
			params.put('recordId', quote.id);
			params.put('apexJobId', jobId);
			DebugLog.addInfo('[CPQcreateDocument.createDocument]CPQ Document generating started. Name: ' + quoteDoc.name, quote.id);  // Temp for debugging

			controlFlow = new Flow.Interview.Monitor_Renewal_Quote_Document_and_Email_Flow(params);  // Init Flow
			controlFlow.start();
			if (controlFlow.getVariableValue('success') == null) {  // Flow runs?
				DebugLog.addError('[CPQcreateDocument.createDocument]'+ quote.Name + ' Could not activate Flow', quote.id);
			}
		}

	}	
}