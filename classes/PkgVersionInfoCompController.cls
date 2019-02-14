/*------------------------------------------------------------
Author:        Jeroen Burgers
Company:       Salesforce
History
	03/09/2018     Created class
------------------------------------------------------------*/
without sharing public class PkgVersionInfoCompController {
	@AuraEnabled
	public static List<Publisher> getPackageInfo() {
		return (
		[
			SELECT
				MajorVersion,
				MinorVersion,
				Name,
				NamespacePrefix
			FROM
				Publisher
			WHERE
				NamespacePrefix IN ('SBQQ','sbaa','webm')]
		);
	}
}