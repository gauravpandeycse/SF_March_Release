/*------------------------------------------------------------	
Author:        Implementation team	
Company:       Salesforce, NNCourage	
Description:   Test data factory for all Test classes. 
Inputs:        Minimum = numRecords, some methods require additional inputs. 
Test Class:    N/A
History	
03/29/2018	   Created class
------------------------------------------------------------*/	
@isTest
public class TestDataFactory {
   /*
    * ImcdCompany__c should receive API value for the global picklist (e.g. 00112)
	*/
    public static List<Account> createAccounts(Integer numRecords, String recordType, ID ownerId, String IMCDCompany) {
        
        RecordType rt = IMCDUtils.getRecordType('Account', recordType);
        
		List<Account> lstAccount = new List<Account>();

 		for(Integer i = 0; i < numRecords; i++) {
        	Account accnt = new Account(Name = 'TestAccount' + i, recordTypeId = rt.Id, ownerId = ownerId, LockedForIntegration__c = false, ImcdCompany__c = IMCDCompany);
        	lstAccount.add(accnt);
    	}
        
		insert lstAccount;
		return lstAccount;
    }

    public static void createIntegrationSettings() {
		insert new IntegrationSettings__c (SetupOwnerId=UserInfo.getOrganizationId(), EvtCreateSoldTo__c ='CREATE_CUSTOMER', stdPricebookId__c = Test.getStandardPricebookId(),
                                           EvtCreateContractedPrice__c = 'CREATED_CONTRACTED_PRICE', EvtCreateTempProduct__c = 'CREATED_TEMP_PRODUCT');
    }

    /*****************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns an Account list, same as CreateAccounts, without the INSERT DML statement
    * Inputs : Integer , String , ID , String
    * History :
    ******************************************************************************************************************************************************************/
    public static List<Account> returnAccounts(Integer numRecords, String recordType, ID ownerId, String IMCDCompany) {

        RecordType rt = IMCDUtils.getRecordType('Account', recordType);

        List<Account> lstAccount = new List<Account>();

        for(Integer i = 0; i < numRecords; i++) {
            Account accnt = new Account(Name = 'TestAccount' + i, recordTypeId = rt.Id, ownerId = ownerId, LockedForIntegration__c = false, ImcdCompany__c = IMCDCompany);
            lstAccount.add(accnt);
        }
        return lstAccount;
    }

	/*****************************************************************************************************************************************************************
	* Author: Jeroen Burgers
	* Company: Salesforce
	* Description: returns an AccountShipToAddress list, without the INSERT DML statement
	* Inputs : Integer, ID
	* History :
	******************************************************************************************************************************************************************/
	public static List<AccountShiptoAddress__c> returnShipto(Integer numRecords, ID accountId) {

		List<AccountShiptoAddress__c> lstShipto = new List<AccountShiptoAddress__c>();

		for(Integer i = 0; i < numRecords; i++) {
			AccountShiptoAddress__c shipto = new AccountShiptoAddress__c(
					Name = 'TestShipto' + i
					, Country__c = TestDataFactoryUtils.getRandomPickListValue(new AccountShiptoAddress__c(), 'Country__c')
					, Account__c = accountId
			);
			lstShipto.add(shipto);
		}
		return lstShipto;
	}

	/*****************************************************************************************************************************************************************
	* Author: Jeroen Burgers
	* Company: Salesforce
	* Description: returns a Contact list, same as CreateAccounts, without the INSERT DML statement
	* Inputs : Integer , String , ID , String
	* History :
	******************************************************************************************************************************************************************/
	public static List<Contact> returnContacts (Integer numRecords) {

		List<Contact> lstContact = new List<Contact>();

		for (Integer i = 0 ; i < numRecords ; i ++) {
			Contact con = new Contact(
					FirstName = 'TestContact' + i
					, LastName = 'TestContact' + i
					, CorrespondenceLanguage__c = TestDataFactoryUtils.getRandomPickListValue(new Contact(), 'CorrespondenceLanguage__c')
			);
			lstContact.add(con);
		}
		return lstContact;
	}

	public static List<AccountLob__c> createAccountLobs(Integer numRecords, List<Account> lstAccounts) {
 		
        List<AccountLob__c> lstAccountLob = new List<AccountLob__c>();
        
        for (Account accnt : lstAccounts) {
            for (Integer i = 0; i < numRecords; i++) {
                AccountLob__c accountLob = new AccountLob__c ( Account__c = accnt.Id, Primary__c = (i == 0 ? true : false) ); 
                //accountLob.LOB1__c = TestDataFactoryUtils.getRandomPickListValue (accountLob, 'LOB1__c');
                //accountLob.LOB2__c = TestDataFactoryUtils.getRandomPickListValue (accountLob, 'LOB2__c');
                //accountLob.LOB3__c = TestDataFactoryUtils.getRandomPickListValue (accountLob, 'LOB3__c');
				accountLob.LOB1__c = 'Coatings & Construction';
            	accountLob.LOB2__c = 'Adhesives & Sealants';
            	//accountLob.LOB3__c = 'Industrial';
                lstAccountLob.add(accountLob);
            }
        }
        insert lstAccountLob;
        return lstAccountLob;
    }

    /*****************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns an AccountLob__c list, given lob1 parametr
    * Inputs : Integer, List<Account>, String
    * History :
    ******************************************************************************************************************************************************************/
    public static List<AccountLob__c> createAccountLobs(Integer numRecords, List<Account> lstAccounts, String lob1)
    {
        List<AccountLob__c> lstAccountLob = new List<AccountLob__c>();

        for (Account accnt : lstAccounts) {
            for (Integer i = 0; i < numRecords; i++) {
                AccountLob__c accountLob = new AccountLob__c ( Account__c = accnt.Id, Primary__c = (i == 0 ? true : false) );
                accountLob.LOB1__c = lob1;
                accountLob.LOB2__c = TestDataFactoryUtils.getRandomPickListValue (accountLob, 'LOB2__c');
                accountLob.LOB3__c = TestDataFactoryUtils.getRandomPickListValue (accountLob, 'LOB3__c');
                lstAccountLob.add(accountLob);
            }
        }
        insert lstAccountLob;
        return lstAccountLob;
    }

    /*****************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns an AccountLob__c list
    * Inputs : Integer, Account, List<String>, Boolean
    * Comments: the size of the lob1List should be equal to numRecords
    * History :
    ******************************************************************************************************************************************************************/
    public static List<AccountLob__c> returnAccountLobs(Integer numRecords, Account account, List<String> lob1List, Boolean primaryNeeded)
    {
        List<AccountLob__c> lstAccountLob = new List<AccountLob__c>();

        for (Integer i = 0; i < numRecords; i++)
        {
            AccountLob__c accountLob = new AccountLob__c ( Account__c = account.Id );
            if(i==0 && primaryNeeded)
            {
                accountLob.Primary__c = true;
            }
            else
            {
                accountLob.Primary__c = false;
            }
            accountLob.LOB1__c = lob1List[i];
            lstAccountLob.add(accountLob);
        }
        return lstAccountLob;
    }
    

    /*****************************************************************************************************************************************************************
    * Author: Unknown, Eli Pogorelov
    * Company: Salesforce
    * Description: inserts & returns a user list
    * Inputs : Integer, String, String
    * History : 8/4/18 generating userName randomly using TestDataFactoryUtils.getRandomNumber, getRandomString, filling the CountryCode field
    ******************************************************************************************************************************************************************/
    public static List<User> createUsers(Integer numRecords, String profileName, String ImcdCompany)
    {
        
        Profile profile = [select Id, Name from profile where Name =: profileName LIMIT 1];
        List<User> lstUsers = new List<User>();
        String baseUsrName = profile.Name.replace(' ','');
        List<String> profileNameSplitted = baseUsrName.split('');

        for(Integer i = 1; i <= numRecords; i++)
        {

            Integer j = TestDataFactoryUtils.getRandomNumber(23*i) ;
            j+=i;
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            baseUsrName += dateString + randomInt;
            String userName = baseUsrName + '@1234testuser' + TestDataFactoryUtils.getRandomString(profileNameSplitted) + TestDataFactoryUtils.getRandomNumber(j) + '.com';
                    
			User user = new User(alias = 'test1', Email=userName,
				emailencodingkey='UTF-8', FirstName = 'TestUser' + TestDataFactoryUtils.getRandomNumber(j), LastName = 'TestUser' + i, languagelocalekey='en_US',
				LocaleSidKey='en_US', ProfileId = profile.Id, CountryCode = 'NL',
				TimezoneSidKey='Europe/Amsterdam', UserName=userName, ImcdCompany__c=ImcdCompany, IntegrationId__c = String.valueOf(TestDataFactoryUtils.getRandomNumber(10000)));
            
            lstUsers.add(user);
        }
        insert lstUsers;
		return lstUsers;
    }

    /*****************************************************************************************************************************************************************
    * Author: Unknown, Eli Pogorelov
    * Company: Salesforce
    * Description: inserts & returns a user list
    * Inputs : Integer, String, String
    * History : 8/4/18 generating userName randomly using TestDataFactoryUtils.getRandomNumber, getRandomString, filling the CountryCode field
    *           13/05/18 adding integrationId to honour validation rule
    ******************************************************************************************************************************************************************/
    public static List<User> returnUsers(Integer numRecords, String profileName, String ImcdCompany)
    {

        Profile profile = [select Id, Name from profile where Name =: profileName LIMIT 1];
        List<User> lstUsers = new List<User>();
        String baseUsrName = profile.Name.replace(' ','');
        List<String> profileNameSplitted = baseUsrName.split('');

        for(Integer i = 1; i <= numRecords; i++)
        {
            Integer j = TestDataFactoryUtils.getRandomNumber(23*i) ;
            j+=i;
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
            baseUsrName += dateString + randomInt;
            String userName = baseUsrName + '@1234testuser' + TestDataFactoryUtils.getRandomString(profileNameSplitted) + TestDataFactoryUtils.getRandomNumber(j) + '.com';

            User user = new User(alias = 'For_Test', Email=userName,
                    emailencodingkey='UTF-8', FirstName = 'TestUser' + TestDataFactoryUtils.getRandomNumber(j), LastName = 'TestUser2' + i, languagelocalekey='en_US',
                    LocaleSidKey='en_US', ProfileId = profile.Id, CountryCode = 'NL',
                    TimezoneSidKey='Europe/Amsterdam', UserName=userName, ImcdCompany__c=ImcdCompany, IntegrationId__c = userName);

            lstUsers.add(user);
        }
        return lstUsers;
    }
    
	/* 
	 * Inputs: Status, if ommitted random status will be used instead.
	 *		   Event, if ommitted fixed event will be used. 
	*/	
    public static List<IntegrationLog__c> createIntegrationLogs(Integer numRecords, String status, String event) { 
        List<IntegrationLog__c> lstIntLog = new List<IntegrationLog__c>();
        
        for(Integer i = 0; i < numRecords; i++) {
            IntegrationLog__c intLog = new IntegrationLog__c();
            if (String.isBlank(status)) intLog.Status__c = TestDataFactoryUtils.getRandomPickListValue (intLog, 'Status__c');
            else intLog.Status__c = status;
            intLog.Event__c = event;
            lstIntLog.add(intLog);
        }
                             
        insert lstIntLog;
		return lstIntLog;
    }
    
    public static Global_Bypass_Processes_Settings__c createBypassCustomSetting(){
        Global_Bypass_Processes_Settings__c bypassSetting = new Global_Bypass_Processes_Settings__c();
        bypassSetting.Run_Triggers__c  = true;
        bypassSetting.Run_Process_Builder__c = true;
        insert bypassSetting;
        return bypassSetting;
    }

    /******************************************************************************************************************************************************************
	* Author: Eli Pogorelov
	* Company: Salesforce
	* Description: returns a SharingAccess__c list, size of this list will be equal to the passed User list size
	* Inputs : Integer, List<User>, String, Boolean
	* History :
	******************************************************************************************************************************************************************/
    public static List<SharingAccess__c> getSharingAccessList(List<User> usrList, String imcdComp, String lob1, Boolean globalchk)
    {
        List<SharingAccess__c> shareAccessList = new List<SharingAccess__c>();
        for(User u : usrList)
        {
            SharingAccess__c sa = new SharingAccess__c();
            sa.Name = 'test';
            sa.IMCDCompany__c = imcdComp;
            sa.UserId__c = u.Id;
            sa.LOB1__c = lob1;
            sa.global__c = globalchk;
            shareAccessList.add(sa);
        }
        return shareAccessList;
    }

    /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: returns a SharingAccess__c
   * Inputs : Integer, User, String, Boolean
   * History :
   ******************************************************************************************************************************************************************/
    public static SharingAccess__c getSharingAccess(User usr, String imcdComp, String lob1, Boolean globalchk)
    {
        SharingAccess__c sa = new SharingAccess__c();
        sa.Name = 'test';
        sa.IMCDCompany__c = imcdComp;
        sa.UserId__c = usr.Id;
        sa.LOB1__c = lob1;
        sa.global__c = globalchk;
        return sa;
    }

    /******************************************************************************************************************************************************************
	* Author: Eli Pogorelov
	* Company: Salesforce
	* Description: returns a Opportunity list, size of this list will be equal to numRecords
	* Inputs : Integer, Account, List<String>, Boolean
	* History :
	******************************************************************************************************************************************************************/
    public static List<Opportunity> returnOpportunities(Integer numRecords, Account account, List<String> lob1List)
    {
        List<Opportunity> lstOpps = new List<Opportunity>();
        RecordType rt = IMCDUtils.getRecordType('Opportunity','Standard');
        for (Integer i = 0; i < numRecords; i++)
        {
            Opportunity opp = new Opportunity ( AccountId = account.Id );
            opp.Name = 'testOpp';
            opp.recordTypeId = rt.Id;
            opp.LOB1__c = !lob1List.isEmpty() ? lob1List[i] : '';
            opp.StageName = 'Analysis' ;
            opp.CloseDate = Date.today().addYears(1);
            opp.Type = 'Development' ;
            opp.CurrencyIsoCode = 'EUR';
            lstOpps.add(opp);
        }
        return lstOpps;
    }

     /******************************************************************************************************************************************************************
    * Author: Aviad Efergan
    * Company: Salesforce
    * Description: returns a OpportunityLineItem list, size of this list will be equal to numRecords
    * Inputs : Integer, Id, List<String>
    * History :
    ******************************************************************************************************************************************************************/
    public static List<OpportunityLineItem> returnOpportunityLineItem(Integer numRecords, Id oppId, PricebookEntry pbEntry){
        List<OpportunityLineItem> lstOppLines = new List<OpportunityLineItem>();

        for (Integer i = 0; i < numRecords; i++){
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = oppId;
            oli.Quantity = 5;
            oli.PricebookEntryId = pbEntry.Id;
            oli.TotalPrice = 5 * pbEntry.UnitPrice;
            lstOppLines.add(oli);
        }
       
        return lstOppLines;
    }

    /******************************************************************************************************************************************************************
    * Author: Aviad Efergan
    * Company: Salesforce
    * Description: returns a SBQQ quote line list, size of this list will be equal to numRecords
    * Inputs : Integer, Id, Id
    * History :
    ******************************************************************************************************************************************************************/
    public static List<SBQQ__QuoteLine__c> returnQuoteLine(Integer numRecords, Id qtId, Id prodId){
        List<SBQQ__QuoteLine__c> lstQtLines = new List<SBQQ__QuoteLine__c>();
        
        for (Integer i = 0; i < numRecords; i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c = qtId;
            ql.SBQQ__Product__c = prodId;
            ql.Stage__c = 'Analysis';
            lstQtLines.add(ql);
        }
       
        return lstQtLines;
    }
    /******************************************************************************************************************************************************************
    * Author: Aviad Efergan
    * Company: Salesforce
    * Description: creates a proudct related to prinicpal account
    * History :
    * 	11/05/2018: Added ItemStatus__c (required)
    ******************************************************************************************************************************************************************/
    public static Product2 createProduct(Id principalId){
        Product2 prod = new Product2();
        prod.RecordTypeId = IMCDUtils.getRecordType('Product2', 'Product').Id;
        prod.Name = 'Product X';
        prod.ProductCode = 'Pro-X';
        prod.ItemStatus__c = '07.Obsolete';
        prod.isActive = true;
        prod.Principal__c = principalId;
        prod.FullSegmentsNumber__c = 'ru48fdh3Test' ;
        prod.TradeName__c = 'test' ;
        prod.CountryofOrigin__c = 'US';
        prod.ProductManager__c = UserInfo.getUserId() ;
        prod.ConversionFactor__c = 8 ;
        prod.UnitOfMeasure__c = TestDataFactoryUtils.getRandomPickListValue(prod, 'UnitOfMeasure__c');
        insert prod;
        return prod;
    }

    /******************************************************************************************************************************************************************
     * Author: Eli Pogorelov
     * Company: Salesforce
     * Description: creates a proudct related to prinicpal account, and let you choose a fullSegmentNumber to a product
     * History :
     * 	11/05/2018: Added ItemStatus__c (required)
     ******************************************************************************************************************************************************************/
    public static Product2 createProduct(Id principalId, String segmentNum){
        Product2 prod = new Product2();
        prod.RecordTypeId = IMCDUtils.getRecordType('Product2', 'Product').Id;
        prod.Name = 'TestProduct';
        prod.ProductCode = 'Pro-X';
        prod.ItemStatus__c = '07.Obsolete';
        prod.isActive = true;
        prod.Principal__c = principalId;
        prod.FullSegmentsNumber__c = segmentNum ;
        prod.TradeName__c = 'test' ;
        prod.CountryofOrigin__c = 'US';
        prod.ProductManager__c = UserInfo.getUserId() ;
        prod.ConversionFactor__c = 8 ;
        prod.UnitOfMeasure__c = TestDataFactoryUtils.getRandomPickListValue(prod, 'UnitOfMeasure__c');
        insert prod;
        return prod;
    }
    
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: creates and returns a list of products related to principal account
    * History :
    *   13/05/2018: Created
    *   06/06/2018: Added overloaded method (numRecord, principalId)
    ******************************************************************************************************************************************************************/
    public static List<Product2> createProducts(Integer numRecords, Id principalId) {
        return ( createProducts(numRecords, principalId, '07.Obsolete', 'Product') );
    }
    
    public static List<Product2> createProducts(Integer numRecords, Id principalId, String status, String recordType) {
        List<Product2> products = new List<Product2>();
        Id rt1Id = IMCDUtils.getRecordType('Product2', recordType).Id;
		for (Integer i = 0; i < numRecords; i++){
        	Product2 prod = new Product2();
        	prod.Name = 'Product X';
        	prod.ProductCode = 'Pro-X';
        	prod.isActive = true;
        	prod.Principal__c = principalId;
        	prod.ItemStatus__c = status;
            prod.FullSegmentsNumber__c = 'ru48fdh3Test' + Math.random() + i ;
            prod.TradeName__c = 'test' ;
            prod.CountryofOrigin__c = 'US';
            prod.ProductManager__c = UserInfo.getUserId() ;
            prod.ConversionFactor__c = 8 ;
            prod.UnitOfMeasure__c = TestDataFactoryUtils.getRandomPickListValue(prod, 'UnitOfMeasure__c');
            prod.RecordTypeId = rt1Id ; 
        	products.add(prod);

        }

        insert products;
        return products;
    }

    /******************************************************************************************************************************************************************
    * Author: Aviad Efergan
    * Company: Salesforce
    * Description: creates a pricebookentry
    * History :
    ******************************************************************************************************************************************************************/
    public static PricebookEntry createPricebookEntry(Id pricebookId, Id prodId){
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.CurrencyIsoCode = 'EUR';
        pbEntry.Pricebook2Id = pricebookId;
        pbEntry.Product2Id = prodId;
        pbEntry.UnitPrice = 0.00;
        pbEntry.IsActive = true;

        insert pbEntry;
        return pbEntry;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: creates a pricebookentry, with choosen currencies
    * History :
    ******************************************************************************************************************************************************************/
        public static PricebookEntry createPricebookEntry(Id pricebookId, Id prodId, String curISOcode){
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.CurrencyIsoCode = curISOcode;
        pbEntry.Pricebook2Id = pricebookId;
        pbEntry.Product2Id = prodId;
        pbEntry.UnitPrice = 0.00;
        pbEntry.IsActive = true;

        insert pbEntry;
        return pbEntry;
    }
    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns a SBQQ_Quote list, size of this list will be equal to numRecords a standard pricebook
    * Inputs : Integer, Account, List<String>, Boolean
    * History :
    ******************************************************************************************************************************************************************/
    public static List<SBQQ__Quote__c> returnQuotes(Integer numRecords, Account account, List<String> lob1List)
    {
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();

        for (Integer i = 0; i < numRecords; i++)
        {
            SBQQ__Quote__c qt = new SBQQ__Quote__c( SBQQ__Account__c = account.Id );
            qt.LOB1__c = !lob1List.isEmpty() ? lob1List[i] : '';
            qt.CurrencyIsoCode = 'EUR';
            qt.SBQQ__Pricebook__c = Test.getStandardPricebookId();
            qt.SBQQ__PricebookId__c = Test.getStandardPricebookId();
            lstQuotes.add(qt);
        }
        return lstQuotes;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: returns a SBQQ_Quote list, size of this list will be equal to numRecords, and assigns a custom pricebook
    * Inputs : Integer, Account, List<String>, Id
    * History :
    ******************************************************************************************************************************************************************/
    public static List<SBQQ__Quote__c> returnQuotes(Integer numRecords, Account account, List<String> lob1List, Id pricebookId)
    {
        List<SBQQ__Quote__c> lstQuotes = new List<SBQQ__Quote__c>();

        for (Integer i = 0; i < numRecords; i++)
        {
            SBQQ__Quote__c qt = new SBQQ__Quote__c( SBQQ__Account__c = account.Id );
            qt.LOB1__c = !lob1List.isEmpty() ? lob1List[i] : '';
            qt.CurrencyIsoCode = 'EUR';
            qt.SBQQ__Pricebook__c = pricebookId;
            qt.SBQQ__PricebookId__c = pricebookId;
            lstQuotes.add(qt);
        }
        return lstQuotes;
    }
    /******************************************************************************************************************************************************************
    * Author: Garth James
    * Company: Salesforce
    * Description: returns Case list, size of this list will be equal to numRecords
    * Inputs : Integer, Account, List<String>, Boolean
    * History :
    ******************************************************************************************************************************************************************/
    public static List<Case> returnCases(Integer numRecords, String recordType, Account account, Contact contact, User user)
    {
        List<Case> lstCases = new List<Case>();

        RecordType rt = IMCDUtils.getRecordType('Case', recordType); // at the time of writing this could be 'Sample_Request' or 'Temporary_Product'

        for (Integer i = 0; i < numRecords; i++)
        {
            Case c = new Case();
            if(account!=null) {c.AccountId = account.Id;}
            if(contact!=null) {c.ContactId = contact.Id;}
            if(user!=null) {c.OwnerId = user.Id;}
            System.debug('TRying to create for user : ' + user.Id);
            c.RecordTypeId = rt.Id;
            lstCases.add(c);
        }
        return lstCases;
    }
    
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: Creates and return list of Contracted Prices for a provided Account and List of Products with random price
    * Inputs : Integer, Account, Product
    * History :
    ******************************************************************************************************************************************************************/
    public static List<SBQQ__ContractedPrice__c> createContractedPrices(Integer numRecords, Account account, List<Product2> products)
    {
        List<SBQQ__ContractedPrice__c> lstPrice = new List<SBQQ__ContractedPrice__c>();

        for (Integer i = 0; i < numRecords; i++)
        {
            for (Product2 prod : products) {
            	SBQQ__ContractedPrice__c price = new SBQQ__ContractedPrice__c();
    			price.SBQQ__Account__c = account.Id;
            	price.SBQQ__Product__c = prod.Id;
            	price.SBQQ__Price__c = TestDataFactoryUtils.getRandomNumber(1000);
	            lstPrice.add(price);
			}
        }
        
        insert lstPrice;
        return lstPrice;
    }

	/******************************************************************************************************************************************************************
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Creates and return list of IMCD Company records 
    * Inputs : List<String> IMCD Company Numbers
    * History :
    ******************************************************************************************************************************************************************/
    public static List<ImcdCompany__c> createImcdCompanies(List<String> companyNumbers){
        List<ImcdCompany__c> imcdCompaniesToCreate = new List<ImcdCompany__c>();
        for(String eachCompanyNumber : companyNumbers){
            ImcdCompany__c eachCompany = new ImcdCompany__c();
            eachCompany.Name = eachCompanyNumber;
            eachCompany.IMCDCompany__c = eachCompanyNumber;
            imcdCompaniesToCreate.add(eachCompany);
        }
        insert imcdCompaniesToCreate;
        return imcdCompaniesToCreate;
    }

	/******************************************************************************************************************************************************************
    * Author: Nimil Christopher
    * Company: Salesforce
    * Description: Creates and return list of Quotes 
    * Inputs : Integer - number of records, account - ID of account to link qoute to, userLinked - Set SBQQ__SalesRep__c field
    * History :
    ******************************************************************************************************************************************************************/
    public static List<SBQQ__Quote__c> createQuotes(Integer numberOfRecords, Account account, User userLinked){
        List<SBQQ__Quote__c> imcdQuotesToCreate = new List<SBQQ__Quote__c>();
        for(Integer index = 0 ; index < numberOfRecords ; index++){
            SBQQ__Quote__c quoteToCreate = new SBQQ__Quote__c(SBQQ__Account__c = account.Id, SBQQ__SalesRep__c = userLinked.Id);
            imcdQuotesToCreate.add(quoteToCreate);
        }
        insert imcdQuotesToCreate;
        return imcdQuotesToCreate;
    }

    /******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description:  Creates and return single quote with a a list of quote lines
    *               LOB values carried over from the account
    * Inputs :
    * History :
    ******************************************************************************************************************************************************************/
    public static SBQQ__Quote__c createQuoteWithLines (RecordType rt, String quoteType, Account account, Contact contact, ID salesRepId, List<Product2> lstProduct, String quoteStatus) {

        SBQQ__Quote__c newQuote = new SBQQ__Quote__c (
                recordTypeId = rt.Id
                , SBQQ__Account__c = account.Id
                , SBQQ__SalesRep__c = salesRepId
                , SBQQ__Status__c = quoteStatus
                , QuoteType__c = quoteType
                , SBQQ__Type__c = quoteType
                , SBQQ__QuoteLanguage__c = 'English'
                , CurrencyIsoCode = 'EUR'
                , QuoteExpirationDate__c = system.today() + 30
                , PriceValidityFrom__c = system.today()
                , PriceValidityTo__c = system.today() + 30
                , LOB1__c = account.Primary_LOB1__c
                , LOB2__c = account.Primary_LOB2__c
                , LOB3__c = account.Primary_LOB3__c
                , SBQQ__PriceBook__c = Test.getStandardPricebookId()
		        , SBQQ__PrimaryContact__c = contact.Id
        );

        insert newQuote;

        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>();

        ID quoteLineRtId;

        switch on quoteType {
            when 'OpportunityQuote' { quoteLineRtId = IMCDUtils.getRecordType('SBQQ__QuoteLine__c', 'OpportunityQuoteLine').Id; }
            when 'CustomerQuote' { quoteLineRtId = IMCDUtils.getRecordType('SBQQ__QuoteLine__c', 'CustomerQuoteLine').Id; }
            when 'SingleQuote' { quoteLineRtId = IMCDUtils.getRecordType('SBQQ__QuoteLine__c', 'SingleQuoteLine').Id; }
            when else { quoteLineRtId = IMCDUtils.getRecordType('SBQQ__QuoteLine__c', 'OpportunityQuoteLine').Id; }
        }

        for (product2 prod : lstProduct) {
            List<SBQQ__QuoteLine__c> ql = returnQuoteLine(1, newQuote.Id, prod.Id); // return a list of 1...
            ql[0].RecordTypeId = quoteLineRtId;
	        ql[0].SBQQ__Quote__c = newQuote.Id;
            ql[0].PriceValidityStart__c = system.today() - 10;
            ql[0].PriceValidityEnd__c = system.today() + 30;
            Integer quantity = TestDataFactoryUtils.getRandomNumber(10000);
            ql[0].SBQQ__Quantity__c = quantity;
            ql[0].Quant__c = quantity;
            ql[0].UOM__c = TestDataFactoryUtils.getRandomPickListValue(new SBQQ__QuoteLine__c(), 'UOM__c');
            ql[0].CurrencyIsoCode = 'EUR';
            ql[0].SBQQ__ListPrice__c = 0;
            ql[0].SBQQ__SpecialPrice__c = 100;
            ql[0].SetContracted__c = false;
	        ql[0].PricePerUOM__c = 100;
            lstQuoteLine.add(ql[0]);
        }

        insert lstQuoteLine; // insert 'm all
        return newQuote;
    }
    
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: create a Discount Schedule with two discount tiers
    * History :
    ******************************************************************************************************************************************************************/
    public static SBQQ__DiscountSchedule__c createDiscountSchedule(Id pricebookId, Id prodId){
        SBQQ__DiscountSchedule__c discountSchedule = new SBQQ__DiscountSchedule__c();
        discountSchedule.SBQQ__Pricebook__c  = pricebookId;
        discountSchedule.SBQQ__Product__c  = prodId;
        insert discountSchedule;
        return discountSchedule;
    }

	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: create 3 discount tiers for a provided discount schedule
    * History :
    ******************************************************************************************************************************************************************/
    public static List<SBQQ__DiscountTier__c> createDiscountTier(SBQQ__DiscountSchedule__c discountSchedule){
        List<SBQQ__DiscountTier__c> discountTiers = new List<SBQQ__DiscountTier__c>();
        discountTiers.add(new SBQQ__DiscountTier__c ( SBQQ__Schedule__c = discountSchedule.Id, SBQQ__LowerBound__c = 1, SBQQ__UpperBound__c = 100,
                                            	SBQQ__Discount__c = 5, Name = 'Tier 1') );
        discountTiers.add(new SBQQ__DiscountTier__c ( SBQQ__Schedule__c = discountSchedule.Id, SBQQ__LowerBound__c = 100, SBQQ__UpperBound__c = 200,
                                            	SBQQ__Discount__c = 10, Name = 'Tier 2') );
        discountTiers.add(new SBQQ__DiscountTier__c ( SBQQ__Schedule__c = discountSchedule.Id, SBQQ__LowerBound__c = 200,
                                            	SBQQ__Discount__c = 15, Name = 'Tier 3') );
        

        insert discountTiers;
        return discountTiers;
    }

    /******************************************************************************************************************************************************************
    * Author: Eli Pogorelov
    * Company: Salesforce
    * Description: Creates and return list of RecordTypesIds
    * History :
    ******************************************************************************************************************************************************************/
    public static void createRecordTypeIds()
    {
        RecordTypeIds__c recordTypeIds = new RecordTypeIds__c();
        recordTypeIds.RTIDCaseSampleRequest__c = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sample Request').getRecordTypeId();
        recordTypeIds.RTIDCaseTemporaryProduct__c = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Temporary Product').getRecordTypeId();
        recordTypeIds.RTIDProduct2Product__c = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        recordTypeIds.RTIDProduct2TempProduct__c = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Temp Product').getRecordTypeId();
        recordTypeIds.RTIDQuoteOpportunityQuote__c = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Opportunity Quote').getRecordTypeId();
        recordTypeIds.RTIDrtQuoteCustomer__c = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Customer Quote').getRecordTypeId();
        recordTypeIds.RTIDrtQuoteLineCustomer__c = Schema.SObjectType.SBQQ__QuoteLine__c.getRecordTypeInfosByName().get('Customer Quote Line').getRecordTypeId();
        recordTypeIds.RTIDrtQuoteLineOpportunity__c = Schema.SObjectType.SBQQ__QuoteLine__c.getRecordTypeInfosByName().get('Opportunity Quote Line').getRecordTypeId();
        recordTypeIds.RTIDrtQuoteOpportunity__c = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Opportunity Quote').getRecordTypeId();
        recordTypeIds.RTIDrtrtQuoteLineRenewal__c = Schema.SObjectType.SBQQ__QuoteLine__c.getRecordTypeInfosByName().get('Renewal Quote Line').getRecordTypeId();
	    recordTypeIds.RTIDrtQuoteLineSingle__c = Schema.SObjectType.SBQQ__QuoteLine__c.getRecordTypeInfosByName().get('Single Quote Line').getRecordTypeId();
        recordTypeIds.RTIDrtrtQuoteRenewal__c = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Renewal Quote').getRecordTypeId();
        insert recordTypeIds;
    }
   
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: Creates and returns list of price books
    * History :
    ******************************************************************************************************************************************************************/
    public static list<Pricebook2> createDefaultPricebooks() {    
		Map<String, String> comps = new Map<String, String>();
		List<PriceBook2> lstPb = new List<PriceBook2>();

		comps = TestDataFactoryUtils.getPicklistValueLabels(new Pricebook2(), 'ImcdCompany__c');

		for (String compkey : comps.keyset()) {
        	lstPb.add(
        		new Pricebook2 (IntegrationId__c=compkey,IsActive=true, ImcdCompany__c=compkey, Name=comps.get(compkey) + ' (' + compkey + ')', DefaultCurrencyIsoCode__c='EUR')
        	);    
		}

		upsert lstPb;
		return lstPb;
    }
	
    /******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: Returns number of Debug errors (to be used in assertions)
    * 			   --> System.assertEquals(0, TestDataFactory.numDebugErrors(), TestDataFactory.getDebugErrors());
    * History :
    ******************************************************************************************************************************************************************/
    public static Integer numDebugErrors() {
        return ([SELECT Id FROM DebugLog__c].size());
    }
    
	/******************************************************************************************************************************************************************
    * Author: Jeroen Burgers
    * Company: Salesforce
    * Description: Returns Debug errors (to be used in assertions)
	*			   --> System.assertEquals(0, TestDataFactory.numDebugErrors(), TestDataFactory.getDebugErrors());
    * History :
    ******************************************************************************************************************************************************************/
    public static List<DebugLog__c> getDebugErrors () {
        return ([SELECT Comments__c, Error_Type__c, LineNumber__c, Message__c, Severity__c, Stack_Trace__c, StackTraceString__c, TypeName__c FROM DebugLog__c]);
    }

   /******************************************************************************************************************************************************************
   * Author: Eli Pogorelov
   * Company: Salesforce
   * Description: returns single QuoteLine
   * History :
   **********************************************************************************************************************/
   public static SBQQ__QuoteLine__c returnSingleQuoteLine(Id qtId, Id testProductId)
   {
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtId,
        SBQQ__Product__c = testProductId,
        Stage__c = 'Identified');
        return testQuoteLine;
   }
}