public  class PriceRenewalCampaignUtils {
/******************************************************************************************************************************************************************
* Author:         Wim van Beek
* Company:     Salesforce / NNcourage
* Description: PriceRenewalCampaign Utils
* Test Class : TestPriceRenewalCampaign
* History :      New 4-2018.
*       13-11-2018. Changes to fix the 200K record issue
******************************************************************************************************************************************************************/

    // https://developer.salesforce.com/docs/atlas.en-us.cpq_api_dev.meta/cpq_api_dev/cpq_api_get_started.htm
    // QuoteModel to Create Quotes and QuoteLines via CPQ-api
    public static String quoteTypeRenewal = 'Renewal';
    public static String quoteTypeCustomer = 'Customer';
    public static String quoteTypeSingle = 'Single';
    Public Static String theUserId;
    public static Integer processNrOfPurchasePrices = 250;  // Max nr of entries to process in PBE



    public class myException extends Exception {}

    // The Qmodel is copied from https://developer.salesforce.com/docs/atlas.en-us.cpq_api_dev.meta/cpq_api_dev/cpq_api_get_started.htm

    public class QuoteModelReturn {
        public SBQQ__Quote__c record;
        public QuoteModelExt ui_original_record; 
        public List<QLrecord> lineItems;
        public Integer nextKey;   // Required
        public Boolean hasMultiSegmentLines;
        Public List<Map<String, String>> lineItemGroups;
    }
 
    public class QLrecord {
        public SBQQ__QuoteLine__c record;
        public QuoteModelExt ui_original_record;        
    }

    public class QuoteModelExt {// New CPQ version 216
        public boolean cloneRecordIfNoCache;// New CPQ version 216
        public String cacheName;// New CPQ version 216
        public String cacheId;// New CPQ version 216
        public List<String>  cachedOriginalRecordPath ; // New CPQ version 216
    }

    public class QuoteModel {   
        public SBQQ__Quote__c record;
        public List<QuoteLineModel> lineItems = new List<QuoteLineModel>();
        public List<QuoteLineGroupModel> lineItemGroups = new List<QuoteLineGroupModel>();
        public Integer nextKey;   // Required
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;
        public Boolean hasMultiSegmentLines;  // Not documented
        public Integer currencyDecimalScale;  // Not documented
    }

    public class QuoteLineModel {
        public SBQQ__QuoteLine__c record;
        public Boolean amountDiscountProrated;
        public Integer parentGroupKey;
        public Integer parentItemKey;
        public Integer key;   // Required
        public Boolean upliftable;
        public String  configurationType;
        public String  configurationEvent;
        public Boolean reconfigurationDisabled;
        public Boolean descriptionLocked;
        public Boolean productQuantityEditable;
        public Decimal productQuantityScale;
        public String  dimensionType;
        public Boolean productHasDimensions;
        public Decimal targetCustomerAmount;
        public Decimal targetCustomerTotal;
    }
    public class QuoteLineGroupModel {
        public SBQQ__QuoteLineGroup__c record;
        public Decimal netNonSegmentTotal;
        public Integer key;
    }

    // Temp storage of data before creating Quote and Quoteline via QuoteModel
    public class Campaign2QuoteModel{
        public  Map<Id, SBQQ__ContractedPrice__c> oldcontractprices = new Map<Id, SBQQ__ContractedPrice__c>();
        public  List<Campaign2QuoteModelItem> items = new List<Campaign2QuoteModelItem>();
    }

    public class Campaign2QuoteModelItem{
        public  PriceRenewalCampaignItem__c item;
        public  Id oldcontractpriceId;
    }

        // Big table precausion 30-10-18 
        public static Map<Id,PriceRenewalCampaign__c> thePRC {get{
            if (thePRC == null){
                thePRC = new Map<Id,PriceRenewalCampaign__c>([SELECT id FROM PriceRenewalCampaign__c 
                                                                        WHERE OwnerId = : theUserId
                                                                        AND   Stage__c = 'Queued']) ;
            }
            return thePRC;
            }set;}
       




    // Create Schedulerentries per user(ownerId) for PRC
    public static void startSchedulder(Id userId, Date startDate, String mode){  // Start the scheduler. type = 'day' or 'next'
        String jobID, cron;
        String cronName = 'PRC_' + mode + '_' + userId;  //Unique name per user
        if (mode == 'day' ) {  // Mode=Day will start the scheduler during the night of the user
            if (startDate == null  || startDate <= Date.today()) {   // Urgent! startdate has expired, will start direct
                  cron = '59 ' + String.valueof(Datetime.now().minute()) + ' * * * ?' ;
                  startSchedulder(userId, null, 'next');
            } else {
                cron = '1 1 0 * * ?'; // Normal nightrun. Will run during the night of the User.s
            }
        }
        if (mode == 'next'){  // Typical every minute until all processing has been done
            cron = '10 ' + string.valueOf(DateTime.now().addMinutes(1).minute())  + ' * * * ?' ;
        }
     
        // Set the scheduler active. If already running, error will be ignored
        try {
        jobID = system.schedule(cronName  ,cron, new PriceRenewalCampaignSchedule ());
           } catch (exception e){
            system.debug('------ Failed to start' + cron ); // Typical error: Entry already exist, No logging needed, can be ignored
        }
    }

    @Future  // Run every 'next' run. Here we do the actual work
    public static void futureProcessing(Id userId){  // Process all updates in futures

            if (processingPurchasePrice(userId) ){  // If no Purchaseprices to be updated
                processingContractedPrice(userId) ;  // Update Contracted price
            }
            closeCampaigns(userId);  // Close Campaign if all items are done
    }

/******************************************************************************************************************************************************************
 * Author:      Wim van Beek
 * Company:     Salesforce / NNcourage
 * Description: Purchase prices update (PriceBookEntry) and create of PriceHistory. Process only owned PRC's
 * History :    New 5-18
 ******************************************************************************************************************************************************************/

    public static boolean processingPurchasePrice(Id userId){
        theUserId = userId;
        Map<Id, PriceRenewalCampaignItem__c> priceRenewalCampaignItemMap = new  Map<Id, PriceRenewalCampaignItem__c>();
        Map<id, PriceBookEntry> priceBookEntryMap = new  Map<id, PriceBookEntry>();

        // Collect Items to process. Limit to avoid process limits
        system.debug('------ thePRC '+ thePRC);
        for (PriceRenewalCampaignItem__c PCI:   [SELECT 
                                                        Id, 
                                                        Status__c, 
                                                        TF_PriceBookEntry__c, 
                                                        NewPrice__c ,  
                                                        PriceRenewalCampaign__c
                                                    FROM  PriceRenewalCampaignItem__c
                                                    WHERE PriceRenewalCampaign__c =: thePRC.keySet()
                                                        AND   TF_PriceBookEntry__c != NULL
                                                        AND   PriceRenewalCampaign__r.EffectiveDate__c <= : Date.today()  // Wait here for effective date
                                                        AND   Status__c != 'Processed' 
                                                    LIMIT : processNrOfPurchasePrices]){
            PCI.Status__c = 'Processed';
            priceRenewalCampaignItemMap.put(PCI.TF_PriceBookEntry__c,PCI);
            // Update PriceBookEntry. Only Id and UnitPrice are needed
            priceBookEntryMap.put(PCI.TF_PriceBookEntry__c, new PriceBookEntry(
                id = PCI.TF_PriceBookEntry__c,
                UnitPrice = PCI.NewPrice__c
                ));
        }

        // Fill PriceHistory object
        List<PriceHistory__c> priceHistoryList = new List<PriceHistory__c>();
        for (PriceBookEntry PBE:    [SELECT UnitPrice, 
                                            CurrencyIsoCode, 
                                            Pricebook2id, 
                                            Id, 
                                            Product2id
                                        FROM PriceBookEntry
                                        WHERE Id =: priceBookEntryMap.keyset()]){
            priceHistoryList.add(new PriceHistory__c(
                CurrencyIsoCode = PBE.CurrencyIsoCode,
                OldValue__c = PBE.UnitPrice,
                PriceBookEntry__c = PBE.Id,
                NewValue__c = priceBookEntryMap.get(PBE.id).UnitPrice,
                PriceRenewalCampaign__c = priceRenewalCampaignItemMap.get(PBE.id).PriceRenewalCampaign__c,
                PriceBook__c = PBE.Pricebook2id,
                Product__c = PBE.Product2id
                ));
        }
        update priceBookEntryMap.values();
        insert priceHistoryList;
        update priceRenewalCampaignItemMap.values();
        return priceBookEntryMap.isEmpty();
    }

    // Close Campaign if all done. If 
    public static void closeCampaigns(Id  userId){  
        List<PriceRenewalCampaign__c> priceRenewalCampaignList = new List<PriceRenewalCampaign__c>();

        // Get all Campaigns of the user.
        // if PriceRenewalCampaignItem__r.Status__c == 'Error', campaign will not be closed

        for (PriceRenewalCampaign__c PRC: [SELECT 
                                            Id, 
                                            Stage__c
                                        FROM PriceRenewalCampaign__c
                                        WHERE OwnerId =: userId
                                        AND   Stage__c = 'Queued'
                                        AND   Id
                                        NOT IN
                                            (SELECT PriceRenewalCampaign__c
                                                    FROM PriceRenewalCampaignItem__c
                                                    WHERE Status__c != 'Processed')]){
            PRC.Stage__c = 'Processed';
            priceRenewalCampaignList.add(PRC);
        }
        update priceRenewalCampaignList;
    }

    // Check if All processing is done. Use to stop renewal of scheduler-run
    public static Boolean allCampaignsDone(Id  userId){
            return  ([SELECT Id, Stage__c    FROM PriceRenewalCampaign__c
                                            WHERE OwnerId =: userId
                                                AND Stage__c = 'Queued'
                                            LIMIT 1 ].isEmpty());
    }

    // Check if processing Items are done. Use to stop renewal of scheduler-run
    public static Boolean allCampaignsItemsDone(Id  userId){
        theUserId = userId;
        thePRC = null;
        return  ([SELECT Id 
                            FROM    PriceRenewalCampaignItem__c 
                            WHERE   PriceRenewalCampaign__c =: thePRC.keyset()
                            AND     Status__c != 'Processed'
                            AND     ContractedPrice__c != null   // New 18-12-18 
                            AND     Status__c != 'Error' LIMIT 1].isEmpty());
    }

/******************************************************************************************************************************************************************
* Author:       Wim van Beek
* Company:      Salesforce / NNcourage
* Description:  processingContractedPrice
*                   Transfers contracted price into Renewal Quotes
*                   Not bulkify, just prepaired for it. Hard limit is in the CPQ-API as this is not bulkify. 
*                   We process only 1 Quote with 1 or more quotelines
*                   Mark items as 'Processed' to signoff the record
* Inputs :      UsedId from owner of PriceRenewal Campains
* Output:       Created 1 Quote with QuoteLines
* Test Class :  TestPriceRenewalCampaign

* History :     New 5-2018.
*               Updted, 12-18 Multiple loops, limits protected
******************************************************************************************************************************************************************/

    public static void processingContractedPrice(Id userId){
        theUserId = userId;
        List<String> itemNoProcess = new List<String>{'Processed','Error'} ;
        Map<Id, PriceRenewalCampaignItem__c> priceRenewalCampaignItemMap = new  Map<Id, PriceRenewalCampaignItem__c>();

        // Limit 1 to find first only
        for (Integer I = 0; I < 5; I++){
            if ( IMCDUtils.limitsWithinRange(50) == false ){break; } // Estimate 10% per Quote Nov18
            thePRC = null;  // Init array

            // Get ONE entry as step 1.

            priceRenewalCampaignItemMap.clear();
            for (PriceRenewalCampaignItem__c  campaignItem  : [SELECT 
                                                                Account__c,  
                                                                Account__r.Primary_LOB1__c,
                                                                ContractedPrice__r.Incoterms__c,
                                                                ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c,
                                                                ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c,
                                                                PriceRenewalCampaign__c, 
                                                                CurrencyIsoCode
                                                            FROM PriceRenewalCampaignItem__c
                                                            WHERE PriceRenewalCampaign__c =: thePRC.keyset()
                                                                AND   ContractedPrice__c != NULL
                                                                AND   Status__c != : itemNoProcess 
                                                            LIMIT 1]){
                // Collect all related objects in step 2
                Campaign2QuoteModel campaign2Quotemodel = new Campaign2QuoteModel();

                // New 8-18 Limit nr of QL
                Integer qlimit = 30;
                for (RPCsettings__mdt settings :[ SELECT QueryLimit__c FROM RPCsettings__mdt WHERE QueryLimit__c != NULL]){
                    qlimit = Integer.valueOf(settings.QueryLimit__c);
                }
     
                // Get all items related to step 1
                for (PriceRenewalCampaignItem__c pci: [SELECT 
                                                            id, 
                                                            Status__c,  
                                                            NewPrice__c, 
                                                            Product__c,
                                                            Account__c,
                                                            ContractedPrice__c ,
                                                            ContractedPrice__r.Incoterms__c,
                                                            Quantity__c,
                                                            CurrencyIsoCode,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.PriceRestriction__c,
                                                            PriceRenewalCampaign__r.TF_TemplateId__c,
                                                            PriceRenewalCampaign__r.EmailTemplate__c,
                                                            PriceRenewalCampaign__r.ValidFrom__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.TF_PreviousPrice__c,
                                                            PriceRenewalCampaign__r.ValidTo__c,
                                                            Account__r.PaymentTerm__c,
                                                            Account__r.OwnerId,
                                                            Account__r.CorrespondenceLanguage__c,
                                                            PriceRenewalCampaign__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c, 
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__c, 
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__Pricebook__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB1__c,  // New 7-8-18
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB2__c,  // New 7-8-18
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB3__c,  // New 7-8-18
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipFromCity__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.Ship_From_Country__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipFromPostalCode__c,
                                                            ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipFromStreet__c


                                                        FROM    PriceRenewalCampaignItem__c
                                                        WHERE   PriceRenewalCampaign__r.OwnerId =: userId
                                                            AND     ContractedPrice__c != NULL
                                                            AND     Status__c != 'Processed'
                                                            AND     Status__c != 'Error'
                                                            AND     CurrencyIsoCode = : campaignItem.CurrencyIsoCode
                                                            AND     Account__c = : campaignItem.Account__c
                                                            AND     ContractedPrice__r.Incoterms__c =: campaignItem.ContractedPrice__r.Incoterms__c  // Added 22-11-2018
                                                            AND     PriceRenewalCampaign__c = : campaignItem.PriceRenewalCampaign__c
                                                   //         AND     Account__r.Primary_LOB1__c = : campaignItem.Account__r.Primary_LOB1__c  // Removed 2-8-18
                                                            AND     ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c = : campaignItem.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c
                                                            AND     ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c = : campaignItem.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c
                                                        ORDER BY ContractedPrice__r.SBQQ__EffectiveDate__c 
                                                        LIMIT : qlimit]){

                    // Build intermedium class and update status
                    pci.Status__c = 'Processed';
                    // Collect all data in temp-structure as first step
                    priceRenewalCampaignItemMap.put(pci.id,pci);
                    Campaign2QuoteModelItem campaign2QuoteLinemodel = new Campaign2QuoteModelItem();
                    campaign2QuoteLinemodel.oldcontractpriceId = pci.ContractedPrice__c;
                    campaign2Quotemodel.oldcontractprices.put(campaign2QuoteLinemodel.oldcontractpriceId, null);
                }

                // Collect oldcontracts elements 
                campaign2Quotemodel.oldcontractprices = new Map<Id, SBQQ__ContractedPrice__c>
                                                                ([SELECT 
                                                                    Id, 
                                                                    CurrencyIsoCode, 
                                                                    Quantity__c, 
                                                                    UOM__c,
                                                                    Incoterms__c,
                                                                    SBQQ__Product__c,
                                                                    SBQQ__EffectiveDate__c, 
                                                                    SBQQ__ExpirationDate__c, 
                                                                    SBQQ__Price__c,
                                                                    SBQQ__OriginalQuoteLine__r.TF_PreviousPrice__c,
                                                                    SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c,
                                                                    SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.PriceRestriction__c
                                                                FROM SBQQ__ContractedPrice__c
                                                                WHERE Id =: campaign2Quotemodel.oldcontractprices.keyset()]);

                
                // All data has been collected for 1 run. Writing is try-secured
                try {   // Catch any error and store in Debuglog. Mark item as Error
                    createQuoteAndLines(priceRenewalCampaignItemMap , campaign2Quotemodel);  
                }
                catch (Exception ex){
                    String errMsg = ex.getMessage() + ' Line ' + String.valueOf(ex.getLineNumber());
                    DebugLog.addError( 'Creation of Quote failed '+ errMsg);
                    for ( PriceRenewalCampaignItem__c campaintItem :  PriceRenewalCampaignItemMap.values()){
                        campaintItem.Status__c = 'Error';
                        campaintItem.Error__c  = errMsg.right(255);
                    }
                }

            }
            if (PriceRenewalCampaignItemMap.size() == 0){break;}
            update PriceRenewalCampaignItemMap.values();
        } // Next loop
    }


    // Move related fields to  QuoteMode and save Quote/Lines
    public static void createQuoteAndLines(Map<id, PriceRenewalCampaignItem__c> priceRenewalCampaignItemMap, Campaign2QuoteModel campaign2Quotemodel){

        // Fill quote and save into Quotemodel       
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.RecordTypeId = IMCDUtils.getRecordType('SBQQ__Quote__c','RenewalQuote').id;
        quote.QuoteType__c = 'Renewal';         
        QuoteModel QModel = new QuoteModel();
        QModel.record = quote;
        system.debug('------ quote '+ quote);
        // QuoteLine
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for (PriceRenewalCampaignItem__c pci : priceRenewalCampaignItemMap.values() ){
            if (quoteLines.size() == 0){
                // Initial values for Quote
                quote.SBQQ__Pricebook__c =  pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__Pricebook__c;
                quote.SBQQ__PricebookId__c = quote.SBQQ__Pricebook__c;
                quote.Incoterms2__c = pci.ContractedPrice__r.Incoterms__c;

                quote.SBQQ__PrimaryContact__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c;  // New 12-18 SFDP-2160

                quote.EmailTemplate__c = pci.priceRenewalCampaign__r.EmailTemplate__c;
                quote.PriceValidityFrom__c = pci.priceRenewalCampaign__r.ValidFrom__c;
                quote.PriceValidityTo__c = pci.priceRenewalCampaign__r.ValidTo__c;
                quote.SBQQ__Account__c = pci.Account__c;
                quote.OwnerId = pci.Account__r.OwnerId;
                quote.CurrencyIsoCode =  pci.CurrencyIsoCode;
                quote.LOB1__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB1__c;
                quote.LOB2__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB2__c;
                quote.LOB3__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.LOB3__c;
                quote.ImcdCompanyLookup__c  = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ImcdCompanyLookup__c;
                quote.SBQQ__SalesRep__c = quote.OwnerId;
                quote.PriceRenewalCampaign__c = pci.PriceRenewalCampaign__c;
                quote.SBQQ__PrimaryContact__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c;
                quote.ShiptoAddress__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c;
                // New 19-11-2018
                quote.ShipFromCity__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipFromCity__c;
                quote.Ship_From_Country__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.Ship_From_Country__c;
                quote.ShipFromPostalCode__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipFromPostalCode__c;
                quote.ShipFromStreet__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipFromStreet__c;

                quote.PriceRestriction__c = pci.ContractedPrice__r.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.PriceRestriction__c;
                String accLang = pci.Account__r.CorrespondenceLanguage__c;

                // Check for allowed and correct language setting. Needed for Batched Quote-doc sending
                if (accLang != null){
                    Set<String> allowdCountries = new Set<String>();
                    for (Schema.PicklistEntry countryList : SBQQ__Quote__c.SBQQ__QuoteLanguage__c.getDescribe().getPicklistValues()){
                        allowdCountries.add(countryList.getLabel());
                    }

                    for (Schema.PicklistEntry countryList : Account.CorrespondenceLanguage__c.getDescribe().getPicklistValues()){
                        if (countryList.getValue() == accLang.left(2)){
                            if (allowdCountries.contains(countryList.getLabel())){
                                quote.SBQQ__QuoteLanguage__c =  countryList.getLabel();
                            }
                        }
                    }
                }
                // Optional, go for 'English'
                quote.SBQQ__QuoteLanguage__c = (quote.SBQQ__QuoteLanguage__c == null ? quote.SBQQ__QuoteLanguage__c = 'English' : quote.SBQQ__QuoteLanguage__c);

            }  // Quote is filled

        system.debug('------ quote '+ quote);

            // Get ContractedPrice
            SBQQ__ContractedPrice__c cp =  campaign2Quotemodel.oldcontractprices.get(pci.ContractedPrice__c);

            // Create Quoteline
            SBQQ__QuoteLine__c quoteLine = returnQuoteLines(cp);
   //         quoteLine.NewPrice__c = Pci.NewPrice__c;  // Update Newprice from CampaignItem // Removed 31-10-18
            quoteLine.SBQQ__Number__c = QModel.lineItems.size() + 1;
            quoteLine.PriceValidityStart__c = pci.PriceRenewalCampaign__r.ValidFrom__c;
            quoteLine.PriceValidityEnd__c = pci.PriceRenewalCampaign__r.ValidTo__c;
            quoteLine.PricePerUOM__c = Pci.NewPrice__c ;
            quoteLine.ProposedUOMprice__c = quoteLine.PricePerUOM__c;
            quoteLine.SBQQ__CustomerPrice__c  = 0; // new per Okt18
            quoteLine.SBQQ__NetPrice__c  = 0; // new per Okt18
      //      quoteLine.SBQQ__SpecialPrice__c   = quoteLine.PricePerUOM__c; // new per Okt18
       
            QuoteLineModel QmodelLine = new QuoteLineModel();
            QmodelLine.record = quoteLine;
            QModel.lineItems.add(QmodelLine);
            quoteLines.add(quoteLine);
            QmodelLine.key = QModel.lineItems.size() + 1;
            QModel.nextKey = QmodelLine.key + 1;
        }
        // Create Quote + QuoteLines now with the Quote-API
        // https://developer.salesforce.com/docs/atlas.en-us.cpq_api_dev.meta/cpq_api_dev/cpq_api_types_parent.htm.
        system.debug('------ QModel '+ JSON.serialize(QModel));

        String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(QModel));
        system.debug('------ quoteJSON '+ quoteJSON);
    }

            // New 19-11-2018  Reset all lines in error to restart items for PriceRenewalCampaigns. Select all Items marked Error and set to 'Updated'
    public Static void resetItemErrors(Id UserId){
        List<PriceRenewalCampaignItem__c> newItems = new List<PriceRenewalCampaignItem__c>();
        for (PriceRenewalCampaignItem__c items: [SELECT id, Name, Status__c FROM PriceRenewalCampaignItem__c 
                                                    WHERE PriceRenewalCampaign__r.OwnerId =: UserId
                                                    AND   Status__c = 'Error'
                                                    LIMIT 990]){
            items.Status__c = 'Updated';
            newItems.add(items);
        }
        update newItems;
    }

    
/******************************************************************************************************************************************************************
* Author:           Wim van Beek
* Company:          Salesforce / NNcourage
* Description:      createContractedPrices
*                       Get QuoteLines and convert them to Contracted prices.
* Inputs :          List Id's from Quote, Opportunity and/or QuoteLine
* Output:           Created/updated Contracted Prices
* Test Class :      TestPriceRenewalCampaign
* History :         New 5-2018.
*                   Support isoluated future CP
******************************************************************************************************************************************************************/

    public static void createContractedPrices(List<Id> quoteOrOpportunityId){
        system.debug('------ quoteOrOpportunityId '+ quoteOrOpportunityId);
        if (System.isScheduled() == true || System.isFuture() == true ){return ;}  // New 3-8-18

        List<Id> accountIds = new List<Id>();
        List<Id> productIds = new List<Id>();
        Map<String, SBQQ__QuoteLine__c> quoteLineMapProduct = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, SBQQ__QuoteLine__c> quoteLineMapQL = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, SBQQ__ContractedPrice__c> contractedPriceUpsert = new Map<String, SBQQ__ContractedPrice__c>();

        Map<String, SBQQ__ContractedPrice__c> contractedPricePrevMap = new Map<String, SBQQ__ContractedPrice__c>();
        Map<String, SBQQ__ContractedPrice__c> contractedPriceLASTMap = new Map<String, SBQQ__ContractedPrice__c>();
        Map<Id, String> quoteLineProductKey = new Map<Id, String>();

        List<String> quoteStatusOk = new List<String>{'Presented','Accepted','Confirmed'} ;
        List<String> oppStatusOk = new List<String>{'Closing','Won'} ;
        List<String> quoteLinesStatusFault = new List<String>{'Lost'} ;
        Map<Id, Id> discountPerquoteLine = new Map<Id, Id>();
        Map<Id, Id> changedDiscount = new Map<Id, Id>();
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        Map<String, String> updateStatus = new Map<String, String>();
        Map<String, SBQQ__ContractedPrice__c> theNewCP = new Map<String, SBQQ__ContractedPrice__c>();

        // Option to avoid 200k records issue
        Map<id, SBQQ__Quote__c> quoteMap = new Map<id, SBQQ__Quote__c>();
        if (quoteOrOpportunityId.size() > 0 && String.valueOf(quoteOrOpportunityId[0]).left(3) == Schema.getGlobalDescribe().get('Opportunity').getDescribe().getKeyPrefix() ){
            quoteMap = new Map<id, SBQQ__Quote__c>([SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: quoteOrOpportunityId]);
        }
        
        // Extended selection, see in line comments
        for (SBQQ__QuoteLine__c quoteLine : [SELECT Id,
                                    CurrencyIsoCode,
                                    PricePerUOM__c,
                                    PriceValidityStart__c,
                                    PriceValidityEnd__c,
                                    SBQQ__Product__c,
                                    SetContracted__c,
                                    Quant__c,
                                    BaseUOM__c,
                                    Name,
                                    UOM__c,
                                    ErrorMsg__c,
                                    Incoterms__c,
                                    UniqueKey__c,
                                    SBQQ__Quote__r.Incoterms2__c,
                                    SBQQ__Quote__c,
                                    SBQQ__Number__c,                                    
                                    SBQQ__Quote__r.ShipToAdressId__c,
                                    SBQQ__Quote__r.ShipFromCity__c,
                                    SBQQ__Quote__r.Ship_From_Country__c,
                                    SBQQ__Quote__r.ShipFromPostalCode__c,
                                    SBQQ__Quote__r.ShipFromStreet__c,
                                    SBQQ__Quote__r.PriceRestriction__c,
                                    SBQQ__Quote__r.QuoteType__c,
                                    SBQQ__Quote__r.PriceValidityFrom__c,
                                    SBQQ__Quote__r.PriceValidityTo__c,
                                    SBQQ__Quote__r.SBQQ__Account__c,
                                    SBQQ__Quote__r.SBQQ__Status__c,
                                    SBQQ__Quote__r.SBQQ__Type__c,
                                    SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                    SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName
                                FROM SBQQ__QuoteLine__c
                                WHERE SBQQ__Quote__r.SBQQ__Account__c != NULL
                                    AND  SBQQ__Quote__r.Migrated__c = false         //Migreated Quotes ignored
                                    AND  SBQQ__Product__r.IsActive = true           // Inactive Products ignored
                                    AND  SBQQ__Product__r.CanCreateCP__c = true     // 27-8-18 Was Tempproduct = false
                                    AND  SBQQ__Quote__r.SBQQ__Account__r.RecordTypeId = : IMCDUtils.recordTypeIdMap.get('Customer_Sold_To')
                                    AND  SetContracted__c = false                   // Once processed ignored
                                    AND  PricePerUOM__c != NULL                     // Need a price
                                    AND  PricePerUOM__c != 0                        // Need a price
                                    AND  Stage__c != : quoteLinesStatusFault        // Disallowed Stages
                                    AND  SBQQ__Quote__r.SBQQ__Status__c = : quoteStatusOk       // Allowed status
                                    AND (     Id = : quoteOrOpportunityId            // Get id's from QuoteLine, Quote Or apportunity
                                        OR SBQQ__Quote__c = : quoteOrOpportunityId
                               //         OR SBQQ__Quote__r.SBQQ__Opportunity2__c = : quoteOrOpportunityId // 200K record 30-10-2018
                                        OR SBQQ__Quote__c = : quoteMap.keyset()  
                                        )
                                    AND SBQQ__Quote__r.SBQQ__Status__c = : quoteStatusOk   // Allowd Quote status
                                    AND (   ( SBQQ__Quote__r.QuoteType__c = : quoteTypeRenewal 
                                                AND SBQQ__Quote__r.SBQQ__Status__c != 'Accepted')
                                            OR (    SBQQ__Quote__r.QuoteType__c = : quoteTypeCustomer
                                                AND SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName = : oppStatusOk )
                                            OR (    SBQQ__Quote__r.QuoteType__c = : quoteTypeSingle )
                                        )
                                ]){
            String updStatus ;
            String qStatus = quoteLine.SBQQ__Quote__r.SBQQ__Status__c;
            String qType = quoteLine.SBQQ__Quote__r.QuoteType__c;
            String oppStage = quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName;
            if (qStatus == 'Presented'){
                    updStatus = 'CU';  // Create update
                if (oppStage == 'Won'){
                    updStatus = 'C';  // Create 
                }
                
            }
            if (qStatus == 'Accepted' || qStatus == 'Confirmed'){
                updStatus = 'C';  // Create 
            }
            system.debug('------ qStatus '+qStatus);
            system.debug('------ qType '+qType);
            system.debug('------ oppStage '+oppStage);
            system.debug('------ updStatus '+updStatus);
            quoteline.ErrorMsg__c = null;
            if (updStatus != null){  // null means, no update
            //    String incoTerm = (quoteLine.Incoterms__c == null ? quoteLine.SBQQ__Quote__r.Incoterms2__c: quoteLine.Incoterms__c) ; 
                quoteline.SetContracted__c = true;   // Replaced this line  4-11-2018
                quoteLines.add(quoteLine); 
                String incoTerm = quoteLine.SBQQ__Quote__r.Incoterms2__c ; // Patched 7-8-18
                // Create unique ProductKey to compare with contracted prices later
   //             String productKeyQuoteLine = String.join(new List<String>{quoteLine.SBQQ__Quote__r.SBQQ__Account__c,quoteLine.SBQQ__Product__c,String.valueOf(Integer.valueOf(quoteLine.SBQQ__Quantity__c)),quoteLine.UOM__c,quoteLine.SBQQ__Quote__r.ShipToAdressId__c,incoTerm},';').toLowerCase();  
                String productKeyQuoteLine = String.join(new List<String>{quoteLine.SBQQ__Quote__r.SBQQ__Account__c,quoteLine.UniqueKey__c},';').toLowerCase();  

                updateStatus.put(productKeyQuoteLine, updStatus);

                System.debug('------ productKeyQuoteLine '+ productKeyQuoteLine);
                SBQQ__ContractedPrice__c contractedPrice = createNewContractedPrice(quoteLine);
                if (contractedPriceUpsert.get(productKeyQuoteLine) == null && contractedPrice != null) {
                    contractedPriceUpsert.put(productKeyQuoteLine, contractedPrice);  
                } 
                accountIds.add(quoteLine.SBQQ__Quote__r.SBQQ__Account__c);
                productIds.add(quoteLine.SBQQ__Product__c);
                quoteLineMapProduct.put(productKeyQuoteLine, quoteLine);
            }
                                   
        }
        if (quoteLines.size() == 0){return ;} // Na data, NoAction

        // Get existing Contracted price

        for (SBQQ__ContractedPrice__c contractedPrice:[SELECT   Id,
                                                                CurrencyIsoCode,
                                                                SBQQ__Account__c,
                                                                SBQQ__Product__c,
                                                                SBQQ__Price__c,
                                                                Quantity__c,
                                                                Number__c,
                                                                UOM__c,
                                                                Old__c,
                                                        //        Price4__c,  // 10-9-18 obsolute
                                                                UniqueKey__c,
                                                                Incoterms__c,
                                                                SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c,                                                                
                                                                SBQQ__OriginalQuoteLine__c,
                                                                SBQQ__OriginalQuoteLine__r.name,
                                                                SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.QuoteType__c,
                                                                SBQQ__EffectiveDate__c,
                                                                SBQQ__ExpirationDate__c
                                                            FROM    SBQQ__ContractedPrice__c
                                                            WHERE   SBQQ__Account__c = : accountIds
                                                            AND     SBQQ__Product__c = : productIds
                                                            AND     Old__c = FALSE
                                                            AND     DeActivate__c = FALSE
                                                            AND     SBQQ__EffectiveDate__c != NULL
                                                        ORDER BY    SBQQ__EffectiveDate__c DESC, CreatedDate DESC  // Ordering is important to get the lastest booking as first
                                                                ]){

            // This key defines an unique productentry. Key must be equaly build on Contracted Price and QuoteLine
  //          String productKeyContractedPrice = String.join(new List<String> {contractedPrice.SBQQ__Account__c,contractedPrice.SBQQ__Product__c,String.valueOf(Integer.valueOf(contractedPrice.Quantity__c)),contractedPrice.UOM__c,contractedPrice.SBQQ__OriginalQuoteLine__r.SBQQ__Quote__r.ShipToAdressId__c,contractedPrice.Incoterms__c},';').toLowerCase();  
            String productKeyContractedPrice = String.join(new List<String> {contractedPrice.SBQQ__Account__c,contractedPrice.UniqueKey__c},';').toLowerCase();  
            System.debug('------ productKeyContractedPrice '+ productKeyContractedPrice);
            SBQQ__QuoteLine__c quoteLineProduct = quoteLineMapProduct.get(productKeyContractedPrice);
            system.debug('------ quoteLineProduct '+ quoteLineProduct);  //TODO check. Skip next section if null ?? 16-10-18 WvB 
            if ( contractedPriceLASTMap.get(productKeyContractedPrice) == null   ){
                contractedPriceLASTMap.put(productKeyContractedPrice, contractedPrice );  // Store first (=last on date) Contracted Price first, skip rest
                quoteLineProductKey.put(contractedPrice.SBQQ__OriginalQuoteLine__c , productKeyContractedPrice);
            } else {
                if (contractedPricePrevMap.get(productKeyContractedPrice) == null){
                    contractedPricePrevMap.put(productKeyContractedPrice,contractedPrice);  // Store one but last Contracted price. Mark is Old
                }  else {
                    if (contractedPrice.Old__c == false){
                        contractedPrice.Old__c = true;
                        theNewCP.put(contractedPrice.id, contractedPrice); // Store old ones, mark it Old
                    }
                }             
            }
        }
        // now we have: 
        //     Most recent CP in contractedPriceLASTMap, 
        //     the one before in contractedPricePrevMap, 
        //     Older in  contractedPriceUpsert. 
        //     All in decending Effective date
        for (String key : contractedPriceUpsert.keySet() ){  // Itterate over all new created contractedPrices. contractedPriceUpsert- Map is updated, deleted or left as is
            SBQQ__ContractedPrice__c contractedPriceLast = contractedPriceLASTMap.get(key); // Last found CP
            SBQQ__ContractedPrice__c contractedPricePrev = contractedPricePrevMap.get(key); // Previous CP
            SBQQ__QuoteLine__c quoteLine = quoteLineMapProduct.get(key);
            String updStatus = updateStatus.get(key);

            if ( quoteLine != null ){
                String quoteType = quoteLine.SBQQ__Quote__r.QuoteType__c;
                String quoteStatus = quoteLine.SBQQ__Quote__r.SBQQ__Status__c;
                

                if (contractedPriceLast == null && (updStatus == 'C'  || updStatus == 'CU' )){ // key NON existed in CP, search for earlier CP of this QL 
                    Id quoteLineId = quoteLineMapProduct.get(key).id;
                    String prevKey = quoteLineProductKey.get(quoteLineId);
                    if ( prevKey != null){  // Deactive earlier version of product
                        SBQQ__ContractedPrice__c cancelCP = contractedPriceLASTMap.get(prevKey);
                        cancelCP.DeActivate__c = true;
                        if (cancelCP.SBQQ__EffectiveDate__c < Date.today()){
                            cancelCP.SBQQ__ExpirationDate__c = Date.today();  // TODO if effectice > today, expiration date = today en effective date = today ?
                        }
                        theNewCP.put(prevKey, cancelCP);
                    }
                }
                SBQQ__ContractedPrice__c tocreateCP;

                if ((updStatus == 'C'  || updStatus == 'CU' ) &&  contractedPriceLast  == null  )  { // Non Existing record, Create record now
                    tocreateCP = createNewContractedPrice(quoteLine)  ;  
                    quoteLine.PriceValidityStart__c = tocreateCP.SBQQ__EffectiveDate__c;
                    quoteLine.ErrorMsg__c  = 'New';
                }
                if ((updStatus == 'C'  ) &&  contractedPriceLast != null && quoteLine != null && contractedPriceLast.SBQQ__OriginalQuoteLine__c == quoteLine.id )  { // Existing record, Skip Update
                    quoteLine.ErrorMsg__c  = 'Skipped';
                }
                system.debug('------ tocreateCP '+tocreateCP);  // New 29-11-2018
                if ((updStatus == 'C'  ) &&  contractedPriceLast  != null && contractedPriceLast.SBQQ__OriginalQuoteLine__c != quoteLine.id )  { // Non Existing record, Create record now
                    tocreateCP = createNewContractedPrice(quoteLine)  ; 
                    system.debug('------ tocreateCP '+tocreateCP);
                    if (quoteline.SBQQ__Quote__r.QuoteType__c != 'Renewal'){ // New 29-11-2018
                        throw new myException('Contracted Price of ' + quoteLine.name + ' exist in '+ contractedPriceLast.SBQQ__OriginalQuoteLine__r.Name);
                    }
                
                }
                

                if (updStatus == 'CU' &&  contractedPriceLast  != null  )  { //  Existing record , Update record now
                    tocreateCP =  createNewContractedPrice(quoteLine)  ; 
                    quoteLine.ErrorMsg__c  = 'Update';
                    if ( contractedPriceLast.SBQQ__EffectiveDate__c < Date.today()){  // Changed 29-8-18
                        tocreateCP.SBQQ__EffectiveDate__c = contractedPriceLast.SBQQ__EffectiveDate__c; 
                        quoteLine.PriceValidityStart__c = tocreateCP.SBQQ__EffectiveDate__c;
                    }
                    tocreateCP.id =   contractedPriceLast.id;  
                }

                // New 9-1-2019 
                // SFDP-2093 One CP in future
                // Situation: New CP to be made, Current one is in future and there is no earlier CP ==> Update CP
                if ((updStatus == 'CU' || updStatus == 'C')  &&  contractedPriceLast  != null &&  contractedPricePrev == null && contractedPriceLast.SBQQ__EffectiveDate__c > Date.today())  {
                    tocreateCP =  createNewContractedPrice(quoteLine)  ; 
                    system.debug('------ tocreateCP '+ tocreateCP);
                    quoteLine.PriceValidityStart__c = tocreateCP.SBQQ__EffectiveDate__c;
            //        tocreateCP.id = contractedPriceLast.id;  // 4-2-19 
                    contractedPriceLast.SBQQ__EffectiveDate__c = Date.today().addDays(-1);  // new 4-2-19
                    contractedPriceLast.SBQQ__ExpirationDate__c = Date.today().addDays(-1); // new 4-2-19
                    contractedPriceLast.Old__c = true; // new 4-2-19
                    contractedPriceLast.DeActivate__c = true; // new 4-2-19
                    theNewCP.put(contractedPriceLast.id, contractedPriceLast);
                    quoteLine.ErrorMsg__c  = 'Future update';
                }


                if (quoteLine.ErrorMsg__c  != null){
                    quoteLine.ErrorMsg__c  = quoteLine.ErrorMsg__c  + ' ' + Datetime.now().format('YYYY-MM-dd HH:ss');
                }
                if (tocreateCP != null){
                    theNewCP.put(key, tocreateCP );
                    if (updStatus == 'C'   &&  contractedPriceLast  != null )  { //  Existing record, Data align (not close the gap, close the overlap)
                        if (contractedPriceLast.SBQQ__ExpirationDate__c > tocreateCP.SBQQ__EffectiveDate__c ){
                           contractedPriceLast.SBQQ__ExpirationDate__c =  tocreateCP.SBQQ__EffectiveDate__c.addDays(-1);
                           theNewCP.put(contractedPriceLast.id, contractedPriceLast );

                        }
                    } 
                    system.debug('------ tocreateCP '+ tocreateCP);
                    if ( tocreateCP.SBQQ__EffectiveDate__c != null && tocreateCP.SBQQ__ExpirationDate__c != null && tocreateCP.SBQQ__EffectiveDate__c > tocreateCP.SBQQ__ExpirationDate__c){
                        tocreateCP.SBQQ__ExpirationDate__c = tocreateCP.SBQQ__EffectiveDate__c;
                    }
                    // Sync startdate from CP to quoteLine
                    if ( tocreateCP.SBQQ__EffectiveDate__c != null ){
                        quoteLine.PriceValidityStart__c = tocreateCP.SBQQ__EffectiveDate__c;
                    }

                    // Sync enddate from CP to quoteLine
                    if (tocreateCP.SBQQ__ExpirationDate__c != null ){
                        quoteLine.PriceValidityEnd__c = tocreateCP.SBQQ__ExpirationDate__c;
                    }
                    // Expirated date is > today. Raise error and continue
                    if (tocreateCP.SBQQ__ExpirationDate__c == null || tocreateCP.SBQQ__ExpirationDate__c < Date.today()){
                        DebugLog.addInfo  ( '(PriceRenewalCampaignUtils.createNewContractedPrice)  Expired Expiration_date found in ' + quoteline.Name + ' '+ quoteline.id);
                        return ;
                    }                    
                }
            }
        }

        
        for (SBQQ__ContractedPrice__c CP: theNewCP.values()){
            system.debug('------ CPold '+ CP); // Just need it here for debugging
        }

  //      system.debug('[PriceRenewalCampaignUtils][createContractedPrices] Ready to upsert contractedPriceUpsert = ' + contractedPriceUpsert.values());

        upsert  theNewCP.values();

        update quoteLines; 

    }

/******************************************************************************************************************************************************************
* Author:       Wim van Beek
* Company:      Salesforce / NNcourage
* Description:  createNewContractedPrice
*                  Map quotelines to Contracted Prices. Shared between manual and PRC-generated quotes
* 
* History :     New 8-2018.
******************************************************************************************************************************************************************/


    public static SBQQ__ContractedPrice__c createNewContractedPrice(SBQQ__QuoteLine__c quoteline){
        // Create new entry in Contracted Price. Here we transfer the quotoLine to Contacted price. Not sure we need it later.

            SBQQ__ContractedPrice__c contractedPrice = new SBQQ__ContractedPrice__c(
                    SBQQ__Account__c = quoteLine.SBQQ__Quote__r.SBQQ__Account__c,
                    SBQQ__Product__c = quoteLine.SBQQ__Product__c,
                    SBQQ__Price__c = quoteLine.PricePerUOM__c,
           //         Price4__c = quoteLine.PricePerUOM__c,   // 4 digits precise // 10-9-18 obsolute
                    UOM__c = quoteLine.UOM__c,
                    Quantity__c = quoteLine.Quant__c,
                    CurrencyIsoCode = quoteLine.CurrencyIsoCode,
                    SBQQ__OriginalQuoteLine__c = quoteLine.id,
                    SBQQ__EffectiveDate__c = quoteLine.PriceValidityStart__c,
                    SBQQ__ExpirationDate__c = quoteLine.PriceValidityEnd__c
            );
            // Make choices with Dates here. Get dates from quote if quoteline dates are empty
            if (contractedPrice.SBQQ__EffectiveDate__c == null){contractedPrice.SBQQ__EffectiveDate__c = quoteLine.SBQQ__Quote__r.PriceValidityFrom__c;}
            if (contractedPrice.SBQQ__ExpirationDate__c == null){contractedPrice.SBQQ__ExpirationDate__c = quoteLine.SBQQ__Quote__r.PriceValidityTo__c;}
            if (contractedPrice.SBQQ__EffectiveDate__c == null || contractedPrice.SBQQ__EffectiveDate__c < Date.today()){contractedPrice.SBQQ__EffectiveDate__c = Date.today();}

            return contractedPrice;
        }

    // Query contractedprices    
    public static List<SBQQ__QuoteLine__c>  returnQuoteLines(Set<Id> contractId, Id quoteId ) {
         return returnQuoteLines([SELECT        Id,
                                                Quantity__c, 
                                                CurrencyIsoCode, 
                                                UOM__c, 
                                                SBQQ__EffectiveDate__c, 
                                                SBQQ__ExpirationDate__c, 
                                                SBQQ__Product__c, 
                                                Incoterms__c,  
                                                SBQQ__Price__c,
                                                SBQQ__OriginalQuoteLine__r.TF_PreviousPrice__c 
                                            FROM SBQQ__ContractedPrice__c WHERE Id IN : contractId  ], quoteId);
    }

    // Return complete QuoteLines
    public static List<SBQQ__QuoteLine__c>  returnQuoteLines(List<SBQQ__ContractedPrice__c> cpList , Id quoteId)  {
            List< SBQQ__QuoteLine__c> returnList = new  List< SBQQ__QuoteLine__c>();
            for (SBQQ__ContractedPrice__c contract: cpList){
                SBQQ__QuoteLine__c quoteLine = returnQuoteLines (contract);
                    quoteLine.SBQQ__Number__c = returnList.size()+1;
                    quoteLine.SBQQ__Quote__c = quoteId;
                    returnList.add(quoteLine);
            }
           return returnList;
    }

    // return one complete QuteLine
    public static SBQQ__QuoteLine__c  returnQuoteLines(SBQQ__ContractedPrice__c contract)  {
                SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c();
                newQuoteLine.RecordTypeId = IMCDUtils.recordTypeIdMap.get('RenewalQuoteLine');
                newQuoteLine.SBQQ__CustomerPrice__c = null;
                newQuoteLine.SBQQ__Quantity__c = contract.Quantity__c;
                newQuoteLine.Quant__c = contract.Quantity__c;  // 5-9-18 WvB
                newQuoteLine.UOM__c = contract.UOM__c;
                newQuoteLine.CurrencyIsoCode= contract.CurrencyIsoCode;
                newQuoteLine.TF_PreviousDateFrom__c = contract.SBQQ__EffectiveDate__c;
                newQuoteLine.TF_PreviousDateTo__c = contract.SBQQ__ExpirationDate__c;
                newQuoteLine.TF_PreviousPrice__c = contract.SBQQ__Price__c;
                newQuoteLine.SBQQ__ListPrice__c = 0;
                newQuoteLine.SBQQ__Product__c = contract.SBQQ__Product__c;
                newQuoteLine.Incoterms__c = contract.Incoterms__c;
                newQuoteLine.PricePerUOM__c = contract.SBQQ__Price__c ;
        //        newQuoteLine.Newprice__c = contract.SBQQ__Price__c;  //Removed 31-10-18
                newQuoteLine.ProposedUOMprice__c = contract.SBQQ__Price__c;
                newQuoteLine.PrevContractedPrice__c = contract.Id;
                newQuoteLine.PrevPricePerUAM__c =  contract.SBQQ__Price__c;
                newQuoteLine.Increase__c = 0;
                return newQuoteLine;
    } 
 
}