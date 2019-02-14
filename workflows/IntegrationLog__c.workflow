<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Status_Delivery_Failed</fullName>
        <description>In case the Delivery fails (the IntegrationLog__c record stays for &gt; 24 hours with Status = Message Triggered) the Status__c of the records is set to Delivery Failed</description>
        <field>Status__c</field>
        <literalValue>Delivery Failed</literalValue>
        <name>Update Status = Delivery Failed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_Message_Triggered</fullName>
        <description>Updates the Status to Message triggered.</description>
        <field>Status__c</field>
        <literalValue>Message Triggered</literalValue>
        <name>Update Status = Message Triggered</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <outboundMessages>
        <fullName>Send_Outbound_Notification_Message</fullName>
        <apiVersion>42.0</apiVersion>
        <endpointUrl>https://talendprod.imcd.biz:9001/services/prod/outbound</endpointUrl>
        <fields>Event__c</fields>
        <fields>Id</fields>
        <fields>ImcdCompany__c</fields>
        <fields>IntegrationId__c</fields>
        <fields>ObjectId__c</fields>
        <fields>Object__c</fields>
        <includeSessionId>false</includeSessionId>
        <integrationUser>jburgers@imcdgroup.com</integrationUser>
        <name>Send Outbound Notification Message</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <rules>
        <fullName>Send Outbound Notification Message</fullName>
        <actions>
            <name>Update_Status_Message_Triggered</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Send_Outbound_Notification_Message</name>
            <type>OutboundMessage</type>
        </actions>
        <active>true</active>
        <description>Workflow responsible for sending the Outbound Message to Talend.</description>
        <formula>IF ( 	AND ( $Setup.Global_Bypass_Processes_Settings__c.Run_Workflows_Rules__c 			, isGroupErp__c 			, ISPICKVAL(Status__c, &apos;Queued&apos;) 	)  	, true  	, false )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Update_Status_Delivery_Failed</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>24</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
