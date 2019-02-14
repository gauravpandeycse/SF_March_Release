global class QuoteThrottledRecalculateSchedulable implements Schedulable {
    
global void execute(SchedulableContext sc) {
    ID BatchId = Database.executeBatch(new QuoteThrottledRecalculate_Batch(), 1);
  }
    
    global static void scheduleMe()  {
    String CRON_EXP = '0 0 * * * ?'; 
QuoteThrottledRecalculateSchedulable qtr = new QuoteThrottledRecalculateSchedulable(); 
system.schedule('Hourly QuoteThrottledRecalculateBatch', CRON_EXP, qtr);
    }  
}