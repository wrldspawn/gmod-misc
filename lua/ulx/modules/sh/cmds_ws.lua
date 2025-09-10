function ulx.notarget(calling_ply, target_plys, should_revoke)
	if not target_plys[1]:IsValid() then return end

	local affected_plys = {}
	for _, ply in ipairs(target_plys) do
		if not should_revoke then
			ply:AddFlags(FL_NOTARGET)
		else
			ply:RemoveFlags(FL_NOTARGET)
		end
		table.insert(affected_plys, ply)
	end

	if not should_revoke then
		ulx.fancyLogAdmin(calling_ply, "#A made #T invisible to NPCs", affected_plys)
	else
		ulx.fancyLogAdmin(calling_ply, "#A made #T visible to NPCs", affected_plys)
	end
end

local notarget = ulx.command("Utility", "ulx notarget", ulx.notarget, "!notarget")
notarget:addParam({ type = ULib.cmds.PlayersArg, ULib.cmds.optional })
notarget:addParam({ type = ULib.cmds.BoolArg, invisible = true })
notarget:defaultAccess(ULib.ACCESS_ADMIN)
notarget:help("Makes target(s) invisible to NPCs.")
notarget:setOpposite("ulx yestarget", { nil, nil, true }, "!yestarget")

function ulx.donttouch(calling_ply, target_plys, should_revoke)
	if not target_plys[1]:IsValid() then return end

	local affected_plys = {}
	for _, ply in ipairs(target_plys) do
		if not should_revoke then
			ply:AddFlags(FL_DONTTOUCH)
		else
			ply:RemoveFlags(FL_DONTTOUCH)
		end
		table.insert(affected_plys, ply)
	end

	if not should_revoke then
		ulx.fancyLogAdmin(calling_ply, "#A made #T ignore triggers", affected_plys)
	else
		ulx.fancyLogAdmin(calling_ply, "#A made #T touch triggers again", affected_plys)
	end
end

local donttouch = ulx.command("Utility", "ulx donttouch", ulx.donttouch, "!donttouch")
donttouch:addParam({ type = ULib.cmds.PlayersArg, ULib.cmds.optional })
donttouch:addParam({ type = ULib.cmds.BoolArg, invisible = true })
donttouch:defaultAccess(ULib.ACCESS_ADMIN)
donttouch:help("Makes target(s) ignore touching triggers.")
donttouch:setOpposite("ulx dotouch", { nil, nil, true }, "!dotouch")

function ulx.fov(calling_ply, target_plys, value)
	if not target_plys[1]:IsValid() then return end

	local affected_plys = {}
	for _, ply in ipairs(target_plys) do
		ply:SetFOV(value)
		table.insert(affected_plys, ply)
	end

	if value == 0 then
		ulx.fancyLogAdmin(calling_ply, "#A reset FOV for #T", affected_plys)
	else
		ulx.fancyLogAdmin(calling_ply, "#A set FOV for #T to #i", affected_plys, value)
	end
end

local fov = ulx.command("Utility", "ulx fov", ulx.fov, "!fov")
fov:addParam({ type = ULib.cmds.PlayersArg, ULib.cmds.optional })
fov:addParam({ type = ULib.cmds.NumArg, default = 0, min = 0, max = 256, hint = "fov" })
fov:defaultAccess(ULib.ACCESS_ALL)
fov:help("Set target(s) FOV.")

local gmod_maxammo = GetConVar("gmod_maxammo")
function ulx.giveammo(calling_ply, target_plys, amount, setammo)
	if not target_plys[1]:IsValid() then return end
	local maxammo = gmod_maxammo:GetInt()
	if amount == nil then amount = maxammo end
	if not setammo and maxammo > 0 then
		amount = math.min(amount, maxammo)
	end

	local affected_plys = {}
	for _, ply in ipairs(target_plys) do
		local wep = ply:GetActiveWeapon()
		if wep:IsValid() then
			local typePrimary = wep:GetPrimaryAmmoType()
			local typeSecondary = wep:GetSecondaryAmmoType()

			if typePrimary ~= -1 or typeSecondary ~= -1 then
				if not setammo then
					if typePrimary ~= -1 then ply:GiveAmmo(amount, typePrimary) end
					if typeSecondary ~= -1 then ply:GiveAmmo(amount, typeSecondary) end
				else
					if typePrimary ~= -1 then ply:SetAmmo(amount, typePrimary) end
					if typeSecondary ~= -1 then ply:SetAmmo(amount, typeSecondary) end
				end
				table.insert(affected_plys, ply)
			end
		end
	end

	if not setammo then
		ulx.fancyLogAdmin(calling_ply, "#A gave #T #i ammo", target_plys, amount)
	else
		ulx.fancyLogAdmin(calling_ply, "#A set the ammo for #T to #i", target_plys, amount)
	end
end

local giveammo = ulx.command("Utility", "ulx giveammo", ulx.giveammo, "!giveammo")
giveammo:addParam({ type = ULib.cmds.PlayersArg, ULib.cmds.optional })
giveammo:addParam({
	type = ULib.cmds.NumArg,
	min = 0,
	default = 9999,
	hint = "amount",
	ULib.cmds.optional,
	ULib.cmds.round
})
giveammo:addParam({ type = ULib.cmds.BoolArg, invisible = true })
giveammo:defaultAccess(ULib.ACCESS_ADMIN)
giveammo:help("Give target(s) ammo.")
giveammo:setOpposite("ulx setammo", { nil, nil, nil, true }, "!setammo")
