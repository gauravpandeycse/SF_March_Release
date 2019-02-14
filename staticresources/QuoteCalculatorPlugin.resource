//  QuoteCalculatorPlugin 
/*------------------------------------------------------------
        Author:         Wim van Beek
        Company:        Salesforce / NNCourage
        Name:           QuoteCalculatorPlugin
        Description:    This javascript needs to be placed in the 'SBQQ__CustomScript__c'  object.
                        1. Create SBQQ__CustomScript__c -record. name it 'QuoteCalculatorPlugin' 
                        2. Fill the quote-fields with 
                        'Id
                        AccountShippingCountry__c
                        SBQQ__Account__c'
                        
                        3. Fill the quoteLine-fields with 
                        'Id
                        Name
                        ScreenAlert__c
                        SBQQ__Product__c'    
                        (Every field on new line)  
                        4. Cut-paste the contents of this scrip into the 'Code' field. It should compile error-free.
                        5. Goto setup-package-CPQ-plugin and add 'QuoteCalculatorPlugin' (name of record) into the 'Quote Calculator Plugin'-field
                          
        Jira:           SFDP-2207
        CPQ-documentation: https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_plugins.meta/cpq_dev_plugins/cpq_dev_jsqcp_parent.htm
        History
        01-2019     Wim van Beek Initial

    ------------------------------------------------------------*/    
  

//var usedId = [];  // Need to have this var global. 

export function onInit(quoteLineModels) {
// alert ("Checking new products");   // Use for startindication

return Promise.resolve();

};

var xx // Global vars not allowed.          
           
export function  onAfterCalculate(quote, lines, conn) {
    if (lines.length){
      var codes = [];
      lines.forEach(function(line) { 
        var code = line.record["SBQQ__Product__c"];
        var theId = line.record["Id"];
        if (theId == null ){  
             codes.push(code);                  // Collect all new QuoteLines (no ID, get ProductId)

         }
         });
         if (codes.length > 0){
           processTheProducts(quote, codes, conn); 
       }
     }
     return Promise.resolve();
}
     
export function processTheProducts (quote, codes, conn){
        var codeList = "('" + codes.join("', '") + "')";
        var restxt =[];
        var accList =  "('" + quote.record.SBQQ__Account__c + "')";
        var principals = [];
        principals.push('x'); // Put one dummy (not sure)
        conn.query('SELECT Id, Name, Account__c, Principal__c FROM DirectSellingRelationship__c WHERE Account__c in'   + accList )          // Check for DirectSelling Relations
             .then (function(results){
               results.records.forEach(function(record) {
                    var principal  = record.Principal__c;
                    principals.push(principal) ;                 // Store in PrincipalsList
 
               });
             });
        

    return conn.query('SELECT Id, Name, AllowedCountries__c, ItemStatus__c, TradeName__c, Principal__c, Principal__r.Name  FROM Product2 WHERE Id IN ' + codeList)
        .then(function(results) {
                 results.records.forEach(function(record) {
                       var prodName = record.Name;
                       var principal = record.Principal__c; 
                       if ( record.ItemStatus__c == '06.Inactive'  || record.ItemStatus__c == '07.Obsolete' || record.ItemStatus__c == '99.Rejected Temp' )   {        // Inactive Products
                           restxt.push( 'Product [' +  prodName + '] has status ['+ record.ItemStatus__c +']  Please remove this product from this quote.')  ;
                       }
                       if (record.ItemStatus__c == '05.Phase Out'  )   {        // Nearly inactive Products
                           restxt.push( 'Product [' +  prodName + '] has status ['+ record.ItemStatus__c +']  Are you sure you want to add this product to this quote?')  ;
                       }                       var AllowedCountries = record.AllowedCountries__c;
                       if (AllowedCountries )    {
                          var  shipCountry = quote.record.AccountShippingCountry__c;
                          if (shipCountry  ){
                              if (AllowedCountries.indexOf(shipCountry) == -1  )    {
                                  restxt.push('Product [' +  prodName + '] is not allowed in ' +  shipCountry )  ;     // Shipcountry is wrong country
                              }                          
                          }   else {
                                restxt.push('Product [' +  prodName + '] is country-resticted, customer has no shippingcountry')  ;
                          }
                       }
                       if (principal)    {
                           var a = principals.indexOf(principal) ;
                             if (a >= 0 ){
                                 restxt.push('This customer has a direct selling relation with the Principal for Product [' + prodName + ']. Are you sure you want to add this product to this quote?')  ;
                             }
                       }
                  });
                  
                 var X ;
                 if (restxt.length > 0) {
                        X = ''
                     var i;
                     for (i = 0; i < restxt.length; i++){
                        X += restxt[i] + ' '; 
                     }
                      alert (X);
                 }
        });
     return Promise.resolve();    
}     
 ///  end      