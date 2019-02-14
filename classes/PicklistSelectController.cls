public with sharing class PicklistSelectController {

    /**
     * Given an API object and field name, returns the configured field label to display to users.
     */    
    @AuraEnabled
    public static String getFieldLabel( String objectName, String fieldName ) {
        String label = Schema.getGlobalDescribe().get( objectName ).getDescribe().fields.getMap().get( fieldName ).getDescribe().getLabel();
        return label;
    }

    private static List<PicklistOption> getPicklistOptions( String objectName, String fieldName) {

        List<PicklistOption> options = new List<PicklistOption>();
        options.add( new PicklistOption( '', '', true) );

        for ( PicklistEntry entry : Schema.getGlobalDescribe().get( objectName ).getDescribe().fields.getMap().get( fieldName ).getDescribe().getPicklistValues() ) {
            options.add( new PicklistOption( entry.getLabel(), entry.getValue(), false) );
        }

        return options;
    }

    /**
     * Given an API object and field name, returns list of the picklist values for use in select input.
     */
    @AuraEnabled
    public static List<PicklistOption> getPicklistOptions( String objectName, String fieldName, String recordId) {

        if (String.isEmpty(recordId)) {
            return (getPicklistOptions(objectName, fieldName));
        }

        String query = 'Select ' + fieldName + ' from ' + objectName + ' where id = \'' + recordId + '\'';
   		sObject queryObject = Database.query(query);      
        String selectedValue =(String)queryObject.get(fieldName);
                
        List<PicklistOption> options = new List<PicklistOption>();
        if (String.isBlank(selectedValue)){
            options.add( new PicklistOption( '', '', true) );
        }
        
        for ( PicklistEntry entry : Schema.getGlobalDescribe().get( objectName ).getDescribe().fields.getMap().get( fieldName ).getDescribe().getPicklistValues() ) {
			options.add( new PicklistOption( entry.getLabel(), entry.getValue(), entry.getValue() == selectedValue) );
        }
        
        return options;
    }

    /**
     * The system class PicklistEntry is not aura enabled so cannot be returned from @AuraEnabled method.
     * Workaround is to define our own class with aura enabled properties.
     */
    public class PicklistOption {
        
        @AuraEnabled
        public String label { get; set; }
        
        @AuraEnabled
        public String value { get; set; }
        
        @AuraEnabled
        public Boolean selected { get; set; }
        
        public PicklistOption( String label, String value, Boolean selected ) {
            this.label = label;
            this.value = value;
            this.selected = selected;
        }
    }  
}