local TAG = "PlayerStatus_AFK"

local mp_afktime = CreateConVar("mp_afktime", "90", bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY))
local afk_times = setmetatable({}, { __mode = "k" })

local PLAYER = FindMetaTable("Player")
function PLAYER:IsAFK()
	return afk_times[self] ~= nil
end

function PLAYER:GetAFKTime()
	local time = afk_times[self]
	return time and CurTime() - time or 0
end

function PLAYER:AFKTime()
	return PLAYER.GetAFKTime(self)
end

if SERVER then
	util.AddNetworkString(TAG)

	net.Receive(TAG, function(len, ply)
		local is_afk = net.ReadBool()
		local start = CurTime() - mp_afktime:GetFloat()
		local duration = 0

		if not is_afk then
			duration = CurTime() - afk_times[ply]
		end
		afk_times[ply] = is_afk and start or nil

		hook.Run("PlayerAFK", ply, is_afk, duration, start)

		net.Start(TAG)
		net.WritePlayer(ply)
		net.WriteBool(is_afk)
		net.WriteFloat(start)
		net.WriteFloat(duration)
		net.Broadcast()
	end)

	hook.Add("PlayerAFK", TAG, function(ply, is_afk, duration)
		local sound = hook.Run("ShouldPlayAFKSound", ply)
		if sound == nil or sound then
			ply:EmitSound(is_afk and "replay/cameracontrolmodeexited.wav" or "replay/cameracontrolmodeentered.wav")
		end

		if AddHUDNotify then
			if is_afk then
				ply._afk_count = (ply._afk_count or 0) + 1
				local c = ply._afk_count

				if c > 2 then
					local suffix = "th"
					if c % 10 == 3 and c ~= 13 then
						suffix = "rd"
					end
					if c % 10 == 2 and c ~= 12 then
						suffix = "nd"
					end
					if c % 10 == 1 and c ~= 11 then
						suffix = "st"
					end

					AddHUDNotify(ply:Name() .. " is AFK for the " .. c .. suffix .. " time.")
				elseif c > 1 then
					AddHUDNotify(ply:Name() .. " is AFK again.")
				else
					AddHUDNotify(ply:Name() .. " is AFK.")
				end
			else
				local minutes = math.floor(duration / 60)
				local seconds = math.floor(duration % 60)

				local timeStr = ""
				if minutes > 0 then
					local s = tostring(seconds)
					if seconds < 10 then
						s = "0" .. s
					end
					timeStr = tostring(minutes) .. ":" .. s .. " minutes"
				else
					timeStr = seconds .. " seconds"
				end

				AddHUDNotify(ply:Name() .. " was AFK for " .. timeStr .. ".")
			end
		end
	end)

	local queue = {}
	hook.Add("PlayerInitialSpawn", TAG, function(ply)
		queue[ply:UserID()] = true
	end)
	gameevent.Listen("OnRequestFullUpdate")
	hook.Add("OnRequestFullUpdate", TAG, function(data)
		local uid = data.userid
		if not queue[uid] then return end

		queue[uid] = nil
		local recv = Player(uid)

		for ply, time in next, afk_times do
			net.Start(TAG)
			net.WritePlayer(ply)
			net.WriteBool(true)
			net.WriteFloat(time)
			net.WriteFloat(CurTime() - time)
			net.Send(recv)
		end
	end)
elseif CLIENT then
	net.Receive(TAG, function()
		local ply = net.ReadPlayer()
		if not IsValid(ply) then return end

		local is_afk = net.ReadBool()
		local start = net.ReadFloat()
		local duration = net.ReadFloat()

		afk_times[ply] = is_afk and start or nil

		hook.Run("PlayerAFK", ply, is_afk, duration, start)
	end)

	local is_afk = false
	local last_keys = {}
	local last_mouse_x = 0
	local last_mouse_y = 0
	local last_focus = nil
	local last_moved = 0

	local function sendAFK(afk)
		net.Start(TAG)
		net.WriteBool(afk)
		net.SendToServer()
	end

	timer.Create(TAG, 0.25, 0, function()
		local now = SysTime()

		for i = KEY_FIRST, KEY_LAST do
			local is_down = input.IsKeyDown(i)
			if last_keys[i] ~= is_down then
				last_moved = now
				last_keys[i] = is_down
			end
		end

		local x, y = input.GetCursorPos()

		if x ~= last_mouse_x then
			last_moved = now
		end

		last_mouse_x = x

		if y ~= last_mouse_y then
			last_moved = now
		end

		last_mouse_y = y

		local focus = system.HasFocus()

		if focus ~= last_focus then
			last_moved = now
		end

		last_focus = focus

		local start = now - last_moved

		if start > mp_afktime:GetFloat() then
			if not is_afk then
				is_afk = true
				sendAFK(is_afk)
			end
		elseif is_afk then
			is_afk = false
			sendAFK(is_afk)
		end
	end)
end
