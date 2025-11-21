if not HolyLib then return end

local TAG = "query_extras"

queryextras_connecting = queryextras_connecting or {}

local function GetPlayers()
	local now = SysTime()

	local highest = 0
	local lowest = 0

	local fields = {}
	local plys = {}
	local connecting = {}

	local i = 1
	for _, client in ipairs(gameserver.GetAll()) do
		local uid = client:GetUserID()
		local ply = Player(uid)

		local score = 0
		local time = 0
		if client:IsFakeClient() then
			time = ply:TimeConnected()
		else
			time = now - client:GetConnectTime()
		end

		if IsValid(ply) then
			score = ply:Frags()

			if score > highest then
				highest = score
			elseif lowest > score then
				lowest = score
			end

			plys[#plys + 1] = { name = ply:Name(), score = score, time = time }
		else
			score = lowest - i

			connecting[#connecting + 1] = { name = "[Connecting] " .. client:GetName(), score = score, time = time }

			i = i + 1
		end
	end

	-- gmod server list sorts by time, everything else sorts by score
	local curtime = CurTime()
	fields[#fields + 1] = { name = "Server Uptime:", score = highest + 3, time = now }
	fields[#fields + 1] = { name = "Map Uptime:", score = highest + 2, time = curtime }
	fields[#fields + 1] = { name = "————————————", score = highest + 1, time = curtime - 1 }

	for _, row in ipairs(plys) do
		fields[#fields + 1] = row
	end
	for _, row in ipairs(connecting) do
		fields[#fields + 1] = row
	end

	return fields
end

local PLAYER_REQUEST = string.byte("U")
local PLAYER_RESPONSE = string.byte("D")
hook.Add("HolyLib:ProcessConnectionlessPacket", TAG, function(bf, ip)
	local header = bf:ReadByte()
	if header ~= PLAYER_REQUEST then return end
	local challenge = bf:ReadLong()
	if challenge == 0 or challenge == -1 then return end

	local players = GetPlayers()

	local packet = bitbuf.CreateWriteBuffer(262144)
	packet:WriteLong(-1)
	packet:WriteByte(PLAYER_RESPONSE)
	packet:WriteByte(#players)

	for i, ply in ipairs(players) do
		packet:WriteByte(i - 1)
		packet:WriteString(ply.name)
		packet:WriteLong(ply.score)
		packet:WriteFloat(ply.time)
	end

	gameserver.SendConnectionlessPacket(packet, ip)
	return true
end)
