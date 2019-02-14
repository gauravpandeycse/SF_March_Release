global class CpqDisableTriggers {

	@InvocableMethod(label='Disable CPQ Triggers in Process Builder')
	global static void cpqDisableTriggers() {
		SBQQ.TriggerControl.disable();
		system.debug('[CpqDisableTriggers][cpqDisableTriggers] CPQ Triggers are now DISABLED');
		IMCDUtils.debugLimits('[CpqDisableTriggers][cpqDisableTriggers]'); // debug output of governor limits
	}
}