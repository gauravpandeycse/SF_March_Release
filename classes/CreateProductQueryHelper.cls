/**
 * Created by kdoruibin on 2019-01-10.
 */

global with sharing class CreateProductQueryHelper {

    global class HelperQueryRequest {
        @InvocableVariable (required=false label='List<String> of Product2 fields')
        global List<String> lstProductFields;
        @InvocableVariable (required=false label='List<Product2>')
        global List<Product2> lstProduct;
        @InvocableVariable (required=false label='<Account> Id field (Principal Id)' description='Provide as well lstQuoteLineFields, Key, Lob, Start/End Dates.')
        global ID principalId;
        @InvocableVariable (required=false label='find {searchString}' description='Search string to filter lstProduct')
        global String searchString = '';
        @InvocableVariable (required=false label='soqlLimit' description='Added as LIMIT n')
        global Integer soqlLimit = 0; // 0 means no limit.
    }

    global class HelperQueryResult {
        @InvocableVariable (required=false label='List<Product2>' description='Output for principalId/returnQuoteLineProducts')
        global List<Product2> lstProduct;
        @InvocableVariable (required=false label='Number of records queried.' description='Number of records returned.')
        global Integer numRecords;
    }

    class CreateProductQueryHelperException extends Exception {}

    @InvocableMethod ( label='Execute Create Product Query Helper' description='Executes a helper query based on provided inputs' )
    global static List<HelperQueryResult> executeCreateProductQueryHelper ( List<HelperQueryRequest> requests ) {

        String origin = '[CreateProductQueryHelper][executeCreateProductQueryHelper]';
        IMCDUtils.debugLimits(origin + ' Method entry');

        HelperQueryRequest request = new HelperQueryRequest();

        // No bulkification, only single request allowed!
        if (requests.size() != 1) {
            throw new CreateProductQueryHelperException ('Method is not bulkified, only allows a single request.');
        }
        else {
            request = requests[0]; // take the single request
        }

        // Returning object
        HelperQueryResult result = new HelperQueryResult();
        result.numRecords = 0; // default
        List<HelperQueryResult> lstResult = new List<HelperQueryResult>();
        Set<Id> setIds = new Set<Id>();
        String soql = '';
        String soqlLimit = (request.soqlLimit > 0) ? ' LIMIT ' + request.soqlLimit : '';
        system.debug(request);
        system.debug(soqlLimit);


        if (request.principalId <> null && request.lstProductFields <> null) {
            soql = 'SELECT ' + String.join(request.lstProductFields, ',') + ' ' +
                    'FROM Product2 WHERE Principal__c = \'' + request.principalId + '\' ' +
                    'AND Name LIKE \'%' + request.searchString.replaceAll(' +|-+', '%') + '%\'' + soqlLimit;
            system.debug(soql);
            result.lstProduct = Database.query(soql);
            result.numRecords = result.lstProduct.size();
            if (result.lstProduct.size() == 0) {
                result.lstProduct = null;
            }
        }

        // No valid inputs
        else {
            throw new CreateProductQueryHelperException ('No valid inputs received.');
        }

        system.debug(origin + ' setIds = ' + setIds);
        system.debug(origin + ' SOQL excuted = ' + soql);
        system.debug(origin + ' result = ' + result);

        lstResult.add(result);

        IMCDUtils.debugLimits(origin + ' Method exit');
        return lstResult;
    }

    // Get the Ids of the passed-in list of objects
    private static Set<Id> getIds (List<sObject> lstSObject) {
        return (new Map<Id,SObject>(lstSObject)).keySet();
    }
}