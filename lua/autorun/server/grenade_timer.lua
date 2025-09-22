local TAG = "grenade_timer"

hook.Add("KeyPress", TAG, function(ply, key)
	if not IsValid(ply) then return end
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "weapon_frag" then return end
	if key ~= IN_RELOAD then return end

	local timer = ply._grenade_timer or 2.5
	if timer == 2.5 then
		timer = 1
	elseif timer == 1 then
		timer = 0.5
	elseif timer == 0.5 then
		timer = 5
	elseif timer == 5 then
		timer = 2.5
	end
	ply._grenade_timer = timer

	ply:PrintMessage(HUD_PRINTCENTER, "Detonates: " .. timer .. " second" .. (timer == 1 and "" or "s"))
end)

hook.Add("WeaponEquip", TAG, function(wep, ply)
	if not IsValid(ply) then return end
	if not IsValid(wep) or wep:GetClass() ~= "weapon_frag" then return end

	ply._grenade_timer = 2.5
end)

hook.Add("OnEntityCreated", TAG, function(ent)
	if not IsValid(ent) then return end
	if ent:GetClass() ~= "npc_grenade_frag" then return end

	timer.Simple(0, function()
		if not IsValid(ent) then return end
		local owner = ent:GetInternalVariable("m_hOwnerEntity")
		if IsValid(owner) then
			ent:Fire("SetTimer", tostring(owner._grenade_timer or 2.5))
		end
	end)
end)
