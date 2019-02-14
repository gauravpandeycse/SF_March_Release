@IsTest
private class TestAccountSummaryController {
	@IsTest
	static void testAccountSummaryController () {
		AccountSummaryController acs = new AccountSummaryController();
		System.assert(acs.numrows == 50);
		System.assert(UserInfo.getUserId() == acs.accountId);
	}
}