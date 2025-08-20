local hooks = hook.GetTable()
if epoe and hooks.EPOE and hooks.EPOE.EPOE_CLI then
	local oldEPOE_CLI = hooks.EPOE.EPOE_CLI

	hook.Add("EPOE", "EPOE_CLI", function(Text, flags, col)
		flags = flags or 0
		if LocalPlayer():IsListenServerHost() and not epoe.HasFlag(flags, epoe.IS_EPOE) then return end

		oldEPOE_CLI(Text, flags, col)
	end)
end
