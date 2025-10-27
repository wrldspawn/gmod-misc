local TAG = "PlayerStatus"

local PLAYER = FindMetaTable("Player")

local statusicons = setmetatable({}, { __mode = "k" })

if SERVER then
	util.AddNetworkString(TAG)
	local lagging = setmetatable({}, { __mode = "k" })
	local spawning = {}

	local function updateIcon(ply, icon)
		if icon == nil then
			icon = "none"
		end

		net.Start(TAG)
		net.WritePlayer(ply)
		net.WriteString(icon)
		net.Broadcast()
	end

	local function formatTime(duration)
		local minutes = math.floor(duration / 60)
		local seconds = math.floor(duration % 60)

		local timeStr = ""
		if minutes > 0 then
			local s = tostring(seconds)
			if seconds < 10 then
				s = "0" .. s
			end
			timeStr = tostring(minutes) .. ":" .. s .. " minute"
		else
			timeStr = seconds .. " second"
		end

		return timeStr
	end

	hook.Add("PlayerPostThink", TAG, function(ply)
		if ply:IsTimingOut() then
			if not lagging[ply] then
				lagging[ply] = SysTime()
				statusicons[ply] = "timingout"
				updateIcon(ply, "timingout")

				Msg("[Player Lag] ")
				print(tostring(ply) .. " timing out")

				if AddHUDNotify then
					AddHUDNotify(ply:Name() .. " is timing out.")
				end
			end
		elseif lagging[ply] ~= nil then
			local duration = SysTime() - lagging[ply]
			lagging[ply] = nil

			local icon = PLAYER.IsAFK and ply:IsAFK() and "afk" or nil
			statusicons[ply] = icon
			updateIcon(ply, icon)

			local time = formatTime(duration)
			local first = string.Explode(":", time)[1]
			local a_or_an = (first == "8" or first == "11") and "an " or "a "

			Msg("[Player Lag] ")
			print(tostring(ply) .. " recovered from " .. a_or_an .. time .. " lag spike")

			if AddHUDNotify then
				AddHUDNotify(ply:Name() .. " recovered from " .. a_or_an .. time .. " lag spike.")
			end
		end
	end)
	hook.Add("PlayerDisconnected", TAG, function(ply)
		if lagging[ply] then
			local duration = SysTime() - lagging[ply]
			lagging[ply] = nil

			local time = formatTime(duration)
			Msg("[Player Lag] ")
			print(tostring(ply) .. " disconnected after " .. time .. " lag spike")

			if AddHUDNotify then
				AddHUDNotify(ply:Name() .. " lost against a lag spike.")
			end
		end
	end)

	hook.Add("PlayerAFK", TAG, function(ply, is_afk)
		if is_afk then
			if statusicons[ply] == nil then
				statusicons[ply] = "afk"
				updateIcon(ply, "afk")
			end
		else
			statusicons[ply] = nil
			updateIcon(ply, nil)
		end
	end)

	hook.Add("PlayerInitialSpawn", TAG, function(ply)
		if ply:IsBot() then return end
		spawning[ply:UserID()] = true

		statusicons[ply] = "spawning"
		updateIcon(ply, "spawning")
	end)
	gameevent.Listen("OnRequestFullUpdate")
	hook.Add("OnRequestFullUpdate", TAG, function(data)
		local uid = data.userid
		if not spawning[uid] then return end

		spawning[uid] = nil
		local ply = Player(uid)

		local icon = PLAYER.IsAFK and ply:IsAFK() and "afk" or nil
		statusicons[ply] = icon
		updateIcon(ply, icon)

		if AddHUDNotify then
			AddHUDNotify(ply:Name() .. " finished connecting.")
		end

		for p, i in next, statusicons do
			net.Start(TAG)
			net.WritePlayer(p)
			net.WriteString(i)
			net.Send(ply)
		end
	end)
elseif CLIENT then
	local ICONS = {
		afk = Material("icon16/status_away.png"),
		timingout = Material("icon16/computer_error.png"),
		spawning = Material("icon16/server_connect.png"),
	}

	net.Receive(TAG, function()
		local ply = net.ReadPlayer()
		if not IsValid(ply) then return end

		local icon = net.ReadString()

		statusicons[ply] = icon == "none" and nil or icon
	end)

	local OFFSET = Vector(0, 0, 12)
	local NO_HDR = Vector(0.6, 0, 0)
	hook.Add("PostDrawTranslucentRenderables", TAG, function(depth, skybox, sky3d)
		if skybox then return end
		local lply = LocalPlayer()

		for _, ply in player.Iterator() do
			if not IsValid(ply) then return end
			if not ply:Alive() then return end
			if ply == lply and not ply:ShouldDrawLocalPlayer() then return end
			local icon = statusicons[ply]
			if icon == nil then return end
			local icon_mat = ICONS[icon]
			if not icon_mat then return end

			local ang = lply:EyeAngles()
			local pos = ply:EyePos() + OFFSET + ang:Up()

			ang:RotateAroundAxis(ang:Forward(), 90)
			ang:RotateAroundAxis(ang:Right(), 90)

			local tone = render.GetToneMappingScaleLinear()
			render.SetToneMappingScaleLinear(NO_HDR)
			cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.5)
			render.PushFilterMag(TEXFILTER.POINT)
			render.PushFilterMin(TEXFILTER.POINT)
			surface.SetMaterial(icon_mat)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(-8, 0, 16, 16)
			render.PopFilterMin()
			render.PopFilterMag()
			cam.End3D2D()
			render.SetToneMappingScaleLinear(tone)
		end
	end)
end
