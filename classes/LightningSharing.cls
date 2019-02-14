/******************************************************************************************************************************************************************
 * Author:      Shane McLaughlin (shane.mclaughlin@salesforce.com, https://github.com/mshanemc/LightningSharing)
 * Company:     Salesforce
 * Title:       Lightning Components + Apex to implement adhoc sharing in Lightning Experience
 * Description: Sharing logic class
 * Test Class:  TestLightningSharing
 * History:     Michael Simkin (msimkin@salsforce.com)  - minor changes for better test coverage and code readability
 ******************************************************************************************************************************************************************/
global with sharing class LightningSharing {

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: find sobject name and Name field value for given record id
     * Inputs:      Id recordId
     * Output:      JSONified recordStuff instance 
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    public static string sayMyName(id recordId){
        string nameField;

        for (Schema.SObjectField dfr : recordId.getSObjectType().getDescribe().fields.getMap().values()) {
            if (dfr.getDescribe().isNameField()) {
                nameField = dfr.getDescribe().getName();
                break;
            }
        }

        string query = 'select ' + nameField + ' from ' + recordId.getSObjectType() + ' where id = \'' + recordId + '\'';
        recordStuff rs = new recordStuff();
        rs.recordName = string.valueOf(Database.query(query)[0].get(nameField));
        rs.objectType = string.valueOf(recordId.getSObjectType().getDescribe().getLabel());

        return JSON.serialize(rs);
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: helper structure with sobject name and Name field value
     * History:     remove unused getters and setters
     ******************************************************************************************************************************************************************/
    @TestVisible
    class recordStuff {
        @TestVisible string recordName;
        @TestVisible string objectType;
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: If current user can edit given record?
     * Inputs:      Id recordId
     * Output:      Boolean
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    global static boolean canIEditPerms(id recordId){
        try {
            String query = 'SELECT RecordId, HasDeleteAccess, HasAllAccess FROM UserRecordAccess WHERE RecordId = \'' + String.escapeSingleQuotes(string.valueOf(recordId)) + '\' AND UserId = \'' + UserInfo.getUserId() + '\'';
            sObject o = Database.query(query);
            if ((Boolean)o.get('HasDeleteAccess') || (Boolean)o.get('HasAllAccess')){
                System.debug('edit allowed because user has full access or modify all permissions');
                return true;
            }
        } catch (system.queryException e){
            //it's possible you can't even see that record and the queries are null!
            return false;
        }
        return false;
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: remove existing sharing rules for given user or group and given record
     * Inputs:      Id UserOrGroupID
     *              Id recordId
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    global static void deletePerm(id userOrGroupId, id recordId){
        //access check
        Schema.DescribeSObjectResult describe = getSharingDescribe(recordId);

        //can I delete the sharing objects?
        if (!describe.isDeletable() || !describe.isAccessible()){
            throw new AuraHandledException('You don\'t have the proper permissions for this action');
        }

        delete Database.query(buildQuery(recordId) + ' AND UserOrGroupId = \'' + userOrGroupId + '\'');
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: (in|up)sert access permission for given user or group and record with given level
     * Inputs:      Id     UserOrGroupID
     *              Id     recordId
     *              String level
     * Output:      JSONified updated existing permissions or inserted new one
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    global static string upsertPerm (id UserOrGroupID, id recordId, string level){

        Schema.DescribeSObjectResult describe = getSharingDescribe(recordId);
        level = String.escapeSingleQuotes(level);

        if (!canIEditPerms(recordId)){
            throw new AuraHandledException('Only the record owner or administrators can modify permissions');
        }
        system.debug('doing perm upsert');

        // special handling for role => groups
        if (UserOrGroupID.getSobjectType() == Schema.UserRole.SObjectType){
            //it's a role...find the matching group?
            list<Group> matchingGroups = [SELECT Id, Name, Type FROM Group WHERE RelatedId = :UserOrGroupID AND Type = 'Role' LIMIT 2];
            if (matchingGroups.size()>1){
                throw new AuraHandledException('There are multiple groups for that role');
            }
            UserOrGroupID = matchingGroups[0].Id;
        }

        list<sobject> existing = Database.query(buildQuery(recordId) + ' AND UserOrGroupID = \'' + UserOrGroupID + '\' ');
        string sobj = objectTypeFromId(recordId);

        if (existing.size() > 0){
            //can I update this thing?

            if (!describe.isUpdateable() ||
                !describe.fields.getMap().get(getAccessLevelField(sobj)).getDescribe().isUpdateable()
                ){
                throw new AuraHandledException('Only the record owner or administrators can modify permissions');
            }

            existing[0].put(getAccessLevelField(sobj), level);
            update existing;
            return JSON.serialize(existing);
        } else {
            system.debug('not already existing. will create');
            //are we even allowed to insert this?  for these specific fields that we'll set?
            if (!describe.isCreateable() ||
                    !describe.fields.getMap().get(getAccessLevelField(sobj)).getDescribe().isCreateable() ||
                    !describe.fields.getMap().get(getLookupField(sobj)).getDescribe().isCreateable() ||
                    !describe.fields.getMap().get('UserOrGroupId').getDescribe().isCreateable()
                 ){
                throw new AuraHandledException('Only the record owner or administrators can create new permissions');
            }
            //create a new SObject dynamically and insert
            Schema.SObjectType newObj = Schema.getGlobalDescribe().get(getSharingTableName(sobj));
            sobject share = newObj.newSObject();

            share.put(getAccessLevelField(sobj), level);
            share.put(getLookupField(sobj), recordId);
            share.put('UserOrGroupId', String.escapeSingleQuotes(string.valueOf(UserOrGroupID)));

            if (objectTypeFromId(recordId)=='Account'){
                //share.put('ContactAccessLevel', level);
                share.put('CaseAccessLevel', level);
                share.put('OpportunityAccessLevel', level);
            }

            insert share;
            return JSON.serialize(share);
        }
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: perform SOSL for given search string and sobject type
     * Inputs:      String searchString
     *              String objectType
     * Output:      JSONified search results
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    global static string doSOSL(String searchString, string objectType){
        //Bobby Tables says always sanitize your inputs.
        searchString = String.escapeSingleQuotes(searchString);
        objectType = String.escapeSingleQuotes(objectType);

        //check CRUD/FLS
        //what object is this?
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objectType).getDescribe();
        //can I query?
        if (!describe.isQueryable() || !describe.isAccessible()){
            throw new AuraHandledException('You don\'t have the proper permissions for this action');
        }

        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
        for (Schema.SObjectField field:fieldMap.values()){
            if (field.getDescribe().isNameField()){
                if (!field.getDescribe().isAccessible()){
                    throw new AuraHandledException('You don\'t have the proper permissions for this action');
                }
            }
        }

        // limit rows returned for performance reasons
        string sosl = 'FIND \'*' + searchString + '*\' IN NAME FIELDS RETURNING ' + getReturning(objectType) + ' limit 200';
        list<list<sobject>> results = search.query(sosl);

        list<sobject> output = new list<sobject>();
        for (list<sobject> result:results){
            output.addAll(result);
        }

        return JSON.serialize(output);
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: helper function for constructing RETURNING clause in SOSL query, in consideration of given sobject type
     * Inputs:      String objectType
     * Output:      RETURNING clause
     ******************************************************************************************************************************************************************/
    @TestVisible
    private static string getReturning (string objectType){
        //assert that we can use these fields as the current user
        if (!User.Id.getDescribe().isAccessible() ||
              !User.Name.getDescribe().isAccessible() ||
              !User.UserType.getDescribe().isAccessible() ||
              !Group.Id.getDescribe().isAccessible() ||
              !Group.Name.getDescribe().isAccessible()
            ){
            throw new AuraHandledException('You don\'t have the required permissions for this action');
        }


        //filter out user types that don't have sharing!
        if (objectType == 'User'){
            return 'User(Id, Name, UserType WHERE UserType IN (\'Standard\', \'PowerCustomerSuccess\', \'PowerPartner\'))';
        }
        if (objectType == 'Group'){
            return objectType + '(Id, Name, Type)';
        } else {
            return objectType + '(Id, Name)';
        }
    }


    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: SObject type name for given record id
     * Inputs:      Id recordId
     * Output:      SObject type name
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    global static string objectTypeFromId(id recordId){
        return recordId.getSObjectType().getDescribe().getName();
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: get list of sharing rules for given record id
     * Inputs:      Id recordId
     * Output:      JSONified list of sharing rules
     ******************************************************************************************************************************************************************/
    @AuraEnabled
    global static string getSharings(id recordId){
        if (!canIEditPerms(recordId)){
            throw new AuraHandledException('Only the record owner or administrators can access permissions');
        }
        list<sobject> results = database.query(buildQuery(recordId));
        list<SharingHolder> output = new list<SharingHolder>();

        set<id> groupAndUserIDs = new set<id>();
        set<id> RoleIds = new set<id>();

        for (sobject so:results){
            SharingHolder sh = new SharingHolder();
            sh.RowCause = string.valueOf(so.get('RowCause'));
            sh.AccessLevel = string.valueOf(so.get(getAccessLevelField(objectTypeFromId(recordId))));
            sh.UserOrGroupID = string.valueOf(so.get('UserOrGroupID'));
            groupAndUserIDs.add(sh.UserOrGroupID);
            output.add(sh);
        }

        if (!User.Id.getDescribe().isAccessible() ||
              !User.Name.getDescribe().isAccessible() ||
              !User.UserType.getDescribe().isAccessible() ||
              !Group.Id.getDescribe().isAccessible() ||
              !Group.Name.getDescribe().isAccessible() ||
              !Group.Type.getDescribe().isAccessible()
            ) {
            throw new AuraHandledException('You don\'t have the required permissions for this action');
        }
        map<id, user> UserMap = new map<id, user>([select Name, UserType from User where id in: groupAndUserIDs]);
        map<id, group> GroupMap = new map<id, group>([select Name, Type, RelatedId from Group where id in: groupAndUserIDs]);
        for (group g:GroupMap.values()){
            if (g.RelatedId != null){
                RoleIds.add(g.RelatedId);
            }
        }
        map<id, UserRole> RoleMap = new map<id, userrole>([select Name from UserRole where id in: RoleIDs]);

        for (SharingHolder sh:output){
            if (UserMap.get(sh.UserOrGroupID)!=null){
                //it's a user
                sh.UserOrGroupType = 'User';
                sh.UserOrGroupName = UserMap.get(sh.UserOrGroupID).Name;
                sh.SubType = huh(UserMap.get(sh.UserOrGroupID).UserType);
            } else if (GroupMap.get(sh.UserOrGroupID)!=null){
                sh.UserOrGroupType = 'Group';
                sh.SubType = GroupMap.get(sh.UserOrGroupID).Type;
                sh.UserOrGroupName = GroupMap.get(sh.UserOrGroupID).Name;
                //special handling for roles
                if (sh.SubType.contains('Role')){
                    sh.UserOrGroupName = RoleMap.get(GroupMap.get(sh.UserOrGroupID).RelatedId).Name;
                }
            }
        }

        return JSON.serialize(output);
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: build query template to select sharing rules for given record id
     * Inputs:      Id recordId
     * Output:      SOQL query template
     ******************************************************************************************************************************************************************/
    @TestVisible private static string buildQuery(id recordId){
        string sobj = objectTypeFromId(recordId);

        schema.DescribeSObjectResult describe = getSharingDescribe(recordId);

        if (!describe.isAccessible() ||
              !describe.fields.getMap().get('Id').getDescribe().isAccessible() ||
              !describe.fields.getMap().get('RowCause').getDescribe().isAccessible() ||
              !describe.fields.getMap().get('UserOrGroupId').getDescribe().isAccessible() ||
              !describe.fields.getMap().get(getAccessLevelField(sobj)).getDescribe().isAccessible() ||
              !describe.fields.getMap().get(getLookupField(sobj)).getDescribe().isAccessible()
              ){
            throw new AuraHandledException('You don\'t have the required permissions for this action');
        }

        return 'SELECT Id, RowCause, UserOrGroupId, ' + getAccessLevelField(sobj) + ' FROM ' + getSharingTableName(sobj) + ' WHERE ' + getLookupField(sobj) + ' = \'' + recordId + '\'';
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: get human readable user type name
     * Inputs:      standard user type name
     * Output:      human readable user type name or input, as fallback
     * History:     Michael Simkin  - declarative vs imperative
     ******************************************************************************************************************************************************************/
    @TestVisible static final Map<String, String> HUH_MAP = new Map<String, String>{
        'PowerCustomerSuccess' => 'Customer Plus (with Sharing)',
        'PowerPartner'         => 'Partner',
        'CustomerSuccess'      => 'Customer',
        'CsnOnly'              => 'Chatter',
        'CSPLitePortal'        => 'High Volume Customer'
    };
    @TestVisible private static string huh(string userType){
        return HUH_MAP.containsKey(userType) ? HUH_MAP.get(userType) : userType;
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: holder class for JSONification sharing results
     * History:     Michael Simkin  - remove unused getters and setters
     ******************************************************************************************************************************************************************/
    global class SharingHolder {
        global string UserOrGroupName;
        global string SubType;
        global string UserOrGroupType;
        global string UserOrGroupID;
        global string AccessLevel;
        global string RowCause;
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: is given sobject have standard access level field
     * Inputs:      sobject name
     * Output:      Boolean
     * History:     Michael Simkin  - declarative vs imperative
     ******************************************************************************************************************************************************************/
    @TestVisible static final Set<String> SOBJECTS_W_STANDARD_AL_FIELD = new Set<String>{
        'Account', 'Asset', 'Campaign', 'Contact', 'Lead', 'Opportunity', 'User'
    };
    private static boolean isStandard (string sobj){
        //if (sobj=='Account' || sobj=='Asset' || sobj=='Campaign' || sobj =='Case' || sobj=='Contact' || sobj=='Lead' || sobj=='Opportunity' || sobj=='User' ){
        //    return true;
        //}
        //return false;
        return SOBJECTS_W_STANDARD_AL_FIELD.contains(sobj);
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: get parent lookup field name for given sobject name
     * Inputs:      String sobj
     * Output:      lookup field name
     * History:     Michael Simkin  - simplify return statement
     ******************************************************************************************************************************************************************/
    @TestVisible
    private static string getLookupField (string sobj){
        return isStandard(sobj) ? (sobj + 'Id') : 'ParentId';
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: get access level field name for given sobject name
     * Inputs:      String sobj
     * Output:      access level field name
     * History:     Michael Simkin  - simplify return statement
     ******************************************************************************************************************************************************************/
    @TestVisible
    private static string getAccessLevelField (string sobj){
        return isStandard(sobj) ? (sobj + 'AccessLevel') : 'AccessLevel';
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: get sobject sharing rules table name for given sobject name
     * Inputs:      String sobject name
     * Output:      sobject sharing rules table name
     * History:     Michael Simkin - Code beautification 
     ******************************************************************************************************************************************************************/
    @TestVisible
    private static string getSharingTableName (string sobj){
        return sobj.endsWith('__c') ? sobj.replaceFirst('c$', 'Share') : (sobj + 'Share');
    }

    /******************************************************************************************************************************************************************
     * Author:      Shane McLaughlin
     * Description: get schema describe for given record id
     * Inputs:      Id recordId
     * Output:      Schema.DescribeSObjectResult
     ******************************************************************************************************************************************************************/
    @TestVisible
    private static Schema.DescribeSObjectResult getSharingDescribe (id recordId){
        try{
            string sharingName = getSharingTableName(objectTypeFromId(recordId));
            return Schema.getGlobalDescribe().get(sharingName).getDescribe();
        } catch (exception e){
            //probably means they don't have sharing turned on for this object
            throw new AuraHandledException('There is no sharing table for that object. Are you SURE you changed the sharing setting to PRIVATE or READ ? ');
        }
    }

}