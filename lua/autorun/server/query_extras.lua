if not serversecure then pcall(require, "serversecure") end
if not serversecure then return end
if not serversecure.Version:find("serversecure%-playerquery") then
	ErrorNoHalt("bad serversecure version for query_extras")
	return
end

local TAG = "query_extras"

queryextras_connecting = queryextras_connecting or {}

gameevent.Listen("player_connect")
hook.Add("player_connect", TAG, function(data)
	if tobool(data.bot) then return end

	queryextras_connecting[data.userid] = {
		start = SysTime(),
		name = data.name
	}
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", TAG, function(data)
	queryextras_connecting[data.userid] = nil
end)

hook.Add("PlayerInitialSpawn", TAG, function(ply)
	queryextras_connecting[ply:UserID()] = nil
end)

hook.Add("A2S_PLAYER", TAG, function(ip, port)
	local now = SysTime()

	local highest = 0
	local lowest = 0

	local plys = {}
	local _plys = {}

	for _, ply in player.Iterator() do
		local score = ply:Frags()

		if score > highest then
			highest = score
		elseif lowest > score then
			lowest = score
		end

		_plys[#_plys + 1] = { name = ply:Name(), score = score, time = ply:TimeConnected() }
	end

	local i = 1
	for _, data in pairs(queryextras_connecting) do
		_plys[#_plys + 1] = { name = "[Connecting] " .. data.name, score = lowest - i, time = now - data.start }
		i = i + 1
	end

	-- gmod server list sorts by time, everything else sorts by score
	local curtime = CurTime()
	plys[#plys + 1] = { name = "Server Uptime:", score = highest + 3, time = now }
	plys[#plys + 1] = { name = "Map Uptime:", score = highest + 2, time = curtime }
	plys[#plys + 1] = { name = "————————————", score = highest + 1, time = curtime - 1 }

	for _, ply in ipairs(_plys) do
		plys[#plys + 1] = ply
	end

	return plys
end)
