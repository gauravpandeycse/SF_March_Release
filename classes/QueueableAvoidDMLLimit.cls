/******************************************************************************************************************************************************************
* Author: Eli Pogorelov
* Company: Salesforce
* Description: Queueable for DML operation for large volume of records when hitting the 10000 DML Limit , calls to itself
* untill all records are inserted/deleted
* Inputs : List<AccountShare>, List<OpportunityShare>, List<SBQQ__Quote__Share>
* Test Class :
* History :
***********************************************************************************************************************/
public without sharing class QueueableAvoidDMLLimit implements Queueable
{
    List<AccountShare> accShareList = new List<AccountShare>();
    List<OpportunityShare> oppShareList = new List<OpportunityShare>();
    List<SBQQ__Quote__Share> quoteShareList = new List<SBQQ__Quote__Share>();

    public enum shareSobject {ACCOUNTSHARING,OPPORTUNITYSHARING,QUOTESHARING, ACCOUNTANDOPPORTUNITYSHARING, ACCOUNTANDQUOTESHARING, OPPORTUNITYANDQUOTESHARING, ALL}

    shareSobject whatShared ;

    Boolean insertFlag = false ;

    public QueueableAvoidDMLLimit(List<AccountShare> accShareList,List<OpportunityShare> oppShareList, List<SBQQ__Quote__Share> quoteShareList, Boolean insertFlag)
    {
        this.accShareList = accShareList;
        this.oppShareList = oppShareList;
        this.quoteShareList = quoteShareList;
        this.insertFlag = insertFlag ;

        if(accShareList.size() > 0)
        {
            Boolean flag = false;
            if(oppShareList.size() > 0)
            {
                whatShared = shareSobject.ACCOUNTANDOPPORTUNITYSHARING;
                flag = true;
            }
            if(quoteShareList.size() > 0)
            {
                whatShared = shareSobject.ACCOUNTANDQUOTESHARING;
                if(flag)
                {
                    whatShared = shareSobject.ALL;
                }
            }
            else
            {
                whatShared = shareSobject.ACCOUNTSHARING;
            }
        }
        else if(oppShareList.size() > 0)
        {
            if(quoteShareList.size() > 0)
            {
                whatShared = shareSobject.OPPORTUNITYANDQUOTESHARING;
            }
            else
            {
                whatShared =shareSobject.OPPORTUNITYSHARING;
            }
        }
        else
        {
            whatShared = shareSobject.QUOTESHARING;
        }
    }

    public void execute(QueueableContext context)
    {
        try
        {
            Switch on whatShared
            {
                when ACCOUNTSHARING
                {
                    system.debug('+++ACCOUNTSHARING in SWITCH : ' + accShareList);
                    if(accShareList.size() > SharingUtils.numOfDMLThatCanBeProcessed() && !Test.isRunningTest())
                    {
                        SharingUtils.insertOrDeleteAccSharesAndInitRemains(accShareList, insertFlag);
                        SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                    }
                    else if(accShareList.size() <= SharingUtils.numOfDMLThatCanBeProcessed() && !Test.isRunningTest())
                    {
                        if(insertFlag)
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareList, true);
                        }
                        else
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareList, false);
                        }
                    }
                }
                when OPPORTUNITYSHARING
                {
                    system.debug('+++OPPORTUNITYSHARING in SWITCH : ' + oppShareList);
                    if(oppShareList.size() > SharingUtils.numOfDMLThatCanBeProcessed() && !Test.isRunningTest())
                    {
                        SharingUtils.insertOrDeleteOppSharesAndInitRemains(oppShareList,insertFlag);
                        SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                    }
                    else if(oppShareList.size() <= SharingUtils.numOfDMLThatCanBeProcessed() && !Test.isRunningTest())
                    {
                        if(insertFlag)
                        {
                            SharingUtils.dmlOperationOnShareRecords(oppShareList, true);
                        }
                        else
                        {
                            SharingUtils.dmlOperationOnShareRecords(oppShareList, false);
                        }
                    }
                }
                when QUOTESHARING
                {
                    system.debug('+++QUOTESHARING in SWITCH : ' + quoteShareList);
                    if(quoteShareList.size() > SharingUtils.numOfDMLThatCanBeProcessed() && !Test.isRunningTest())
                    {
                        SharingUtils.insertOrDeleteQtSharesAndInitRemains(quoteShareList, insertFlag);
                        SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                    }
                    else if(quoteShareList.size() <= SharingUtils.numOfDMLThatCanBeProcessed() && !Test.isRunningTest())
                    {
                        if(insertFlag)
                        {
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, true);
                        }
                        else
                        {
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, false);
                        }

                    }
                }
                when ACCOUNTANDOPPORTUNITYSHARING
                {
                    system.debug('+++ACCOUNTANDOPPORTUNITYSHARING in SWITCH : ' + accShareList);
                    system.debug('+++QACCOUNTANDOPPORTUNITYSHARING in SWITCH : ' + quoteShareList);
                    Boolean remainsStillExist = SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareList,oppShareList, insertFlag);
                    if(remainsStillExist)
                    {
                        SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                    }
                }
                when ACCOUNTANDQUOTESHARING
                {
                    system.debug('+++ACCOUNTANDQUOTESHARING in SWITCH : ' + accShareList);
                    system.debug('+++ACCOUNTANDQUOTESHARING in SWITCH : ' + quoteShareList);
                    if((accShareList.size() + quoteShareList.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) && !Test.isRunningTest() )
                    {
                        Boolean remainsStillExist = SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(accShareList,quoteShareList, insertFlag);
                        if(remainsStillExist)
                        {
                            SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                        }
                    }
                    else
                    {
                        if(insertFlag)
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareList, true);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, true);
                        }
                        else
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareList, false);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, false);
                        }
                    }
                }
                when OPPORTUNITYANDQUOTESHARING
                {
                    system.debug('+++OPPORTUNITYANDQUOTESHARING in SWITCH : ' + oppShareList);
                    system.debug('+++OPPORTUNITYANDQUOTESHARING in SWITCH : ' + quoteShareList);
                    if((oppShareList.size() + quoteShareList.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) && !Test.isRunningTest() )
                    {
                        Boolean remainsStillExist = SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareList,quoteShareList, insertFlag);
                        if(remainsStillExist)
                        {
                            SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                        }
                    }
                    else
                    {

                        if(insertFlag)
                        {
                            SharingUtils.dmlOperationOnShareRecords(oppShareList, true);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, true);
                        }
                        else
                        {
                            SharingUtils.dmlOperationOnShareRecords(oppShareList, false);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, false);
                        }
                    }
                }
                when ALL
                {
                    system.debug('+++ALL in SWITCH : ' + oppShareList);
                    system.debug('+++ALL in SWITCH : ' + oppShareList);
                    system.debug('+++ALL in SWITCH : ' + quoteShareList);
                    if((accShareList.size() + oppShareList.size() + quoteShareList.size() >= SharingUtils.numOfDMLThatCanBeProcessed()) && !Test.isRunningTest() )
                    {
                        Boolean remainsStillExist = SharingUtils.checkForDMLlimitAndInsertOrDeleteSharingRemains(oppShareList,quoteShareList, insertFlag);
                        if(remainsStillExist)
                        {
                            SharingUtils.createAndRunAvoidDMLJob(accShareList,oppShareList,quoteShareList, insertFlag);
                        }
                    }
                    else
                    {
                        if(insertFlag)
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareList, true);
                            SharingUtils.dmlOperationOnShareRecords(oppShareList, true);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, true);
                        }
                        else
                        {
                            SharingUtils.dmlOperationOnShareRecords(accShareList, false);
                            SharingUtils.dmlOperationOnShareRecords(oppShareList, false);
                            SharingUtils.dmlOperationOnShareRecords(quoteShareList, false);
                        }
                    }
                }
                when else
                {
                    DebugLog.addError('No case matched in switch in class : QueueableAvoidDMLLimit');
                }
            }
            system.debug('+++QueueableAvoidDMLLimit getHeapSize()'+ Limits.getHeapSize());
        }
        catch(Exception ex)
        {
            DebugLog.addException(ex, 'QueueableAvoidDMLLimit') ;
        }
    }
}