local TAG = "oc_empty_to_lobby"

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", TAG, function()
	local count = #player.GetHumans()
	if count == 0 and not Obsidian.IsLobbyMap() then
		print("Returning to lobby in 5 minutes")

		timer.Create(TAG, 300, 1, function()
			local self = GAMEMODE
			self.LevelChangeTimer = self:CountdownDisplay("Level Change", 10)
			self.BackToLobby = true
			self.BackToLobbyTimer = CurTime()
		end)
	end
end)

gameevent.Listen("player_connect")
hook.Add("player_connect", TAG, function()
	if timer.Exists(TAG) then
		print("Cancelling return to lobby")
		timer.Remove(TAG)
	end
end)
