public with sharing class AccountSummaryController {

	public ID accountId  {
		get {
			if (Test.isRunningTest()) return UserInfo.getUserId(); else return ApexPages.currentPage().getParameters().get('id');
		}
	}
	public Integer numrows   { get { return 50; } } // showing max num rows supported by CMDT Enhanced Related List package
}