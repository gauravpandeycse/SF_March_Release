/*
https://github.com/dhoechst/Salesforce-Test-Factory
// The TestFactory will pre-fill all the fields we typically need
Account a = (Account)CPQTestFactory.createSObject(new Account());
insert a;

*/


@isTest
public class CPQTestFactory {

    public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = 'CPQTestFactory.' + objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
  //      system.debug('------ defaultClassName '+defaultClassName);
        // If there is a class that exists for the default values, then use them
      if (Type.forName(defaultClassName) != null) {
          sObj = createSObject(sObj, defaultClassName);
      }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            throw new TestFactoryException('Invalid defaults class.');
        }
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        return sObj;
    }
    public class TestFactoryException extends Exception {}

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[] {};
        SObject newObj;

        // Get one copy of the object
        if (defaultClassName == null) {
            newObj = createSObject(sObj);
        } else {
            newObj = createSObject(sObj, defaultClassName);
        }

        // Get the name field for the object
        String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            // we dont need this when the name field is an autonumber
            if (!sobj.getSObjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isAutoNumber()) {
                clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
            }
            sObjs.add(clonedSObj);
    
        }
        return sObjs;
    }
    // When we create a list of SObjects, we need to
    private static Map<String, String> nameFieldMap = new Map<String, String> {
            'Contact' => 'LastName',
            'Case' => 'Subject',
            'Lead' => 'LastName',
            'User' => 'LastName',
            'Account' => 'Description' 
    };

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, (String)null);
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
        if (doInsert) {
            insert retList;
        }
        return retList;
    } 
    public class PriceRenewalCampaignDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            PriceRenewalCampaign__c.PricesToProcess__c => 'All',
            PriceRenewalCampaign__c.PriceBook__c => Test.getStandardPricebookId(),
            PriceRenewalCampaign__c.PurchasePriceIncrease__c => 1,
            PriceRenewalCampaign__c.ContractedPriceIncrease__c => 1,
            PriceRenewalCampaign__c.Stage__c => 'Setup'
            };
        }
    }
    public class AccountDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            Account.LockedForIntegration__c => false,
            Account.Name => 'TestName'
            };
        }
    }


    public class SBQQContractedPriceDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            SBQQ__ContractedPrice__c.IntegrationId__c => 'SomeId'
            };
        }
    }
    public class Product2Defaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            Product2.Name => 'Test Product',
            Product2.ItemStatus__c => '04.Active Sales',
            Product2.IsActive => true,
            Product2.ProductManager__c => Userinfo.getUserId()
            };
        }
    }

    public class Pricebook2Defaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            Pricebook2.IsActive => true,
         
            Pricebook2.DefaultCurrencyIsoCode__c => 'EUR',
            Pricebook2.ImcdCompany__c => Pricebook2.ImcdCompany__c.getDescribe().getPicklistValues()[0].getValue(),
            Pricebook2.IntegrationId__c => Pricebook2.ImcdCompany__c.getDescribe().getPicklistValues()[0].getValue()
        
            };
        }
    }

 

}