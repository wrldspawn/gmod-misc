local enabled = CreateConVar("sv_idlerestart", "1", FCVAR_ARCHIVE, "Automatically restart the server when empty", 0, 1)

local restarting = false
hook.Add("Think", "idlerestart", function()
	if not enabled then return end

	local total = #player.GetHumans()
	if gameserver then
		total = gameserver.GetNumClients() - gameserver.GetNumFakeClients()
	end

	if total > 0 then return end
	if restarting then return end

	if SysTime() > 43200 then
		restarting = true
		print("Restarting server as uptime is 12 hours")
		engine.CloseServer()
	elseif CurTime() > 10800 then
		restarting = true
		print("Restarting map as CurTime is over 3 hours")
		RunConsoleCommand("changelevel", game.GetMap())
	end
end)
