if not HolyLib then return end

local enabled = CreateConVar("sv_ignoreauth", "1", FCVAR_ARCHIVE, "Ignore Steam auth requests", 0, 1)

hook.Add("HolyLib:OnNotifyClientConnect", "ignoreauth", function()
	if enabled:GetBool() then
		return true
	end
end)
