public with sharing class PriceRenewalCampaignSchedule implements Schedulable{
/******************************************************************************************************************************************************************
 * Author: 		Wim van Beek
 * Company: 	Salesforce / NNcourage
 * Description: PriceRenewalCampaign Scheduler
 *                  Started by various schedulded jobs. 
 *					1 Starts PriceRenewalCampaignUtils.futureProcessing(thisUser) 
 *					2 Cancel current job
 *					3 Reschedule new job (next minute)
 *
 * Inputs		None
 * Test Class : 
 * History :  	New 4-2018. 
 *              12-18. Better control when creating new scheduled job to avoid errors on limmited resources
 ******************************************************************************************************************************************************************/

 	
	// Main entry-point of scheduled process
	public void execute(SchedulableContext sc){
		Id jobId = sc.getTriggerId();
		String cronName;	
		Id thisUser = Userinfo.getUserid();

		CronTrigger ct = [SELECT  CronJobDetailId, CronExpression, Id, OwnerId FROM CronTrigger WHERE Id = : jobId];

		// Get the name of the current CronTab entry
		for (CronJobDetail ctd : [SELECT Id, Name, JobType FROM CronJobDetail WHERE Id = : ct.CronJobDetailId ]){
			cronName= ctd.Name;
			system.debug('------ cronName '+ cronName);
		}
		Integer jobsLeft= 0;
		jobsLeft = (90 - [SELECT count()  FROM CronJobDetail WHERE JobType = '7']);  // get remaining cronjobs
		system.debug('------ jobsLeft '+ jobsLeft);
		if ( cronName.indexOf('_next_')  > 0 ) {  // Next jobs only
			if (jobsLeft > 0){
				System.abortJob(jobId);  // Abort current Scheduled Job
			}
			if (PriceRenewalCampaignUtils.allCampaignsItemsDone(thisUser) ){} else  {  // All Items done ?
				if (jobsLeft > 0){
					PriceRenewalCampaignUtils.startSchedulder(thisUser, null, 'next');
				}
			    PriceRenewalCampaignUtils.futureProcessing(thisUser);
			}
		} else {   // Main jobs
			if (PriceRenewalCampaignUtils.allCampaignsItemsDone(thisUser)  ){  // All Campaigns done
				System.abortJob(JobId);
			} else {
				PriceRenewalCampaignUtils.startSchedulder(thisUser, null, 'next');
			    PriceRenewalCampaignUtils.futureProcessing(thisUser);
			}
		}
	}
}