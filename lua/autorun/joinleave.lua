local TAG = "joinleave"

local MSG_CONNECT = 0
local MSG_DISCONNECT = 1
local MSG_SPAWNED = 2
local MSG_UPDATE_COLOR = 3

if SERVER then
	util.AddNetworkString(TAG)

	local connecttimes = {}

	gameevent.Listen("player_connect")
	hook.Add("player_connect", TAG, function(data)
		if tobool(data.bot) then return end

		connecttimes[data.userid] = {
			connect = SysTime()
		}

		net.Start(TAG)
		net.WriteUInt(MSG_CONNECT, 3)
		net.WriteString(data.name)
		net.WriteString(data.networkid)
		net.Broadcast()
	end)

	gameevent.Listen("player_disconnect")
	hook.Add("player_disconnect", TAG, function(data)
		local gaveup = false
		local time = connecttimes[data.userid]
		if time then
			if not time.spawned then gaveup = true end
			connecttimes[data.userid] = nil
		end

		net.Start(TAG)
		net.WriteUInt(MSG_DISCONNECT, 3)
		net.WriteBool(gaveup)
		net.WriteInt(data.userid, 32)
		net.WriteString(data.name)
		net.WriteString(data.networkid)
		net.WriteString(data.reason)
		net.Broadcast()
	end)

	hook.Add("PlayerInitialSpawn", TAG, function(ply)
		if not ply:IsBot() then
			local uid = ply:UserID()
			if not connecttimes[uid] then
				connecttimes[uid] = {}
			end
			connecttimes[uid].spawned = SysTime()
		end

		net.Start(TAG)
		net.WriteUInt(MSG_SPAWNED, 3)
		net.WritePlayer(ply)
		net.WriteString(ply:Name())
		net.WriteString(ply:SteamID())
		net.Broadcast()
	end)

	gameevent.Listen("OnRequestFullUpdate")
	hook.Add("OnRequestFullUpdate", TAG, function(data)
		local times = connecttimes[data.userid]
		if not times then return end
		local now = SysTime()

		local spawnDelta = math.ceil(times.spawned - (times.connect or times.spawned))
		local netDelta = math.ceil(now - times.spawned)

		MsgN(data.name .. " connected in " .. spawnDelta .. "s (spawned in " .. netDelta .. "s)")

		connecttimes[data.userid] = nil
	end)

	hook.Add("PlayerChangedTeam", TAG, function(ply)
		net.Start(TAG)
		net.WriteUInt(MSG_UPDATE_COLOR, 3)
		net.WritePlayer(ply)
		net.Broadcast()
	end)
elseif CLIENT then
	local COLOR_PREFIX = Color(128, 128, 255)
	local COLOR_WHITE = Color(255, 255, 255)
	local COLOR_GRAY = Color(164, 164, 164)
	local COLOR_GREEN = Color(128, 255, 128)
	local COLOR_RED = Color(255, 128, 128)
	local COLOR_YELLOW = Color(255, 255, 100)

	local teamcolors = {}

	net.Receive(TAG, function()
		local msg = net.ReadUInt(3)

		if msg == MSG_CONNECT then
			local name = net.ReadString()
			local steamid = net.ReadString()

			chat.AddText(COLOR_GREEN, "+ ", COLOR_PREFIX, name, COLOR_GRAY, " (" .. steamid .. ") ", COLOR_WHITE,
				"is connecting")
		elseif msg == MSG_DISCONNECT then
			local gaveup = net.ReadBool()
			local userid = net.ReadInt(32)
			local name = net.ReadString()
			local steamid = net.ReadString()
			local reason = net.ReadString()

			local color = teamcolors[userid]

			local parts = { COLOR_RED, "- " }
			if color then
				table.insert(parts, color)
			else
				table.insert(parts, COLOR_YELLOW)
			end
			table.insert(parts, name)

			table.insert(parts, COLOR_GRAY)
			table.insert(parts, " (" .. steamid .. ") ")

			table.insert(parts, COLOR_WHITE)
			if gaveup and reason == "Disconnect by user." then
				table.insert(parts, "gave up connecting")
			else
				table.insert(parts, "disconnected")
				if reason ~= "Disconnect by user." then
					table.insert(parts, COLOR_GRAY)
					table.insert(parts, " (" .. reason .. ")")
				end
			end

			chat.AddText(unpack(parts))
		elseif msg == MSG_SPAWNED then
			local ply = net.ReadPlayer()
			local name = net.ReadString()
			local steamid = net.ReadString()

			timer.Simple(0, function()
				if not IsValid(ply) then return end

				local color = hook.Run("GetTeamColor", ply)
				teamcolors[ply:UserID()] = color

				chat.AddText(COLOR_GREEN, "\xE2\x80\xA3 ", color, name, COLOR_GRAY, " (" .. steamid .. ") ", COLOR_WHITE,
					"has spawned")
			end)
		elseif msg == MSG_UPDATE_COLOR then
			local ply = net.ReadPlayer()
			timer.Simple(0, function()
				if not IsValid(ply) then return end

				local color = hook.Run("GetTeamColor", ply)
				teamcolors[ply:UserID()] = color
			end)
		end
	end)

	hook.Add("InitPostEntity", TAG, function()
		for _, ply in player.Iterator() do
			local color = hook.Run("GetTeamColor", ply)
			teamcolors[ply:UserID()] = color
		end
	end)

	hook.Add("ChatText", TAG, function(idx, name, text, msg)
		if msg == "joinleave" then return true end
	end)
end
