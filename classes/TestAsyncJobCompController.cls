@IsTest
private class TestAsyncJobCompController {
	@IsTest
	static void testgetSharingJobs () {
		List<aggregateResult> results = AsyncJobCompController.getSharingJobs();
		system.assert(results.size() == 0);
	}
}