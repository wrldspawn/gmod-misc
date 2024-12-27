local PLAYER = FindMetaTable("Player")
local hasUnstuck = PLAYER.IsStuck ~= nil and PLAYER.UnStuck ~= nil
local checked = false

hook.Add("PlayerSay", "unstuck", function(ply, str)
	if not hasUnstuck and not checked then
		hasUnstuck = PLAYER.IsStuck ~= nil and PLAYER.UnStuck ~= nil
		checked = true
	end

	if str:find("stuck") and hasUnstuck and ply:IsStuck() then
		ply:UnStuck()
	end
end)
