global class CpqEnableTriggers {

	@InvocableMethod(label='Enable CPQ Triggers in Process Builder')
	global static void cpqEnableTriggers() {
		SBQQ.TriggerControl.enable();
		system.debug('[CpqEnableTriggers][cpqEnableTriggers] CPQ Triggers are now ENABLED');
		IMCDUtils.debugLimits('[CpqEnableTriggers][cpqEnableTriggers]'); // debug output of governor limits
	}
}