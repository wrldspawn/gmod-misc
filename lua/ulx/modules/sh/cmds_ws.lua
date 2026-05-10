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

if util.IsBinaryModuleInstalled("workshop") then
	pcall(require, "workshop")
	if steamworks.DownloadUGC then
		local ulx_votemapVetotime = GetConVar("ulx_votemapVetotime")

		function ulx.wsmap(calling_ply, wsid)
			if wsid == nil then return end

			ulx.fancyLogAdmin(calling_ply, "#A attempting to download workshop addon #q", wsid)
			steamworks.FileInfo(wsid, function(info)
				if info == nil then
					Msg("[wsmap] ")
					print(string.format("Failed to fetch info for %q", wsid))
					ULib.tsay(calling_ply, "Failed to fetch workshop addon info", true)
					return
				end

				ULib.tsay(nil, string.format("Server is now downloading %q...", info.title or wsid), true)
				steamworks.DownloadUGC(wsid, function(path, _f)
					if path == nil then
						Msg("[wsmap] ")
						print(string.format("Failed to download %q", wsid))
						ULib.tsay(nil, "Failed to download workshop addon", true)
						return
					end

					ULib.tsay(nil, "Server is now mounting addon", true)
					local succ, files = game.MountGMA(path)
					if not succ then
						Msg("[wsmap] ")
						print(string.format("Failed to mount %q", wsid))
						ULib.tsay(nil, "Failed to mount workshop addon", true)
						return
					end

					local map
					for _, f in ipairs(files) do
						if not string.match(f, "maps/.-%.bsp") then continue end
						map = string.GetFileFromFilename(string.StripExtension(f))
						break
					end

					if map == nil then
						Msg("[wsmap] ")
						print(string.format("Addon %q contains no maps", wsid))
						ULib.tsay(nil, "Workshop addon has no maps", true)
						return
					end

					local vetotime = ulx_votemapVetotime:GetInt()
					local admins = {}
					for _, ply in player.Iterator() do
						if ply:IsConnected() and ULib.ucl.query(ply, "ulx veto") then
							admins[#admins + 1] = ply
						end
					end

					if #admins <= 0 or vetotime < 1 then
						ULib.tsay(nil, string.format("Changing map to %q...", map), true)
						ulx.logString(string.format("Changing to workshop map %q (%s)", map, wsid))
						file.Write("wsmap_lastmap.txt", map .. ":" .. wsid)
						game.ConsoleCommand("changelevel " .. map .. "\n")
					else
						ULib.tsay(nil, string.format("Changing map to %q in %d seconds", map, vetotime), true)
						for _, ply in ipairs(admins) do
							ULib.tsay(ply, 'To veto this map change, just say "!veto"', true)
						end
						ulx.logString(string.format("Changing to workshop map %q (%s). Pending admin veto.", map, wsid))
						ulx.timedVeto = true
						hook.Call(ulx.HOOK_VETO)
						timer.Create("ULXVotemap", vetotime, 1, function()
							file.Write("wsmap_lastmap.txt", map .. ":" .. wsid)
							game.ConsoleCommand("changelevel " .. map .. "\n")
						end)
					end
				end)
			end)
		end

		local wsmap = ulx.command("Utility", "wsmap", ulx.wsmap, "!wsmap")
		wsmap:addParam({
			type = ULib.cmds.StringArg,
			hint = "workshopid",
		})
		wsmap:defaultAccess(ULib.ACCESS_ADMIN)
		wsmap:help("Download a map from the workshop and switch to it")
	end
end
if file.Exists("wsmap_lastmap.txt", "DATA") then
	local data = file.Read("wsmap_lastmap.txt", "DATA")
	local split = string.Explode(":", data)
	local map = split[1]
	local wsid = split[2]

	if map ~= nil and wsid ~= nil and game.GetMap() == map then
		resource.AddWorkshop(wsid)
	end
end
