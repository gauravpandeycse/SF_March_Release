global  class CPQadvancedSearchPlugin implements SBQQ.ProductSearchPlugin{
    
    /*------------------------------------------------------------
        Author:         Wim van Beek
        Company:        Salesforce / NNCourage
        Description:    Will activate an advanced search to find the products and indicate problemes with that products
                        1. Search PBE and products in either standard PB or specific PB
                        2. Some array-processing and checking for allowed countries and de-doubling
                        3. Query 2 to return PriceBookEntries
        Deploy:         Place in 'Product Search Plugin' in 'Plugins' from Package-CPQ

        Source:         https://community.steelbrick.com/t5/Developer-Guidebook/Product-Search-Plugin/ta-p/13626
                        Only section search has been adapted, comments from source still present
        Special         Must be non-blocking and non-error reporting. Empty queries will result in no output

        History
        03-2018     Wim van Beek Initial
        29-6-2018   Wim van Beek, Changed Country-field in Account. Billing=>Shipping. Removed ISOcode translation.
                    Assumtion: Works with ISOcodes only   
        6-7-2018    Wim van Beek, Changed buildup of Quoery in search. 
        18-8-18     Change   TempProductFlag__c for NoActiveProd__c ??
        26-11-2018  Change   Added TF_ExcludeSegment4__c field for selection

    ------------------------------------------------------------*/  
    

    Global class priceBookEntrySelectionClass {
        Public Boolean hasEntry = false;
        Public Set<String>  msg = null; 
        Public id priceBookeEntryId;
        Public String allowedCountries;
    }

    global CPQadvancedSearchPlugin(){
        
    }

    global Boolean isSearchCustom(SObject quote, Map<String,Object> fieldValuesMap){
        return true;
    }   
    global Boolean isFilterHidden(SObject quote, String fieldName){
        return false;
    }   
    global String getFilterDefaultValue(SObject quote, String fieldName){
        return NULL;
    }
    global String getAdditionalSearchFilters(SObject quote, Map<String,Object> fieldValuesMap){
        return NULL;
    }
    // Only use search here
    global List<PricebookEntry> search(SObject quote, Map<String,Object> fieldValuesMap){
        system.debug('------ theSearch '+ fieldValuesMap);
        
        Map<Id, priceBookEntrySelectionClass> priceBookEntryMap = new Map<Id, priceBookEntrySelectionClass>();

        String theCountry ;
        for (Account acc:[SELECT id, BillingCountry, ShippingCountry FROM Account WHERE id =: string.valueof(quote.get('SBQQ__Account__c'))]){
            theCountry = acc.ShippingCountry;
        }
        System.debug('------ theCountry '+ theCountry);
        
        Pricebook2 pricebook ;
        String PBid = string.valueOf(quote.get('SBQQ__PricebookId__c'));
        for (Pricebook2 pb2 :  [SELECT id, ImcdCompany__c,GroupFlag__c  FROM Pricebook2 WHERE id =: PBid ]){
            pricebook = pb2;
        }
        System.debug('------ pricebook '+ pricebook);


        //GET ALL POSSIBLE FILTER FIELDS FROM THE SEARCH FILTER FIELD SET

        List<Schema.FieldSetMember> searchFilterFieldSetFields = SObjectType.Product2.FieldSets.SBQQ__SearchFilters.getFields();

        //GET ALL POSSIBLE FIELDS FROM THE SEARCH RESULTS FIELD SET
        List<Schema.FieldSetMember> searchResultFieldSetFields = SObjectType.Product2.FieldSets.SBQQ__SearchResults.getFields();

        //BUILD THE SELECT STRING
        String selectClause = 'SELECT ';
        // Make sure to include product2 fields in the list if required in the query.
        Set<String> theFieldsSelect = new Set<String>{'id', 'UnitPrice', 'Product2.Segment4__c', 'Product2.GroupFlag__c','Product2.LocalCompany__c','Pricebook2Id', 'Pricebook2.isStandard', 'Product2.ItemStatus__c', 'Product2.AllowedCountries__c'};
        for(Schema.FieldSetMember field : searchResultFieldSetFields){
            theFieldsSelect.add('Product2.'+ field.getFieldPath());
        }

        String where1;
        String where2;

        selectClause += String.join(new List<String>(theFieldsSelect), ', ');

         // Step 1 Temp products or not temp-products
        String whereClause = 'WHERE ((Pricebook2.isStandard = true AND Product2.TempProductFlag__c = false AND CurrencyIsoCode = \'EUR\' ) ';
        whereClause = whereClause + ' OR (Product2.TempProductFlag__c = true AND Pricebook2.isStandard = false)) ';

        // Search in Group or not
        if (pricebook.GroupFlag__c == true){
            whereClause = whereClause +  ' AND  (Product2.TempProductFlag__c = true OR Product2.GroupFlag__c = true ) ' ; 
            whereClause = whereClause +  ' AND  (Pricebook2.isStandard = true OR Pricebook2.GroupFlag__c = true ) ' ;
        } else {                        
            whereClause = whereClause +  ' AND ( Product2.LocalCompanyIndex__c = \'' + pricebook.ImcdCompany__c  + '\' OR Pricebook2Id = \'' + quote.get('SBQQ__PricebookId__c') + '\' ) '  ;
            whereClause = whereClause +  ' AND  (Pricebook2.isStandard = true OR Pricebook2.GroupFlag__c = false ) ' ;
        }

        system.debug('------ whereClause '+ whereClause);

        List<String> wheres = new List<String>();  // Collection of 'AND'-clauses for SOQL-query

        for (String key : fieldValuesMap.keySet()){
            system.debug('------ key '+ key+ ' ==> ' + fieldValuesMap.get(key));
            if (fieldValuesMap.get(key) != null){
                String newWhere ;
                if (key == 'ItemStatus__c'){
                    newWhere = ' Product2.' + key + ' = ' + '\'' + fieldValuesMap.get(key) + '\'';
                    system.debug('------ key '+ key);
                    } else {
                // Assume all key's are fields in Product2
                    if (key == 'Principal__c'){
                        newWhere = ' Product2.' + key + ' = ' + '\'' + fieldValuesMap.get(key) + '\'';
                    } else {
                        if (key == 'TF_ExcludeSegment4__c'){ // New 26-11-2018
                            String choice = String.valueOf(fieldValuesMap.get(Key));
                            if (choice != null ){
                                system.debug('------ choice '+ choice);
                                if (choice == 'Exclude segment 4' ) {
                                    newWhere = ' Product2.Segment4__c = null ';
                                }
                                if (choice == 'Only show segment 4' ) {
                                    newWhere = ' Product2.Segment4__c != null ';
                                }
                            }  
                        } else {
                            newWhere = ' Product2.' + key + ' Like ' + '\'%' + String.escapeSingleQuotes(String.valueOf(fieldValuesMap.get(Key))) + '%\'';
                        }
                    }
                }
                
                system.debug('------ newWhere '+ newWhere);
                if (newWhere != null){
                    wheres.add(newWhere);
                }
            }
        }
 
        for(Schema.FieldSetMember field : searchFilterFieldSetFields){
            if (fieldValuesMap.get(field.getFieldPath()) != null ){
                if(field.getType() ==   Schema.DisplayType.Picklist){
                    wheres.add('  Product2.' + field.getFieldPath() + ' = ' + fieldValuesMap.get(field.getFieldPath()) + ' ');
                }
            }
        }

        if (wheres.size() > 0 ){   // Merge all wheres into one SOQL-where string
        	wheres.add(' Product2.IsActive = true ');  // Defaulted
           	wheres.add(' IsActive = true ');

            whereClause += ' AND  (';
            whereClause += String.join(wheres, ' AND ');
            whereClause += '    )   ';

        } else {
            return new List<PricebookEntry>();  // Empty search because no selections data available
        }

        //BUILD THE QUERY#1

        system.debug('------ selectClause '+ selectClause);
        system.debug('------ whereClause '+ whereClause);
        if (Test.isRunningTest() == true ){whereClause = '';}   // Hate it. Some issue with Pricebook settings. 
                                                                // In a testclass the standardpricebook does not have all functions available 
                                                                // The crossobject search seems to be one of these issues 
        String query = selectClause + ' FROM PricebookEntry  ' + whereClause + ' ORDER BY Product2.Name LIMIT 300 '; // Max 400

        //DO THE QUERY #1
        List<PricebookEntry> pbesQuery = new List<PricebookEntry>();
        pbesQuery = Database.query(query);
        if (pbesQuery.size() == 0 ){return new List<PricebookEntry>();} // Empty search

        Map<Id, String> alertStr = new  Map<Id, String>();

        // Analize results per product. Make sure at the end there is only one pricebookentryId per selectable product
        // Fill alert-field if needed.

        for (PricebookEntry PBE : pbesQuery){
//            system.debug('------ PBE.Product2.Segment4__c '+ PBE.Product2.Segment4__c );
            priceBookEntrySelectionClass PBESC = priceBookEntryMap.get(PBE.Product2Id);
            if (PBESC == null){   // Fill priceBookEntrySelectionClass
                PBESC = new priceBookEntrySelectionClass();
                PBESC.msg = new Set<String>();
                priceBookEntryMap.put(PBE.Product2Id, PBESC);
            }
            PBESC.allowedCountries = PBE.Product2.AllowedCountries__c;
            PBESC.priceBookeEntryId = PBE.id;

            if (theCountry == null && PBESC.allowedCountries != null){
                PBESC.msg.add('Customer needs Sold To Country');
            }

            if (theCountry != null && PBESC.allowedCountries != null){
                if (PBESC.allowedCountries.indexOf(theCountry) == -1){
                    PBESC.msg.add('Invalid for country '+ theCountry);   // Country is required, does not match
                }
            }
        }

        List<Id> pbeIDs = new List<Id>();
        for (priceBookEntrySelectionClass PBESC : priceBookEntryMap.values()){
            pbeIDs.add(PBESC.priceBookeEntryId); // Collect all PriceBookEntriesId
        }

        String newWhereClause = ' WHERE id in ( \''+  String.join( pbeIDs, '\', \'' ) + '\' ) ';
        query = selectClause  + ' FROM PricebookEntry  ' + newWhereClause + ' ORDER BY Product2.Name LIMIT 200';
        System.debug('------ query ' + query);
                    
        List<PricebookEntry> pbesOut ;
        pbesOut = Database.query(query);  // Query #2 width selected id's 
        for (PricebookEntry PBE: pbesOut){  // Add msg to Alert-field
            PBE.UnitPrice = 0;
            List<String> theMsgStr = new List<String>(priceBookEntryMap.get(PBE.Product2Id).msg);
            PBE.Product2.Alert__c = String.join(theMsgStr, ', ');  // Fill alert field.
        }

        return pbesOut;
    }   


    global Boolean isSuggestCustom(SObject quote, Map<String,Object> inputValuesMap){
        return true;
    }

    global Boolean isInputHidden(SObject quote, String input){
        return false;
    }   
    global String getInputDefaultValue(SObject quote, String input){
        return NULL;
    }
    global String getAdditionalSuggestFilters(SObject quote , Map<String,Object> xx){
        return NULL;        
    }
    global list<PricebookEntry> suggest(SObject quote , Map<String,Object> xx){
        return NULL;        
    }   
}