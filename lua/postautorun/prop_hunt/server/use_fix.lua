local function use_fix()
	GAMEMODE._PlayerUse = GAMEMODE._PlayerUse or GAMEMODE.PlayerUse

	function GAMEMODE:PlayerUse(ply, ent)
		local ret = self:_PlayerUse(ply, ent)
		if ret == true and table.HasValue(USABLE_PROP_ENTITIES, ent:GetClass()) then ret = false end

		return ret
	end
end

hook.Add("PostGamemodeLoaded", "ph_use_fix", use_fix)
if GAMEMODE then use_fix() end
