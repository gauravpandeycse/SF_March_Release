<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Uncheck_the_bypass_checkbox</fullName>
        <field>bypassEditValidationRule__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck the bypass checkbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Lock record for Editing</fullName>
        <actions>
            <name>Uncheck_the_bypass_checkbox</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>SharingAccess__c.bypassEditValidationRule__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Uncheck bypassEditValidationRule__c checkbox, to activate Validation Rule that prevents editing SharingAccess records</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
